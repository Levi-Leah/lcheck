#!/bin/bash
# link-checker.sh does the following:
# gathers all master.adoc files in the repo
# builds all the master.adoc files with asciidoctor
# saves all the master.html files in a var and passes them to the link_checker.py

all_master_adoc_files=$(find . -type f -name "master.adoc")

echo "Building files..."
for i in $all_master_adoc_files; do asciidoctor --safe -v -n $i > /dev/null 2>&1; done

all_master_html_files=$(find . -type f -name "master.html")

export all_master_html_files

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

python $SCRIPT_DIR/link_checker.py
