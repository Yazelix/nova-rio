#!/usr/bin/env python3
"""Visual regression: hidden phases stay blank; visible moves settle while idle."""

import os
import shutil
import time


def emit(value):
    os.write(1, value.encode())


def pause(label, cursor):
    emit(f"\x1b[?2026h\x1b[1;1H\x1b[2K{label}{cursor}\x1b[?2026l")
    time.sleep(1)


columns, rows = shutil.get_terminal_size()
center = f"\x1b[{max(3, rows - 2)};{max(2, columns // 2)}H"
try:
    emit("\x1b[?1049h\x1b[2J\x1b[2 q")
    pause("Visible cursor", center + "\x1b[?25h")
    for column in (1, columns):
        pause("Hidden cursor: no trail", f"\x1b[?25l\x1b[{rows // 2};{column}H")
        pause("Visible again: no trail from the border", center + "\x1b[?25h")
    for column in (1, columns):
        pause("Visible movement: trail settles while idle", f"\x1b[{rows // 2};{column}H")
        pause("Visible return: trail settles while idle", center)
finally:
    emit("\x1b[0 q\x1b[?25h\x1b[?1049l")
