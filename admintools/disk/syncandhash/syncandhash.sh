#!/bin/bash
: '
bash version 4.4.12(1)

/*
Date: 13 Nov 2021 04:25:23.558525304
File: syncandhash.sh

Copyright Notice
This document is protected by the GNU General Public License v3.0.

This allows for commercial use, modification, distribution, patent and private
use of this software only when the GNU General Public License v3.0 and this
copyright notice are both attached in their original form.

For developer and author protection, the GPL clearly explains that there is no
warranty for this free software and that any source code alterations are to be
shown clearly to identify the original author as well as any subsequent changes
made and by who.

For any questions or ideas, please contact:
github:  https://github(dot)com/dnc77
email:   dnc77(at)hotmail(dot)com
web:     http://www(dot)dnc77(dot)com

Copyright (C) 2021 Duncan Camilleri, All rights reserved.
End of Copyright Notice

Performs an rsync vs two different directories and then hashes each and
reports hashsum to ensure both directories are the same.
Comments: Is this hashing really necessary? rsync typically does a great
            job but for reporting purposes having a hash on source and
            destination may be a good thing to confirm success. This is
            good for background backup purposes so that whenever a backup
            runs, one does not need to worry about completion status and
            can check the two hashes match after rsync. We did not notice
            any option to show hashsum resultant information using rsync
            and one hashsum for all the directory should be enough to
            justify the absence of a difference.

Version Control
Date        Description                                        Author
ages back   Initial developmet                                 Duncan
13 Nov 2021 Some date output fixes                             Duncan
17 Nov 2021 Stat log revised                                   Duncan
17 Nov 2021 Remove old log files                               Duncan
*/
'
# Dependencies deserving mention
# hashdir.sh v2.03.0003, nice, rsync, date
VERSION='v1.01.0003'

#
# User variables
#
# Source root folder
SRCROOT=
# Source parent folder (parent of folders to keep synced)
SRCDIR=
# Destination root folder
DSTROOT=
# Destination parent folder (parent of folders to keep synced)
DSTDIR=
# Space separated list of directories to sync in both SRCDIR and DSTDIR
HASHDIRS=""
# Output location for timestamp and log files.
OUTDIR=
# Main log file
LOGFILE=
# Source timestamps file
SRCTSFILE=
# Destination timestamps file
DSTTSFILE=
# Hash log file source path and prefix for each hashdir's hash log
SRCHASHLOGFILE=
# Hash log file destination path and prefix for each hashdir's hash log
DESTHASHLOGFILE=
# Hashdir script location.
HASH=

#
# Operational variables
#

# Tool configuration
RSYNCOPT="-rv --del --progress --size-only --inplace"    # -rvn simulate
RSYNCMODE="starting"  #"simulation"  # n option
DATEOPT="+%a %d %b %Y %H:%M:%S.%N"

# Tools
NICE=nice
RSYNC=rsync
DATE=date

#
# End of configurable options
#

# Locations.
CURPATH=`pwd`

# Remove any old log files.
rm -f "$LOGFILE"
rm -f "$SRCHASHLOGFILE"*
rm -f "$DESTHASHLOGFILE"*

# Keep track of time!
curdate=`$DATE "$DATEOPT"`
statLog="syncandhash statistics"
statLog="$statLog\n-----------------------\n\n"
statLog=s"$statLog\nstarted: $curdate"

# Prepare last sync information.
echo "Sync $RSYNCMODE at:  `$DATE "$DATEOPT"`" > $LOGFILE
# ls -lha $LOGFILE

# Fetch...
cd "$SRCDIR"
for x in $HASHDIRS; do
   echo
   echo >> "$LOGFILE"
   echo "--"
   echo "--" >> "$LOGFILE"
   echo "Syncing $x..."
   echo "Syncing $x..." >> "$LOGFILE"
   echo "--"
   echo "--" >> "$LOGFILE"
   echo
   echo >> "$LOGFILE"

   echo "sync $SRCDIR/$x with $DSTDIR/$x"
   echo "sync $SRCDIR/$x with $DSTDIR/$x" >> "$LOGFILE"

   # Run rsync...
   $NICE $RSYNC $RSYNCOPT "$SRCDIR/$x/" "$DSTDIR/$x/" 2>&1 >> "$LOGFILE"
   echo "sync complete - generate hashsums"
   echo "sync complete - generate hashsums" 2>&1 >> "$LOGFILE"

   # Keep track of time
   curdate=`$DATE "$DATEOPT"`
   statLog="$statLog sync ($x) completed: $curdate"

   # Generate source hashsums...
   OUTOPTS="-V$SRCHASHLOGFILE-$x.log -T$SRCTSFILE-$x.syn"
   SOURCEHASH=`$NICE "$HASH" $OUTOPTS "$SRCDIR/$x"`
   echo "source hashsum: $SOURCEHASH"
   echo "source hashsum: $SOURCEHASH" 2>&1 >> "$LOGFILE"

   # Keep track of time
   curdate=`$DATE "$DATEOPT"`
   statLog=$statLog"source hashsum ($x) generated: $curdate"

   # Generate destination hashsums...
   OUTOPTS="-V$DESTHASHLOGFILE-$x.log -T$DSTTSFILE-$x.syn"
   DESTHASH=`$NICE "$HASH" $OUTOPTS "$DSTDIR/$x"`
   echo "destination hashsum: $DESTHASH"
   echo "destination hashsum: $DESTHASH" 2>&1 >> "$LOGFILE"

   # Keep track of time
   curdate=`$DATE "$DATEOPT"`
   statLog=$statLog"dest hashsum ($x) generated: $curdate"

   # Report hashsum status...
   if [ $SOURCEHASH == $DESTHASH ]; then
      echo "$x hashsum match" 
      echo "$x hashsum match" >> $LOGFILE
   else
      echo "$x hashsum mismatch" 
      echo "$x hashsum mismatch" >> $LOGFILE
   fi
done

# Output stats.
curdate=`$DATE "$DATEOPT"`
statLog=$statLog"completed: `$DATE "$DATEOPT"`"
echo -e "$statLog"
echo -e "$statLog" >> $LOGFILE
