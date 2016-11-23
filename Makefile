.PHONY: build-libs clean-libs

build-libs:
	make -C libs build
	make -C libs octave-libs
	make -C libs install-matlab-files

clean-libs:
	make -C libs clean-all
