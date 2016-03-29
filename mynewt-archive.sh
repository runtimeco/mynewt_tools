#!/bin/sh

set -e

scriptname="$(basename "$0")"

print_usage() {
    cat <<-EOS
usage: $scriptname <dst-prefix> <tag-name>

  example:
      $scriptname ~/rels/apache-newt-0.8.0-b2 mynewt_0_8_0_b2_tag
  
  creates the following files:
      * ~/rels/apache-newt-0.8.0-b2.tgz
      * ~/rels/apache-newt-0.8.0-b2.tgz.asc
      * ~/rels/apache-newt-0.8.0-b2.tgz.sha
EOS
}

usage_err() {
    if [ "$1" != "" ]
    then
        printf "* error: %s\n" >&2
    fi

    print_usage >&2
}

dstprefix=$1
tagname=$2

if [ "$tagname" = '' ] || [ "$dstprefix" = '' ]
then
    usage_err
    exit 1
fi

dstfile="$dstprefix.tgz"
dstdir="$(dirname "$dstprefix")"
tarprefix=$(basename "$dstprefix")

# Create tgz file.
mkdir -p "$dstdir"
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
