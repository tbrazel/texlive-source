# pdfTeX: profile-guided optimization gives ~10% with identical output

## Summary

This branch does not change any TeX Live source or build logic. It
contains a write-up (this file) and the scripts under `pgo-study/` used
to measure where pdflatex spends its time and whether compiler settings
alone can make it faster.

Result: building pdftex with clang profile-guided optimization (PGO)
made pdflatex 10-11% faster on two documents that were not used for
training, and 11-13% faster with ThinLTO added. PDFs and logs were
byte-identical to the default `-O2` build, and the pdftex test scripts
pass. `-O3` and LTO alone gave no meaningful gain.

This is offered as data for a possible change to how release binaries
are built. It is not meant to be merged as-is (`pgo-study/` is not
wired into Automake).

## Where the time goes

pdftex built from trunk (`fd728dfcde`) with `-O2 -g`, sampled with
macOS `sample` over a 515-page article (`pgo-study/docs/big.tex` with
400 iterations instead of 60):

| Function(s)                                   | Share of samples |
|-----------------------------------------------|------------------|
| `getnext`                                     | 42%              |
| `macrocall`, `endtokenlist`, `expand`         | 22%              |
| `idlookup`, `scantoks`, `conditional`, others | ~25%             |
| zlib (`longest_match`, `deflate_slow`)        | 2.3%             |
| PDF output (`pdfhlistout`, ...)               | < 1%             |

Most of the time goes to the token interpreter walking `mem[]` and
`eqtb[]`. Changing it at the source level would risk changing TeX's
behavior, so I didn't attempt it. Setting `\pdfcompresslevel=0` or using
`-draftmode` saved only about 3%.

## Measurements

Wall-clock seconds, min / median of 9 runs, pdflatex format built by
each binary from the same TeX Live 2024 tree:

| Build                     | `big.tex` (78 pp) | `beamer.tex` (80 frames) | `min.tex`     |
|---------------------------|-------------------|--------------------------|---------------|
| `-O2` (Autoconf default)  | 1.046 / 1.050     | 0.600 / 0.601            | 0.225 / 0.227 |
| `-O3`                     | 1.049 / 1.083     | 0.596 / 0.601            | 0.225 / 0.226 |
| `-O2 -flto=thin`          | 1.027 / 1.057     | 0.589 / 0.591            | 0.220 / 0.221 |
| `-O2` + PGO               | 0.930 / 0.932     | 0.542 / 0.546            | 0.223 / 0.224 |
| `-O2 -flto=thin` + PGO    | 0.907 / 0.912     | 0.534 / 0.537            | —             |

- PGO was trained on one run of `huge.tex` (generated from `big.tex`:
  article, amsmath, TikZ, lipsum, hyperref). `beamer.tex` shares none
  of that workload apart from amsmath and still sped up by 10%.
- `min.tex` (an empty article, so startup only) doesn't change.
  Startup is dominated by loading the format and initializing
  kpathsea.
- For reference: loading just the preamble of `big.tex` (`pre.tex`)
  takes 0.42 s of the 1.05 s total.

Environment: Apple Silicon Mac, macOS 27 (Darwin 27.0.0), Apple clang
21.0.0, runtime files from an installed TeX Live 2024. I have only
measured on this one machine. Results on x86-64, GCC, or MSVC were not
measured.

## Verification

- **Identical output.** `pgo-study/compare.sh` typesets `big.tex` and
  `beamer.tex` twice with `SOURCE_DATE_EPOCH`/`FORCE_SOURCE_DATE` set.
  The `.pdf` and `.log` from the PGO and PGO+LTO builds are byte-identical
  to `-O2`.
- **Tests.** pdftex test scripts run against the PGO+LTO binary, all
  exit 0: `wprob`, `pdftex`, `pdfimage`, `expanded`, `tests/cnfline`,
  `tests/partoken`, `wcfname`. They were run directly with
  `srcdir=... sh <test>` because `make check` also builds MetaPost,
  which fails here (see below).
- The full `./Build` and test suite were **not** run, since no code
  changed.

## Reproducing

```sh
# macOS 27 only, see "Build issues" below:
export SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
export TLROOT=/usr/local/texlive/2024        # installed TeX Live runtime
export STUDYDIR=$PWD/pgo-work                 # all output goes here

pgo-study/build-pdftex.sh                     # pdftex -O2 + pdflatex.fmt
pgo-study/variants.sh                         # O3, lto, pgo, pgolto
pgo-study/compare.sh pgo pgolto               # byte-identical check
for v in O2 O3 lto pgo pgolto; do
  echo "$v: $(pgo-study/bench.sh $STUDYDIR/bin/pdftex-$v big.tex)"
done
```

`variants.sh` uses clang's `-fprofile-instr-generate` /
`-fprofile-instr-use` and `llvm-profdata`. GCC would need
`-fprofile-generate` / `-fprofile-use` instead. That variant is not
scripted here.

## What adopting this would involve

- A two-stage build for each release binary: instrument, run a
  representative training corpus, rebuild with the profile. The default
  `configure`/`make` behavior would stay the same, and PGO would be an
  opt-in step in the release build process.
- Picking a training corpus. One TikZ-heavy article was enough here,
  but a release build should use something broader (plain TeX, LaTeX
  classes, beamer, documents with lots of images and fonts).
- PGO doesn't change semantics, but it does make each build depend on
  its profile. Results from compilers and platforms other than clang on
  arm64 still need to be measured.

## Build issues found along the way (separate from this proposal)

1. On macOS 27 the Command Line Tools linker rejects the SDK's
   `libSystem.tbd` ("unknown architecture arm64e.x1-macos"), so
   configure fails with "C compiler cannot create executables". Using
   Xcode's SDK via `SDKROOT` works around it. This is a local toolchain
   problem, not a TeX Live bug.
2. `libs/mpfi/mpfi-src/src/z_sub.c:31` fails with clang 21 in C23 mode
   (`CC="gcc -std=gnu23"`): "static declaration of 'mpfr_z_sub'
   follows non-static declaration". This blocks MetaPost and
   `make check` in `texk/web2c`. It should probably go to the mpfi
   maintainers.

## AI assistance

The profiling, scripts, and this write-up were produced with Claude
(Claude Code). The numbers above come from runs on the machine
described, and have not yet been independently re-run by a second
person.
