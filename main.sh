#!/bin/bash

# MDS-ML CMS LLP Analyzer Pipeline
# Automated setup and execution script for run3_llp_analyzer
# 
# By default, this script starts completely from scratch:
# - Removes and recreates CMSSW release
# - Recompiles all code
# - Switches to target branch
# 
# Use --keep-* flags to preserve existing work

set -e  # Exit on any error

# =============================================================================
# CONFIGURATION
# =============================================================================

# Project paths
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${PROJECT_DIR}/work"

# CMSSW configuration
export CMSSW_VERSION="CMSSW_14_1_0_pre4"
export CMSSW_BASE="${WORK_DIR}/${CMSSW_VERSION}"
export REPO_DIR="run3_llp_analyzer"
export REPO_URL="git@github.com:cms-lpc-llp/run3_llp_analyzer.git"

# Analysis configuration
export TARGET_BRANCH="add-rechit-data"        # Branch to switch to after initial build
export ANALYZER_NAME="llp_MuonSystem_CA_mdsnano"
export INPUT_LIST="data/input.txt"
export OUTPUT_FILE="data/MuonSystem_Tree.root"
export DATA_FLAG="-d=no"  # no for MC, yes for data
export ANALYSIS_TAG="Summer24"  # Summer24 tag for Hidden Valley samples (2024)

# ROOT and CMSSW paths (adjust if needed)
export ROOT_SETUP_SCRIPT="/cvmfs/sft.cern.ch/lcg/app/releases/ROOT/6.36.00/x86_64-almalinux9.5-gcc115-opt/bin/thisroot.sh"
export CMSSW_SETUP_SCRIPT="/cvmfs/cms.cern.ch/cmsset_default.sh"

# =============================================================================
# COMMAND LINE ARGUMENTS
# =============================================================================

# Default behavior: rebuild everything from scratch
KEEP_CMSSW=false
KEEP_CLONE=false
KEEP_BUILD=false
SKIP_BRANCH=false
RUN_ANALYZER=true

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "By default, this script rebuilds everything from scratch for reliability."
    echo "Use --keep-* options to preserve existing work:"
    echo ""
    echo "Options:"
    echo "  --keep-cmssw        Keep existing CMSSW release (don't recreate)"
    echo "  --keep-clone        Keep existing repository clone (don't reclone)"
    echo "  --keep-build        Keep existing build (don't recompile)"
    echo "  --skip-branch       Skip switching to target branch"
    echo "  --no-run           Don't run the analyzer, just setup"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Environment variables you can override:"
    echo "  CMSSW_VERSION       Default: ${CMSSW_VERSION}"
    echo "  TARGET_BRANCH       Default: ${TARGET_BRANCH}"
    echo "  ANALYZER_NAME       Default: ${ANALYZER_NAME}"
    echo "  INPUT_LIST          Default: ${INPUT_LIST}"
    echo "  OUTPUT_FILE         Default: ${OUTPUT_FILE}"
    echo "  ANALYSIS_TAG        Default: ${ANALYSIS_TAG}"
    echo ""
    echo "Examples:"
    echo "  $0                           # Full rebuild from scratch"
    echo "  $0 --keep-cmssw             # Keep CMSSW, rebuild code"
    echo "  $0 --keep-cmssw --keep-build # Keep everything, just run"
    echo "  $0 --no-run                 # Setup only, don't run analyzer"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --keep-cmssw)
            KEEP_CMSSW=true
            shift
            ;;
        --keep-clone)
            KEEP_CLONE=true
            shift
            ;;
        --keep-build)
            KEEP_BUILD=true
            shift
            ;;
        --skip-branch)
            SKIP_BRANCH=true
            shift
            ;;
        --no-run)
            RUN_ANALYZER=false
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# =============================================================================
# MAIN PIPELINE
# =============================================================================

echo "=== MDS-ML CMS LLP Analyzer Pipeline ==="
echo "Project Directory: ${PROJECT_DIR}"
echo "Work Directory: ${WORK_DIR}"
echo "CMSSW Version: ${CMSSW_VERSION}"
echo "Target Branch: ${TARGET_BRANCH}"
echo "Analyzer: ${ANALYZER_NAME}"
echo ""
echo "Pipeline mode:"
echo "  Keep CMSSW: ${KEEP_CMSSW}"
echo "  Keep Clone: ${KEEP_CLONE}"
echo "  Keep Build: ${KEEP_BUILD}"
echo "  Skip Branch: ${SKIP_BRANCH}"
echo "  Run Analyzer: ${RUN_ANALYZER}"
echo ""

# Create work directory
mkdir -p "${WORK_DIR}"

# Stage 1: Setup Environment
echo "=== Stage 1: Setting up Environment ==="
source "${PROJECT_DIR}/scripts/setup_environment.sh"

# Stage 2: Setup CMSSW (with cleanup if not keeping)
if [[ "$KEEP_CMSSW" == "true" && -d "${CMSSW_BASE}" ]]; then
    echo "=== Stage 2: Using existing CMSSW release ==="
    source "${PROJECT_DIR}/scripts/setup_cmssw.sh" --use-existing
else
    echo "=== Stage 2: Creating fresh CMSSW release ==="
    # Remove existing CMSSW release if it exists
    if [[ -d "${CMSSW_BASE}" ]]; then
        echo "Removing existing CMSSW release: ${CMSSW_BASE}"
        rm -rf "${CMSSW_BASE}"
    fi
    source "${PROJECT_DIR}/scripts/setup_cmssw.sh"
fi

# Stage 3: Clone and Build (with cleanup if not keeping)
REPO_PATH="${CMSSW_BASE}/src/${REPO_DIR}"
if [[ "$KEEP_CLONE" == "true" && -d "${REPO_PATH}" ]]; then
    echo "=== Stage 3: Using existing repository clone ==="
    if [[ "$KEEP_BUILD" == "false" ]]; then
        echo "Rebuilding code..."
        source "${PROJECT_DIR}/scripts/clone_and_build.sh" --build-only
    else
        echo "Keeping existing build"
        # Just verify we're in the right environment
        cd "${REPO_PATH}"
    fi
else
    echo "=== Stage 3: Fresh clone and build ==="
    # Remove existing repository if it exists
    if [[ -d "${REPO_PATH}" ]]; then
        echo "Removing existing repository: ${REPO_PATH}"
        rm -rf "${REPO_PATH}"
    fi
    
    BUILD_FLAG=""
    if [[ "$KEEP_BUILD" == "true" ]]; then
        BUILD_FLAG="--skip-build"
    fi
    source "${PROJECT_DIR}/scripts/clone_and_build.sh" $BUILD_FLAG
fi

# Stage 4: Optional Branch Switch
if [[ "$SKIP_BRANCH" == "false" && -n "$TARGET_BRANCH" ]]; then
    echo "=== Stage 4: Switching to branch ${TARGET_BRANCH} ==="
    source "${PROJECT_DIR}/scripts/switch_branch.sh"
fi

# Stage 5: Run Analyzer
if [[ "$RUN_ANALYZER" == "true" ]]; then
    echo "=== Stage 5: Running Analyzer ==="
    source "${PROJECT_DIR}/scripts/run_analyzer.sh"
else
    echo "=== Setup Complete (skipping analyzer run) ==="
fi

echo ""
echo "=== Pipeline Complete ==="
echo "CMSSW Base: ${CMSSW_BASE}"
echo "Repository: ${CMSSW_BASE}/src/${REPO_DIR}"
echo ""
echo "To run the analyzer manually:"
echo "  cd ${CMSSW_BASE}/src/${REPO_DIR}"
echo "  ./RazorRun ${INPUT_LIST} ${ANALYZER_NAME} ${DATA_FLAG} -f=${OUTPUT_FILE} -l=${ANALYSIS_TAG}" 