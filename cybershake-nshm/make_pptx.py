# /// script
# requires-python = ">=3.11"
# dependencies = ["python-pptx"]
# ///
"""Build the .pptx from the Typst deck, with the Marlborough video embedded.

Typst cannot put a playable video in a PDF, and a conference laptop will most
likely be running PowerPoint, so this is the deck to present from. Each slide is
the Typst page rendered as a full-bleed picture: the Typst deck stays the one
design source, and the two cannot drift apart the way a hand-built layout here
did. The cost is that slide text is not editable in PowerPoint -- edit main.typ
and rerun.

The one slide that is more than a picture is the Marlborough slide: the movie
is laid exactly over the poster frame, from the position and size the deck
records in its `<video>` metadata, with that same frame as the poster
PowerPoint shows before playback.

Speaker notes are lifted from the ``// SAY:`` comment blocks in ``main.typ``
rather than duplicated here, so the two decks cannot disagree about what is
being said over a slide.

Run (after `typst compile main.typ`, so the figures it embeds exist):
    uv run make_pptx.py
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path

from pptx import Presentation
from pptx.util import Emu, Inches

SLIDE_W, SLIDE_H = 13.333, 7.5  # inches, 16:9
PPI = 250  # slide render resolution: 3333 px across, sharp on a 4K projector



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
    """Map slide title -> speaker notes, from ``// SAY:`` blocks in the deck.

    A block is a run of consecutive ``//`` comment lines whose first line begins
    ``// SAY:`` and which is immediately followed by a ``== Title`` heading.
    """
    notes: dict[str, str] = {}
    block: list[str] = []
    for line in path.read_text().splitlines():
        stripped = line.strip()
        if stripped.startswith("//"):
            block.append(stripped[2:].strip())
            continue
        if stripped.startswith("== ") and block and block[0].startswith("SAY:"):
            title = stripped[3:].strip()
            body = " ".join([block[0][4:].strip(), *block[1:]])
            notes[title] = re.sub(r"\s+", " ", body).strip()
        block = []
    return notes


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", type=Path, default=Path(__file__).parent)
    ap.add_argument("--out", type=Path, default=None)
    args = ap.parse_args()

    root = args.root
    out = args.out or root / "out" / "cybershake-talk.pptx"
    renders = root / "out" / "pptx"
    renders.mkdir(parents=True, exist_ok=True)
    for old in renders.glob("slide-*.png"):
        old.unlink()
    subprocess.run(["typst", "compile", "main.typ", str(renders / "slide-{0p}.png"), "--format", "png",
                    "--ppi", str(PPI)], cwd=root, check=True)
    pages = sorted(renders.glob("slide-*.png"))

    # Title for each page: headings in source order, paired with the page
    # Typst put each one on. The title slide has no heading.
    titles = headings_in_source(root / "main.typ")
    placed = typst_eval(root, "query(heading).map(it => it.location().page())")
    if len(titles) != len(placed):
        raise SystemExit(f"{len(titles)} headings in main.typ but Typst placed {len(placed)}")
    title_of = dict(zip(placed, titles))
    notes = notes_from_typst(root / "main.typ")
    content_titles = {t for t in headings_in_source(root / "main.typ", level=2)}
    video = typst_eval(root, "query(<video>).map(it => (page: it.location().page(), ..it.value))")

    prs = Presentation()
    prs.slide_width = Inches(SLIDE_W)
    prs.slide_height = Inches(SLIDE_H)
    missing = []
    for number, png in enumerate(pages, start=1):
        slide = prs.slides.add_slide(prs.slide_layouts[6])  # blank
        slide.shapes.add_picture(str(png), 0, 0, prs.slide_width, prs.slide_height)
        title = title_of.get(number)
        if title in notes:
            slide.notes_slide.notes_text_frame.text = notes[title]
        elif title in content_titles:  # section slides (`= `) carry no notes by design
            missing.append(title)

        for v in video:
            if v["page"] != number:
                continue
            # Typst points to EMU, scaled from the Typst page to the pptx slide.
            sx = prs.slide_width / v["page-width"]
            sy = prs.slide_height / v["page-height"]
            slide.shapes.add_movie(
                str(root / v["src"]),
                Emu(round(v["x"] * sx)), Emu(round(v["y"] * sy)),
                Emu(round(v["width"] * sx)), Emu(round(v["height"] * sy)),
                poster_frame_image=str(root / v["poster"]),
                mime_type="video/mp4",
            )

    out.parent.mkdir(parents=True, exist_ok=True)
    prs.save(out)
    if missing:
        print("these slides have no `// SAY:` block, so they ship without notes:\n  " + "\n  ".join(missing))
    print(f"wrote {out}  ({len(pages)} slides, {len(video)} video)")


if __name__ == "__main__":
    main()
