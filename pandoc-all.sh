#!/usr/bin/env bash

perl ~/.pandoc/filters/pp-include.pl

/usr/lib/pandoc -s -p -f markdown+tex_math_single_backslash --filter=pandoc-mustache --lua-filter=crossref-ordered-list.lua --lua-filter=secgroups.lua --filter=pandoc-crossref --lua-filter=inline-headers.lua
