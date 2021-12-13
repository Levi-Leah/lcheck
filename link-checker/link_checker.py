#!/usr/bin/python3

import subprocess
import re
import urllib.request
import urllib.error
from multiprocessing.pool import ThreadPool
import http.client


class Regex:
    LINKS_AND_XREFS = re.compile(r'(?<=<a href=")[^\s]*(?=">)')
    ATTRIBUTE = re.compile(r'{[^\s]*?}')


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
                # TODO: remove localhost

            # remove dublicate entries per master
            matches = list(dict.fromkeys(matches))

            links_dict[master] = matches

    return links_dict


'''def resolve_redirect(link):
    if re.findall(Regex.ATTRIBUTE, link):
        return link
    else:
        command = ('curl -Ls -o /dev/null -w %{url_effective} ' + '"' + link + '"')

        process = subprocess.run(command, stdout=subprocess.PIPE, shell=True).stdout
        final_link = ''.join(process.strip().decode('utf-8').split('\n'))

        return final_link'''


def resolve_redirect(link):
    headers = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.64 Safari/537.11', 'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8', 'Accept-Charset': 'ISO-8859-1,utf-8;q=0.7,*;q=0.3', 'Accept-Encoding': 'none', 'Accept-Language': 'en-US,en;q=0.8', 'Connection': 'keep-alive'}
    opener = urllib.request.build_opener()
    link = opener.open(urllib.request.Request(link, headers=headers)).geturl()

    return link


def load_link(link):

    try:
        headers = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.64 Safari/537.11', 'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8', 'Accept-Charset': 'ISO-8859-1,utf-8;q=0.7,*;q=0.3', 'Accept-Encoding': 'none', 'Accept-Language': 'en-US,en;q=0.8', 'Connection': 'keep-alive'}

        link = resolve_redirect(link)

        request = urllib.request.Request(link, headers=headers)
        response = urllib.request.urlopen(request)

        return link, response.read(), None, True
    except urllib.error.HTTPError as e:
        if e.code == 429:
            pass
        else:
            return link, None, e.code, 'HTTPError'
    except urllib.error.URLError as e:
        return link, None, e.reason, 'URLError'
    except http.client.IncompleteRead as e:
        pass


def check_links(links_dict):

    for key in links_dict:
        print(f"Checking {key}")

        results = ThreadPool(20).imap_unordered(load_link, links_dict[key])

        for link, html, error, msg in results:
            if error:
                print(bcolors.FAIL + f'\t{msg}: {error}, {link}' + bcolors.ENDC)


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
