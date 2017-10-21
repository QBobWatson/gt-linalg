#!/usr/bin/python3

import argparse
import os
import re
import shutil
import sys
from hashlib import md5
from subprocess import check_output, CalledProcessError, STDOUT

BASE = os.path.realpath(os.path.dirname(__file__))
SOURCES = os.path.join(BASE, 'img-source')
OUTPUTS = os.path.join(BASE, 'images')
XSL_DIR = os.path.realpath(os.path.join(BASE, '..', 'mathbook', 'xsl'))

def hash(fname):
    with open(fname, 'rb') as fobj:
        return md5(fobj.read()).hexdigest()

def dump(output):
    print("=" * 80)
    print("=" * 80)
    print(output)
    print("=" * 80)
    print("=" * 80)

def main():
    parser = argparse.ArgumentParser(
        description="Compile embedded LaTeX images to svg")
    parser.add_argument('--recompile-all', action='store_true',
                        help="Force recompile of all files")
    parser.add_argument(
        'xmlfile', default='linalg.xml', type=str, nargs='?',
        help="Extract images from this xml file")
    args = parser.parse_args(sys.argv[1:])

    os.environ['TEXINPUTS'] = ".:{}/style:".format(BASE)
    os.environ['TEXMFHOME'] = "{}/style/texmf-var".format(BASE)

    print("Extracting images from {}...".format(args.xmlfile))

    os.makedirs(SOURCES, exist_ok=True)

    try:
        check_output(['xsltproc', '--stringparam', 'scratch', SOURCES,
                      '--xinclude',
                      os.path.join(XSL_DIR, 'extract-latex-image.xsl'),
                      args.xmlfile], stderr=STDOUT)
    except CalledProcessError:
        print("Error extracting images from {}".format(args.xmlfile))
        sys.exit(1)

    compiled = 0

    os.chdir(SOURCES)
    for fname in os.listdir(SOURCES):
        match = re.match(r'(image-\d+).tex', fname)
        if not match:
            continue
        basename = match.group(1)
        fullpath = os.path.join(SOURCES, fname)
        checksum = hash(fullpath)

        tex = checksum + '.tex'
        svg = os.path.join(SOURCES, checksum + '.svg')
        pdf = os.path.join(SOURCES, checksum + '.pdf')
        outfile = os.path.join(OUTPUTS, basename + '.svg')

        if os.path.exists(svg) and not args.recompile_all:
            # File is up to date; just copy
            shutil.copy(svg, outfile)

        else:
            # Doesn't exist, or have to recompile
            print("(Re)compiling {}...".format(basename))
            shutil.copy(fname, tex)
            try:
                check_output(['pdflatex', '-interaction=nonstopmode',
                              '\\input{' + tex + '}'],
                             stderr=STDOUT)
            except CalledProcessError as cpe:
                print("Compilation failed.")
                print("Source was:")
                with open(tex) as fobj:
                    dump(fobj.read())
                print("Compilation output:")
                dump(cpe.output.decode())
                sys.exit(1)

            print("Converting output to svg...")
            try:
                check_output(['pdfcrop', pdf, pdf], stderr=STDOUT)
            except CalledProcessError as cpe:
                print("Error running pdfcrop")
                print("Output was:")
                dump(cpe.output.decode())

            try:
                check_output(['pdf2svg', pdf, svg], stderr=STDOUT)
            except CalledProcessError as cpe:
                print("Error running pdfsvg")
                print("Output was:")
                dump(cpe.output.decode())

            print("Copying to {}".format(outfile))
            shutil.copy(svg, outfile)
            compiled += 1

    if compiled > 0:
        print("Successfully compiled {} images".format(compiled))
    else:
        print("All images are up to date (use --recompile-all)")


if __name__ == "__main__":
    main()
