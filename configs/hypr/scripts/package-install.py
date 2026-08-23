#!/usr/bin/env python3
"""
Interactive Package Installer with Smart Error Diagnosis & Auto-Fix.
Runs inside a floating Ghostty window when an app/package is chosen in MasterR.
"""

import os
import sys
import time
import getpass
import subprocess
import shutil

# ANSI Styling (matching MasterR palette)
C_RESET = "\033[0m"
C_BOLD = "\033[1m"
C_DIM = "\033[2m"
C_VERM = "\033[38;2;224;86;59m"      # #e0563b
C_FLAME = "\033[38;2;255;154;100m"   # #ff9a64
C_CREAM = "\033[38;2;230;214;203m"   # #e6d6cb
C_FAINT = "\033[38;2;111;99;91m"     # #6f635b
C_GREEN = "\033[38;2;118;185;71m"
C_YELLOW = "\033[38;2;240;180;60m"
C_BG_CARD = "\033[48;2;34;24;19m"

def clear_screen():
    os.system("clear")

def print_header(pkg_name: str, source: str, version: str = ""):
    print()
    print(f"  {C_VERM}▌{C_RESET} {C_BOLD}{C_CREAM}Package Installation{C_RESET}")
    print(f"  {C_FAINT}▏{C_RESET}")
    src_badge = f"{C_GREEN}[Official Repo (OAR)]{C_RESET}" if source == "OAR" else f"{C_FLAME}[Arch User Repo (AUR)]{C_RESET}"
    ver_str = f" {C_FAINT}({version}){C_RESET}" if version else ""
    print(f"  {C_FAINT}▏{C_RESET}  Target:  {C_BOLD}{C_CREAM}{pkg_name}{C_RESET}{ver_str}")
    print(f"  {C_FAINT}▏{C_RESET}  Source:  {src_badge}")
    print(f"  {C_FAINT}▏{C_RESET}")

def prompt_sudo():
    """Prompt for sudo password cleanly and cache credentials."""
    # Check if sudo is already validated
    res = subprocess.run(["sudo", "-n", "true"], capture_output=True)
    if res.returncode == 0:
        return True

    print(f"  {C_FLAME}▫{C_RESET} {C_CREAM}Administrator authorization required:{C_RESET}")
    attempts = 0
    while attempts < 3:
        try:
            pwd = getpass.getpass(f"  {C_FAINT}▏{C_RESET}  [sudo] password for {getpass.getuser()}: ")
            if not pwd:
                print(f"  {C_FAINT}▏{C_RESET}  {C_VERM}Password cannot be empty.{C_RESET}")
                attempts += 1
                continue
            
            p = subprocess.Popen(["sudo", "-S", "-v"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            _, err = p.communicate(input=pwd + "\n")
            if p.returncode == 0:
                print(f"  {C_FAINT}▏{C_RESET}  {C_GREEN}✔ Authentication successful.{C_RESET}")
                print(f"  {C_FAINT}▏{C_RESET}")
                return True
            else:
                attempts += 1
                left = 3 - attempts
                print(f"  {C_FAINT}▏{C_RESET}  {C_VERM}Incorrect password ({left} attempts remaining).{C_RESET}")
        except (KeyboardInterrupt, EOFError):
            print(f"\n  {C_FAINT}▏{C_RESET}  {C_VERM}Operation cancelled by user.{C_RESET}")
            return False
    return False

def diagnose_error(output_text: str):
    """Analyze package manager output to identify root cause and actionable fix."""
    lower = output_text.lower()
    
    if "db.lck" in lower or "/var/lib/pacman/db.lck" in lower:
        return {
            "type": "DATABASE_LOCK",
            "title": "Pacman Database Lock Detected",
            "cause": "Another package manager is currently active, or a previous installation terminated unexpectedly and left a stale lock file (/var/lib/pacman/db.lck).",
            "solution": "Remove the stale lock file and retry the installation.",
            "fix_cmd": "sudo rm -f /var/lib/pacman/db.lck"
        }
    
    if "pgp signature" in lower or "invalid or corrupted package" in lower or "unknown trust" in lower or "keyring" in lower:
        return {
            "type": "KEYRING_ERROR",
            "title": "Outdated or Corrupted PGP Keyring",
            "cause": "The Arch Linux signature keyring on your system is outdated, causing PGP verification to reject packages.",
            "solution": "Refresh the archlinux-keyring and sync package keys.",
            "fix_cmd": "sudo pacman -Sy --noconfirm archlinux-keyring && sudo pacman-key --refresh-keys"
        }
    
    if "exists in filesystem" in lower:
        return {
            "type": "FILE_CONFLICT",
            "title": "Filesystem File Collision",
            "cause": "Files from this package already exist on your filesystem (often from a previous manual install or conflicting package).",
            "solution": "Force overwrite conflicting files during installation.",
            "fix_cmd": "OVERWRITE"
        }

    if "cannot find" in lower and ("make" in lower or "gcc" in lower or "automake" in lower or "fakeroot" in lower):
        return {
            "type": "MISSING_DEVEL",
            "title": "Missing Base Development Tools",
            "cause": "AUR packages require compilation tools (gcc, make, automake, fakeroot) which are not installed.",
            "solution": "Install the base-devel meta-package.",
            "fix_cmd": "sudo pacman -S --needed --noconfirm base-devel"
        }

    if "failed retrieving file" in lower or "could not resolve host" in lower or "the requested url returned error: 404" in lower:
        return {
            "type": "MIRROR_OUTDATED",
            "title": "Package Mirror Sync Error (404 Not Found)",
            "cause": "Your local repository index is out of sync with current mirrors, or the mirror is unreachable.",
            "solution": "Force synchronize package databases with upstream mirrors.",
            "fix_cmd": "sudo pacman -Syy"
        }

    if "not enough free disk space" in lower or "partition / is full" in lower:
        return {
            "type": "DISK_FULL",
            "title": "Insufficient Disk Space",
            "cause": "The root filesystem partition does not have sufficient space to extract and install this package.",
            "solution": "Clean cached pacman archives to free up disk space.",
            "fix_cmd": "sudo pacman -Sc --noconfirm"
        }

    if "unresolvable package conflict" in lower or "conflicting dependencies" in lower:
        return {
            "type": "DEPENDENCY_CONFLICT",
            "title": "Package Dependency Conflict",
            "cause": "This package requires or replaces existing installed packages that conflict with your current setup.",
            "solution": "Review conflicting package names in the log above and remove the incompatible package before installing.",
            "fix_cmd": None
        }

    return {
        "type": "UNKNOWN_ERROR",
        "title": "Installation Encountered an Error",
        "cause": "The package manager returned a non-zero exit status. See the log above for details.",
        "solution": "Check your internet connection or inspect the package PKGBUILD/upstream issues.",
        "fix_cmd": None
    }

def run_installation(pkg_name: str, source: str, force_overwrite: bool = False):
    """Run pacman or yay command with live streaming."""
    if source == "AUR" or shutil.which("yay"):
        cmd = ["yay", "-S", "--needed", "--noconfirm"]
    else:
        cmd = ["sudo", "pacman", "-S", "--needed", "--noconfirm"]

    if force_overwrite:
        cmd.extend(["--overwrite", "*"])

    cmd.append(pkg_name)

    print(f"  {C_FLAME}▫{C_RESET} {C_CREAM}Executing: {C_BOLD}{' '.join(cmd)}{C_RESET}\n")
    
    logs = []
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
    
    for line in process.stdout:
        sys.stdout.write("  " + line)
        sys.stdout.flush()
        logs.append(line)
        
    process.wait()
    full_output = "".join(logs)
    return process.returncode, full_output

def send_notification(pkg_name: str, success: bool):
    try:
        if success:
            subprocess.run([
                "notify-send",
                "Installation Complete",
                f"{pkg_name} was successfully installed.",
                "-i", "package-x-generic",
                "-a", "MasterR Installer"
            ], timeout=2)
        else:
            subprocess.run([
                "notify-send",
                "Installation Failed",
                f"Failed to install {pkg_name}. See installer log.",
                "-i", "dialog-error",
                "-a", "MasterR Installer"
            ], timeout=2)
    except Exception:
        pass

def main():
    if len(sys.argv) < 2:
        print("Usage: package-install.py <package_name> [source] [version]")
        sys.exit(1)

    pkg_name = sys.argv[1]
    source = sys.argv[2] if len(sys.argv) > 2 else "OAR"
    version = sys.argv[3] if len(sys.argv) > 3 else ""

    force_overwrite = False

    while True:
        clear_screen()
        print_header(pkg_name, source, version)

        # Authenticate with sudo
        if not prompt_sudo():
            input(f"\n  {C_FAINT}Press Enter to exit...{C_RESET}")
            sys.exit(1)

        # Execute install
        code, output = run_installation(pkg_name, source, force_overwrite=force_overwrite)
        
        print()
        if code == 0:
            print(f"  {C_GREEN}✔ Successfully installed {C_BOLD}{pkg_name}{C_RESET}{C_GREEN}!{C_RESET}")
            send_notification(pkg_name, success=True)
            print(f"\n  {C_FAINT}Closing in 3 seconds (or press Enter)...{C_RESET}")
            try:
                for i in range(3, 0, -1):
                    time.sleep(1)
            except KeyboardInterrupt:
                pass
            sys.exit(0)
        else:
            send_notification(pkg_name, success=False)
            diag = diagnose_error(output)
            
            print(f"  {C_VERM}▌{C_RESET} {C_BOLD}{C_VERM}ERROR: {diag['title']}{C_RESET}")
            print(f"  {C_FAINT}▏{C_RESET}")
            print(f"  {C_FAINT}▏{C_RESET}  {C_BOLD}Reason:{C_RESET}   {C_CREAM}{diag['cause']}{C_RESET}")
            print(f"  {C_FAINT}▏{C_RESET}  {C_BOLD}Solution:{C_RESET} {C_YELLOW}{diag['solution']}{C_RESET}")
            print(f"  {C_FAINT}▏{C_RESET}")

            options = []
            if diag.get("fix_cmd"):
                options.append(f"{C_FLAME}[F] Auto-Fix & Retry{C_RESET}")
            options.append(f"{C_CREAM}[R] Retry{C_RESET}")
            options.append(f"{C_FAINT}[Q] Quit{C_RESET}")
            
            print(f"  {C_FAINT}▏{C_RESET}  Action: {'  '.join(options)}")
            print(f"  {C_FAINT}▏{C_RESET}")
            
            try:
                choice = input(f"  {C_FLAME}▫{C_RESET} Select option: ").strip().lower()
            except (KeyboardInterrupt, EOFError):
                choice = "q"

            if choice == "f" and diag.get("fix_cmd"):
                if diag["fix_cmd"] == "OVERWRITE":
                    force_overwrite = True
                    print(f"  {C_FAINT}▏{C_RESET}  {C_GREEN}Enabling overwrite flag for retry...{C_RESET}")
                    time.sleep(1)
                else:
                    print(f"  {C_FAINT}▏{C_RESET}  {C_YELLOW}Running fix: {diag['fix_cmd']}{C_RESET}")
                    subprocess.run(diag["fix_cmd"], shell=True)
                    time.sleep(1.5)
                continue
            elif choice == "r":
                continue
            else:
                print(f"  {C_FAINT}▏{C_RESET}  Exiting.")
                sys.exit(code)

if __name__ == "__main__":
    main()
