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

Nastran_lan_list = ["chs",
                    "cht",
                    "fra",
                    "deu",
                    "ita",
                    "jpn",
                    "kor"]

CFD_lan_list = ["chs",
                "cht",
                "fra",
                "deu",
                "ita",
                "jpn",
                "kor",
                "rus"]

lan_list_dict = {
    "Moldflow": Moldflow_lan_list,
    "Nastran": Nastran_lan_list,
    "CFD": CFD_lan_list
}


def create_Moldflow_mapping_file(parent_folder, lan):
    full_path = os.path.join(parent_folder, "mapping.txt")
    file = open(full_path, "w")
    file.write(
        "ACTION	PREVIOUS LPU NAME	CURRENT LPU NAME	PREVIOUS SRCLST NAME	CURRENT SRCLST NAME		\n")
    file.write(
        "LPURENAME	%s_All_Moldflow	%s_All_Moldflow" % (lan, lan))
    file.close()


def create_Nastran_mapping_file(parent_folder, lan):
    full_path = os.path.join(parent_folder, "mapping.txt")
    file = open(full_path, "w")
    file.write(
        "ACTION	PREVIOUS LPU NAME	CURRENT LPU NAME	PREVIOUS SRCLST NAME	CURRENT SRCLST NAME		\n")
    file.write(
        "LPURENAME	%s_All_Nastran_InCAD	%s_All_Nastran_InCAD" % (lan, lan))
    file.close()

def create_CFD_mapping_file(parent_folder, lan):
    full_path = os.path.join(parent_folder, "mapping.txt")
    file = open(full_path, "w")
    file.write(
        "ACTION	PREVIOUS LPU NAME	CURRENT LPU NAME	PREVIOUS SRCLST NAME	CURRENT SRCLST NAME		\n")
    file.write(
        "LPURENAME	%s_All_CFD360	%s_All_CFD360" % (lan, lan))
    file.close()

if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('--path', type=str, default=None)
    parser.add_argument('--project', type=str, default=None)
    args = parser.parse_args()
    target_folder = args.path
    project = args.project
    lan_list = lan_list_dict[project]

    for lan in lan_list:
        # create subfolder for each language
        lan_subfolder = os.path.join(target_folder, lan)
        if not os.path.exists(lan_subfolder):
            os.mkdir(lan_subfolder)
        # create old and new folder under language subfolder to put old and new lpus
        old_folder = os.path.join(lan_subfolder, "LastReleaseLpu")
        new_folder = os.path.join(lan_subfolder, "CurrentReleaseLpu")
        if not os.path.exists(old_folder):
            os.mkdir(old_folder)
        if not os.path.exists(new_folder):
            os.mkdir(new_folder)
        # create mapping file
        if project == "Moldflow":
            create_Moldflow_mapping_file(new_folder, lan)
        elif project == "Nastran":
            create_Nastran_mapping_file(new_folder, lan)
        elif project == "CFD":
            create_CFD_mapping_file(new_folder, lan)

        for filename in os.listdir(target_folder):
            if filename.startswith("old"):
                # copy old lpu to LastReleaseLpu folder, and rename it with 3 letter language code e.g. chs_All_Moldflow.lpu
                lpu_full_path = os.path.join(target_folder, filename)
                lpu_name_with_lan_code = lan + "_" + filename.split("old_")[1]
                lpu_destination = os.path.join(old_folder, lpu_name_with_lan_code)
                shutil.copyfile(lpu_full_path, lpu_destination)
                print(lpu_name_with_lan_code + " copied")
            if filename.startswith("new"):
                # copy new lpu to LastReleaseLpu folder, and rename it with 3 letter language code e.g. chs_All_Moldflow.lpu
                lpu_full_path = os.path.join(target_folder, filename)
                lpu_name_with_lan_code = lan + "_" + filename.split("new_")[1]
                lpu_destination = os.path.join(new_folder, lpu_name_with_lan_code)
                shutil.copyfile(lpu_full_path, lpu_destination)
                print(lpu_name_with_lan_code + " copied")

