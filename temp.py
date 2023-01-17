"""
do it all...
"""

import os, sys, shutil, glob, ntpath, codecs

curr_path = os.path.dirname(os.path.realpath(__file__))
all_files_root = r"C:\Users\AnZhou\Downloads\temp\LSReview\LPUs_Only"
final_files_root = r"c:\Users\AnZhou\Downloads\temp\LSReview\ForALQM"
make_stats_tool = os.path.join(curr_path, 'make_stats.py')


def get_new_csv_name(old_name):
    old_file_name = ntpath.basename(old_name)
    # we're assuming that bundle name look like chs_Rogue_Bin_ForLSReview.tbulic15
    lang = old_file_name[0: old_file_name.index('_')].upper()

    # remove extension
    new_file_name = os.path.splitext(old_file_name)[0]

    # remove lang
    new_file_name = new_file_name[new_file_name.index('_') + 1:]

    # Remove ForLSReview string
    new_file_name = new_file_name.replace("ForLSReview", '')

    # Replace underscores by nothing
    new_file_name = new_file_name.replace("_", '')

    # Add lang and extension
    new_file_name = f"{new_file_name}_{lang}.csv"

    return new_file_name


def convert_from_utf16_to_utf8(file_to_convert):
    orig_file_path = os.path.dirname(os.path.realpath(file_to_convert))
    orig_file = codecs.open(file_to_convert, 'r', encoding='utf-16le')
    new_file_name = get_new_csv_name(file_to_convert)
    new_file_path = os.path.join(orig_file_path, new_file_name)
    new_file = codecs.open(new_file_path, 'w', encoding='utf8')
    for line in orig_file:
        new_file.write(line)
    orig_file.close()
    new_file.close()
    os.unlink(file_to_convert)


if __name__ == '__main__':

    # Clear final directory
    if not os.path.exists(final_files_root):
        os.makedirs(final_files_root)
    else:
        shutil.rmtree(final_files_root)
        os.makedirs(final_files_root)

    # For every *LSReview*LPU file in given lang dir
    for root, dirs, files in os.walk(all_files_root):
        # dir represents one language
        for dir in dirs:
            lang_dir = os.path.join(root, dir)
            lpus = glob.glob(os.path.join(lang_dir, '*_ForLSReview.lpu'))
            for lpu in lpus:
                lpu_file_path = os.path.join(root, lpu)
                print(f"Processing {lpu_file_path}")

                # Reference file contains all strings from the bundle
                cmd = f"pslcmd /openproject:{lpu_file_path} /runmacro:ExportScDump-all.bas"
                os.system(cmd)

                # Review file contains only forreview strings.
                cmd = f"pslcmd /openproject:{lpu_file_path} /runmacro:ExportScDump-review.bas"
                os.system(cmd)

                # Export statistics
                # Review file contains only forreview strings.
                cmd = f"pslcmd /openproject:{lpu_file_path} /runmacro:AdskStatisticsTrn_WriteStats.bas"
                os.system(cmd)

            # Convert CSV files from utf16le to utf8
            csv_files = glob.glob(os.path.join(lang_dir, '*.csv'))
            for csv in csv_files:
                convert_from_utf16_to_utf8(csv)

            print("starting make_stats.py...")
            os.system(f"{make_stats_tool} {lang_dir}")
            print("make_stats.py done running")
            # Move final files (CVS, reference CSV, summary file)
            # Create lang dir under final
            final_lang_dir = os.path.join(final_files_root, dir)
            os.makedirs(final_lang_dir)
            final_lang_reference_dir = os.path.join(final_lang_dir, 'reference')
            os.makedirs(final_lang_reference_dir)

            summary_stats_file = os.path.join(lang_dir, 'Summary_stats.txt')
            shutil.move(summary_stats_file, os.path.join(final_lang_reference_dir, 'Summary_stats.txt'))

            reference_files = glob.glob(os.path.join(lang_dir, '*reference*.csv'))
            for reference_file in reference_files:
                shutil.move(reference_file, os.path.join(final_lang_reference_dir, ntpath.basename(reference_file)))

            final_csv_files = glob.glob(os.path.join(lang_dir, '*.csv'))
            for final_csv_file in final_csv_files:
                shutil.move(final_csv_file, os.path.join(final_lang_dir, ntpath.basename(final_csv_file)))
