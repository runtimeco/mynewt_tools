#!/bin/sh

set -e

print_usage() {
    echo "usage: $(basename "$0") <tagname> <dst-prefix>"
    echo "  example: $(basename "$0")  mynewt_0_8_0_b2_tag ~/rel/apache-larva-0.8.0-incubating-b2"
}

usage_err() {
    if [ "$1" != "" ]
    then
        printf "* error: %s\n" >&2
    fi

    print_usage >&2
}

tagname=$1
dstprefix=$2

if [ "$tagname" = '' ] || [ "$dstprefix" = '' ]
then
    usage_err
    exit 1
fi

dstfile="$dstprefix.tgz"
tarprefix=$(basename "$dstprefix")

# Create tgz file.
git archive --format tgz --output "$dstfile" --prefix "$tarprefix"/ "$tagname"

# Create ASCII armored detached signature.
gpg2 --armor --output "$dstfile".asc --detach-sig "$dstfile"

# Create sha; cd to target directory first for friendlier output.
(
    dir="$(dirname "$dstfile")"
    filename="$(basename "$dstfile")"
    cd "$dir" &&
    gpg2 --print-md SHA512 "$filename" > "$filename".sha
)

# Verify signature.
gpg2 --verify "$dstfile.asc" "$dstfile"
