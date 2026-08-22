---
name: wireframing
description: Wireframing and UI mockups — produce interactive, navigable prototypes from compact text sources. Load when asked to mock up, wireframe, sketch, prototype, or plan the layout of any screen, dialog, or app flow, or when a wireframe fails to render.
---

## When to use me

When a request concerns the **shape of a user interface** that isn't already running code: "mock up a sign-in dialog", "sketch the settings page", "what would this dashboard look like?", "plan the screens for this feature". Also when an ADR or spec needs screens visualised.

Reach for a wireframe whenever you catch yourself describing layout in prose ("there's a title bar with a search box…"). The reader sees a picture instead of imagining one. Boundaries: Mermaid for flow/sequence/ER diagrams; real components for working software. Wireframes here are static structural mockups — never generate HTML for them.

## How it works

Wireframes are authored as `.wireloom` files — a small indentation-based DSL (one `window` root per screen) — and rendered by `wireloom-render` into self-contained SVG with a navigable viewer. Agents author the compact source; the tool owns all markup.

## Workflow

1. Write each screen as its own `.wireloom` file.
2. Render and validate before claiming done:

   ```bash
   wireloom-render login.wireloom dashboard.wireloom -o dist
   ```

   Zero parse errors is the completion criterion. Every input produces `<slug>.svg`; multiple inputs also produce `dist/index.html`, a self-contained clickable viewer with tab and arrow-key navigation between screens.
3. For live preview add `--serve` (default port 4173). Theme: `--theme dark`.
4. To place a wireframe in ADR artifacts, reference it from the markdown source and rebuild:

   ```
   {{wireloom: screens/login.wireloom}}
   ```

   `build.sh` renders it to `<slug>.svg` beside the document and inlines it as an image.

## Grammar essentials

Indentation-based, one node per line:

```
name "Positional" attr="value" flag:
  children indented 2 spaces
```

- Indent 2 **or** 4 spaces per level, consistently; tabs are errors.
- Leaves take positional strings before attributes and never have children (no trailing `:`).
- Strings are double-quoted; identifiers (`type=password`) and flags (`primary`) are bare.
- Exactly one `window` root; `annotation` nodes may follow it as siblings.

Minimum viable:

```wireloom
window "Sign in":
  header:
    text "Welcome back"
  panel:
    input placeholder="Email" type=email
    input placeholder="Password" type=password
    row align=right:
      button "Forgot?" id="forgot"
      button "Sign in" primary id="signin"

annotation "Primary action.\nDisabled until valid." target="signin" position=right
```

Core primitives:

| Group | Primitives |
|-------|------------|
| Chrome | `window`, `header` (+ `large`), `footer`, `navbar` (`leading:`/`center:`/`trailing:`), `tabbar` |
| Containers | `panel`, `section "T"`, `tabs`>`tab`, `row` (`align=`, `justify=`, `spacer`), `col [fill|N]`, `list`>(`item`\|`slot`), `grid cols=N rows=M`>`cell`, `sheet position=\|title=` |
| Leaves | `text`, `button`, `input`, `combo`, `slider range=N-M value=K`, `kv "L" "V"`, `image label= w= h=`, `icon name=`, `divider` |
| Widgets | `checkbox`, `radio`, `toggle`, `tree`>`node`, `menubar`>`menu`>`menuitem`, `breadcrumb`>`crumb`, `chip`, `avatar`, `spinner`, `status` |
| Game UI | `resourcebar`>`resource`, `stats`>`stat`, `progress value= max=`, `chart kind=` |

Key attributes: `bold`/`italic`/`muted`, `size=small|regular|large`, `badge="…"`, `active`, `disabled`, `accent=<name>`, `state=<name>`, `chevron` (tap-for-detail rows on `slot`/`item`). `navbar` and `header` are mutually exclusive; so are `tabbar` and `footer`. At most one `sheet` per window; exactly one `segment selected` per `segmented`.

Annotations attach a callout box plus leader line to any element carrying `id="…"`. Use them when asked for mockups "with callouts/annotations/labels". `\n` breaks lines inside annotation bodies.

## Common errors

| Error | Fix |
|-------|-----|
| tab in indentation | Spaces only, consistent unit |
| `"kv" needs two separate strings` | `kv "Label" "Value"` — split on the space, not `=` |
| `"text" cannot have children` | Drop the trailing `:` from leaf primitives |
| unknown primitive / attribute | Check the full tables in `${FIXTURES_DIR}/grammar.md`; error text lists valid options |
| navbar/header, tabbar/footer clash | One chrome band each — pick one |
| indentation not a multiple of unit | Re-indent the whole file at one unit |

Parse errors report `file:line:col` — fix top-down; indentation errors cascade.

## Limits

Static SVG per screen. The generated viewer gives click-through navigation *between* screens; there is no in-screen interactivity, animation, custom hex colour, nested window, or real chart data. Say so rather than promising behaviour.

Full grammar — every primitive, attribute, mobile navigation pattern, icon name, and the complete error table — is vendored at `${FIXTURES_DIR}/grammar.md`. Read it when composing unusual screens or interpreting unfamiliar errors.
