SetList
=======

LabVIEW control for BEC experiments.

This is a fresh repository forked from the SVNrepo revision 456.
=======
####You can now use Labview's built-in tools to compare/diff and merge from git:

#####Setup
Open either a git-bash (included in standard git distribution) or a git-powershell (included in GitHub distribution)
session in the current repository.  From the root level, run `sh scr/setupLVTools.sh`
This will copy appropriate scripts to `~/bin/` on your local drive, and set up new git commands `difflv` and `mergelv`.

#####Using diff/comparing changes
* To compare uncommitted changes to the last checked in version, file-by-file use `git difflv`
* To compare a specific VI to the most current version checked in to the repository, use `git difflv path/to/file.vi`
* To compare VIs between two known commits, use `git difflv path/to/file.vi <Commit Hash 1> <Commit Hash 2>`
* See `git help diff` for more details.

#####Resolving merge conflicts
If you attempt a merge and conflicts are reported, you can run `git mergelv`.  This should begin listing conflicted
files and give you the option to launch LVMerge to help resolve them.
