#!/bin/sh

d=`pwd`

cd build/libopc
doxygen Doxyfile

rm -Rf doc/md
cp -Rf doc/html doc/md

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
