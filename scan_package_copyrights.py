#!/usr/bin/env python3
"""Extract copyright statements per Yocto package, not per recipe.

Each recipe's work directory is scanned once with scancode, then each package
listed in the SBOM gets the copyrights of:
  - the files it ships (from pkgdata FILES_INFO), and
  - the source files its binaries were compiled from (from their debug info).

When unsure it over-reports, because this is meant for compliance use:
  - a package that cannot be mapped gets all of its recipe's copyrights and is
    marked "fallback" in _report.tsv;
  - copyrights not assigned to any package go to <recipe>/_unassigned.txt.

Requires scancode and pyelftools in the scancode venv. There is no need to
activate it: the script uses ~/scancode_venv, or SCANCODE_VENV if set.

Usage:
  scan_package_copyrights.py --sbom sbom.json --tmp BUILD/tmp --out OUT_DIR \\
      [--manifest IMAGE.manifest] [--recipe-copyrights RECIPE_OUT_DIR] \\
      [--recipes qt4-x11-free,zlib]

--manifest is the image manifest (tmp/deploy/images/<machine>/<image>.manifest).
With it, only the packages it lists are processed, whatever the SBOM's "images"
field says, and differences between the two go to OUT_DIR/_manifest_mismatch.tsv.
Without it, the packages with a non-empty "images" field are processed.

--recipe-copyrights points to the output of scan_copyrights.sh. It adds holders
from files outside the work directory's package/ tree (licence files, sources
that were not compiled) to fallback packages and to _unassigned.txt.

Output:
  OUT_DIR/<recipe>/<package>/copyrights.txt   the package's copyrights
  OUT_DIR/<recipe>/<package>/files.txt        the files they were taken from
  OUT_DIR/<recipe>/<package>/external.txt     sources outside the recipe's tree
                                              (e.g. other recipes' headers)
  OUT_DIR/<recipe>/<package>/external_copyrights.txt
                                              copyrights of those sources, kept
                                              apart from copyrights.txt
  OUT_DIR/<recipe>/<package>/external_unresolved.txt
                                              those sources that were not found
                                              in the recipe's sysroots, so their
                                              copyrights are unknown
  OUT_DIR/<recipe>/_unassigned.txt            copyrights not linked to a package
  OUT_DIR/_report.tsv                         one line per package
  OUT_DIR/_failed.txt                         recipes that failed, with the reason
  OUT_DIR/_logs/<recipe>.log                  scancode output

Safe to re-run: finished recipes are skipped, failed ones are retried.
"""

import argparse
import glob
import hashlib
import json
import os
import shutil
import signal
import subprocess
import sys
import tempfile
import time

# Run inside the scancode venv without having to activate it: restart with its
# Python, which ends with this process, so the calling shell is left untouched.
VENV = os.environ.get("SCANCODE_VENV", os.path.expanduser("~/scancode_venv"))
VENV_PYTHON = os.path.join(VENV, "bin", "python3")
if os.path.realpath(sys.prefix) != os.path.realpath(VENV) and os.path.exists(VENV_PYTHON):
    os.execv(VENV_PYTHON, [VENV_PYTHON] + sys.argv)
os.environ["PATH"] = os.path.join(sys.prefix, "bin") + os.pathsep + os.environ.get("PATH", "")

try:
    from elftools.common.exceptions import ELFError
    from elftools.elf.elffile import ELFFile
except ImportError:
    sys.exit(f"pyelftools not found; install it with: {sys.prefix}/bin/pip install pyelftools")

REPORT_HEADER = ("recipe\tpackage\tstatus\tcopyrights\tfiles\telf\texternal"
                 "\texternal_copyrights\texternal_unresolved\tnote\n")
SCAN_FINISHED = "Removing temporary files...done"


def is_elf(path):
    try:
        with open(path, "rb") as f:
            return f.read(4) == b"\x7fELF"
    except OSError:
        return False


def text(value):
    return value.decode("utf-8", "surrogateescape") if isinstance(value, bytes) else value


def dwarf_sources(path):
    """Return the source paths in an ELF's debug info, or None if it has none."""
    with open(path, "rb") as f:
        elf = ELFFile(f)
        if not elf.has_dwarf_info():
            return None
        dwarf = elf.get_dwarf_info()
        sources = set()
        found_cu = False
        for cu in dwarf.iter_CUs():
            found_cu = True
            top = cu.get_top_DIE()
            comp_attr = top.attributes.get("DW_AT_comp_dir")
            comp_dir = text(comp_attr.value) if comp_attr else ""
            name_attr = top.attributes.get("DW_AT_name")
            if name_attr:
                sources.add(os.path.join(comp_dir, text(name_attr.value)))

            program = dwarf.line_program_for_CU(cu)
            if program is None:
                continue
            header = program.header
            if header["version"] >= 5:
                dirs = [text(d.DW_LNCT_path) for d in header["directories"]]
                for entry in header["file_names"]:
                    index = entry.DW_LNCT_directory_index
                    directory = dirs[index] if index < len(dirs) else ""
                    sources.add(os.path.join(comp_dir, directory, text(entry.DW_LNCT_path)))
            else:
                # before DWARF 5, directory 0 is the compilation directory
                dirs = [text(d) for d in header["include_directory"]]
                for entry in header["file_entry"]:
                    index = entry.dir_index
                    directory = dirs[index - 1] if 0 < index <= len(dirs) else ""
                    sources.add(os.path.join(comp_dir, directory, text(entry.name)))
        return sources if found_cu else None


def debug_file_for(package_root, shipped_path, cache):
    """Return the sources for a shipped ELF, looking where Yocto puts debug info."""
    directory, base = os.path.split(shipped_path)
    candidates = [
        os.path.join(package_root, directory.lstrip("/"), ".debug", base),
        os.path.join(package_root, "usr/lib/debug", shipped_path.lstrip("/") + ".debug"),
        os.path.join(package_root, shipped_path.lstrip("/")),  # not stripped
    ]
    for candidate in candidates:
        if not os.path.isfile(candidate):
            continue
        if candidate not in cache:
            try:
                cache[candidate] = dwarf_sources(candidate)
            except (ELFError, OSError, KeyError, ValueError, AttributeError, IndexError,
                    AssertionError) as error:
                print(f"  cannot read debug info of {candidate}: {error}", file=sys.stderr)
                cache[candidate] = None
        if cache[candidate]:
            return cache[candidate]
    return None


def read_files_info(pkgdata_dirs, package):
    """Return (file list, split name) for a package name from the SBOM, or None."""
    for pkgdata in pkgdata_dirs:
        path = os.path.join(pkgdata, "runtime-reverse", package)
        if not os.path.exists(path):
            continue
        with open(path, encoding="utf-8", errors="surrogateescape") as f:
            for line in f:
                if line.startswith("FILES_INFO"):
                    return list(json.loads(line.split(": ", 1)[1]))
        return []
    return None


def find_workdir(tmp, recipe, version):
    """Return (work directory, warning or None), preferring the SBOM's version."""
    matches = [d for d in glob.glob(os.path.join(glob.escape(tmp), "work", "*",
                                                 glob.escape(recipe), "*"))
               if os.path.isdir(os.path.join(d, "package"))]
    exact = [d for d in matches
             if os.path.basename(d) == version or os.path.basename(d).startswith(version + "-")]
    pool = exact or matches
    if not pool:
        return None, None
    pool.sort(key=os.path.getmtime, reverse=True)
    warning = None
    if len(pool) > 1:
        warning = f"{len(pool)} work directories, using newest: {pool[0]}"
    elif not exact:
        warning = f"version {version} not found, using {pool[0]}"
    return pool[0], warning


def kill_group(process):
    for sig in (signal.SIGTERM, signal.SIGKILL):
        try:
            os.killpg(process.pid, sig)
        except ProcessLookupError:
            return
        if sig == signal.SIGTERM:
            time.sleep(5)


def run_scancode(package_root, output, log_path, args):
    """Run scancode, returning None on success or the failure reason."""
    command = ["scancode", "--copyright", "-n", str(args.procs),
               "--timeout", str(args.file_timeout), "--strip-root",
               "--ignore", "*/.debug/*", "--ignore", "*/usr/lib/debug/*",
               "--json", output, package_root]
    started = time.monotonic()
    finished_at = None
    with open(log_path, "wb") as log:
        process = subprocess.Popen(command, stdout=log, stderr=subprocess.STDOUT,
                                   stdin=subprocess.DEVNULL, start_new_session=True)
    try:
        while process.poll() is None:
            time.sleep(2)
            now = time.monotonic()
            if finished_at is None:
                with open(log_path, errors="replace") as log:
                    if SCAN_FINISHED in log.read():
                        finished_at = now
            if finished_at is not None and now - finished_at >= args.exit_grace:
                # scancode can hang at exit after it has written its results
                print("  scancode finished but did not exit; killing it")
                kill_group(process)
                process.wait()
                return None
            if args.recipe_timeout and now - started >= args.recipe_timeout:
                kill_group(process)
                process.wait()
                return f"timed out after {args.recipe_timeout}s"
    except BaseException:
        kill_group(process)
        raise
    return None if process.returncode == 0 else f"scancode exit code {process.returncode}"


def scan_recipe(package_root, dest, log_path, args):
    """Return {relative path: [copyrights]}, reusing an earlier scan if there is one."""
    cache = os.path.join(dest, "_scan.json")
    if os.path.isfile(cache) and not args.force:
        with open(cache, encoding="utf-8") as f:
            return json.load(f)
    raw = os.path.join(dest, "_scan.raw.json")
    hits = scan_to_hits(package_root, raw, log_path, args)
    save_json(cache, hits)
    return hits


def scan_to_hits(root, raw, log_path, args):
    """Scan root and return {relative path: [copyrights]}, leaving no raw output."""
    reason = run_scancode(root, raw, log_path, args)
    if reason:
        raise RuntimeError(reason)
    with open(raw, encoding="utf-8") as f:
        scanned = json.load(f)
    hits = {}
    for entry in scanned.get("files", []):
        copyrights = [c["copyright"] for c in entry.get("copyrights", [])]
        if copyrights:
            hits[entry["path"]] = copyrights
    os.remove(raw)
    return hits


def save_json(path, data):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f)
    os.replace(tmp, path)


def find_external(path, workdir):
    """Return where a path from the debug info is in the recipe's sysroots, or None.

    Yocto strips the sysroot prefix from debug paths, so /usr/include/x.h is
    <sysroot>/usr/include/x.h in the target or native sysroot.
    """
    for sysroot in ("recipe-sysroot", "recipe-sysroot-native"):
        candidate = os.path.join(workdir, sysroot, path.lstrip("/"))
        if os.path.isfile(candidate):
            return candidate
    return None


def scan_external(paths, workdir, log_path, args):
    """Return {path: [copyrights]} for the external sources that could be found.

    Recipes share most headers, so results are cached by file content across
    recipes and each distinct file is scanned only once.
    """
    cache_path = os.path.join(args.out, "_external_cache.json")
    cache = {}
    if os.path.isfile(cache_path):
        with open(cache_path, encoding="utf-8") as f:
            cache = json.load(f)

    digests = {}
    pending = {}
    for path in paths:
        found = find_external(path, workdir)
        if found is None:
            continue
        with open(found, "rb") as f:
            digest = hashlib.sha256(f.read()).hexdigest()
        digests[path] = digest
        if digest not in cache:
            pending[digest] = found

    if pending:
        with tempfile.TemporaryDirectory(dir=args.out, prefix="_external.") as tmp:
            root = os.path.join(tmp, "scan")
            for digest, found in pending.items():
                os.makedirs(os.path.join(root, digest))
                shutil.copyfile(found, os.path.join(root, digest, os.path.basename(found)))
            hits = scan_to_hits(root, os.path.join(tmp, "raw.json"), log_path, args)
        for digest in pending:
            cache[digest] = []
        for path, copyrights in hits.items():
            cache[path.split("/", 1)[0]] = copyrights
        save_json(cache_path, cache)

    return {path: cache[digest] for path, digest in digests.items()}


def write_lines(path, lines):
    with open(path, "w", encoding="utf-8", errors="surrogateescape") as f:
        f.writelines(line + "\n" for line in sorted(lines))


def write_if_any(path, lines):
    """Write lines to path, or make sure there is no such file when there are none."""
    if lines:
        write_lines(path, lines)
    elif os.path.exists(path):
        os.remove(path)


def read_manifest(path):
    """Return the package names in an image manifest (lines: name arch version)."""
    names = set()
    with open(path, encoding="utf-8", errors="surrogateescape") as f:
        for line in f:
            fields = line.split()
            if fields and not fields[0].startswith("#"):
                names.add(fields[0])
    return names


def packages_to_process(data, installed):
    """Return a recipe's sorted packages: those in the manifest, or else in an image."""
    packages = data.get("packages", {})
    if installed is not None:
        return sorted(name for name in packages if name in installed)
    return sorted(name for name, pkg in packages.items() if pkg.get("images"))


def compare_manifest(sbom, installed, out):
    """Write the differences between SBOM and manifest; return (sbom only, manifest only)."""
    owners = {name: recipe for recipe, data in sbom.items() for name in data.get("packages", {})}
    sbom_only = sorted(set(owners) - installed)
    manifest_only = sorted(installed - set(owners))
    with open(os.path.join(out, "_manifest_mismatch.tsv"), "w", encoding="utf-8",
              errors="surrogateescape") as f:
        f.write("found_only_in\tpackage\trecipe\n")
        f.writelines(f"sbom\t{name}\t{owners[name]}\n" for name in sbom_only)
        f.writelines(f"manifest\t{name}\t\n" for name in manifest_only)
    return sbom_only, manifest_only


def remove_stale_output(path, marker):
    """Remove an output directory no longer wanted, if this script's marker shows it made it."""
    if os.path.exists(os.path.join(path, marker)):
        shutil.rmtree(path)


def process_recipe(recipe, packages, data, pkgdata_dirs, args):
    """Scan one recipe and write its per-package output. Raises on failure."""
    workdir, warning = find_workdir(args.tmp, recipe, data.get("version", ""))
    if workdir is None:
        raise RuntimeError("no work directory with a package/ tree")
    if warning:
        print(f"  WARNING: {warning}", file=sys.stderr)

    dest = os.path.join(args.out, recipe)
    os.makedirs(dest, exist_ok=True)
    package_root = os.path.join(workdir, "package")
    hits = scan_recipe(package_root, dest, os.path.join(args.out, "_logs", recipe + ".log"), args)
    everything = {c for found in hits.values() for c in found}

    recipe_level = set()
    if args.recipe_copyrights:
        path = os.path.join(args.recipe_copyrights, recipe, "copyrights.txt")
        if os.path.isfile(path):
            with open(path, encoding="utf-8", errors="surrogateescape") as f:
                recipe_level = {line.rstrip("\n") for line in f if line.strip()}
        else:
            print(f"  WARNING: no recipe-level result at {path}", file=sys.stderr)

    dwarf_cache = {}
    assigned = set()
    results = []
    for package in packages:
        files = read_files_info(pkgdata_dirs, package)
        paths = set()
        external = set()
        notes = []
        elf_count = 0
        fallback = files is None
        if files is None:
            notes.append("not in pkgdata")
        for shipped in files or []:
            relative = shipped.lstrip("/")
            full = os.path.join(package_root, relative)
            if os.path.islink(full) or not os.path.isfile(full):
                continue
            paths.add(relative)
            if not is_elf(full):
                continue
            elf_count += 1
            sources = debug_file_for(package_root, shipped, dwarf_cache)
            if sources is None:
                fallback = True
                notes.append(f"no debug info: {shipped}")
                continue
            for source in sources:
                normal = os.path.normpath(source).lstrip("/")
                if os.path.isfile(os.path.join(package_root, normal)):
                    paths.add(normal)
                elif not source.startswith("<"):
                    external.add(os.path.normpath(source))

        copyrights = {c for path in paths for c in hits.get(path, [])}
        if fallback:
            copyrights |= everything | recipe_level
        else:
            assigned |= copyrights
        results.append((package, fallback, copyrights, paths, external, elf_count, notes))

    external_hits = scan_external(
        {path for result in results for path in result[4]}, workdir,
        os.path.join(args.out, "_logs", recipe + ".external.log"), args)

    rows = []
    for package, fallback, copyrights, paths, external, elf_count, notes in results:
        pkg_dir = os.path.join(dest, package)
        os.makedirs(pkg_dir, exist_ok=True)
        write_lines(os.path.join(pkg_dir, "copyrights.txt"), copyrights)
        write_lines(os.path.join(pkg_dir, "files.txt"), paths)
        external_copyrights = {c for path in external for c in external_hits.get(path, [])}
        unresolved = {path for path in external if path not in external_hits}
        write_if_any(os.path.join(pkg_dir, "external.txt"), external)
        write_if_any(os.path.join(pkg_dir, "external_copyrights.txt"), external_copyrights)
        write_if_any(os.path.join(pkg_dir, "external_unresolved.txt"), unresolved)
        rows.append(f"{recipe}\t{package}\t{'fallback' if fallback else 'ok'}\t{len(copyrights)}"
                    f"\t{len(paths)}\t{elf_count}\t{len(external)}\t{len(external_copyrights)}"
                    f"\t{len(unresolved)}\t{'; '.join(notes)}\n")

    for entry in os.listdir(dest):
        if entry not in packages:
            remove_stale_output(os.path.join(dest, entry), "files.txt")

    write_lines(os.path.join(dest, "_unassigned.txt"), (everything | recipe_level) - assigned)
    with open(os.path.join(dest, "_report.tsv"), "w", encoding="utf-8",
              errors="surrogateescape") as f:
        f.writelines(rows)
    return len(packages)


def parse_args():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--sbom", required=True, help="SBOM JSON file")
    parser.add_argument("--tmp", required=True, help="Yocto TMPDIR (with work/ and pkgdata/)")
    parser.add_argument("--out", required=True, help="output directory")
    parser.add_argument("--manifest", help="image manifest: process only the packages it lists")
    parser.add_argument("--recipe-copyrights", help="output directory of scan_copyrights.sh")
    parser.add_argument("--recipes", help="comma-separated recipes to process (default: all)")
    parser.add_argument("--procs", type=int, default=2, help="scancode processes (default: 2)")
    parser.add_argument("--file-timeout", type=int, default=300,
                        help="max seconds per file in scancode (default: 300)")
    parser.add_argument("--recipe-timeout", type=int, default=21600,
                        help="max seconds per recipe, 0 = none (default: 21600)")
    parser.add_argument("--exit-grace", type=int, default=60,
                        help="kill scancode this many seconds after it finished (default: 60)")
    parser.add_argument("--force", action="store_true", help="rescan finished recipes")
    return parser.parse_args()


def main():
    args = parse_args()
    if not shutil.which("scancode"):
        sys.exit("scancode not in PATH (venv not active?)")
    # a broken scancode install would otherwise fail on every recipe in turn
    check = subprocess.run(["scancode", "--version"], capture_output=True, text=True)
    if check.returncode != 0:
        sys.exit("scancode does not start (is EXTRACTCODE_LIBARCHIVE_PATH set?):\n"
                 + check.stderr[-1500:])

    with open(args.sbom, encoding="utf-8") as f:
        sbom = json.load(f)
    pkgdata_dirs = [d for d in glob.glob(os.path.join(glob.escape(args.tmp), "pkgdata", "*"))
                    if os.path.isdir(os.path.join(d, "runtime-reverse"))]
    if not pkgdata_dirs:
        sys.exit(f"no pkgdata found under {args.tmp}/pkgdata")

    selected = sorted(sbom)
    if args.recipes:
        selected = args.recipes.split(",")
        unknown = [r for r in selected if r not in sbom]
        if unknown:
            sys.exit(f"recipes not in the SBOM: {', '.join(unknown)}")

    os.makedirs(os.path.join(args.out, "_logs"), exist_ok=True)

    installed = None
    manifest_only = []
    if args.manifest:
        installed = read_manifest(args.manifest)
        known = {name for data in sbom.values() for name in data.get("packages", {})}
        if not installed & known:
            sys.exit(f"no package in {args.manifest} is in the SBOM: wrong file or format?")
        sbom_only, manifest_only = compare_manifest(sbom, installed, args.out)
        print(f"manifest: {len(installed)} packages; {len(sbom_only)} only in the SBOM (skipped), "
              f"{len(manifest_only)} only in the manifest (NOT processed)")

    # output left by an earlier run for recipes that no longer have any package
    for recipe, data in sbom.items():
        if not packages_to_process(data, installed):
            remove_stale_output(os.path.join(args.out, recipe), "_report.tsv")

    ok = skipped = 0
    failures = []
    for recipe in selected:
        data = sbom[recipe]
        packages = packages_to_process(data, installed)
        if not packages:
            continue
        # .done records the packages processed, so a different selection is redone
        done = os.path.join(args.out, recipe, ".done")
        wanted = "\n".join(packages) + "\n"
        if os.path.exists(done):
            with open(done, encoding="utf-8", errors="surrogateescape") as f:
                unchanged = f.read() == wanted
            if unchanged and not args.force:
                skipped += 1
                continue
            os.remove(done)
        print(f"\n[{time.strftime('%F %T')}] processing {recipe}", flush=True)
        started = time.monotonic()
        try:
            count = process_recipe(recipe, packages, data, pkgdata_dirs, args)
        except (RuntimeError, OSError, ValueError) as error:
            print(f"  FAILED: {error}", file=sys.stderr)
            failures.append(f"{recipe}\t{error}\n")
            continue
        with open(done, "w", encoding="utf-8", errors="surrogateescape") as f:
            f.write(wanted)
        print(f"  ok in {time.monotonic() - started:.0f}s, {count} packages", flush=True)
        ok += 1

    with open(os.path.join(args.out, "_failed.txt"), "w", encoding="utf-8") as f:
        f.writelines(failures)
    with open(os.path.join(args.out, "_report.tsv"), "w", encoding="utf-8",
              errors="surrogateescape") as report:
        report.write(REPORT_HEADER)
        for path in sorted(glob.glob(os.path.join(glob.escape(args.out), "*", "_report.tsv"))):
            with open(path, encoding="utf-8", errors="surrogateescape") as f:
                report.write(f.read())

    print(f"\ndone: {ok} ok, {skipped} skipped (already done), {len(failures)} failed")
    print(f"report: {args.out}/_report.tsv")
    if manifest_only:
        print(f"WARNING: {len(manifest_only)} installed packages are not in the SBOM and have no "
              f"results; see {args.out}/_manifest_mismatch.tsv")
    if failures:
        print(f"failed recipes listed in {args.out}/_failed.txt")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
