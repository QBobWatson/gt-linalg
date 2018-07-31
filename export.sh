#!/bin/bash

base_dir="/base"
compile_dir="$base_dir/gt-linalg"
build_base="/home/vagrant"
build_dir="$build_base/build"

# Run in the vagrant build vm
if [ ! -d "$base_dir" ]; then
    if [ ! $(vagrant status --machine-readable | grep state,running) ]; then
        vagrant up || die "Cannot start build environment virtual machine"
    fi
    vagrant ssh -- "$compile_dir/export.sh" "$@"
    exit $?
fi


VERSION=$1
[ -n "$VERSION" ] || VERSION=default

cd "$build_base"
mv build $VERSION
tar cvzf "$base_dir/$VERSION.tar.gz" $VERSION
mv $VERSION build
