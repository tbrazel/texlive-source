#!/bin/sh
# Build the -O3, LTO, PGO and PGO+LTO variants (clang).
# PGO is trained on docs/huge.tex, which is not one of the timed documents.
set -e
here=$(cd "$(dirname "$0")" && pwd)
. "$here/env.sh"
profdata=${LLVM_PROFDATA:-$(xcrun -f llvm-profdata 2>/dev/null || echo llvm-profdata)}

"$here/rebuild.sh" O3 "-O3 -g"
"$here/rebuild.sh" lto "-O2 -g -flto=thin" "-flto=thin"

"$here/rebuild.sh" pgogen "-O2 -g -fprofile-instr-generate" \
  "-fprofile-instr-generate"
mkdir -p "$STUDYDIR/run"
sed 's/<60/<400/' "$here/docs/big.tex" > "$STUDYDIR/run/huge.tex"
rm -f "$STUDYDIR"/train-*.profraw
(cd "$STUDYDIR/run" && LLVM_PROFILE_FILE="$STUDYDIR/train-%p.profraw" \
  "$STUDYDIR/bin/pdftex-pgogen" -fmt=pdflatex -progname=pdflatex \
  -interaction=batchmode huge.tex >/dev/null)
"$profdata" merge -o "$STUDYDIR/pdftex.profdata" "$STUDYDIR"/train-*.profraw

use="-fprofile-instr-use=$STUDYDIR/pdftex.profdata"
"$here/rebuild.sh" pgo "-O2 -g $use"
"$here/rebuild.sh" pgolto "-O2 -g -flto=thin $use" "-flto=thin"
