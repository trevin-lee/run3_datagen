#!/bin/bash

# Setup Environment for CMS LLP Analyzer
# Sets up CMSSW and ROOT environments

echo "Setting up CMSSW environment..."

# Source CMSSW environment
if [[ -f /cvmfs/cms.cern.ch/cmsset_default.sh ]]; then
    source /cvmfs/cms.cern.ch/cmsset_default.sh
    echo "✓ CMSSW environment sourced"
else
    echo "❌ CMSSW environment not found at /cvmfs/cms.cern.ch/cmsset_default.sh"
    echo "Make sure you're on a machine with CVMFS access"
    exit 1
fi

# Setup ROOT if specified path exists
if [[ -n "$ROOT_SETUP" && -f "$ROOT_SETUP" ]]; then
    echo "Setting up ROOT from: $ROOT_SETUP"
    source "$ROOT_SETUP"
    echo "✓ ROOT environment sourced"
else
    echo "⚠️  ROOT setup path not found or not specified: $ROOT_SETUP"
    echo "   Will use default ROOT from CMSSW"
fi

# Verify environment
echo ""
echo "Environment Check:"
echo "  CMSSW_BASE: ${CMSSW_BASE:-'Not set'}"
echo "  ROOT Version: $(root-config --version 2>/dev/null || echo 'Not available')"
echo "  Architecture: ${SCRAM_ARCH:-'Not set'}"
echo "" 

# Ensure python3, make, and wget are available; use conda if needed
if ! command -v python3 >/dev/null 2>&1 || ! command -v make >/dev/null 2>&1 || ! command -v wget >/dev/null 2>&1; then
    if command -v conda >/dev/null 2>&1; then
        CONDA_BASE_DIR="$(conda info --base 2>/dev/null)"
        if [[ -n "$CONDA_BASE_DIR" && -d "$CONDA_BASE_DIR/bin" ]]; then
            export PATH="$CONDA_BASE_DIR/bin:$PATH"
        fi

        # Install missing tools non-interactively using conda (prefer conda-forge defaults on miniforge)
        MISSING_PKGS=()
        command -v python3 >/dev/null 2>&1 || MISSING_PKGS+=(python)
        command -v make >/dev/null 2>&1 || MISSING_PKGS+=(make)
        command -v wget >/dev/null 2>&1 || MISSING_PKGS+=(wget)
        if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
            echo "Installing missing build tools via conda: ${MISSING_PKGS[*]}"
            conda install -y ${MISSING_PKGS[*]} || true
        fi
    fi
fi

# Final check
if ! command -v python3 >/dev/null 2>&1; then
    echo "⚠️  python3 not found; some helper scripts may fail (e.g., MakeAnalyzerCode.py)"
fi
if ! command -v make >/dev/null 2>&1; then
    echo "⚠️  make not found; build will likely fail. Install make or ensure it's on PATH."
fi
if ! command -v wget >/dev/null 2>&1; then
    echo "⚠️  wget not found; FastJet installation will fail. Install wget or ensure it's on PATH."
fi