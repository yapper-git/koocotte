#!/bin/bash

cd "$(dirname "$0")" && cd ..

make build/5-darby.xml > /dev/null

while grep '<reference osisRef="John.2.1"' build/5-darby.xml > /dev/null
do
    echo "Generating 5-darby.xml..."
    rm -f build/5-darby.xml
    make build/5-darby.xml > /dev/null 2>&1
done
