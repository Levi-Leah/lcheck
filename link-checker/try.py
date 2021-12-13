#!/usr/bin/python3

import subprocess
import re
import urllib.request
from socket import timeout


class Regex:
    LINKS_AND_XREFS = re.compile(r'(?<=<a href=")[^\s]*(?=">)')


class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'



# find all the adoc files in the repo
def get_all_master_adoc_files():
    command = ("find . -type f -name 'master.adoc'")
    process = subprocess.run(command, stdout=subprocess.PIPE, shell=True).stdout
    all_master_adoc_files = process.strip().decode('utf-8').split('\n')

    return all_master_adoc_files


def build_all_master_adoc_files(master_adocs):
    for master in master_adocs:
        command = 'asciidoctor --safe -v -n {} > /dev/null 2>&1'.format(master_adocs)
        process = subprocess.run(command, stdout=subprocess.PIPE, shell=True).stdout


def get_all_master_html_files():
    command = ("find . -type f -name 'master.html'")
    process = subprocess.run(command, stdout=subprocess.PIPE, shell=True).stdout
    all_master_html_files = process.strip().decode('utf-8').split('\n')

    return all_master_html_files


def smth(master_htmls):

    for master in master_htmls:
        print(f"\nChecking {master}")
        with open(master, 'r') as file:
            original = file.read()
            links = re.findall(Regex.LINKS_AND_XREFS, original)
            for link in links:
                if not link.startswith('http'):
                    pass
                else:
                    req = urllib.request.Request(link, headers={'User-Agent': 'Mozilla/5.0'})
                    try:
                        urllib.request.urlopen(req, timeout=20)
                        print(f"\tOK {link}")
                    except urllib.error.HTTPError as e:
                        if e.code == 404:
                            print(bcolors.FAIL + '\tNA ' + link + bcolors.ENDC)


def main():
    all_master_adoc_files = get_all_master_adoc_files()

    print("Building master.adoc files...")
    #build_all_master_adoc_files(all_master_adoc_files)

    all_master_html_files = get_all_master_html_files()

    print("Gathering links...")

    all_links = smth(all_master_html_files)


main()
