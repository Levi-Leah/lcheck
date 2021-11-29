#!/usr/bin/python3

import re
import subprocess
import sys
import fileinput


# defining main pattern to search for (string), pattern to search within the main pattern,(substring), and the replacement pattern to change the substring to (replacement substring)
class Regex:
    """Compiles patterns used."""
    REPLACEMENT_SUBSTRING = re.compile(r'\{ProductNumberLink\}')
    SUBSTRING = re.compile(r'\{ProductNumber\}')
    MAIN_STRING = re.compile(r'(?:https?|file|ftp|irc):\/\/[^\s\[\]<]*\[')


# find all the adoc files in the repo
def get_all_adoc_files():
    """Returnes a list of all adoc files."""
    command = ("find . -type f -name '*.adoc'")
    process = subprocess.run(command, stdout=subprocess.PIPE, shell=True).stdout
    adoc_files = process.strip().decode('utf-8').split('\n')

    return adoc_files


# replace substring
def replace_all():
    """Replaces all matching substrings."""
    # if substring and the replacement substring don't need to be compiled, they can be defined here
    substring = '{ProductNumber}'
    replacement_substring = '{ProductNumberLink}'

    adoc_files = get_all_adoc_files()

    for path in adoc_files:

        for line in fileinput.input(path, inplace=1):
            matches = Regex.MAIN_STRING.findall(line)
            for i in matches:
                if i in line:
                    updates = [str.replace(substring, replacement_substring) for str in matches]
                    for i, _ in enumerate(matches):
                        line = line.replace(matches[i], updates[i])
            sys.stdout.write(line)


replace_all()
