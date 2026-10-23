// Order of accuracy in the rows under the free surface, previous solver
// against SW4.
//
// Importable:
//   #import "figures/accuracy-order.typ": accuracy-order
//
// Schematic. The previous solver is a staggered-grid scheme: fourth order in
// space in the interior, second order in the row next to the free surface, and
// second order in time throughout. SW4 is fourth order in space and in time.
// Its summation-by-parts boundary rows are themselves only second-order
// accurate locally -- that is true of any SBP closure -- but they are built so
// the solution as a whole still converges at fourth order, free surface
// included. So the SW4 top row is labelled "4th overall", not "4th order", to
// avoid claiming a fourth-order stencil in that row. The point of drawing it as rows is
// that the second-order row sits exactly where V_S is lowest, so where the grid
// has the fewest points per wavelength.

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": defect, exact, quiet, stat

#let accuracy-order = canvas(length: 1cm, {
  import draw: *

  let lbl = 10pt
  let rows = 6
  let dz = 0.55
  let w = 4.2
  let nx = 8

  let column(x0, title, paint, top-order, top-fill, time-order, time-paint, top-label: none) = {
    content((x0 + w / 2, 0.75), text(11pt, weight: "bold", fill: paint)[#title])
    // Row bands: order of the spatial stencil in that row.
    for r in range(0, rows) {
      let (fill, o) = if r == 0 { (top-fill, top-order) } else { (exact.lighten(90%), [4th]) }
      rect((x0, -r * dz), (x0 + w, -(r + 1) * dz), fill: fill, stroke: none)
      for i in range(0, nx + 1) {
        circle((x0 + i * w / nx, -(r + 0.5) * dz), radius: 0.045, fill: exact, stroke: none)
      }
      if r == 0 or r == 3 {
        content(
          (x0 + w + 0.15, -(r + 0.5) * dz),
          text(lbl, fill: if r == 0 { if top-order == [2nd] { defect } else { stat } } else { exact })[#if r == 0 and top-label != none { top-label } else [#o order]],
          anchor: "west",
        )
      }
    }
    line((x0, 0), (x0 + w, 0), stroke: (thickness: 1.6pt, paint: exact))
    rect((x0, -rows * dz), (x0 + w, 0), stroke: (thickness: 0.6pt, paint: exact))
    content(
      (x0 + w / 2, -rows * dz - 0.45),
      text(lbl + 1pt)[Time: #text(weight: "bold", fill: time-paint)[#time-order]],
    )
  }

  column(0, [EMOD3D], exact, [2nd], defect.lighten(70%), [2nd order], defect)
  column(6.2, [SW4], stat, [4th], stat.lighten(75%), [4th order], stat, top-label: [4th order overall])

  // Shared annotations on the left edge.
  // "Free surface" sits above the top edge and "Lowest V_S" beside the first
  // row, so the two never share a baseline.
  content((-0.2, 0.08), text(lbl)[Free surface], anchor: "south-east")
  content((-0.2, -0.5 * dz), text(lbl, fill: quiet.darken(20%))[Lowest $V_S$ →], anchor: "east")
})
