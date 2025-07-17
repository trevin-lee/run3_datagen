"""
MDS-ML Utils Package

This package provides utilities for fast iteration development with the LLP Run3 analyzer.

Main components:
- CMSSWInitializer: CMSSW environment setup and management  
- AnalyzerCompiler: CMSSW-native compilation using scram build system
- RazorRunner: Interface for running the RazorRun C++ analyzer
- PersistentShellSession: Maintains persistent shell state

Quick usage:
    from utils import AnalyzerCompiler, RazorRunner, PersistentShellSession
    
    shell = PersistentShellSession()
    shell.start()
    compiler = AnalyzerCompiler(shell)
    success = compiler.build_with_shell()
    
    if success:
        runner = RazorRunner(shell, "llp_MuonSystem_CA_mdsnano")
        runner.run_with_shell(input_file, output_file, is_data=False)
"""

# Import main classes for easy access
from .cmssw_init import CMSSWInitializer
from .compilation import AnalyzerCompiler
from .razor_run import RazorRunner
from .shell_session import PersistentShellSession
from .analytics import analyze_root_file

# Version info
__version__ = "1.0.0"
__author__ = "MDS-ML Development Team"

# Expose main classes in __all__ for clean imports
__all__ = [
    # CMSSW management
    'CMSSWInitializer',
    
    # Compilation
    'AnalyzerCompiler',
    
    # Analysis execution
    'RazorRunner',
    
    # Shell session management
    'PersistentShellSession',
    
    # Analytics
    'analyze_root_file',
    
    # Package info
    '__version__',
    '__author__'
]
