#!/usr/bin/env python3

# TODO:
#  * Prune css, javascript

import itertools
import os
import sys
from subprocess import Popen, PIPE

from mako.template import Template
from mako.lookup import TemplateLookup
from mako.runtime import Context
import yaml
from markdown import markdown
from mdx_partial_gfm import PartialGithubFlavoredMarkdownExtension
from gfm import SemiSaneListExtension

CONTEXT_NAME = "context.yaml"

def merge(a, b):
    if isinstance(a, dict) and isinstance(b, dict):
        d = dict(a)
        d.update({k: merge(a.get(k, None), b[k]) for k in b})
        return d

    if isinstance(a, list) and isinstance(b, list):
        return [merge(x, y) for x, y in itertools.zip_longest(a, b)]

    return a if b is None else b

def update_context(filename, context):
    try:
        with open(filename, 'r') as ctx_file:
            return merge(context, yaml.load(ctx_file))
    except FileNotFoundError:
        return context

def markdown_filter(text):
    return '<div class="markdown-body">' \
        + markdown(
            text,
            output_format='html5',
            extensions=[PartialGithubFlavoredMarkdownExtension(),
                        SemiSaneListExtension()]
        ) + '</div>'

def coffee_filter(text):
    proc = Popen(['coffee', '-scb'], stdin=PIPE, stdout=PIPE,
                 universal_newlines=True)
    out, _ = proc.communicate(text)
    if proc.returncode > 0:
        raise Exception("Can't compile coffeescript")
    return out

def process(path=".", context=None):
    if context is None:
        context = dict(base_dir='.', md=markdown_filter, coffee=coffee_filter)
    else:
        context = dict(context)
        if context['base_dir'] == '.':
            context['base_dir'] = '..'
        else:
            context['base_dir'] = os.path.join(context['base_dir'], '..')

    dir_ctx = update_context(os.path.join(path, CONTEXT_NAME), context)

    print("Entering {}".format(path))

    subdirs = []
    for filename in os.listdir(path):
        if path != '.':
            fullpath = os.path.join(path, filename)
        else:
            fullpath = filename

        if filename[0] == '.' or filename[:2] == '__':
            continue

        if os.path.isdir(fullpath):
            subdirs.append(fullpath)
            continue

        if filename[-4:] != 'mako':
            continue
        if filename[:4] == 'base':
            continue
        if process_files and os.path.realpath(fullpath) not in process_files:
            continue

        context_file = os.path.join(path, filename[:-4] + "yaml")
        output_file = os.path.join(path, filename[:-4] + "html")
        print("Processing {} to {}".format(
            filename, os.path.basename(output_file)))
        file_ctx = update_context(context_file, dir_ctx)
        file_ctx['this_file'] = filename
        file_ctx['this_path'] = fullpath
        lookup = TemplateLookup(directories=['.'], #parents(path),
                                output_encoding='utf-8')
        template = Template(filename=fullpath, lookup=lookup,
                            input_encoding='utf-8')
        with open(output_file, 'w') as output:
            ctx = Context(output, **file_ctx)
            template.render_context(ctx)

    for subdir in subdirs:
        process(subdir, dir_ctx)

if len(sys.argv) >= 1:
    process_files = set(os.path.realpath(fname) for fname in sys.argv[1:])
else:
    process_files = []
os.chdir(os.path.dirname(os.path.realpath(__file__)))
process()
