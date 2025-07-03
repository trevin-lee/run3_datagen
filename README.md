# MDS-ML: CMSSW Analysis Tools

This repository contains Python tools for working with the CMSSW framework and the run3_llp_analyzer package.

## Overview

The project provides three main Python modules:

1. **`CMSSWInitializer`** (`utils/cmssw_init.py`) - Handles CMSSW environment setup and initialization
2. **`RazorRunner`** (`utils/razor_run.py`) - Python interface for running the RazorRun C++ analyzer script
3. **`AnalyzerCompiler`** (`utils/compilation.py`) - Dedicated compilation tools for building analyzers

## Quick Start

### Basic Usage

```python
from utils.cmssw_init import CMSSWInitializer
from utils.razor_run import RazorRunner

# 1. Initialize CMSSW environment
cmssw_init = CMSSWInitializer()
cmssw_init.status()  # Check current status

# 2. Set up environment variables
cmssw_init.setup_environment_in_current_process()

# 3. Run analysis
runner = RazorRunner()
result = runner.run(
    input_files="data/PAT_NANO_100.root",
    analyzer_name="llp_MuonSystem",
    is_data=False,
    output_file="output/analysis.root"
)
```

### Interactive Setup

Run the example script for an interactive setup:

```bash
python example_usage.py --mode interactive
```

Available modes:
- `--mode status`: Check installation and compilation status
- `--mode complete`: Full setup and analysis example  
- `--mode interactive`: Interactive setup with user choices
- `--mode compile`: Compilation tools and options

## CMSSWInitializer

The `CMSSWInitializer` class handles the complete CMSSW setup process.

### Features

- **Automatic CMSSW Release Setup**: Creates CMSSW release using `cmsrel`
- **Repository Cloning**: Clones the run3_llp_analyzer from GitHub
- **Compilation**: Compiles the analyzer using `make`
- **Environment Management**: Sets up environment variables
- **Status Checking**: Monitors installation status

### Usage Examples

```python
from utils.cmssw_init import CMSSWInitializer

# Basic initialization
init = CMSSWInitializer()

# Check current status
init.status()

# Full setup (if needed)
init.full_setup()

# Force reinstallation
init.full_setup(force_cmssw=True, force_analyzer=True)

# Set up environment variables in current Python process
init.setup_environment_in_current_process()
```

### Command Line Usage

```bash
# Check status only
python utils/cmssw_init.py --status-only

# Full setup
python utils/cmssw_init.py

# Force reinstall
python utils/cmssw_init.py --force

# Custom CMSSW version
python utils/cmssw_init.py --version CMSSW_14_1_0_pre4
```

## RazorRunner

The `RazorRunner` class provides a Python interface to the RazorRun C++ script.

### Features

- **File Validation**: Checks input files exist before running
- **Multiple Input Formats**: Supports single files, file lists, or Python lists
- **Argument Handling**: Manages all RazorRun command-line arguments
- **Error Handling**: Comprehensive error checking and reporting
- **Analyzer Discovery**: Lists available analyzers automatically

### Usage Examples

```python
from utils.razor_run import RazorRunner

# Initialize runner
runner = RazorRunner()

# List available analyzers
analyzers = runner.get_available_analyzers()
print(f"Available: {analyzers}")

# Run with single file
result = runner.run(
    input_files="data/input.root",
    analyzer_name="llp_MuonSystem",
    is_data=False,
    output_file="output.root"
)

# Run with file list
result = runner.run(
    input_files="data/inputlist.txt",
    analyzer_name="llp_MuonSystem",
    is_data=True,
    option_number=1,
    option_label="data_run"
)

# Run with Python list of files
files = ["file1.root", "file2.root", "file3.root"]
result = runner.run(
    input_files=files,
    analyzer_name="llp_MuonSystem",
    is_data=False
)
```

### Command Line Usage

```bash
# Basic usage
python utils/razor_run.py input_files.txt llp_MuonSystem

# With options
python utils/razor_run.py input_files.txt llp_MuonSystem -d -f output.root -n 1

# List available analyzers
python utils/razor_run.py --list-analyzers

# Custom RazorRun path
python utils/razor_run.py input.txt analyzer --razor-path /custom/path/RazorRun
```

## AnalyzerCompiler

The `AnalyzerCompiler` class provides dedicated compilation functionality for CMSSW analyzers.

### Features

- **Smart Compilation**: Checks if recompilation is needed based on file timestamps
- **Progress Indicators**: Shows compilation progress with visual feedback
- **Parallel Building**: Supports parallel compilation jobs for faster builds
- **Clean Builds**: Option to clean before compiling
- **Status Monitoring**: Detailed compilation status and diagnostics
- **Error Handling**: Comprehensive build error reporting

### Usage Examples

```python
from utils.compilation import AnalyzerCompiler, compile_analyzer

# Basic compilation
success = compile_analyzer()

# Compilation with options
success = compile_analyzer(
    clean_first=True,
    parallel_jobs=4,
    show_progress=True
)

# Using the compiler class directly
compiler = AnalyzerCompiler()

# Check compilation status
compiler.print_status()

# Get detailed status info
status = compiler.get_compilation_status()
print(f"Needs recompilation: {status['needs_recompilation']}")

# Compile with progress
success = compiler.compile_with_progress(
    clean_first=True,
    parallel_jobs=4
)
```

### Command Line Usage

```bash
# Basic compilation
python utils/compilation.py

# Compilation with options
python utils/compilation.py --clean -j 4

# Status check only
python utils/compilation.py --status

# Custom analyzer directory
python utils/compilation.py --analyzer-dir /path/to/analyzer
```

## RazorRun Arguments

Based on the README.md from run3_llp_analyzer, the RazorRun script accepts:

- **Input files**: Path to input file list or single file
- **Analyzer name**: Name of the analyzer (e.g., `llp_MuonSystem`)
- **Options**:
  - `-d, --isData`: Input is data (not MC)
  - `-f=, --outputFile=`: Output filename
  - `-n=, --optionNumber=`: Option number
  - `-l=, --optionLabel=`: Option label
  - `-h, --help`: Show help

## Project Structure

```
mds-ml/
├── utils/
│   ├── cmssw_init.py       # CMSSW initialization
│   ├── razor_run.py        # RazorRun interface
│   └── compilation.py      # Analyzer compilation tools
├── data/
│   ├── inputlist.txt       # Example input file list
│   └── PAT_NANO_100.root   # Example input file
├── output/                 # Analysis output directory
├── notebooks/
│   └── main.ipynb         # Jupyter notebook examples
├── example_usage.py        # Complete usage examples
└── README.md              # This file
```

## Installation Requirements

### System Requirements

- Linux (el9 architecture recommended)
- CMSSW framework installed
- Git access to GitHub
- Python 3.6+

### CMSSW Setup (Manual)

If you prefer manual setup, follow these steps:

```bash
# Set up CMSSW
cmsrel CMSSW_14_1_0_pre4
cd CMSSW_14_1_0_pre4/src
cmsenv

# Source ROOT
source /cvmfs/cms.cern.ch/el9_amd64_gcc12/lcg/root/6.30.07-024df6516c17fd2edef848a927a788f1/bin/thisroot.sh

# Clone and compile analyzer
git clone git@github.com:cms-lpc-llp/run3_llp_analyzer.git run3_llp_analyzer
cd run3_llp_analyzer
make
```

### Python Dependencies

```bash
pip install pathlib subprocess typing
```

## Environment Variables

The tools automatically set these environment variables:

- `CMSSW_BASE`: Path to CMSSW installation
- `CMSSW_VERSION`: CMSSW version
- `SCRAM_ARCH`: Architecture (el9_amd64_gcc12)

## Examples

### Example 1: Status Check

```python
from utils.cmssw_init import CMSSWInitializer

# Check what's installed
init = CMSSWInitializer()
init.status()
```

### Example 2: Complete Setup and Analysis

```python
from utils.cmssw_init import CMSSWInitializer
from utils.razor_run import RazorRunner

# 1. Setup CMSSW if needed
init = CMSSWInitializer()
if not init.check_cmssw_installed():
    init.full_setup()

# 2. Set environment
init.setup_environment_in_current_process()

# 3. Run analysis
runner = RazorRunner()
result = runner.run(
    input_files="data/PAT_NANO_100.root",
    analyzer_name="llp_MuonSystem",
    is_data=False,
    output_file="output/my_analysis.root"
)
```

### Example 3: Compilation Management

```python
from utils.compilation import AnalyzerCompiler, compile_analyzer

# Check compilation status
compiler = AnalyzerCompiler()
status = compiler.get_compilation_status()

if status['needs_recompilation']:
    print("Recompilation needed")
    success = compile_analyzer(clean_first=True, parallel_jobs=4)
    if success:
        print("Compilation successful!")
else:
    print("Code is up to date")

# List available analyzers
analyzers = compiler.get_analyzer_names()
print(f"Available analyzers: {analyzers}")
```

### Example 4: Batch Processing

```python
from utils.razor_run import RazorRunner

runner = RazorRunner()

# Process multiple datasets
datasets = [
    ("data/dataset1.txt", True, "dataset1_output.root"),
    ("data/dataset2.txt", False, "dataset2_output.root"),
]

for input_list, is_data, output_file in datasets:
    result = runner.run(
        input_files=input_list,
        analyzer_name="llp_MuonSystem",
        is_data=is_data,
        output_file=f"output/{output_file}"
    )
    print(f"Completed: {output_file}")
```

## Troubleshooting

### Common Issues

1. **"RazorRun script not found"**
   - Ensure CMSSW is set up and the analyzer is compiled
   - Check that `CMSSW_BASE` environment variable is set
   - Verify the RazorRun script exists and is executable

2. **"No analyzers found"**
   - Run `make` in the analyzer directory
   - Check that compilation was successful
   - Verify the `bin/` directory contains `Run*` executables

3. **"Input file not found"**
   - Check file paths are correct
   - Ensure input files exist and are accessible
   - For file lists, verify each file in the list exists

4. **CMSSW environment issues**
   - Make sure you're on a compatible system (el9)
   - Verify CMSSW tools are in PATH
   - Source the proper CMSSW environment (`cmsenv`)

### Getting Help

- Check the status with `CMSSWInitializer().status()`
- Use `RazorRunner().show_help()` for RazorRun options
- Run `python example_usage.py --mode status` for overall status

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with the example scripts
5. Submit a pull request

## License

This project follows the same license as the underlying CMSSW and run3_llp_analyzer packages. 