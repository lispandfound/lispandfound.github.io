// SW4 variable mesh refinement: the grid spacing doubles at each interface
// going down.
//
// Importable:
//   #import "figures/refinement.typ": refinement
//
// Block heights are schematic -- the real depth ranges span 1.5 km to 22 km and
// would flatten the top block to a line. The numbers on the right are the
// 2012p578973 benchmark (offshore Mw 5.1, no topography), from
// ~/notes/20260703T130738--sw4-optimisation-notes: spacing, depth range and
// each block's share of the grid points. The share is the whole argument: the
// top 1.5 km carries two thirds of the points even with refinement, so a
// uniform grid at 50 m would have been the top block's density all the way
// down.
//
// The panel on the right is why the blocks are where they are: the grid has to
// carry 2 Hz at 5 points per wavelength, so the spacing it needs at each depth
// is h = V_S,min(z) / (5 x 2 Hz) -- the slowest material at that depth sets it.
// Drawn on the same schematic depth axis as the blocks, so each SW4 step sits
// beside its block. SW4 steps down through 50, 100, 200 and 400 m, staying under
// the required spacing; EMOD3D keeps the 50 m the surface needs all the way
// down. The V_S,min profile is SCHEMATIC: it rises from the 500 m/s floor and is
// chosen to be consistent with the benchmark's refinement depths, not read from
// a velocity model. The top axis gives the same positions as V_S,min, since at
// 2 Hz and 5 points per wavelength V_S,min (m/s) = 10 h (m).

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": defect, exact, quiet, sediment, stat

#let refinement = canvas(length: 1cm, {
  import draw: *

  let lbl = 15pt
  let x0 = 0.0
  let x1 = 9.6

  // (top, bottom, spacing, label, share) -- schematic heights.
  let blocks = (
    (0.0, -1.2, 0.15, [50 m], [0--1.5 km], [66%]),
    (-1.2, -2.4, 0.3, [100 m], [1.5--5 km], [19%]),
    (-2.4, -3.6, 0.6, [200 m], [5--25 km], [13%]),
    (-3.6, -4.8, 1.2, [400 m], [25--47 km], [2%]),
  )

  // A shallow basin, so the top block has a reason to be fine.
  let basin(x) = -0.95 * calc.exp(-calc.pow((x - 6.4) / 1.4, 4))
  let fine = 120
  let xs = range(0, fine + 1).map(i => x0 + (x1 - x0) * i / fine)
  line(
    ..xs.filter(x => basin(x) < -0.02).map(x => (x, basin(x))),
    close: true,
    fill: sediment,
    stroke: none,
  )

  for (top, bot, h, name, depth, share) in blocks {
    let n = int(calc.round((x1 - x0) / h))
    for i in range(0, n + 1) {
      let x = x0 + i * h
      line((x, top), (x, bot), stroke: (thickness: 0.3pt, paint: quiet))
    }
    let m = int(calc.round((top - bot) / h))
    for j in range(0, m + 1) {
      let z = top - j * h
      line((x0, z), (x1, z), stroke: (thickness: 0.3pt, paint: quiet))
    }
    line((x0, bot), (x1, bot), stroke: (thickness: 0.9pt, paint: exact))

    let mid = (top + bot) / 2
    content(
      (x1 + 0.3, mid),
      std.grid(
        columns: (2.2cm, 2.7cm, 1.1cm),
        align: (left, left, right),
        text(lbl, weight: "bold", fill: stat)[#name],
        text(lbl, fill: quiet.darken(25%))[#depth],
        text(lbl, weight: "bold")[#share],
      ),
      anchor: "west",
    )
  }

  line(
    ..xs.filter(x => basin(x) < -0.02).map(x => (x, basin(x))),
    stroke: (thickness: 0.8pt, paint: exact),
  )
  line((x0, 0), (x1, 0), stroke: (thickness: 1.2pt, paint: exact))
  rect((x0, -4.8), (x1, 0), stroke: (thickness: 0.6pt, paint: exact))

  content(
    (x1 + 0.3, 0.35),
    std.grid(
      columns: (2.2cm, 2.7cm, 1.1cm),
      align: (left, left, right),
      text(lbl - 1pt, fill: quiet)[Spacing],
      text(lbl - 1pt, fill: quiet)[Depth],
      text(lbl - 1pt, fill: quiet)[Points],
    ),
    anchor: "west",
  )

  // --- Required spacing against depth -------------------------------------
  // (depth top km, depth bottom km) of each block, matching `blocks` above.
  let ranges = ((0.0, 1.5), (1.5, 5.0), (5.0, 25.0), (25.0, 47.0))
  let spacing = (50, 100, 200, 400)
  // Schematic depth (km) onto the block layout's y.
  let y-of(z) = {
    let out = -4.8
    for (i, (a, b)) in ranges.enumerate() {
      if z >= a and z <= b { out = -1.2 * i - 1.2 * (z - a) / (b - a); break }
    }
    out
  }
  // Schematic minimum V_S (km/s) with depth: the 500 m/s floor, then rising.
  let knots = ((0.0, 0.5), (0.3, 0.5), (1.5, 1.05), (5.0, 2.05), (25.0, 4.05), (47.0, 4.4))
  let vs-of(z) = {
    let v = knots.last().at(1)
    for i in range(0, knots.len() - 1) {
      let (z0, v0) = knots.at(i)
      let (z1, v1) = knots.at(i + 1)
      if z >= z0 and z <= z1 { v = v0 + (v1 - v0) * (z - z0) / (z1 - z0); break }
    }
    v
  }
  let px0 = x1 + 7.2
  let pw = 6.0
  let hmax = 450.0
  let X(h) = px0 + h / hmax * pw

  // Axes.
  line((px0, 0), (px0 + pw, 0), stroke: (thickness: 0.6pt, paint: exact))
  line((px0, 0), (px0, -4.8), stroke: (thickness: 0.6pt, paint: exact))
  for h in spacing {
    line((X(h), 0), (X(h), 0.1), stroke: (thickness: 0.6pt, paint: exact))
    content((X(h), 0.15), text(lbl - 3pt, fill: exact)[#h], anchor: "south")
    line((X(h), 0), (X(h), -4.8), stroke: (thickness: 0.3pt, paint: quiet.lighten(50%), dash: "dotted"))
  }
  content((px0 + pw / 2, 0.75), text(lbl - 2pt, fill: quiet.darken(25%))[grid spacing $h$ (m)], anchor: "south")
  for (i, (a, b)) in ranges.enumerate() {
    line((px0, -1.2 * (i + 1)), (px0 + pw, -1.2 * (i + 1)), stroke: (thickness: 0.3pt, paint: quiet.lighten(50%), dash: "dotted"))
  }

  // EMOD3D: the surface spacing, everywhere.
  line((X(50), 0), (X(50), -4.8), stroke: (thickness: 2pt, paint: defect, dash: "dashed"))
  // SW4: one step per block.
  let pts = ()
  for (i, h) in spacing.enumerate() {
    pts.push((X(h), -1.2 * i))
    pts.push((X(h), -1.2 * (i + 1)))
  }
  line(..pts, stroke: (thickness: 2.4pt, paint: stat))
  // Required: V_S,min / (5 f_t) at 2 Hz, i.e. 100 m per km/s.
  let n = 160
  let req = range(0, n + 1).map(k => {
    let z = 47.0 * calc.pow(k / n, 3)
    (X(calc.min(100 * vs-of(z), hmax)), y-of(z))
  })
  line(..req, stroke: (thickness: 1.6pt, paint: exact))

  // Labels, placed where each line has room.
  content((X(50) + 0.12, -4.45), text(lbl - 2pt, weight: "bold", fill: defect)[EMOD3D], anchor: "west")
  content((X(400) - 0.12, -4.45), text(lbl - 2pt, weight: "bold", fill: stat)[SW4], anchor: "east")
  content(
    (X(hmax) + 0.15, y-of(16.0)),
    align(left, text(lbl - 3pt, fill: exact)[Required: \ $V_(S, min) (z) \/ 5 f_t$]),
    anchor: "west",
  )
})
