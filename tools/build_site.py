# /// script
# requires-python = ">=3.11"
# ///
"""Build the GitHub Pages site: every talk as an HTML deck and a PDF, plus a profile page.

    python3 tools/build_site.py            # -> site/
    python3 -m http.server -d site          # to look at it

Each talk is a folder with a `main.typ`. Its figures are committed, because
most of them come from simulation data that lives outside this repo, so the
site build only runs Typst: it never regenerates a figure.

Add a talk by adding its folder to TALKS. The profile page also lists
PUBLICATIONS, CONFERENCE, POSTERS and SOFTWARE; they were pulled from ORCID (0000-0003-2427-8181),
OpenAlex and Zenodo (posters from Jake's own list), so add new entries here by
hand when those records grow.
"""

from __future__ import annotations

import argparse
import html
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# (folder, title, subtitle, year). Order is the order on the index page, newest first.
TALKS = [
    ("cybershake-nshm", "Cybershake NZ: towards simulations in the NSHM",
     "rupture selection, multi-segment ruptures, and the physics in between", 2026),
    ("reproducible-data", "Reproducible and usable scientific data at scale",
     "lessons from Cybershake and validation research", 2026),
    ("gmcm-modelling", "Towards 2+ Hz",
     "topography, variable mesh refinement and modular velocity models for "
     "physics-based ground motion simulation", 2026),
]

# Self, as the name appears in author lists; it is set in bold there.
ME = "J. Faulkner"

# Peer-reviewed papers. (authors, year, title, venue, [(link label, url)]). Newest first.
PUBLICATIONS = [
    (["B.A. Bradley", "J. Faulkner", "F. Kuncar", "C.A. Pajaro"], 2026,
     "Ground-motion simulation of multi-segment ruptures on the Alpine-Marlborough fault system",
     "Preprint, submitted to <i>Earthquake Spectra</i>",
     [("Preprint", "https://arxiv.org/abs/2610.33399")]),
    (["J. Faulkner", "G. Van de Voorde"], 2025,
     "On the equivalence, stabilisers, and feet of Buekenhout-Tits unitals",
     "<i>Designs, Codes and Cryptography</i> 93(2), 297&ndash;307",
     [("DOI", "https://doi.org/10.1007/s10623-023-01234-4"), ("Preprint", "https://arxiv.org/abs/2209.10863")]),
]

# Conference submissions, which are not peer-reviewed papers; same shape as PUBLICATIONS.
CONFERENCE = [
    (["M. Dupuis", "B.A. Bradley", "J. Faulkner", "R.L. Lee"], 2026,
     "Sensitivity to rupture characteristics of hybrid broadband ground-motion simulations "
     "for Mw8.7 rupture scenarios on the Hikurangi Subduction Zone",
     "13th U.S. National Conference on Earthquake Engineering, EERI, Portland, Oregon",
     [("PDF", "https://mrldupuis.github.io/assets/pdf/13NCEE-Dupuis-Hikurangi.pdf")]),
]

# (authors, year, title, venues). A poster shown at more than one meeting is one
# entry with a venue for each. Newest first.
SEPT_2025_SCEC = "SCEC Annual Meeting, Palm Springs, California, 7&ndash;10 September 2025"
SEPT_2025_QUAKECORE = "QuakeCoRE Annual Meeting, Dunedin, New Zealand, 1&ndash;4 September 2025"
# The 2026 meeting's published dates disagree (31 Aug-3 Sep vs 1-3 Sep), so only the year.
QUAKECORE_2026 = "QuakeCoRE Annual Meeting, Dunedin, New Zealand, 2026"
POSTERS = [
    (["J. Faulkner", "B.A. Bradley", "C. Pajaro", "F. Kuncar", "A. Ridden-Harper"], 2026,
     "Towards engineering-ready physics-based seismic hazard: the next iteration of Cybershake NZ",
     [QUAKECORE_2026]),
    (["B.A. Bradley", "J. Faulkner"], 2025,
     "Extending kinematic rupture generators to multi-segment geometries",
     [SEPT_2025_SCEC]),
    (["F. Kuncar", "B.A. Bradley", "R.L. Lee", "C. Pajaro", "M. Dupuis", "J. Faulkner", "S. Bae"], 2025,
     "Toward a unified database of hybrid broadband ground-motion simulations for historical "
     "Mw3.5&ndash;7.8 crustal and subduction earthquakes in New Zealand",
     [SEPT_2025_SCEC, SEPT_2025_QUAKECORE]),
    (["A. Ridden-Harper", "J. Faulkner", "J. Kim", "R.L. Lee", "B.A. Bradley"], 2025,
     "Large standardised dataset derived from NZGD investigation files",
     [SEPT_2025_QUAKECORE]),
    (["S. Bae", "A. Tiwari", "A. Ridden-Harper", "J. Faulkner", "B.A. Bradley"], 2025,
     "A collaborative, Python-based platform for the New Zealand Community Velocity Model",
     [SEPT_2025_QUAKECORE]),
]

# (authors, year, name, blurb, concept DOI covering every release, repository). Newest first.
SOFTWARE = [
    (["J. Faulkner", "B. Bradley", "C. Pajaro"], 2026, "rupture_generator",
     "Kinematic earthquake rupture generation.",
     "10.5281/zenodo.23384099", "https://github.com/ucgmsim/rupture_generator"),
    (["S. Bae", "J. Faulkner", "A. Ridden-Harper", "A. Tiwari", "J. Ridden", "C. Schill"], 2026,
     "velocity_modelling", "Builds 3D seismic velocity models from the NZ Community Velocity Model.",
     "10.5281/zenodo.19228320", "https://github.com/ucgmsim/velocity_modelling"),
    (["S. Bae", "J. Faulkner", "A. Ridden-Harper"], 2026, "nzcvm_data",
     "Data files for the New Zealand Community Velocity Model.",
     "10.5281/zenodo.19228329", "https://github.com/ucgmsim/nzcvm_data"),
    (["J. Ridden", "A. Ridden-Harper", "C. Schill", "J. Faulkner", "S. Bae"], 2026, "nzgmdb",
     "The New Zealand Ground Motion Database.",
     "10.5281/zenodo.22103991", "https://github.com/ucgmsim/nzgmdb"),
]

INDEX = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Jake Faulkner</title>
<meta name="description" content="Jake Faulkner, Research Software Engineer at the University of Canterbury: publications, posters, conference submissions, software and talks.">
<style>
  :root {{ --ink: #23373b; --accent: #eb811b; --quiet: #6b7174; --paper: #fafafa; --rule: #e3e4e5;
          --band: #23373b; --band-ink: #fff; }}
  @media (prefers-color-scheme: dark) {{
    :root {{ --ink: #e6e8e9; --accent: #f29a45; --quiet: #a2a8ab; --paper: #161c1e; --rule: #2e3739;
            --band: #0f1416; --band-ink: #fff; }}
  }}
  body {{ margin: 0; background: var(--paper); color: var(--ink);
         font: 18px/1.55 "Libertinus Serif", Georgia, serif; }}
  header {{ background: var(--band); color: var(--band-ink); padding: 40px 16px 32px;
           border-bottom: 4px solid var(--accent); }}
  header > div, main {{ max-width: 760px; margin: 0 auto; }}
  header h1 {{ margin: 0; font-weight: normal; font-size: 36px; letter-spacing: .01em; }}
  .role {{ margin: 4px 0 14px; opacity: .85; }}
  header nav a {{ color: var(--band-ink); font-weight: normal; border-bottom: 1px solid var(--accent); }}
  header nav a:hover {{ text-decoration: none; color: var(--accent); }}
  main {{ padding: 8px 16px 56px; }}
  section {{ margin-top: 36px; }}
  h2 {{ margin: 0 0 6px; font-size: 14px; font-weight: bold; letter-spacing: .14em;
       text-transform: uppercase; color: var(--accent); }}
  .about {{ margin: 0; }}
  ol {{ list-style: none; margin: 0; padding: 0; }}
  li {{ border-bottom: 1px solid var(--rule); padding: 16px 0; display: grid;
       grid-template-columns: 3.2em 1fr; column-gap: 12px; }}
  li:last-child {{ border-bottom: 0; }}
  .year {{ color: var(--quiet); font-variant-numeric: tabular-nums; }}
  h3 {{ margin: 0 0 2px; font-size: 19px; font-weight: bold; line-height: 1.35; }}
  .meta {{ margin: 0 0 6px; color: var(--quiet); }}
  .meta b {{ color: var(--ink); }}
  .venue {{ margin: 0; color: var(--quiet); font-style: italic; }}
  .sub {{ margin: 0 0 6px; color: var(--quiet); font-style: italic; }}
  code {{ font: 16px/1 ui-monospace, "SFMono-Regular", Menlo, monospace; }}
  a {{ color: var(--accent); text-decoration: none; font-weight: bold; margin-right: 18px; }}
  a:hover {{ text-decoration: underline; }}
  footer {{ max-width: 760px; margin: 0 auto; padding: 0 16px 40px; color: var(--quiet); font-size: 15px; }}
  @media (max-width: 520px) {{
    header h1 {{ font-size: 30px; }}
    li {{ grid-template-columns: 1fr; }}
  }}
</style>
</head>
<body>
<header><div>
<h1>Jake Faulkner</h1>
<p class="role">Research Software Engineer &middot; University of Canterbury &middot; QuakeCoRE</p>
<nav><a href="https://orcid.org/0000-0003-2427-8181">ORCID</a><a href="https://github.com/lispandfound">GitHub</a></nav>
</div></header>
<main>
<section>
<h2>About</h2>
<p class="about">I build research software for physics-based earthquake ground-motion simulation in
New Zealand: rupture generation, seismic velocity models, and the Cybershake NZ simulations that feed
seismic hazard analysis. I came to this from pure mathematics, where my work was in finite geometry.</p>
</section>
<section>
<h2>Publications</h2>
<ol>
{publications}
</ol>
</section>
<section>
<h2>Posters</h2>
<ol>
{posters}
</ol>
</section>
<section>
<h2>Conference submissions</h2>
<ol>
{conference}
</ol>
</section>
<section>
<h2>Software</h2>
<ol>
{software}
</ol>
</section>
<section>
<h2>Talks</h2>
<ol>
{talks}
</ol>
</section>
</main>
<footer>Software citations point at Zenodo concept DOIs, which resolve to the newest release.</footer>
</body>
</html>
"""


def authors(names: list[str]) -> str:
    """An author list with self in bold, each name kept on one line."""
    names_html = [html.escape(n).replace(" ", "&nbsp;") for n in names]
    return ", ".join(f"<b>{h}</b>" if n == ME else h for n, h in zip(names, names_html))


def entry(year: str, body: str) -> str:
    return f'<li><span class="year">{year}</span><div>{body}</div></li>'


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
    talks = []
    for folder, title, subtitle, year in TALKS:
        build(folder, title, args.out)
        talks.append(entry(str(year), (
            f'<h3>{html.escape(title)}</h3><p class="sub">{html.escape(subtitle)}</p>'
            f'<a href="{folder}/">Slides</a><a href="{folder}/{folder}.pdf">PDF</a>'
        )))
    publications, conference = ([
        entry(str(year), (
            f'<h3>{html.escape(title)}</h3><p class="meta">{authors(names)}. {venue}.</p>'
            + "".join(f'<a href="{url}">{label}</a>' for label, url in links)
        ))
        for names, year, title, venue, links in papers
    ] for papers in (PUBLICATIONS, CONFERENCE))
    # Titles here carry entities (Mw3.5&ndash;7.8), so they are written as HTML.
    posters = [
        entry(str(year), (
            f'<h3>{title}</h3><p class="meta">{authors(names)}.</p>'
            + "".join(f'<p class="venue">{v}</p>' for v in venues)
        ))
        for names, year, title, venues in POSTERS
    ]
    software = [
        entry(str(year), (
            f'<h3><code>{html.escape(name)}</code></h3><p class="sub">{html.escape(blurb)}</p>'
            f'<p class="meta">{authors(names)}.</p>'
            f'<a href="https://doi.org/{doi}">Zenodo</a><a href="{repo}">Source</a>'
        ))
        for names, year, name, blurb, doi, repo in SOFTWARE
    ]
    (args.out / "index.html").write_text(INDEX.format(
        publications="\n".join(publications), posters="\n".join(posters), conference="\n".join(conference), software="\n".join(software), talks="\n".join(talks)))
    # Pages must not run the site through Jekyll, which drops underscored paths.
    (args.out / ".nojekyll").touch()
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
