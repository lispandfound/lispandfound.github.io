// The magnitude-only sampling rule, and the two ruptures it cannot tell apart.
//
// Importable, and built in two stages:
//   #import "figures/magnitude-blind.typ": magnitude-blind
//   magnitude-blind(pair: false)   // the rule alone
//   magnitude-blind(pair: true)    // the rule, and what it cannot see
//
// Forked from ~/Documents/phd-proposal/Figures/magnitude-sampling.typ, which draws
// the New Zealand Cybershake rule
//
//   N(Mw) = 14              for Mw < 6.0
//           27 Mw - 148     for 6.0 <= Mw <= 8.0
//           68              for Mw > 8.0
//
// The addition here is the pair. Both ruptures sit ABOVE the upper breakpoint, so
// both land on the same plateau, and at 0.026 apart in magnitude they are one
// point on this curve -- which is exactly the argument.
//
// Stage one is drawn with the pair `hide`n rather than omitted, and `hide` is
// called with `bounds: true`, so the hidden elements still occupy their space.
// The two stages therefore have identical extents and the axes do not move under
// the audience when the second stage appears -- which is the point of staging it:
// the rule has to be visibly the same rule before and after.
//
// Verified against data/ruptures.parquet (Leonard 2014 magnitudes, as used by the
// pipeline -- NOT the pilot CSV's magnitudes, which sit ~0.17 lower):
//   41065  Mw 8.199  rate 3.389e-05  1 in   29,510 yr  20,630 core-h
//   90894  Mw 8.225  rate 3.099e-07  1 in 3,226,515 yr  34,706 core-h

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": defect, exact, perf, quiet, stat

#let magnitude-blind(pair: true) = canvas(length: 1cm, {
  import draw: *

  set-style(
    stroke: (thickness: 0.5pt),
    mark: (fill: black, scale: 0.4),
    content: (padding: 0.1),
  )
  let lbl = 7pt

  let lo = 6.0
  let hi = 8.0
  let n-lo = 14
  let n-hi = 68

  let m-min = 5.5
  let m-max = 9.7
  let n-max = 80

  let W = 8.4
  let H = 4.2
  let px(m) = (m - m-min) / (m-max - m-min) * W
  let py(n) = n / n-max * H

  let dotted = (thickness: 0.4pt, dash: "dotted", paint: quiet)

  // --- axes ------------------------------------------------------------------
  line((0, 0), (W + 0.35, 0), mark: (end: "stealth"))
  line((0, 0), (0, H + 0.35), mark: (end: "stealth"))
  content((W / 2, -0.72), text(lbl)[moment magnitude $M_w$], anchor: "north")
  content(
    (-0.82, H / 2),
    text(lbl)[realisations per rupture, $N$],
    anchor: "south",
    angle: 90deg,
  )
  for m in (6, 7, 8, 9) {
    line((px(m), 0), (px(m), -0.12))
    content((px(m), -0.20), text(lbl)[#m], anchor: "north")
  }

  // --- the rule --------------------------------------------------------------
  for (m, n) in ((lo, n-lo), (hi, n-hi)) {
    line((0, py(n)), (px(m), py(n)), stroke: dotted)
    line((px(m), 0), (px(m), py(n)), stroke: dotted)
    line((-0.12, py(n)), (0, py(n)))
    content((-0.18, py(n)), text(lbl)[#n], anchor: "east")
  }
  line(
    (px(m-min), py(n-lo)),
    (px(lo), py(n-lo)),
    (px(hi), py(n-hi)),
    (px(m-max), py(n-hi)),
    stroke: (thickness: 1.3pt, paint: exact),
  )
  circle((px(lo), py(n-lo)), radius: 0.07, fill: exact, stroke: none)
  circle((px(hi), py(n-hi)), radius: 0.07, fill: exact, stroke: none)
  content(
    (px(6.05), py(56)),
    text(lbl, fill: exact)[$N = 27 M_w - 148$],
    anchor: "south-west",
  )

  // --- stage two: what the rule cannot see -----------------------------------
  let mx = px(8.21)
  let my = py(68)

  // Card geometry, and the bracket that feeds both cards.
  //
  // The cards are fed from a spine rather than by one straight leader each.
  // Card A sits directly between the marker and card B, so ANY straight leader
  // to B crosses A -- and, drawn second, it crosses on top and strikes through
  // A's text. A spine sidesteps the geometry entirely: one line down from the
  // marker, then a short stub into each card's left edge. Nothing can overlap.
  let cw = 3.55
  let ch = 1.24
  let cx = 5.98 // card left edge, clear of the spine
  let cy-a = 2.58
  let cy-b = 1.00
  let spine = 5.66 // between the marker and the cards

  let card(cy, col, id, mw, ret, cost, who) = {
    rect(
      (cx, cy - ch / 2),
      (cx + cw, cy + ch / 2),
      fill: col.lighten(90%),
      stroke: (thickness: 0.6pt, paint: col),
      radius: 0.06,
    )
    content(
      (cx + 0.14, cy + ch / 2 - 0.16),
      text(lbl, weight: "bold", fill: col.darken(15%))[#id],
      anchor: "north-west",
    )
    content(
      (cx + cw - 0.14, cy + ch / 2 - 0.16),
      text(lbl, fill: col.darken(15%))[$M_w$ #mw],
      anchor: "north-east",
    )
    content(
      (cx + 0.14, cy + ch / 2 - 0.52),
      text(lbl - 0.8pt, fill: quiet.darken(35%))[#who],
      anchor: "north-west",
    )
    content(
      (cx + 0.14, cy - ch / 2 + 0.14),
      text(lbl, weight: "bold")[#ret],
      anchor: "south-west",
    )
    content(
      (cx + cw - 0.14, cy - ch / 2 + 0.14),
      text(lbl, fill: quiet.darken(35%))[#cost],
      anchor: "south-east",
    )
  }

  let hair = (thickness: 0.5pt, paint: quiet)
  let stage-two = {
    circle(
      (mx, my),
      radius: 0.15,
      fill: stat,
      stroke: (thickness: 0.9pt, paint: white),
    )
    line((mx, my - 0.16), (spine, cy-a), stroke: hair)
    line((spine, cy-a), (spine, cy-b), stroke: hair)
    line((spine, cy-a), (cx, cy-a), stroke: hair)
    line((spine, cy-b), (cx, cy-b), stroke: hair)
    card(
      cy-a,
      perf,
      [41065],
      [8.20],
      [1 in 30 kyr],
      [20,600 core-h],
      [Alpine: Caswell -- Resolution],
    )
    card(
      cy-b,
      defect,
      [90894],
      [8.23],
      [1 in 3.2 Myr],
      [34,700 core-h],
      [Ohariu + Mohaka + Wellington],
    )
  }

  if pair { stage-two } else { hide(stage-two, bounds: true) }
})
