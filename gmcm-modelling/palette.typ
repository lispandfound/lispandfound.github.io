// One palette, reused across every figure in the deck. Ported from
// ~/Documents/reproducible-data-talk/palette.typ so this deck sits natively on
// the metropolis theme -- `exact` and `stat` are metropolis' own dark and
// accent.
//
// Semantics for THIS deck:
//   exact   the previous workflow -- uniform grid, flat surface, EMOD3D
//   stat    the new workflow -- SW4, refinement, topography, NZCVM
//   defect  a compromise being paid for
//   perf    a measured result that came out of the change
//   quiet   de-emphasis, guides, axes

#let exact = rgb("#23373b")
#let stat = rgb("#eb811b")
#let defect = rgb("#b3242b")
#let perf = rgb("#1f6f5c")
#let quiet = rgb("#8a8f92")

// Sediment fill for the cross-sections, so every basin in the deck is the same
// colour.
#let sediment = rgb("#e9d8a6")

// Text helper. Figures are drawn at document scale and scaled at use, so a
// point size here is relative to the figure, not to the slide.
#let lbl(body, size: 7pt, fill: black, ..args) = text(size, fill: fill, ..args)[#body]

// Relaxation-mechanism colours for the attenuation figures: one hue per
// mechanism, so a reader can see which points carry which. Eight, because the
// coarse-grained scheme spreads eight mechanisms over a 2 x 2 x 2 block.
#let mechanisms = (
  rgb("#4e79a7"),
  rgb("#f28e2b"),
  rgb("#59a14f"),
  rgb("#e15759"),
  rgb("#76b7b2"),
  rgb("#edc948"),
  rgb("#b07aa1"),
  rgb("#9c755f"),
)
