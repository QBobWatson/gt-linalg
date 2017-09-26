
# Getting Started Guide

Throughout this guide, I'm assuming you're using a UNIX-like system (e.g., a
Mac), and that you have basic familiarity with the command shell.  All of the
interaction is done through the shell.

Overview: 
* Install prerequisites
* Sign up for GitHub
* Create an SSH key
* Create an SSH key for use from home
* Fetch the repositories
* Build the site
* Push a commit
* Editing XML
* Resources


## Installing prerequisites

There are only two prerequisites for compiling: git and xsltproc.  They may
already be installed on your system; type `git` and `xsltproc` from a command
shell to find out.  If not, refer to Google for how to install them.

If you've never run git before, then you need to tell it who you are so it knows
how to sign your commits.  Run these commands:
```
> git config --global user.name "Joe Rabinoff"
> git config --global user.email "jrabinoff6@math.gatech.edu"
```


## Signing up for GitHub

You need to join the `math-online-textbooks` group on the campus GitHub site.  I
can't give you access to the group until you've signed onto GitHub for the first
time.  To do so, navigate to https://github.gatech.edu/; send me an email when
you've signed on.

Once you have access, the GitHub group can be found here:
https://github.gatech.edu/math-online-textbooks


## Setting up an SSH key

An SSH key allows you to login to github with a public / private key pair.  This
saves you a lot of time typing passwords every time you want to interact with
GitHub.  Here's how to create and enable a key pair:

1) Create a directory off your home directory called `.ssh`:
```
mkdir ~/.ssh
```

2) Run `ssh-keygen`.  The default key file name `~/.ssh/id_rsa` is fine.  **Do
not enter a passphrase,** as this defeats the purpose.

3) Make a text file called `config` in your `~/.ssh` directory, with the
following contents:

```
ControlMaster auto
ControlPersist yes

Host github.gatech.edu
     User         git
     IdentityFile ~/.ssh/id_rsa
```

4) In your GitHub account settings page
(https://github.gatech.edu/settings/keys), click the "New SSH Key" button.  Call
the key whatever you want, then paste the contents of `~/.ssh/id_rsa.pub`
into the "Key" field.

Now if you type `ssh github.gatech.edu`, it should give you a message like,
```
Hi jrabinoff6! You've successfully authenticated, but GitHub does not provide shell access.
Shared connection to github.gatech.edu closed.
```
This means you're successfully authenticated.


## Setting up an SSH key if you want to work from home

Unfortunately, you can't ssh directly to `github.gatech.edu` from outside the
campus network.  If you have a VPN set up, you can use that to connect.
Otherwise, here's a workaround that uses an ssh tunnel through the math ssh
server.

First `ssh you@ssh.math.gatech.edu`, then complete steps (1)-(4) above *from the
ssh shell*.

5) Still from the ssh shell, run `cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys`.  This will let you use the same key to login to ssh.math.gatech.edu.

6) Copy the files `id_rsa` and `id_rsa.pub` from `ssh.math.gatech.edu` to
`~/.ssh` on your home computer.

7) Make a `config` file in `~/.ssh` on your home computer, with the following contents:
```
ControlMaster auto
ControlPersist yes

Host gatech
     HostName     ssh.math.gatech.edu
     User         jrabinoff6  # Replace with your username
     IdentityFile ~/.ssh/id_rsa

Host github.gatech.edu
     User         git
     IdentityFile ~/.ssh/id_rsa
     ProxyCommand ssh -q gatech nc github.gatech.edu 22
```

Now typing `ssh github.gatech.edu` should give you the same message as above.


## Cloning the repositories

First decide where you want to put all the files.  I have my files in
`~/projects/textbooksGT`.  Change to that directory and run:
```
> git clone -b gt git@github.gatech.edu:math-online-textbooks/mathbook.git
> git clone -b gt git@github.gatech.edu:math-online-textbooks/mathbook-assets.git
> git clone git@github.gatech.edu:math-online-textbooks/gt-text-common.git
> git clone git@github.gatech.edu:math-online-textbooks/gt-linalg.git
```

This should create directories called `mathbook`, `mathbook-assets`,
`gt-text-common`, and `gt-linalg` in the current directory.  The first three are
support files needed to build the book.  The last repository contains the book.


## Build the site

I've created a build script that should do everything for you.  Change to your
project directory (for instance, `~/projects/textbooksGT`), then into the
`gt-linalg` directory.  Type `./build.sh`.  If everything goes well, then the
book will appear in `~/projects/textbooksGT/build`.  Open
`~/projects/textbooksGT/index.html` in a browser.


## Push a commit

After making changes to the xml files, first build the site on your computer using the above instructions.  Assuming there are no errors, you now want to update the version on the GitHub repository.

Here is the general procedure for synchronizing your repository with the remote:

1) Run `git fetch origin`.  This pulls any changes from the server that have happened since you started editing and stores them.

2) Run `git merge origin/master`.  This updates your local files with the remote version.  If you've been editing the same file as someone else, then this step might cause issues.  If everything goes smoothly, it should say something like:
```
Updating 03ffb15..8beab76
Fast-forward
   [list of files that were modified on the server]
```

3) Run `git status`.  It should tell you that you've modified one of the files.

4) Run `git add [file you modified]`.  This tells git that you intend to update this file on the server.

5) Run `git commit -m 'A descriptive commit message'`.  This finalizes the changes on your computer.

6) Run `git push origin`.  This sends your changes to the server.

Now when you navigate to
https://github.gatech.edu/math-online-textbooks/gt-linalg/, you should see your
changes.


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


## Resources

* Beezer's documentation on Mathbook XML:
    https://mathbook.pugetsound.edu/
* Author's guide:
    http://mathbook.pugetsound.edu/doc/author-guide/html/
* Intro to git:
    http://mathbook.pugetsound.edu/gfa/html/
* FCLA source:
    https://github.com/rbeezer/fcla

* Math 1553 materials can be found here:
    http://course-repos.math.gatech.edu/
* Here's a direct link to my slides:
    http://course-repos.math.gatech.edu/math1553/slides/allslides-web.pdf

