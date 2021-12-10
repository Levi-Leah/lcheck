#!/usr/bin/python3

import subprocess
import re
import urllib.request
import urllib.error
import queue
from threading import Thread


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
        process = subprocess.Popen(commands, shell=True)


def get_all_master_html_files():
    command = ("find . -type f -name 'master.html'")
    process = subprocess.run(command, stdout=subprocess.PIPE, shell=True).stdout
    all_master_html_files = process.strip().decode('utf-8').split('\n')

    return all_master_html_files


def check_links(links):
    for link in links:
        if not link.startswith('http'):
            pass
        else:
            request = urllib.request.Request(link, headers={'User-Agent': 'Mozilla/5.0'})
            try:
                response = urllib.request.urlopen(request)
            except urllib.error.HTTPError as e:
                if e.code == 429:
                    pass
                else:
                    print(bcolors.FAIL + '\tHTTPError: {}'.format(e.code) + ', ' + link + bcolors.ENDC)
            except urllib.error.URLError as e:
                print(bcolors.FAIL + '\tURLError: {}'.format(e.reason) + ', ' + link + bcolors.ENDC)


def perform_web_requests(addresses, no_workers):
    class Worker(Thread):
        def __init__(self, request_queue):
            Thread.__init__(self)
            self.queue = request_queue
            self.results = []

        def run(self):
            while True:
                content = self.queue.get()
                if content == "":
                    break
                check_links(content)
                self.queue.task_done()

    # Create queue and add addresses
    q = queue.Queue()
    for url in addresses:
        q.put(url)

    # Create workers and add tot the queue
    workers = []
    for _ in range(no_workers):
        worker = Worker(q)
        worker.start()
        workers.append(worker)
    # Workers keep working till they receive an empty string
        for _ in workers:
            q.put("")
    # Join workers to wait till they finished
    for worker in workers:
        worker.join()

    # Combine results from all workers
    r = []
    for worker in workers:
        r.extend(worker.results)
    return r


def uniq(list):
    last = object()
    for item in list:
        if item == last:
            continue
        yield item
        last = item


def sort_and_deduplicate(l):
    return list(uniq(sorted(l, reverse=True)))

def get_links(master_htmls):
    links = []
    Dict = {}

    for master in master_htmls:
        #print(f"Checking {master}")
        with open(master, 'r') as file:
            original = file.read()
            links.append(re.findall(Regex.LINKS_AND_XREFS, original))

            Dict[master] = links

    return Dict


def get_unique_links(links):
    unique_links = []
    for link in links:
        if link.startswith('http'):
            if link not in unique_links:
                unique_links.append(link)

    return unique_links


#perform_web_requests(links, 20)


if __name__ == "__main__":
    all_master_adoc_files = get_all_master_adoc_files()

    print("Building master.adoc files...")
    build_all_master_adoc_files(all_master_adoc_files)

    all_master_html_files = get_all_master_html_files()

    print("Gathering links...")

    links = get_links(all_master_html_files)

    for key in links:
        print(key)
