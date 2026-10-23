// Where the relaxation mechanisms live: coarse-grained against per-point.
//
// Importable:
//   #import "figures/attenuation-cells.typ": attenuation-cells
//
// Left: the coarse-grained memory-variable scheme of the previous solver. Eight
// relaxation mechanisms are spread over a 2 x 2 x 2 block of grid points, one
// mechanism per point, so the intended Q(f) is only recovered on average over
// the block. Right: SW4, where every grid point carries every mechanism (three
// here, as in our runs) and Q(f) is fitted at the point itself.
//
// Drawn as an oblique projection of a single cube so the eight corners are all
// visible without a 3D renderer.

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": exact, mechanisms, quiet, stat

#let attenuation-cells = canvas(length: 1cm, {
  import draw: *

  let lbl = 9pt
  let side = 2.6
  // Oblique projection: depth runs up and to the right.
  let p(x0, x, y, z) = (x0 + x + 0.5 * y, z + 0.38 * y)

  // Corner order is fixed so each corner keeps its mechanism colour.
  let corners = ()
  for z in (0, 1) { for y in (0, 1) { for x in (0, 1) { corners.push((x, y, z)) } } }

  let cube(x0) = {
    let edges = (
      ((0, 0, 0), (1, 0, 0)), ((0, 1, 0), (1, 1, 0)), ((0, 0, 1), (1, 0, 1)), ((0, 1, 1), (1, 1, 1)),
      ((0, 0, 0), (0, 1, 0)), ((1, 0, 0), (1, 1, 0)), ((0, 0, 1), (0, 1, 1)), ((1, 0, 1), (1, 1, 1)),
      ((0, 0, 0), (0, 0, 1)), ((1, 0, 0), (1, 0, 1)), ((0, 1, 0), (0, 1, 1)), ((1, 1, 0), (1, 1, 1)),
    )
    for (a, b) in edges {
      let back = a.at(1) == 1 and b.at(1) == 1
      line(
        p(x0, a.at(0) * side, a.at(1) * side, a.at(2) * side),
        p(x0, b.at(0) * side, b.at(1) * side, b.at(2) * side),
        stroke: (thickness: 0.7pt, paint: if back { quiet } else { exact }, dash: if back { "dashed" } else { none }),
      )
    }
  }

  // --- previous solver: one mechanism per point ---------------------------
  cube(0)
  for (m, (x, y, z)) in corners.enumerate() {
    circle(p(0, x * side, y * side, z * side), radius: 0.2, fill: mechanisms.at(m), stroke: (thickness: 0.6pt, paint: white))
  }
  content((0.5 * side + 0.25 * side, -0.75), text(11pt, weight: "bold", fill: exact)[EMOD3D])
  content((0.5 * side + 0.25 * side, -1.3), text(lbl, fill: quiet.darken(20%))[One mechanism per point, \ eight per $2 times 2 times 2$ block])

  // --- SW4: every mechanism at every point --------------------------------
  let x1 = 6.4
  cube(x1)
  for (x, y, z) in corners {
    let (cx, cy) = p(x1, x * side, y * side, z * side)
    for (m, (dx, dy)) in ((0, (-0.15, -0.09)), (1, (0.15, -0.09)), (2, (0.0, 0.16))) {
      circle((cx + dx, cy + dy), radius: 0.12, fill: mechanisms.at(m), stroke: (thickness: 0.4pt, paint: white))
    }
  }
  content((x1 + 0.75 * side, -0.75), text(11pt, weight: "bold", fill: stat)[SW4])
  content((x1 + 0.75 * side, -1.3), text(lbl, fill: quiet.darken(20%))[Every mechanism \ at every point])
})
