from typing import List, Optional, Union
from pathlib import Path

from .shell_session import PersistentShellSession


class RazorRunner:
    """
    Runner for the RazorRun analysis pipeline.
    Handles execution of the compiled analyzer executables.
    """
    
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

        self.shell.run_command("pwd")
        
        print("[RazorRun] Running RazorRun...")
        setup_commands = [
            "cd run3_llp_analyzer",
            f"./RazorRun {input_file} {self.analyzer_name} -f={output_file} -d={is_data}"
        ]
        
        for cmd in setup_commands:
            success, output, exit_code = self.shell.run_command(cmd)
            if exit_code != 0:
                print(f"[RazorRun] ERROR: Environment setup failed: {cmd}")
                if output:
                    print(f"Output:\n{output}")
                return False
        
        return True
