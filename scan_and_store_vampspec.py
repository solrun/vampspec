#!/usr/bin/env python3

# Code for parsing vampire output logs into a dictionary and storing all the data in a pickle.
# Thanks to Martin Suda for the original version of this code!

from curses import longname
from pickletools import long4
import sys, os

import pickle
import gzip
import math
from collections import defaultdict

if __name__ == "__main__":
  # to be run as in: ./scan_and_store_inst.py folder_name_with_output_logs
  # In this case the output folder is labeled by date
  # contains subfolders for tip subsets which contain a
  # subdirectory for each problem, which contains log files named for the proof strategy employed

  # might encounter a meta-file whose content we forward to the pickle we create!
  meta = None
  results = defaultdict(dict) # probname -> {'method1':(result, time, mega_instr, activations, proof length, inductions), 'method2': ...}

  outputfolders = sys.argv[2:]
  for outputfolder in outputfolders:
    if outputfolder.endswith("/"):
      outputfolder = outputfolder[:-1]


    subfolders = [f.path for f in os.scandir(outputfolder) if f.is_dir()]
    for subfolder in subfolders:
      root, problems, files = next(os.walk(subfolder))
      for problem in problems:
        problempath = os.path.join(root,problem)
        problemname = problempath.split('/',1)[1]
        print('Processing problem: ',problemname)
        logfiles = [f.name for f in os.scandir(problempath)]
        for filename in logfiles:
          longname = os.path.join(problempath,filename)
          #print(longname)
          if filename == "meta.info":
            with open(longname, "r") as f:
              # the first line in this file (minus the final endl)
              new_meta = next(f)[:-1]
              print(new_meta)

            continue

          # print(filename)
          assert filename.endswith(".log")

          proofmethod = filename[:-4]
          #print(proofmethod)

          with open(longname, "r") as f:
            result = None
            time = None
            instructions = 0
            activations = 0
            inductions = 0
            indinproof = 0
            indapps = 0
            length = 0
            disregard = False

            for line in f:
            # vampiric part:
              if (line.startswith("% SZS status Timeout for") or line.startswith("% SZS status GaveUp") or
                  line.startswith("% Time limit reached!") or line.startswith("% Refutation not found, incomplete strategy") or
                  line.startswith("% Instruction limit reached!") or
                  line.startswith("% Refutation not found, non-redundant clauses discarded") or
                  line.startswith("Unsupported amount of allocated memory:") or
                  line.startswith("Memory limit exceeded!")):
                result = "---"

              if line.startswith("% SZS status Unsatisfiable") or line.startswith("% SZS status Theorem") or line.startswith("% SZS status ContradictoryAxioms"):
                result = "uns"
              if line.startswith("% SZS status Satisfiable") or line.startswith("% SZS status CounterSatisfiable"):
                result = "sat"

              if line.startswith("Parsing Error on line"):
                result = "err"

              if line.startswith("% Time elapsed:"):
                time = float(line.split()[-2])

              if line.startswith("% Instructions burned:"):
                  # "% Instructions burned: 361 (million)"
                instructions = int(line.split()[-2])

              if line.startswith("% Activations started:"):
                activations = int(line.split()[-1])

              if line.startswith("% Success in time"):  # in the case of portfolio mode, overwrite the startegy's reported time
                time = float(line.split()[-2])

              if line.startswith("% StructuralInduction:"):
                inductions = int(line.split()[-1])

              if line.startswith("% StructuralInductionInProof:"):
                indinproof = int(line.split()[-1])

              if line.startswith("% InductionApplications:"):
                indapps = int(line.split()[-1])
              if line[0].isnumeric():
                length = length + 1
            if proofmethod in results[problemname].keys():
              # This should only happen if a proof was found with a bigger timeout and that output was already encountered
              disregard = True
            if "biggertimeout" in proofmethod:
              if  result == "---":
                disregard = True
              elif result == "uns":
                proofmethod = proofmethod.replace('-biggertimeout','')
                if proofmethod == 'trainind_5':
                  proofmethod = 'trainind'
            if not disregard:
              results[problemname][proofmethod] = (result,time,instructions,activations,inductions,indinproof,indapps,length)
          #print(problemname,results[problemname])
  pklname = sys.argv[1]
  pklname += ".pkl"
  print("Saving",pklname)
  with open(pklname,'wb') as f:
    pickle.dump((meta,results),f)
