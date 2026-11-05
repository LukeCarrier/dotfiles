from pathlib import Path
import subprocess
import sys
import unittest


SCRIPT = Path(__file__).with_name("strip-github-timestamps.py")


class StripGithubTimestampsTests(unittest.TestCase):
    def test_filter(self):
        for data, expected in [
            (b"", b""),
            (b"2026-04-01T12:34:56Z text\n", b"text\n"),
            (b"2026-04-01T12:34:56.1234567Z   indented\r\n", b"  indented\r\n"),
            (b"2026-04-01T12:34:56Z \xff no final newline", b"\xff no final newline"),
            (b"keep 2026-04-01T12:34:56Z this\n", b"keep 2026-04-01T12:34:56Z this\n"),
            (b"2026-04-01T12:34:56Z\n", b"2026-04-01T12:34:56Z\n"),
            (b"plain\n2026-04-01T12:34:56Z text\n\xff", b"plain\ntext\n\xff"),
        ]:
            with self.subTest(data=data):
                result = subprocess.run([sys.executable, str(SCRIPT)], input=data,
                                        capture_output=True, check=True)
                self.assertEqual(result.stdout, expected)
                self.assertEqual(result.stderr, b"")


if __name__ == "__main__":
    unittest.main()
