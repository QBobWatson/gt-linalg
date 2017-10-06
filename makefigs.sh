#!/bin/bash

compile_dir="$(cd "$(dirname "$0")"; pwd)"
base_dir="$compile_dir/.."
mbx="$base_dir/mathbook/script/mbx"

xmlfile=linalg.xml
[ -n "$1" ] && xmlfile="$1"

cd "$compile_dir"
TEXINPUTS=".:$compile_dir/style:"; export TEXINPUTS
TEXMFHOME="$compile_dir/style/texmf-var"; export TEXMFHOME
exec $mbx -c latex-image -f svg -d images "$xmlfile"
