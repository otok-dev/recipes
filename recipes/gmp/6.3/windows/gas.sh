#!/bin/sh
# CCAS of GMP's build with MSVC: GNU as of the MSYS2 tree (its path the first argument) for GMP's x86_64 assembly,
# which m4 has expanded. GMP gives the assembler the C compiler's options, cl's here, which as does not take: they are
# dropped, and the include directories kept. The object is -o's, or the source's name with .obj (configure's tests).
as=$1
shift
out=
src=
inc=
while [ $# -gt 0 ]; do
    case "$1" in
        -o) out=$2; shift ;;
        -I) inc="$inc -I$2"; shift ;;
        -I*) inc="$inc $1" ;;
        -*) ;;
        *) src=$1 ;;
    esac
    shift
done
[ -n "$out" ] || out=${src%.*}.obj
exec "$as" --64 $inc -o "$out" "$src"
