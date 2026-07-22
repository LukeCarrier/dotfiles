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

If decode fails, fix the syntax errors. Common mistakes:
- Missing comma in tabular row
- Unquoted string containing comma
- Wrong number of fields in a tabular row
- Extra whitespace after a value
- Indentation inconsistency (mixing spaces/tabs)

## Common mistakes

| Mistake | Fix |
|---------|-----|
| `key:value` (no space after colon) | `key: value` |
| `items[2]{a,b}: val1,val2,val3` (wrong field count) | Match row columns to `{fields}` count |
| `thing: value with , comma` (bare comma) | Quote: `"value with , comma"` |
| Mixed tab/space indentation | Use 2 spaces only |
| Trailing whitespace on lines | Strip it |
