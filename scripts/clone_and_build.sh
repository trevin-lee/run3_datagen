#!/bin/bash

# Clone Repository and Build Analyzer
# Clones the run3_llp_analyzer repository and builds it

SKIP_BUILD=false
BUILD_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --build-only)
            BUILD_ONLY=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# Navigate to CMSSW src directory
cd "${CMSSW_BASE}/src"

# Ensure CMSSW environment is active
if [[ -z "$CMSSW_BASE" ]]; then
    echo "❌ CMSSW environment not set up properly"
    exit 1
fi

# Clone repository if not build-only
if [[ "$BUILD_ONLY" == "false" ]]; then
    if [[ -d "$REPO_DIR" ]]; then
        echo "Repository directory already exists: $REPO_DIR"
    else
        echo "Cloning repository: $REPO_URL"
        git clone "$REPO_URL" "$REPO_DIR"
        
        if [[ $? -ne 0 ]]; then
            echo "❌ Failed to clone repository"
            exit 1
        fi
        
        echo "✓ Repository cloned successfully"
        
        # Navigate to repository and set up git properly
        cd "$REPO_DIR"
        
        # Fetch all branches to ensure target branch is available
        git fetch --all
        
        # Go back to parent directory
        cd ..
    fi
fi

# Navigate to repository directory
cd "$REPO_DIR"

# Verify we're in the right place
if [[ ! -f "Makefile" ]]; then
    echo "❌ Makefile not found. Are we in the right directory?"
    echo "Current directory: $(pwd)"
    exit 1
fi

# Build the analyzer if not skipping
if [[ "$SKIP_BUILD" == "false" ]]; then
    echo "Building analyzer..."
    
    # Clean previous build if it exists
    if [[ -f "RazorRun" ]]; then
        make clean
    fi
    
    # Build
    make
    
    if [[ $? -ne 0 ]]; then
        echo "❌ Build failed"
        exit 1
    fi
    
    echo "✓ Build completed successfully"
    
    # Verify build products
    if [[ -f "RazorRun" ]]; then
        echo "✓ RazorRun executable created"
    else
        echo "⚠️  RazorRun executable not found after build"
    fi
else
    echo "Skipping build step"
fi

echo ""
echo "Repository setup complete:"
echo "  Repository: $(pwd)"
echo "  Branch: $(git branch --show-current 2>/dev/null || echo 'Unknown')"
echo "" 