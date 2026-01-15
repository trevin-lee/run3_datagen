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

# Initialize VOMS proxy (optional but recommended for remote data access)
if command -v voms-proxy-info >/dev/null 2>&1; then
    VOMS_VO="${VOMS_VO:-cms}"
    VOMS_VALID="${VOMS_VALID:-192:00}"
    if ! voms-proxy-info -exists -hours 1 >/dev/null 2>&1; then
        echo "Initializing VOMS proxy for VO: ${VOMS_VO}"
        if [[ -n "${X509_USER_KEY_PASSPHRASE:-}" ]]; then
            if echo -n "${X509_USER_KEY_PASSPHRASE}" | voms-proxy-init -rfc -voms "${VOMS_VO}" -valid "${VOMS_VALID}" -pwstdin >/dev/null 2>&1; then
                echo "✓ VOMS proxy initialized"
            else
                echo "⚠️  Failed to initialize VOMS proxy non-interactively."
                echo "    You may need to run this manually (will prompt for passphrase):"
                echo "    voms-proxy-init -rfc -voms ${VOMS_VO} -valid ${VOMS_VALID}"
            fi
        else
            echo "⚠️  Skipping automatic VOMS init (no X509_USER_KEY_PASSPHRASE set)."
            echo "    To initialize manually, run:"
            echo "    voms-proxy-init -rfc -voms ${VOMS_VO} -valid ${VOMS_VALID}"
        fi
    else
        TIMELEFT="$(voms-proxy-info -timeleft 2>/dev/null || echo '')"
        echo "✓ Existing VOMS proxy detected (time left: ${TIMELEFT}s)"
    fi
    # Export proxy path if available
    PROXY_PATH="$(voms-proxy-info -path 2>/dev/null || true)"
    if [[ -n "${PROXY_PATH}" && -f "${PROXY_PATH}" ]]; then
        export X509_USER_PROXY="${PROXY_PATH}"
    fi
else
    echo "⚠️  voms-proxy-info not found; skipping VOMS proxy setup."
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