#!/bin/sh

set -e

d=`pwd`

if [ ! -f libopc/configure ] ; then
	cd libopc
	git submodule update --init
	cd ..
fi

export MACOSX_DEPLOYMENT_TARGET=10.7

function build {
	platform="$1"
	target="$2"
	architectures="$3"
	
	if [ ! -f "build/configure.ctx" ]; then
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
	fi
	
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
				mkdir -p "$a"; cd "$a"
				ar -x "../$a.a"
				cd ..
			done
			
			ar -qc lib.a **/*.o
			
			cd ../..
			archs="$archs tmp/$arch/lib.a"
		done
	done <<< "$architectures"
	
	mkdir -p libopc.framework/Versions/A
	lipo $archs -create -output libopc.framework/Versions/A/libopc
		
	rm -Rf tmp
	
	mkdir -p libopc.framework/Versions/A/Headers/opc
	cp ../../../opc/*.h libopc.framework/Versions/A/Headers/opc
	cp ../../../config/opc/*.h libopc.framework/Versions/A/Headers/opc
	mkdir -p libopc.framework/Versions/A/Headers/mce
	cp ../../../mce/*.h libopc.framework/Versions/A/Headers/mce
	cp ../../../config/mce/*.h libopc.framework/Versions/A/Headers/mce
	mkdir -p libopc.framework/Versions/A/Headers/plib
	cp include/build_plib_config_platform_plib_include/plib/* libopc.framework/Versions/A/Headers/plib
	
	cd libopc.framework/Versions/A/Headers
	rm -f libopc.h
	
	echo "// libopc.framework built by Alessandro Volz, © 2016 volz.io\n" >> libopc.h
	find . -name '*.h' | while read header; do
		if [ "$header" = "./libopc.h" ]; then continue; fi
		
		name="${header##*/}"
		dir="${header%$name}"
		dir="${dir:2}"

		echo "#import \"$dir$name\"" >> libopc.h

		sed -i '' -e "s/^\(#[ ]*include \)<${dir//\//\\/}\(.*\)>/\1\"\2\"/g" "$header"
	
	    sed -i '' -e "s/^\(#[ ]*include \)<\(opc\/.*\)>/\1\"..\/\2\"/g" "$header"
	    sed -i '' -e "s/^\(#[ ]*include \)<\(mce\/.*\)>/\1\"..\/\2\"/g" "$header"
	    sed -i '' -e "s/^\(#[ ]*include \)<\(plib\/.*\)>/\1\"..\/\2\"/g" "$header"
	done
	
#	cd ..
#	mkdir -p Modules
#	cd Modules
#	
#	rm -f module.modulemap
#	echo "framework module libopc {\n\tumbrella header \"libopc.h\"\n\t\n\texport *\n\tmodule * { export * }\n}" >> module.modulemap
	
	cd ../..
	ln -s A Current
	cd ..
	ln -s Versions/Current/libopc libopc
	ln -s Versions/Current/Headers Headers
#	ln -s Versions/Current/Modules Modules
}

for target in release debug; do
	cd "$d"
	
	mkdir -p "build/$target"
	cp -af libopc "build/$target/"
	cd "$d/build/$target/libopc"
	
	framework="$d/build/$target/libopc/build/darwin-$target-gcc-universal/static/libopc.framework"
	rm -Rf "$framework"

	build "darwin-$target-gcc-universal" "$target" "x86_64,i386"
	
	mkdir -p "$d/build/frameworks/$target"
	rm -Rf "$d/build/frameworks/$target/libopc.framework"
	cp -af "$framework" "$d/build/frameworks/$target/"
done

echo done
exit 0;
