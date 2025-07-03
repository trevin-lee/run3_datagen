from pathlib import Path
from typing import Optional, List, Dict, Tuple

from .shell_session import PersistentShellSession


class AnalyzerCompiler:
    """
    A class to handle compilation of CMSSW analyzers using the proper CMSSW build system.
    """
    
    def __init__(self, shell: PersistentShellSession, recompile: bool = True, parallel_jobs: int = 4):
        """
        Initialize the compiler.
        """
        self.recompile = recompile
        self.parallel_jobs = parallel_jobs
        self.shell = shell
        self.working_directory = shell.get_working_directory()

    def build_with_shell(self) -> bool:
        """
        Build the analyzer using the proper CMSSW build system.
        """ 
        if not self.recompile:
            print("[Compiler] Skipping compilation (recompile=False)")
            return True

        # Check if we're already in CMSSW src directory, if not navigate there
        success, output, exit_code = self.shell.run_command("pwd")
        current_dir = output.strip() if success else ""
        
        if not current_dir.endswith("/CMSSW_14_1_0_pre4/src"):
            # Try to navigate to CMSSW src directory
            success, output, exit_code = self.shell.run_command("cd CMSSW_14_1_0_pre4/src")
            if exit_code != 0:
                print(f"[Compiler] ERROR: Failed to navigate to CMSSW src directory")
                print(f"Output:\n{output}")
                return False

        # Ensure CMSSW environment is set up
        print("[Compiler] Setting up CMSSW environment...")
        success, output, exit_code = self.shell.run_command("cmsenv")
        if exit_code != 0:
            print(f"[Compiler] ERROR: Failed to set up CMSSW environment")
            print(f"Output:\n{output}")
            return False

        # Check if we need to run ProjectRename (in case the project was moved)
        print("[Compiler] Checking CMSSW project status...")
        success, output, exit_code = self.shell.run_command("scram b echo_CXX 2>&1")
        
        if "moved/renamed" in output or exit_code != 0:
            print("[Compiler] Project was moved, running ProjectRename...")
            success, output, exit_code = self.shell.run_command("scramv1 b ProjectRename")
            if exit_code != 0:
                print(f"[Compiler] ERROR: ProjectRename failed")
                print(f"Output:\n{output}")
                return False
            print("[Compiler] ProjectRename completed successfully")

        # Build using CMSSW's scram build system
        build_commands = [
            f"scram b clean",  # Clean previous build
            f"scram b -j{self.parallel_jobs}",  # Build with specified parallel jobs
        ]

        for cmd in build_commands:
            print(f"[Compiler] Running: {cmd}")
            success, output, exit_code = self.shell.run_command(cmd)
            if exit_code != 0:
                print(f"[Compiler] ERROR: Command failed: {cmd}")
                print(f"Output:\n{output}")
                return False

        print("[Compiler] CMSSW analyzer built successfully using scram build system")
        return True

    def clean_build(self) -> bool:
        """
        Perform a clean build by removing all previous build artifacts.
        """
        print("[Compiler] Performing clean build...")
        
        # Navigate to CMSSW src directory if needed
        success, output, exit_code = self.shell.run_command("pwd")
        current_dir = output.strip() if success else ""
        
        if not current_dir.endswith("/CMSSW_14_1_0_pre4/src"):
            success, output, exit_code = self.shell.run_command("cd CMSSW_14_1_0_pre4/src")
            if exit_code != 0:
                print(f"[Compiler] ERROR: Failed to navigate to CMSSW src directory")
                return False

        # Ensure CMSSW environment is set up
        success, output, exit_code = self.shell.run_command("cmsenv")
        if exit_code != 0:
            print(f"[Compiler] ERROR: Failed to set up CMSSW environment")
            return False

        # Perform clean build
        success, output, exit_code = self.shell.run_command(f"scram b clean && scram b -j{self.parallel_jobs}")
        if exit_code != 0:
            print(f"[Compiler] ERROR: Clean build failed")
            print(f"Output:\n{output}")
            return False

        print("[Compiler] Clean build completed successfully")
        return True

    def check_build_status(self) -> bool:
        """
        Check if the analyzer is already built and up to date.
        """
        success, output, exit_code = self.shell.run_command("pwd")
        current_dir = output.strip() if success else ""
        
        if not current_dir.endswith("/CMSSW_14_1_0_pre4/src"):
            success, output, exit_code = self.shell.run_command("cd CMSSW_14_1_0_pre4/src")
            if exit_code != 0:
                return False
        
        success, output, exit_code = self.shell.run_command("cmsenv && scram b echo_CXX")
        return exit_code == 0