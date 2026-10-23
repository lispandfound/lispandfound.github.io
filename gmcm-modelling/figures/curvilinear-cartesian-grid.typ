// The hybrid curvilinear / Cartesian discretisation used by SW4 to carry a
// topographic free surface.
//
// Importable:
//   #import "figures/curvilinear-cartesian-grid.typ": curvilinear-cartesian-grid
//   #figure(curvilinear-cartesian-grid, caption: [...]) <fig:curvilinear-grid>
//
// The near-surface block is a smooth map of the unit square onto the region
// between the topography and a flat interface, so the free-surface boundary
// condition is applied on a grid line rather than on a staircase. Below the
// interface the grid is Cartesian, where the update stencil is cheap.

#import "@preview/cetz:0.4.2": canvas, draw

#let curvilinear-cartesian-grid = canvas(length: 1cm, {
  import draw: *

  set-style(
    stroke: (thickness: 0.5pt),
    mark: (fill: black, scale: 0.4),
    content: (padding: 0.1),
  )
  let lbl = 11.5pt

  let x0 = 0.0
  let x1 = 11.0
  let zi = -2.2 // curvilinear / Cartesian interface
  let zbot = -4.6

  let topo(x) = (
    0.68 * calc.exp(-calc.pow((x - 2.6) / 1.05, 2))
      + 0.44 * calc.exp(-calc.pow((x - 5.3) / 0.70, 2))
      + 0.30 * calc.exp(-calc.pow((x - 8.6) / 1.40, 2))
  )

  // Vertical map: q = 0 at the free surface, q = 1 at the interface.
  let zc(x, q) = topo(x) * (1.0 - q) + zi * q

  let nx = 22 // grid columns
  let nq = 6 // curvilinear rows
  let dx = (x1 - x0) / nx

  // --- curvilinear block ---------------------------------------------------
  let fine = 110
  line(
    ..range(0, fine + 1).map(i => {
      let x = x0 + (x1 - x0) * i / fine
      (x, topo(x))
    }),
    (x1, zi),
    (x0, zi),
    close: true,
    stroke: none,
  )

  // Rows of constant q.
  for j in range(1, nq) {
    let q = j / nq
    line(
      ..range(0, fine + 1).map(i => {
        let x = x0 + (x1 - x0) * i / fine
        (x, zc(x, q))
      }),
      stroke: (thickness: 0.3pt, paint: gray),
    )
  }
  // Columns of constant x.
  for i in range(0, nx + 1) {
    let x = x0 + i * dx
    line((x, topo(x)), (x, zi), stroke: (thickness: 0.3pt, paint: gray))
  }

  // --- Cartesian block -----------------------------------------------------
    let nz = 5
  let dz = (zi - zbot) / nz
  for j in range(1, nz) {
    line((x0, zbot + j * dz), (x1, zbot + j * dz), stroke: (
      thickness: 0.3pt,
      paint: gray,
    ))
  }
  for i in range(0, nx + 1) {
    let x = x0 + i * dx
    line((x, zi), (x, zbot), stroke: (thickness: 0.3pt, paint: gray))
  }

  // --- boundaries ----------------------------------------------------------
  line(
    ..range(0, fine + 1).map(i => {
      let x = x0 + (x1 - x0) * i / fine
      (x, topo(x))
    }),
    stroke: (thickness: 1.2pt),
  )
  line((x0, zi), (x1, zi), stroke: (thickness: 0.9pt))
  line((x0, zbot), (x1, zbot), stroke: (thickness: 0.6pt))
  line((x0, zbot), (x0, topo(x0)), stroke: (thickness: 0.6pt))
  line((x1, zbot), (x1, topo(x1)), stroke: (thickness: 0.6pt))

  // --- labels --------------------------------------------------------------
  content(
    (x0 - 2.1, topo(x0)),
    text(lbl)[$z = tau(x, y)$],
    anchor: "west",
  )

  content(
    (x1 + 0.2, (zi + 1.0) / 2),
    box(width: 4.6cm, text(lbl, hyphenate: false)[Curvilinear grid, \ topography-conforming]),
    anchor: "west",
  )
  content(
    (x1 + 0.2, (zi + zbot) / 2),
    box(width: 4.6cm, text(lbl, hyphenate: false)[Cartesian grid, \ cheap update stencil]),
    anchor: "west",
  )
  content(
    (x0 + 0.15, zi - 0.28),
    box(fill: white, inset: (x: 2pt, y: 1.5pt), text(lbl)[Grid interface]),
    anchor: "west",
  )

  // Grid spacing annotation on the Cartesian block.
  let ax = x0 + 3 * dx
  line(
    (ax, zbot + 0.9 * dz),
    (ax + dx, zbot + 0.9 * dz),
    mark: (start: "stealth", end: "stealth"),
    stroke: (thickness: 0.5pt),
  )
  content(
    (ax + dx / 2, zbot + 0.9 * dz + 0.1),
    box(fill: white, inset: (x: 1.5pt, y: 1pt), text(lbl)[$h$]),
    anchor: "south",
  )
})
