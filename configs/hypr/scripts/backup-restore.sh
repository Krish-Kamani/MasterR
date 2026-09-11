#!/usr/bin/env bash
#
# backup-restore.sh — 1-click configuration backup and restore for MasterR.
# Backs up ~/.config/hypr, ~/.config/quickshell, ~/.config/ghostty, and flags.json.
#

set -euo pipefail

BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/masterr/backups"
mkdir -p "$BACKUP_DIR"

case "${1:-list}" in
    backup)
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        NAME="${2:-backup_$TIMESTAMP}"
        ARCHIVE="$BACKUP_DIR/${NAME}.tar.gz"
        
        tar -czf "$ARCHIVE" \
            -C "$HOME" \
            .config/hypr \
            .config/quickshell \
            .config/ghostty \
            .local/state/masterr/flags.json \
            2>/dev/null || true
            
        echo "$ARCHIVE"
        ;;
        
    list)
        python3 -c "
import json, os, glob
from pathlib import Path
bdir = Path('$BACKUP_DIR')
files = sorted(bdir.glob('*.tar.gz'), key=os.path.getmtime, reverse=True)
out = []
for f in files:
    stat = f.stat()
    out.append({
        'name': f.name,
        'path': str(f.resolve()),
        'size': stat.st_size,
        'mtime': stat.st_mtime
    })
print(json.dumps(out, indent=2))
"
        ;;
        
    restore)
        TARGET="${2:-}"
        if [ -z "$TARGET" ]; then
            echo "Usage: $0 restore <archive_name_or_path>" >&2
            exit 1
        fi
        
        [ -f "$TARGET" ] || TARGET="$BACKUP_DIR/$TARGET"
        if [ ! -f "$TARGET" ]; then
            echo "Backup file not found: $TARGET" >&2
            exit 1
        fi
        
        tar -xzf "$TARGET" -C "$HOME"
        echo "Restored from $TARGET"
        
        # Reload daemons
        hyprctl reload >/dev/null 2>&1 || true
        qs -c pill ipc reload >/dev/null 2>&1 || true
        ;;
        
    *)
        echo "Usage: $0 [backup [name] | list | restore <file>]" >&2
        exit 1
        ;;
esac
