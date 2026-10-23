# Build the talk: figures -> PNGs -> Typst deck + starter PowerPoint.
#
#   just            # everything, in order
#   just deck       # just the PDF
#   just watch      # live-rebuild the PDF while editing
#
# The PowerPoint is the deliverable and the Typst deck is the design source, so
# `just` builds both and they are always generated from the same figures.

png := "out/png"
repo := "/home/jake/src/monte_carlo_hazard_estimation_code"

# Export resolution for the figure PNGs that go into PowerPoint. These are
# placed at a fixed physical size on the slide, so extra pixels do not change
# the layout -- they buy headroom for zooming, for a projector at native
# resolution, and for print. 600 is comfortable; raise it here and nowhere else.
ppi := "600"

# Every figure that export.typ knows how to render.
typst_figures := "bias-variance-curves two-strategies psha-pipeline cybershake-timeline scale-ladder magnitude-blind-1 magnitude-blind-2 objectives-fan nshm-logic-tree sampling-logic-tree solve-and-project multi-segment-propagation"

default: figures deck pptx

# Matplotlib figures (PEP-723 scripts, run with uv).
mpl:
    uv run scripts/plot_fields_row.py --out {{png}}/fields-row.png --dpi {{ppi}}
    uv run scripts/plot_hazard_coverage.py --out {{png}}/hazard-coverage.png --dpi {{ppi}}
    uv run scripts/plot_key_idea.py --out {{png}}/key-idea.png --dpi {{ppi}}
    uv run scripts/plot_generator_preview.py --out {{png}}/generator-preview.png --dpi {{ppi}}
    # Efficiency curves come from the analysis repo, so the deck cannot drift
    # from the numbers. Slide variant: no maps, poster type scaled for a slide.
    uv run {{repo}}/report/make_efficiency_figure.py {{repo}}/data/density.h5 \
        {{repo}}/pilot_runs_emod3d_with_event_attributes.csv {{repo}}/data/ruptures.parquet \
        {{repo}}/data/all_real_sites.parquet {{repo}}/data/coastline.wkb {{png}} \
        --width-cm 22 --curves-only --font-scale 0.5

# Vector figures, exported standalone at print resolution for PowerPoint.
vector:
    mkdir -p {{png}}
    for f in {{typst_figures}}; do \
        typst compile --input fig=$f export.typ "{{png}}/$f.png" --format png --ppi {{ppi}}; \
    done

figures: mpl vector

# The Typst deck. Depends on fields-row.png, which main.typ embeds directly.
deck: mpl
    typst compile main.typ

# One PNG per slide, for reviewing the deck without opening a PDF viewer.
slides: deck
    typst compile main.typ '{{png}}/slide-{p}.png' --format png --ppi 110

# The starter deck: editable titles, figures placed, speaker notes carried
# across from the `// SAY:` blocks in main.typ.
pptx: figures
    uv run make_pptx.py

watch:
    typst watch main.typ

clean:
    rm -rf out main.pdf
