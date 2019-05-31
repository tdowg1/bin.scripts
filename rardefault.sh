#!/bin/bash -
#===============================================================================
#          FILE:  rardefault.sh
#         USAGE:  rardefault.sh <thing to archive>
#
#   DESCRIPTION:
# a rar archive creator with some default settings I prefer.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:
#         NOTES:  ---
#        AUTHOR:   (),
#       COMPANY:
#       VERSION:  1.0
#       CREATED:  04/13/2012 12:15:04 AM EDT
#      REVISION:  ---
#===============================================================================

getlastcharacter(){
   local str="${1}"
   echo "${str:$(( ${#str} - 1 )):${#str}}"
}

removetrailingslashes(){
#removetrailingslashesbycounting(){
   # Example invocations
   # $ removetrailingslashes "/the/slash/monster/rawrrr/"
   # /the/slash/monster/rawrrr
   # $ removetrailingslashes "/and/her/little/dog/too"
   # /and/her/little/dog/too
   # $ removetrailingslashes "/woof/woof//"
   # /woof/woof
   # $ removetrailingslashes "/please/no-really/srsly/nobody///"
   # /please/no-really/srsly/nobody
   # $ removetrailingslashes "/let/the/freaking/dogs/out/_..._/shutups/////"
   # /let/the/freaking/dogs/out/_..._/shutups
   # $ removetrailingslashes ""
   #
   # $ removetrailingslashes "/"
   #
   # $ removetrailingslashes "///"
   #
   local str="${1}"

   local prevlength=0
   local currlength="${#str}"
   while [[ $prevlength != $currlength ]] ; do
      # removes 1x '/' character from tail end of string
      str="${str%/}"

      prevlength="$currlength"
      currlength="${#str}"
   done

   echo "$str"
}


rardefault(){
   # Example invocations
   #  $ rardefault directory-to-archive/
   #  # end up with directory-to-archive.rar containing directory-to-archive/ .
   #  $ rardefault file-to-archive
   #  # end up with file-to-archive.rar containing file-to-archive .
   local fso="${1}"  # file system object
   fso="$( removetrailingslashes "${fso}" )"

   rar a -m5 -r -rr4p -t -tsmca "${fso}.rar"  "${fso}"
}

if [[ $# != 0 ]] ; then
   rardefault "$*"
fi


