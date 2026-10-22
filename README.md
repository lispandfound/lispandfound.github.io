# Rupture sampling and rupture generation — talk

Deliverable is `out/rupture-sampling-talk.pptx`, for Office 365. The design is
authored in Typst; the PowerPoint is generated from the same figures so the two
cannot drift.

```sh
just          # figures -> PNGs -> main.pdf + starter .pptx
just deck     # main.pdf only
just slides   # one PNG per slide, for a quick look
just watch    # live rebuild while editing
```

## What is where

| Path | What |
|---|---|
| `main.typ` | the deck. Speaker notes are `// SAY:` comments above each `==` heading |
| `palette.typ` | the shared colours, ported from `~/Documents/presentation/diagrams.typ` |
| `figures/bias-variance-curves.typ` | hazard vs variance weighting against exceedance probability |
| `figures/two-strategies.typ` | the two allocations the GMM implies, and the weight between them |
| `scripts/plot_hazard_coverage.py` | hazard covered vs ruptures simulated, per selection rule |
| `figures/psha-pipeline.typ` | the four-stage process, with this work's two stages marked |
| `figures/cybershake-timeline.typ` | NSHM releases and Cybershake campaigns, 2010 to now |
| `figures/*.typ` | one importable `#let` per figure (fletcher for box-and-arrow, cetz for geometric) |
| `scripts/plot_fields_row.py` | the four kinematic fields, matplotlib, PEP-723 + `uv` |
| `export.typ` | renders one figure standalone: `--input fig=<name>`, transparent background |
| `make_pptx.py` | the starter deck: editable titles, figures placed, `// SAY:` notes carried across |
| `out/png/` | figure PNGs at `ppi`, plus `slide-N.png` review renders |

## Rebuilding the PowerPoint after a figure change

`just` is enough — it re-exports every PNG and regenerates the `.pptx`. If you
have already restyled the deck in Office, don't regenerate over it: export the
single figure you changed and replace that one picture.

```sh
typst compile --input fig=magnitude-blind-2 export.typ out/png/magnitude-blind-2.png \
  --format png --ppi 600
```

## Export resolution

Set once, as `ppi` at the top of the `Justfile` (currently **600**); it drives
both the Typst exports and the matplotlib `--dpi`. Raise it there and nowhere
else.

Figures are placed on the slide at a fixed physical size, so extra pixels do not
move anything — they buy headroom for zooming in, for a projector running at its
native resolution, and for print. At 600 ppi the *lowest* effective on-slide
resolution across the deck is ~267 ppi, against ~144 ppi for a full-bleed slide
on a 1920-wide projector and 300 ppi for print. Total figure weight is 2.1 MB
and the deck is 1.9 MB, so there is room to go higher if a poster ever needs it.

## Staged slides

The magnitude-rule slide is built in two stages: the piecewise rule alone, then
the two ruptures it cannot distinguish. In Typst that is `#only("1", ...)` /
`#only("2-", ...)`; in PowerPoint it is two consecutive slides.

Stage one draws the pair with cetz's `hide(..., bounds: true)` rather than
omitting it, so both stages have identical extents (verified: 1491x789 px each)
and the axes do not move under the audience on the reveal. If you add anything
to stage two, put it inside the `stage-two` block so it is hidden — not omitted
— in stage one.

## The two blank slides

Slides 10 and 11 carry a title, a caption, and a 16:9 placeholder frame sized to
the body, so a dropped-in video snaps to the right dimensions. Delete the
"drop video here" rectangle once the video is in.

## Conventions

**Discrete colour, never a continuous ramp.** Brendon reads a map by counting
bands. `scripts/plot_fields_row.py` follows
`~/src/eqvis_workflow/src/eqvis_workflow/raster.py:discrete_norm`: round level
boundaries from `MaxNLocator` over the robust 1–99% range, a `BoundaryNorm`
against `cmap.N`, and colourbar ticks placed *on* the boundaries (thinned to
what fits). Every field here is non-negative with a zero floor, so the norm
extends at the top only — `extend="max"`, not `"both"`, since a low-end arrow
would advertise underflow that cannot happen. Rupture-time contours are drawn
on the same boundaries as the colour bands, so the two are one partition of the
field rather than two competing ones.

**No conclusions in the figures.** The figures carry evidence; the claims get
added in PowerPoint. Removed accordingly: "109× rarer, same N, 68% more
compute", "No single objective function combines these cleanly", "epistemic
uncertainty, resolved by stated weights", and "slip, rise time, rake, eikonal —
unchanged".

Kept, because they are data rather than argument: the EuroHPC reference line and
its value, the card contents (IDs, magnitudes, return periods, core-hours), and
the branch weights. Say the word if any of those should go too.

The −0.14 to +0.03 s curved-chart timing limit is **spoken, not written** — it
lives only in the `// SAY:` note for that slide, so it reaches the PowerPoint
notes pane and not the slide.

**Explicit colour, never `*bold*`.** Metropolis recolours strong text, so
markup bold comes out accent-coloured in the deck and plain black in the
standalone PNG — the PowerPoint would then not match the PDF. Every figure sets
`text(weight: "bold", fill: ...)` explicitly.

**Segment names** are off the propagation figure. Which fault is "segment 3"
carries no argument — the order, the branch and the entry times do — and four
extra labels crowded a figure already dense with arrows.

## Numbers on the slides, and where they came from

Everything quantitative was recomputed from the data rather than quoted, and
the derivations are in the header comment of the figure that shows them.

| Claim | Source |
|---|---|
| Cybershake NZ v25.6: 4.7 M core-hours, 200 m, NSHM 2010, 16,043 simulations | supplied by Jake; campaign is `abbasnejardfard2025subduction` |
| 293 pilot ruptures, 3.74 M core-hours | `~/Downloads/emod3d_performance_cs_nshm_2022_pilot.csv` |
| pilot resolution is h = 100 m | inferred as `sqrt(domain_area_km2 / (nx·ny))` across all 293 runs |
| 1.4 × 10⁸ core-hours for one realisation each | 7,122 rate-bearing ruptures in `data/ruptures.parquet`, costed by the fitted model `log10(core_h) = 0.342 Mw + 1.562` |
| 41065 / 90894 magnitudes and rates (stage two) | `data/ruptures.parquet` (Leonard 2014 magnitudes) |
| tectonic and strategy weights (0.25/0.75; variance leaves 0.125, bias leaves 0.375) | `sampling_logic_tree` root attribute of `data/density.h5` |
| efficiency curves: 7 / 10 / 5 % vs the Mw rule's 23 / 40 / 16 % | `report/figures/efficiency_summary.json`; the slide variant is rendered by `just figures` with `--curves-only --font-scale 0.5` |
| Cybershake NZ v19.5, h = 400 m, NSHM 2010 | `bradley2019cybershakenz` (2019) |
| Cybershake NZ h = 200 m, + subduction | `abbasnejardfard2025subduction`; also `abbasnejardfard2024cybershake` |
| NSHM 2010 / NSHM 2022 release years | `stirling2012national` / `gerstenberger2024seismicity` — placed at the year each model is *named* for, not its publication year (2012 / 2024), since the gap between model and campaign is what the timeline is about |
| hazard covered by top-500 ruptures: 40 / 52 / 86 % (CBGS) | ranked by magnitude, rate, GMM contribution; from `report/figures/site_slice.npz` at the 1-in-475-yr threshold |
| magnitude and area rank ruptures identically | Spearman ρ = 1.0000, computed — area is a deterministic function of magnitude under the scaling relation |
| bias = summed hazard of unsampled ruptures | `report/make_efficiency_figure.py`, `bias = hazard[:, ~sampled].sum(axis=1)` in `evaluate()` |
| −0.14 to +0.03 s curved-chart timing shortfall | `rupture_generator-hybrid` README, "Known limits" |

Two things the slides deliberately correct against the docs: `CLAUDE.md`
describes a `FAULT_SYSTEM_TECTONIC_TYPE` mapping that no longer exists in
`logic_tree.py` (branches declare `fault_systems` directly), and
`MagnitudeBinnedSample` raises `NotImplementedError`, which is why it is drawn
dashed rather than as a live branch.

The ladder counts **simulations**, not ruptures: core-hours scale with how many
simulations were run, so that is the only unit under which the three bars are
comparable — and it keeps the slide from contradicting the timeline, which says
NSHM 2010 has 536 characteristic ruptures. v25.6's 16,043 is 29.9 per rupture,
which is the N(Mw) rule's own mean (14–68, and 536 × 30 = 16,080), so it is
realisations across the 2010 catalogue rather than distinct ruptures.

Per simulation the first two bars are 293 core-hours against 12,765, a factor of
44. Halving the grid accounts for 16×; the remaining 2.7× is composition, since
v25.6 spans a whole catalogue including small cheap events while the pilot is
293 *large* crustal ruptures, Mw 6.7 to 8.4. Worth having ready, because someone
will divide one by the other.

The `225,841` in `report/figures/efficiency_summary.json` is the Cybershake rule
over **crustal only**, since the efficiency study simulates only crustal. The
all-systems figure used here is 433,329. Don't mix them.
