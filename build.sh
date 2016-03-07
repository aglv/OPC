#!/bin/sh

d=`pwd`

if [ ! -f build/libopc.zip ] ; then
	echo "Please download the libopc archive from https://libopc.codeplex.com/SourceControl/latest# and move the downloaded zip file to $d/build/libopc.zip"
	exit 1
fi

mkdir -p build
rm -Rf build/libopc

ditto -xk build/libopc.zip build/libopc
export MACOSX_DEPLOYMENT_TARGET=10.7

function build {
	platform="$1"
	target="$2"
	architectures="$3"

	./configure --platform="$platform" --target="$target" --arch="$architectures"
	
	archs=''
	while IFS=',' read -ra architecture; do
		for arch in "${architecture[@]}"; do
			archs="-arch $arch $archs"
		done
	done <<< "$architectures"
	
	echo "fixing Makefiles CPPFLAGS to $archs"
	
	find "build/$platform" -name 'Makefile*' | while read m; do
		sed -i '' -e "s/^CPPFLAGS=-arch x86_64/CPPFLAGS=$archs/g" "$m"
	done
	
	make
	
	cd "build/$platform/static"
	
	mkdir tmp
	archs=''
	while IFS=',' read -ra architecture; do
		for arch in "${architecture[@]}"; do
			mkdir "tmp/$arch"
			cd "tmp/$arch"
			
			for a in libopc libmce libplib; do
				lipo "../../$a.a" -thin "$arch" -output "$a.a"
				ar -x "$a.a"
			done
			
			ar -qc lib.a *.o
			
			cd ../..
			archs="$archs tmp/$arch/lib.a"
		done
	done <<< "$architectures"
	
	mkdir -p OPC.framework/Versions/A
	lipo $archs -create -output OPC.framework/Versions/A/OPC
		
	rm -Rf tmp
	
	mkdir -p OPC.framework/Versions/A/Headers/opc
	cp ../../../opc/*.h OPC.framework/Versions/A/Headers/opc
	cp ../../../config/opc/*.h OPC.framework/Versions/A/Headers/opc
	mkdir -p OPC.framework/Versions/A/Headers/mce
	cp ../../../mce/*.h OPC.framework/Versions/A/Headers/mce
	cp ../../../config/mce/*.h OPC.framework/Versions/A/Headers/mce
	mkdir -p OPC.framework/Versions/A/Headers/plib
	cp include/build_plib_config_platform_plib_include/plib/* OPC.framework/Versions/A/Headers/plib
	
	cd OPC.framework/Versions/A/Headers
	rm -f OPC.h
	
	echo "// OPC.framework built by Alessandro Volz, © 2016 volz.io\n" >> OPC.h
	find . -name '*.h' | while read header; do
		if [ "$header" = "./OPC.h" ]; then continue; fi
		
		name="${header##*/}"
		dir="${header%$name}"
		dir="${dir:2}"

		echo "#import \"$dir$name\"" >> OPC.h

		sed -i '' -e "s/^\(#[ ]*include \)<${dir//\//\\/}\(.*\)>/\1\"\2\"/g" "$header"
	
	    sed -i '' -e "s/^\(#[ ]*include \)<\(opc\/.*\)>/\1\"..\/\2\"/g" "$header"
	    sed -i '' -e "s/^\(#[ ]*include \)<\(mce\/.*\)>/\1\"..\/\2\"/g" "$header"
	    sed -i '' -e "s/^\(#[ ]*include \)<\(plib\/.*\)>/\1\"..\/\2\"/g" "$header"
	done
	
	cd ../..
	ln -s A Current
	cd ..
	ln -s Versions/Current/OPC OPC
	ln -s Versions/Current/Headers Headers
}

for target in release debug; do
	cd "$d/build/libopc"
	
	build "darwin-$target-gcc-universal" "$target" "x86_64,i386"
	
	rm -Rf "$d/libs/$target/OPC.framework"
	cp -af "$d/build/libopc/build/darwin-$target-gcc-universal/static/OPC.framework" "$d/libs/$target/"
done

echo done
exit 0;
