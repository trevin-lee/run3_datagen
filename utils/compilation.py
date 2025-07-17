from pathlib import Path
from typing import Optional, List, Dict, Tuple

from .shell_session import PersistentShellSession


class AnalyzerCompiler:
    """
    A class to handle compilation of CMSSW analyzers using the proper build system.
    For run3_llp_analyzer, this uses the standalone Makefile rather than CMSSW's scram.
    """
    
    def __init__(self, shell: PersistentShellSession, recompile: bool = True):
        """
        Initialize the compiler.
        """
        self.recompile = recompile
        self.shell = shell
        self.working_directory = shell.get_working_directory()

    def build_with_shell(self) -> bool:
        """
        Build the analyzer using the proper build system.
        For run3_llp_analyzer, this uses the standalone Makefile.
        """ 
        if not self.recompile:
            print("[Compiler] Skipping compilation (recompile=False)")
            return True

        success, output, exit_code = self.shell.run_command("pwd")
        current_dir = output.strip() if success else ""
        print(f"[Compiler] Current directory: {current_dir}")
        print("[Compiler] Setting up build environment...")
        
        commands = [
            "cd run3_llp_analyzer",
            "make clean",
            "make -j 8"
        ]
        
        for cmd in commands:
            success, output, exit_code = self.shell.run_command(cmd)
            if exit_code != 0:
                print(f"[Compiler] ERROR: Environment setup failed: {cmd}")
                if output:
                    print(f"Output:\n{output}")
                return False
        
        return True

       