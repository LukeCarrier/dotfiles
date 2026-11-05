import copy
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import unittest
from html.parser import HTMLParser
from unittest.mock import patch


SCRIPT = Path(__file__).parent / "bin" / "terraform-plan-html.py"
spec = importlib.util.spec_from_file_location("renderer", SCRIPT)
renderer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(renderer)


class ResourceParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.addresses = []
        self.in_code = False
        self.depth = 0

    def handle_starttag(self, tag, attrs):
        if tag == "details":
            assert self.depth == 0
            assert "open" not in dict(attrs)
            self.depth += 1
        if tag == "code":
            self.in_code = True

    def handle_endtag(self, tag):
        if tag == "details":
            self.depth -= 1
        if tag == "code":
            self.in_code = False

    def handle_data(self, data):
        if self.in_code:
            self.addresses.append(data)


class RendererTests(unittest.TestCase):
    def setUp(self):
        self.plan = {
            "format_version": "1.2",
            "resource_changes": [{
                "address": 'module.example.test.item["a b"]',
                "change": {
                    "actions": ["create"], "before": None,
                    "after": {"name": "<script>alert(1)</script>", "token": "SECRET"},
                    "after_sensitive": {"token": True},
                    "after_unknown": {"id": True},
                },
            }],
        }

    def invoke(self, data):
        return subprocess.run([sys.executable, str(SCRIPT)], input=data,
                              capture_output=True)

    def test_json_stdin(self):
        result = self.invoke(json.dumps(self.plan).encode())
        self.assertEqual(result.returncode, 0, result.stderr)
        doc = result.stdout.decode()
        self.assertNotIn("SECRET", doc)
        self.assertIn("(sensitive value)", doc)
        self.assertIn("(known after apply)", doc)
        self.assertIn("&lt;script&gt;", doc)
        parser = ResourceParser()
        parser.feed(doc)
        self.assertEqual(parser.addresses, [self.plan["resource_changes"][0]["address"]])
        self.assertEqual(parser.depth, 0)
        self.assertIn("Copy all resource addresses", doc)

    def test_actions(self):
        for actions, label in [
            (["create"], "will be created"), (["delete"], "will be destroyed"),
            (["update"], "will be updated in-place"), (["read"], "will be read"),
            (["create", "delete"], "create then destroy"),
            (["delete", "create"], "destroy then create"),
            (["no-op"], "no changes"), (["forget"], "not destroyed"),
        ]:
            with self.subTest(actions=actions):
                plan = copy.deepcopy(self.plan)
                plan["resource_changes"][0]["change"]["actions"] = actions
                self.assertIn(label, renderer.render_json_plan(plan))

    def test_visible_diff_direction(self):
        change = {"actions": ["update"], "before": {"name": "OLD_VALUE"},
                  "after": {"name": "NEW_VALUE"}}
        doc = renderer.render_change(change)
        self.assertRegex(doc, r'class="remove">-.*OLD_VALUE')
        self.assertRegex(doc, r'class="add">\+.*NEW_VALUE')
        change["actions"] = ["create"]
        doc = renderer.render_change(change)
        self.assertIn("NEW_VALUE", doc)
        self.assertNotIn("OLD_VALUE", doc)
        change["actions"] = ["delete"]
        doc = renderer.render_change(change)
        self.assertIn("OLD_VALUE", doc)
        self.assertNotIn("NEW_VALUE", doc)

    def test_sensitive_nested_values_and_outputs(self):
        change = {
            "actions": ["update"],
            "before": {"nested": [{"password": "OLD_SECRET"}]},
            "after": {"nested": [{"password": "NEW_SECRET"}]},
            "before_sensitive": {"nested": [{"password": True}]},
            "after_sensitive": False,
        }
        self.plan["resource_changes"][0]["change"] = change
        self.plan["output_changes"] = {"secret": {
            "actions": ["create"], "after": "OUTPUT_SECRET", "after_sensitive": True,
        }}
        doc = renderer.render_json_plan(self.plan)
        for secret in ["OLD_SECRET", "NEW_SECRET", "OUTPUT_SECRET"]:
            self.assertNotIn(secret, doc)
        self.assertIn("Output changes", doc)

    def test_partial_unknown_values(self):
        self.assertEqual(renderer.display_value(None, unknown={"items": [True]}),
                         {"items": ["(known after apply)"]})

    def test_sensitive_attribute_changing_shape(self):
        for before, after, old_mask, new_mask in [
            (["OLD_SECRET"], {"token": "NEW_SECRET"}, [True], {"token": True}),
            ({"token": "OLD_SECRET"}, ["NEW_SECRET"], {"token": True}, [True]),
        ]:
            change = {"actions": ["update"], "before": before, "after": after,
                      "before_sensitive": old_mask, "after_sensitive": new_mask}
            doc = renderer.render_change(change)
            self.assertNotIn("OLD_SECRET", doc)
            self.assertNotIn("NEW_SECRET", doc)

    @unittest.skipUnless(shutil.which("node"), "Node required for clipboard JavaScript test")
    def test_copy_addresses(self):
        result = self.invoke(json.dumps(self.plan).encode())
        script = re.search(r"<script>(.*?)</script>", result.stdout.decode(), re.S)[1]
        test = r'''
const assert = require('node:assert/strict');
const addresses = ['module.test.item["a b"]', 'test.other'];
const status = {};
let copied;
let field;
Object.defineProperty(globalThis, 'navigator', {value: {
  clipboard: {writeText: async text => {copied = text}}
}, configurable: true});
globalThis.document = {
  querySelectorAll: () => addresses.map(textContent => ({textContent})),
  getElementById: () => status,
  createElement: () => field = {
    setAttribute() {}, select() {this.selected = true}, remove() {this.removed = true}
  },
  body: {append() {}},
  execCommand: () => {copied = field.value; return true}
};
(async () => {
  await copyAddresses();
  assert.equal(copied, addresses.join('\n'));
  navigator.clipboard = undefined;
  await copyAddresses();
  assert.equal(copied, addresses.join('\n'));
  assert.equal(field.removed, true);
  document.execCommand = () => false;
  await copyAddresses();
  assert.equal(field.selected, true);
  assert.match(status.textContent, /Automatic copy failed/);
  document.querySelectorAll = () => [];
  await copyAddresses();
  assert.equal(status.textContent, 'No resource addresses to copy.');
})().catch(error => {console.error(error); process.exitCode = 1});
'''
        subprocess.run(["node", "-e", script + test], check=True, capture_output=True)

    def test_saved_plan_uses_json_and_selected_engine(self):
        for engine in ["terraform", "tofu"]:
            with self.subTest(engine=engine):
                stdout = io.TextIOWrapper(io.BytesIO(), encoding="utf-8")
                argv = [str(SCRIPT), "example.tfplan", "--engine", engine]
                result = subprocess.CompletedProcess([], 0, json.dumps(self.plan).encode())
                with patch.object(sys, "argv", argv), patch.object(sys, "stdout", stdout), \
                        patch.object(renderer.subprocess, "run", return_value=result) as run:
                    renderer.main()
                run.assert_called_once_with(
                    [engine, "show", "-json", str(Path("example.tfplan").resolve())],
                    stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, check=True,
                )
                stdout.flush()
                self.assertIn(b'<details class="resource add">', stdout.buffer.getvalue())
                self.assertNotIn(b"SECRET", stdout.buffer.getvalue())

    def test_saved_plan_errors_produce_no_html(self):
        for error in [FileNotFoundError("CLI missing"), subprocess.CalledProcessError(1, ["tofu"])]:
            stdout = io.TextIOWrapper(io.BytesIO(), encoding="utf-8")
            with patch.object(sys, "argv", [str(SCRIPT), "example.tfplan", "--engine", "tofu"]), \
                    patch.object(sys, "stdout", stdout), contextlib.redirect_stderr(io.StringIO()), \
                    patch.object(renderer.subprocess, "run", side_effect=error):
                with self.assertRaises(SystemExit) as raised:
                    renderer.main()
            self.assertNotEqual(raised.exception.code, 0)
            stdout.flush()
            self.assertFalse(stdout.buffer.getvalue())

    def test_invalid_json(self):
        for data in [b'{', b'{"remote_plan_format":1}', b'{"format_version":"1.0","values":{}}']:
            result = self.invoke(data)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(result.stdout)
            self.assertIn(b"Unable to render JSON plan", result.stderr)

    def test_empty_and_output_only_plans(self):
        self.assertIn("0 resource entries", renderer.render_json_plan({
            "format_version": "1.2", "planned_values": {},
        }))
        self.assertIn("Planning failed", renderer.render_json_plan({
            "format_version": "1.2", "errored": True,
        }))

    def test_text_regression(self):
        sample = b'''2026-04-01T12:34:56.123Z Terraform will perform the following actions:
2026-04-01T12:34:56.123Z 
2026-04-01T12:34:56.123Z   # test.example will be created
2026-04-01T12:34:56.123Z   \x1b[32m+\x1b[0m resource "test" "example" {
2026-04-01T12:34:56.123Z       + nested = {
2026-04-01T12:34:56.123Z           + name = "<example>"
2026-04-01T12:34:56.123Z         }
2026-04-01T12:34:56.123Z     }
2026-04-01T12:34:56.123Z 
2026-04-01T12:34:56.123Z   # test.other must be replaced
2026-04-01T12:34:56.123Z -/+ resource "test" "other" {
2026-04-01T12:34:56.123Z       ~ name = "old" -> "new"
2026-04-01T12:34:56.123Z     }
2026-04-01T12:34:56.123Z 
2026-04-01T12:34:56.123Z Plan: 2 to add, 0 to change, 1 to destroy.
'''
        result = self.invoke(sample)
        self.assertEqual(result.returncode, 0, result.stderr)
        doc = result.stdout.decode()
        parser = ResourceParser()
        parser.feed(doc)
        self.assertEqual(parser.addresses, ["test.example", "test.other"])
        self.assertEqual(parser.depth, 0)
        self.assertNotIn("\x1b", doc)
        self.assertNotIn("2026-04-01T", doc)
        self.assertIn("&lt;example&gt;", doc)
        self.assertGreater(doc.index("Plan: 2 to add"), doc.rindex("</details>"))


if __name__ == "__main__":
    unittest.main()
