#!/usr/bin/env python3

# BUGS :
#  - overwrites already existing *.mkvmerged.mkv files when already exists, but not always...

# IMPROVEMENTS :
#  - seems like ffmpeg might be the proper tool to use, which appears to  result in files that are the exact same kind from which they came

# ASSUMPTIONS :
#  - not tested with spaces in specified path (the -p argument).
#  - video files are properly timestamped (basically, if your dashcam isnt bonkers and created them normally and havent been modified after the fact, this should be automatically satisfied.  at a minimum, files apart of a multipart video set should be chronologically created.
#  - mkvmerge is somewhere in PATH.
#  - video files can be combined using mkvmerge.


def executeCommandLine( command ):
    rc = subprocess.run( shlex.split( command ) )
    return rc


def generateMkvmergedFilename( basefilename ):
    return ("%s.mkvmerged.mkv " % basefilename )


# the start and end indices of the list of files that are members of the set, inclusive.
def generateMkvmergeCmdln( fileArray, start, end ):
    end += 1
    cmdlnBuilding0 = "mkvmerge -o"
    cmdlnBuilding1 = generateMkvmergedFilename( fileArray[start] )
    cmdlnBuilding2 = (" + ".join(fileArray[start:end]))
    return ("%s %s %s" % (cmdlnBuilding0, cmdlnBuilding1, cmdlnBuilding2) )


def handleSingleOrEndOfASetFile( fileArray, start, end ):
    x


import os
import glob
import optparse
import shlex, subprocess

parser = optparse.OptionParser()
#parser.add_option("-p", "--path", help="path that contains mkvmerge-able files", dest="search_dir")
parser.add_option("-p", "--path", help="path that contains mkvmerge-able files", dest="search_dir", default=".")
parser.add_option("-n", help="dry-run; dont actually do anything, just show", action="store_true", dest="isDryRun", default=False)

(options, arguments) = parser.parse_args()

import pprint
pprint.pprint(options)

#files = filter(os.path.isfile, glob.glob(options.search_dir + "*"))         # Python 2
files = list( filter(os.path.isfile, glob.glob(options.search_dir + "*")) )  # Python 3
files.sort(key=lambda x: os.path.getmtime(x))

beginningSetIndex = 0
for i in range(0, len(files)):
    print("%s" % files[i])

    if i + 1 < len( files ):  # "if this isn't the last element in the list ..."

        if files[i + 1][ -7: ] == '001.MOV':  # "if this isnt the middle of a set..."
            # if got here, its either:
            #   - a solo; notify and do nothing more.
            #   - the last of a set; determine cmdln string and execute.


            # handleSingleOrEndOfASetFile( files, beginningSetIndex, i )

            if beginningSetIndex == i:  # "if this is a solo..."
                # basically noop.
                print("# single file; no mkvmergeing to do.")

            else:  # "if this is the last of a set..."
                generatedFilename = generateMkvmergedFilename( files[ beginningSetIndex ] )
                helpingNote = ("touch --reference %s %s" % ( files[ beginningSetIndex ], generatedFilename ) )
                print( helpingNote )

                cmdln = generateMkvmergeCmdln( files, beginningSetIndex, i )

                if options.isDryRun:
                    print( cmdln )
                else:
                   executeCommandLine( cmdln )

            # forward progress:
            beginningSetIndex = i + 1


        else:
            print( "# files[i] is NOT solo ; it continues a set (inclusively).")


    else:  # "this is the last item in the list"

        #### FROM HERE DOWN
        if beginningSetIndex == i:  # "if this is a solo..."
            # basically noop.
            print("# single file; no mkvmergeing to do.")

        else:  # "if this is the last of a set..."
            generatedFilename = generateMkvmergedFilename( files[ beginningSetIndex ] )
            helpingNote = ("touch --reference %s %s" % ( files[ beginningSetIndex ], generatedFilename ) )
            print( helpingNote )

            cmdln = generateMkvmergeCmdln( files, beginningSetIndex, i )

            if options.isDryRun:
                print( cmdln )
            else:
               executeCommandLine( cmdln )
        #### FROM HERE UP...
        # ... could convert to function since they indentical within both uses.

    print("")

