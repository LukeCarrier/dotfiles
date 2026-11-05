from pathlib import Path
import subprocess
import sys
import unittest


SCRIPT = Path(__file__).parent / "bin" / "strip-ansi.py"


class StripAnsiTests(unittest.TestCase):
    def test_filter(self):
        for data, expected in [
            (b"", b""),
            (b"plain\r\n\xff no final newline", b"plain\r\n\xff no final newline"),
            (b"\x1b[31mred\x1b[0m\n", b"red\n"),
            (b"before\x1b[2Kafter", b"beforeafter"),
            (b"\x1b]0;title\x07text", b"text"),
            (b"\x1b]8;;https://example.com\x1b\\link\x1b]8;;\x1b\\", b"link"),
            (b"before\x1bMafter\xff", b"beforeafter\xff"),
        ]:
            with self.subTest(data=data):
                result = subprocess.run([sys.executable, str(SCRIPT)], input=data,
                                        capture_output=True, check=True)
                self.assertEqual(result.stdout, expected)
                self.assertEqual(result.stderr, b"")


if __name__ == "__main__":
    unittest.main()
