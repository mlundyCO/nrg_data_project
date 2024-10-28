# Analysis Reproduction
The following are steps to reproduce the analysis results this repository. I use `renv` and `pip` to manage R and Python packages, and the following assumes you have set up your environment.

First collect data (defaults to 2023):
```
./data/get_clean_data.sh
```

Then conduct the preliminary analysis of the interchange data using R:
```
Rscript R/prelim_interchange_analysis.R 2023
```
This will save figures to the `fig` directory.

The preliminary graph analysis can be reproduced (note this currently only uses 6 months of data):
```
python3 py/prelim_graph_analysis.py 2023
```
It takes ~10 seconds to load the 6 months of data, after which some results are printed to the terminal, and a figure is saved to `fig`.
