#!/bin/bash

# Run LLP Analyzer
# Runs the RazorRun analyzer with specified parameters

# Navigate to repository directory
cd "${CMSSW_BASE}/src/${REPO_DIR}"

# Verify we're in the right place and executable exists
if [[ ! -f "RazorRun" ]]; then
    echo "❌ RazorRun executable not found"
    echo "Current directory: $(pwd)"
    echo "Make sure the analyzer has been built successfully"
    exit 1
fi

# Check if input list exists (handle both relative and absolute paths)
INPUT_LIST_PATH="$INPUT_LIST"
if [[ ! -f "$INPUT_LIST_PATH" ]]; then
    # Try relative to project directory
    INPUT_LIST_PATH="${PROJECT_DIR}/${INPUT_LIST}"
fi

if [[ ! -f "$INPUT_LIST_PATH" ]]; then
    echo "❌ Input list file not found: $INPUT_LIST"
    echo "Tried paths:"
    echo "  $INPUT_LIST"
    echo "  ${PROJECT_DIR}/${INPUT_LIST}"
    echo ""
    echo "You need to create an input list file. Example content:"
    echo "  /path/to/input/file1.root"
    echo "  /path/to/input/file2.root"
    echo ""
    echo "Creating a sample input list file for you..."
    
    # Create sample list file in project directory
    SAMPLE_LIST_PATH="${PROJECT_DIR}/${INPUT_LIST}"
    mkdir -p "$(dirname "$SAMPLE_LIST_PATH")"
    cat > "$SAMPLE_LIST_PATH" << 'EOF'
# Sample input list for MDS-ML LLP Analyzer
# Replace these paths with actual input ROOT files
# Example format:
# /eos/uscms/store/user/someuser/sample/file1.root
# /eos/uscms/store/user/someuser/sample/file2.root

# For testing, you can use any available ROOT file
# or files from the CMS datasets
EOF
    
    echo "✓ Sample $INPUT_LIST created at $SAMPLE_LIST_PATH"
    echo "⚠️  Please edit $SAMPLE_LIST_PATH with actual input file paths before running"
    echo ""
    echo "To run the analyzer after editing the input list:"
    echo "  cd ${CMSSW_BASE}/src/${REPO_DIR}"
    echo "  ./RazorRun $INPUT_LIST $ANALYZER_NAME $DATA_FLAG"
    exit 0
fi

# Determine output path if specified
OUTPUT_PATH=""
if [[ -n "$OUTPUT_FILE" ]]; then
    OUTPUT_PATH="$OUTPUT_FILE"
    if [[ ! "$OUTPUT_PATH" =~ ^/ ]]; then
        # If not absolute path, make it relative to project directory
        OUTPUT_PATH="${PROJECT_DIR}/${OUTPUT_FILE}"
    fi
fi

# Display run information
echo "Running LLP Analyzer..."
echo "  Executable: ./RazorRun"
echo "  Input List: $INPUT_LIST_PATH"
echo "  Analyzer: $ANALYZER_NAME"
echo "  Data Flag: $DATA_FLAG"
echo "  Analysis Tag: $ANALYSIS_TAG"

if [[ -n "$OUTPUT_PATH" ]]; then
    echo "  Output File: $OUTPUT_PATH"
fi
echo "  Working Directory: $(pwd)"
echo ""

# Count input files
INPUT_COUNT=$(grep -v '^#' "$INPUT_LIST_PATH" | grep -v '^$' | wc -l)
echo "Number of input files: $INPUT_COUNT"

if [[ $INPUT_COUNT -eq 0 ]]; then
    echo "⚠️  No input files found in $INPUT_LIST_PATH"
    echo "Please add input file paths to the list"
    exit 1
fi

echo ""
echo "Starting analyzer run..."
echo "============================================"

# Run the analyzer with proper analysis tag to avoid segmentation fault
if [[ -n "$OUTPUT_PATH" ]]; then
    echo "Output will be saved to: $OUTPUT_PATH"
    # Ensure output directory exists
    mkdir -p "$(dirname "$OUTPUT_PATH")"
    ./RazorRun "$INPUT_LIST_PATH" "$ANALYZER_NAME" "$DATA_FLAG" "-f=$OUTPUT_PATH" "-l=$ANALYSIS_TAG"
else
    # Use default output (in current directory)
    ./RazorRun "$INPUT_LIST_PATH" "$ANALYZER_NAME" "$DATA_FLAG" "-l=$ANALYSIS_TAG"
fi

# Check if run was successful
if [[ $? -eq 0 ]]; then
    echo "============================================"
    echo "✓ Analyzer run completed successfully"
    
    # Show output files
    echo ""
    if [[ -n "$OUTPUT_PATH" && -f "$OUTPUT_PATH" ]]; then
        echo "Output file created: $OUTPUT_PATH"
        echo "  Size: $(ls -lh "$OUTPUT_PATH" | awk '{print $5}')"
        echo "  Created: $(ls -l "$OUTPUT_PATH" | awk '{print $6, $7, $8}')"
        
        # Quick ROOT file check
        echo ""
        echo "Quick ROOT file check:"
        root -l -b -q "$OUTPUT_PATH" <<'EOF' 2>/dev/null | grep -E "(TTree|TH1|entries|Events)" || echo "  Could not inspect ROOT file"
.ls
EOF
    else
        echo "Output files created in current directory:"
        ls -lah *.root 2>/dev/null | tail -5 || echo "  No ROOT files found"
        
        # Show the most recent ROOT file details
        LATEST_ROOT=$(ls -t *.root 2>/dev/null | head -1)
        if [[ -n "$LATEST_ROOT" ]]; then
            echo ""
            echo "Latest output file: $LATEST_ROOT"
            echo "  Size: $(ls -lh "$LATEST_ROOT" | awk '{print $5}')"
            echo "  Created: $(ls -l "$LATEST_ROOT" | awk '{print $6, $7, $8}')"
            
            # Quick ROOT file check
            echo ""
            echo "Quick ROOT file check:"
            root -l -b -q "$LATEST_ROOT" <<'EOF' 2>/dev/null | grep -E "(TTree|TH1|entries|Events)" || echo "  Could not inspect ROOT file"
.ls
EOF
        fi
    fi
    
else
    echo "============================================"
    echo "❌ Analyzer run failed"
    echo "Check the output above for error messages"
    exit 1
fi

echo ""
echo "Analyzer run complete!"
echo "Working directory: $(pwd)" 