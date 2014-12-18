#!/bin/bash

#./ifdeftoif_mod.sh

for th3configFile in ../TH3/cfg/*.cfg;
do
	#generate test
	cd ../TH3
	./mkth3.tcl bugs/*.test "$th3configFile" > ../TypeChef-SQLiteIfdeftoif/th3_generated_test.c
	cd ../TypeChef-SQLiteIfdeftoif
	
	#insert /* Alex: added initialization of our version of the azCompileOpt array */ init_azCompileOpt();
	sed -i \
		's/int main(int argc, char \*\*argv){/int main(int argc, char \*\*argv){\/* Alex: added initialization of our version of the azCompileOpt array *\/ init_azCompileOpt()\;/' \
		th3_generated_test.c
	#better never touch this sed again
	
	for f in ./optionstructs_ifdeftoif/feature-wise/id2i_optionstruct*.h;
	do
		#sed filters everything but the number of the configuration
		configID=$(basename $f | sed 's/id2i_optionstruct_//' | sed 's/.h//')
		
		echo "testing #ifConfig $f on th3Config $th3configFile"
		cp $f ../ifdeftoif/id2i_optionstruct.h
		rm -f a.out
		gcc -w -DSQLITE_OMIT_LOAD_EXTENSION -DSQLITE_THREADSAFE=0 \
			-include "./optionstructs_ifdeftoif/feature-wise/id2i_include_$configID.h" \
			sqlite3_ifdeftoif.c th3_generated_test.c
		#disabled all warnings! -w
		./a.out
		echo "TH3 test result: $?\n"
		if ($? == $expectedOutputValue) then
			echo "Test successful\n"
		else 
			echo "Test result differs\n"
		fi
		rm -f a.out
	done
done
