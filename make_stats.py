import re, os, sys

"""
Recursively parses statistics files (*_Statistics.txt) in given directory and creates summary statistics.
Only words are counted.
"""

# ########
# Consts #
# ########

STATS_FILE_PATTERN = '_Statistics.txt'
SUMMARY_STATS = 'Summary_stats.txt'
TO_TRANSLATE = 'Total new      to translate (w/o repeated):'
TOTAL_UPDATED = 'Total updated  to translate (w/o repeated):'
REPEATED = 'Total repeated to translate:'
TO_POST_EDIT = 'Total          to post-edit (MT):'
TO_REVIEW = 'Total          to review:'
SRC_NEW = 'Total src new:'
SRC_CHANGED = 'Total src changed:'
EST_TRANS_TIME = 'Estimated translation time'

# Charon-like column headers
charon_column_headers = [
    '',  # empty column for language
    'New',
    'Updated',
    'Repeated',
    'MT post edit',
    'To review',
    'Trans. time',
]

language_stats = list()


# #########
# Classes #
# #########

class Language_stat():
    """
    Covers statistics from all databases for given language
    """

    def __init__(self, language):
        self.language = language
        self.database_stats = list()
        self.to_translate = 0
        self.to_post_edit = 0
        self.to_review = 0
        self.src_new = 0
        self.src_changed = 0
        self.est_trans_time = 0
        self.total_updated = 0
        self.repeated = 0

    def reset_counters(self):
        self.to_translate = 0
        self.to_post_edit = 0
        self.to_review = 0
        self.src_new = 0
        self.src_changed = 0
        self.est_trans_time = 0
        self.total_updated = 0
        self.repeated = 0

    def get_database_stat_by_name(self, name):
        for database_stat in self.database_stats:
            if name.lower() == database_stat.database_name.lower():
                return database_stat
        return None

    def count_summary_stats(self):
        """
        Go via all lang stats and re-calculate summary statistics
        :return:
        """

        self.reset_counters()
        for database_stat in self.database_stats:
            self.to_translate += int(database_stat.to_translate)
            self.to_post_edit += int(database_stat.to_post_edit)
            self.to_review += int(database_stat.to_review)
            self.src_new += int(database_stat.src_new)
            self.src_changed += int(database_stat.src_changed)
            self.est_trans_time += float(database_stat.est_trans_time)
            self.total_updated += int(database_stat.total_updated)
            self.repeated += int(database_stat.repeated)

    def add_database_stat(self, database_stat):
        for stat_file in self.database_stats:
            if stat_file.stat_file_name == database_stat.stat_file_name:
                print("WARNING: Database stat %s was already added for %s language!\n" \
                      "Check the file structure for redundant stat files" \
                      % (stat_file_name, database_stat.language))
                return
        database_stat.parse_statistics()
        # add database stat under lang stat
        self.database_stats.append(database_stat)
        # recalculate summary statistics for given lang
        self.count_summary_stats()


class Database_stat():
    def __init__(self, stat_file):
        # as a stat name
        database_name = os.path.basename(stat_file)
        database_name = re.sub(r'(.*)'  # actual database name and anything beyond it
                               r'__\w{3}_Statistics.txt'  # last three letters + statistics.txt
                               , '\g<1>', database_name)

        self.database_name = database_name
        self.stat_file_name = stat_file
        self.to_translate = 0
        self.to_post_edit = 0
        self.to_review = 0
        self.src_new = 0
        self.src_changed = 0
        self.est_trans_time = 0
        self.total_updated = 0
        self.repeated = 0

    def parse_statistics(self):
        """
        Parses following stats from given file: to translate, to post edit, to review, src new, src changed
        :return:
        """

        stat_file = open(os.path.join(stats_files_dir, self.stat_file_name), 'r')
        for line in stat_file:
            if TO_TRANSLATE in line:
                self.to_translate = self.get_words_from_stats_file(line)
            elif TO_POST_EDIT in line:
                self.to_post_edit = self.get_words_from_stats_file(line)
            elif TO_REVIEW in line:
                self.to_review = self.get_words_from_stats_file(line)
            elif SRC_NEW in line:
                self.src_new = self.get_words_from_stats_file(line)
            elif SRC_CHANGED in line:
                self.src_changed = self.get_words_from_stats_file(line)
            elif EST_TRANS_TIME in line:
                self.est_trans_time = self.parse_est_trans_time(line)
            elif TOTAL_UPDATED in line:
                self.total_updated = self.get_words_from_stats_file(line)
            elif REPEATED in line:
                self.repeated = self.get_words_from_stats_file(line)

    def get_words_from_stats_file(self, line):
        match = re.match(r'.*:'  # everything before colon
                         r'\s+\d+\s+'  # rest of whitespaces and 'letters' category
                         r'(\d*)',  # words category
                         line)
        return match.group(1)

    def parse_est_trans_time(self, line):
        match = re.match(r'.*:\s*(.*)', line)
        return match.group(1)


# ############
# Functions #
# ############
def get_all_database_stats_name():
    """
    Go through all language stats and make a list of all available database stats
    :return:
    """

    all_databases_stats_names = set()
    for language_stat in language_stats:
        for database_stat in language_stat.database_stats:
            all_databases_stats_names.add(database_stat.database_name)
    return all_databases_stats_names


if __name__ == '__main__':
    if len(sys.argv) != 2:
        print('''
        Insufficient parameters

        Usage:
            make_stats.py dir_with_stats_files
        ''')


    def get_language_stat(language):
        lang_low = language.lower()

        for language_stat in language_stats:
            if lang_low == language_stat.language.lower():
                return language_stat
        return None


    stats_files_dir = sys.argv[1]

    # find all statistics file in given dir and parse it
    print("INFO: Collecting statistics from following directory: %s" % stats_files_dir)
    for root, dirs, files in os.walk(stats_files_dir):
        for stat_file_name in files:
            if STATS_FILE_PATTERN in stat_file_name:
                print(stat_file_name)
                database_stat = Database_stat(os.path.join(root, stat_file_name))
                language = 'none'
                language_stat = get_language_stat(language)
                if language_stat == None:
                    language_stat = Language_stat(language)
                    language_stats.append(language_stat)
                language_stat.add_database_stat(database_stat)

    # create CSV file for importing data into Charon
    charon_stats_file = os.path.join(stats_files_dir, SUMMARY_STATS)
    print("INFO: Summary stats written into %s" % charon_stats_file)
    summary_stats = """AUTODESK STATISTICS - VERSION: $Revision: 189 $

--------------------------------------------------------------------------------
------------------------------------- {} --------------------------------------
--------------------------------------------------------------------------------
                                                    [String]    [Word]    [Char]
Total new      to translate (w/o repeated):                0         {}         0
Total updated  to translate (w/o repeated):                0         {}         0
Total repeated to translate:                               0         {}         0
Total          to post-edit (MT):                          0        {}       0
Total          to review:                                  0         {}         0
--------------------------------------------------------------------------------
""".format(
        language,
        language_stat.to_translate,
        language_stat.total_updated,
        language_stat.repeated,
        language_stat.to_post_edit,
        language_stat.to_review,
    )

    with open(charon_stats_file, 'w') as charon_stats:
        charon_stats.write(summary_stats)
