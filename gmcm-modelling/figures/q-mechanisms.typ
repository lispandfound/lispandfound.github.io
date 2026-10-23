// What a relaxation mechanism is, and why several of them make a constant Q.
//
// Importable:
//   #import "figures/q-mechanisms.typ": rheology, absorption-band
//
// rheology: the material as springs and dashpots. One spring carries the
// unrelaxed elastic response; each mechanism is a spring in series with a
// dashpot, all in parallel. A dashpot resists the rate of deformation, so each
// arm relaxes stress on its own timescale and turns a little of every cycle's
// strain energy into heat. The arm colours match the mechanism colours in
// attenuation-cells.typ, so the next slide reads as "where these arms live".
//
// absorption-band: 1/Q against log frequency. One mechanism absorbs in a
// single Debye peak centred on its relaxation frequency; three peaks spread a
// decade or so apart sum to a nearly flat 1/Q across the band -- the
// frequency-independent Q that observations support. Curves are computed from
// the Debye form omega tau / (1 + (omega tau)^2) with equal weights; the band
// edges are schematic.

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": exact, mechanisms, quiet, stat

#let rheology = canvas(length: 1cm, {
  import draw: *

  let lbl = 9pt
  let top = 3.4
  let bot = 0.0

  let spring(x, y0, y1, paint) = {
    let n = 6
    let a = 0.18
    let lead = 0.2
    let pts = ((x, y0), (x, y0 + lead))
    let seg = (y1 - y0 - 2 * lead) / n
    for i in range(0, n) {
      let s = if calc.rem(i, 2) == 0 { a } else { -a }
      pts.push((x + s, y0 + lead + (i + 0.5) * seg))
    }
    pts.push((x, y1 - lead))
    pts.push((x, y1))
    line(..pts, stroke: (thickness: 1pt, paint: paint))
  }

  let dashpot(x, y0, y1, paint) = {
    let mid = (y0 + y1) / 2
    // Cylinder (open at the top) and piston.
    line((x, y0), (x, mid - 0.35), stroke: (thickness: 1pt, paint: paint))
    line((x - 0.25, mid + 0.25), (x - 0.25, mid - 0.35), (x + 0.25, mid - 0.35), (x + 0.25, mid + 0.25), stroke: (thickness: 1pt, paint: paint))
    line((x - 0.17, mid), (x + 0.17, mid), stroke: (thickness: 1.4pt, paint: paint))
    line((x, mid), (x, y1), stroke: (thickness: 1pt, paint: paint))
  }

  // Plates.
  let x0 = -0.4
  let x1 = 4.4
  rect((x0, top), (x1, top + 0.15), fill: exact, stroke: none)
  rect((x0, bot - 0.15), (x1, bot), fill: exact, stroke: none)

  // The elastic arm.
  spring(0.2, bot, top, exact)
  content((0.2, bot - 0.45), text(lbl, fill: exact)[Elastic], anchor: "north")

  // Three mechanism arms: spring in series with dashpot.
  for (i, x) in (1.6, 2.7, 3.8).enumerate() {
    let paint = mechanisms.at(i)
    spring(x, top - 1.5, top, paint)
    dashpot(x, bot, top - 1.5, paint)
  }
  content((2.7, bot - 0.45), text(lbl, fill: exact)[Relaxation mechanisms], anchor: "north")

  // Load arrows.
  line((2.0, top + 0.95), (2.0, top + 0.25), stroke: (thickness: 1pt, paint: quiet), mark: (end: "stealth", fill: quiet, scale: 0.5))
  content((2.15, top + 0.6), text(lbl, fill: quiet.darken(20%))[Stress], anchor: "west")
})

#let absorption-band = canvas(length: 1cm, {
  import draw: *

  let lbl = 9pt
  // x is log10 of frequency relative to the band centre, from -2.5 to 2.5.
  let (xa, xb) = (-2.5, 2.5)
  let w = 8.0
  let hgt = 3.2
  let X(x) = (x - xa) / (xb - xa) * w
  let centres = (-1.0, 0.0, 1.0)
  let debye(x, c) = {
    let r = calc.pow(10.0, x - c)
    2.0 * r / (1.0 + r * r)
  }
  let xs = range(0, 201).map(i => xa + (xb - xa) * i / 200)
  let total(x) = centres.map(c => debye(x, c)).sum()
  let peak = calc.max(..xs.map(total))
  let Y(v) = v / peak * (hgt - 0.5)

  // The band the mechanisms are fitted over.
  rect((X(-1.0), 0), (X(1.0), hgt), fill: stat.lighten(88%), stroke: none)
  content((X(0), hgt + 0.05), text(lbl - 1pt, fill: stat.darken(10%))[Fitted band], anchor: "south")

  // Axes.
  line((0, 0), (w + 0.3, 0), stroke: (thickness: 0.7pt, paint: exact), mark: (end: "stealth", fill: exact, scale: 0.5))
  line((0, 0), (0, hgt + 0.3), stroke: (thickness: 0.7pt, paint: exact), mark: (end: "stealth", fill: exact, scale: 0.5))
  content((w + 0.3, -0.25), text(lbl, fill: quiet.darken(20%))[$log f$], anchor: "north-east")
  content((-0.15, hgt + 0.3), text(lbl, fill: quiet.darken(20%))[$1 \/ Q$], anchor: "south-west")

  // One Debye peak per mechanism.
  for (i, c) in centres.enumerate() {
    line(..xs.map(x => (X(x), Y(debye(x, c)))), stroke: (thickness: 1.1pt, paint: mechanisms.at(i)))
  }
  // Their sum: nearly flat over the band.
  line(..xs.map(x => (X(x), Y(total(x)))), stroke: (thickness: 2pt, paint: exact))
  content((X(1.9), Y(total(1.9)) + 0.15), text(lbl, weight: "bold", fill: exact)[Sum], anchor: "south-west")
})
