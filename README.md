# vampspec
Combining Vampire and QuickSpec.

[generateLemmas.sh](generateLemmas.sh) is a script used to generate lemmas using QuickSpec (via tip-spec) and translate benchmarks to a Vampire-friendly syntax.
Benchmark files can be found at [https://github.com/tip-org/benchmarks](https://github.com/tip-org/benchmarks).
The tip-tools (including tip-spec) can be installed from [https://github.com/tip-org/tools/](https://github.com/tip-org/tools/).

[scan_and_store_vampspec.py](scan_and_store_vampspec.py) contains code for parsing vampire output log files into a python dictionary and saving the output in a pickle file.

[ProcessResults.ipynb](ProcessResults.ipynb) is a python notebook for processing data from such a result pickle and extracting interesting metrics.
