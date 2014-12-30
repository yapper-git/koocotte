#!/bin/bash

OSIS_FILE=darby.osis.xml
TMP_FOLDER=$(mktemp -d)
VERSIFICATIONS="
    Catholic
    Catholic2
    German
    KJV
    KJVA
    LXX
    Leningrad
    Luther
    MT
    NRSV
    NRSVA
    Orthodox
    Rahlfs
    Synodal
    SynodalProt
    Vulg
"

cd "$(dirname "$0")" && cd ..

for VERSIFICATION in $VERSIFICATIONS
do
    echo === $VERSIFICATION ===
    osis2mod $TMP_FOLDER $OSIS_FILE -z -v $VERSIFICATION | grep -c versification
done
