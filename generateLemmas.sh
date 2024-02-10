#!/bin/bash

# Translate benchmarks to Vampire-friendly syntax
# Generate lemmas using QuickSpec (via tip-spec)

cd benchmarks

outputfile=$HOME/2023/VampSpec/vampspecTIP240125.csv
# uncomment if outputfile should be created
#echo "folder_name,problem,default_settings,skip_predicates,with_observers,size_5,smaller_params,int_is_nat" > $outputfile
#mkdir ../vampireSyntax/tipSpec240125

for folder_name in prod isaplanner tip2015 ; do
    echo "processing problems in $folder_name"
    #mkdir -p ../vampireSyntax/tipSpec240125/$folder_name
    cd $folder_name
    for file_name in *; do
        echo "processing problem file: $file_name"
        vfilename=../../vampireSyntax/tipSpec240125/$folder_name/$file_name
        problemname=$(basename $file_name .smt2)
        default_settings=0
        skippredicates=0
        withobservers=0
        size5=0
        smallerparams=0
        intisnat=0

        if [ -f "$vfilename" ]
        then
            echo "previously processed"
        else
            default_settings=1
            timeout 1m tip-spec --prune --size 7 $file_name +RTS -M8g | tip --vampire > $vfilename
        fi
        if [ ! -s "$vfilename" ]
        then
            # try without predicates if previous exploration timed out
            skippredicates=1
            timeout 1m tip-spec --prune --size 7 --predicates "" $file_name +RTS -M8g | tip --vampire > $vfilename
        fi
        if [ ! -s "$vfilename" ]
        then
            # try with observers if both previous attempts timed out
            withobservers=1
            timeout 1m tip-spec --prune --size 7 --observers --depth 3 --test-size 5 $file_name +RTS -M8g | tip --vampire > $vfilename
        fi
        if [ ! -s "$vfilename" ]
        then
            # try with ints as nats if previous attempt timed out
            withobservers=0
            intisnat=1
            timeout 1m tip-spec --prune --size 7 --depth 3 --test-size 5 --predicates "" --int-is-nat $file_name +RTS -M8g| tip --vampire > $vfilename
        fi
        if [ ! -s "$vfilename" ]
        then
            # try with smaller parameters if previous attempt timed out
            intisnat=0
            size5=1
            smallerparams=1
            timeout 2m tip-spec --prune --size 5 --depth 2 --test-size 4 --predicates "" $file_name +RTS -M8g| tip --vampire > $vfilename
        fi
        if [ ! -s "$vfilename" ]
        then
            # try with smaller parameters and observers if previous attempt timed out
            withobservers=1
            timeout 2m tip-spec --prune --size 5 --depth 2 --test-size 4 --predicates "" --observers $file_name -T 100 +RTS -M8g| tip --vampire > $vfilename
        fi
        if [ ! -s "$vfilename" ]
        then
            # try with smaller parameters and int as nat if previous attempt timed out
            intisnat=1
            withobservers=0
            timeout 2m tip-spec --prune --size 5 --depth 2 --test-size 4 --predicates "" --int-is-nat $file_name -T 100 +RTS -M8g| tip --vampire > $vfilename
        fi
        echo "$folder_name,$problemname,$default_settings,$skippredicates,$withobservers,$size5,$smallerparams,$intisnat" >> $outputfile

    done
    cd ..
done
