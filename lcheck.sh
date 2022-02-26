#!/bin/bash

if  [[ $1 = "-l" ]]; then
    path_to_script="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"
    master_adocs=$(find . -type f -name master\*adoc)
    for i in $master_adocs; do asciidoctor --safe -v -n $i >/dev/null 2>&1; done
    find . -type f -name master\*html | xargs linkchecker -r1 -f $path_to_script/lcheck.ini --check-extern 2>/dev/null | grep -Ev "^Check time|^Size.*"
elif [[ $1 = "-a" ]]; then
    master_adocs=$(find . -type f -name master\*adoc)
    for i in $master_adocs; do
        asciidoctor -a attribute-missing=warn --failure-level=WARN $i 2> >(grep -E "missing attribute" && echo -e $i"\n")
    done
elif [[ $1 = "-h" ]]; then
    echo "-h          list avaliable commandline options"
    echo "-a          check unresolved attributes"
    echo "-l          check broken links"
else
    echo "-h          list avaliable commandline options"
    echo "-a          check unresolved attributes"
    echo "-l          check broken links"
fi
