#!/usr/bin/env python3
"""Remove ANSI escape sequences from stdin, writing plain text to stdout."""

import re
import sys


escape = re.compile(
    rb"\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)"  # OSC: titles and hyperlinks.
    rb"|\x1b\[[0-?]*[ -/]*[@-~]"  # CSI: styling and cursor controls.
    rb"|\x1b[ -/]*[@-Z\\-_]"  # Other ESC sequences.
)

sys.stdout.buffer.write(escape.sub(b"", sys.stdin.buffer.read()))
