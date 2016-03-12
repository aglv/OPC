#!/bin/sh

set -e

d=`pwd`

if [ ! -f doc/index.html ] ; then
	cd doc
	git submodule update --init
	cd ..
fi

if [ ! -f libopc/configure ] ; then
	cd libopc
	git submodule update --init
	cd ..
fi

rm -Rf build/libopc
cp -af libopc build/

cd build/libopc
doxygen Doxyfile

cd ../..

cp -af build/libopc/doc/html/* doc/

exit 0



echo "Warning: pandoc XML/HTML to MD conversion doesn't work properly for us..."

cd doc/md
find . -name '*.html' | while read html; do
	pandoc -f html -t markdown -s "$html" -o "${html%.*}.md"
	rm "$html"
done

exit 1

cd "$d"
rm -rf wiki/*
cp -Rf build/libopc/doc/md/* wiki/

cd wiki
mkdir -p images
mv *.png images/
#rm *.css
#rm *.js
#mv indexpage.md Home.md

exit 0
