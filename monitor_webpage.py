#!/usr/bin/env python3

import hashlib
from urllib.request import urlopen, Request
import ssl
from datetime import date

target_url = "https://pst.giustizia.it/PST/it/pst_3.wp"
# fix for ssl mishandling
ssl._create_default_https_context = ssl._create_unverified_context

# open stuff
url = Request(target_url,
              headers={'User-agent': 'Mozilla/5.0'})

response = urlopen(url).read()
currentHash = hashlib.sha1(response).hexdigest()

# create the log line
logline = (f"{currentHash} \n")

# find the last line of the log, by using the length of the list
file_log = open("/home/carlo/file.txt", "r")
line_list = file_log.readlines()
last_hash = line_list[len(line_list)-1]

# check if the current has is identical to the last recorded hash
if last_hash == logline:
    print("still current, do nothing")
    file_log.close()
    # write the date and the last found hash
else:
    today = date.today()
    print("New content", f"on {today}")
    print(logline)
    file_log = open("/home/carlo/file.txt", "a")
    file_log.write(f"New content on {today} \n")
    file_log.write(logline)

file_log.close()
