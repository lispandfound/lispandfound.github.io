// A decade of the group's hybrid simulations: transition frequency against
// year, validation studies and Cybershake campaigns.
//
// Importable:
//   #import "figures/study-timeline.typ": study-timeline
//
// Every h and f_t below was read from a source; the full table, with the quote
// behind each number, is in README.md under "Timeline sources". Three journal
// papers (Razafindrakoto 2018, Bradley 2017 SRL, Lee 2022) are placed from a
// group document describing the same simulations, not from the publisher text.
//
// Left out on purpose: scenario-only studies (Alpine Fault, Hope Fault,
// Hikurangi), and the Cybershake v22.4 and 2022 Hikurangi posters, whose
// printed grid spacing and transition frequency contradict each other. The two
// v17.x Cybershake versions share a marker.
//
// The y axis is log2 of f_t, because every study sits on a power of two: the
// transition frequency is V_S,min / (5 h) with V_S,min = 500 m/s throughout, so
// halving h is exactly one step up.

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": exact, quiet, stat

// (year, f_t in Hz, h label, name, label side: 1 above, -1 below, 0 right,
// 2 above-right, -2 below-right)
#let validation = (
  (2016.3, 1.0, [100 m], [Canterbury sequence], 1),
  (2017.2, 0.5, [200 m], [Kaikōura], -1),
  (2018.3, 1.0, [100 m], [Christchurch], -1),
  (2020.1, 1.0, [100 m], [Canterbury, small $M_w$], 1),
  (2021.3, 0.5, [200 m], [Moderate $M_w$ 5--7], -1),
  (2022.5, 1.0, [100 m], [NZ-wide, small $M_w$], -1),
  (2025.0, 1.0, [100 m], [Site effects], 1),
  (2025.5, 1.0, [100 m], [Subduction], -1),
)

#let cybershake = (
  (2017.8, 0.25, [400 m], [v17.8, v17.9], -1),
  (2019.4, 0.25, [400 m], [v19.5], -1),
  (2020.6, 0.5, [200 m], [v20.8, subduction], 1),
  (2025.6, 0.5, [200 m], [v25.6], -1),
)

// Work in preparation sits in its own panel to the right: shaded, separated
// from the dated axis by a gap, and with no year labels, because these are
// not yet dated. Entries are placed by their position across the panel (0 to
// 1), not by year. Markers are solid -- the panel already says "not yet
// published". All of it is supplied by Jake; move an entry into `validation` or
// `cybershake`, with its year, once it is out.
//
// The unified validation database (small, moderate and large magnitude) takes
// the validation marker.
//
// (position in panel, f_t in Hz, h label, name, label side, kind)
#let in-prep = (
  (0.16, 1.0, [100 m], [Unified \ validation \ database], -1, "validation"),
  (0.50, 1.0, [100 m], [v26], 1, "cybershake"),
  (0.84, 1.0, [100 m], [NSHM 2022 \ sources], -1, "cybershake"),
)

#let study-timeline = canvas(length: 1cm, {
  import draw: *

  let lbl = 8pt
  // Dated axis.
  let (y0, y1) = (2015.8, 2026.4)
  let wm = 13.4
  let X(t) = (t - y0) / (y1 - y0) * wm
  // The in-preparation panel, after a gap.
  let bx0 = wm + 0.5
  let bx1 = bx0 + 3.9
  let B(u) = bx0 + 0.35 + u * (bx1 - bx0 - 0.7)
  // log2(f_t): 0.25 -> 0, 0.5 -> 1, 1 -> 2, 2 -> 3.
  let rowh = 1.55
  let Y(f) = (calc.log(f, base: 2) + 2) * rowh
  let top = Y(2.0) + 0.9

  // The panel.
  rect((bx0, -0.5), (bx1, top - 0.3), fill: stat.lighten(90%), stroke: none, radius: 0.08)
  content(((bx0 + bx1) / 2, top - 0.3), text(lbl, weight: "bold", fill: stat.darken(10%))[In preparation], anchor: "south")

  // Frequency gridlines, broken at the gap so the panel reads as separate.
  for (f, t) in ((0.25, [0.25 Hz]), (0.5, [0.5 Hz]), (1.0, [1 Hz]), (2.0, [2 Hz])) {
    let st = (thickness: 0.4pt, paint: quiet.lighten(40%), dash: "dotted")
    line((0, Y(f)), (wm, Y(f)), stroke: st)
    line((bx0, Y(f)), (bx1, Y(f)), stroke: st)
    content((-0.2, Y(f)), text(lbl + 1pt, fill: if f == 2.0 { stat } else { exact })[#t], anchor: "east")
  }
  content((-0.2, top), text(lbl, fill: quiet.darken(20%))[Transition \ frequency], anchor: "north-east")

  // Year axis, under the dated part only.
  let ax = -1.35
  line((0, ax), (wm, ax), stroke: (thickness: 0.7pt, paint: exact))
  for yr in range(2016, 2027) {
    line((X(yr), ax), (X(yr), ax - 0.1), stroke: (thickness: 0.6pt, paint: exact))
    content((X(yr), ax - 0.2), text(lbl, fill: exact)[#yr], anchor: "north")
  }

  let point-label(x, y, side, name, h, paint) = content(
    (x, y + side * 0.28),
    align(center, text(lbl, fill: paint)[#name \ #text(fill: quiet.darken(20%))[#h]]),
    anchor: if side > 0 { "south" } else { "north" },
  )

  let dot(x, y) = circle((x, y), radius: 0.14, fill: exact, stroke: (thickness: 0.8pt, paint: white))
  let square(x, y) = rect((x - 0.14, y - 0.14), (x + 0.14, y + 0.14), fill: white, stroke: (thickness: 1.4pt, paint: exact))

  for (t, f, h, name, side) in validation {
    dot(X(t), Y(f))
    point-label(X(t), Y(f), side, name, h, exact)
  }
  for (t, f, h, name, side) in cybershake {
    square(X(t), Y(f))
    point-label(X(t), Y(f), side, name, h, exact)
  }
  for (u, f, h, name, side, kind) in in-prep {
    if kind == "validation" { dot(B(u), Y(f)) } else { square(B(u), Y(f)) }
    point-label(B(u), Y(f), side, name, h, exact)
  }

  // This work, in the panel at 2 Hz.
  let tx = B(0.92)
  circle((tx, Y(2.0)), radius: 0.2, fill: stat, stroke: (thickness: 0.8pt, paint: white))
  content(
    (tx - 0.35, Y(2.0)),
    align(right, text(lbl + 1pt, weight: "bold", fill: stat)[This work \ #text(weight: "regular", size: lbl)[SW4, refined grid]]),
    anchor: "east",
  )

  // Legend.
  let lx = 0.3
  let ly = top
  dot(lx, ly)
  content((lx + 0.25, ly), text(lbl)[Validation], anchor: "west")
  square(lx + 2.22, ly)
  content((lx + 2.5, ly), text(lbl)[Cybershake NZ], anchor: "west")
})
