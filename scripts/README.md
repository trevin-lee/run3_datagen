# MDS-ML CMS LLP Analyzer Scripts

This directory contains modular scripts for setting up and running the CMS LLP analyzer pipeline, based on Daniel's original setup session.

## Overview

The script system replicates Daniel's exact workflow in a modular, automated way. **By default, it rebuilds everything from scratch** to ensure clean, reproducible results. This approach eliminates issues caused by stale builds, environment mismatches, or partially corrupted setups.

Use `--keep-*` flags only when you're confident your existing setup is clean and compatible.

## Usage

### Quick Start

```bash
# Full rebuild from scratch (recommended)
./main.sh

# Keep existing CMSSW but rebuild code
./main.sh --keep-cmssw

# Keep everything, just run the analyzer
./main.sh --keep-cmssw --keep-build
```

### Command Line Options

**Default Behavior**: The script rebuilds everything from scratch for maximum reliability.

- `--keep-cmssw`: Keep existing CMSSW release (don't recreate)
- `--keep-clone`: Keep existing repository clone (don't reclone)
- `--keep-build`: Keep existing build (don't recompile)
- `--skip-branch`: Skip switching to target branch
- `--no-run`: Don't run the analyzer, just setup
- `-h, --help`: Show help message

**Examples**:
```bash
./main.sh                           # Full rebuild from scratch (recommended)
./main.sh --keep-cmssw             # Keep CMSSW, rebuild code
./main.sh --keep-cmssw --keep-build # Keep everything, just run
./main.sh --no-run                 # Setup only, don't run analyzer
```

### Environment Variables

You can override these variables before running:

```bash
export CMSSW_VERSION="CMSSW_14_1_0_pre4"
export TARGET_BRANCH="add-rechit-data"
export ANALYZER_NAME="llp_MuonSystem_CA_mdsnano"
export INPUT_LIST="data/input.txt"
export OUTPUT_FILE="data/MuonSystem_Tree.root"
export DATA_FLAG="-d=no"  # no for MC, yes for data
export ANALYSIS_TAG="Summer24"  # Critical: prevents segmentation fault
```

## Pipeline Stages

### Stage 1: Environment Setup (`setup_environment.sh`)
- Sources CMSSW environment from CVMFS
- Sets up ROOT environment if specified
- Verifies environment variables

### Stage 2: CMSSW Setup (`setup_cmssw.sh`)
- **Default**: Removes existing CMSSW release and creates fresh one
- **With --keep-cmssw**: Uses existing CMSSW release
- Activates CMSSW environment with `cmsenv`
- Sets up additional ROOT if needed

### Stage 3: Clone and Build (`clone_and_build.sh`)
- **Default**: Removes existing repository and does fresh clone + build
- **With --keep-clone**: Uses existing repository clone
- **With --keep-build**: Keeps existing build (no recompilation)
- Builds the analyzer using `make`

### Stage 4: Branch Switch (`switch_branch.sh`)
- Switches to the target branch (default: `add-rechit-data`)
- Rebuilds after branch switch
- Fetches latest changes from origin

### Stage 5: Run Analyzer (`run_analyzer.sh`)
- Runs the RazorRun analyzer
- Creates sample input list if none exists
- Shows output file information

## File Structure

```
mds-ml/
├── main.sh                    # Main orchestration script
├── CMSSW_14_1_0_pre4/        # CMSSW release (created in main directory)
│   └── src/
│       └── run3_llp_analyzer/  # Cloned repository
├── data/                      # Input files
└── scripts/
    ├── setup_environment.sh   # Environment setup
    ├── setup_cmssw.sh        # CMSSW release setup
    ├── clone_and_build.sh    # Repository clone and build
    ├── switch_branch.sh      # Branch switching
    └── run_analyzer.sh       # Analyzer execution
```

## Example Workflows

### First Time Setup
```bash
./main.sh
```

### Using Existing CMSSW Release
```bash
./main.sh --skip-cmssw
```

### Just Building (if repo already cloned)
```bash
./main.sh --skip-cmssw --skip-clone
```

### Setup Only (no analyzer run)
```bash
./main.sh --no-run
```

### Force Rebuild Everything
```bash
./main.sh --force-rebuild
```

## Input Files

The analyzer requires an input list file (`data/input.txt` by default) containing paths to ROOT files:

```
# Example data/input.txt content
root://cmsxrootd.fnal.gov//store/group/lpclonglived/christiw/privateProduction/Run3Summer22EE/MDSNano/v2/higgs_m_15_ctau_10000_xiO_2p5_xiL_1/HiddenValley_higgs_m_15_ctau_10000_xiO_2p5_xiL_1/crab_Summer22EE_HiddenValley_higgs_m_15_ctau_10000_xiO_2p5_xiL_1_batch2_MDSNano_v2_v2/250225_233524/0000/PAT_NANO_100.root
```

The project already includes a `data/input.txt` file with Hidden Valley sample files. If no input list exists, the run script will create a template for you to edit.

## Notes

- Make sure you're on a machine with CVMFS access (like LPC)
- The scripts preserve the exact workflow from Daniel's session
- All environment variables are passed between script stages
- Each script can be run independently if needed
- Output ROOT files are created in the repository directory

## Critical Fixes Applied

### Analysis Tag Fix (Prevents Segmentation Fault)

**Issue**: The analyzer was defaulting to unsupported analysis tag "Razor2016_80X", causing:
- Segmentation fault in `RazorHelper::getJecUnc()` 
- Corrupted 615-byte output files instead of expected ~71KB files
- NULL pointer access when JEC uncertainty objects weren't initialized

**Solution**: The script now properly sets analysis tag "Summer24" for Hidden Valley samples:
```bash
export ANALYSIS_TAG="Summer24"  # For Hidden Valley 2024 samples
./RazorRun input.txt llp_MuonSystem_CA_mdsnano -d=no -l=Summer24
```

**Supported Analysis Tags**: Summer22, Summer22EE, Summer23, Summer23BPix, Summer24

This fix ensures proper initialization of JEC uncertainty objects and produces the expected 71KB output files with ~200 events.

### RazorRun Script Fix (Missing MET Trigger Files)

**Issue**: The `RazorRun` script was missing MET trigger efficiency file copies, causing:
- `file METTriggerEff_Summer24.root does not exist` errors
- Segmentation fault in `loadMetTrigger_Summer24()`
- Analyzer crashing during initialization

**Solution**: Added missing MET trigger file copies to `RazorRun` script:
```bash
cp ${CMSSW_BASE}/src/run3_llp_analyzer/data/trigger/METTriggerEff_Summer24.root .
# (and all other Summer22/23/24 variants)
```

The script now copies all required data files for proper analyzer operation. 