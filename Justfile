# Build the talk.
#
#   just            # data figures, then the PDF
#   just deck       # the PDF, using whatever figures are already built
#   just watch      # live-rebuild the PDF while editing
#   just slides     # one PNG per slide, for reviewing without a PDF viewer
#
# The figures that carry real numbers are generated here rather than pasted in,
# so a slide cannot drift from the data behind it. `just data` needs
# ~/tmp/ims.duckdb on disk (the Cybershake pilot) and a network connection for
# pypistats; the PyPI script falls back to out/png/pypi-downloads.json if the
# API is unreachable, so a build offline reuses the last numbers instead of
# failing. The citation figure needs neither -- its numbers are a published
# result, hard-coded from the paper.

png := "out/png"

# Export resolution for the figures. They are placed at a fixed size on the
# slide, so extra pixels do not change the layout -- they buy headroom for a
# projector at native resolution, and for print.
ppi := "300"

default: data deck

# The two data-driven figures. PEP-723 scripts, run with uv.
data:
    mkdir -p {{png}}
    uv run scripts/plot_basin_amplification.py --out {{png}}/basins.png --dpi {{ppi}}
    uv run scripts/plot_pypi.py --out {{png}}/pypi.png --dpi {{ppi}}
    uv run scripts/plot_citation.py --out {{png}}/citation.png --dpi {{ppi}}

deck:
    typst compile main.typ

# One PNG per slide, for reviewing the deck without opening a PDF viewer.
#
# The old PNGs are removed first. Typst writes one file per page, so a deck that
# loses a slide leaves the last render of the old final slide sitting on disk
# under a number nothing writes any more -- which reads exactly like a slide
# that failed to update.
slides: deck
    rm -f {{png}}/slide-*.png
    typst compile main.typ '{{png}}/slide-{0p}.png' --format png --ppi 110

watch:
    typst watch main.typ

clean:
    rm -rf out main.pdf

# Lint the deck's prose for AI writing tells.
#
# Vale cannot read Typst, so the prose is extracted first: the rendered slide
# text out of the PDF, and the `// SAY:` speaker script out of main.typ. They
# are linted separately because they are different registers.
lint: deck
    mkdir -p out/lint
    pdftotext main.pdf out/lint/slides.md
    uv run scripts/extract_prose.py main.typ out/lint/notes.md
    -vale out/lint/slides.md out/lint/notes.md

# Rebuild the baseline: the PhD proposal body, references stripped.
#
# One baseline, deliberately. It is the longest sample of the author's own
# connected prose, and it disagrees with the earlier decks about the em-dash --
# which is the point of having a baseline at all.
lint-baseline:
    mkdir -p out/lint/baseline
    pdftotext ~/Documents/phd-proposal/main.pdf out/lint/baseline/_full.md
    sed -n '42,1217p' out/lint/baseline/_full.md > out/lint/baseline/phd-proposal.md
    rm out/lint/baseline/_full.md
    -vale out/lint/baseline/phd-proposal.md
    uv run scripts/prose_metrics.py

# Structural densities Vale's keyword rules cannot express, against the baseline.
metrics: lint
    uv run scripts/prose_metrics.py out/lint/slides.md out/lint/notes.md
