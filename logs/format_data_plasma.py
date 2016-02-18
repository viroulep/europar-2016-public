#!/usr/bin/env python
import itertools
import time
import subprocess
import glob
import sys
import os.path
from optparse import OptionParser


RHEADER = "Runtime WSselect WSpush WSpush_init Strict_Push Progname Size Blocksize Iterations Threads Gflops"
if __name__ == "__main__":
    parser = OptionParser()
    parser.add_option('-b', '--basename', dest='basename',
                      help='Basename of logfiles')
    (options, args) = parser.parse_args()
    if not options.basename:
        parser.error("Basename is required !")
    datafile = "rdata." + options.basename + ".dat"
    if os.path.isfile(datafile):
            print "Error : output datafile already exists (" + datafile + ")\n"
            sys.exit(1)
    subprocess.call("echo \"" + RHEADER + "\" > " + datafile, shell=True)
    for f in glob.glob(options.basename + ".*.log"):
        fileinfo = f.split(".")
        if len(fileinfo) != 8:
            print "Error : one filename isn't in the right format (" + f + ")\n"
            sys.exit(1)
        strict_numa = fileinfo[6]
        push_init = fileinfo[5]
        push = fileinfo[4]
        select = fileinfo[3]
        runtime = fileinfo[2]
        xpid = fileinfo[1]
        prependstring = runtime + " " + select + " " + push + " " + push_init + " " + strict_numa
        cmdLine = ("grep -v -i -e \"#\" -e \"KAAPI_\" -e \"OMP_\" -e \"OPENMP\" -e \"^$\" " + f + " | sed 's/^/"
                   + prependstring + " /' | sed 's/224 224/224/' | sed 's/128 128/128/' | sed 's/512 128/512/' | sed 's/256 256/256/' | sed 's/512 512/512/' | sed 's/1024 256/1024/' >> " + datafile)
        print cmdLine
        subprocess.call(cmdLine, shell=True)

    print "Done"

