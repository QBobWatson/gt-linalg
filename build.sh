#!/bin/bash

die() {
    echo "$@"
    exit 1
}

PRETEX_ALL=

while [[ $# -gt 0 ]]; do
    case $1 in
        --reprocess-latex)
            PRETEX_ALL="true"
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
    shift
done

compile_dir="$(cd "$(dirname "$0")"; pwd)"
base_dir="$compile_dir/.."
base_dir="$(cd "$base_dir"; pwd)"
build_dir="$base_dir/build"
static_dir="$build_dir/static"
pretex="$base_dir/gt-text-common/pretex/processtex.py"

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
cp "$base_dir/mathbook/css/mathbook-add-on.css" "$static_dir/css"
cp "$base_dir/gt-text-common/js/"*.js "$static_dir/js"
cp "$base_dir/mathbook-assets/stylesheets/"*.css "$static_dir/css"
cp "$base_dir/mathbook-assets/stylesheets/fonts/ionicons/fonts/"* "$static_dir/fonts"
cp -r "$base_dir/gt-text-common/fonts/"* "$static_dir/fonts"
cp "$compile_dir/images/"* "$static_dir/images"
cp -r "$compile_dir/demos" "$build_dir/demos"
ln -s "static/images" "$build_dir/images"

echo "Converting xml to html..."
xsltproc -o "$build_dir/" --xinclude \
         "$compile_dir/xsl/mathbook-html.xsl" linalg.xml \
    || die "xsltproc failed!"

echo "Preprocessing LaTeX (be patient)..."
[ -n "$PRETEX_ALL" ] && rm -r pretex-cache
python3 "$pretex" --preamble "$build_dir/preamble.tex" \
        --cache-dir pretex-cache --style-path "$compile_dir"/style \
        "$build_dir"/*.html "$build_dir"/knowl/*.html \
    || die "Can't process html!"

echo "Build successful!  Open or reload"
echo "     $build_dir/index.html"
echo "in your browser to see the result."
