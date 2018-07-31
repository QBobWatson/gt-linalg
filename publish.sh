#!/bin/bash

for vers in default 1553; do
    echo "***************************************************************************"
    echo "BUILDING VERSION $vers"
    echo "***************************************************************************"

    ./build.sh --version $vers --pdf-vers --minify --demos
    ./export.sh $vers

    cp ../$vers.tar.gz /tmp
    (cd /tmp && rm -rf $vers && tar xvzf $vers.tar.gz)
done

cd /tmp
mv 1553 default
cd default
rsync -e ssh --delete -rvc . shadext:/mnt/raid/www/docs/gt-linalg

if [ "$0" == "production" ]; then
    rsync -e ssh --delete -rvc . textbooks.math.gatech.edu:/httpdocs/ila
fi

