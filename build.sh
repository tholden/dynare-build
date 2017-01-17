#!/bin/bash

# Produces Dynare snapshot (source tarball, windows installer and zip archive for windows).
#
# The binaries are cross compiled for windows (32/64bits), octave 4.2.0 and matlab (all
# versions since R2007b). The build chain has been tested on debian Jessie.
#
# (C) DynareTeam 2017
#
# This file is part of dynare-build project. Sources are available at:
#
#     https://gitlab.com/DynareTeam/dynare-build.git
#
# Dynare is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Dynare is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Dynare.  If not, see <http://www.gnu.org/licenses/>.

# Exit on first error
set -ex

# Set root directory
THISSCRIPT=$(readlink -f $0)
ROOT_DIRECTORY=`dirname $THISSCRIPT`

# Set options.
FORCE_BUILD=0

# Set the number of threads
NTHREADS=`nproc --all`

# Load shell functions
. $ROOT_DIRECTORY/tools.sh

# Load the configuration file
if [ -f "$ROOT_DIRECTORY/configuration.inc" ]
then
    echo "Found configuration file!"
    . $ROOT_DIRECTORY/configuration.inc
else
    tput setaf 1; echo "I did not find any configuration file! Use defaults"
    # Set Dynare sources
    GIT_REMOTE=https://github.com/DynareTeam/dynare.git
    GIT_BRANCH=master
    VERSION=
    # Set the number of snapshots to be kept on the server.
    N_SNAPSHOTS_TO_KEEP=5
fi

# Set Date
DATE=`date --rfc-3339=date`

# Get last commit sha1 hash in selected branch (GIT_BRANCH on GIT_REMOTE)
LAST_HASH=`git ls-remote $GIT_REMOTE refs/heads/$GIT_BRANCH | cut -f 1`
SHORT_SHA=`echo $LAST_HASH | cut -c1-7`

# Set basename for snapshot installer
if [ -z "$VERSION" ]
then
    VERSION=$GIT_BRANCH-$DATE-$SHORT_SHA
fi

BASENAME=dynare-$VERSION
__BASENAME__=dynare-$GIT_BRANCH-$SHORT_SHA

# Set directories for libraries
LIB32=$ROOT_DIRECTORY/libs/lib32
LIB64=$ROOT_DIRECTORY/libs/lib64

# Set name of directories
GITREPO_DIRECTORY=$ROOT_DIRECTORY/git
GITWORK_DIRECTORY=$GITREPO_DIRECTORY/$LAST_HASH
SOURCES_DIRECTORY=$ROOT_DIRECTORY/tar
WINDOWS_EXE_DIRECTORY=$ROOT_DIRECTORY/win
WINDOWS_ZIP_DIRECTORY=$ROOT_DIRECTORY/zip
BUILDS_DIRECTORY=$ROOT_DIRECTORY/builds
THIS_BUILD_DIRECTORY=$BUILDS_DIRECTORY/$BASENAME

# Set source TARBALL name
TARBALL_NAME=$__BASENAME__.tar.xz

# Set default values for dummy variables
MAKE_SOURCE_TARBALL=1
CLONE_REMOTE_REPOSITORY=1
BUILD_WINDOWS_EXE=1
BUILD_WINDOWS_ZIP=1

# Test if there is something new on the remote.
if [ -d "$GITWORK_DIRECTORY" ]; then
    if [ -f "$SOURCES_DIRECTORY/$TARBALL_NAME"  ]; then
	if [ -f "$WINDOWS_EXE_DIRECTORY/dynare-$GIT_BRANCH-"*"-$SHORT_SHA-win.exe" ]; then
	    if [ -f  "$WINDOWS_ZIP_DIRECTORY/dynare-$GIT_BRANCH-"*"-$SHORT_SHA-win.zip" ]; then
		echo "Dynare ($LAST_HASH) has already been compiled!"
		BUILD_WINDOWS_ZIP=0
	    fi
	    BUILD_WINDOWS_EXE=0
	else
	    BUILD_WINDOWS_EXE=1
	fi
	MAKE_SOURCE_TARBALL=0
    else
	MAKE_SOURCE_TARBALL=1
    fi
    CLONE_REMOTE_REPOSITORY=0
else
    CLONE_REMOTE_REPOSITORY=1
fi

# Clone remote branch
if [ $CLONE_REMOTE_REPOSITORY -eq 1 ]; then
    git clone --recursive --depth 1 --branch $GIT_BRANCH $GIT_REMOTE $GITWORK_DIRECTORY
fi

if [ $MAKE_SOURCE_TARBALL -eq 1 ]; then
    # Go into build directory
    cd $GITWORK_DIRECTORY
    # Update version number with current date and sha1 digest
    cat configure.ac | sed "s/AC_INIT(\[dynare\], \[.*\])/AC_INIT([dynare],\ [$GIT_BRANCH-$DATE-$SHORT_SHA])/" > configure.ac.new
    mv configure.ac.new configure.ac
    cd $GITWORK_DIRECTORY/mex/build/octave
    cat configure.ac | sed "s/AC_INIT(\[dynare\], \[.*\])/AC_INIT([dynare],\ [$GIT_BRANCH-$DATE-$SHORT_SHA])/" > configure.ac.new
    mv configure.ac.new configure.ac
    cd $GITWORK_DIRECTORY/mex/build/matlab
    cat configure.ac | sed "s/AC_INIT(\[dynare\], \[.*\])/AC_INIT([dynare],\ [$GIT_BRANCH-$DATE-$SHORT_SHA])/" > configure.ac.new
    mv configure.ac.new configure.ac
    cd $GITWORK_DIRECTORY
    # Create snapshot source (tarball)
    autoreconf -si
    ./configure
    make dist
    # Move tarball
    mv $BASENAME.tar.xz $SOURCES_DIRECTORY/$TARBALL_NAME
fi

# Extract tarball in BUILDS_DIRECTORY
if [ $BUILD_WINDOWS_EXE -eq 1 ]; then
    if [ -d $THIS_BUILD_DIRECTORY ]; then
	if [ $FORCE_BUILD -eq 1 ]; then
	    rm -rf $THIS_BUILD_DIRECTORY
	    cd $SOURCES_DIRECTORY
	    tar xavf $TARBALL_NAME -C $BUILDS_DIRECTORY/
	fi
    else
	cd $SOURCES_DIRECTORY
	tar xavf $TARBALL_NAME -C $BUILDS_DIRECTORY/
    fi
fi

# Go to the build directory
cd $THIS_BUILD_DIRECTORY

if [ $BUILD_WINDOWS_EXE -eq 1 ]; then
    # Create Windows binaries of preprocessor (32bit version), Dynare++ and documentation
    ./configure --host=i686-w64-mingw32 \
		--with-boost=$LIB32/Boost \
		--with-blas=$LIB32/OpenBLAS/libopenblas.a \
		--with-lapack=$LIB32/Lapack/liblapack.a \
		--with-matio=$LIB32/matIO \
		--disable-octave \
		--disable-matlab \
		PACKAGE_VERSION=$VERSION \
		PACKAGE_STRING="dynare $VERSION"
    make clean
    make -j$NTHREADS -C doc pdf html
    make -j$NTHREADS -C dynare++ pdf
    make -j$NTHREADS all
    i686-w64-mingw32-strip matlab/preprocessor32/dynare_m.exe
    i686-w64-mingw32-strip dynare++/src/dynare++.exe
    # Make 64-bit preprocessor
    cp -p matlab/preprocessor32/dynare_m.exe .
    ./configure --host=x86_64-w64-mingw32 \
		--with-boost=$LIB64/Boost \
		--with-blas=$LIB64/OpenBLAS/libopenblas.a \
		--with-lapack=$LIB64/Lapack/liblapack.a \
		--with-matio=$LIB64_DIR/matio \
		--disable-octave --disable-matlab \
		PACKAGE_VERSION=$VERSION \
		PACKAGE_STRING="dynare $VERSION"
    make -C preprocessor clean
    make -C preprocessor -j$NTHREADS all
    x86_64-w64-mingw32-strip matlab/preprocessor64/dynare_m.exe
    mkdir matlab/preprocessor32
    mv dynare_m.exe matlab/preprocessor32/
    # Cleanup mex folders under build directory
    rm -f mex/matlab/*.mexw32 mex/matlab/*.mexw64 mex/matlab/*.dll mex/octave/*.mex
    # Go to ROOT_DIRECTORY
    cd $ROOT_DIRECTORY
    # Reset the number of threads. The mex files for matlab/octave (32bits and 64bits) will be built
    # in parallel, so we need to account for the number of tasks and lower the value of NTHREADS.
    NTASKS=4
    NTHREADS=$(( $NTHREADS/$NTASKS ))
    # Create TMP folder
    mkdir -p tmp
    rm -rf $ROOT_DIRECTORY/tmp/*
    TMP_DIRECTORY=$ROOT_DIRECTORY/tmp
    # Some variables and functions need to be available in subshells.
    export TMP_DIRECTORY
    export THIS_BUILD_DIRECTORY
    export ROOT_DIRECTORY
    export BASENAME
    export LIB32
    export LIB64
    export VERSION
    export NTHREADS
    export -f movedir
    export -f build_windows_matlab_mex_32
    export -f build_windows_matlab_mex_64_a
    export -f build_windows_matlab_mex_64_b
    export -f build_windows_octave_mex_32
    # Build all the mex files (parallel).
    parallel ::: build_windows_matlab_mex_32 build_windows_matlab_mex_64_a build_windows_matlab_mex_64_b build_windows_octave_mex_32
    # Create Windows installer
    cd $THIS_BUILD_DIRECTORY/windows
    makensis dynare.nsi
    $ROOT_DIRECTORY/signature/osslsigncode sign -pkcs12 $ROOT_DIRECTORY/dynare-object-signing.p12 -n Dynare -i http://www.dynare.org -in dynare-$VERSION-win.exe -out dynare-$VERSION-win-signed.exe
    rm dynare-$VERSION-win.exe
    mv dynare-$VERSION-win-signed.exe $ROOT_DIRECTORY/win/dynare-$VERSION-win.exe
    cd $THIS_BUILD_DIRECTORY
fi

# Create .zip file (for those that are not allowed to download/execute the installer)
if [ $BUILD_WINDOWS_ZIP -eq 1 ]; then
    ZIPDIR=$ROOT_DIRECTORY/$VERSION
    mkdir -p $ZIPDIR
    cp -p NEWS $ZIPDIR
    cp -p license.txt $ZIPDIR
    cp -p windows/mexopts-win32.bat $ZIPDIR
    cp -p windows/mexopts-win64.bat $ZIPDIR
    cp -p windows/README.txt $ZIPDIR
    mkdir -p $ZIPDIR/contrib/ms-sbvar/TZcode
    cp -pr contrib/ms-sbvar/TZcode/MatlabFiles $ZIPDIR/contrib/ms-sbvar/TZcode
    mkdir $ZIPDIR/mex
    cp -pr mex/octave $ZIPDIR/mex
    cp -pr mex/matlab $ZIPDIR/mex
    cp -pr matlab $ZIPDIR
    cp -pr examples $ZIPDIR
    cp -pr scripts $ZIPDIR
    mkdir $ZIPDIR/dynare++
    cp -p dynare++/src/dynare++.exe $ZIPDIR/dynare++
    cp -p dynare++/extern/matlab/dynare_simul.m $ZIPDIR/dynare++
    mkdir -p $ZIPDIR/doc/dynare++
    cp -pr doc/dynare.html $ZIPDIR/doc
    cp -p doc/*.pdf $ZIPDIR/doc
    cp -p doc/macroprocessor/macroprocessor.pdf $ZIPDIR/doc
    cp -p doc/parallel/parallel.pdf $ZIPDIR/doc
    cp -p doc/preprocessor/preprocessor.pdf $ZIPDIR/doc
    cp -p doc/userguide/UserGuide.pdf $ZIPDIR/doc
    cp -p doc/gsa/gsa.pdf $ZIPDIR/doc
    cp -p dynare++/doc/dynare++-tutorial.pdf $ZIPDIR/doc/dynare++
    cp -p dynare++/doc/dynare++-ramsey.pdf $ZIPDIR/doc/dynare++
    cp -p dynare++/sylv/sylvester.pdf $ZIPDIR/doc/dynare++
    cp -p dynare++/tl/cc/tl.pdf $ZIPDIR/doc/dynare++
    cp -p dynare++/integ/cc/integ.pdf $ZIPDIR/doc/dynare++
    cp -p dynare++/kord/kord.pdf $ZIPDIR/doc/dynare++
    cd $ROOT_DIRECTORY
    zip -r dynare-$VERSION-win.zip $ZIPDIR
    mv dynare-$VERSION-win.zip $ROOT_DIRECTORY/zip
    rm -rf $ZIPDIR
fi

if [ -v BUILD_INTERNAL_DOC -a $BUILD_INTERNAL_DOC -eq 1 ]; then
    # Build internal documentation (org-mode and m2html)
    cd $THIS_BUILD_DIRECTORY
    build_internal_documentation
    build_m2html_documentation
    if [ -v PUSH_INTERNAL_DOC -a $PUSH_INTERNAL_DOC -eq 1 ]; then
	if [ -v REMOTE_USER -a -v REMOTE_SERVER -a -v REMOTE_PATH ]; then
	    rsync -v -r -t -e 'ssh -i $ROOT_DIRECTORY/keys/snapshot-manager_rsa' --delete $ROOT_DIRECTORY/dynare-matlab-m2html $REMOTE_USER@$REMOTE_SERVER:$REMOTE_PATH
	    rsync -v -r -t -e 'ssh -i $ROOT_DIRECTORY/keys/snapshot-manager_rsa' --delete $ROOT_DIRECTORY/dynare-internals $REMOTE_USER@$REMOTE_SERVER:$REMOTE_PATH
	else
	    echo "Could not push internal documentation!"
	    echo "Please set REMOTE_USER, REMOTE_DIRECTORY and REMOTE_PATH in configuration file."
	fi
    fi
fi

# Clean build and snapshot directories
delete_oldest_folders $GITREPO_DIRECTORY $N_SNAPSHOTS_TO_KEEP
delete_oldest_folders $BUILDS_DIRECTORY $N_SNAPSHOTS_TO_KEEP
delete_oldest_files_with_given_extension $SOURCES_DIRECTORY tar.xz $N_SNAPSHOTS_TO_KEEP
delete_oldest_files_with_given_extension $WINDOWS_EXE_DIRECTORY exe $N_SNAPSHOTS_TO_KEEP
delete_oldest_files_with_given_extension $WINDOWS_ZIP_DIRECTORY zip $N_SNAPSHOTS_TO_KEEP

# Push snapshot on server
if [ -v PUSH_SNAPSHOT_SRC -a $PUSH_SNAPSHOT_SRC -eq 1 ]; then
    if [ -v REMOTE_USER -a -v REMOTE_SERVER -a -v REMOTE_PATH ]; then
	rsync -v -r -t -e 'ssh -i $ROOT_DIRECTORY/keys/snapshot-manager_rsa' --delete $ROOT_DIRECTORY/tar/ $REMOTE_USER@$REMOTE_SERVER:$REMOTE_PATH/snapshot/source/
    else
	echo "Could not push source tarball!"
	echo "Please set REMOTE_USER, REMOTE_DIRECTORY and REMOTE_PATH in configuration file."
    fi
fi

if [ -v PUSH_SNAPSHOT_EXE -a $PUSH_SNAPSHOT_EXE -eq 1 ]; then
    if [ -v REMOTE_USER -a -v REMOTE_SERVER -a -v REMOTE_PATH ]; then
	rsync -v -r -t -e 'ssh -i $ROOT_DIRECTORY/keys/snapshot-manager_rsa' --delete $ROOT_DIRECTORY/win/ $REMOTE_USER@$REMOTE_SERVER:$REMOTE_PATH/snapshot/windows/
    else
	echo "Could not push windows installer!"
	echo "Please set REMOTE_USER, REMOTE_DIRECTORY and REMOTE_PATH in configuration file."
    fi
fi

if [ -v PUSH_SNAPSHOT_ZIP -a $PUSH_SNAPSHOT_ZIP -eq 1 ]; then
   if [ -v REMOTE_USER -a -v REMOTE_SERVER -a -v REMOTE_PATH ]; then
       rsync -v -r -t -e 'ssh -i $ROOT_DIRECTORY/keys/snapshot-manager_rsa' --delete $ROOT_DIRECTORY/zip/ $REMOTE_USER@$REMOTE_SERVER:$REMOTE_PATH/snapshot/windows-zip/
   else
       echo "Could not push windows zip archive!"
       echo "Please set REMOTE_USER, REMOTE_DIRECTORY and REMOTE_PATH in configuration file."
   fi
fi
