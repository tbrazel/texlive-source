#!/bin/sh
# usage: rebuild.sh NAME "CFLAGS" ["LDFLAGS"]
# Recompile the pdftex objects in $STUDYDIR/build with the given flags
# (kpathsea and the bundled libraries are left alone) and copy the
# result to $STUDYDIR/bin/pdftex-NAME.
set -e
here=$(cd "$(dirname "$0")" && pwd)
. "$here/env.sh"
name=$1 cflags=$2 ldflags=$3
cd "$STUDYDIR/build/texk/web2c"
rm -f pdftex pdftex-*.o pdftexdir/*.o libpdftex.a lib/*.o lib/lib.a
make pdftex CFLAGS="$cflags" CXXFLAGS="$cflags" LDFLAGS="$ldflags" \
  -j8 > "$STUDYDIR/rebuild-$name.log" 2>&1
cp pdftex "$STUDYDIR/bin/pdftex-$name"
echo "built $STUDYDIR/bin/pdftex-$name"
