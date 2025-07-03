from typing import List, Optional, Union
from pathlib import Path

from .shell_session import PersistentShellSession


class RazorRunner:
    
    def __init__(self, shell: PersistentShellSession, analyzer_name: str):
        self.shell = shell
        self.analyzer_name = analyzer_name
        self.working_directory = shell.get_working_directory()

    def run_with_shell(
        self, 
        input_file: str,
        output_file: str,
        is_data: bool,
    ) -> bool:

        # Build the RazorRun command
        cmd_parts = ["./RazorRun", input_file, self.analyzer_name]
        
        if output_file:
            cmd_parts.append(f"-f={output_file}")
        if is_data:
            cmd_parts.append("-d")
            
        razor_cmd = " ".join(cmd_parts)
        
        # Check if we're already in run3_llp_analyzer directory
        success, output, exit_code = self.shell.run_command("pwd")
        current_dir = output.strip() if success else ""
        
        if not current_dir.endswith("/run3_llp_analyzer"):
            success, output, exit_code = self.shell.run_command("cd run3_llp_analyzer")
            if exit_code != 0:
                print(f"[RazorRun] ERROR: Failed to change to run3_llp_analyzer directory")
                print(f"Output:\n{output}")
                return False
        
        # Set CMSSW_BASE - determine the path based on current location
        success, output, exit_code = self.shell.run_command("pwd")
        current_dir = output.strip() if success else ""
        
        if "/CMSSW_14_1_0_pre4/src/run3_llp_analyzer" in current_dir:
            # We're in the right place, set CMSSW_BASE to grandparent
            cmssw_base_cmd = "export CMSSW_BASE=$(realpath ../..)"
        else:
            # Fallback - try relative path
            cmssw_base_cmd = "export CMSSW_BASE=$(realpath ../..)"
        
        success, output, exit_code = self.shell.run_command(cmssw_base_cmd)
        if exit_code != 0:
            print(f"[RazorRun] ERROR: Failed to set CMSSW_BASE")
            print(f"Output:\n{output}")
            return False

        print(f"[RazorRun] Executing: {razor_cmd}")
        success, output, exit_code = self.shell.run_command(razor_cmd)
        if exit_code != 0:
            print(f"[RazorRun] ERROR: Command failed: {razor_cmd}")
            print(f"Output:\n{output}")
            return False

        print("[RazorRun] Analysis completed successfully")
        return True
