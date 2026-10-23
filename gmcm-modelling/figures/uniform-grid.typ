// The previous Cybershake NZ discretisation: one grid spacing everywhere, and a
// flat free surface.
//
// Importable:
//   #import "figures/uniform-grid.typ": uniform-grid
//
// Schematic, not to scale. The point is the two compromises side by side: the
// spacing that the basin sediments need is paid for all the way to the base of
// the model, and the real topography (dashed) is not in the model at all -- the
// grid starts at a flat z = 0.

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": defect, exact, quiet, sediment

// A label that sits on grid lines, on a knock-out box in the local background.
#let knockout(fill, body) = box(fill: fill, inset: (x: 2pt, y: 1.5pt), body)

#let uniform-grid = canvas(length: 1cm, {
  import draw: *

  let lbl = 8pt
  let x0 = 0.0
  let x1 = 12.0
  let zbot = -5.0
  let h = 0.5

  // Topography the model cannot see.
  let topo(x) = (
    0.9 * calc.exp(-calc.pow((x - 2.4) / 1.2, 2))
      + 0.5 * calc.exp(-calc.pow((x - 4.6) / 0.8, 2))
      + 0.15 * calc.exp(-calc.pow((x - 10.5) / 1.5, 2))
  )
  // Basin floor, below the flat surface.
  let basin(x) = -1.6 * calc.exp(-calc.pow((x - 8.0) / 1.5, 4))

  let fine = 120
  let xs = range(0, fine + 1).map(i => x0 + (x1 - x0) * i / fine)

  // Sediment.
  line(
    ..xs.filter(x => basin(x) < -0.02).map(x => (x, basin(x))),
    close: true,
    fill: sediment,
    stroke: none,
  )

  // One spacing, everywhere.
  for i in range(0, int((x1 - x0) / h) + 1) {
    let x = x0 + i * h
    line((x, 0), (x, zbot), stroke: (thickness: 0.3pt, paint: quiet))
  }
  for j in range(0, int(-zbot / h) + 1) {
    let z = -j * h
    line((x0, z), (x1, z), stroke: (thickness: 0.3pt, paint: quiet))
  }

  // Basin outline over the grid.
  line(
    ..xs.filter(x => basin(x) < -0.02).map(x => (x, basin(x))),
    stroke: (thickness: 0.8pt, paint: exact),
  )

  // The flat free surface, and the topography it replaces.
  line((x0, 0), (x1, 0), stroke: (thickness: 1.2pt, paint: exact))
  line(
    ..xs.map(x => (x, topo(x))),
    stroke: (thickness: 1pt, paint: defect, dash: "dashed"),
  )
  rect((x0, zbot), (x1, 0), stroke: (thickness: 0.6pt, paint: exact))

  // --- labels --------------------------------------------------------------
  content(
    (3.4, 1.25),
    text(lbl, fill: defect)[True topography, not in the model],
    anchor: "south",
  )
  content(
    (8.0, -0.8),
    knockout(sediment, text(lbl, fill: exact)[Sediments, low $V_S$]),
  )

  // Spacing annotation, deep in the model where it is not needed.
  let ax = 2.0
  let az = zbot + 0.5 * h
  line(
    (ax, az),
    (ax + h, az),
    mark: (start: "stealth", end: "stealth", fill: exact, scale: 0.4),
    stroke: (thickness: 0.6pt, paint: exact),
  )
  content((ax + h + 0.15, az), knockout(white, text(lbl)[$h$, set by the lowest $V_S$]), anchor: "west")

  content((x1 + 0.2, 0), text(lbl)[$z = 0$], anchor: "west")
  content((x1 + 0.2, zbot), text(lbl, fill: quiet.darken(20%))[Base of model], anchor: "west")
})
