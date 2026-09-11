#!/usr/bin/env python3
"""
The generic, brick-safe GRUB theme step for the MasterR installer.

It does one thing: drop the torii theme into /boot/grub and point GRUB at it. It
never touches boot entries, never disables os-prober, never deploys a curated
menu. That keeps it safe on any machine; a wrong menu entry can leave a box
unbootable, a theme cannot. Erik's personal install-torii.sh (hardcoded CachyOS
disks, a fixed 3-entry menu, 10_masterr, probe-sda4.sh) is the opposite of this
and deliberately does not ship.

apply(source, dry) returns the three actions it plans or ran:
  1. copy <source>/grub/themes/torii  -> /boot/grub/themes/torii
  2. back up /etc/default/grub, then set GRUB_THEME to the theme
  3. grub-mkconfig -o /boot/grub/grub.cfg

Under dry, each action is just {"desc", "cmd"} and nothing runs. Otherwise each
action also carries {"ok", "detail"}: every step runs via sudo, failures are
collected not raised, so the caller can report them and move on.
"""
import os
import shlex
import subprocess

THEME = "masterr-glass"
GRUB_ROOT = "/boot/grub"
THEME_DEST = f"{GRUB_ROOT}/themes/{THEME}"
THEME_TXT = f"{THEME_DEST}/theme.txt"
GRUB_DEFAULT = "/etc/default/grub"
GRUB_BACKUP = "/etc/default/grub.masterr-bak"
GRUB_CFG = f"{GRUB_ROOT}/grub.cfg"


def _plan(source):
    """The three actions, as (desc, cmd) pairs, with no side effects."""
    theme_name = THEME if os.path.exists(os.path.join(source, "grub", "themes", THEME)) else "torii"
    theme_src = os.path.join(source, "grub", "themes", theme_name)
    theme_dest = f"{GRUB_ROOT}/themes/{theme_name}"
    theme_txt = f"{theme_dest}/theme.txt"

    copy = (
        f"Copy the {theme_name} GRUB theme to {theme_dest}",
        ["sudo", "sh", "-c",
         f"mkdir -p {shlex.quote(GRUB_ROOT)}/themes "
         f"&& cp -rT {shlex.quote(theme_src)} {shlex.quote(theme_dest)}"],
    )

    # Back up the original grub default once (cp -n never clobbers an earlier
    # backup), then replace an existing GRUB_THEME line or append a new one.
    set_theme = (
        f"Back up {GRUB_DEFAULT} and set GRUB_THEME",
        ["sudo", "sh", "-c",
         f'cp -n {shlex.quote(GRUB_DEFAULT)} {shlex.quote(GRUB_BACKUP)} 2>/dev/null || true; '
         f'if grep -q "^GRUB_THEME=" {shlex.quote(GRUB_DEFAULT)} 2>/dev/null; then '
         f'sed -i \'s|^GRUB_THEME=.*|GRUB_THEME="{theme_txt}"|\' {shlex.quote(GRUB_DEFAULT)}; '
         f'else printf \'\\nGRUB_THEME="{theme_txt}"\\n\' >> {shlex.quote(GRUB_DEFAULT)}; fi'],
    )

    regen = (
        f"Regenerate {GRUB_CFG}",
        ["sudo", "grub-mkconfig", "-o", GRUB_CFG],
    )

    return [copy, set_theme, regen]


def _run(cmd):
    """Run one step, return (ok, detail). A bad step is a soft failure, never a raise."""
    printable = " ".join(shlex.quote(a) for a in cmd)
    try:
        result = subprocess.run(cmd)
    except OSError as exc:
        return False, f"{exc}: {printable}"
    if result.returncode != 0:
        return False, f"exit {result.returncode}: {printable}"
    return True, ""


def apply(source, dry):
    """
    Apply the torii GRUB theme from <source>/grub/themes/torii. Theme only, it
    never edits boot entries or os-prober. Returns the list of actions: under dry
    each is {"desc", "cmd"} and nothing runs; otherwise each also gets
    {"ok", "detail"} from running it via sudo.
    """
    actions = [{"desc": desc, "cmd": cmd} for desc, cmd in _plan(source)]
    if dry:
        return actions

    # The caller already gated on bootloader == grub; guard anyway so a box with
    # grub-mkconfig on PATH but no /boot/grub never gets a half-written theme, and
    # a missing defaults file never gets fabricated as a one-line GRUB_THEME stub.
    if not os.path.isdir(GRUB_ROOT) or not os.path.isfile(GRUB_DEFAULT):
        missing = GRUB_ROOT if not os.path.isdir(GRUB_ROOT) else GRUB_DEFAULT
        for action in actions:
            action["ok"] = False
            action["detail"] = f"{missing} not found, not a standard GRUB install"
        return actions

    for action in actions:
        ok, detail = _run(action["cmd"])
        action["ok"] = ok
        action["detail"] = detail
    return actions


def _revert_plan():
    """The revert actions as (desc, cmd) pairs, with no side effects."""
    restore_default = (
        f"Restore or clean {GRUB_DEFAULT}",
        ["sudo", "sh", "-c",
         f'if [ -f {shlex.quote(GRUB_BACKUP)} ]; then '
         f'cp {shlex.quote(GRUB_BACKUP)} {shlex.quote(GRUB_DEFAULT)} && rm -f {shlex.quote(GRUB_BACKUP)}; '
         f'else sed -i \'/^GRUB_THEME=.*masterr.*\\|^GRUB_THEME=.*torii.*/d\' {shlex.quote(GRUB_DEFAULT)}; fi'],
    )
    cleanup = (
        "Remove MasterR GRUB themes and sync helpers",
        ["sudo", "rm", "-rf",
         THEME_DEST,
         f"{GRUB_ROOT}/themes/masterr-glass",
         "/usr/local/bin/sync-grub-bg",
         "/etc/sudoers.d/masterr-grub-bg"],
    )
    regen = (
        f"Regenerate {GRUB_CFG}",
        ["sudo", "grub-mkconfig", "-o", GRUB_CFG],
    )
    return [restore_default, cleanup, regen]


def revert(dry):
    """
    Revert the MasterR GRUB theme changes:
    Restores /etc/default/grub, removes the installed themes, and regenerates grub.cfg.
    """
    actions = [{"desc": desc, "cmd": cmd} for desc, cmd in _revert_plan()]
    if dry:
        return actions

    if not os.path.isdir(GRUB_ROOT) or not os.path.isfile(GRUB_DEFAULT):
        missing = GRUB_ROOT if not os.path.isdir(GRUB_ROOT) else GRUB_DEFAULT
        for action in actions:
            action["ok"] = False
            action["detail"] = f"{missing} not found, not a standard GRUB install"
        return actions

    for action in actions:
        ok, detail = _run(action["cmd"])
        action["ok"] = ok
        action["detail"] = detail
    return actions


if __name__ == "__main__":
    src = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "configs")
    out = apply(src, dry=True)
    assert len(out) == 3, f"expected 3 actions, got {len(out)}"
    for a in out:
        assert isinstance(a["cmd"], list) and a["cmd"], f"bad cmd in {a}"
        print(f"  {a['desc']}")
        print(f"    {' '.join(shlex.quote(x) for x in a['cmd'])}")
    rev = revert(dry=True)
    assert len(rev) == 3, f"expected 3 revert actions, got {len(rev)}"
    for a in rev:
        assert isinstance(a["cmd"], list) and a["cmd"], f"bad revert cmd in {a}"
        print(f"  {a['desc']}")
        print(f"    {' '.join(shlex.quote(x) for x in a['cmd'])}")
    print("selftest ok: 3 apply + 3 revert dry actions, all with cmd lists")

