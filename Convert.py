"""
Convert all csv file from utf16 le to utf8, rename to file accepted by ALQM
"""

import os, sys, glob, codecs, ntpath





all_files_root = sys.argv[1]

for root, dirs, files in os.walk(all_files_root):
    for file in files:
        if '.csv' in file:

