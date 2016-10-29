#!/usr/bin/python
#
# dql.py
#

from bcc import BPF
from ctypes import c_ushort, c_int, c_ulonglong
from time import sleep
from sys import argv

def usage():
    print("USAGE: %s [interval [count]]" % argv[0])
    exit()

# arguments
interval = 5
count = -1
if len(argv) > 1:
    try:
        interval = int(argv[1])
        if interval == 0:
            raise
        if len(argv) > 2:
            count = int(argv[2])
    except:
        usage()

# load BPF program
b = BPF(src_file = "dql.c")
b.attach_kretprobe(event="dql_completed", fn_name="do_return_completed")

# header
print("Tracing... Hit Ctrl-C to end.")

# output
loop = 0
do_exit = 0
while (1):
    if count > 0:
        loop += 1
        if loop > count:
            exit()
    try:
        sleep(interval)
    except KeyboardInterrupt:
        pass; do_exit = 1

    print
    limits = b.get_table("limit")
    lowest_slacks = b.get_table("lowest_slack")
    for k, v in limits.items():
        print("%10d limit: %d bytes" % (v.value, k.value))
    for k, v in lowest_slacks.items():
        print("%10d lowest slacks: %d bytes" % (v.value, k.value))
    b["limit"].clear()
    b["lowest_slack"].clear()
    if do_exit:
        exit()
