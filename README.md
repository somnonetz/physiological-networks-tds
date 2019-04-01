# physiological-networks-tds

Physiological Networks TDS is an implementation of the Time Delay Stability algorithm, introduced by Bashan et al. ([doi:10.1038/ncomms1705](https://doi.org/10.1038/ncomms1705)). It can be used in sleep research to determine the topology of the physiological networks by analysis of a polysomnographic recording. The software is developed at CBMI of HTW Berlin - University of Applied Sciences (https://cbmi.htw-berlin.de)

## Getting started

### Prerequisites

You need a recent Matlab installation and the Signal Processing Toolbox on your computer. The application is tested with R2015b. 

### Pathes

Download the repo and add the directory pn-tds to your matlab-path. 
If you don't have the psgscan-2-edfdata repository downloaded, you need to add also the directory externals to your matlab path

### Run the application

The basic function call is: @sn_TDS('data',EDF-FILE)@

Please check the documentation with in the matlabfiles for further information. 







