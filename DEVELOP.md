
# Developer's Getting Started Guide

The command-line arguments given in this guide assume you're using a UNIX-like
system (e.g., a Mac).  Building under Windows is similar.

Overview: 
* Fetch the repositories
* Setup the build system
* Build the site
* Editing XML
* Resources


## Fetch the repositories

First decide where you want to put all the files.  I have my files in
`~/projects/textbooksGT`.  Change to that directory and run:
```
> git clone -b gt git@github.com:QBobWatson/mathbook.git
> git clone -b gt git@github.com:QBobWatson/mathbook-assets.git
> git clone git@github.com:QBobWatson/gt-text-common.git
> git clone git@github.com:QBobWatson/gt-linalg.git
```

This should create directories called `mathbook`, `mathbook-assets`,
`gt-text-common`, and `gt-linalg` in the current directory.  The first three contain
support files needed to build the book.  The last repository contains the source for the book and demos.


## Setup the build system

The build system has a large number of complicated dependencies.  For this reason, I've packaged everything needed to build the book into a [Vagrant](https://www.vagrantup.com/) box.  This is a prepackaged virtual machine that can be launched from any Unix, Mac, or Windows computer.  It has two prerequisites:
* VirtualBox: the underlying virtual machine software.  [Download](https://www.virtualbox.org/wiki/Downloads).
* Vagrant: the program that manages the virtual machine.  [Download](https://www.vagrantup.com/downloads.html).

The build environment `build_env.box` can be found here: [Download](https://www.dropbox.com/s/8ldk0xymt8dmqxi/build_env.box).  This file is very large (over 6GB; mostly LaTeX and relatives), so be patient.

To install the build environment, change into `gt-linalg`, and type:
```
vagrant box add --name build_env /path/to/build_env.box
vagrant up
```

If you want to poke around the virtual machine, use `vagrant ssh`.  To stop it, type `vagrant halt`.

## Build the site

I've created a build script that should do everything for you.  Change into `gt-linalg`, then type `./build.sh`.  This starts the Vagrant box if it is not already running, then does an enormous amount of work to build the site.  Beware that the first build can take several hours on a laptop computer.

The build script has several options:
* `--version` Build a particular version of the book (default, 1553, 1554).
* `--reprocess-latex` The build system caches the results of LaTeX compilation.  This option deletes the cache.
* `--pdf-vers` Also compile the pdf version of the book.
* `--demos` Also regenerate the demos.
* `--minify` Mangle `.js` and `.css` files to save space at the expense of readability.

The result of the build is contained in the virtual machine, which conveniently runs a web server.  Point your browser at `http://localhost:8081/` to see the version you just built.  Type `./export.sh` to export the built book; it will appear in the file `../default.tar.gz`.


## Editing XML

It will probably save you time in the long run to obtain and learn to use a good XML editor.  Beezer recommends [XML Copy Editor](http://xml-copy-editor.sourceforge.net/).

One advantage of a smart XML editor is that it knows what tags are allowed
where.  I've adapted Beezer's XML schema files for this purpose; they are
contained in `gt-text-common/schemas`.  Use `pretext.rnc`, `pretext.rng`, or
`pretext.xsd`, in that order of preference, depending on what kind of schema
your editor supports.  You'll have to figure out how to tell your editor to use
those schemas.

I use Emacs's `nxml-mode`, which came pre-installed with my Emacs distribution.
I don't think it's worth learning to use Emacs just to edit xml.  If you already
use Emacs, then be sure to open the xml files in `nxml-mode`; it should
automatically read the appropriate schema file from the file `schemas.xml`,
which I've included in the repository.

Note that `build.sh` will refuse to compile malformed `xml` files.


## Resources

* Beezer's documentation on Mathbook XML:
    https://mathbook.pugetsound.edu/
* Author's guide:
    http://mathbook.pugetsound.edu/doc/author-guide/html/
* FCLA source:
    https://github.com/rbeezer/fcla


