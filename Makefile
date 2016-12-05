.PHONY: libs build clean-libs

NTHREADS=$(shell echo `nproc --all`)

all: build

libs:
	make -C libs -j$(NTHREADS) build
	make -C libs -j$(NTHREADS) octave-libs
	make -C libs -j$(NTHREADS) install-matlab-files

clean-libs:
	make -C libs clean-all

signature/osslsigncode:
	git clone git://git.code.sf.net/p/osslsigncode/osslsigncode signature/source
	cd signature/source && git reset --hard e72a1937d1a13e87074e4584f012f13e03fc1d64 && ./autogen.sh && ./configure && make 
	mv signature/source/osslsigncode signature/osslsigncode

clean-osslsigncode:
	rm -rf signature/*
