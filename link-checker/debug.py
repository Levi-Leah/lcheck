#!/usr/bin/python3

import re
import urllib.request
import urllib.error
import threading
import queue
import concurrent.futures


class Regex:
    LINKS_AND_XREFS = re.compile(r'(?<=<a href=")[^\s]*(?=">)')


class bcolors:
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    OKGREEN = '\033[92m'


htmls = ['/home/levi/rhel-8-docs/rhel-8/titles/configuring-and-maintaining/managing-file-systems/master.html', '/home/levi/rhel-8-docs/rhel-8/titles/configuring-and-maintaining/configuring-and-managing-logical-volumes/master.html', '/home/levi/rhel-8-docs/rhel-8/titles/configuring-and-maintaining/deploying-different-types-of-servers/master.html', '/home/levi/rhel-8-docs/rhel-8/titles/configuring-and-maintaining/configuring-and-managing-networking/master.html', '/home/levi/rhel-8-docs/rhel-8/titles/configuring-and-maintaining/security-hardening/master.html', '/home/levi/rhel-8-docs/rhel-8/titles/configuring-and-maintaining/configuring-rhel-8-for-sap-hana-2-installation/master.html']


def get_links_dict(master_htmls):
    links_dict = {}

    for master in master_htmls:
        with open(master, 'r') as file:
            original = file.read()
            matches = re.findall(Regex.LINKS_AND_XREFS, original)

            for m in matches[:]:
                if m.startswith('#'):
                    matches.remove(m)

            # remove dublicate entries per master
            matches = list(dict.fromkeys(matches))

            links_dict[master] = matches

    return links_dict


def load_request(link):
    headers = {'User-Agent': 'Mozilla/5.0'}
    request = urllib.request.Request(link, headers=headers)
    return request


def load_link(req, timeout):
    with urllib.request.urlopen(req, timeout=timeout) as response:
        return response.read()


def check_links(links_dict):

    for key in links_dict:
        print(f"Checking {key}")

        for link in links_dict[key]:
            request = load_request(link)
            try:
                load_link(request, 60)
            except urllib.error.HTTPError as e:
                if e.code == 429:
                    pass
                else:
                    print(bcolors.FAIL + '\tHTTPError: {}'.format(e.code) + ', ' + link + bcolors.ENDC)
            except urllib.error.URLError as e:
                print(bcolors.FAIL + '\tURLError: {}'.format(e.reason) + ', ' + link + bcolors.ENDC)
            else:
                print(bcolors.OKGREEN + '\tOK: ' + link + bcolors.ENDC)


def main():
    links_dict = get_links_dict(htmls)
    check_links(links_dict)


main()
