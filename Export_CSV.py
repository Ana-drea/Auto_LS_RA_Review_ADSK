import os, sys

all_files_root = sys.argv[1]

for root, dirs, files in os.walk(all_files_root):
    for file in files:
        if '.tbulic15' in file:
            tbulic_file_path = os.path.join(root, file)
            cmd = f"pslcmd /openproject:{tbulic_file_path} /runmacro:ExportScDump-all.bas"
            os.system(cmd)
            cmd = f"pslcmd /openproject:{tbulic_file_path} /runmacro:ExportScDump-review.bas"
            os.system(cmd)

