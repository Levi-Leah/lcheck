#!/bin/bash

path_to_script="$(realpath $(dirname "$0"))"
lcheck=$path_to_script'/lcheck.sh'
dependencies="linkchecker asciidoctor"

for i in $dependencies; do
    if command -v $i >/dev/null 2>&1 ; then
        :
    else
        sudo yum install $i -y
    fi
done

sed -i "\|lcheck\.sh|d" ~/.bashrc

echo 'alias lcheck="'$lcheck'"' >> ~/.bashrc
source ~/.bashrc
