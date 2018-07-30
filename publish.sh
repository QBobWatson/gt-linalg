#!/bin/bash

./build.sh --pdf-vers --minify
./export.sh

cp ../book.tar.gz /tmp
cd /tmp
rm -rf book
tar xvzf book.tar.gz
cd book
rsync -e ssh --delete -rvc . shadext:/mnt/raid/www/docs/gt-linalg

if [ "$0" == "production" ]; then
    rsync -e ssh --delete -rvc . textbooks.math.gatech.edu:/httpdocs/ila
fi
