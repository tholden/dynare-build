# Cross compilation of Dynare for Windows (32 and 64 bits)

## Compilation

   First you will have to build and install the libraries needed by dynare. This is done within the `dynare-libs` submodule, which you have first to install:
   ```bash
   ~$ git submodule init
   ~$ git submodule update
   ```
   Then just do
   ```
   ~$ make build 
   ```
   The libraries in `dynare-libs` will be cross-compiled and then dynare (with mex files) will be cross-compiled.
   

## Requirements
   All the requirements of `dynare-libs` submodule, and:
   ```bash
   ~$ sudo apt-get install parallel libtool pkg-config libssl-dev libcurl4-openssl-dev flex bison gfortran libsuitesparse-dev texlive texlive-publishers texlive-extra-utils texlive-formats-extra texlive-latex-extra texlive-math-extra texlive-fonts-extra latex-beamer texinfo texi2html latex2html doxygen gcc-multilib g++-multilib gfortran-multilib nsis zip libboost-dev
   ```
