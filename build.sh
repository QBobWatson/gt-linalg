#!/bin/bash

die() {
    echo "$@"
    exit 1
}

PRETEX_ALL=
CHUNKSIZE="250"

while [[ $# -gt 0 ]]; do
    case $1 in
        --reprocess-latex)
            PRETEX_ALL="true"
            ;;
        --chunk)
            shift
            CHUNKSIZE=$1
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
figure_img_dir="$build_dir"/figure-images
pretex="$base_dir/gt-text-common/pretex/pretex.py"

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
cp "$compile_dir/extra/google9ccfcae89045309c.html" "$build_dir"

echo "Converting xml to html..."
cat >xsl/git-hash.xsl <<EOF
<?xml version='1.0'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl">
  <xsl:template name="git-hash">
    <xsl:text>$(git rev-parse HEAD)</xsl:text>
  </xsl:template>
</xsl:stylesheet>
EOF
xsltproc -o "$build_dir/" --xinclude \
         "$compile_dir/xsl/mathbook-html.xsl" linalg.xml \
    || die "xsltproc failed!"

echo "Preprocessing LaTeX (be patient)..."
[ -n "$PRETEX_ALL" ] && rm -r pretex-cache
python3 "$pretex" --chunk-size $CHUNKSIZE --preamble "$build_dir/preamble.tex" \
        --cache-dir pretex-cache --style-path "$compile_dir"/style \
        "$build_dir"/*.html "$build_dir"/knowl/*.html \
    || die "Can't process html!"
mkdir "$figure_img_dir"
cp pretex-cache/*.png "$figure_img_dir"

echo "Cleaning up..."
rm "$build_dir"/preamble.tex
rm "$build_dir"/demos/*.mako
rm "$build_dir"/demos/js/*.coffee
rm "$build_dir"/demos/generate.py

echo "Build successful!  Open or reload"
echo "     $build_dir/index.html"
echo "in your browser to see the result."
