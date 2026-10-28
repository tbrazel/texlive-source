#!/bin/sh
# usage: compare.sh VARIANT...
# Typeset docs/big.tex and docs/beamer.tex (two passes) with
# $STUDYDIR/bin/pdftex-O2 and each VARIANT under a fixed date, then
# check that PDFs and logs are byte-identical to the -O2 baseline.
here=$(cd "$(dirname "$0")" && pwd)
. "$here/env.sh"
export SOURCE_DATE_EPOCH=1700000000 FORCE_SOURCE_DATE=1
status=0
for v in O2 "$@"; do
  d=$STUDYDIR/cmp/$v
  mkdir -p "$d"
  cp "$here/docs/big.tex" "$here/docs/beamer.tex" "$d/"
  for f in big beamer; do
    for pass in 1 2; do
      (cd "$d" && "$STUDYDIR/bin/pdftex-$v" -fmt=pdflatex \
        -progname=pdflatex -interaction=batchmode $f.tex >/dev/null 2>&1)
    done
  done
done
for v in "$@"; do
  for f in big beamer; do
    for ext in pdf log; do
      if cmp -s "$STUDYDIR/cmp/O2/$f.$ext" "$STUDYDIR/cmp/$v/$f.$ext"; then
        echo "same:   $v $f.$ext"
      else
        echo "DIFFER: $v $f.$ext"; status=1
      fi
    done
  done
done
exit $status
