# /// script
# requires-python = ">=3.11"
# ///
"""Build the GitHub Pages site: every talk as an HTML deck and a PDF, plus an index.

    python3 tools/build_site.py            # -> site/
    python3 -m http.server -d site          # to look at it

Each talk is a folder with a `main.typ`. Its figures are committed, because
most of them come from simulation data that lives outside this repo, so the
site build only runs Typst: it never regenerates a figure.

Add a talk by adding its folder to TALKS.
"""

from __future__ import annotations

import argparse
import html
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# (folder, title, subtitle). Order is the order on the index page, newest first.
TALKS = [
    ("cybershake-nshm", "Cybershake NZ: towards simulations in the NSHM",
     "rupture selection, multi-segment ruptures, and the physics in between"),
    ("reproducible-data", "Reproducible and usable scientific data at scale",
     "lessons from Cybershake and validation research"),
    ("gmcm-modelling", "Towards 2+ Hz",
     "topography, variable mesh refinement and modular velocity models for "
     "physics-based ground motion simulation"),
]

INDEX = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Presentations</title>
<style>
  :root {{ --ink: #23373b; --accent: #eb811b; --quiet: #6b7174; --paper: #fafafa; --rule: #e3e4e5; }}
  body {{ margin: 0; background: var(--paper); color: var(--ink);
         font: 18px/1.5 "Libertinus Serif", Georgia, serif; }}
  header {{ background: var(--ink); color: #fff; padding: 28px 16px; }}
  header h1 {{ margin: 0 auto; max-width: 760px; font-weight: normal; font-size: 30px; }}
  main {{ max-width: 760px; margin: 0 auto; padding: 8px 16px 48px; }}
  article {{ border-bottom: 1px solid var(--rule); padding: 22px 0; }}
  h2 {{ margin: 0 0 4px; font-size: 22px; }}
  p {{ margin: 0 0 10px; color: var(--quiet); font-style: italic; }}
  a {{ color: var(--accent); text-decoration: none; font-weight: bold; margin-right: 18px; }}
  a:hover {{ text-decoration: underline; }}
</style>
</head>
<body>
<header><h1>Presentations</h1></header>
<main>
{talks}
</main>
</body>
</html>
"""


def build(folder: str, title: str, out: Path) -> None:
    talk = ROOT / folder
    target = out / folder
    target.mkdir(parents=True)
    subprocess.run(["typst", "compile", "main.typ", str(target / f"{folder}.pdf")], cwd=talk, check=True)
    subprocess.run([sys.executable, "-I", str(ROOT / "tools" / "make_html.py"), "--root", str(talk),
                    "--title", title, "--out", str(target)], check=True)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", type=Path, default=ROOT / "site")
    args = ap.parse_args()

    if args.out.exists():
        shutil.rmtree(args.out)
    args.out.mkdir(parents=True)
    entries = []
    for folder, title, subtitle in TALKS:
        build(folder, title, args.out)
        entries.append(
            f'<article><h2>{html.escape(title)}</h2><p>{html.escape(subtitle)}</p>'
            f'<a href="{folder}/">Slides</a><a href="{folder}/{folder}.pdf">PDF</a></article>'
        )
    (args.out / "index.html").write_text(INDEX.format(talks="\n".join(entries)))
    # Pages must not run the site through Jekyll, which drops underscored paths.
    (args.out / ".nojekyll").touch()
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
