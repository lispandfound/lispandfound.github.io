# /// script
# requires-python = ">=3.11"
# dependencies = ["python-pptx"]
# ///
"""Build a starter .pptx with the exported figures already placed.

The deliverable is a PowerPoint deck edited in Office 365, but the design is
authored in Typst. This script bridges the two: it lays out a 16:9 deck whose
titles are real editable PowerPoint text and whose figures are the 300 ppi PNGs
exported from `export.typ`, so restyling in Office is a matter of moving and
recolouring rather than rebuilding.

Speaker notes are lifted from the ``// SAY:`` comment blocks in ``main.typ``
rather than duplicated here, so the two decks cannot disagree about what is
being said over a slide.

Run:
    uv run make_pptx.py
"""

from __future__ import annotations

import argparse
import re
import struct
from pathlib import Path

from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.text import MSO_ANCHOR, PP_ALIGN
from pptx.util import Emu, Inches, Pt

# Palette, matching palette.typ so the starter deck and the Typst deck agree.
EXACT = RGBColor(0x23, 0x37, 0x3B)
STAT = RGBColor(0xEB, 0x81, 0x1B)
QUIET = RGBColor(0x8A, 0x8F, 0x92)
PAPER = RGBColor(0xFA, 0xFA, 0xFA)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)

SLIDE_W, SLIDE_H = 13.333, 7.5  # inches, 16:9
BAND_H = 0.92  # title band height
BODY_TOP = BAND_H + 0.18
BODY_BOT = SLIDE_H - 0.55

FONT = "Libertinus Serif"


def png_size(path: Path) -> tuple[int, int]:
    """Pixel dimensions of a PNG, read from its IHDR chunk."""
    head = path.read_bytes()[:33]
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path} is not a PNG")
    return struct.unpack(">II", head[16:24])


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


def fit(box: tuple[float, float, float, float], px: tuple[int, int]):
    """Centre an image in ``box`` (l, t, w, h in inches), preserving aspect."""
    left, top, width, height = box
    pw, ph = px
    scale = min(width / pw, height / ph)
    w, h = pw * scale, ph * scale
    return Inches(left + (width - w) / 2), Inches(top + (height - h) / 2), Inches(w), Inches(h)


def rect(slide, left, top, width, height, fill):
    from pptx.enum.shapes import MSO_SHAPE

    shape = slide.shapes.add_shape(
        MSO_SHAPE.RECTANGLE, Inches(left), Inches(top), Inches(width), Inches(height)
    )
    shape.fill.solid()
    shape.fill.fore_color.rgb = fill
    shape.line.fill.background()
    shape.shadow.inherit = False
    return shape


def textbox(
    slide,
    text,
    left,
    top,
    width,
    height,
    *,
    size=14,
    color=EXACT,
    bold=False,
    align=PP_ALIGN.CENTER,
    italic=False,
):
    box = slide.shapes.add_textbox(Inches(left), Inches(top), Inches(width), Inches(height))
    tf = box.text_frame
    tf.word_wrap = True
    tf.vertical_anchor = MSO_ANCHOR.MIDDLE
    p = tf.paragraphs[0]
    p.alignment = align
    run = p.add_run()
    run.text = text
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.italic = italic
    run.font.color.rgb = color
    run.font.name = FONT
    return box


# Every title used here must also appear as a `== Title` heading in main.typ,
# because that is how the speaker notes are matched. The two are separate string
# literals, so renaming a slide in main.typ and not here fails silently: the
# slide keeps its old title and quietly loses its notes. Recorded and checked.
USED_TITLES: list[str] = []


def content_slide(prs, title, notes):
    USED_TITLES.append(title)
    slide = prs.slides.add_slide(prs.slide_layouts[6])  # blank
    rect(slide, 0, 0, SLIDE_W, 0.08, PAPER)  # paper ground
    rect(slide, 0, 0, SLIDE_W, BAND_H, EXACT)
    textbox(
        slide,
        title,
        0.42,
        0.06,
        SLIDE_W - 0.84,
        BAND_H - 0.12,
        size=26,
        color=WHITE,
        align=PP_ALIGN.LEFT,
    )
    rect(slide, 0, SLIDE_H - 0.09, SLIDE_W * 0.62, 0.09, STAT)
    if notes:
        slide.notes_slide.notes_text_frame.text = notes
    return slide


def picture(slide, path: Path, box):
    left, top, width, height = fit(box, png_size(path))
    return slide.shapes.add_picture(str(path), left, top, width, height)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--root", type=Path, default=Path(__file__).parent)
    ap.add_argument("--out", type=Path, default=None)
    args = ap.parse_args()

    root = args.root
    png = root / "out" / "png"
    out = args.out or root / "out" / "rupture-sampling-talk.pptx"
    notes = notes_from_typst(root / "main.typ")

    prs = Presentation()
    prs.slide_width = Inches(SLIDE_W)
    prs.slide_height = Inches(SLIDE_H)

    # --- title ---------------------------------------------------------------
    s = prs.slides.add_slide(prs.slide_layouts[6])
    rect(s, 0, 0, SLIDE_W, SLIDE_H, EXACT)
    textbox(
        s,
        "Which ruptures should we simulate, and how do we build them?",
        0.9,
        2.25,
        SLIDE_W - 1.8,
        1.5,
        size=34,
        color=WHITE,
        align=PP_ALIGN.LEFT,
    )
    textbox(
        s,
        "a sampling logic tree for Cybershake NZ, and multi-segment and curved "
        "rupture generation",
        0.9,
        3.65,
        SLIDE_W - 1.8,
        0.8,
        size=17,
        color=QUIET,
        align=PP_ALIGN.LEFT,
        italic=True,
    )
    rect(s, 0.9, 4.55, 3.4, 0.05, STAT)
    textbox(
        s,
        "Jake Faulkner   ·   University of Canterbury   ·   25 August 2026",
        0.9,
        4.75,
        SLIDE_W - 1.8,
        0.5,
        size=14,
        color=QUIET,
        align=PP_ALIGN.LEFT,
    )

    def section(name):
        sl = prs.slides.add_slide(prs.slide_layouts[6])
        rect(sl, 0, 0, SLIDE_W, SLIDE_H, EXACT)
        textbox(sl, name, 0.9, 3.0, SLIDE_W - 1.8, 1.2, size=40, color=WHITE, align=PP_ALIGN.LEFT)
        rect(sl, 0.9, 4.25, 2.4, 0.05, STAT)
        return sl

    full = (0.55, BODY_TOP, SLIDE_W - 1.1, BODY_BOT - BODY_TOP)

    # --- orientation ---------------------------------------------------------
    # Process above, timeline below. Split roughly 40/60: the pipeline is four
    # short boxes and the timeline needs the height for two label lanes.
    t = "Where this sits"
    s = content_slide(prs, t, notes.get(t, ""))
    body_h = BODY_BOT - BODY_TOP
    picture(s, png / "psha-pipeline.png", (0.55, BODY_TOP, SLIDE_W - 1.1, body_h * 0.34))
    picture(
        s,
        png / "cybershake-timeline.png",
        (0.4, BODY_TOP + body_h * 0.40, SLIDE_W - 0.8, body_h * 0.58),
    )

    # --- sampling ------------------------------------------------------------
    section("Sampling")

    t = "A complete campaign buys 293 ruptures at 100 m"
    picture(content_slide(prs, t, notes.get(t, "")), png / "scale-ladder.png", full)

    # Two stages, two slides: the rule alone, then the pair it cannot see.
    # The figures share a bounding box, so the axes do not move between them.
    t = "The rule is a function of magnitude and nothing else"
    for stage in (1, 2):
        picture(
            content_slide(prs, t, notes.get(t, "") if stage == 2 else ""),
            png / f"magnitude-blind-{stage}.png",
            full,
        )

    t = "The key idea"
    picture(content_slide(prs, t, notes.get(t, "")), png / "key-idea.png", full)

    t = "Every rule is guessing at the same number"
    picture(content_slide(prs, t, notes.get(t, "")), png / "hazard-coverage.png", full)

    # Two figures side by side: the analytic reason on the left, the framework
    # it implies on the right.
    t = "Two strategies out of one model"
    s = content_slide(prs, t, notes.get(t, ""))
    body_h = BODY_BOT - BODY_TOP
    picture(s, png / "bias-variance-curves.png", (0.5, BODY_TOP, 6.1, body_h))
    picture(s, png / "two-strategies.png", (6.9, BODY_TOP, 6.0, body_h))

    t = "One budget, several incompatible objectives"
    picture(content_slide(prs, t, notes.get(t, "")), png / "objectives-fan.png", full)

    t = "Borrow the grammar you already use"
    s = content_slide(prs, t, notes.get(t, ""))
    half_h = BODY_BOT - BODY_TOP - 0.85
    picture(s, png / "nshm-logic-tree.png", (0.35, BODY_TOP, 6.15, half_h))
    picture(s, png / "sampling-logic-tree.png", (6.75, BODY_TOP, 6.25, half_h))
    textbox(
        s,
        "density_i = Σ_s  w_s · σ_i,s / Σ_j σ_j,s        σ_i = λ_i √(P_i (1 − P_i))",
        0.9,
        BODY_TOP + half_h,
        SLIDE_W - 1.8,
        0.6,
        size=15,
    )

    t = "What the tree buys"
    picture(content_slide(prs, t, notes.get(t, "")), png / "core_hour_efficiency.png", full)

    # --- rupture generation --------------------------------------------------
    section("Rupture generation")

    t = "What we have to build"
    picture(content_slide(prs, t, notes.get(t, "")), png / "generator-preview.png", full)

    t = "Two additions to a framework you already know"
    s = content_slide(prs, t, notes.get(t, ""))
    picture(s, png / "fields-row.png", (0.7, BODY_TOP, SLIDE_W - 1.4, 1.85))
    panel_top = BODY_TOP + 2.32
    panel_h = 2.35
    for left, width, label, name in (
        (0.5, 6.35, "Curved ruptures: solve and project", "solve-and-project"),
        (7.2, 5.6, "Multi-segment: sampled path, computed jump", "multi-segment-propagation"),
    ):
        rect(s, left, panel_top, width, panel_h, RGBColor(0xFD, 0xF2, 0xE6))
        textbox(
            s,
            label,
            left + 0.12,
            panel_top + 0.04,
            width - 0.24,
            0.3,
            size=12,
            bold=True,
            color=STAT,
            align=PP_ALIGN.LEFT,
        )
        picture(
            s,
            png / f"{name}.png",
            (left + 0.15, panel_top + 0.38, width - 0.3, panel_h - 0.52),
        )

    # --- the two video slides ------------------------------------------------
    for title, caption in (
        (
            "Multi-segment rupture",
            "rupture path drawn from the Shaw–Dieterich jump probabilities; "
            "jump points computed, not supplied",
        ),
        (
            "Curved rupture",
            "Hikurangi interface: same generator as a crustal fault, solved on the "
            "fitted plane and projected back",
        ),
    ):
        s = content_slide(prs, title, notes.get(title, ""))
        # A 16:9 frame sized to the body, so a dropped-in video snaps to it.
        frame_h = BODY_BOT - BODY_TOP - 0.5
        frame_w = frame_h * 16 / 9
        if frame_w > SLIDE_W - 1.6:
            frame_w = SLIDE_W - 1.6
            frame_h = frame_w * 9 / 16
        holder = rect(
            s,
            (SLIDE_W - frame_w) / 2,
            BODY_TOP,
            frame_w,
            frame_h,
            RGBColor(0xF0, 0xEF, 0xEC),
        )
        holder.line.color.rgb = QUIET
        holder.line.width = Pt(0.75)
        holder.text_frame.text = "drop video here"
        p = holder.text_frame.paragraphs[0]
        p.alignment = PP_ALIGN.CENTER
        p.runs[0].font.size = Pt(13)
        p.runs[0].font.italic = True
        p.runs[0].font.color.rgb = QUIET
        p.runs[0].font.name = FONT
        textbox(
            s,
            caption,
            0.8,
            BODY_TOP + frame_h + 0.1,
            SLIDE_W - 1.6,
            0.4,
            size=12,
            color=QUIET,
        )

    out.parent.mkdir(parents=True, exist_ok=True)
    prs.save(out)
    orphans = [t for t in USED_TITLES if t not in notes]
    if orphans:
        raise SystemExit(
            "these slide titles have no `// SAY:` block in main.typ, so they "
            "would ship without speaker notes -- the heading was probably "
            "renamed in one file and not the other:\n  "
            + "\n  ".join(orphans)
        )
    unused = [t for t in notes if t not in USED_TITLES]
    if unused:
        print(f"note: {len(unused)} `// SAY:` block(s) not used by any slide here")
        for t in unused:
            print(f"  {t}")

    print(f"wrote {out}  ({len(prs.slides._sldIdLst)} slides)")
    print(f"speaker notes carried across: {len(notes)}")


if __name__ == "__main__":
    main()
