#!/usr/bin/env bash
#
# MasterR uninstaller.
# Removes MasterR configs, restores backups, and provides a full purge mode
# to wipe caches, state, themes, binaries, wallpapers, and optional packages.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

# Hanko styling
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    verm=$(printf '\033[38;2;192;68;43m')
    flame=$(printf '\033[38;2;255;154;100m')
    cream=$(printf '\033[38;2;230;214;203m')
    bright=$(printf '\033[38;2;255;246;240m')
    dim=$(printf '\033[38;2;138;125;116m')
    faint=$(printf '\033[38;2;111;99;91m')
    rst=$(printf '\033[0m')
else
    verm=""; flame=""; cream=""; bright=""; dim=""; faint=""; rst=""
fi

sec()  { printf '\n  %s▌%s %s%s%s\n' "$verm" "$rst" "$cream" "$1" "$rst"; }
gap()  { printf '  %s▏%s\n' "$faint" "$rst"; }
row()  { printf '  %s▏%s  %s\n' "$faint" "$rst" "$1"; }
act()  { printf '  %s▫%s %s%s%s %s%s%s\n' "$flame" "$rst" "$cream" "$1" "$rst" "$bright" "$2" "$rst"; }
note() { printf '  %s▫%s %s%s%s\n' "$faint" "$rst" "$dim" "$*" "$rst"; }
die()  { printf '  %s▌%s %s%s%s\n' "$verm" "$rst" "$verm" "$*" "$rst" >&2; exit 1; }

usage() {
    cat << EOF
Usage: ./uninstall.sh [OPTIONS]

Options:
  --purge, --all        Completely remove the entire MasterR setup:
                        configs, caches, state, symlinks, themes, wallpapers, and clone.
  --configs-only        Standard removal: remove ~/.config entries and restore backups.
  --remove-packages     Prompt to uninstall packages installed for MasterR.
  --dry-run             Preview all actions without modifying the system.
  -y, --yes             Skip interactive confirmation prompts.
  -h, --help            Show this help message.

Examples:
  ./uninstall.sh                # Interactive menu (choose standard or full purge)
  ./uninstall.sh --purge        # Cleanly purge entire rice and themes
  ./uninstall.sh --purge -y     # Non-interactive full purge
  ./uninstall.sh --dry-run      # Preview uninstall actions
EOF
    exit 0
}

DRY_RUN=false
PURGE=false
CONFIGS_ONLY=false
REMOVE_PACKAGES=false
ASSUME_YES=false
EXTRA_ARGS=()

while [ $# -gt 0 ]; do
    case "$1" in
        --purge|--all) PURGE=true ;;
        --configs-only) CONFIGS_ONLY=true ;;
        --remove-packages) REMOVE_PACKAGES=true ;;
        --dry-run) DRY_RUN=true ;;
        -y|--yes) ASSUME_YES=true ;;
        -h|--help) usage ;;
        *) EXTRA_ARGS+=("$1") ;;
    esac
    shift
done

# Locate python installer
INSTALLER_PY=""
if [ -f "$SCRIPT_DIR/installer/masterr_install.py" ]; then
    INSTALLER_PY="$SCRIPT_DIR/installer/masterr_install.py"
elif [ -f "${XDG_DATA_HOME:-$HOME/.local/share}/masterr/installer/masterr_install.py" ]; then
    INSTALLER_PY="${XDG_DATA_HOME:-$HOME/.local/share}/masterr/installer/masterr_install.py"
else
    die "Could not find installer/masterr_install.py. Make sure you run this script inside the MasterR repository."
fi

# Interactive menu if neither --purge nor --configs-only was specified and stdin is a TTY
if [ "$PURGE" = false ] && [ "$CONFIGS_ONLY" = false ]; then
    if [ -t 0 ] && [ "$ASSUME_YES" = false ]; then
        sec "MasterR Uninstaller"
        gap
        row "${cream}Choose an uninstall mode:${rst}"
        gap
        row "${flame}1)${rst} ${bright}Standard uninstall${rst}  ${dim}(Remove ~/.config entries and restore your backups)${rst}"
        row "${flame}2)${rst} ${bright}Full purge${rst}          ${dim}(Remove configs, caches, states, themes, binaries, wallpapers, clone)${rst}"
        row "${flame}3)${rst} ${bright}Full purge + Packages${rst} ${dim}(Full purge plus remove MasterR-specific packages)${rst}"
        row "${flame}4)${rst} ${dim}Cancel${rst}"
        gap
        printf "  %s▌%s %sSelect an option [1-4]:%s " "$verm" "$rst" "$cream" "$rst"
        read -r choice || choice="4"
        case "$choice" in
            1) CONFIGS_ONLY=true ;;
            2) PURGE=true ;;
            3) PURGE=true; REMOVE_PACKAGES=true ;;
            *) note "Uninstall cancelled."; exit 0 ;;
        esac
    else
        # Non-interactive default is standard configs-only removal
        CONFIGS_ONLY=true
    fi
fi

# Shell reversion prompt/check if full purge
revert_shell() {
    current_shell=$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || echo "$SHELL")
    if [[ "$current_shell" =~ fish$ ]]; then
        fallback_shell="/bin/bash"
        [ -x "/bin/zsh" ] && fallback_shell="/bin/zsh"
        [ -x "/bin/bash" ] && fallback_shell="/bin/bash"

        if [ "$DRY_RUN" = true ]; then
            echo "  would revert login shell from $current_shell to $fallback_shell"
            return 0
        fi

        do_revert=false
        if [ "$ASSUME_YES" = true ]; then
            do_revert=true
        elif [ -t 0 ]; then
            printf "\n  %s▌%s %sYour login shell is currently set to fish. Revert to %s?%s [Y/n] " \
                "$verm" "$rst" "$cream" "$fallback_shell" "$rst"
            read -r ans || ans="y"
            case "$ans" in
                ""|y|Y|yes|YES) do_revert=true ;;
                *) do_revert=false ;;
            esac
        fi

        if [ "$do_revert" = true ]; then
            if command -v sudo >/dev/null 2>&1; then
                sudo chsh -s "$fallback_shell" "$USER" && act "reverted shell to" "$fallback_shell" || true
            else
                chsh -s "$fallback_shell" && act "reverted shell to" "$fallback_shell" || true
            fi
        fi
    fi
}

# Optional package removal
remove_installed_packages() {
    # Distro-agnostic list of rice-specific packages safe to remove
    RICE_PKGS=("quickshell" "matugen" "swww" "hyprpicker" "hyprpolkitagent" "hypridle" "hyprsunset" "dotool" "cava" "ghostty" "satty")
    
    if [ "$DRY_RUN" = true ]; then
        echo "  would check and prompt to remove rice packages: ${RICE_PKGS[*]}"
        return 0
    fi

    echo ""
    sec "Optional Package Removal"
    gap
    row "${dim}Candidate packages to remove:${rst} ${cream}${RICE_PKGS[*]}${rst}"
    gap

    do_rm=false
    if [ "$ASSUME_YES" = true ]; then
        do_rm=true
    elif [ -t 0 ]; then
        printf "  %s▌%s %sUninstall these rice packages?%s [y/N] " "$verm" "$rst" "$cream" "$rst"
        read -r ans || ans="n"
        case "$ans" in
            y|Y|yes|YES) do_rm=true ;;
            *) do_rm=false ;;
        esac
    fi

    if [ "$do_rm" = true ]; then
        # Detect package manager
        if command -v pacman >/dev/null 2>&1; then
            to_remove=()
            for p in "${RICE_PKGS[@]}"; do
                if pacman -Qq "$p" >/dev/null 2>&1; then
                    to_remove+=("$p")
                fi
            done
            if [ ${#to_remove[@]} -gt 0 ]; then
                sudo pacman -Rns --noconfirm "${to_remove[@]}" || sudo pacman -R --noconfirm "${to_remove[@]}" || true
            else
                note "None of the candidate packages are installed via pacman."
            fi
        elif command -v apt-get >/dev/null 2>&1; then
            to_remove=()
            for p in "${RICE_PKGS[@]}"; do
                if dpkg -s "$p" >/dev/null 2>&1; then
                    to_remove+=("$p")
                fi
            done
            if [ ${#to_remove[@]} -gt 0 ]; then
                sudo apt-get remove --purge -y "${to_remove[@]}" || true
            fi
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf remove -y "${RICE_PKGS[@]}" 2>/dev/null || true
        elif command -v zypper >/dev/null 2>&1; then
            sudo zypper --non-interactive remove -u "${RICE_PKGS[@]}" 2>/dev/null || true
        fi
    fi
}

# Construct command line for masterr_install.py
CMD=("python3" "$INSTALLER_PY" "--uninstall")
[ "$DRY_RUN" = true ] && CMD+=("--dry-run")
[ "$PURGE" = true ] && CMD+=("--purge")
[ "$ASSUME_YES" = true ] && CMD+=("-y")
[ ${#EXTRA_ARGS[@]} -gt 0 ] && CMD+=("${EXTRA_ARGS[@]}")

# Execute the python uninstaller
"${CMD[@]}"

# Perform shell reversion and package removal if purge/requested
if [ "$PURGE" = true ]; then
    revert_shell
fi

if [ "$REMOVE_PACKAGES" = true ]; then
    remove_installed_packages
fi

if [ "$DRY_RUN" = false ]; then
    sec "Uninstall Finished"
    gap
    row "${dim}Your previous configs (if any) have been restored.${rst}"
    row "${dim}A system reboot or fresh login session is recommended.${rst}"
    gap
fi
