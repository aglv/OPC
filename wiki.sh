#!/bin/sh

d=`pwd`

cd build/libopc
doxygen Doxyfile

rm -Rf doc/md
cp -Rf doc/xml doc/md

echo "Warning: pandoc XML to MD conversion doesn't work properly for us..."

cd doc/md
find . -name '*.xml' | while read xml; do
	pandoc -f docbook -t markdown -s "$xml" -o "${xml%.*}.md"
	rm "$xml"
done

exit 1

cd "$d"
rm -rf wiki/*
cp -Rf build/libopc/doc/md/* wiki/

cd wiki
mv indexpage.md Home.md

exit 0
