# MDS-ML: CMS LLP Analyzer Pipeline

This project provides an automated pipeline for CMS (Compact Muon Solenoid) Long-Lived Particles (LLP) analysis with machine learning components. It includes tools for data processing, validation, and compatibility checking for muon system analysis.

## Overview

The MDS-ML project automates the setup and execution of the `run3_llp_analyzer` for CMS physics analysis. It focuses on:

- **Automated CMSSW environment setup**
- **Data processing and analysis pipeline**
- **Model validation and compatibility checking**
- **Cluster analysis and validation**

## Project Structure

```
├── main.sh                     # Main pipeline execution script
├── scripts/                    # Modular setup and execution scripts
│   ├── clone_and_build.sh     # Repository cloning and compilation
│   ├── run_analyzer.sh        # Analyzer execution script
│   ├── setup_cmssw.sh         # CMSSW environment setup
│   ├── setup_environment.sh   # Environment configuration
│   └── switch_branch.sh       # Git branch management
├── notebooks/                  # Analysis and validation notebooks
│   ├── model_compatibility/    # Dataset compatibility validation
│   ├── validate_cluster_id/    # Cluster ID assignment validation
│   └── validate_cluster_sort/  # Cluster sorting validation
├── data/                       # Data files and input configurations
└── CMSSW_14_1_0_pre4/         # CMSSW release directory (auto-generated)
```

## Quick Start

### Basic Usage

```bash
# Full rebuild from scratch (recommended for clean setup)
./main.sh

# Keep existing CMSSW but rebuild code
./main.sh --keep-cmssw

# Keep everything, just run the analyzer
./main.sh --keep-cmssw --keep-build

# Setup only, don't run analyzer
./main.sh --no-run
```

### Command Line Options

- `--keep-cmssw`: Keep existing CMSSW release (don't recreate)
- `--keep-clone`: Keep existing repository clone (don't reclone)
- `--keep-build`: Keep existing build (don't recompile)
- `--skip-branch`: Skip switching to target branch
- `--no-run`: Don't run the analyzer, just setup
- `-h, --help`: Show help message

## Scripts

### `main.sh`
**Primary pipeline script** that orchestrates the entire analysis workflow:
- **Purpose**: Automated setup and execution of the CMS LLP analyzer
- **Features**: 
  - Complete CMSSW environment setup
  - Repository management and compilation
  - Branch switching and dependency handling
  - Configurable rebuild options for development
- **Configuration**: Targets `add-rechit-data` branch with `llp_MuonSystem_CA_mdsnano` analyzer
- **Default Mode**: Rebuilds everything from scratch for reproducibility

### Scripts Directory (`scripts/`)

#### `setup_cmssw.sh`
- **Purpose**: Sets up CMSSW release environment
- **Features**: Downloads and configures CMSSW_14_1_0_pre4

#### `clone_and_build.sh`
- **Purpose**: Clones the run3_llp_analyzer repository and compiles the code
- **Repository**: `cms-lpc-llp/run3_llp_analyzer`

#### `switch_branch.sh`
- **Purpose**: Manages git branches and handles branch switching
- **Target**: Switches to `add-rechit-data` branch for rechit analysis

#### `run_analyzer.sh`
- **Purpose**: Executes the LLP analyzer with configured parameters
- **Analyzer**: `llp_MuonSystem_CA_mdsnano`
- **Output**: Generates ROOT files for further analysis

#### `setup_environment.sh`
- **Purpose**: Configures ROOT and CMSSW environment variables
- **Dependencies**: Sets up paths for ROOT 6.36.00 and CMSSW tools

## Notebooks

### `model_compatibility/model_compatibility.ipynb`
**Dataset Compatibility Validation**
- **Purpose**: Ensures new and old datasets have compatible structures
- **Features**:
  - Column comparison between datasets
  - Variable distribution plotting
  - Compatibility verification for ML model training
- **Data Sources**: Compares current `MuonSystem_Tree.root` with legacy data

### `validate_cluster_id/validate_cluster_id.ipynb`
**Cluster ID Assignment Validation**
- **Purpose**: Validates correct cluster ID assignments to rechits
- **Analysis**:
  - Compares cluster-level eta/phi with individual rechit coordinates
  - Validates CSC (Cathode Strip Chamber) and DT (Drift Tube) clustering
  - Ensures proper rechit-to-cluster associations

### `validate_cluster_sort/validate_cluster_sort.ipynb`
**Cluster Sorting Validation**
- **Purpose**: Validates that cluster sorting preserves coordinate arrays
- **Analysis**:
  - Verifies that `cluster.sort()` properly sorts eta and phi arrays
  - Creates visualization plots with cluster-based coloring
  - Tracks event metadata (ID, luminosity section, run number)
- **Integration**: Can execute the main pipeline directly from the notebook

## Data Analysis Focus

This project specifically analyzes:

- **Muon System Data**: CSC and DT detector rechits
- **Cluster Analysis**: Spatial clustering of detector hits
- **Long-Lived Particles**: Search for displaced particle signatures
- **ML Compatibility**: Ensuring data format consistency for machine learning models

## Configuration

### Key Environment Variables

```bash
export CMSSW_VERSION="CMSSW_14_1_0_pre4"        # CMSSW release version
export TARGET_BRANCH="add-rechit-data"          # Analysis branch
export ANALYZER_NAME="llp_MuonSystem_CA_mdsnano" # Specific analyzer
export ANALYSIS_TAG="Summer24"                   # Hidden Valley samples tag
export DATA_FLAG="-d=no"                        # MC vs data flag
```

### Input/Output

- **Input**: Configured via `data/input.txt`
- **Output**: ROOT files written to `data/MuonSystem_Tree.root`
- **Analysis**: Summer24 tag for Hidden Valley samples (2024)

## Requirements

- **CMSSW**: Version 14_1_0_pre4
- **ROOT**: Version 6.36.00
- **Python**: For notebook analysis (NumPy, Matplotlib, Uproot, etc.)
- **System**: Linux environment with CVMFS access

## Development Notes

- **Default Behavior**: Scripts rebuild from scratch for reproducibility
- **Keep Flags**: Use `--keep-*` options only with clean, compatible setups
- **Branch Focus**: Currently targets `add-rechit-data` branch for rechit analysis
- **Validation**: Multiple notebook-based validation steps ensure data quality

## Output

The pipeline generates:
- **ROOT Files**: Processed muon system data for analysis
- **Validation Plots**: Quality assurance visualizations
- **Compatibility Reports**: Dataset structure comparisons
- **Analysis Results**: Ready for ML model training and physics analysis 