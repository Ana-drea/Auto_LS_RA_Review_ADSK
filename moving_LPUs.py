import os
import shutil
import sys
import argparse




if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('--path', type=str, default=None)
    parser.add_argument('--lan', type=str, default=None)
    args = parser.parse_args()
    target_folder = args.path
    lan_list_str=args.lan
    length = len(lan_list_str)
    lan_list = lan_list_str[1:length-1].split(",")


    LPUs_Only_folder = os.path.join(target_folder,"LPUs_Only")
    print(LPUs_Only_folder)
    if not os.path.exists(LPUs_Only_folder):
        os.mkdir(LPUs_Only_folder)
    for lan in lan_list:
        #create subfolder for each language
        lan_subfolder = os.path.join(LPUs_Only_folder, lan)
        if not os.path.exists(lan_subfolder):
            os.mkdir(lan_subfolder)
            lpu_source_folder = os.path.join(target_folder,lan,"new")
            for filename in os.listdir(lpu_source_folder):
                if filename.endswith("ForLSReview.lpu"):
                    lpu_source_path = os.path.join(lpu_source_folder,filename)
                    shutil.copy(lpu_source_path,lan_subfolder)

    ALQM_folder = os.path.join(target_folder, "ForALQM")
    if not os.path.exists(ALQM_folder):
        os.mkdir(ALQM_folder)

