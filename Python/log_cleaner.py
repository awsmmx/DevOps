#!/bin/python3

from genericpath import isfile
import shutil
import os
import sys
import argparse

if len(sys.argv) < 4:
    print("Missing argument")
    sys.exit(1)

parser = argparse.ArgumentParser(description='Process some args.')
parser.add_argument("-f", "--file", help='file name')
parser.add_argument("-ls", "--limitsize", type=int, help='limit size for the file')
parser.add_argument("-ln", "--logsnumbers", type=int, help='size of log files number')

args = parser.parse_args()

file_name = args.file
limit_size = args.limitsize
logs_numbers = args.logsnumbers

if os.path.isfile(file_name) == True:
    logfile_size = os.stat(file_name).st_size // 1024

    if logfile_size >= limit_size:
        if logs_numbers > 0:
            for x in range(logs_numbers, 1, -1):
                src = file_name + "_" + str(x-1)
                dst = file_name + "_" + str(x)

                if os.path.isfile(src) == True:
                    shutil.copyfile(src,dst)
                    print(f"Copied: {src} to {dst}")
            shutil.copyfile(file_name, file_name + "_1")
            print(f"Copied {file_name}     to  {file_name}_1")
        f = open(file_name, "w")
        print(f"Main log file {file_name} is cleared")
        f.close