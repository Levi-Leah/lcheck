#!/bin/bash
# link-checker.sh does the following:
# gathers all master.adoc files in the repo
# builds all the master.adoc files with asciidoctor
# saves all the master.html files in a var and passes them to the link_checker.py

all_master_adoc_files=$(echo /home/levi/rhel-8-docs/rhel-9/titles/planning/getting-the-most-from-your-support-experience/master)

echo "Building files..."
asciidoctor --safe -v -n $all_master_adoc_files.adoc > /dev/null 2>&1

all_master_html_files=$(echo $all_master_adoc_files.html)

echo "$all_master_html_files"

export all_master_html_files

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

python $SCRIPT_DIR/link_checker.py
