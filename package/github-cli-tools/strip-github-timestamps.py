#!/usr/bin/env python3
"""Remove leading GitHub Actions timestamps and their single separator space."""

import re
import sys


timestamp = re.compile(
    rb"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}"
    rb"(?:\.[0-9]+)?Z "
)

for line in sys.stdin.buffer:
    sys.stdout.buffer.write(timestamp.sub(b"", line, count=1))
