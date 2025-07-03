#!/bin/bash
# Convenient conda setup script for VSCode and terminal use

export CONDA_EXE="/uscms_data/d3/tlee/miniforge3/bin/conda"
export CONDA_PREFIX="/uscms_data/d3/tlee/miniforge3"
export CONDA_PYTHON_EXE="/uscms_data/d3/tlee/miniforge3/bin/python"
export PATH="/uscms_data/d3/tlee/miniforge3/bin:$PATH"

# Initialize conda for this shell session
if [ -f "/uscms_data/d3/tlee/miniforge3/etc/profile.d/conda.sh" ]; then
    source "/uscms_data/d3/tlee/miniforge3/etc/profile.d/conda.sh"
fi

# Activate mdsml environment
conda activate mdsml

echo "✅ Conda environment 'mdsml' activated!"
echo "🐍 Python: $(which python)"
echo "📦 Conda: $(which conda)"
