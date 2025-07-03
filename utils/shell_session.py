"""
Persistent Shell Session Module

This module provides a shell session wrapper that maintains environment
state across commands using shell script generation.
"""

import subprocess
import os
import tempfile
from pathlib import Path
from typing import Optional, Tuple, List
import shlex


class PersistentShellSession:
    """A shell session that maintains environment state across commands."""

    def __init__(self, working_directory=None, verbose: bool = True, timeout: int = 300):
        """
        Initialize a shell session.
        
        Args:
            working_directory: Initial working directory for the shell
            verbose: Whether to print command output
            timeout: Default timeout for commands in seconds
        """
        self.working_directory = Path(working_directory) if working_directory else Path.cwd()
        self.verbose = verbose
        self.timeout = timeout
        self.is_running = False
        
        # Track environment setup commands
        self.setup_commands: List[str] = []
        self.current_directory = str(self.working_directory)
        
    def start(self) -> bool:
        """Start the shell session."""
        self.is_running = True
        if self.verbose:
            print("[Shell] Session started successfully")
        return True

    def stop(self):
        """Stop the shell session."""
        self.is_running = False
        if self.verbose:
            print("[Shell] Session stopped")

    def add_setup_command(self, command: str):
        """Add a command to be run before every command (for environment setup)."""
        self.setup_commands.append(command)

    def run_command(self, command: str, timeout: Optional[int] = None) -> Tuple[bool, str, int]:
        """
        Run a command in the shell session.
        
        Args:
            command: The command to execute
            timeout: Command timeout (uses default if None)
            
        Returns:
            Tuple of (success, output, exit_code)
        """
        if not self.is_running:
            return False, "Shell session not running", -1

        timeout = timeout or self.timeout
        
        try:
            if self.verbose:
                print(f"[Shell] Executing: {command}")
            
            # Build the full command with all setup
            script_lines = []
            
            # Add shebang and error handling
            script_lines.append("#!/bin/bash")
            script_lines.append("set -e")  # Exit on error
            
            # Change to working directory
            script_lines.append(f"cd {shlex.quote(self.current_directory)}")
            
            # Add all setup commands (source scripts, env vars, etc.)
            for setup_cmd in self.setup_commands:
                script_lines.append(setup_cmd)
            
            # Handle directory changes specially
            if command.strip().startswith("cd "):
                # Extract the directory
                parts = command.strip().split(maxsplit=1)
                if len(parts) == 2:
                    new_dir = parts[1]
                    script_lines.append(command)
                    # Update our tracked directory
                    script_lines.append("pwd")  # Get the new absolute path
                else:
                    script_lines.append(command)
            else:
                # Add the actual command
                script_lines.append(command)
            
            # Join into a single script
            script = "\n".join(script_lines)
            
            # Run the script
            result = subprocess.run(
                ["bash", "-c", script],
                capture_output=True,
                text=True,
                timeout=timeout,
                cwd=str(self.working_directory)
            )
            
            output = result.stdout.strip()
            
            # If this was a cd command, update our current directory
            if command.strip().startswith("cd ") and result.returncode == 0:
                # The last line of output should be the new directory from pwd
                if output:
                    lines = output.split('\n')
                    if lines:
                        self.current_directory = lines[-1]
                        # Remove the pwd output from the actual output
                        output = '\n'.join(lines[:-1]).strip()
            
            # Handle special setup commands
            if result.returncode == 0:
                # Track certain commands for environment persistence
                if command.startswith("source ") or command.startswith(". "):
                    self.setup_commands.append(command)
                elif command.startswith("export "):
                    self.setup_commands.append(command)
                elif command == "cmsenv":
                    self.setup_commands.append(command)
            
            # Print output if verbose
            if self.verbose and output:
                for line in output.split('\n'):
                    if line.strip():
                        print(f"[Shell] {line}")
            
            # Also capture stderr if there was an error
            if result.returncode != 0 and result.stderr:
                if self.verbose:
                    for line in result.stderr.strip().split('\n'):
                        if line.strip():
                            print(f"[Shell] ERROR: {line}")
                output = output + "\n" + result.stderr if output else result.stderr
            
            return True, output, result.returncode
            
        except subprocess.TimeoutExpired:
            return False, f"Command timed out after {timeout} seconds", -1
        except Exception as e:
            return False, f"Error executing command: {e}", -1

    def run_command_simple(self, command: str) -> Tuple[bool, str]:
        """Simplified command execution that returns success and output only."""
        success, output, exit_code = self.run_command(command)
        return success and exit_code == 0, output

    def set_verbose(self, verbose: bool):
        """Enable or disable verbose output."""
        self.verbose = verbose
        if verbose:
            print("[Shell] Verbose mode enabled")
        else:
            print("[Shell] Verbose mode disabled")

    def get_working_directory(self) -> str:
        """Get the current working directory in the shell."""
        return self.current_directory

    def change_directory(self, path: str) -> bool:
        """Change the working directory."""
        success, output, exit_code = self.run_command(f"cd {path}")
        return success and exit_code == 0

    def __enter__(self):
        """Context manager entry."""
        self.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.stop()

