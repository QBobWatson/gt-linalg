#!/usr/bin/env python3

import os
from shutil import copy, copytree, rmtree, move
from subprocess import Popen, PIPE, check_output, check_call

from mako.template import Template
from mako.lookup import TemplateLookup
from mako.runtime import Context
import yaml

BUILD_YAML = "build.yaml"
BUILD_DIR = "../build-demos"

def cat(outfile, infiles, sep=''):
    with open(outfile, 'w') as outfobj:
        for infile in infiles:
            with open(infile, 'r') as infobj:
                outfobj.write(infobj.read())
                outfobj.write(sep)

def cat_js(outfile, infiles):
    cat(outfile, infiles, ';')

cat_css = cat

# Har har
def coffee_filter(text):
    proc = Popen(['coffee', '-scb'], stdin=PIPE, stdout=PIPE,
                 universal_newlines=True)
    out, _ = proc.communicate(text)
    if proc.returncode > 0:
        raise Exception("Can't compile coffeescript")
    return out

# TODO: relative directory
VERSIONS = {} # Cache
def version_filter(fname):
    if fname in VERSIONS:
        vers = VERSIONS[fname]
    else:
        commit = check_output(
            ['git', 'hash-object', os.path.join(BUILD_DIR, fname)])
        vers = commit.decode()[:6]
        VERSIONS[fname] = vers
    return "{}?vers={}".format(fname, vers)


def run_mako(infile, outfile):
    # pylint: disable=bad-whitespace
    context = dict(
        coffee = coffee_filter,
        vers   = version_filter
    )
    lookup = TemplateLookup(directories=['.'], output_encoding='utf-8')
    template = Template(filename=infile, lookup=lookup, input_encoding='utf-8')
    with open(outfile, 'w') as output:
        ctx = Context(output, **context)
        template.render_context(ctx)


def build(rule):
    # First interpret the rule
    # pylint: disable=bad-whitespace
    if isinstance(rule, str):
        fname = rule
        todo = dict(
            source = fname,
            action = None,
            copy   = True
        )
    elif isinstance(rule, dict):
        fname = list(rule.keys())[0]
        val = rule[fname]
        if isinstance(val, str):
            todo = dict(
                source = val,
                action = 'compile',
                copy   = True
            )
        elif isinstance(val, list):
            todo = dict(
                source = val,
                action = 'combine',
                copy   = True
            )
        elif isinstance(val, dict):
            todo = val
            todo.setdefault('action', 'compile')
            todo.setdefault('copy', True)
    if 'type' not in todo:
        if fname[-3:].lower() == '.js':
            todo['type'] = 'js'
        elif fname[-4:].lower() == '.css':
            todo['type'] = 'css'
        elif fname[-5:].lower() == '.html':
            todo['type'] = 'html'
    if isinstance(todo['source'], str):
        todo['source'] = [todo['source']]
    if todo['copy']:
        outfile = os.path.join(BUILD_DIR, fname)
    else:
        outfile = fname

    # Check if a source file was modified
    if os.path.exists(outfile):
        outtime = os.path.getmtime(outfile)
        if all(os.path.getmtime(source) < outtime for source in todo['source']):
            return

    # Now actually do something
    os.makedirs(
        os.path.join(BUILD_DIR, os.path.dirname(outfile)), exist_ok=True)
    if todo['action'] is None:
        # Just copy
        if todo['copy']:
            if os.path.isdir(todo['source'][0]):
                if os.path.isdir(outfile):
                    rmtree(outfile)
                copytree(todo['source'][0], outfile)
            else:
                copy(todo['source'][0], outfile)
    elif todo['action'] == 'combine':
        if todo['type'] == 'js':
            cat_js(outfile, todo['source'])
        elif todo['type'] == 'css':
            cat_css(outfile, todo['source'])
    elif todo['action'] == 'compile':
        if todo['type'] == 'js':
            check_call(['coffee', '-c', todo['source'][0]])
            generated = todo['source'][0].replace('.coffee', '.js')
            if generated != outfile:
                move(generated, outfile)
        elif todo['type'] == 'html':
            run_mako(todo['source'][0], outfile)
    print("Generated {}".format(outfile))


def main():
    os.chdir(os.path.dirname(os.path.realpath(__file__)))
    with open(BUILD_YAML, 'r') as fobj:
        rules = yaml.load(fobj)
    for rule in rules:
        build(rule)

if __name__ == '__main__':
    main()
