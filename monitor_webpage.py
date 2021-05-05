#!/usr/bin/env python3

import hashlib
from urllib.request import urlopen, Request
import ssl
from datetime import date
from pathlib import Path

# List of current URL to check
target_url = ["https://pst.giustizia.it/PST/it/pst_3.wp",
              "https://www.piana.eu",
              "https://www.amici-oncologia.it/donazioni",
              ]
# fix for ssl mishandling
ssl._create_default_https_context = ssl._create_unverified_context

# open stuff


def change_check(page):
    url = Request(page,
                  headers={'User-agent': 'Mozilla/5.0'})
    p = Path(page)
    unique_name = p.stem
    file_name = (f"/home/carlo/{unique_name}_log.log")
    print(file_name)
    response = urlopen(url).read()
    currentHash = hashlib.sha1(response).hexdigest()
    # create the log line
    logline = (f"{currentHash} \n")
    # find the last line of the log, by using the length of the list

    file_log = open(file_name, "a")
    file_log.close()

    file_log = open(file_name, "r")
    line_list = file_log.readlines()

    print("length of the file is ", len(line_list))

    # Check if file is new, put some content in it in case
    while len(line_list) <= 1:
        file_log = open(file_name, "a")
        file_log.write("beginning of file \n start \n")
        file_log.close()
        file_log = open(file_name, "r")
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
        file_log = open(file_name, "a")
        file_log.write(f"New content on {today} \n")
        file_log.write(logline)

    file_log.close()


for i in target_url:
    change_check(i)
