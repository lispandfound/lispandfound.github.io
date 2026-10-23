// True topography against the squashed-tapered approximation previous
// Cybershake runs used, drawn in the style of curvilinear-cartesian-grid.typ.
//
// Importable:
//   #import "figures/topography-squashing.typ": topography-squashing
//
// Left: the topography-conforming mesh, with near-surface velocity layers at a
// constant depth below the free surface and an elevated sedimentary basin (in
// the deck's sediment colour; think Hanmer) under a raised valley floor.
// Right: the same model after squashed-tapered mapping onto a flat free
// surface. The flat grid's depth z' (sea level 0, taper depth -D) samples the
// true model at
//   z = z' + tau(x) (1 + z' / D),
// so the column from the surface down to -D is compressed into the D below sea
// level, by D / (D + tau). Anything d below the true surface lands at
// z' = -d D / (D + tau): thinner under every hill, and an elevated basin loses
// thickness in proportion to how high it sits. Relief, taper depth and layers
// are SCHEMATIC and exaggerated so the compression reads at slide scale.

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": exact, quiet, sediment, stat

// Near-surface layers, slow to fast: (depth of base below surface, fill).
// A ramp on the theme's dark teal, lightest (slowest) at the top.
#let layers = (
  (0.30, exact.lighten(95%)),
  (0.65, exact.lighten(80%)),
  (1.00, exact.lighten(60%)),
)
#let rock = exact.lighten(32%)

#let lbl = 11.5pt
#let x0 = 0.0
#let x1 = 11.0
#let zi = -1.5 // curvilinear / Cartesian interface, and the taper depth
#let zbot = -3.0
#let nx = 22
#let dx = (x1 - x0) / nx
#let fine = 110
#let xs = range(0, fine + 1).map(i => x0 + (x1 - x0) * i / fine)

#let bump(x, c, w) = calc.exp(-calc.pow((x - c) / w, 2))
#let sig(x) = 1 / (1 + calc.exp(-4 * x))

// A range on the left; on the right, a raised valley floor between two ridges.
#let topo(x) = (
  1.9 * bump(x, 2.4, 1.0)
    + 1.0 * (sig(x - 6.2) - sig(x - 10.2))
    + 0.55 * bump(x, 5.9, 0.45)
    + 0.45 * bump(x, 10.5, 0.4)
)

// Sediment thickness of the elevated basin under the valley floor.
#let basin(x) = 1.35 * calc.exp(-calc.pow((x - 8.2) / 1.25, 4))
#let bxs = xs.filter(x => basin(x) > 0.01)

// Fill the bands between successive layer bases, given where each sits at x.
#let bands(top, base) = {
  import draw: *
  line(..xs.map(x => (x, top(x))), (x1, zbot), (x0, zbot), close: true, fill: rock, stroke: none)
  let upper = top
  for (k, (d, fill)) in layers.enumerate() {
    let lower = x => base(x, d)
    line(
      ..xs.map(x => (x, upper(x))),
      ..xs.rev().map(x => (x, lower(x))),
      close: true,
      fill: fill,
      stroke: none,
    )
    line(..xs.map(x => (x, lower(x))), stroke: (thickness: 0.4pt, paint: exact.lighten(40%)))
    upper = lower
  }
}

// The basin, from the surface down to its floor, given where depth d sits at x.
#let basin-fill(top, base) = {
  import draw: *
  line(
    ..bxs.map(x => (x, top(x))),
    ..bxs.rev().map(x => (x, base(x, basin(x)))),
    close: true,
    fill: sediment,
    stroke: none,
  )
  line(..bxs.map(x => (x, base(x, basin(x)))), stroke: (thickness: 0.8pt, paint: stat.darken(10%)))
}

#let frame(top) = {
  import draw: *
  line(..xs.map(x => (x, top(x))), stroke: (thickness: 1.2pt))
  line((x0, zbot), (x1, zbot), stroke: (thickness: 0.6pt))
  line((x0, zbot), (x0, top(x0)), stroke: (thickness: 0.6pt))
  line((x1, zbot), (x1, top(x1)), stroke: (thickness: 0.6pt))
}

#let title(body) = draw.content(
  ((x0 + x1) / 2, 2.25),
  text(13pt, weight: "bold", fill: exact)[#body],
  anchor: "south",
)

#let grid-stroke = (thickness: 0.3pt, paint: quiet.lighten(25%))

#let true-panel = canvas(length: 1cm, {
  import draw: *

  bands(topo, (x, d) => topo(x) - d)
  basin-fill(topo, (x, d) => topo(x) - d)

  // Curvilinear rows of constant q, then the Cartesian block below.
  let nq = 6
  for j in range(1, nq) {
    let q = j / nq
    line(..xs.map(x => (x, topo(x) * (1 - q) + zi * q)), stroke: grid-stroke)
  }
  for i in range(0, nx + 1) {
    let x = x0 + i * dx
    line((x, topo(x)), (x, zbot), stroke: grid-stroke)
  }
  let dz = (zi - zbot) / 4
  for j in range(1, 4) {
    line((x0, zbot + j * dz), (x1, zbot + j * dz), stroke: grid-stroke)
  }
  line((x0, zi), (x1, zi), stroke: (thickness: 0.9pt))
  frame(topo)

  content(
    (x0 + 0.15, zi - 0.28),
    box(fill: white, inset: (x: 2pt, y: 1.5pt), text(lbl)[Grid interface]),
    anchor: "west",
  )
  content(
    (8.2, topo(8.2) + 0.35),
    text(lbl, fill: exact)[Elevated basin],
  )
  title[True: topography-conforming mesh]
})

#let squashed-panel = canvas(length: 1cm, {
  import draw: *

  let flat = x => 0.0
  let D = -zi
  let squash = (x, d) => -d * D / (D + topo(x))
  bands(flat, squash)
  basin-fill(flat, squash)

  // The topography the flat surface throws away, and where it went.
  line(
    ..xs.map(x => (x, topo(x))),
    stroke: (thickness: 0.8pt, paint: quiet, dash: "dashed"),
  )
  for xa in (2.4, 8.2) {
    line(
      (xa, topo(xa) - 0.05),
      (xa, 0.08),
      mark: (end: "stealth", fill: quiet),
      stroke: (thickness: 0.7pt, paint: quiet),
    )
  }

  for i in range(0, nx + 1) {
    let x = x0 + i * dx
    line((x, 0), (x, zbot), stroke: grid-stroke)
  }
  let dz = (0 - zbot) / 8
  for j in range(1, 8) {
    line((x0, j * -dz), (x1, j * -dz), stroke: grid-stroke)
  }
  line((x0, zi), (x1, zi), stroke: (thickness: 0.9pt, dash: "dotted"))
  frame(flat)

  content(
    (x0 + 0.15, zi - 0.28),
    box(fill: white, inset: (x: 2pt, y: 1.5pt), text(lbl)[Taper depth]),
    anchor: "west",
  )
  content(
    (8.2, squash(8.2, basin(8.2)) - 0.3),
    box(fill: white, inset: (x: 2pt, y: 1.5pt), text(lbl, fill: exact)[Basin thinned]),
  )
  title[Squashed-tapered: flat surface]
})

#let topography-squashing = grid(
  columns: 2,
  column-gutter: 0.9cm,
  true-panel, squashed-panel,
)
