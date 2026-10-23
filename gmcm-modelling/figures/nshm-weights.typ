// Where simulations are headed in the NSHM: the ground-motion logic tree
// weight on empirical models against simulations, across three generations of
// the model.
//
// Importable:
//   #import "figures/nshm-weights.typ": nshm-weights
//
// Schematic: the bar heights are illustrative, not published weights. Empirical
// models take `exact`, the established convention; simulations take `stat`, the
// deck's colour for where this work is going.

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": exact, quiet, stat

// (title, model, empirical weight, simulation weight)
#let stages = (
  ([Convention], [NZ NSHM 2022], 1.0, 0.0),
  ([Emerging], [NZ NSHM 2028/2030], 0.8, 0.2),
  ([Future], [NZ NSHM 2030s], 0.1, 0.9),
)

#let nshm-weights = canvas(length: 1cm, {
  import draw: *

  let lbl = 8pt
  let H = 4.2 // height of 100%
  let spacing = 5.0
  let bw = 1.4 // bar width
  let gap = 0.3
  let x0 = 1.9
  let centre(i) = x0 + i * spacing
  let emp-x(i) = centre(i) - gap / 2 - bw / 2
  let sim-x(i) = centre(i) + gap / 2 + bw / 2
  let x-end = centre(2) + 2.4
  let empirical = exact.lighten(15%)

  // Axes.
  let axis = (thickness: 0.8pt, paint: exact)
  line((0, 0), (x-end, 0), stroke: axis, mark: (end: ">", fill: exact))
  line((0, 0), (0, H + 1.6), stroke: axis, mark: (end: ">", fill: exact))
  content((x-end + 0.15, 0), text(lbl + 1pt, fill: exact)[Time], anchor: "west")
  line((-0.1, H), (0.1, H), stroke: axis)
  content((-0.2, H), text(lbl, fill: exact)[100%], anchor: "east")
  line((0, H), (x-end - 0.4, H), stroke: (thickness: 0.4pt, paint: quiet.lighten(40%), dash: "dotted"))
  content(
    (-0.9, H / 2),
    align(center, text(lbl + 1pt, fill: exact)[Ground-motion \ logic tree \ weight]),
    anchor: "east",
  )

  for (i, (title, model, emp, sim)) in stages.enumerate() {
    let bar(x, w, paint) = if w > 0 {
      rect((x - bw / 2, 0), (x + bw / 2, w * H), fill: paint, stroke: none)
    }
    bar(emp-x(i), emp, empirical)
    bar(sim-x(i), sim, stat)
    content((emp-x(i), -0.2), text(lbl, fill: exact)[Empirical], anchor: "north")
    content((sim-x(i), -0.2), text(lbl, fill: exact)[Simulation], anchor: "north")
    content(
      (centre(i), H + 1.55),
      align(center, text(lbl + 1pt, fill: exact)[#text(weight: "bold")[#title] \ #text(fill: quiet.darken(20%))[#model]]),
      anchor: "north",
    )
  }
  content((sim-x(0), 0.3), text(lbl, fill: quiet.darken(20%), style: "italic")[No weight], anchor: "south")

  // The trends, drawn over the bars from one stage to the last.
  let trend(from, to, paint) = line(
    from,
    to,
    stroke: (thickness: 2.2pt, paint: paint),
    mark: (end: ">", fill: paint, scale: 0.8),
  )
  let emp-from = (emp-x(0) + bw / 2 + 0.1, H - 0.3)
  let emp-to = (emp-x(2) - 0.1, 0.1 * H + 0.45)
  let sim-from = (sim-x(0) + 0.6, 0.12 * H + 0.55)
  let sim-to = (sim-x(2) - 0.05, H + 0.35)
  let emp-trend = empirical.lighten(45%)
  trend(emp-from, emp-to, emp-trend)
  trend(sim-from, sim-to, stat)

  // Each label hangs off a point on its own arrow, above it and well away
  // from where the two cross, so neither can be read as naming the other.
  let along((x1, y1), (x2, y2), t) = (x1 + t * (x2 - x1), y1 + t * (y2 - y1))
  let (sx, sy) = along(sim-from, sim-to, 0.68)
  content(
    (sx - 0.15, sy + 0.3),
    align(right, text(lbl + 1pt, weight: "bold", fill: stat)[Simulation \ total weight]),
    anchor: "south-east",
  )
  let (ex, ey) = along(emp-from, emp-to, 0.14)
  content(
    (ex + 0.1, ey + 0.3),
    align(left, text(lbl + 1pt, weight: "bold", fill: emp-trend.darken(35%))[Empirical \ total weight]),
    anchor: "south-west",
  )
})
