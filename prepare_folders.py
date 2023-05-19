import os.path
import shutil
import sys
import argparse

Moldflow_lan_list = ["chs",
                     "cht",
                     "fra",
                     "deu",
                     "ita",
                     "jpn",
                     "kor",
                     "ptg",
                     "esn"]

LSR_tool_folder = r"C:\tools\LSReview"

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('--path', type=str, default=None)
    parser.add_argument('--lan', type=str, default=None)
    args = parser.parse_args()
    target_folder = args.path
    lan_list_str=args.lan
    length = len(lan_list_str)
    lan_list = lan_list_str[1:length-1].split(",")

    for lan in lan_list:
        #create subfolder for each language
        lan_subfolder = os.path.join(target_folder, lan)
        if not os.path.exists(lan_subfolder):
            os.mkdir(lan_subfolder)
        #copy the necessary batch file under language subfolder
        shutil.copy("DiffLpuLS.bat", lan_subfolder)
        shutil.copy("DiffLpuWrapper.bat", lan_subfolder)
        #create old and new folder under language subfolder to put old and new lpus
        old_folder = os.path.join(lan_subfolder, "old")
        new_folder = os.path.join(lan_subfolder, "new")
        if not os.path.exists(old_folder):
            os.mkdir(old_folder)
        if not os.path.exists(new_folder):
            os.mkdir(new_folder)
        #copy DiffLpuLS.bat to new folder
        shutil.copy("DiffLpuLS.bat", new_folder)
        for filename in os.listdir(target_folder):
            if filename.startswith("old"):
                #copy old lpu to old folder, and rename it with 3 letter language code e.g. chs_All_Moldflow.lpu
                lpu_full_path = os.path.join(target_folder, filename)
                lpu_name_with_lan_code = lan + "_" + filename.split("old_")[1]
                lpu_destination = os.path.join(old_folder, lpu_name_with_lan_code)
                shutil.copyfile(lpu_full_path, lpu_destination)
                print(lpu_name_with_lan_code+" copied")
            if filename.startswith("NEW") or filename.startswith("new"):
                # copy new lpu to new folder, and rename it with 3 letter language code e.g. chs_All_Moldflow.lpu
                lpu_full_path = os.path.join(target_folder, filename)
                lpu_name_with_lan_code = lan + "_" + filename.split("new_")[1]
                lpu_destination = os.path.join(new_folder, lpu_name_with_lan_code)
                shutil.copyfile(lpu_full_path, lpu_destination)
                print(lpu_name_with_lan_code + " copied")


