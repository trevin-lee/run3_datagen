from pathlib import Path
from .shell_session import PersistentShellSession

class CMSSWInitializer:
    """Initializes a CMSSW environment in a persistent shell session."""
    
    def __init__(self, shell: PersistentShellSession, project_root: string):
        self.shell = shell
        self.project_root = project_root


    def setup_with_shell(self) -> bool:
        """Set up CMSSW environment properly."""
        
        success, output, exit_code = self.shell.run_command("pwd")
        current_dir = output.strip() if success else ""
        print(f"[CMSSW] Current directory: {current_dir}")
                
        commands = [
            f"cd {self.project_root}",
            "source /cvmfs/cms.cern.ch/cmsset_default.sh",
            f"cd {self.project_root}/CMSSW_14_1_0_pre4/src",
            "source /cvmfs/cms.cern.ch/el9_amd64_gcc12/lcg/root/6.30.07-024df6516c17fd2edef848a927a788f1/bin/thisroot.sh",
            "cmsenv",
        ]
        
        for cmd in commands:
            print(f"[CMSSW] Executing: {cmd}")
            success, output, exit_code = self.shell.run_command(cmd)
            if not success or exit_code != 0:
                print(f"[CMSSW] ERROR: Command failed during setup: {cmd}")
                print(f"Exit code: {exit_code}")
                if output:
                    print(f"Output: {output}")
                return False

        success, output, exit_code = self.shell.run_command("echo $CMSSW_BASE")
        if exit_code == 0 and output.strip():
            print(f"[CMSSW] ✅ Environment initialized successfully")
            print(f"[CMSSW] CMSSW_BASE: {output.strip()}")
            
            success, output, exit_code = self.shell.run_command("which root-config")
            if exit_code == 0:
                print(f"[CMSSW] ✅ ROOT found: {output.strip()}")
                return True
            else:
                print("[CMSSW] ❌ ROOT not found after setup")
                return False
        else:
            print("[CMSSW] ❌ CMSSW environment setup failed - CMSSW_BASE not set")
            return False
    
