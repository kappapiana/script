#!/usr/bin/env python3

import io
import re
import sys
import csv
import yaml

SUB_TABLE = {
    "\u2022": "-",
    "\u2014": "-",
    "\u2018": "'",
    "\u2019": "'",
    "\u201C": '"',
    "\u201D": '"',
    "\xA7": "Section",
}

# https://stackoverflow.com/questions/45004464/yaml-dump-adding-unwanted-newlines-in-multiline-strings/45004775#45004775


yaml.SafeDumper.org_represent_str = yaml.SafeDumper.represent_str

def repr_str(dumper, data):
    if len(data) > 80:
        return dumper.represent_scalar(u'tag:yaml.org,2002:str', data, style='|')
    return dumper.org_represent_str(data)

yaml.add_representer(str, repr_str, Dumper=yaml.SafeDumper)

# end of snippet

fname = sys.argv[1]
quotechar = sys.argv[2] if len(sys.argv) > 2 else '"'
out_fname = re.sub(r"\.csv$", ".yml", fname)

with open(fname) as f:
    csv_str = f.read()

for k, v in SUB_TABLE.items():
    csv_str = csv_str.replace(k, v)

reader = csv.DictReader(io.StringIO(csv_str) , delimiter=',', quotechar=quotechar)
data = [
    {k: (int(v) if k == "order" else v)
    for k, v in row.items()}
    for row in reader
]

with open(out_fname, "w") as f:
    yaml.safe_dump(data, f, width=None, sort_keys=False)

print(f"Wrote {out_fname}")





