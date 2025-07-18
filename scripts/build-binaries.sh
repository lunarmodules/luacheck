#!/usr/bin/env bash
set -eu
set -o pipefail

# Builds the following binaries:
# * luacheck (Linux x86-64)
# * luacheck32 (Linux x86)
# * luacheck.exe (Windows x86-64)
# * luacheck32.exe (Windows x86)
# Should be executed from root Luacheck directory.
# Resulting binaries will be in `build/bin/`.

: ${MAKE:=make}
: ${CROSSBUILDS=1}

cd build

${MAKE} fetch

function build {
    label="$1"
    shift

    echo
    echo "=== Building Luacheck ($label) ==="
    echo

    ${MAKE} clean "$@"
    ${MAKE} "-j$(nproc)" "$@"
}

build "Linux x86-64" LINUX=1
if [ "$CROSSBUILDS" -ne 0 ]; then
	#build "Linux x86" LINUX=1 "BASE_CC=gcc -m32" SUFFIX=32
	build "Windows x86-64" CROSS=x86_64-w64-mingw32- SUFFIX=.exe
	build "Windows x86" CROSS=i686-w64-mingw32- SUFFIX=32.exe
fi
