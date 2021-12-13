#!/usr/bin/env python
from multiprocessing.pool import ThreadPool
from time import time as timer
from urllib2 import urlopen


urls = ["http://www.google.com", "http://www.apple.com", "http://www.microsoft.com", "http://www.amazon.com", "http://www.facebook.com"]


def fetch_url(url):
    try:
        response = urlopen(url)
        return url, response.read(), None
    except Exception as e:
        return url, None, e


start = timer()
results = ThreadPool(20).imap_unordered(fetch_url, urls)
for url, html, error in results:
    if error is None:
        print("%r fetched in %ss" % (url, timer() - start))
    else:
        print("error fetching %r: %s" % (url, error))
print("Elapsed Time: %s" % (timer() - start,))


from queue import Queue
from threading import Thread
import urllib.request

hosts = ["http://yahoo.com", "http://google.com", "http://amazon.com","http://ibm.com", "http://apple.com"]

queue = Queue()

class ThreadUrl(Thread):
   def __init__(self, queue):
       Thread.__init__(self)
       self.queue = queue

   def run(self):
      while True:
         host = self.queue.get()
         url=urllib.request.urlopen(host)
         print(url.read(512))
         self.queue.task_done()

def main():
    for i in range(5):
        t = ThreadUrl(queue)
        t.setDaemon(True)
        t.start()

    for host in hosts:
        queue.put(host)

    queue.join()

main()
