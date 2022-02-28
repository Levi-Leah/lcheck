#!/bin/bash

path_to_script="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"
lcheck=$path_to_script'/lcheck.sh'

# install dependencies
sudo yum install -y linkchecker asciidoctor

if [ "grep $lcheck ~/.baschrc" ]; then
    sed -i "\|${lcheck}|d" ~/.bashrc
    echo 'alias lcheck="'$lcheck'"' >> ~/.bashrc
    source ~/.bashrc
else
    echo 'alias lcheck="'$lcheck'"' >> ~/.bashrc
    source ~/.bashrc
fi
