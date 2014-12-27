#!/bin/bash

cd ..
make build/5-darby.xml > /dev/null
grep '<reference osisRef="John.2.1"' build/5-darby.xml > /dev/null && echo BUG || echo OK
