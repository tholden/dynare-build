.PHONY: libs build clean-libs install

NTHREADS=$(shell echo `nproc --all`)

all: build

libs:
	make -C libs -j$(NTHREADS) build
	make -C libs -j$(NTHREADS) octave-libs
	make -C libs -j$(NTHREADS) install-matlab-files

clean-libs:
	make -C libs clean-all

clean:
	rm -f win/*
	rm -f tar/*
	rm -rf builds/*
	rm -rf git/*
	rm -rf git/*
	rm -rf signature/source
	rm -f dynare-object-signing.p12.gpg
	rm -f dynare-object-signing.p12
	rm -f snapshot-manager-key.tar.gpg
	rm -f snapshot-manager-key.tar
	rm -rf keys

cleanall: clean-libs clean

install:
	./install-packages.sh

build: libs signature/osslsigncode dynare-object-signing.p12 keys/snapshot-manager_rsa.pub m2html/Contents.m
	./build.sh

signature/osslsigncode:
	rm -rf signature/source
	git clone git://git.code.sf.net/p/osslsigncode/osslsigncode signature/source
	cd signature/source && git reset --hard e72a1937d1a13e87074e4584f012f13e03fc1d64 && ./autogen.sh && ./configure && make 
	mv signature/source/osslsigncode signature/osslsigncode

clean-osslsigncode:
	rm -rf signature/*

dynare-object-signing.p12.gpg:
	wget http://www.dynare.org/dynare-build/dynare-object-signing.p12.gpg

dynare-object-signing.p12: dynare-object-signing.p12.gpg
	./dynare-object-signing.p12.sh

snapshot-manager-key.tar.gpg:
	wget http://www.dynare.org/dynare-build/snapshot-manager-key.tar.gpg

snapshot-manager-key.tar: snapshot-manager-key.tar.gpg
	./snapshot-manager-key.tar.sh

keys/snapshot-manager_rsa.pub: snapshot-manager-key.tar
	mkdir -p keys
	tar -xvf snapshot-manager-key.tar -C keys

m2html.zip:
	wget http://www.artefact.tk/software/matlab/m2html/m2html.zip

m2html/Contents.m: m2html.zip
	unzip m2html
