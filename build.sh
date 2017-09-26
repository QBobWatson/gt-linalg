#!/bin/bash

die() {
    echo "$@"
    exit 1
}

compile_dir="$(cd "$(dirname "$0")"; pwd)"
base_dir="$compile_dir/.."
base_dir="$(cd "$base_dir"; pwd)"
build_dir="$base_dir/build"
static_dir="$build_dir/static"

echo "Checking xml..."
cd "$compile_dir"
xmllint --xinclude --noout --relaxng "$base_dir/mathbook/schema/pretext.rng" \
        linalg.xml
if [[ $? == 3 || $? == 4 ]]; then
    echo "Input is not valid MathBook XML; exiting"
    exit 1
fi

echo "Cleaning up previous build..."
rm -rf "$build_dir"
mkdir -p "$build_dir"
mkdir -p "$static_dir"
mkdir -p "$static_dir/js"
mkdir -p "$static_dir/css"
mkdir -p "$static_dir/fonts"
mkdir -p "$static_dir/images"

echo "Copying static files..."
cp "$base_dir/gt-text-common/css/"*.css "$static_dir/css"
cp "$base_dir/gt-text-common/js/"*.js "$static_dir/js"
cp "$base_dir/mathbook-assets/stylesheets/"*.css "$static_dir/css"
cp "$base_dir/mathbook-assets/stylesheets/fonts/ionicons/fonts/"* "$static_dir/fonts"
cp "$compile_dir/images/"* "$static_dir/images"
ln -s "static/images" "$build_dir/images"

echo "Building html..."
xsltproc -o "$build_dir/" --xinclude \
         "$compile_dir/xsl/mathbook-html.xsl" linalg.xml \
         || die "xsltproc failed!"

echo "Build successful!  Open or reload"
echo "     $build_dir/index.html"
echo "in your browser to see the result."
