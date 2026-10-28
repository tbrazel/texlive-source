# Source this file. Points an out-of-tree pdftex at an installed
# TeX Live tree, since kpathsea otherwise derives TEXMFROOT from the
# binary's own location.
#
#   TLROOT     installed TeX Live (default /usr/local/texlive/2024)
#   STUDYDIR   work area for build, binaries, formats, results
#              (default ./pgo-work)

: ${TLROOT:=/usr/local/texlive/2024}
: ${STUDYDIR:=$(pwd)/pgo-work}
export TLROOT STUDYDIR

export TEXMFCNF=$TLROOT/texmf-dist/web2c
export TEXMFROOT=$TLROOT
export TEXMFDIST=$TLROOT/texmf-dist
export TEXMFLOCAL=$TLROOT/../texmf-local
export TEXMFSYSVAR=$TLROOT/texmf-var
export TEXMFSYSCONFIG=$TLROOT/texmf-config
export TEXFORMATS=$STUDYDIR/fmt:
