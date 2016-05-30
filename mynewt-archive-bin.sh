#!/bin/sh

set -e

scriptname="$(basename "$0")"

print_usage() {
    cat <<-EOS
usage: $scriptname <dst-prefix> <bin-files>

  example:
      $scriptname ~/rels/apache-newt-bin-osx-0.8.0-b2 \\
        newt LICENSE NOTICE DISCLAIMER
  
  creates the following files:
      * ~/rels/apache-newt-bin-osx-0.8.0-b2.tgz
      * ~/rels/apache-newt-bin-osx-0.8.0-b2.tgz.asc
      * ~/rels/apache-newt-bin-osx-0.8.0-b2.tgz.sha
EOS
}

usage_err() {
    if [ "$1" != "" ]
    then
        printf "* error: %s\n\n" "$1" >&2
    fi

    print_usage >&2
    exit 1
}

if [ $# -lt 2 ]
then
    usage_err
fi

dstprefix=$1
shift

tgzpath="$dstprefix.tgz"
tgzfile="$(basename "$tgzpath")"
dstroot=$(basename "$dstprefix")
dstdir="$(dirname "$tgzpath")"

workdir=$(mktemp -d /tmp/mynewt-bin-archive.XXXXXXXXXX)
workchild="$workdir/$dstroot"
mkdir "$workchild"

# Link each specified file to the work directory.
for binfile
do
    if [ ! -e "$binfile" ]
    then
        usage_err "File not found: $binfile"
    fi

    ln -s "$binfile" "$workchild"
done

# Create tgz file.
mkdir -p "$dstdir"
tar -C "$workdir" -h -czvf "$tgzpath" "$dstroot"

# Delete temp directory.
rm -r "$workdir"

# Create ASCII armored detached signature.
gpg2 --armor --output "$tgzpath".asc --detach-sig "$tgzpath"

# Create sha; cd to target directory first for friendlier output.
(
    cd "$dstdir" &&
    gpg2 --print-md SHA512 "$tgzfile" > "$tgzfile".sha
)

# Verify signature.
gpg2 --verify "$tgzpath.asc" "$tgzpath"
