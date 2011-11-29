all:
	mxmlc -static-link-runtime-shared-libraries -compiler.source-path=. test/Test.as -output Test.swf

clean:
	find -type f -name "*~" -exec rm -f {} \;
	rm -f *.swf
