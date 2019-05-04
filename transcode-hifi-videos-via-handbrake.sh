#!/bin/bash -p
#===============================================================================
#          FILE:  transcode-hifi-videos-via-handbrake.sh
#         USAGE:  <see f_usage()>
#   DESCRIPTION:  <see f_usage()>
#       OPTIONS:  <see f_usage()>
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:   (),
#       COMPANY:
#       VERSION:  1.0
#       CREATED:  2019-04-26T03:09:17-0400
#      REVISION:  ---
#===============================================================================
#set -o xtrace                               # After expanding each simple command, for command, case command, select command, or arithmetic for command, display the expanded value of PS4, followed by the command and its expanded arguments or associated word list.
PS4=' { ${LINENO} } '                       # The value of this parameter is expanded as with PS1 and the value is printed before each command bash displays during an execution trace.  The first character of PS4 is replicated multiple times, as necessary, to indicate multiple levels of indirection.  The default is ``+ ''.
#set -o errexit                              # Exit immediately if a pipeline (which may consist of a single simple command), a subshell command enclosed in parentheses, or one of the commands executed as part of a command list enclosed by braces (see SHELL GRAMMAR above) exits with a non-zero status.
set -o nounset                              # Treat unset variables as an error
set -o pipefail                             # with pipefail enabled, the pipelines return status is the value of the last (rightmost) command to exit with a non-zero status, or zero if all commands exit successfully.


: ${handbrakeTranscodingProfileToUseDEFAULT:="AppleTV 3"}


f_usage(){
   local scriptname="$( basename "$0" )"
   cat <<__usageHEREDOC__
Usage: $scriptname <arguments>

This script is intended to help with identifying and
transcoding high quality video files so that they
are suitable for / cabable of playback on less powerful
machines.

It does this by analyzing all files in cwd, trying to find
video files, then, for any candidates, begins the transcode
process.  Transcoded files are placed alongside the source
originals.  Transcoded files will be named according to the
HandBrake profile(s) that were used.

--maxWidthPx  Any video file found to have more pixels than
              this will be transcoded.
--maxHeightPx Any video file found to have more pixels than
              this will be transcoded.
--maxFps      Any video file found to have higher framerates
              this will be transcoded.
--g_handbrakeTranscodingProfileToUse
              The profile to use.  Default is "$handbrakeTranscodingProfileToUseDEFAULT"

Program Dependancies:
- HandBrakeCLI
- mediainfo

Examples:
  $scriptname  --maxWidthPx=1900
  $scriptname --maxHeightPx=1079
  $scriptname  --maxWidthPx=1900 --maxHeightPx=1079
  $scriptname --maxFps=30
  $scriptname --maxHeightPx=1079 --maxFps=29
  $scriptname --maxHeightPx=1079 --maxFps=29 --g_handbrakeTranscodingProfileToUse="AppleTV 3"
  $scriptname --maxHeightPx=1079 --maxFps=29 --g_handbrakeTranscodingProfileToUse=AppleTV
__usageHEREDOC__
   exit 1
}


if [[ $# = 0 ]] ; then
   echo "ERROR: $# is not enough cmdln arguments... must specify"
   echo "at least one property to analyze... i.e. at least one of:"
   echo "   --maxWidthPx"
   echo "   --maxHeightPx"
   echo "   --maxFps"
   f_usage
fi


#
# PARSE CMDLN, VARIABLE DEFINITIONS, SANITY CHECKS && META GENERATION
#====================================================================
#
loopcount=0
while [ "$#" -gt "0" ] ; do
   case $1 in
      -q|--quiet) # specified like: -k, or like: --key
         ISQUIET="TRUE"
         shift
         ;;
      -u|--usage|-h|--help) # specified like: -k, or like: --key
         f_usage
         ;;
      --*=?*) # specified like: --key=value
         # $this --key1=value1   ends up defining "key1" with "value1"
         # for example: --xyz=abc
         value=${1#--*=}  # abc
         tmp=${1%=*}
         key=${tmp#--}    # xyz

         # set the variable xyz to abc
         eval ${key}="\"${value}\""
         shift
         ;;
      *) # anything else.
         echo "not sure what to do with: $1"
         echo "bai"
         exit 1
   esac

   let loopcount+=1
   if [[ $loopcount = 40 ]] ; then
      echo "problem parsing cmdln args.  entered infinite loop.  bai."
      exit 5
   fi
done


#
# VARIABLE PARAMS/INITIALIZATION AND SANITY CHECKING
#====================================================================
#
# vars to define if not defd; think "<cfparam=*..."
: ${ISQUIET:="FALSE"}

: ${maxWidthPx:=0}
: ${maxHeightPx:=0}
: ${maxFps:=0}

: ${g_handbrakeTranscodingProfileToUse:="$handbrakeTranscodingProfileToUseDEFAULT"}


which HandBrakeCLI >/dev/null 2>&1
if [[ $? != 0 ]] ; then
   echo "ERROR: cannot find:: HandBrakeCLI"
   f_usage
fi
which mediainfo >/dev/null 2>&1
if [[ $? != 0 ]] ; then
   echo "ERROR: cannot find:: mediainfo"
   f_usage
fi


#
# FUNCTIONS AND ANY OTHER PRE-MAIN
#====================================================================
#
#if [ -n "${ISQUIET}" ] ; then
if [ x"${ISQUIET}" = x"TRUE" ] ; then
    exec &>/dev/null
fi


function handleTranscoding(){
   local existingFile="$1"

   #local transcodedFilenameExtension="$( mediainfo "$existingFile" --Inform="General;%FileExtension%" )"
   # handbrake creates MP4 files:
   local transcodedFilenameExtension="mp4"
   local suffixToMatch="${g_handbrakeTranscodingProfileToUse}.${transcodedFilenameExtension}"


   # if the length of suffixMatchAttempt == existingFile , then the suffix match
   # attempt failed/did NOT match, and hence, this file is NOT a transcoded file.
   #${parameter%%word}  matches matching suffix...
   suffixMatchAttempt="${existingFile%%${suffixToMatch}}"


   # firstly, check that $existingFile isnt a transcoded file:
   if [[ ${#existingFile} -eq ${#suffixMatchAttempt} ]] ; then
      # $existingFile is NOT a transcoded file, at least not with $g_handbrakeTranscodingProfileToUse .
      local suffixToAdd="$suffixToMatch"

      local generatedNewTranscodeFilename="$( basename "${existingFile}.${suffixToAdd}" )"

      # lastly, check that a transcoded file hasnt been created for $existingFile already:
      if [[ ! -f "$generatedNewTranscodeFilename" ]] ; then
         #echo HandBrakeCLI --preset "${g_handbrakeTranscodingProfileToUse}" \
         HandBrakeCLI --preset "${g_handbrakeTranscodingProfileToUse}" \
            -i "$existingFile" \
            -o "$generatedNewTranscodeFilename"
      fi
   fi

}


#
# MAIN
#====================================================================
#
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")


if [[ $maxWidthPx != 0 ]] ; then
   for currFile in $( find . -maxdepth 1 -type f ) ; do
      currFileWidth="$( mediainfo "$currFile" --Inform="Video;%Width%" )"

      if [[ $currFileWidth -gt $maxWidthPx ]] ; then
         handleTranscoding "$currFile"
      fi
   done
fi


if [[ $maxHeightPx != 0 ]] ; then
   for currFile in $( find . -maxdepth 1 -type f ) ; do
      currFileHeight="$( mediainfo "$currFile" --Inform="Video;%Height%" )"

      if [[ $currFileHeight -gt $maxHeightPx ]] ; then
         handleTranscoding "$currFile"
      fi
   done
fi


if [[ $maxFps != 0 ]] ; then
   for currFile in $( find . -maxdepth 1 -type f ) ; do
      currFileFps="$( mediainfo "$currFile" --Inform="Video;%FrameRate%" )"
      # strip off any floating point:
      currFileFps=${currFileFps%.*}

      if [[ $currFileFps -gt $maxFps ]] ; then
         handleTranscoding "$currFile"
      fi
   done
fi


IFS=$SAVEIFS
exit

