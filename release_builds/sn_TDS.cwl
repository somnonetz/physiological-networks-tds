cwlVersion: v1.0
class: CommandLineTool
baseCommand: run_sn_TDS.sh

inputs:
  MCRroot:
    type: string
    inputBinding:
      position: 0
    doc: "Path to the Matlab Compiler Runtime 2015a installation"
  data:
    type: File
    inputBinding:
      prefix: data
    doc: "Polysomnography in EDF format."
  montage_filename:
    type: File?
    inputBinding:
      prefix: montage_filename
    doc: "Montage in plain text format: a list of signal types contained in the Polysomnography EDF file. Should contain one signal type per row for each corresponding channel. Possible values are eeg, eog, emg, ecg and resp."
  resultpath:
    type: string?
    inputBinding:
      prefix: resultpath
    doc: "directory where the results are stored, default: working"
  outputfilebase:
    type: string?
    inputBinding:
      prefix: outputfilebase
    doc: "string from which the result filenames are deduced, default filebasename of the EDF"
  wl_sfe:
    type: int?
    inputBinding:
      prefix: wl_sfe
    doc: "windowlength of signal feature extraction, default 2 secs"
  ws_sfe:
    type: int?
    inputBinding:
      prefix: ws_sfe
    doc: "windowshift of signal feature extraction, default 1 secs"
  wl_xcc:
    type: int?
    inputBinding:
      prefix: wl_xcc
    doc: "windowlength of crosscorrelation in seconds, default 60"
  ws_xcc:
    type: int?
    inputBinding:
      prefix: ws_xcc
    doc: "windowshift of crosscorrelation in seconds, default 30"
  wl_tds:
    type: int?
    inputBinding:
      prefix: wl_tds
    doc: "windowlength of stability analysis in seconds, default 5"
  ws_tds:
    type: int?
    inputBinding:
      prefix: ws_tds
    doc: "windowshift of stability analysis in seconds, default 1"
  mld_tds:
    type: float?
    inputBinding:
      prefix: mld_tds
    doc: "maximum lag difference in window to be accounted as stable sequence, default 2"
  mlf_tds:
    type: float?
    inputBinding:
      prefix: mlf_tds
    doc: "minimum lag fraction in window that need to fulfill mld_tds, default: 0.8"
  debug:
    type: int?
    inputBinding:
      prefix: debug
    doc: "if set to 1 debug information is provided, default 0"

outputs:
  tds:
    type: File?
    outputBinding:
      glob: "*_getTDS.mat"
    doc: "Matlab data file (.mat) containing results of a Time-Delay-Stability (TDS) analysis performed on a Polysomnography in EDF format. File can be loaded in Matlab and Octave environments."
  tds_all:
    type: File?
    outputBinding:
      glob: "*_getTDS_all.mat"
    doc: "Matlab data file (.mat) containing results of a Time-Delay-Stability (TDS) analysis performed on a Polysomnography in EDF format. File can be loaded in Matlab and Octave environments. The tds_all file contains more Matlab objects than the tds file."
