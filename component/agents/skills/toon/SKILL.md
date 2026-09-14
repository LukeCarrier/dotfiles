---
name: toon
description: Writing Token-Oriented Object Notation (TOON) files. Load when you need to produce or debug .toon output for structured data interchange between agents.
---

## When to use me

When writing `.toon` files for code-review findings, ADR artifacts, or any structured agent-to-agent data. TOON is the canonical format for multi-agent communication in this repo.

## Basics

TOON uses indentation (2 spaces) instead of braces, arrays declare length and optional field names up front, and strings are quoted only when necessary.

### Objects

```toon
key: value
nested:
  child: value
multiWordKey: value
```

### Primitive arrays (inline)

```toon
items[3]: apple,banana,cherry
```

### Tabular arrays (uniform objects)

```toon
items[2]{name,role}:
  Archie,Architecture
  Paige,Product
```

Field names are declared once in `{braces}`. Each row is comma-separated values in the same order. Tabular format is the most token-efficient.

### Nested tabular arrays (first field on the hyphen line)

```toon
review:
  findings[2]{id,severity}:
    F-001,critical
    F-002,high
```

## Quoting rules

Strings MUST be quoted when they contain:
- The active delimiter (comma inside tabular rows)
- A colon
- Leading or trailing whitespace
- Structural characters: `[`, `]`, `{`, `}`, `"`, `\`
- Equal to `true`, `false`, or `null` (case-sensitive)

Strings that look like numbers (e.g. `"42"`, `"-3.14"`) MUST be quoted.

Otherwise, strings should be unquoted to save tokens.

### Examples

```toon
items[2]{name,description}:
  archie,"Reviews structure, clarity, and convention"
  paige,"Evaluates completeness against the spec"
```

### Multiline strings

TOON has no block strings. A value that must contain newlines is a single-line quoted string using `\n` escapes. Do NOT continue the value onto further indented lines — each continuation line is parsed as a new key and decoding fails with `Missing colon after key`. Physical line breaks inside quotes are also rejected (`Unterminated string: missing closing quote`).

```toon
context: "First paragraph.\n\nSecond paragraph with a colon: here.\n{{mermaid: file.mmd}}"
```

The decoder restores `\n` escapes to real newlines, so the resulting JSON value is identical to what a block string would have produced.

## Validation

Always validate TOON output before writing:

```bash
toon --decode <file.toon> > /dev/null
```

For ADR documents, also validate against the JSON Schema to catch structure errors:

```bash
toon --decode spec.toon | check-jsonschema --schemafile ${FIXTURES_DIR}/spec.schema.json /dev/stdin
toon --decode plan.toon | check-jsonschema --schemafile ${FIXTURES_DIR}/plan.schema.json /dev/stdin
toon --decode tasks.toon | check-jsonschema --schemafile ${FIXTURES_DIR}/tasks.schema.json /dev/stdin
toon --decode retro.toon | check-jsonschema --schemafile ${FIXTURES_DIR}/retro.schema.json /dev/stdin
```

If decode fails, fix the syntax errors — see the table below.

## Counting rows and files

**Always count before you write.** The decoder rejects a mismatch between the declared length and the actual item count with `Expected N items, but got M`. Two traps:

- `filesChanged[N]` — count the comma-separated paths; they are easy to miscount when copied from a shell command.
- `findings[N]` — count the data rows only; the `agents[N]` block that follows is a separate array, not part of findings.

The safest approach: write the rows first, count them, then fill in the `[N]`.

## Commas inside quoted values

Quoting a value is necessary but not sufficient when the value contains commas. Even inside a quoted string, a bare comma is parsed as a column separator in a tabular row. Two rules:

1. Quote any value containing a comma.
2. Replace commas inside the quoted string with semicolons or reword to remove them.

```toon
# BAD — comma inside quoted value breaks column parsing
findings[1]{id,recommendation}:
  my-finding,"Add a test: runExecutor({environment:'dev'},ctx()) and assert"

# GOOD — comma removed by rewording
findings[1]{id,recommendation}:
  my-finding,"Add a test calling runExecutor with no deployableSha and assert a loud failure"
```

## Validate immediately

Run the decoder as soon as you write the file — before passing it to any report script or downstream tool:

```bash
toon --decode <file.toon> > /dev/null
```

The error message names the offending line and column. Fix the first error and re-run; errors cascade.

## Common mistakes

| Mistake | Fix |
|---------|-----|
| `key:value` (no space after colon) | `key: value` |
| `items[2]{a,b}: val1,val2,val3` (wrong field count) | Match row columns to `{fields}` count |
| `thing: value with , comma` (bare comma) | Quote: `"value with , comma"` |
| Comma inside a quoted tabular value | Replace with semicolon or reword |
| Declared length does not match row count | Count rows first; fill in `[N]` last |
| Value continued onto indented lines | Join into one quoted string with `\n` escapes |
| Mixed tab/space indentation | Use 2 spaces only |
| Trailing whitespace on lines | Strip it |
