#!/usr/bin/env python3
"""
MasterR installer terminal UI, the widget layer the orchestrator imports.

This is a clack-style sequential prompt flow, not a full-screen TUI. The terminal
keeps scrolling: every answered question stays on screen, collapsed to a single
line that shows the chosen value, and the next question prints below it. A quiet
left gutter joins the whole history so you can scroll up and read every answer you
gave. The screen is never cleared. Only the one currently active prompt redraws in
place while you move the arrows; the moment you submit it freezes into scrollback
and the next prompt prints under it.

The skin is the locked MasterR Hanko: the vermilion edge marker that echoes the
pill's hanko stamps and the torii, corner-bracketed answers, square seals for
multiselect and round dots for single choice, all in the rice's ember palette.

Keys come from /dev/tty, the controlling terminal, not from stdin. The real
installer ships as `curl -fsSL ... | bash`, so the process stdin is the piped
script itself and reading keys there fails. Output goes to the same controlling
terminal so the scrolling history stays coherent, with a stdout fallback for the
headless case. When there is no controlling terminal at all the interactive
functions raise RuntimeError so the orchestrator falls back to its non-interactive
defaults instead of hanging on a read that never returns.
"""
import os
import select
import signal
import sys
import termios


_NO_COLOR = os.environ.get("NO_COLOR") is not None


def _rgb(r, g, b):
    """Truecolor foreground escape, or empty string when NO_COLOR is set."""
    return "" if _NO_COLOR else f"\033[38;2;{r};{g};{b}m"


VERM = _rgb(192, 68, 43)
FLAME = _rgb(255, 154, 100)
CREAM = _rgb(230, 214, 203)
BRIGHT = _rgb(255, 246, 240)
DIM = _rgb(138, 125, 116)
FAINT = _rgb(111, 99, 91)
GREEN = _rgb(120, 180, 120)
DEEP = _rgb(63, 69, 80)
INK = _rgb(51, 55, 63)
SLATE = _rgb(139, 145, 156)
RESET = "" if _NO_COLOR else "\033[0m"

HIDE = "\033[?25l"
SHOW = "\033[?25h"

INTRO = "▌"
OUTRO = "▌"
BAR = "▏"
ACTIVE = "◼"
DONE = "▫"
CHECK_ON = "■"
CHECK_OFF = "□"
RADIO_ON = "●"
RADIO_OFF = "○"
LBRACKET = "「"
RBRACKET = "」"

TORII = [
    (DEEP, "      ╱▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔╲"),
    (DEEP, "   ▗▄████████████████████▄▖"),
    (INK, "      ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀"),
    (VERM, "        ███   ▐▌   ███"),
    (VERM, "    ▄▄▄▄███▄▄▄▄▄▄▄▄███▄▄▄▄"),
    (FLAME, "    ▀▀▀▀███▀▀▀▀▀▀▀▀███▀▀▀▀"),
    (VERM, "        ███        ███"),
    (VERM, "        ███        ███"),
    (SLATE, "       ▟███▙      ▟███▙"),
]


_tty_out = None
_tty_out_tried = False


def _out():
    """The terminal stream for all output: /dev/tty when present, else stdout."""
    global _tty_out, _tty_out_tried
    if not _tty_out_tried:
        _tty_out_tried = True
        try:
            _tty_out = open("/dev/tty", "w")
        except OSError:
            _tty_out = None
    return _tty_out or sys.stdout


def _write(text):
    """Send text to the controlling terminal and flush it immediately."""
    stream = _out()
    stream.write(text)
    stream.flush()


def _width():
    """Columns of the controlling terminal, with a safe 80-column fallback."""
    try:
        return os.get_terminal_size(_out().fileno()).columns
    except (OSError, ValueError, AttributeError):
        return 80


def _vis(text):
    """Visible cell width of a string, counting the corner brackets as two."""
    return sum(2 if ch in (LBRACKET, RBRACKET) else 1 for ch in text)


def _clip(segments, width):
    """
    Assemble (color, text) pieces into one line whose visible width stays within
    the terminal, so the line never soft-wraps and the active block height stays
    predictable for the redraw math. Each piece carries its own color; a single
    reset closes the line.
    """
    parts = []
    used = 0
    for color, text in segments:
        kept = []
        for ch in text:
            cell = 2 if ch in (LBRACKET, RBRACKET) else 1
            if used + cell > width:
                break
            kept.append(ch)
            used += cell
        if kept:
            parts.append(color + "".join(kept))
        if used >= width:
            break
    return "".join(parts) + RESET


def _wrap(text, width):
    """Greedy word wrap by visible width; always returns at least one line."""
    words = text.split()
    if not words:
        return [""]
    lines = []
    current = ""
    for word in words:
        candidate = word if not current else f"{current} {word}"
        if _vis(candidate) <= width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    lines.append(current)
    return lines


def _header(marker, marker_color, title, title_color, width):
    """A step header line: two-space indent, the marker, the title."""
    return _clip(
        [("", "  "), (marker_color, marker), ("", "  "), (title_color, title)],
        width,
    )


def _gutter(segments, width):
    """A content line hung on the quiet vertical connector bar."""
    return _clip([("", "  "), (FAINT, BAR), ("", "  ")] + list(segments), width)


def _spacer(width):
    """A bare connector-bar line that breathes between steps."""
    return _clip([("", "  "), (FAINT, BAR)], width)


def _bottom(width):
    """The vermilion bottom cap that closes an active prompt block."""
    return _clip([("", "  "), (VERM, OUTRO)], width)


def _bracket_lines(value, width):
    """
    The corner-bracketed answer value, wrapped across connector lines when long.
    Only the first line opens with the left bracket and only the last closes with
    the right one, so a multi-line value still reads as a single quoted answer.
    """
    inner = max(8, width - 9)
    chunks = _wrap(value, inner)
    lines = []
    for i, chunk in enumerate(chunks):
        left = LBRACKET if i == 0 else " "
        right = RBRACKET if i == len(chunks) - 1 else ""
        lines.append(_gutter([(CREAM, f"{left}{chunk}{right}")], width))
    return lines


def _collapsed_block(title, value, width):
    """The frozen form of an answered step: done marker, value, a breathing bar."""
    lines = [_header(DONE, FAINT, title, CREAM, width)]
    lines.extend(_bracket_lines(value, width))
    lines.append(_spacer(width))
    return lines


def _menu_block(title, options, idx, checked, multi, width):
    """
    The active choice block. The header carries the ember active marker, each row
    shows its seal and label, the focused row alone unfolds its dim description and
    the green Recommended tag, and a vermilion cap closes the block.
    """
    lines = [_header(ACTIVE, FLAME, title, BRIGHT, width)]
    label_width = max((_vis(label) for label, _, _ in options), default=0)
    for i, (label, desc, recommended) in enumerate(options):
        focused = i == idx
        selected = i in checked
        if multi:
            seal, seal_color = (CHECK_ON, FLAME) if selected else (CHECK_OFF, FAINT)
        else:
            seal, seal_color = (RADIO_ON, FLAME) if selected else (RADIO_OFF, FAINT)
        if focused:
            label_color = BRIGHT
        elif selected:
            label_color = CREAM
        else:
            label_color = DIM
        segments = [(seal_color, seal), ("", " "), (label_color, label)]
        if focused:
            pad = " " * (label_width - _vis(label) + 4)
            if desc:
                segments += [("", pad), (FAINT, desc)]
            if recommended:
                segments += [("", "   "), (GREEN, "(Recommended)")]
        lines.append(_gutter(segments, width))
    lines.append(_bottom(width))
    return lines


def _confirm_block(title, summary, idx, width):
    """The active confirm block: the summary lines, then a Yes/No radio."""
    lines = [_header(ACTIVE, FLAME, title, BRIGHT, width)]
    inner = max(8, width - 5)
    for line in summary:
        for piece in _wrap(line, inner):
            lines.append(_gutter([(CREAM, piece)], width))
    lines.append(_spacer(width))
    for i, label in enumerate(("Yes, continue", "No, cancel")):
        focused = i == idx
        dot, dot_color = (RADIO_ON, FLAME) if focused else (RADIO_OFF, FAINT)
        label_color = BRIGHT if focused else DIM
        lines.append(_gutter([(dot_color, dot), ("", " "), (label_color, label)], width))
    lines.append(_bottom(width))
    return lines


def banner():
    """Print the torii art, the name and repo, then the intro marker once."""
    width = _width()
    lines = [_clip([("", "  "), (color, art)], width) for color, art in TORII]
    lines.append("")
    lines.append(
        _clip(
            [
                ("", "  "),
                (FLAME, "MasterR"),
                ("", "   "),
                (DIM, "A warm Hyprland rice"),
            ],
            width,
        )
    )
    lines.append(_clip([("", "  "), (FAINT, "github.com/Krish-Kamani/MasterR")], width))
    lines.append("")
    lines.append(_header(INTRO, VERM, "MasterR installer", CREAM, width))
    lines.append(_spacer(width))
    _write("\n".join(lines) + "\n")


def detected(rows):
    """
    Print the detection step, one fact per line on the gutter. Each row is
    (label, value, ok); a fresh machine reads its OS, session, package manager
    and helper at a glance, aligned and separator-free, without input.
    """
    width = _width()
    pad = max((len(label) for label, _, _ in rows), default=0)
    out = [_header(DONE, FAINT, "Detected", CREAM, width)]
    for label, value, _ in rows:
        out.append(_gutter([(DIM, label.ljust(pad) + "   "), (CREAM, value)], width))
    out.append(_spacer(width))
    _write("\n".join(out) + "\n")


def info(lines):
    """Print a quiet block of context hung on the connector gutter, word-wrapped."""
    if isinstance(lines, str):
        lines = [lines]
    width = _width()
    inner = max(8, width - 5)
    out = [_gutter([(DIM, piece)], width)
           for line in lines for piece in _wrap(line, inner)]
    out.append(_spacer(width))
    _write("\n".join(out) + "\n")


def outro(message):
    """Print the vermilion end marker that closes the whole flow."""
    _write(_header(OUTRO, VERM, message, CREAM, _width()) + "\n")


def closing(title, tally, steps, attention, notes=None):
    """
    The end-of-run summary, shaped so it reads at a glance instead of as a wall of
    text. A vermilion headline, a one-line package tally, then the numbered next
    steps with the action lit bright and its reason dimmed beside it. Anything that
    still needs the user lands last under its own vermilion header with the exact
    command to paste, so the one thing left to do never hides inside the prose.
    """
    width = _width()
    out = [_header(OUTRO, VERM, title, BRIGHT, width), _spacer(width)]

    if tally:
        out.append(_gutter([(DIM, "packages   "), (CREAM, tally)], width))
        out.append(_spacer(width))

    if steps:
        out.append(_header(DONE, FLAME, "Next", CREAM, width))
        keyw = max((_vis(k) for k, _ in steps), default=0)
        for i, (key, hint) in enumerate(steps, 1):
            seg = [(FLAME, f"{i}  "), (BRIGHT, key)]
            if hint:
                seg += [("", " " * (keyw - _vis(key) + 3)), (DIM, hint)]
            out.append(_gutter(seg, width))
        out.append(_spacer(width))

    if notes:
        for line in notes:
            out.append(_gutter([(FAINT, line)], width))
        out.append(_spacer(width))

    if attention:
        head = "One step needs you" if len(attention) == 1 else "A few steps need you"
        out.append(_header(OUTRO, VERM, head, BRIGHT, width))
        labw = max((_vis(label) for label, _ in attention), default=0)
        for label, cmd in attention:
            # Aligned one-liner when it fits; otherwise the instruction wraps onto
            # its own indented lines, since a clipped fix-hint is a useless one.
            pad = labw - _vis(label) + 3
            if 7 + _vis(label) + pad + _vis(cmd) <= width:
                out.append(_gutter(
                    [(FLAME, DONE + " "), (CREAM, label),
                     ("", " " * pad), (BRIGHT, cmd)], width))
            else:
                out.append(_gutter([(FLAME, DONE + " "), (CREAM, label)], width))
                for piece in _wrap(cmd, max(8, width - 11)):
                    out.append(_gutter([("", "  "), (BRIGHT, piece)], width))
        out.append(_spacer(width))

    _write("\n".join(out) + "\n")


def _raise_keyboard_interrupt(signum, frame):
    """Turn a SIGTERM into a KeyboardInterrupt so the finally cleanup still runs."""
    raise KeyboardInterrupt


def _enter_raw(fd):
    """
    Put the controlling terminal into raw input while keeping newline translation
    on output. Disabling ICANON and ECHO gives key-at-a-time reads with no visible
    typing; clearing ISIG means Ctrl-C arrives as a byte we decode rather than a
    signal. Returns the saved attributes so the caller can restore them.
    """
    saved = termios.tcgetattr(fd)
    new = termios.tcgetattr(fd)
    new[0] &= ~(
        termios.IGNBRK
        | termios.BRKINT
        | termios.PARMRK
        | termios.ISTRIP
        | termios.INLCR
        | termios.IGNCR
        | termios.ICRNL
        | termios.IXON
    )
    new[3] &= ~(
        termios.ECHO
        | termios.ECHONL
        | termios.ICANON
        | termios.ISIG
        | termios.IEXTEN
    )
    new[6][termios.VMIN] = 1
    new[6][termios.VTIME] = 0
    termios.tcsetattr(fd, termios.TCSADRAIN, new)
    return saved


class _Keys:
    """
    A live keyboard session bound to /dev/tty. It owns the raw-mode terminal, the
    hidden cursor, and a SIGTERM handler, and it restores all of them on exit no
    matter how the block ends. Opening fails loudly when there is no controlling
    terminal so the caller can fall back to non-interactive defaults.
    """

    def __enter__(self):
        try:
            self.fd = os.open("/dev/tty", os.O_RDONLY | os.O_NOCTTY)
        except OSError as exc:
            raise RuntimeError("no controlling terminal; use --quickstart") from exc
        try:
            self.saved = _enter_raw(self.fd)
        except termios.error as exc:
            os.close(self.fd)
            raise RuntimeError("no controlling terminal; use --quickstart") from exc
        try:
            self.old_sigterm = signal.signal(signal.SIGTERM, _raise_keyboard_interrupt)
        except ValueError:
            self.old_sigterm = None
        _write(HIDE)
        return self

    def __exit__(self, *exc):
        self._safely(lambda: _write(SHOW))
        self._safely(lambda: termios.tcsetattr(self.fd, termios.TCSADRAIN, self.saved))
        if self.old_sigterm is not None:
            self._safely(lambda: signal.signal(signal.SIGTERM, self.old_sigterm))
        self._safely(lambda: os.close(self.fd))
        return False

    @staticmethod
    def _safely(action):
        try:
            action()
        except Exception:
            pass

    def read(self):
        """Block for one key and decode it to a name the prompt loops understand."""
        data = os.read(self.fd, 1)
        if not data:
            return "eof"
        if data == b"\x1b":
            ready, _, _ = select.select([self.fd], [], [], 0.02)
            if not ready:
                return "esc"
            nxt = os.read(self.fd, 1)
            if nxt != b"[":
                return "esc"
            arrow = os.read(self.fd, 1)
            return {b"A": "up", b"B": "down", b"C": "right", b"D": "left"}.get(arrow, "esc")
        if data in (b"\r", b"\n"):
            return "enter"
        if data == b" ":
            return "space"
        if data == b"\x03":
            return "ctrl-c"
        return data.decode("utf-8", "ignore")


_PENDING = object()


def _drive(keys, render, handle, collapse):
    """
    Run one redraw-in-place prompt. render() returns the active block lines for the
    current state; the loop reprints them over their own height on each key so only
    this block moves while the frozen history above it stays put. handle(key)
    returns _PENDING to keep looping or a result to submit; on submit the block is
    redrawn once in its collapsed single-value form, freezing the answer into the
    scrollback before the next prompt prints below it.
    """
    height = 0
    while True:
        lines = render()
        if height:
            _write(f"\033[{height}A\033[J")
        _write("\n".join(lines) + "\n")
        height = len(lines)
        result = handle(keys.read())
        if result is _PENDING:
            continue
        _write(f"\033[{height}A\033[J")
        _write("\n".join(collapse(result)) + "\n")
        return result


def select_one(title, options, default=0):
    """
    Radio prompt. options is a list of (label, desc, recommended_bool). The filled
    dot tracks the focused row, so whatever is highlighted on enter is the result.
    Returns the chosen index, or raises KeyboardInterrupt if the user cancels.
    """
    if not options:
        raise ValueError(f"select_one({title!r}) needs at least one option")
    with _Keys() as keys:
        state = {"idx": default}

        def render():
            return _menu_block(title, options, state["idx"], {state["idx"]}, False, _width())

        def handle(key):
            if key in ("up", "k"):
                state["idx"] = (state["idx"] - 1) % len(options)
            elif key in ("down", "j"):
                state["idx"] = (state["idx"] + 1) % len(options)
            elif key == "enter":
                return state["idx"]
            elif key in ("ctrl-c", "q", "eof"):
                raise KeyboardInterrupt
            return _PENDING

        def collapse(result):
            return _collapsed_block(title, options[result][0], _width())

        return _drive(keys, render, handle, collapse)


def select_many(title, options, preselect=()):
    """
    Multiselect prompt. Space toggles the focused row, enter confirms. options is a
    list of (label, desc, recommended_bool); preselect seeds the ticked rows. An
    empty option list short-circuits to no choices instead of drawing a dead menu.
    Returns the sorted list of chosen indices, or raises KeyboardInterrupt.
    """
    if not options:
        return []
    with _Keys() as keys:
        state = {"idx": 0, "checked": set(preselect)}

        def render():
            return _menu_block(title, options, state["idx"], state["checked"], True, _width())

        def handle(key):
            if key in ("up", "k"):
                state["idx"] = (state["idx"] - 1) % len(options)
            elif key in ("down", "j"):
                state["idx"] = (state["idx"] + 1) % len(options)
            elif key == "space":
                state["checked"] ^= {state["idx"]}
            elif key == "enter":
                return sorted(state["checked"])
            elif key in ("ctrl-c", "q", "eof"):
                raise KeyboardInterrupt
            return _PENDING

        def collapse(result):
            value = ", ".join(options[i][0] for i in result) or "none"
            return _collapsed_block(title, value, _width())

        return _drive(keys, render, handle, collapse)


def confirm(title, lines):
    """
    Show a summary (a string or list of strings) and a Yes/No choice, default Yes.
    Returns True to proceed, False to back out. y and n are shortcuts; q or esc
    cancels, which here means False, the safe answer for a final go/no-go.
    """
    if isinstance(lines, str):
        lines = [lines]
    with _Keys() as keys:
        state = {"idx": 0}

        def render():
            return _confirm_block(title, lines, state["idx"], _width())

        def handle(key):
            if key in ("up", "k", "down", "j"):
                state["idx"] ^= 1
            elif key == "enter":
                return state["idx"] == 0
            elif key == "y":
                return True
            elif key in ("n", "q", "esc", "eof"):
                return False
            elif key == "ctrl-c":
                raise KeyboardInterrupt
            return _PENDING

        def collapse(result):
            return _collapsed_block(title, "Yes" if result else "No", _width())

        return _drive(keys, render, handle, collapse)


def _selftest():
    """A real sample flow so Erik can run this file and feel each step collapse."""
    try:
        banner()
        detected(
            [
                ("OS", "CachyOS", True),
                ("Session", "Hyprland", True),
                ("Package manager", "pacman", True),
                ("AUR helper", "yay", True),
            ]
        )
        select_one(
            "Install profile",
            [
                ("Quick", "Core defaults, no questions", True),
                ("Full", "Everything, the daily apps too", False),
                ("Custom", "Walk every choice yourself", False),
            ],
        )
        select_many(
            "Optional apps",
            [
                ("dolphin", "KDE file manager", False),
                ("keepassxc", "Password manager", False),
                ("zathura", "Keyboard PDF viewer", False),
            ],
        )
        confirm("Ready", "Install this?")
        outro("Done")
    except KeyboardInterrupt:
        _write("\n")
        outro("Cancelled")
        return 0
    except RuntimeError as exc:
        print(exc, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(_selftest())
