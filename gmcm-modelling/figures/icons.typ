// Small pictograms for the two "three changes" overview slides, one per
// change. Each is a cetz canvas of about 4 x 3 units, drawn without text where
// the shape can carry the idea, so the panel title does the naming.
//
// Importable:
//   #import "figures/icons.typ": icon-refine, icon-order, icon-topo, icon-atten,
//     icon-layers, icon-blend, icon-backus

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": defect, exact, mechanisms, quiet, sediment, stat

#let thin = (thickness: 0.4pt, paint: quiet)

// --- SW4 --------------------------------------------------------------------

// Grid spacing doubling with depth.
#let icon-refine = canvas(length: 1cm, {
  import draw: *
  let w = 4.0
  let blocks = ((0.0, -0.8, 0.2), (-0.8, -1.6, 0.4), (-1.6, -2.8, 0.8))
  for (top, bot, h) in blocks {
    for i in range(0, int(calc.round(w / h)) + 1) {
      line((i * h, top), (i * h, bot), stroke: thin)
    }
    for j in range(0, int(calc.round((top - bot) / h)) + 1) {
      line((0, top - j * h), (w, top - j * h), stroke: thin)
    }
    line((0, bot), (w, bot), stroke: (thickness: 0.8pt, paint: exact))
  }
  line((0, 0), (w, 0), stroke: (thickness: 1.4pt, paint: stat))
  rect((0, -2.8), (w, 0), stroke: (thickness: 0.8pt, paint: exact))
})

// Error against grid spacing on log axes: slope 2 against slope 4.
#let icon-order = canvas(length: 1cm, {
  import draw: *
  let ax = (thickness: 0.8pt, paint: exact)
  line((0, 0), (4.0, 0), stroke: ax, mark: (end: "stealth", fill: exact, scale: 0.5))
  line((0, 0), (0, 2.9), stroke: ax, mark: (end: "stealth", fill: exact, scale: 0.5))
  content((4.0, -0.25), text(9pt, fill: quiet.darken(20%))[$log h$], anchor: "north-east")
  content((-0.15, 2.9), text(9pt, fill: quiet.darken(20%))[$log "error"$], anchor: "north-east")
  // Both lines meet at the coarse end, so the gap opens as h shrinks.
  // Labels sit clear of the y-axis, at the fine (left) end of each line.
  line((1.0, 2.6 - 0.35 * 2.7), (3.7, 2.6), stroke: (thickness: 1.4pt, paint: quiet))
  line((1.0, 2.6 - 0.7 * 2.7), (3.7, 2.6), stroke: (thickness: 1.8pt, paint: stat))
  content((0.9, 2.6 - 0.35 * 2.7), text(9pt, fill: quiet.darken(20%))[2nd], anchor: "east")
  content((0.9, 2.6 - 0.7 * 2.7), text(9pt, weight: "bold", fill: stat)[4th], anchor: "east")
})

// A grid whose top rows bend to follow the ground surface, flattening with
// depth into the Cartesian block below.
#let icon-topo = canvas(length: 1cm, {
  import draw: *
  let w = 4.0
  let surf(x) = 0.45 * calc.exp(-calc.pow((x - 1.2) / 0.6, 2)) + 0.3 * calc.exp(-calc.pow((x - 2.9) / 0.5, 2))
  let n = 40
  let xs = range(0, n + 1).map(i => w * i / n)
  let rows = 5
  let base = -1.4
  for r in range(0, rows + 1) {
    let f = 1 - r / rows
    line(..xs.map(x => (x, f * surf(x) + (1 - f) * base + f * 0)), stroke: if r == 0 { (thickness: 1.4pt, paint: stat) } else { thin })
  }
  for i in range(0, 9) {
    let x = w * i / 8
    line((x, surf(x)), (x, -2.8), stroke: thin)
  }
  for j in range(1, 4) {
    line((0, base - j * 0.35), (w, base - j * 0.35), stroke: thin)
  }
  line((0, base), (w, base), stroke: (thickness: 0.8pt, paint: exact))
  line((0, -2.8), (w, -2.8), stroke: (thickness: 0.8pt, paint: exact))
  line((0, 0), (0, -2.8), stroke: (thickness: 0.8pt, paint: exact))
  line((w, 0), (w, -2.8), stroke: (thickness: 0.8pt, paint: exact))
})

// Every grid point carries every relaxation mechanism.
#let icon-atten = canvas(length: 1cm, {
  import draw: *
  let n = 4
  let s = 1.0
  for i in range(0, n) {
    line((i * s, 0), (i * s, -(n - 1) * s), stroke: thin)
    line((0, -i * s), ((n - 1) * s, -i * s), stroke: thin)
  }
  for i in range(0, n) {
    for j in range(0, n) {
      let (x, y) = (i * s, -j * s)
      for (m, (dx, dy)) in ((0, (-0.13, -0.08)), (1, (0.13, -0.08)), (2, (0.0, 0.14))).map(
        p => p,
      ) {
        circle((x + dx, y + dy), radius: 0.1, fill: mechanisms.at(m), stroke: none)
      }
    }
  }
})

// --- NZCVM ------------------------------------------------------------------

// A stack of layers with one sliding in from the side.
#let icon-layers = canvas(length: 1cm, {
  import draw: *
  let bar(y, fill, paint, dash: none) = rect(
    (0, y),
    (3.2, y + 0.5),
    radius: 0.08,
    fill: fill,
    stroke: (thickness: 0.8pt, paint: paint, dash: dash),
  )
  bar(0.0, exact.lighten(80%), exact)
  bar(0.7, exact.lighten(80%), exact)
  bar(1.4, none, quiet, dash: "dashed")
  bar(2.1, exact.lighten(80%), exact)
  // The new layer, on its way in.
  rect((4.0, 1.4), (7.2, 1.9), radius: 0.08, fill: stat.lighten(70%), stroke: (thickness: 1pt, paint: stat))
  line((3.9, 1.65), (3.35, 1.65), stroke: (thickness: 1.2pt, paint: stat), mark: (end: "stealth", fill: stat, scale: 0.6))
})

// A meshed tomography block with a meshed basin laid over it.
#let icon-blend = canvas(length: 1cm, {
  import draw: *
  let (w, hgt) = (4.4, 2.8)
  // Triangulated background: a lattice with one diagonal per cell.
  let s = 0.55
  let nx = int(calc.round(w / s))
  let ny = int(calc.round(hgt / s))
  for i in range(0, nx + 1) { line((i * s, 0), (i * s, -hgt), stroke: thin) }
  for j in range(0, ny + 1) { line((0, -j * s), (w, -j * s), stroke: thin) }
  for i in range(0, nx) {
    for j in range(0, ny) {
      line((i * s, -j * s), ((i + 1) * s, -(j + 1) * s), stroke: thin)
    }
  }
  // The basin, over it.
  let basin(x) = -1.5 * calc.exp(-calc.pow((x - 2.6) / 1.1, 4))
  let xs = range(0, 61).map(i => 0.8 + 3.6 * i / 60)
  let pts = xs.filter(x => basin(x) < -0.03).map(x => (x, basin(x)))
  line(..pts, close: true, fill: sediment.transparentize(15%), stroke: (thickness: 1pt, paint: stat))
  rect((0, -hgt), (w, 0), stroke: (thickness: 0.8pt, paint: exact))
  // Priority badges: lower number wins.
  let badge(pos, body, paint) = {
    circle(pos, radius: 0.32, fill: white, stroke: (thickness: 0.9pt, paint: paint))
    content(pos, text(8pt, weight: "bold", fill: paint)[#body])
  }
  badge((0.55, -2.25), [255], exact)
  badge((2.6, -0.65), [0], stat)
})

// A layered cell, point-sampled, collapsing to one effective cell.
#let icon-backus = canvas(length: 1cm, {
  import draw: *
  let (w, hgt) = (1.3, 2.8)
  let n = 7
  for k in range(0, n) {
    let fill = if calc.rem(k, 2) == 0 { exact.lighten(55%) } else { exact.lighten(88%) }
    rect((0, -k * hgt / n), (w, -(k + 1) * hgt / n), fill: fill, stroke: none)
  }
  rect((0, -hgt), (w, 0), stroke: (thickness: 0.8pt, paint: exact))
  for k in range(0, n) {
    circle((w / 2, -(k + 0.5) * hgt / n), radius: 0.07, fill: stat, stroke: none)
  }
  line((w + 0.35, -hgt / 2), (w + 1.35, -hgt / 2), stroke: (thickness: 1.2pt, paint: stat), mark: (end: "stealth", fill: stat, scale: 0.6))
  rect((w + 1.7, -hgt), (2 * w + 1.7, 0), fill: exact.lighten(70%), stroke: (thickness: 0.8pt, paint: exact))
  content((w + 1.7 + w / 2, -hgt / 2), text(11pt, fill: exact)[$mu_"eff"$])
})
