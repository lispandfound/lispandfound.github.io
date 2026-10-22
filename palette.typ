// One palette, reused across every figure in the deck. Ported from
// ~/Documents/presentation/diagrams.typ so these slides sit natively on the
// metropolis theme -- `exact` and `stat` are metropolis' own dark and accent.
//
// Semantics for THIS deck:
//   exact   structure that already exists and is accepted (NSHM, genslip)
//   stat    the contribution -- what we add
//   defect  the cost/infeasibility argument
//   perf    the measured result
//   quiet   de-emphasis, guides, axes

#let exact = rgb("#23373b")
#let stat = rgb("#eb811b")
#let defect = rgb("#b3242b")
#let perf = rgb("#1f6f5c")
#let quiet = rgb("#8a8f92")

// Fault-system accents, matching hazard_estimation/plot_spatial_bias.py:47-51
// so a slide and the interactive explorer agree on which colour is which fault.
#let hikurangi = rgb("#3b82f6")
#let puysegur = rgb("#10b981")
#let crustal = rgb("#f59e0b")

// Text helper. Figures are drawn at document scale and scaled at use, so a
// point size here is relative to the figure, not to the slide.
#let lbl(body, size: 7pt, fill: black, ..args) = text(size, fill: fill, ..args)[#body]
