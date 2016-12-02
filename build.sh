#!/bin/sh

# Produces Dynare snapshot (tarball and windows installer).

# (C) DynareTeam 2016

# Exit on first error
set -ex

# Set the number of threads
NTHREADS=`nproc --all`

# Load shell functions
. ./tools.sh

# Load the configuration file
if [ -f "configuration.inc" ]
then
    echo "Found configuration file!"
    . ./configuration.inc
else
    tput setaf 1; echo "I did not find any configuration file! Use defaults"
    GIT_REMOTE=https://github.com/DynareTeam/dynare.git
    GIT_BRANCH=master
    VERSION=
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

# Get current directory
SNAPSHOT_DIRECTORY=`pwd`

# Set directories for libraries
LIB32=$SNAPSHOT_DIRECTORY/libs/lib32
LIB64=$SNAPSHOT_DIRECTORY/libs/lib64

# Set name of directories
GITREPO_DIRECTORY=$SNAPSHOT_DIRECTORY/git
GITWORK_DIRECTORY=$GITREPO_DIRECTORY/$LAST_HASH
SOURCES_DIRECTORY=$SNAPSHOT_DIRECTORY/tar
WINDOWS_DIRECTORY=$SNAPSHOT_DIRECTORY/win
BUILDS_DIRECTORY=$SNAPSHOT_DIRECTORY/builds
THIS_BUILD_DIRECTORY=$BUILDS_DIRECTORY/$BASENAME

# Test if there is something new on the remote.
if [ -d "$GITWORK_DIRECTORY" ]; then
    if [ -f "$SOURCES_DIRECTORY/$BASENAME.tar.xz"  ]; then
	if [ -f "$WINDOWS_DIRECTORY/$BASENAME-win.exe" ]; then
	    tput setaf 1; echo "Dynare ($LAST_HASH) has already been compiled!"
	    exit 1
	else
	    rm -rf $GITWORK_DIRECTORY
	    rm $SOURCES_DIRECTORY/$BASENAME.tar.xz
	fi
    else
	rm -rf $GITWORK_DIRECTORY
    fi
fi

# Clone remote branch
git clone --recursive --depth 1 --branch $GIT_BRANCH $GIT_REMOTE $GITWORK_DIRECTORY

# Clean build directories
delete_oldest_folders $GITREPO_DIRECTORY 10
delete_oldest_folders $BUILDS_DIRECTORY 10
delete_oldest_files_with_given_extension $SOURCES_DIRECTORY tar.xz 10
delete_oldest_files_with_given_extension $WINDOWS_DIRECTORY exe 10
delete_oldest_files_with_given_extension $WINDOWS_DIRECTORY zip 10

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
mv $BASENAME.tar.xz $SOURCES_DIRECTORY

# Extract tarball in BUILDS_DIRECTORY
cd $SOURCES_DIRECTORY
tar xavf $BASENAME.tar.xz -C $BUILDS_DIRECTORY  

# Go to the build directory
cd $THIS_BUILD_DIRECTORY

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
make -j$NTHREADS all pdf html
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

# Create Windows 32-bit DLL binaries for MATLAB R2008b
cd mex/build/matlab
./configure --host=i686-w64-mingw32 \
	    --with-boost=$LIB32/Boost \
	    --with-gsl=$LIB32/Gsl \
	    --with-matio=$LIB32/matIO \
	    --with-slicot=$LIB32/Slicot/without-underscore \
	    --with-matlab=$LIB32/matlab/R2008b \
	    MATLAB_VERSION=R2008b \
	    MEXEXT=mexw32 \
	    PACKAGE_VERSION=$VERSION \
	    PACKAGE_STRING="dynare $VERSION"
make clean
make -j$NTHREADS all
cd $THIS_BUILD_DIRECTORY
i686-w64-mingw32-strip mex/matlab/*.mexw32
mkdir -p mex/matlab/win32-7.5-8.6
mv mex/matlab/*.mexw32 mex/matlab/win32-7.5-8.6

# Create Windows 64-bit DLL binaries for MATLAB R2008b
cd mex/build/matlab
./configure --host=x86_64-w64-mingw32 \
	    --with-boost=$LIB64/Boost \
	    --with-gsl=$LIB64/Gsl \
	    --with-matio=$LIB64/matIO \
	    --with-slicot=$LIB64/Slicot \
	    --with-matlab=$LIB64/matlab/R2008b \
	    MATLAB_VERSION=R2008b \
	    MEXEXT=mexw64 \
	    PACKAGE_VERSION=$VERSION \
	    PACKAGE_STRING="dynare $VERSION"
make clean
make -j$NTHREADS all
cd $THIS_BUILD_DIRECTORY
x86_64-w64-mingw32-strip mex/matlab/*.mexw64
mkdir -p mex/matlab/win64-7.5-7.7
mv mex/matlab/*.mexw64 mex/matlab/win64-7.5-7.7

# Create Windows 64-bit DLL binaries for MATLAB R2008b
cd mex/build/matlab
./configure --host=x86_64-w64-mingw32 \
	    --with-boost=$LIB64/Boost \
	    --with-gsl=$LIB64/Gsl \
	    --with-matio=$LIB64/matIO \
	    --with-slicot=$LIB64/Slicot \
	    --with-matlab=$LIB64/matlab/R2009a \
	    MATLAB_VERSION=R2009a \
	    MEXEXT=mexw64 \
	    PACKAGE_VERSION=$VERSION \
	    PACKAGE_STRING="dynare $VERSION"
make clean
make -j$NTHREADS all
cd $THIS_BUILD_DIRECTORY
x86_64-w64-mingw32-strip mex/matlab/*.mexw64
mkdir -p mex/matlab/win64-7.8-9.0
mv mex/matlab/*.mexw64 mex/matlab/win64-7.8-9.0

# Create Windows DLL binaries for Octave/MinGW
cd mex/build/octave
./configure --host=i686-w64-mingw32 MKOCTFILE=$LIB32/mkoctfile --with-boost=$LIB32/Boost --with-gsl=$LIB32/Gsl --with-matio=$LIB32/matIO --with-slicot=$LIB32/Slicot/with-underscore PACKAGE_VERSION=$VERSION PACKAGE_STRING="dynare $VERSION"
make clean
make -j$NTHREADS all
cd $THIS_BUILD_DIRECTORY
i686-w64-mingw32-strip mex/octave/*.mex mex/octave/*.oct
