#!/bin/bash

path_to_script="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"

echo "Searching for master.adocs"
master_adocs=$(find . -type f -name master\*adoc)

echo "Building master.adocs"
for i in $master_adocs; do asciidoctor --safe -v -n $i >/dev/null 2>&1; done

echo "Checking links"
find . -type f -name master\*html | xargs linkchecker -r1 -f $path_to_script/lcheck.ini --check-extern 2>/dev/null | grep -Ev "^Check time|^Size.*"
