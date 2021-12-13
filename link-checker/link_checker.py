#!/usr/bin/python3

import subprocess
import re
import urllib.request
import urllib.error
import concurrent.futures


class Regex:
    LINKS_AND_XREFS = re.compile(r'(?<=<a href=")[^\s]*(?=">)')


class bcolors:
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    OKGREEN = '\033[92m'


# find all the adoc files in the repo
def get_all_master_adoc_files():
    command = ("find . -type f -name 'master.adoc'")
    process = subprocess.run(command, stdout=subprocess.PIPE, shell=True).stdout
    all_master_adoc_files = process.strip().decode('utf-8').split('\n')

    return all_master_adoc_files


def build_all_master_adoc_files(master_adocs):
    for master in master_adocs:
        commands = 'asciidoctor --safe -v -n {} > /dev/null 2>&1'.format(master)
        process = subprocess.Popen(commands, shell=True)


def get_all_master_html_files():
    command = ("find . -type f -name 'master.html'")
    process = subprocess.run(command, stdout=subprocess.PIPE, shell=True).stdout
    all_master_html_files = process.strip().decode('utf-8').split('\n')

    return all_master_html_files


def get_links_dict(master_htmls):
    links_dict = {}

    for master in master_htmls:
        with open(master, 'r') as file:
            original = file.read()
            matches = re.findall(Regex.LINKS_AND_XREFS, original)

            for m in matches[:]:
                if not m.startswith('http'):
                    matches.remove(m)

            # remove dublicate entries per master
            matches = list(dict.fromkeys(matches))

            links_dict[master] = matches

    return links_dict


def load_link(link, timeout):
    headers = {'User-Agent': 'Mozilla/5.0'}
    request = urllib.request.Request(link, headers=headers)

    with urllib.request.urlopen(request, timeout=timeout) as response:
        return response.read()


def check_links(links_dict):

    for key in links_dict:
        print(f"Checking {key}")

        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            future_to_link = {executor.submit(load_link, link, 60): link for link in links_dict[key]}
            for future in concurrent.futures.as_completed(future_to_link):
                link = future_to_link[future]
                try:
                    data = future.result()
                except urllib.error.HTTPError as e:
                    if e.code == 429:
                        pass
                    else:
                        print(bcolors.FAIL + '\tHTTPError: {}'.format(e.code) + ', ' + link + bcolors.ENDC)
                except urllib.error.URLError as e:
                    print(bcolors.FAIL + '\tURLError: {}'.format(e.reason) + ', ' + link + bcolors.ENDC)


def main():
    print('Serching for master.adoc files...')
    master_adoc_files = get_all_master_adoc_files()
    print('Building master.adoc files...')
    build_all_master_adoc_files(master_adoc_files)
    print('Gathering master.html files...')
    master_html_files = get_all_master_html_files()
    print('Gathering links...')
    links_dict = get_links_dict(master_html_files)
    print('Checking links...')
    check_links(links_dict)
    print('DONE')


main()
