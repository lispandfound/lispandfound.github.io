# /// script
# requires-python = ">=3.11"
# ///
"""Build an HTML slide deck from a Typst (touying) deck, with any video live.

Typst cannot put a playable video in a PDF. A browser can, so this renders every
Typst page to SVG and wraps them in one self-contained page: a folder that
opens from disk in any browser, with no server and nothing fetched from the
network, so it can go on a USB stick.

A deck asks for a video by placing `<video>` metadata on the slide -- the
video and poster paths (relative to the deck), and the poster's position and
size on the page; see cybershake-nshm/main.typ. The video is laid exactly over
the poster, starts when the slide is shown and rewinds when you leave it.

Keys, in the deck:
    → ↓ space PgDn, click     next slide
    ← ↑ PgUp                  previous slide
    Home / End                first / last
    f                         fullscreen
    s                         speaker view (notes, next slide, timer) in a new window
    p                         play / pause the video

Speaker notes are lifted from ``main.typ`` rather than duplicated here, in
either convention the decks in this repo use: a ``// SAY:`` comment block above
a ``== Title``, or a ``#say[...]`` block under it.

Run, from a talk's folder:
    uv run ../tools/make_html.py --title "Talk title"   # -> out/html/index.html
"""

from __future__ import annotations

import argparse
import html
import json
import re
import shutil
import subprocess
from pathlib import Path



def typst_eval(root: Path, expression: str):
    out = subprocess.run(
        ["typst", "eval", expression, "--in", "main.typ", "--format", "json"],
        cwd=root, check=True, capture_output=True, text=True,
    )
    return json.loads(out.stdout)


def headings_in_source(path: Path, level: int | None = None) -> list[str]:
    """Slide titles in order, from the `= ` and `== ` lines of the deck."""
    return [m.group(2).strip() for line in path.read_text().splitlines()
            if (m := re.match(r"^(={1,2}) (.+)$", line)) and level in (None, len(m.group(1)))]


def notes_from_typst(path: Path) -> dict[str, str]:
    """Map slide title -> speaker notes.

    Two conventions: a run of ``//`` comment lines from a ``// SAY:`` (any
    line of the run may repeat the ``SAY:``) immediately above a ``== Title``;
    or a ``#say[`` block after a ``== Title``, closed by a line that is just
    ``]``.
    """
    notes: dict[str, str] = {}
    block: list[str] = []
    title = None
    lines = iter(path.read_text().splitlines())
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("//"):
            block.append(stripped[2:].strip())
            continue
        if stripped.startswith("== "):
            title = stripped[3:].strip()
            # The block starts at its first `SAY:`, so a rule or other comment
            # above it (`// ----`) is not read as notes.
            start = next((i for i, b in enumerate(block) if b.startswith("SAY:")), None)
            if start is not None:
                body = " ".join(re.sub(r"^SAY:\s*", "", b) for b in block[start:])
                notes[title] = re.sub(r"\s+", " ", body).strip()
        elif stripped.startswith("#say[") and title is not None:
            body = [stripped[5:]]
            for inner in lines:
                if inner.strip() == "]":
                    break
                body.append(inner.strip())
            notes[title] = re.sub(r"\s+", " ", " ".join(body)).strip()
        block = []
    return notes


PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<style>
  html, body {{ margin: 0; height: 100%; background: #000; overflow: hidden; }}
  #stage {{ position: absolute; left: 50%; top: 50%; transform: translate(-50%, -50%);
            width: min(100vw, calc(100vh * {aspect})); aspect-ratio: {aspect}; background: #fff; }}
  .slide {{ position: absolute; inset: 0; display: none; }}
  .slide.active {{ display: block; }}
  .slide > img {{ width: 100%; height: 100%; display: block; }}
  .slide > video {{ position: absolute; background: #000; }}
  body.cursor-hidden {{ cursor: none; }}
</style>
</head>
<body>
<div id="stage">
{slides}
</div>
<script>
const NOTES = {notes};
const TITLES = {titles};
const slides = [...document.querySelectorAll('.slide')];
let current = 0;
const channel = new BroadcastChannel('deck-{key}');

function show(n, broadcast = true) {{
  n = Math.max(0, Math.min(slides.length - 1, n));
  slides[current].querySelectorAll('video').forEach(v => {{ v.pause(); v.currentTime = 0; }});
  slides[current].classList.remove('active');
  current = n;
  slides[current].classList.add('active');
  slides[current].querySelectorAll('video').forEach(v => v.play().catch(() => {{}}));
  history.replaceState(null, '', '#' + (current + 1));
  if (broadcast) channel.postMessage({{ slide: current }});
}}
channel.onmessage = e => {{ if (e.data.slide !== undefined && e.data.slide !== current) show(e.data.slide, false); }};

document.addEventListener('keydown', e => {{
  const k = e.key;
  if (['ArrowRight', 'ArrowDown', ' ', 'PageDown'].includes(k)) {{ show(current + 1); e.preventDefault(); }}
  else if (['ArrowLeft', 'ArrowUp', 'PageUp'].includes(k)) {{ show(current - 1); e.preventDefault(); }}
  else if (k === 'Home') show(0);
  else if (k === 'End') show(slides.length - 1);
  else if (k === 'f') document.fullscreenElement ? document.exitFullscreen() : document.documentElement.requestFullscreen();
  else if (k === 'p') slides[current].querySelectorAll('video').forEach(v => v.paused ? v.play() : v.pause());
  else if (k === 's') openSpeaker();
}});
document.getElementById('stage').addEventListener('click', e => {{
  if (e.target.tagName !== 'VIDEO') show(current + 1);
}});

// Hide the cursor when it is idle, so it is not left over a figure.
let idle;
document.addEventListener('mousemove', () => {{
  document.body.classList.remove('cursor-hidden');
  clearTimeout(idle);
  idle = setTimeout(() => document.body.classList.add('cursor-hidden'), 2000);
}});

function openSpeaker() {{
  const w = window.open('', 'speaker-{key}', 'width=1100,height=700');
  if (!w) return;
  const imgs = slides.map(s => s.querySelector('img').getAttribute('src'));
  w.document.write(`<!doctype html><meta charset="utf-8"><title>Speaker view</title>
  <style>
    body {{ margin: 0; font: 18px/1.45 system-ui, sans-serif; background: #1d2427; color: #eee;
           display: grid; grid-template-columns: 1.4fr 1fr; grid-template-rows: auto 1fr; gap: 14px;
           padding: 14px; box-sizing: border-box; height: 100vh; }}
    img {{ width: 100%; background: #fff; display: block; }}
    #bar {{ grid-column: 1 / 3; display: flex; justify-content: space-between; font-size: 22px; }}
    #notes {{ overflow-y: auto; font-size: 21px; padding-right: 8px; }}
    #next-label {{ color: #9aa; font-size: 14px; margin: 0 0 4px; }}
    button {{ font: inherit; background: #34434a; color: #eee; border: 0; padding: 2px 12px; }}
  </style>
  <div id="bar"><span id="count"></span><span><span id="clock">0:00</span> <button id="reset">reset</button></span></div>
  <div><img id="now"><p id="notes"></p></div>
  <div><p id="next-label">next</p><img id="next"></div>`);
  w.document.close();
  const base = document.baseURI;
  const abs = s => new URL(s, base).href;
  const render = n => {{
    w.document.getElementById('now').src = abs(imgs[n]);
    w.document.getElementById('next').src = n + 1 < imgs.length ? abs(imgs[n + 1]) : '';
    w.document.getElementById('notes').textContent = NOTES[n] || '';
    w.document.getElementById('count').textContent = `${{n + 1}} / ${{imgs.length}}  ${{TITLES[n] || ''}}`;
  }};
  render(current);
  const ch = new BroadcastChannel('deck-{key}');
  ch.onmessage = e => {{ if (e.data.slide !== undefined) render(e.data.slide); }};
  // The speaker window drives the deck too.
  w.document.addEventListener('keydown', e => {{
    const k = e.key;
    let n = null;
    if (['ArrowRight', 'ArrowDown', ' ', 'PageDown'].includes(k)) n = current + 1;
    else if (['ArrowLeft', 'ArrowUp', 'PageUp'].includes(k)) n = current - 1;
    if (n !== null) {{ show(n); render(current); e.preventDefault(); }}
  }});
  let start = Date.now();
  w.document.getElementById('reset').onclick = () => {{ start = Date.now(); }};
  w.setInterval(() => {{
    const s = Math.floor((Date.now() - start) / 1000);
    w.document.getElementById('clock').textContent = `${{Math.floor(s / 60)}}:${{String(s % 60).padStart(2, '0')}}`;
  }}, 500);
}}

show(Math.max(0, (parseInt(location.hash.slice(1)) || 1) - 1), false);
</script>
</body>
</html>
"""


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", type=Path, default=Path.cwd(), help="the talk's folder (default: here)")
    ap.add_argument("--title", default="Slides", help="browser tab title")
    ap.add_argument("--out", type=Path, default=None, help="output folder (default out/html)")
    args = ap.parse_args()

    root = args.root
    out = args.out or root / "out" / "html"
    pages_dir = out / "slides"
    if pages_dir.exists():
        shutil.rmtree(pages_dir)
    pages_dir.mkdir(parents=True)
    subprocess.run(["typst", "compile", "main.typ", str(pages_dir / "slide-{0p}.svg"), "--format", "svg"],
                   cwd=root, check=True)
    pages = sorted(pages_dir.glob("slide-*.svg"))

    titles = headings_in_source(root / "main.typ")
    placed = typst_eval(root, "query(heading).map(it => it.location().page())")
    if len(titles) != len(placed):
        raise SystemExit(f"{len(titles)} headings in main.typ but Typst placed {len(placed)}")
    title_of = dict(zip(placed, titles))
    notes = notes_from_typst(root / "main.typ")
    content_titles = set(headings_in_source(root / "main.typ", level=2))
    videos = typst_eval(root, "query(<video>).map(it => (page: it.location().page(), ..it.value))")
    for v in videos:
        shutil.copy2(root / v["src"], out / Path(v["src"]).name)
        shutil.copy2(root / v["poster"], out / Path(v["poster"]).name)

    blocks, slide_notes, slide_titles, missing = [], [], [], []
    for number, svg in enumerate(pages, start=1):
        title = title_of.get(number)
        slide_titles.append(title or "")
        slide_notes.append(notes.get(title, ""))
        if title in content_titles and title not in notes:
            missing.append(title)
        parts = [f'<img src="slides/{svg.name}" alt="{html.escape(title or "title slide")}">']
        for v in (v for v in videos if v["page"] == number):
            # Percentages of the page, so the video tracks the slide at any size.
            style = (f"left:{100 * v['x'] / v['page-width']:.4f}%;top:{100 * v['y'] / v['page-height']:.4f}%;"
                     f"width:{100 * v['width'] / v['page-width']:.4f}%;"
                     f"height:{100 * v['height'] / v['page-height']:.4f}%")
            parts.append(f'<video src="{Path(v["src"]).name}" poster="{Path(v["poster"]).name}" style="{style}" muted playsinline '
                         f'preload="auto"></video>')
        blocks.append(f'<section class="slide">{"".join(parts)}</section>')

    (out / "index.html").write_text(PAGE.format(
        title=html.escape(args.title),
        aspect="16 / 9",  # metropolis-theme aspect-ratio in main.typ
        slides="\n".join(blocks),
        notes=json.dumps(slide_notes),
        titles=json.dumps(slide_titles),
        key=root.name,
    ))
    if missing:
        print("these slides have no `// SAY:` block, so they ship without notes:\n  " + "\n  ".join(missing))
    size = sum(f.stat().st_size for f in out.rglob("*") if f.is_file()) / 1e6
    print(f"wrote {out / 'index.html'}  ({len(pages)} slides, {len(videos)} video, {size:.0f} MB)")


if __name__ == "__main__":
    main()
