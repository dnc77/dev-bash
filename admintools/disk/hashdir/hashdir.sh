#!/bin/bash
: '
bash version 4.4.12(1)

/*
Date: 13 Nov 2021 10:32:08.965548516
File: hashdir.sh

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

Hashes a directory
Version Control
Date         Description                                        Author
ages back    Initial developmet                                 Duncan
22 Oct 2021  Display final hash                                 Duncan 
07 Nov 2021  Introduce use/create timestamp file                Duncan
07 Nov 2021  Removed hash file functionality                    Duncan
07 Nov 2021  Speeded up createTmpStampfile with grep            Duncan
09 Nov 2021  Log messages changed to reflect upcoming events    Duncan
09 Nov 2021  After time stamps newly created, do not process    Duncan
10 Nov 2021  Introduced log verbose messages to file            Duncan
11 Nov 2021  Optimized for better speed - still not happy       Duncan
12 Nov 2021  Added notable dependencies                         Duncan
13 Nov 2021  Added copyright header                             Duncan

Dependencies deserving mention
mktemp, trap, grep, stat --format="%Y:%s, find, md5sum 

*/
'
# Default settings
OLDIFS=$IFS
IFS=$'\n'
VERSION='v2.03.0003'

function usage {
   echo "$0 $VERSION Usage:"
   echo "$0 [-T<file>] [-v] [-l] [directory]"
   echo "-l          show list of hashed files and their hash"
   echo "-T<file>    use/create a timestamps file"
   echo "-v          verbose: show log messages"
   echo "-V<file>    verbose to file: like -v but output goes to file instead."
}

function toHashfile {
   if [[ -n "$2" ]]; then
      echo "$1" >> "$2"
   fi
}

# Globals
DIR='./'
CURPATH=`pwd`
SHOWLIST=0
TIMESTAMP=0
TIMESTAMPFILECREATE=0
TIMESTAMPFILE=''
VERBOSE=0
VERBOSEFILE=''

# Temp files
FILELIST=`mktemp`
HASHES=`mktemp`
trap "rm -f $FILELIST $HASHES" exit

#
# Message reporting.
#

function errMsg {
   echo "error: $1"
}

function logMsg {
   if [[ $VERBOSE -ne 0 ]]; then
      echo "info: $1"
   fi

   if [[ ! -z "$VERBOSEFILE" ]]; then
      echo "info: $1" >> $VERBOSEFILE
   fi
}

#
# Command line.
#

function parseCmdline {
   # Get Command line options...
   while [ -n "$1" ]; do
      if [[ "$1" = -T* ]]; then
         TIMESTAMPFILE="${1##-T}"
         TIMESTAMP=1
         logMsg "timestamps enabled."   
         if [[ ! -e "$TIMESTAMPFILE" ]]; then
            TIMESTAMPFILECREATE=1
         fi
      elif [[ "$1" = -l ]]; then
         SHOWLIST=1
         logMsg "showlist is enabled."
      elif [[ "$1" = -v ]]; then
         VERBOSE=1
         logMsg "verbose mode enabled."
      elif [[ "$1" = -V* ]]; then
         VERBOSEFILE="${1##-V}"
         if [[ ! -z "$VERBOSEFILE" ]]; then
            echo -n "" > "$VERBOSEFILE"
            if [[ ! -e "$VERBOSEFILE" ]]; then
               VERBOSEFILE=
            fi
         fi
         logMsg "verbose to file mode enabled ($VERBOSEFILE)."
      elif [[ "$1" = -* ]]; then
         # Unknown option...
         usage
         exit
      else
         # Default option is directory name.
         DIR="$1"
      fi

      # Next cmdline
      shift
   done
}

#
# Filename processing.
#

function echoChildPathOnly
{
   # TODO: Need to learn how to deal better with /// after getting noprefix.
   noprefix="${1#$DIR}"
   echo "${noprefix#/}"
}

#
# Timestamps functionality.
#

# Creates a temporary timestamp file using the existing timestamp list
# and considering any new/removed files from the new tree structure.
function createTmpStampFile {
   # Do not proceed if timestamps disabled.
   if [[ "$TIMESTAMP" -ne 1 ]]; then
      return
   fi

   TMPSTAMPFILE=`mktemp`

   # Go through new filelist.
   for x in `cat "$FILELIST"`; do
      # Skip empty entries...
      if [[ -z $x ]]; then
         continue
      fi

      # Get current file.
      currentFile=`echoChildPathOnly "$x"`

      # Locate current file in current timestamps.
      timestampEntry=`grep "^$currentFile:" "$TIMESTAMPFILE"`

      if [[ -n "$timestampEntry" ]]; then
         echo "$timestampEntry" >> $TMPSTAMPFILE
      else
         echo "$currentFile:new:file:detected" >> "$TMPSTAMPFILE"
      fi
   done

   echo "$TMPSTAMPFILE"
}


# A new time stamp file will be created with new hashsums - the lot.
# Will not perform any checking. It's assumed that:
# $TIMESTAMPFILE is valid,
# A timestamp line consists of:
# filename:timestamp:size:hashsum
function createNewTimestampFile
{
   # Timestamps never existed. Create base timestamp.
   echo -n "" > "$TIMESTAMPFILE"

   # Go through each file, record timestamp.
   # To read the timestamp of a file we do:
   # stat --format="%Y:%s" <file>
   # This will give us: <timestamp:size>
   logMsg "creating new time stamp file $TIMESTAMPFILE"
   for x in `cat "$FILELIST"`; do
      timestamp=`stat --format="%Y:%s" $x`
      filenameonly=$(echoChildPathOnly $x)

      logMsg "   hashing $filenameonly"
      hashOnly=$(echoHashOnly $x)

      # Write hashes and time stamp information.
      echo "$filenameonly:$timestamp:$hashOnly" >> "$TIMESTAMPFILE"
      echo "$filenameonly:$hashOnly" >> "$HASHES"
   done 
}

# Will read the current time stamp file, go through each entry and if
# a timestamp exists will compare it with the current file time stamp.
# When different, the hash will be renewed.
# If a timestamp does not exist (new file), then the hash is generated
# and recorded along with the current timestamp.
# Assumptions:
# #TIMESTAMP != 0 meaning a timestamp file was provided from where we
# can read existing timestamps.
function processAllTimestamps {
   TMPSTAMPFILE=`mktemp`
   logMsg "updating existing hashsums..."
   logMsg "$TMPSTAMPFILE created"

   # Go through the current file list.
   for x in `cat "$FILELIST"`; do
      # Skip empty lines.
      if [[ -z "$x" ]]; then
         continue
      fi

      # Short filename and current size and time stamp.
      currentFile=`echoChildPathOnly "$x"`
      currentTimestamp=`stat --format="%Y:%s" "$x"`
      currentFilehash=

      # Has this file had a hashsum generated before already?
      # (get old time stamp entry).
      currentEntry=
      oldEntry=`grep "^$currentFile:" "$TIMESTAMPFILE"`

      # Get old information from old time stamp entry.
      oldTimestamp=`timestampTime "$oldEntry"`
      oldFilesize=`timestampSize "$oldEntry"`
      oldFilehash=`timestampHash "$oldEntry"`
      # Combine timestamp and file size to have the complete time stamp.
      # We use the file time and size and treat it as the 'time stamp'.
      oldTimestamp=$oldTimestamp:$oldFilesize

      # Now we compare...
      if [[ $currentTimestamp = $oldTimestamp ]]; then
         # Save time - write old hash.
         logMsg "   $currentFile: no changes detected"
         currentEntry="$oldEntry"
      else
         # Changes detected - determine if this was a new file or not.
         keyword=
         previous=
         if [[ -n $oldEntry ]]; then
            # old entry non zero but does not match current.
            keyword=renewing
            previous="was $oldFilehash"
         else
            keyword=generating
            previous="new file"
         fi

         # Changes detected in file!
         logMsg "   $keyword hash for $currentFile ($previous)"
         currentFilehash=`echoHashOnly "$x"`
         currentEntry="$currentFile:$currentTimestamp:$currentFilehash"
      fi

      # New time stamp entry determined ($currentEntry). Store it.
      echo $currentEntry >> "$TMPSTAMPFILE"
      # Update the hashsum list.
      echo $currentFile:$currentFilehash >> "$HASHES"
   done

   # We are now ready!
   cat "$TMPSTAMPFILE" > "$TIMESTAMPFILE"
   rm -f $TMPSTAMPFILE
}

# filename:time:size:hash
function timestampFile {
   # Remove longest tail (%%) ':*' (anything incl. and after last :).
   echo "${1%%:*}"
}

# filename:time:size:hash
function timestampTime {
   fileTime="${1#*:}"
   echo "${fileTime%%:*}"
}

# filename:time:size:hash
function timestampSize {
   removedHash="${1%:*}"
   echo "${removedHash##*:}"
}

# filename:time:size:hash
function timestampHash {
   # Remove longest head (##) sequence *:
   echo "${1##*:}"
}

#
# Hashing
#

function echoHashOnly {
   sum=`md5sum -b "$1" | cut -d ' ' -f 1`
   echo -n "${sum%$'\n'}"
}

# Will simply go through each file and generate it's hashsum..
function processAllHashes {
   logMsg "generating hashsums...."
   for x in `cat "$FILELIST"`; do
      filenameonly=`echoChildPathOnly "$x"`
      logMsg "   hashing $filenameonly"

      # Find hash.
      filehash=`echoHashOnly "$x"`

      # Write hashsum.
      echo "$filenameonly:$filehash" >> "$HASHES"
   done
}

# Will go through each file in file list and generate new hashsums.

#
# Main processing.
#

# When timestamping is enabled, the timestamp file will be updated and only
# those files with a different timestamp will have their hashsum generated
# again.
function preprocessHash {
   # Timestamps enabled??
   if [[ $TIMESTAMP -eq 0 ]]; then
      processAllHashes
   else
      processAllTimestamps      
   fi
}

# First determine command line parameters.
parseCmdline "$@"

# Create the filelist first. This is the list of files to process.
logMsg "creating temporary file list in $FILELIST"
find "$DIR" -type f | sort > "$FILELIST"

# Do we need to create the timestamps first?
if [[ "$TIMESTAMPFILECREATE" -eq 1 ]]; then
   # By creating the time stamp file, we mean that this has never existed
   # before. Therefore, this process needs to generate the hashsums as well.
   # Might as well do the whole thing here.
   createNewTimestampFile
else
   # Process files. This will consider if a timestamp file already exists
   # and if so, uses it to save time on generating hashes (provided the
   # option is enabled).
   preprocessHash
fi

# Hash all file hashes.
logMsg "generating overall hashsum"
OVERALLHASH=`echoHashOnly "$HASHES"`

# Write hash to time stamp file also if it exists.
if [[ $TIMESTAMP -ne 0 ]]; then
   echo $OVERALLHASH >> "$TIMESTAMPFILE"
fi

# List final output.
if [[ $SHOWLIST -ne 0 ]]; then
   cat "$HASHES"
fi
echo $OVERALLHASH

# Cleanup.
rm -f "$FILELIST" "$HASHES"
