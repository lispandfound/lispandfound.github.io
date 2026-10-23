// The Graves-Pitarka hybrid broadband method, as a pipeline and as a spectrum.
//
// Importable:
//   #import "figures/hybrid-method.typ": hybrid-pipeline, crossover-spectrum
//
// hybrid-pipeline: one kinematic rupture drives two branches. Below the
// transition frequency, a deterministic 3D finite-difference simulation through
// the velocity model; above it, a stochastic method with a 1D path and random
// phase. The Vs30-based site amplification is applied to the stochastic branch
// only (workflow/scripts/bb_sim.py), and the two are then combined with matched
// low- and high-pass filters at the transition frequency. The 3D branch gets no
// empirical site term: its site response is whatever the velocity model holds,
// drawn as its own box so the two branches mirror each other, and dashed
// because it is not a processing step: nothing is applied there.
//
// crossover-spectrum: the same split in the frequency domain. The shaded
// band between 1 and 2 Hz is what this talk moves from the stochastic side to
// the deterministic side. Shapes are schematic, not computed.

#import "@preview/cetz:0.4.2": canvas, draw
#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "../palette.typ": exact, quiet, stat

#let hybrid-pipeline = {
  set par(justify: false, first-line-indent: 0pt, leading: 0.45em)
  set text(8pt, hyphenate: false)

  let step(pos, title, sub, paint, name, width: 34mm, dash: none) = node(
    pos,
    align(center)[
      #text(weight: "bold", fill: paint)[#title] \
      #text(0.85em, fill: quiet.darken(25%))[#sub]
    ],
    width: width,
    inset: 5pt,
    stroke: (thickness: 0.9pt, paint: paint, dash: dash),
    name: name,
  )

  diagram(
    spacing: (9mm, 7mm),
    node-corner-radius: 3pt,
    edge-stroke: (thickness: 0.9pt),

    step((0, 0.5), [Kinematic rupture], [Slip, rise time, \ rupture velocity], exact, <src>, width: 30mm),
    step((1, 0), [Low frequency], [3D finite difference \ through the velocity model], stat, <lf>),
    step((1, 1), [High frequency], [Stochastic, 1D path, \ random phase], exact, <hf>),
    step((2, 0), [Site response], [From the 3D \ velocity model], stat, <lfsite>, width: 28mm, dash: "dashed"),
    step((2, 1), [Site amplification], [Empirical, \ $V_(S 30)$-based], exact, <site>, width: 28mm),
    step((3, 0.5), [Combine], [Matched filters \ at $f_t$], exact, <bb>, width: 24mm),

    edge(<src>, <lf>, "-|>"),
    edge(<src>, <hf>, "-|>"),
    edge(<hf>, <site>, "-|>"),
    edge(<lf>, <lfsite>, "-|>"),
    edge(<lfsite>, <bb>, "-|>", label: text(7.5pt)[$f < f_t$], label-side: left),
    edge(<site>, <bb>, "-|>", label: text(7.5pt)[$f > f_t$], label-side: right),
  )
}

#let crossover-spectrum = canvas(length: 1cm, {
  import draw: *

  let lbl = 9pt
  // log10 frequency from 0.05 Hz to 20 Hz onto x in [0, 9].
  let x-of(f) = (calc.log(f, base: 10) - calc.log(0.05, base: 10)) / (calc.log(20, base: 10) - calc.log(0.05, base: 10)) * 9.0
  let hgt = 3.6

  // The band this talk moves across.
  rect((x-of(1), 0), (x-of(2), hgt), fill: stat.lighten(85%), stroke: none)

  // Axes.
  line((0, 0), (9.3, 0), stroke: (thickness: 0.7pt, paint: exact), mark: (end: "stealth", fill: exact, scale: 0.5))
  line((0, 0), (0, hgt + 0.3), stroke: (thickness: 0.7pt, paint: exact), mark: (end: "stealth", fill: exact, scale: 0.5))
  for (f, t) in ((0.1, [0.1]), (1, [1]), (2, [2]), (10, [10])) {
    line((x-of(f), 0), (x-of(f), -0.1), stroke: (thickness: 0.6pt, paint: exact))
    content((x-of(f), -0.2), text(lbl)[#t], anchor: "north")
  }
  content((9.3, -0.6), text(lbl, fill: quiet.darken(20%))[Frequency (Hz)], anchor: "north-east")
  content((-0.15, hgt + 0.3), text(lbl, fill: quiet.darken(20%))[Contribution], anchor: "south-west")

  // Schematic filter responses: a smooth step down (low-pass) and up
  // (high-pass) about each transition frequency, on log frequency.
  let step(x, xt, up) = {
    let s = 1.0 / (1.0 + calc.exp(-(x - xt) * 3.2))
    if up { s } else { 1.0 - s }
  }
  let xs = range(0, 181).map(i => 9.0 * i / 180)
  let ft-old = x-of(1)
  let ft-new = x-of(2)

  // Previous: 1 Hz, drawn quiet and dashed.
  line(..xs.map(x => (x, step(x, ft-old, false) * (hgt - 0.4))), stroke: (thickness: 1pt, paint: quiet, dash: "dashed"))
  line(..xs.map(x => (x, step(x, ft-old, true) * (hgt - 0.4))), stroke: (thickness: 1pt, paint: quiet, dash: "dashed"))
  // This work: 2 Hz.
  line(..xs.map(x => (x, step(x, ft-new, false) * (hgt - 0.4))), stroke: (thickness: 1.8pt, paint: stat))
  line(..xs.map(x => (x, step(x, ft-new, true) * (hgt - 0.4))), stroke: (thickness: 1.8pt, paint: exact))

  content((0.3, hgt - 0.15), text(lbl, weight: "bold", fill: stat)[Deterministic 3D], anchor: "south-west")
  content((9.0, hgt - 0.15), text(lbl, weight: "bold", fill: exact)[Stochastic], anchor: "south-east")
  content(((ft-old + ft-new) / 2, hgt + 0.1), text(lbl - 1pt, fill: stat.darken(10%))[1 → 2 Hz], anchor: "south")
})
