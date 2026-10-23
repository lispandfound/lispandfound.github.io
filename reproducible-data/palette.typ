// One palette, reused across every figure in the deck. Ported from
// ~/Documents/rupture-sampling-talk/palette.typ so this deck sits natively on
// the metropolis theme -- `exact` and `stat` are metropolis' own dark and
// accent.
//
// Semantics for THIS deck:
//   exact   the old way -- what we built, and what it cost
//   stat    the new way -- containers, PyPI, NetCDF, DuckDB
//   defect  the failure being paid for
//   perf    a measured result that came out of the change
//   quiet   de-emphasis, guides, axes

#let exact = rgb("#23373b")
#let stat = rgb("#eb811b")
#let defect = rgb("#b3242b")
#let perf = rgb("#1f6f5c")
#let quiet = rgb("#8a8f92")

// Text helper. Figures are drawn at document scale and scaled at use, so a
// point size here is relative to the figure, not to the slide.
#let lbl(body, size: 7pt, fill: black, ..args) = text(size, fill: fill, ..args)[#body]
