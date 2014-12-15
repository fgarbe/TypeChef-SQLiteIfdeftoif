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
	
	for f in ./optionstructs_ifdeftoif/id2i_optionstruct*.h;
	do
		echo "testing #ifConfig $f on th3Config $th3configFile"
		cp $f ../ifdeftoif/id2i_optionstruct.h
		rm -f a.out
		gcc -w -DSQLITE_OMIT_LOAD_EXTENSION -DSQLITE_THREADSAFE=0 sqlite3_ifdeftoif.c th3_generated_test.c
		#disabled all warnings! -w
		./a.out
		echo $?
		rm -f a.out
	done
done