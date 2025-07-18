#!/bin/bash

# Switch Git Branch and Rebuild
# Switches to target branch and rebuilds the analyzer

# Get the project directory to source configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Source the main script to get environment variables if they're not set
if [[ -z "$TARGET_BRANCH" || -z "$CMSSW_BASE" || -z "$REPO_DIR" ]]; then
    echo "Loading configuration from main script..."
    # Extract variables from main.sh without running the full script
    export CMSSW_VERSION="CMSSW_14_1_0_pre4"
    export CMSSW_BASE="${PROJECT_DIR}/${CMSSW_VERSION}"
    export REPO_DIR="run3_llp_analyzer"
    export TARGET_BRANCH="add-rechit-data"
fi

echo "=== Branch Switch Script Debug ==="
echo "Configuration:"
echo "  TARGET_BRANCH: $TARGET_BRANCH"
echo "  CMSSW_BASE: $CMSSW_BASE"
echo "  REPO_DIR: $REPO_DIR"
echo "  Full path: ${CMSSW_BASE}/src/${REPO_DIR}"
echo ""

# Debug: Check if target directory exists
if [[ ! -d "${CMSSW_BASE}/src/${REPO_DIR}" ]]; then
    echo "❌ ERROR: Repository directory does not exist: ${CMSSW_BASE}/src/${REPO_DIR}"
    echo "Available directories in ${CMSSW_BASE}/src/:"
    ls -la "${CMSSW_BASE}/src/" 2>/dev/null || echo "  Cannot list directory"
    exit 1
fi

# Navigate to repository directory
cd "${CMSSW_BASE}/src/${REPO_DIR}"

# Verify we're in the right place
if [[ ! -d ".git" ]]; then
    echo "❌ Not in a git repository"
    echo "Current directory: $(pwd)"
    exit 1
fi

# Check current branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null)
echo "Current branch: ${CURRENT_BRANCH:-'Unknown'}"

# Switch to target branch if different
if [[ "$CURRENT_BRANCH" != "$TARGET_BRANCH" ]]; then
    echo "Switching to branch: $TARGET_BRANCH"
    
    # Fetch latest changes
    echo "Fetching latest changes..."
    git fetch origin
    
    # Switch to branch (create if doesn't exist locally)
    git checkout "$TARGET_BRANCH" 2>/dev/null || git checkout -b "$TARGET_BRANCH" "origin/$TARGET_BRANCH"
    
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to switch to branch: $TARGET_BRANCH"
        exit 1
    fi
    
    echo "✓ Switched to branch: $TARGET_BRANCH"
    
    # Show current commit
    echo "Current commit: $(git rev-parse --short HEAD)"
    
    # Rebuild since we switched branches
    echo ""
    echo "Rebuilding after branch switch..."
    
    # Clean and rebuild
    make clean
    make
    
    if [[ $? -ne 0 ]]; then
        echo "❌ Rebuild failed after branch switch"
        exit 1
    fi
    
    echo "✓ Rebuild completed successfully"
    
else
    echo "Already on target branch: $TARGET_BRANCH"
    echo "Skipping branch switch"
fi

echo ""
echo "Branch switch complete:"
echo "  Repository: $(pwd)"
echo "  Branch: $(git branch --show-current)"
echo "  Commit: $(git rev-parse --short HEAD)"
echo "" 