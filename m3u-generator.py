#!/usr/bin/env python3

# IMPROVEMENT IDEAS :
#  - add flag to URL encode the contents of the m3u ?  (e.g. " " -> "%20") this will play in vlc but not qmmp.  (and non-url encoded content will play in qmmp but not in vlc lol fml)
#       https://meyerweb.com/eric/tools/dencoder/

# BUG :
#  - FIXED it creates an empty .m3u file within directories which have no music files.
#
#  - probably wont work as desired if music file extensions are MIXED OR UPPER-CASE.
#      try implementing~:  if file.lower().endswith('.m3u'):<...>

#  - FIXED its barfing (err... totally skipping over
#       'm3u-test-cpal-6/2005-12-19 Sunchase - sands of time ep [msxep041]'
#    for some reason... seems to be related to the square brakets?? cause whene i rememver them, my program is
#    ok with that dir then... and when i renamed Darude to havve square brackets, it starting barfing on
#    Darude, then... hrmmm.
#        ya so it seems like... probably glob.glob() is not the thing I should really be using... because i only want
#        a list of all directories (in one or two cases), and a list of all music file'd extensions...
#   might want should use os.walk()  (which is diff from os.path.walk() FYI)
#
#                   ... ^^hrm... or even just os.listdir


import os
import glob
import argparse
import datetime
import io
import textwrap


def generateM3uFilePath(albumPath):
    # Example invocation
    # ------- ----------
    # Input:  'parent-dir/Carl Cox'
    # Output: 'parent-dir/Carl Cox/Carl Cox.<date>.m3u'
    #
    return albumPath + os.path.sep + os.path.basename( os.path.normpath(albumPath) ) + "." \
           + datetime.datetime.now().strftime("%Y%m%dT%H%M%S") + ".m3u"


parser = argparse.ArgumentParser(
    formatter_class=argparse.RawDescriptionHelpFormatter,
    description=textwrap.dedent('''\
    Generates an 'm3u' for any music file(s) that exist within each direct/immediate subdirectory of the specified path,
    if an 'm3u' doesnt already exist.  So, by default, each subdirectory represents an album and path represents a
    collection of albums.

    Examples:
        m3u-generator.py    -p Vin-Petrols-music-collection
        m3u-generator.py -s -p almond-activation-music
        m3u-generator.py    -p 'craigyferg-tunes/wassacominago CD1'  --only-one
        m3u-generator.py -o -p 'RLY-expensive-applesauce-albums/Improvised Turkish blue grass Disk 33'

        # List subdirectories (albums) devoid of an 'm3u':
        m3u-generator.py -s -p  albanian-free-jazz/ | grep "NO  m3u" | sed 's/NO  m3u : //'

        # ^^This could be built on further by piping to xargs to generate an 'm3u' for, for instance,
        # multi-disk releases:
        xargs -L 1 -I{}  m3u-generator.py --path '{}'
        '''))
parser.add_argument('--path', '-p', default=os.path.curdir,
                    help="path (to an album collection) that contains subdirectories (albums) to check, defaults to "
                         "cwd.")
parser.add_argument('--only-one', '-o', action='store_true',
                    help="treat --path as if it were a subdirectory (an album).  IOW, create an 'm3u' file for the "
                         "music files within only one directory, namely, the one specified by --path.  Do not analyze "
                         "any deeper directories from here.  (Useful for creating just a lone 'm3u' for a specific "
                         "album).")
parser.add_argument('--show-m3us', '-s', action='store_true',
                    help="for each subdirectory (album), say whether it has an 'm3u' or not, then exit.")
parser.add_argument('--dry-run', '-n', action='store_true',
                    help="dont actually do anything.  Just show me!")
args = parser.parse_args()


if args.only_one:
    # ¿ get just that one directory???  is the purpose of this to just test that it's a directory????  yes, seems that way.
    if os.path.isdir(args.path):
        dirs = list()
        dirs.append(args.path)
    else:
        print("not a directory: %s" % args.path)
        exit()
else:
    # ¿ get list of directories

    # the following does not give relative path names which is whats needed:
    #dirs = list(filter(os.path.isdir, os.listdir(args.path + os.path.sep)))
    # so build it:
    dirs = list()
    for d in os.listdir(args.path):
        if os.path.isdir(os.path.join(args.path, d)):
            dirs.append(os.path.join(args.path, d))


import pprint
pprint.pprint(dirs, width=125, compact=False)
print("")

if args.show_m3us:
    for album in dirs:
        existingM3uCount2 = len([f for f in os.listdir(album) if f.endswith('.m3u')])
        if existingM3uCount2 > 0:
            print("YES m3u : %s" % album)
        else:
            print("NO  m3u : %s" % album)
    exit()


_AUDIO_FILENAME_EXTENSIONS = ("mp3", "flac", "ogg", "m4a")
for album in dirs:
    existingM3uCount2 = len([f for f in os.listdir(album) if f.endswith('.m3u')])
    if existingM3uCount2 > 0:
        # looks good.  an m3u already exists.
        continue

    musicFiles2 = [f for f in os.listdir(album) if f.endswith(_AUDIO_FILENAME_EXTENSIONS)]


    musicFiles = musicFiles2
    if len(musicFiles) > 0:
        # ok.  found some music files.
        musicFiles = list(map(lambda x: os.path.basename(x), musicFiles))
        musicFiles.sort()
        #pprint.pprint(musicFiles, width=125, compact=False)

        if args.dry_run:
            print("CREATE m3u : %s" % generateM3uFilePath(album))
        else:
            with io.open(generateM3uFilePath(album), "w") as m3uFile:
                m3uFile.write(u'\n'.join(musicFiles))


