#!/usr/bin/env python

'''
 Copyright (c) 2013, Lawrence Livermore National Security, LLC.
 Produced at the Lawrence Livermore National Laboratory (cf, DISCLAIMER).
 Written by Charles Heizer <heizer1 at llnl.gov>.
 LLNL-CODE-636469 All rights reserved.
 
 This file is part of MacPatch, a program for installing and patching
 software.
 
 MacPatch is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License (as published by the Free
 Software Foundation) version 2, dated June 1991.
 
 MacPatch is distributed in the hope that it will be useful, but WITHOUT ANY
 WARRANTY; without even the IMPLIED WARRANTY OF MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the terms and conditions of the GNU General Public
 License for more details.
 
 You should have received a copy of the GNU General Public License along
 with MacPatch; if not, write to the Free Software Foundation, Inc.,
 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
'''

import datetime
import logging
import os
import argparse
import plistlib
import sys
import subprocess
import hashlib

# Define logging for global use
logger = logging.getLogger('MPSyncContent')
logFile = "/Library/MacPatch/Server/Logs/MPSyncContent.log"

def main():
    '''Main command processing'''
    parser = argparse.ArgumentParser(description='Process some args.')
    parser.add_argument('--plist', help="MacPatch SUS Config file", required=False)
    parser.add_argument('--server', help="Rsync Server to Sync from.", required=False)
    parser.add_argument('--checksum', help='Use checksum verificartion', action='store_true')
    parser.add_argument('--dry', help="Outputs results, dry run.", required=False)
    args = parser.parse_args()

    # Rsync Path
    SYNC_DIR_NAME="mpContentWeb"
    # Rsync Server
    MASTER_SERVER="localhost"
    # Sync Content to...
    LOCAL_CONTENT="/Library/MacPatch/Content/Web"

    MP_SRV_BASE="/Library/MacPatch/Server"
    MP_SRV_CONF=MP_SRV_BASE+"/conf"
    MP_SYNC_PLIST=MP_SRV_CONF+"/etc/gov.llnl.mp.sync.plist"

    # Setup Logging
    try:
        hdlr = logging.FileHandler(logFile)
        formatter = logging.Formatter('%(asctime)s %(levelname)s --- %(message)s')
        hdlr.setFormatter(formatter)
        logger.addHandler(hdlr) 
        logger.setLevel(logging.INFO)

    except Exception, e:
        print "%s" % e
        sys.exit(1)

    # Set Default Values
    if args.checksum:
        useChecksum="-c"
    else:
        useChecksum=""

    # Set Default Values
    if args.dry:
        useDry="-n"
    else:
        useDry=""


    # Make Sure the Config Plist Exists
    if args.plist:
        if not os.path.exists(args.plist):
            print "Unable to open " + args.plist +". File not found."
            sys.exit(1)   

        # Read First Line to check and see if binary and convert
        infile = open(args.plist, 'r')
        if not '<?xml' in infile.readline():
            os.system('/usr/bin/plutil -convert xml1 ' + args.plist)
        
        # ReadPlist and create config Object
        rConfig = plistlib.readPlist(args.plist)
        

    logger.info('# ------------------------------------------------------')
    logger.info('# Starting content sync  '                               )
    logger.info('# ------------------------------------------------------')
    
    if args.server == None and args.plist != None:
        if rConfig != None:
            print rConfig
            if rConfig.has_key('MPServerAddress'):
                MASTER_SERVER = rConfig['MPServerAddress']
    
    if args.server:
        MASTER_SERVER = args.server

    if MASTER_SERVER == "localhost":
        logger.error("Error, localhost is not supported.")
        sys.exit(1)
    
    logger.info("Starting Content Sync")
    rStr = "-vai " + useDry + " " + useChecksum + " --delete-before --ignore-errors --exclude=.DS_Store " + MASTER_SERVER + "::" + SYNC_DIR_NAME + " " + LOCAL_CONTENT
    os.system('/usr/bin/rsync ' + rStr)
    logger.info("Content Sync Complete")

    
if __name__ == '__main__':
    main()