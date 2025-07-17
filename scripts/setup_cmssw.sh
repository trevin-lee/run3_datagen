#!/bin/bash

# Setup CMSSW Release
# Creates new CMSSW release or uses existing one

USE_EXISTING=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --use-existing)
            USE_EXISTING=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

cd "${WORK_DIR}"

if [[ "$USE_EXISTING" == "true" || -d "${CMSSW_VERSION}" ]]; then
    if [[ -d "${CMSSW_VERSION}" ]]; then
        echo "Using existing CMSSW release: ${CMSSW_VERSION}"
        cd "${CMSSW_VERSION}/src"
        eval `scramv1 runtime -sh`
        echo "✓ CMSSW environment activated"
    else
        echo "❌ CMSSW release directory not found: ${CMSSW_VERSION}"
        exit 1
    fi
else
    echo "Creating new CMSSW release: ${CMSSW_VERSION}"
    
    # Create CMSSW release
    cmsrel "${CMSSW_VERSION}"
    
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to create CMSSW release"
        exit 1
    fi
    
    echo "✓ CMSSW release created"
    
    # Navigate to src and setup environment
    cd "${CMSSW_VERSION}/src"
    cmsenv
    
    echo "✓ CMSSW environment activated"
fi

# Setup additional ROOT if specified
if [[ -n "$ROOT_SETUP" && -f "$ROOT_SETUP" ]]; then
    echo "Setting up additional ROOT environment..."
    source "$ROOT_SETUP"
    echo "✓ Additional ROOT environment sourced"
fi

# Verify setup
echo ""
echo "CMSSW Setup Complete:"
echo "  CMSSW_BASE: ${CMSSW_BASE}"
echo "  CMSSW_VERSION: ${CMSSW_VERSION}"
echo "  SCRAM_ARCH: ${SCRAM_ARCH}"
echo "  Working Directory: $(pwd)"
echo "" 