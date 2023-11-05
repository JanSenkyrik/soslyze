#!/usr/bin/python
import sys
import getopt
import os
from pathlib import Path


class c:  # terminar colors
    BLUE = '\033[0;34m'
    BOLD = '\033[1m'
    CYAN = '\033[01;36m'
    GREEN = '\033[0;32m'
    ORANGE = '\033[93m'
    PURPLE = '\033[0;35m'
    RED = '\033[0;31m'
    RESET = '\033[0m'
    UNDERLINE = '\033[4m'
    YELLOW = '\033[01;33m'


class facts:
    sospath = '.'


def showHelp(errmsg=""):
    print("\nUsage: " + os.path.basename(__file__) + " [Options] [SosreportPath]"  # noqa E501
          "\n  Arguments:"
          "\n    [SosreportPath]: Path to sosreport. (Defaults to current path)"  # noqa E501
          "\n  Options:"
          "\n    [-h|--help]: Show help.")
    if errmsg != "":
        print(f"{c.RED}\nERROR:{c.RESET}\n" + errmsg + "\n")
        sys.exit(1)


def getOpts():
    try:
        options, remainder = getopt.getopt(sys.argv[1:], 'h', ['help'])
        if len(remainder) > 0:  # set sosreport path
            facts.sospath = remainder[0]

        if not Path(facts.sospath + "/sos_reports").is_dir():  # exit if path is not a sosreport  # noqa E501
            showHelp("Sosreport path '" + facts.sospath + "' does not " +
                     "contain a valid sosreport folder. Exiting...")

        os.chdir(facts.sospath)  # change workdir to sosreport path

        # get command line options
        for opt, arg in options:
            if opt == '-h' or opt == '--help':
                showHelp()
    except Exception as e:
        print(e)


def main():
    print("Do all the work")


if __name__ == "__main__":
    getOpts()
    main()
