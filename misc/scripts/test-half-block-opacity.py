#!/usr/bin/env python3
"""Visual regression at opacity=.70, opacity-cells=true: paired colors stay flat."""

import os
import shutil
import time


def emit(value):
    os.write(1, value.encode())


columns, rows = shutil.get_terminal_size()
cases = [
    ("Equal RGB: upper / lower / full", "38;2;40;100;160;48;2;40;100;160", "▀▄█"),
    ("Distinct RGB: orientation reverses", "38;2;40;100;160;48;2;180;60;20", "▀▄"),
    ("Equal palette: upper / lower", "38;5;31;48;5;31", "▀▄"),
    ("Distinct palette: orientation reverses", "38;5;31;48;5;166", "▀▄"),
    ("Inverse: orientation reverses", "7;38;2;40;100;160;48;2;180;60;20", "▀▄"),
    ("Sparse: uncovered half keeps window background", "38;2;40;100;160", "▀▄"),
    ("Ordinary text and spaces: background stays translucent", "38;2;40;100;160;48;2;40;100;160", "x "),
]
try:
    emit("\x1b[?1049h\x1b[?25l\x1b[2J\x1b[H\x1b[?2026h")
    row = 1
    for label, style, glyphs in cases:
        if row + 1 > rows:
            break
        emit(f"\x1b[{row};1H\x1b[0m{label[:columns]}")
        # Separate solid columns make half-cell boundaries and gaps measurable.
        width = columns // len(glyphs)
        emit(f"\x1b[{row + 1};1H\x1b[0;{style}m")
        emit("".join(glyph * width for glyph in glyphs))
        row += 2
    emit("\x1b[0m\x1b[?2026l")
    time.sleep(30)
finally:
    emit("\x1b[?2026l\x1b[0m\x1b[?25h\x1b[?1049l")
