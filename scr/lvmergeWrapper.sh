#!/bin/bash
# lvmergeWrapper.sh
# ZSS, 19 Aug 2014
# Wrapper to help launch LVMerge as a LabView merge tool
#
# Script cobbled together from the internet, most valuable source
# being http://lavag.org/topic/17934-configuring-git-to-work-with-lvcompare-and-lvmerge/#entry108533
# and thread, as well as git documentation (mergetool, merge, config).

# Get a Windows Absolute path from the git merge-tool style relative path
abspath () {
(
#	echo "1= $1"
	DIR=$(dirname "$1")
	FN=$(basename "$1")
	cd "$DIR"
#	echo "FN=$FN"
	# tr should be doing magical forward-slash to backslash translation
	printf "%s/%s" "$(pwd -W)" "$FN" | tr '/' '\\' | tr ' ' '\ '
)
}

# Path to executable
lvmerge="/c/Program Files (x86)/National Instruments/Shared/LabVIEW Merge/LVMerge.exe"

# Convert each passed git-relative path to a Windows-style absolute path
baseWin=$(abspath "$1")
localWin=$(abspath "$2")
remoteWin=$(abspath "$3")
mergedWin=$(abspath "$4")

echo Launching "$lvmerge"
exec "$lvmerge" "$baseWin" "$remoteWin" "$localWin" "$mergedWin"
