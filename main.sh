#!/bin/bash

# MDS-ML CMS LLP Analyzer Pipeline (No-Flags Version)
# Configure booleans and settings below, then run this script.

set -e

# =============================================================================
# USER SETTINGS (edit these)
# =============================================================================

# Steps to run
# Stage 1 (Env) always runs
DO_CMSSW_CREATE=false  # Stage 2: If true, recreate CMSSW; if false, use existing (or create if missing)
DO_CLONE=false         # Stage 3: Fresh clone (deletes existing if true); otherwise use existing or clone if missing
DO_BRANCH=false        # Stage 4: Switch to target branch
DO_BUILD=true        # Stage 5: Build analyzer
DO_RUN=true           # Stage 6: Run analyzer

# Analysis configuration
export CMSSW_VERSION="CMSSW_14_1_0_pre4"
export TARGET_BRANCH="main"
export ANALYZER_NAME="llp_MuonSystem_CA_mdsnano"
export INPUT_LIST="/uscms/home/tlee/nobackup/work/run3_datagen/data/samples/input.txt"              # Relative to project dir unless absolute
export OUTPUT_FILE="/uscms/home/tlee/nobackup/work/run3_datagen/data/analyzer_output_mdsnano.root"  # Relative to project dir unless absolute
export DATA_FLAG="-d=no"                         # "-d=no" for MC, "-d=yes" for data
export ANALYSIS_TAG="Summer22"

# Optional environment paths (leave empty to use CMSSW's ROOT)
export ROOT_SETUP=""

# =============================================================================
# CONSTANTS
# =============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_DIR
export CMSSW_BASE="${PROJECT_DIR}/${CMSSW_VERSION}"
export REPO_DIR="run3_llp_analyzer"
export REPO_URL="git@github.com:cms-lpc-llp/run3_llp_analyzer.git"

# Derived paths
REPO_PATH="${CMSSW_BASE}/src/${REPO_DIR}"

# =============================================================================
# PRINT CONFIG
# =============================================================================

echo "=== MDS-ML CMS LLP Analyzer Pipeline (No-Flags) ==="
echo "Project Directory: ${PROJECT_DIR}"
echo "CMSSW Base: ${CMSSW_BASE}"
echo "CMSSW Version: ${CMSSW_VERSION}"
echo "Target Branch: ${TARGET_BRANCH}"
echo "Analyzer: ${ANALYZER_NAME}"
echo ""
echo "Selected steps:"
echo "  Env: true"
echo "  CMSSW Create: ${DO_CMSSW_CREATE}"
echo "  Clone: ${DO_CLONE}"
echo "  Branch: ${DO_BRANCH}"
echo "  Build: ${DO_BUILD}"
echo "  Run: ${DO_RUN}"
echo ""

# Simple validation
# (no mutually exclusive toggles remain)

# =============================================================================
# STAGE 1: ENVIRONMENT
# =============================================================================

echo "=== Stage 1: Setting up Environment ==="
source "${PROJECT_DIR}/scripts/setup_environment.sh"

# =============================================================================
# STAGE 2: CMSSW
# =============================================================================

if [[ "${DO_CMSSW_CREATE}" == "true" ]]; then
    echo "=== Stage 2: Creating fresh CMSSW release ==="
    if [[ -d "${CMSSW_BASE}" ]]; then
        echo "Removing existing CMSSW release: ${CMSSW_BASE}"
        rm -rf "${CMSSW_BASE}"
    fi
    export CMSSW_VERSION
    source "${PROJECT_DIR}/scripts/setup_cmssw.sh"
else
    if [[ -d "${CMSSW_BASE}" ]]; then
        echo "=== Stage 2: Using existing CMSSW release ==="
        export CMSSW_VERSION
        source "${PROJECT_DIR}/scripts/setup_cmssw.sh" --use-existing
    else
        echo "=== Stage 2: CMSSW not found; creating new release ==="
        export CMSSW_VERSION
        source "${PROJECT_DIR}/scripts/setup_cmssw.sh"
    fi
fi

# =============================================================================
# STAGE 3: REPOSITORY
# =============================================================================

if [[ "${DO_CLONE}" == "true" ]]; then
    echo "=== Stage 3: Fresh clone ==="
    if [[ -d "${REPO_PATH}" ]]; then
        echo "Removing existing repository: ${REPO_PATH}"
        rm -rf "${REPO_PATH}"
    fi
    source "${PROJECT_DIR}/scripts/clone_and_build.sh" --skip-build
else
    if [[ -d "${REPO_PATH}" ]]; then
        echo "=== Stage 3: Using existing repository clone ==="
        cd "${REPO_PATH}"
    else
        echo "=== Stage 3: Repository not found; cloning ==="
        source "${PROJECT_DIR}/scripts/clone_and_build.sh" --skip-build
    fi
fi

# =============================================================================
# STAGE 4: BRANCH
# =============================================================================

if [[ "${DO_BRANCH}" == "true" ]]; then
    echo "=== Stage 4: Switching to branch ${TARGET_BRANCH} ==="
    export TARGET_BRANCH
    export CMSSW_BASE
    export REPO_DIR
    export PROJECT_DIR
    if [[ ! -d "${CMSSW_BASE}/src/${REPO_DIR}" ]]; then
        echo "❌ Repository does not exist at ${CMSSW_BASE}/src/${REPO_DIR}"; exit 1
    fi
    cd "${CMSSW_BASE}/src"
    eval `scramv1 runtime -sh`
    source "${PROJECT_DIR}/scripts/switch_branch.sh"
else
    echo "=== Stage 4: Skipping branch switch ==="
fi

# =============================================================================
# STAGE 5: BUILD
# =============================================================================

if [[ "${DO_BUILD}" == "true" ]]; then
    echo "=== Stage 5: Building analyzer ==="
    cd "${CMSSW_BASE}/src/${REPO_DIR}"
    cd "${CMSSW_BASE}/src" && eval `scramv1 runtime -sh` && cd "${REPO_DIR}"
    # Build using 8 cores
    export MAKEFLAGS="-j8"
    echo "Using MAKEFLAGS=${MAKEFLAGS}"
    source "${PROJECT_DIR}/scripts/clone_and_build.sh" --build-only
    if [[ $? -ne 0 ]]; then
        echo "❌ Build failed"; exit 1
    fi
else
    echo "=== Stage 5: Skipping build ==="
fi

# =============================================================================
# STAGE 6: RUN
# =============================================================================

if [[ "${DO_RUN}" == "true" ]]; then
    echo "=== Stage 6: Running Analyzer ==="
    source "${PROJECT_DIR}/scripts/run_analyzer.sh"
else
    echo "=== Skipping analyzer run ==="
fi

echo ""
echo "=== Pipeline Complete ==="
echo "CMSSW Base: ${CMSSW_BASE}"
echo "Repository: ${CMSSW_BASE}/src/${REPO_DIR}"
echo ""
echo "To run the analyzer manually:"
echo "  cd ${CMSSW_BASE}/src/${REPO_DIR}"
echo "  ./RazorRun ${INPUT_LIST} ${ANALYZER_NAME} ${DATA_FLAG} -f=${OUTPUT_FILE} -l=${ANALYSIS_TAG}"


