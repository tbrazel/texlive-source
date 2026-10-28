#!/bin/sh
# usage: bench.sh BINARY DOC.tex [N]
# Run pdflatex N times (default 9) on a document from docs/ and print
# the minimum and median wall-clock seconds.
here=$(cd "$(dirname "$0")" && pwd)
. "$here/env.sh"
bin=$1 doc=$2 n=${3:-9}
mkdir -p "$STUDYDIR/run"
cp "$here/docs/$doc" "$STUDYDIR/run/"
cd "$STUDYDIR/run"
now() { perl -MTime::HiRes=time -e 'printf "%.4f\n", time'; }
i=0
while [ $i -lt $n ]; do
  s=$(now)
  "$bin" -fmt=pdflatex -progname=pdflatex -interaction=batchmode \
    "$doc" >/dev/null 2>&1
  e=$(now)
  echo "$e - $s" | bc
  i=$((i + 1))
done | sort -n | awk '{a[NR] = $1}
  END {printf "min %.3f  med %.3f\n", a[1], a[int((NR + 1) / 2)]}'
