#!/bin/bash

die() {
    echo "$@"
    exit 1
}

compile_latex() {
    (cd "$latex_dir" && \
            TEXINPUTS=".:$latex_dir/style:" pdflatex \
                     -interaction=nonstopmode "\input{index}" \
                || die "pdflatex failed")
}

make_hashes() {
    cat >xsl/git-hash.xsl <<EOF
<?xml version='1.0'?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl">
  <xsl:template name="git-hash">
    <xsl:text>$(git rev-parse HEAD)</xsl:text>
  </xsl:template>
  <xsl:template name="versioned-file">
    <xsl:param name="file"/>
    <xsl:variable name="commit">
      <xsl:choose>
        <xsl:when test="\$file='static/gt-linalg.js'">
          <xsl:text>$(git hash-object "$build_dir"/static/gt-linalg.js | cut -c 1-6)</xsl:text>
        </xsl:when>
        <xsl:when test="\$file='static/gt-linalg.css'">
          <xsl:text>$(git hash-object "$build_dir"/static/gt-linalg.css | cut -c 1-6)</xsl:text>
        </xsl:when>
        <xsl:when test="\$file='demos/cover.js'">
          <xsl:text>$(git hash-object "$build_dir"/demos/cover.js | cut -c 1-6)</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="\$file"/>
    <xsl:text>?vers=</xsl:text>
    <xsl:value-of select="\$commit"/>
  </xsl:template>
</xsl:stylesheet>
EOF
}

combine_css() {
    if [ -n "$MINIFY" ]; then
        ./node_modules/clean-css-cli/bin/cleancss --skip-rebase "$@"
    else
        cat "$@"
    fi
}

combine_js() {
    if [ -n "$MINIFY" ]; then
        ./node_modules/uglify-js/bin/uglifyjs -m -- "$@"
    else
        (
            for file in "$@"; do
                cat "$file"
                echo ";"
            done
        )
    fi
}


PRETEX_ALL=
LATEX_TOO=
MINIFY=
CHUNKSIZE="250"

while [[ $# -gt 0 ]]; do
    case $1 in
        --reprocess-latex)
            PRETEX_ALL="true"
            ;;
        --pdf-vers)
            LATEX_TOO="true"
            ;;
        --minify)
            MINIFY="true"
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
latex_dir="$base_dir/build-pdf"
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
mkdir -p "$static_dir/fonts"
mkdir -p "$static_dir/images"

if [ -n "$LATEX_TOO" ]; then
    rm -rf "$latex_dir"
    mkdir -p "$latex_dir"
    cp -r "$compile_dir/style" "$latex_dir/style"
    cp -r "$compile_dir/figure-images" "$latex_dir/figure-images"
    echo "Generating master LaTeX file"
    xsltproc -o "$latex_dir/" --xinclude \
             "$compile_dir/xsl/mathbook-latex.xsl" linalg.xml \
        || die "xsltproc failed!"
    echo "Compiling PDF version (pass 1)"
    compile_latex
    echo "Compiling PDF version (pass 2)"
    compile_latex
    mv "$latex_dir"/index.pdf "$build_dir"/gt-linalg.pdf
fi

echo "Copying static files..."
combine_css "$base_dir/mathbook-assets/stylesheets/mathbook-gt.css" \
            "$base_dir/mathbook/css/mathbook-add-on.css" \
            "$base_dir/gt-text-common/css/mathbook-gt-add-on.css" \
            "$base_dir/gt-text-common/css/knowlstyle.css" \
            "$compile_dir/demos/mathbox/mathbox.css" \
            > "$static_dir/gt-linalg.css"
combine_js "$base_dir/gt-text-common/js/jquery.min.js" \
           "$base_dir/gt-text-common/js/jquery.sticky.js" \
           "$base_dir/gt-text-common/js/knowl.js" \
           "$base_dir/gt-text-common/js/GTMathbook.js" \
           > "$static_dir/gt-linalg.js"

cp "$base_dir/mathbook-assets/stylesheets/fonts/ionicons/fonts/"* "$static_dir/fonts"
cp -r "$base_dir/gt-text-common/fonts/"* "$static_dir/fonts"
cp "$compile_dir/images/"* "$static_dir/images"
cp "$compile_dir/manifest.json" "$build_dir"
cp "$compile_dir/extra/google9ccfcae89045309c.html" "$build_dir"

cp -r "$compile_dir/build-demos" "$build_dir/demos"
if [ -n "$MINIFY" ]; then
    for js in "$build_dir/demos/"*.js "$build_dir/demos/"*/*.js; do
        ./node_modules/uglify-js/bin/uglifyjs -m -- "$js" > "$js".min
        mv "$js".min "$js"
    done
    for css in "$build_dir/demos/css/"*.css; do
        ./node_modules/clean-css-cli/bin/cleancss --skip-rebase "$css" > "$css".min
        mv "$css".min "$css"
    done
fi

echo "Converting xml to html..."
make_hashes
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

echo "Build successful!  Open or reload"
echo "     $build_dir/index.html"
echo "in your browser to see the result."
