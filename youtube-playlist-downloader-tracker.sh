#!/bin/bash -p
#===============================================================================
#          FILE:  youtube-playlist-downloader-tracker.sh
#         USAGE:  <see f_usage()>
#   DESCRIPTION:  <see f_usage()>
#       OPTIONS:  <see f_usage()>
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:   (),
#       COMPANY:
#       VERSION:  1.0
#       CREATED:  2019-04-29T03:32:42-0400
#      REVISION:  ---
#===============================================================================

#set -o xtrace                               # After expanding each simple command, for command, case command, select command, or arithmetic for command, display the expanded value of PS4, followed by the command and its expanded arguments or associated word list.
#PS4=' { ${LINENO} } '                       # The value of this parameter is expanded as with PS1 and the value is printed before each command bash displays during an execution trace.  The first character of PS4 is replicated multiple times, as necessary, to indicate multiple levels of indirection.  The default is ``+ ''.
#set -o errexit                              # Exit immediately if a pipeline (which may consist of a single simple command), a subshell command enclosed in parentheses, or one of the commands executed as part of a command list enclosed by braces (see SHELL GRAMMAR above) exits with a non-zero status.
set -o nounset                              # Treat unset variables as an error
set -o pipefail                             # with pipefail enabled, the pipelines return status is the value of the last (rightmost) command to exit with a non-zero status, or zero if all commands exit successfully.


YOUTUBE_PLAYLIST_URL="\${YOUTUBE_PLAYLIST_URL}"
YOUTUBE_PLAYLIST_TITLE="\${YOUTUBE_PLAYLIST_TITLE}"
OUTPUT_TEMPLATE="'%(autonumber)s-%(title)s-%(id)s.%(ext)s'"
OUTPUT_TEMPLATE="'%(playlist)s/%(autonumber)s-%(playlist_index)s-%(title)s-%(id)s.%(ext)s'"
YOUTUBE_DL_CMDLN1="youtube-dl --yes-playlist --flat-playlist --dump-single-json ${YOUTUBE_PLAYLIST_URL}  > ${YOUTUBE_PLAYLIST_TITLE}/$( date +"%Y%m%d_%H%M%S" )-${YOUTUBE_PLAYLIST_TITLE}.json"
YOUTUBE_DL_CMDLN2="youtube-dl --yes-playlist ${YOUTUBE_PLAYLIST_URL} --retries 5 --xattr-set-filesize --no-overwrites --xattrs --add-metadata --sleep-interval 3 --max-sleep-interval 13 --prefer-ffmpeg  -o  ${OUTPUT_TEMPLATE} --ignore-errors"


f_usage(){
   local scriptname="$( basename "$0" )"
   cat <<__usageHEREDOC__
Usage: $scriptname <youtube-playlist-url>

This script takes the URL of a youtube playlist and does the
following:

- creates a directory named <name of playlist> where the rest
  of the things that this script ultimately creates, get placed.

- downloads the playlist JSON file which contains all of the
  playlist elements.  Currently, youtube (or youtube-dl script)
  is writing this file with all of the content in proper playlist
  order.

- downloads playlist contents according to the following format:
-- $OUTPUT_TEMPLATE

- generates a simple .m3u playlist file within the created
  directory.

Some Cmdlns thatll be executed:
- $YOUTUBE_DL_CMDLN1

- $YOUTUBE_DL_CMDLN2

Program Dependancies:
- youtube-dl
- jq
- ffmpeg

Examples:
  $scriptname https://www.youtube.com/playlist?list=PL9I3J8bsZiuBGXPccFdDYAUCtB5dlTip

Tips:
- if you have a txt file just containing the URLs for all your
  (or somebodys) playlists, could scoop them all with something
  like:
     while read line; do time $scriptname \$line; done < playlist-urls.txt
__usageHEREDOC__
   exit 1
}


if [[ $# != 1 ]] ; then
   echo "ERROR: $# is not the proper number of cmdln arguments."
   f_usage
fi


#
# PARSE CMDLN, VARIABLE DEFINITIONS, SANITY CHECKS && META GENERATION
#====================================================================
#
loopcount=0
while [ "$#" -gt "0" ] ; do
   case $1 in
      -u|--usage|-h|--help) # specified like: -k, or like: --key
         f_usage
         ;;
      *) # if user input didn't match any of the prior flags,
         # going to assume it's the starting path. A sanity
         # check will be performed after all cmdln args parsed.
         YOUTUBE_PLAYLIST_URL=$1
         shift
         ;;
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
#: ${ISQUIET:="FALSE"}

# required to be defined by now; think "<cfparam=* required=yes..."
#: ${TEMPDIR2:?ERROR: not specified}

which youtube-dl >/dev/null 2>&1
if [[ $? != 0 ]] ; then
   echo "ERROR: cannot find:: youtube-dl"
   f_usage
fi
which jq >/dev/null 2>&1
if [[ $? != 0 ]] ; then
   echo "ERROR: cannot find:: jq"
   f_usage
fi
which ffmpeg>/dev/null 2>&1
if [[ $? != 0 ]] ; then
   echo "ERROR: cannot find:: ffmpeg"
   f_usage
fi


#
# FUNCTIONS AND ANY OTHER PRE-MAIN
#====================================================================
#
f_control_c(){
   # c-c was entered.
   #echo -en "\n*** Ouch! Exiting ***\n"
   exit 1
}

# trap keyboard interrupt (control-c)
trap f_control_c SIGINT

# alternatively,
#trap exit SIGINT SIGTERM


#
# MAIN
#====================================================================
#
echo -n "determining playlist title..."
YOUTUBE_PLAYLIST_TITLE=$( youtube-dl --yes-playlist  --flat-playlist --dump-single-json $YOUTUBE_PLAYLIST_URL  --ignore-errors 2>/dev/null | jq -r '.title' )
echo "$YOUTUBE_PLAYLIST_TITLE"


echo -n "determining number of playlist entries..."
playlist_entries_cnt=$( youtube-dl --yes-playlist  --flat-playlist --dump-single-json $YOUTUBE_PLAYLIST_URL  --ignore-errors 2>/dev/null | jq '.entries[].id' | wc -l )
echo "$playlist_entries_cnt"


mkdir -v "$YOUTUBE_PLAYLIST_TITLE"
[[ $? != 0 ]] && echo "^^thats ok though..."


echo $YOUTUBE_DL_CMDLN1
echo $( eval $YOUTUBE_DL_CMDLN1 )
#???eval $YOUTUBE_DL_CMDLN1

echo $YOUTUBE_DL_CMDLN2
eval $YOUTUBE_DL_CMDLN2


cd "$YOUTUBE_PLAYLIST_TITLE"
# generate playlist:
find . -type f | grep -vP '\.json|\.m3u' | sort -n > "$( date +"%Y%m%d_%H%M%S" )-${YOUTUBE_PLAYLIST_TITLE}.m3u"
cd - >/dev/null

