// SW4 run time relative to EMOD3D on the same event: how far behind it started
// and how much of that the work so far has closed.
//
// Importable:
//   #import "figures/sw4-cost.typ": sw4-cost
//
// Numbers from ~/notes/20260703T130738--sw4-optimisation-notes, for the
// 2012p578973 benchmark (offshore Mw 5.1): EMOD3D about 25 min; SW4 out of the
// box about 40 h; SW4 with corrected process placement and the tuned MPI/OpenMP
// split about 3 h on the 50 m grid (5000 steps/h), and about 1 h at 100 m with
// topography (9500 steps/h). The SW4 rows are not all the same grid, so read
// each bar against its label, not against its neighbours. Log scale, because the
// first bar is two orders of magnitude.

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": defect, exact, perf, quiet, stat

// (label, minutes, paint). The two tuned rows differ in grid: 50 m top block
// (2 Hz) and 100 m with topography (1 Hz); the label carries only the frequency.
#let runs = (
  ([EMOD3D], 25.0, exact),
  ([SW4, out of the box], 40.0 * 60, defect),
  ([], 3.0 * 60, stat),
  ([SW4, tuned], 60.0, perf),
)

#let sw4-cost = canvas(length: 1cm, {
  import draw: *

  let lbl = 15pt
  let w = 7.0
  let row = 1.3
  let bar = 0.7
  // log10(relative) from 1x to 100x onto [0, w].
  let X(rel) = calc.log(rel, base: 10) / 2.0 * w

  for (i, (name, minutes, paint)) in runs.enumerate() {
    let y = -i * row
    let rel = minutes / 25.0
    rect(
      (0, y - bar / 2),
      (calc.max(X(rel), 0.08), y + bar / 2),
      fill: paint,
      stroke: none,
    )
    content(
      (-0.25, y),
      text(lbl, weight: "bold", fill: paint)[#name],
      anchor: "east",
    )
    let time = if minutes >= 60 {
      [#calc.round(minutes / 60, digits: 0) h]
    } else { [#int(minutes) min] }
    content(
      (calc.max(X(rel), 0.08) + 0.2, y),
      text(lbl, fill: exact)[#time #text(
          fill: quiet.darken(20%),
        )[(#calc.round(rel, digits: 1)×)]],
      anchor: "west",
    )
  }

  let base = -(runs.len() - 1) * row - 0.7
  line((0, base), (w, base), stroke: (thickness: 0.6pt, paint: exact))
  line((0, base), (0, row / 2 + 0.1), stroke: (thickness: 0.6pt, paint: exact))
  for (rel, t) in ((1, [1×]), (10, [10×]), (100, [100×])) {
    line((X(rel), base), (X(rel), base - 0.1), stroke: (
      thickness: 0.6pt,
      paint: exact,
    ))
    content((X(rel), base - 0.18), text(lbl - 1pt)[#t], anchor: "north")
    line((X(rel), base), (X(rel), row / 2), stroke: (
      thickness: 0.3pt,
      paint: quiet.lighten(40%),
      dash: "dotted",
    ))
  }
  content(
    (w / 2, base - 0.75),
    text(
      lbl - 1pt,
      fill: quiet.darken(20%),
    )[Run time relative to EMOD3D, same event],
    anchor: "north",
  )
})
