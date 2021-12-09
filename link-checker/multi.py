#!/usr/bin/python3

import subprocess
import re
import urllib.request
import urllib.error
from multiprocessing import Process


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
        commands = 'asciidoctor --safe -v -n {} > /dev/null 2>&1'.format(master)
        processes = [subprocess.Popen(commands, shell=True)]


def get_all_master_html_files():
    command = ("find . -type f -name 'master.html'")
    process = subprocess.run(command, stdout=subprocess.PIPE, shell=True).stdout
    all_master_html_files = process.strip().decode('utf-8').split('\n')

    return all_master_html_files


def load_link(link):
    req = urllib.request.Request(link, headers={'User-Agent': 'Mozilla/5.0'})
    req = urllib.request.urlopen(req)

    return req.readall()


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
                        req = urllib.request.urlopen(req)
                    except urllib.error.HTTPError as e:
                        print(bcolors.FAIL + '\tHTTPError: {}'.format(e.code) + ', ' + link + bcolors.ENDC)
                    except urllib.error.URLError as e:
                        print(bcolors.FAIL + '\tURLError: {}'.format(e.reason) + ', ' + link + bcolors.ENDC)


if __name__ == "__main__":
    all_master_adoc_files = get_all_master_adoc_files()

    print("Building master.adoc files...")
    build_all_master_adoc_files(all_master_adoc_files)

    all_master_html_files = get_all_master_html_files()

    print("Gathering links...")

    smth(all_master_html_files)
