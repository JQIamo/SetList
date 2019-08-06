# SetList

LabVIEW control for BEC experiments. SetList can be cited using [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3344809.svg)](https://doi.org/10.5281/zenodo.3344808).

## Getting started

Read the [documentation](#documentation), and clone the repository! If you encounter issues, please submit a ticket on the [issues page](https://github.com/JQIamo/SetList/issues) or email Zach (zsmith12 at umd).

### For Developers

You can now use Labview's built-in tools to compare/diff and merge from git:

**Setup LVTools**:

Open either a git-bash (included in standard git distribution) or a git-powershell (included in GitHub distribution)
session in the current repository.  From the root level, run `sh scr/setupLVTools.sh`
This will copy appropriate scripts to `~/bin/` on your local drive, and set up new git commands `difflv` and `mergelv`.

**Using diff/comparing changes**

* To compare uncommitted changes to the last checked in version, file-by-file use `git difflv`
* To compare a specific VI to the most current version checked in to the repository, use `git difflv path/to/file.vi`
* To compare VIs between two known commits, use `git difflv path/to/file.vi <Commit Hash 1> <Commit Hash 2>`
* See `git help diff` for more details.

**Resolving merge conflicts**

If you attempt a merge and conflicts are reported, you can run `git mergelv`.  This should begin listing conflicted
files and give you the option to launch LVMerge to help resolve them.

## Documentation

For documentation, see the [SetList project page](http://jqiamo.github.io/SetList/). This has a link to a pdf dump of the documentation, which for historic reasons is currently being maintained on the [internal JQI wiki](https://jqi-wiki.physics.umd.edu/d/documentation/software/computercontrol/setlist/home).

## Other Info

**The root of this repository was a fresh repository forked from the SVNrepo revision 456.** The SVN repository is now obsolete and should no longer be used for version control.
