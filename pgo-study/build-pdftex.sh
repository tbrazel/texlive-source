#!/bin/sh
# Configure and build only pdftex, out of tree, under $STUDYDIR/build,
# then build a pdflatex format with it under $STUDYDIR/fmt.
# The baseline binary is copied to $STUDYDIR/bin/pdftex-O2.
#
# On macOS, if the Command Line Tools SDK cannot be linked against,
# export SDKROOT to Xcode's SDK first (see PR.md).
set -e
here=$(cd "$(dirname "$0")" && pwd)
top=$(cd "$here/.." && pwd)
. "$here/env.sh"
mkdir -p "$STUDYDIR/build" "$STUDYDIR/bin" "$STUDYDIR/fmt"
cd "$STUDYDIR/build"

"$top/configure" --disable-all-pkgs --enable-web2c --enable-pdftex \
  --disable-tex --disable-etex --disable-ptex --disable-eptex \
  --disable-uptex --disable-euptex --disable-aleph --disable-hitex \
  --disable-luatex --disable-luajittex --disable-luahbtex \
  --disable-luajithbtex --disable-mflua --disable-mfluajit \
  --disable-mp --disable-pmp --disable-upmp --disable-xetex \
  --disable-mf --disable-mf-nowin --disable-synctex \
  --without-x --disable-shared --disable-native-texlive-build \
  --enable-silent-rules CFLAGS="-O2 -g" CXXFLAGS="-O2 -g" \
  > configure.log 2>&1
# The top-level make configures the subdirectories on demand.
make -j8 > make.log 2>&1

cp texk/web2c/pdftex "$STUDYDIR/bin/pdftex-O2"
cd "$STUDYDIR/fmt"
"$STUDYDIR/bin/pdftex-O2" -ini -etex -interaction=batchmode \
  -jobname=pdflatex -progname=pdflatex pdflatex.ini >/dev/null
echo "built $STUDYDIR/bin/pdftex-O2 and $STUDYDIR/fmt/pdflatex.fmt"
