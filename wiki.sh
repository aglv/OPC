#!/bin/sh

d=`pwd`

cd build/libopc
doxygen Doxyfile

rm -Rf doc/md
cp -Rf doc/xml doc/md

cd doc/md
find . -name '*.xml' | while read xml; do
	pandoc -f docbook -t markdown -s "$xml" -o "${xml%.*}.md"
	rm "$xml"
done

cd "$d"
rm -rf wiki/*
cp -Rf build/libopc/doc/md/* wiki/

cd wiki
mv index.md Home.md

exit 0
