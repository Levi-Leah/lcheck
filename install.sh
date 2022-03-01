#!/bin/bash

path_to_script="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"
lcheck=$path_to_script'/lcheck.sh'
dependencies="linkchecker asciidoctor"

for i in $dependencies; do
    if command -v $i >/dev/null 2>&1 ; then
        :
    else
        sudo yum install $i -y
    fi
done

if [ "grep lcheck.sh ~/.bashrc" ]; then
    sed -i "\|lcheck.sh|d" ~/.bashrc
    echo 'alias lcheck="'$lcheck'"' >> ~/.bashrc
    source ~/.bashrc
else
    echo 'alias lcheck="'$lcheck'"' >> ~/.bashrc
    source ~/.bashrc
fi
