#!/usr/bin/env node
import wireloom from "wireloom";
import { createServer } from "node:http";
import { readFile, writeFile, mkdir } from "node:fs/promises";
import { extname, join, resolve, basename } from "node:path";
import { existsSync } from "node:fs";

const usage = `wireloom-render — render Wireloom sources into a navigable prototype

Usage:
  wireloom-render [options] <screen.wireloom> [<screen.wireloom> ...]

Options:
  -o, --out <dir>     Output directory (default: ./dist)
      --theme <name>  "default" or "dark" (default: default)
      --serve [port]  Serve the output over HTTP (default port: 4173)
      --no-index      Skip generating the index.html viewer
  -h, --help          Show this help

Each input renders to <name>.svg. With multiple inputs, an index.html
viewer is generated with tab and keyboard navigation between screens.`;

const args = process.argv.slice(2);
if (args.length === 0 || args.includes("-h") || args.includes("--help")) {
  console.log(usage);
  process.exit(args.includes("-h") || args.includes("--help") ? 0 : 1);
}

let outDir = "dist";
let theme = "default";
let wantIndex = true;
let servePort = null;
const inputs = [];

for (let i = 0; i < args.length; i++) {
  const a = args[i];
  if (a === "-o" || a === "--out") outDir = args[++i];
  else if (a === "--theme") theme = args[++i];
  else if (a === "--serve") {
    const next = args[i + 1];
    servePort = /^\d+$/.test(next ?? "") ? Number(args[++i]) : 4173;
  } else if (a === "--no-index") wantIndex = false;
  else if (a.startsWith("-")) {
    console.error(`wireloom-render: unknown option "${a}"`);
    process.exit(1);
  } else inputs.push(a);
}

if (!["default", "dark"].includes(theme)) {
  console.error(`wireloom-render: unknown theme "${theme}"`);
  process.exit(1);
}
wireloom.initialize({ theme });

const slug = (name) =>
  name.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");

const screens = [];
for (const input of inputs) {
  const name = basename(input, extname(input));
  let source;
  try {
    source = await readFile(input, "utf8");
  } catch (err) {
    console.error(`wireloom-render: cannot read ${input}: ${err.message}`);
    process.exit(1);
  }
  try {
    const doc = wireloom.parse(source);
    const title = doc.root?.title || name;
    const { svg } = await wireloom.render(slug(name), source);
    screens.push({ slug: slug(name), title, svg });
  } catch (err) {
    if (err instanceof wireloom.WireloomError) {
      console.error(`${input}:${err.line}:${err.column}: ${err.message}`);
    } else {
      console.error(`${input}: ${err.message}`);
    }
    process.exit(1);
  }
}

await mkdir(outDir, { recursive: true });
for (const s of screens) {
  await writeFile(join(outDir, `${s.slug}.svg`), s.svg + "\n");
  console.log(`✓ ${join(outDir, `${s.slug}.svg`)}`);
}

function viewer(screens) {
  const esc = (s) =>
    s.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll('"', "&quot;");
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Wireloom prototype</title>
<style>
  body { margin: 0; font-family: system-ui, sans-serif; background: #f4f4f5; color: #18181b; }
  header { display: flex; align-items: center; gap: 0.5rem; padding: 0.5rem 1rem;
           border-bottom: 1px solid #d4d4d8; background: #fff; position: sticky; top: 0; }
  header nav { display: flex; gap: 0.25rem; flex-wrap: wrap; }
  header a { padding: 0.3rem 0.75rem; border-radius: 6px; text-decoration: none;
             color: inherit; font-size: 0.85rem; border: 1px solid transparent; }
  header a.active { background: #e4e4e7; border-color: #d4d4d8; font-weight: 600; }
  main { display: grid; place-items: start center; padding: 2rem 1rem; }
  main > div { background: #fff; border-radius: 10px; box-shadow: 0 1px 4px #0002;
               max-width: 100%; overflow-x: auto; }
  main svg { display: block; height: auto; }
</style>
</head>
<body>
<header>
  <nav>${screens.map((s, i) => `<a href="#${s.slug}" data-i="${i}">${esc(s.title)}</a>`).join("")}</nav>
</header>
<main id="stage"></main>
<script>
const screens = ${JSON.stringify(screens.map((s) => s.slug))};
const stage = document.getElementById("stage");
const svgs = {};
${screens.map((s) => `svgs[${JSON.stringify(s.slug)}] = ${JSON.stringify(s.svg)};`).join("\n")}
function show(slug) {
  const i = Math.max(0, screens.indexOf(slug));
  const s = screens[i];
  stage.innerHTML = "<div>" + svgs[s] + "</div>";
  document.querySelectorAll("header a").forEach((a) =>
    a.classList.toggle("active", a.getAttribute("href") === "#" + s));
  history.replaceState(null, "", "#" + s);
}
addEventListener("hashchange", () => show(location.hash.slice(1)));
addEventListener("keydown", (e) => {
  const i = Math.max(0, screens.indexOf(location.hash.slice(1)));
  if (e.key === "ArrowRight") location.hash = screens[Math.min(i + 1, screens.length - 1)];
  if (e.key === "ArrowLeft") location.hash = screens[Math.max(i - 1, 0)];
});
show(location.hash.slice(1) || screens[0]);
</script>
</body>
</html>`;
}

if (wantIndex && screens.length > 1) {
  await writeFile(join(outDir, "index.html"), viewer(screens) + "\n");
  console.log(`✓ ${join(outDir, "index.html")} (${screens.length} screens)`);
}

if (servePort !== null) {
  const root = resolve(outDir);
  const types = { ".html": "text/html", ".svg": "image/svg+xml" };
  createServer(async (req, res) => {
    const rel =
      req.url === "/" && existsSync(join(root, "index.html"))
        ? "index.html"
        : decodeURIComponent(req.url.slice(1));
    try {
      const data = await readFile(join(root, rel));
      res.writeHead(200, { "content-type": types[extname(rel)] ?? "text/plain" });
      res.end(data);
    } catch {
      res.writeHead(404);
      res.end("not found");
    }
  }).listen(servePort, () => {
    console.log(`serving ${root} at http://localhost:${servePort}`);
  });
}
