#!/bin/bash

th3IfdeftoifDir=/home/$USER/th3_generated_performance
resultDir=~/sqlite
jobExportDir=$resultDir/pf_$1
if [ $USER == "rhein" ]; then
    th3IfdeftoifDir=/home/garbe/th3_generated_performance
fi

TESTDIRS=$(find ../TH3 -name '*test' ! -path "*/TH3/stress/*" -printf '%h\n' | sort -u | wc -l)
CFGFILES=$(find ../TH3/cfg/ -name "*.cfg" ! -name "cG.cfg" | wc -l)
#IFCONFIGS=$(find ../TypeChef-SQLiteIfdeftoif/optionstructs_ifdeftoif/featurewise/generated/ -name "id2i_optionstruct_*.h" | wc -l)
TOTAL=$(( $TESTDIRS * $CFGFILES ))

TESTDIRNO=$(( ($1 / $CFGFILES) + 1 ))
TH3CFGNO=$(( ($1 % $CFGFILES)  + 1 ))
TH3IFDEFNO=$1

if [ $1 -lt $TOTAL ]; then
    cd ..
    rm -rf tmppfpredict_$1
    mkdir tmppfpredict_$1
    cd tmppfpredict_$1

    # find $1'th sub directory containing .test files, excluding stress folder
    TESTDIR=$(find ../TH3 -name '*test' ! -path "*/TH3/stress/*" -printf '%h\n' | sort -u | head -n $TESTDIRNO | tail -n 1)
    TESTDIRBASE=$(basename $TESTDIR)

    # find $3'th .cfg
    TH3CFG=$(find ../TH3/cfg/ -name "*.cfg" ! -name "cG.cfg" | sort | head -n $TH3CFGNO | tail -n 1)
    TH3CFGBASE=$(basename $TH3CFG)

    # count .test files
    TESTFILENO=$(find $TESTDIR -name "*.test" | wc -l)

    cd ../TH3
    # Ignore ctime03.test since it features a very large struct loaded with 100 different #ifdefs & #elses
    # Ignore date2.test since it returns the systems local time; this makes string differences in test results impossible
    TESTFILES=$(find $TESTDIR -name "*.test" ! -name "ctime03.test" ! -name "date2.test" | sort)
    ./mkth3.tcl $TESTFILES "$TH3CFG" > ../tmppfpredict_$1/th3_generated_test.c
    cd ../tmppfpredict_$1

    #insert performance function at the start and end of the main function
    sed -i '1s/^/#include "\.\.\/Hercules\/performance\/noincludes.c"\n#include "\.\.\/Hercules\/performance\/perf_measuring\.c"\n/' th3_generated_test.c
    sed -i 's/int main(int argc, char \*\*argv){/int main(int argc, char \*\*argv){\n  id2iperf_time_start()\;/' th3_generated_test.c
    sed -i 's/return nFail\;/id2iperf_time_end()\;\n  return nFail\;/' th3_generated_test.c

    cp ../TypeChef-SQLiteIfdeftoif/sqlite3.h sqlite3.h

    if ! cp $th3IfdeftoifDir/sqlite3_performance_$TH3IFDEFNO.c sqlite3_performance.c &> /dev/null ; then
        ./../TypeChef-SQLiteIfdeftoif/parallel_th3_test_performance.sh $1
    fi

    for config in ../TypeChef-SQLiteIfdeftoif/optionstructs_ifdeftoif/featurewise/generated/id2i_optionstruct_*.h; do
        # find $2'th optionstruct
        IFCONFIG=$config
        IFCONFIGBASE=$(basename $IFCONFIG)

        #sed filters everything but the number of the configuration
        configID=$(basename $IFCONFIG | sed 's/id2i_optionstruct_//' | sed 's/.h//')

        # Copy files used for compilation into temporary directory
        cp $IFCONFIG id2i_optionstruct.h

        if cp $th3IfdeftoifDir/sqlite3_performance_$TH3IFDEFNO.c sqlite3_performance.c; then
            echo "performance testing: jobid $1 ifdeftoif $TH3IFDEFNO; #ifConfig $IFCONFIGBASE on $TESTFILENO .test files in $TESTDIRBASE with th3Config $TH3CFGBASE at $(date +"%T")"

            performanceGCC=$(gcc -w -DSQLITE_OMIT_LOAD_EXTENSION -DSQLITE_THREADSAFE=0 sqlite3_performance.c 2>&1)
            # gcc returns errors
            if [ $? != 0 ]; then
                echo "can not compile performance file"
            else
                # Run ifdeftoif binary
                #echo -e "\n\n-= Hercules Performance =-\n"
                ./a.out > tmp_res_$configID.txt 2>&1
                # Clear temporary simulator files
                rm -rf *.db
                rm -rf *.out
                rm -rf *.lock
            fi
        fi
    done

    lastNO=$(( $(find . -name "tmp_res_*.txt" | wc -l) - 1))
    lastID=$(printf "%03d" $lastNO)
    for configResult in ./tmp_res_*.txt; do
        #sed filters everything but the number of the configuration
        configID=$(basename $configResult | sed 's/tmp_res_//' | sed 's/.txt//')
        configNO=$(echo $configID | sed 's/^0*//')
        if [ "$configID" == "000" ]; then
            configNO="0"
        fi
        for i in $(seq $configNO $lastNO); do
            cat $configResult >> aggregated_$i.txt
        done
    done
    for configResult in `ls -v ./aggregated_*.txt`; do
        #sed filters everything but the number of the configuration
        configID=$(basename $configResult | sed 's/tmp_res_//' | sed 's/.txt//' | printf "%03d")
        java -jar ../Hercules/performance/PerfTimes.jar $configResult ../TypeChef-SQLiteIfdeftoif/optionstructs_ifdeftoif/performance/allyes_include.h
    done

    originalGCC=$(gcc -w -DSQLITE_OMIT_LOAD_EXTENSION -DSQLITE_THREADSAFE=0 \
    -I /usr/local/include \
    -I /usr/lib/gcc/x86_64-linux-gnu/4.8/include-fixed \
    -I /usr/lib/gcc/x86_64-linux-gnu/4.8/include \
    -I /usr/include/x86_64-linux-gnu \
    -I /usr/include \
    -include "../TypeChef-SQLiteIfdeftoif/optionstructs_ifdeftoif/performance/allyes_include.h" \
    -include "../TypeChef-SQLiteIfdeftoif/partial_configuration.h" \
    -include "../TypeChef-SQLiteIfdeftoif/sqlite3_defines.h" \
    ../TypeChef-SQLiteIfdeftoif/sqlite3_original.c th3_generated_test.c 2>&1)

    if [ $? != 0 ]
    then
        echo -e $originalGCC
        echo -e "\n\ncan not compile original gcc file"
    else
        # Run normal binary
        echo -e "-= Original Binary =-"
        result=$(./a.out 2>&1 | grep "Total time:")
        echo -e $result
        # Clear temporary variant files
        rm -rf *.out
        rm -rf *.db
        rm -rf *.lock
    fi

    cp ../TypeChef-SQLiteIfdeftoif/optionstructs_ifdeftoif/performance/allyes_optionstruct.h id2i_optionstruct.h
    performanceGCC=$(gcc -w -DSQLITE_OMIT_LOAD_EXTENSION -DSQLITE_THREADSAFE=0 sqlite3_performance.c 2>&1)
    # gcc returns errors
    if [ $? != 0 ]; then
        echo "can not compile performance file"
    else
        # Run ifdeftoif binary
        echo -e "-= Hercules Performance =-"
        result=$(./a.out 2>&1 | grep "Total time:")
        echo -e $result
        # Clear temporary simulator files
        rm -rf *.db
        rm -rf *.out
        rm -rf *.lock
    fi

    cd ..
    #rm -rf tmppfpredict_$1
fi