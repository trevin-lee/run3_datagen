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