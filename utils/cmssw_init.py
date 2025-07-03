from pathlib import Path
from .shell_session import PersistentShellSession

class CMSSWInitializer:
    """Initializes a CMSSW environment in a persistent shell session."""
    
    def __init__(self, shell: PersistentShellSession, cmssw_path: Path):
        self.shell = shell
        self.cmssw_path = str(cmssw_path)

    def setup_with_shell(self) -> bool:
        commands = [
            f"cd {self.cmssw_path}",
            "cd src",
            "source /cvmfs/cms.cern.ch/cmsset_default.sh",
            "cmsenv",
            "source /cvmfs/cms.cern.ch/el9_amd64_gcc12/lcg/root/6.30.07-024df6516c17fd2edef848a927a788f1/bin/thisroot.sh"
        ]
        
        for cmd in commands:
            success, output, exit_code = self.shell.run_command(cmd)
            if not success or exit_code != 0:
                print(f"[CMSSW] ERROR: Command failed during setup: {cmd}")
                print(f"Exit code: {exit_code}")
                if output:
                    print(f"Output: {output}")
                return False

        return True
    
