#!/usr/bin/env python3
"""
Test script to verify the LLP pipeline works correctly.
"""

import sys
from pathlib import Path

# Add the project root to the Python path
project_root = "/uscms_data/d3/tlee/work/mds-ml"
sys.path.append(project_root)

from utils import PersistentShellSession, CMSSWInitializer, AnalyzerCompiler, RazorRunner

def test_pipeline():
    """Test the complete pipeline"""
    
    print("🧪 Testing LLP Pipeline...")
    
    # Initialize shell session
    shell_session = PersistentShellSession(project_root)
    success = shell_session.start()
    
    if not success:
        print("❌ Failed to start shell session")
        return False
    
    # Initialize CMSSW environment
    print("\n1. Setting up CMSSW environment...")
    cmssw = CMSSWInitializer(
        shell=shell_session, 
        cmssw_path=Path("CMSSW_14_1_0_pre4")
    )
    
    success = cmssw.setup_with_shell()
    if not success:
        print("❌ CMSSW initialization failed")
        return False
    
    print("✅ CMSSW environment initialized successfully!")
    
    # Test compilation
    print("\n2. Testing compilation...")
    compiler = AnalyzerCompiler(
        shell=shell_session,
        recompile=True,
        parallel_jobs=4
    )
    
    success = compiler.build_with_shell()
    if not success:
        print("❌ Compilation failed")
        return False
    
    print("✅ Compilation successful!")
    
    # Test RazorRunner (just setup, not full execution)
    print("\n3. Testing RazorRunner setup...")
    runner = RazorRunner(
        shell=shell_session, 
        analyzer_name="llp_MuonSystem_CA_mdsnano"
    )
    
    # Just test the navigation and environment setup
    success, output, exit_code = shell_session.run_command("pwd")
    current_dir = output.strip() if success else ""
    print(f"Current directory: {current_dir}")
    
    # Navigate to analyzer directory  
    if current_dir.endswith("/CMSSW_14_1_0_pre4"):
        analyzer_path = "src/run3_llp_analyzer"
    elif current_dir.endswith("/work/mds-ml"):
        analyzer_path = "CMSSW_14_1_0_pre4/src/run3_llp_analyzer"
    elif current_dir.endswith("/run3_llp_analyzer"):
        analyzer_path = "."
    else:
        analyzer_path = "CMSSW_14_1_0_pre4/src/run3_llp_analyzer"
    
    if analyzer_path != ".":
        success, output, exit_code = shell_session.run_command(f"cd {analyzer_path}")
        if exit_code != 0:
            print(f"❌ Failed to navigate to analyzer directory")
            return False
    
    # Check if RazorRun and executables exist
    success, output, exit_code = shell_session.run_command("ls -la RazorRun")
    if exit_code != 0:
        print("❌ RazorRun script not found")
        return False
    
    success, output, exit_code = shell_session.run_command("ls -la bin/Run*")
    if exit_code != 0:
        print("❌ No executables found in bin/")
        return False
    
    print("✅ RazorRunner setup successful!")
    print(f"Available executables:\n{output}")
    
    # Clean up
    shell_session.stop()
    
    print("\n🎉 All tests passed! Your pipeline is working correctly.")
    return True

if __name__ == "__main__":
    success = test_pipeline()
    if not success:
        sys.exit(1) 