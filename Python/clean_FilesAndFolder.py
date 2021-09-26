import os 
import time 
from datetime import datetime

DAYS = 5
FOLDERS = ["X:\Folders", "Z:\Folders"]
TOTAL_DELETED_SIZE = 0
TOTAL_DELETED_FILE = 0
TOTAL_DELETED_DIRS = 0

nowTime = time.time() #in seconds
ageTime = nowTime - 60*60*24*DAYS


def delete_files(folder):
    global TOTAL_DELETED_FILE
    global TOTAL_DELETED_SIZE

    for path, files in os.walk(folder):
        for file in files:
            fileName = os.path.join(path, file) #Full path to file
            fileTime_mod = os.path.getmtime(fileName)
            #fileTime_cr = os.path.getctime(fileName)
            if fileTime_mod < ageTime:
                TOTAL_DELETED_SIZE += os.path.getsize(fileName)
                TOTAL_DELETED_FILE += 1
                print(f"Deleting file: {fileName}")
                os.remove(fileName)

def delete_folders(folder):
    global TOTAL_DELETED_DIRS
    counter = 0
    for path, dirs, files in os.walk(folder):
        if not dirs and not files:
            TOTAL_DELETED_DIRS += 1
            counter += 1
            print(f"Deleting empty dir: {str(path)}")
            os.rmdir(path)
    if counter > 0:
        delete_folders(folder)

if __name__ == "__main__":
    start_time = datetime.now()

    for folder in FOLDERS:
        delete_files(folder)
        delete_folders(folder)
    print("-------------------------------")
    print("[INFO] Done by" + str(datetime.now() - start_time))
    print("[INFO] Total Deleted Size: " + str(int(TOTAL_DELETED_SIZE/1024/1024)) + "MB")
    print("[INFO] Total Deleted Files: " + str(TOTAL_DELETED_FILE))
    print("[INFO] Total Deleted Folders: " + str(TOTAL_DELETED_DIRS))
    print("-------------------------------")