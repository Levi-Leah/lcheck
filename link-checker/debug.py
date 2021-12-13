#!/usr/bin/python3

import re
import urllib.request
import urllib.error
from queue import Queue
from threading import Thread
import concurrent.futures
from multiprocessing.pool import ThreadPool


class Regex:
    LINKS_AND_XREFS = re.compile(r'(?<=<a href=")[^\s]*(?=">)')


class bcolors:
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    OKGREEN = '\033[92m'


htmls = ['/home/levi/rhel-8-docs/rhel-8/titles/configuring-and-maintaining/managing-file-systems/master.html', '/home/levi/rhel-8-docs/rhel-8/titles/configuring-and-maintaining/configuring-and-managing-logical-volumes/master.html', '/home/levi/rhel-8-docs/rhel-8/titles/configuring-and-maintaining/deploying-different-types-of-servers/master.html', '/home/levi/rhel-8-docs/rhel-8/titles/configuring-and-maintaining/configuring-and-managing-networking/master.html', '/home/levi/rhel-8-docs/rhel-8/titles/configuring-and-maintaining/security-hardening/master.html', '/home/levi/rhel-8-docs/rhel-9/titles/configuring-and-maintaining/deploying-rhel-9-on-public-cloud-platforms/master.html']


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


def load_link(link):

    try:
        headers = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.11 (KHTML, like Gecko) Chrome/23.0.1271.64 Safari/537.11', 'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8', 'Accept-Charset': 'ISO-8859-1,utf-8;q=0.7,*;q=0.3', 'Accept-Encoding': 'none', 'Accept-Language': 'en-US,en;q=0.8', 'Connection': 'keep-alive'}
        opener = urllib.request.build_opener()
        link = opener.open(urllib.request.Request(link, headers=headers)).geturl()
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


def check_links(links_dict):

    for key in links_dict:
        print(f"Checking {key}")

        results = ThreadPool(20).imap_unordered(load_link, links_dict[key])

        for link, html, error, msg in results:
            if error:
                print(bcolors.FAIL + f'\t{msg}: {error}, {link}' + bcolors.ENDC)


def main():
    links_dict = get_links_dict(htmls)
    check_links(links_dict)

main()
