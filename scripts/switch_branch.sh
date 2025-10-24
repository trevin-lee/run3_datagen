#!/bin/bash

# Switch Git Branch
# Switches to target branch for building

# Get the project directory to source configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source the main script to get environment variables if they're not set
if [[ -z "$TARGET_BRANCH" || -z "$CMSSW_BASE" || -z "$REPO_DIR" ]]; then
    # Extract variables from main.sh without running the full script
    export CMSSW_VERSION="CMSSW_14_1_0_pre4"
    export CMSSW_BASE="${PROJECT_DIR}/${CMSSW_VERSION}"
    export REPO_DIR="run3_llp_analyzer"
    export TARGET_BRANCH="add-rechit-data"
fi

# Check if target directory exists
if [[ ! -d "${CMSSW_BASE}/src/${REPO_DIR}" ]]; then
    echo "❌ ERROR: Repository directory does not exist: ${CMSSW_BASE}/src/${REPO_DIR}"
    exit 1
fi

# Ensure CMSSW environment is active
cd "${CMSSW_BASE}/src"
eval `scramv1 runtime -sh`
if [[ $? -ne 0 ]]; then
    echo "❌ Failed to setup CMSSW environment"
    exit 1
fi

# Navigate to repository directory
cd "${CMSSW_BASE}/src/${REPO_DIR}"

# Verify we're in the right place
if [[ ! -d ".git" ]]; then
    echo "❌ Not in a git repository"
    exit 1
fi

# Check current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)

# Switch to target branch if different
if [[ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]]; then
    echo "Switching to branch: $TARGET_BRANCH"
    
    # Test git connectivity
    git ls-remote --heads origin > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "⚠️  WARNING: Cannot connect to remote repository. Using local branches only."
        FETCH_FAILED=true
    else
        FETCH_FAILED=false
    fi
    
    # Fetch latest changes if possible
    if [[ "$FETCH_FAILED" != "true" ]]; then
        git fetch origin
        if [[ $? -ne 0 ]]; then
            FETCH_FAILED=true
        fi
    fi
    
    # Try to switch to target branch
    git checkout "$TARGET_BRANCH" 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "✓ Switched to branch: $TARGET_BRANCH"
    else
        # Try to create from remote
        if [[ "$FETCH_FAILED" != "true" ]]; then
            git checkout -b "$TARGET_BRANCH" "origin/$TARGET_BRANCH" 2>/dev/null
            if [[ $? -eq 0 ]]; then
                echo "✓ Created and switched to branch: $TARGET_BRANCH"
            else
                echo "❌ Failed to switch to branch: $TARGET_BRANCH"
                exit 1
            fi
        else
            echo "❌ Cannot switch to branch: $TARGET_BRANCH"
            exit 1
        fi
    fi
else
    echo "Already on target branch: $TARGET_BRANCH"
fi 