#!/bin/bash

# Set this to relevant path to Vampire executable
VAMPIRE=$HOME/Forrit/buildvampire/bin/vampire_z3_rel_rule-induction-sorting_7011

# Set default timeout (seconds) for Vampire
VAMPIRE_TIMEOUT=5

# Vampire syntax
PROBLEMS=$HOME/Code/benchmarks/vampireSyntax/tipvampire240123/nolemmas240123

# With QS lemmas
WITHLEMMAS=$HOME/Code/benchmarks/vampireSyntax/tipSpec240125

outputfile=$HOME/2023/VampSpec/benchmarking/tipbenchmarking240127.csv
# uncomment if outputfile should be created
echo "folder_name,problem,no_ind,no_lemmas,with_lemmas,no_lemmas_tt,with_lemmas_tt" > $outputfile

logdir=$HOME/2023/VampSpec/benchmarking/240127

# arg 1: Prover timeout in seconds
# arg 2: the filename
# arg 3: log file name
prove_no_ind() {
	$VAMPIRE --time_limit $1 --proof off --input_syntax smtlib2 $2 > $3
}
# vanilla structural induction
# Additionally, one can experiment with these options, but some of them are really explosive or might easily lose proofs. "-indgen on -sik all -fnrw on -indstrhyp on -thsq on"
prove_ind_struct() {
	  $VAMPIRE --time_limit $1 -ind struct -indoct on -to lpo -drc off -nui on --input_syntax smtlib2 -stat full $2 > $3
}
prove_ind_trained() {
    $VAMPIRE --input_syntax smtlib2 --mode portfolio --schedule struct_induction -stat full --time_limit $1 $2 > $3
}
prove_ind_tip_trained() {
    $VAMPIRE --input_syntax smtlib2 --mode portfolio --schedule struct_induction_tip -stat full --time_limit $1 $2 > $3
}
prove_ind_int() {
    $VAMPIRE --input_syntax smtlib2 --time_limit $1 -ind int -indoct on -iik all -stat full $2 > $3
}
prove_ind_oeis_trained() {
    $VAMPIRE --input_syntax smtlib2 --mode portfolio --schedule intind_oeis -stat full --time_limit $1 $2 > $3
}

# arg 1: vampire timeout
# arg 2: problem filename
# TODO make a method that calls tip-spec before calling vampire
prove_with_lemmas() {
    prove_ind_trained $1 $2
}

cd $PROBLEMS

for folder_name in isaplanner prod tip2015; do
    echo "processing problems in $folder_name"
    cd $folder_name
    mkdir $logdir/$folder_name
    for file_name in *; do
        echo "processing problem file: $file_name"
        problemname=$(basename $file_name .smt2)
        mkdir $logdir/$folder_name/$problemname
        logfolder=$logdir/$folder_name/$problemname
        echo "processing problem: $problemname"
        no_ind=0
        no_lemmas=0
        with_lemmas=0
        no_lemmas_tt=0
        with_lemmas_tt=0
        specfilename=$WITHLEMMAS/$folder_name/$file_name
        noindlog=$logfolder/noind.log
        noindlemmaslog=$logfolder/noind-withlemmas.log
        vanindlog=$logfolder/vanind.log
        vanindlemmaslog=$logfolder/vanind-withlemmas.log
        trainindlog=$logfolder/trainind.log
        trainindlemmaslog=$logfolder/trainind-withlemmas.log
        if prove_no_ind $VAMPIRE_TIMEOUT $file_name $noindlog
        then
            no_ind=1
        fi
        if prove_no_ind $VAMPIRE_TIMEOUT $specfilename $noindlemmaslog
        then
            no_ind=1
        fi
        if prove_ind_struct $VAMPIRE_TIMEOUT $file_name $vanindlog
        then
            no_lemmas=1
        fi
        if prove_ind_struct $VAMPIRE_TIMEOUT $specfilename $vanindlemmaslog
        then
            with_lemmas=1
        fi
        if prove_ind_tip_trained $VAMPIRE_TIMEOUT $file_name $trainindlog
        then
            no_lemmas_tt=1
        fi
        if prove_ind_tip_trained $VAMPIRE_TIMEOUT $specfilename $trainindlemmaslog
        then
            with_lemmas_tt=1
        fi
        echo "$folder_name,$problemname,$no_ind,$no_lemmas,$with_lemmas,$no_lemmas_tt,$with_lemmas_tt" >> $outputfile
    done
    cd ..
done
