#!/usr/bin/python3

import argparse
import os
import shutil
import sys
from hashlib import md5
from subprocess import check_call, CalledProcessError

BASE = os.path.realpath(os.path.dirname(__file__))
CACHE = os.path.join(BASE, 'prejax-cache')
BUILD = os.path.realpath(os.path.join(BASE, '..', 'build'))
PREJAX = os.path.realpath(os.path.join(
    BASE, '..', 'gt-text-common', 'prejax', 'prejax.js'))

def hash_file(fname):
    with open(fname, 'rb') as fobj:
        return md5(fobj.read()).hexdigest()

def update_files_in_dir(dirname, args, nocss=False):
    # Find files that need updating
    need_update = []
    for fname in os.listdir(dirname):
        if not fname.endswith('.html'):
            continue
        fullpath = os.path.join(dirname, fname)
        hashed = hash_file(fullpath)
        cached = os.path.join(args.cache_dir, hashed + '.html')

        if os.path.exists(cached) and not args.process_all:
            shutil.copy(cached, fullpath)

        else:
            # Doesn't exist, or have to recompile
            need_update.append((fullpath, cached))

    cmdline = ['nodejs', PREJAX]
    if nocss:
        cmdline += ['--no-css']
    cmdline += [os.path.join(BUILD, 'preamble.tex')]
    cmdline += [x[0] for x in need_update]
    check_call(cmdline)
    for path, cached in need_update:
        shutil.copy(path, cached)

def main():
    parser = argparse.ArgumentParser(
        description="Preprocess MathJax")
    parser.add_argument('--process-all', action='store_true',
                        help="Force reprocessing of all files")
    parser.add_argument('--build-dir', default=BUILD, type=str,
                        help="Build directory")
    parser.add_argument('--cache-dir', default=CACHE, type=str,
                        help="Cache directory")
    args = parser.parse_args(sys.argv[1:])

    os.makedirs(args.cache_dir, exist_ok=True)

    update_files_in_dir(args.build_dir, args)
    update_files_in_dir(os.path.join(args.build_dir, 'knowl'), args)


if __name__ == "__main__":
    main()
