#!python

import os
import re
import platform
from shutil import copy2, rmtree, copytree
from glob import iglob
import tarfile
from pathlib import Path

# ----------------------------------
# Definitions:
# ----------------------------------

# Game Script name
gs_name = "Growth_Requires_Networking_2"

# Directory where the final tar should go
GSdir = r"C:\Users\Callum-Home\Documents\OpenTTD\game"

# ----------------------------------


# Script:
mainversion = -1
subversion = -1
with open("version.nut", 'r+') as file:
    for line in file:
        r = re.search('SELF_MAJORVERSION\\s+<-\\s+([0-9]+)', line)
        if(r != None):
            mainversion = r.group(1)
        r2 = re.search('SELF_MINORVERSION\\s+<-\\s+([0-9]+)', line)
        if(r2 != None):
            subversion = r2.group(1)

if(mainversion == -1 or subversion == -1):
    print("Couldn't find " + gs_name + " version in info.nut!")
    exit(-1)

tmp_dir = gs_name + "-" + str(mainversion) + "." + str(subversion)
tar_name = tmp_dir + ".tar"
tar_path = os.path.join(GSdir, tar_name)

# Ensure GS directory exists
os.makedirs(GSdir, exist_ok=True)

if os.path.exists(tmp_dir):
    rmtree(tmp_dir)
os.mkdir(tmp_dir)

files = iglob("*.nut")
for file in files:
    if os.path.isfile(file):
        copy2(file, tmp_dir)

copy2('readme.txt', tmp_dir)
copy2('changelog.txt', tmp_dir)
copytree('lang', os.path.join(tmp_dir, 'lang'))

for f in os.listdir(GSdir):
    if f.startswith(gs_name) and f.endswith(".tar"):
        os.remove(os.path.join(GSdir, f))

with tarfile.open(tar_path, "w:") as tar_handle:
    for root, dirs, files in os.walk(tmp_dir):
        for file in files:
            tar_handle.add(os.path.join(root, file))

rmtree(tmp_dir)

print(f"Created {tar_path}")