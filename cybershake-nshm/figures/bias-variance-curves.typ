// Why bias reduction and variance reduction are not the same ruptures.
//
// Importable:
//   #import "figures/bias-variance-curves.typ": bias-variance-curves
//
// Both quantities come from the same empirical model, and both are per-rupture,
// but they weight a rupture by different functions of its exceedance
// probability P = P(IM > im | rupture, site):
//
//   contribution to hazard    h_i = lambda_i P                  rises to P = 1
//   contribution to variance  s_i = lambda_i sqrt(P (1 - P))    peaks at P = 0.5
//
// Divided through by the rate they are just P and sqrt(P(1-P)), which is what is
// drawn -- the shapes are the whole argument and the rate only scales them.
//
// The reading:
//   * a rupture that nearly always exceeds carries a lot of hazard and almost no
//     uncertainty. You know the answer. Simulate it ONCE, or it lands in the
//     unsampled sum and becomes bias.
//   * a rupture on the fence carries the uncertainty. Simulate it REPEATEDLY.
//
// So bias is a question about coverage and variance is a question about
// replication, and a single allocation cannot be optimal for both. That is the
// dial the logic tree exposes.
//
// s_i is exactly `_variance_reduction_density` in sampling_strategies.py:83-87,
// which forms sqrt(rate*hazard - hazard^2) -- algebraically lambda sqrt(P(1-P)).

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": defect, exact, perf, quiet, stat

#let bias-variance-curves = canvas(length: 1cm, {
  import draw: *

  set-style(
    stroke: (thickness: 0.5pt),
    mark: (fill: black, scale: 0.35),
    content: (padding: 0.09),
  )
  let lbl = 7pt

  let W = 6.4
  let H = 3.5
  let px(p) = p * W
  let py(v) = v * H

  let n = 120
  let curve(f) = range(0, n + 1).map(i => {
    let p = i / n
    (px(p), py(f(p)))
  })

  // --- axes ------------------------------------------------------------------
  line((0, 0), (W + 0.3, 0), mark: (end: "stealth"))
  line((0, 0), (0, H + 0.3), mark: (end: "stealth"))
  content(
    (W / 2, -0.66),
    text(lbl)[exceedance probability $P(op("IM") > op("im") | "rupture")$],
    anchor: "north",
  )
  for p in (0.0, 0.5, 1.0) {
    line((px(p), 0), (px(p), -0.11))
    content((px(p), -0.19), text(lbl, fill: quiet.darken(20%))[#p], anchor: "north")
  }

  // The y axis is NOT "hazard contribution": that is true of the red curve only,
  // and the orange one is a contribution to the estimator's variance. What the
  // two share is that both are per-rupture contributions with the rate divided
  // out, which is what puts them on a common 0-1 scale and lets the shapes be
  // compared at all.
  for v in (0.0, 0.5, 1.0) {
    line((0, py(v)), (-0.11, py(v)))
    content((-0.19, py(v)), text(lbl, fill: quiet.darken(20%))[#v], anchor: "east")
  }
  content(
    (-0.92, H / 2),
    text(lbl)[contribution per rupture $div lambda$],
    anchor: "south",
    angle: 90deg,
  )
  line((px(0.5), 0), (px(0.5), py(0.5)), stroke: (
    thickness: 0.4pt,
    dash: "dotted",
    paint: quiet,
  ))

  // --- the two weightings ----------------------------------------------------
  line(..curve(p => p), stroke: (thickness: 1.5pt, paint: defect))
  line(..curve(p => calc.sqrt(p * (1 - p))), stroke: (
    thickness: 1.5pt,
    paint: stat,
  ))

  // Both labels sit in the upper-left, which is the one region free of both
  // curves: above the arch's left flank and above the hazard line, which is
  // still low there. Anything placed mid-plot gets crossed by one or the other.
  content(
    (px(0.04), py(0.93)),
    text(lbl, weight: "bold", fill: defect.darken(10%))[
      hazard #h(0.3em) $lambda P$
    ],
    anchor: "west",
  )
  content(
    (px(0.04), py(0.77)),
    text(lbl, weight: "bold", fill: stat.darken(12%))[
      variance #h(0.3em) $lambda sqrt(P (1 - P))$
    ],
    anchor: "west",
  )

  // Two markers, no captions. What they mean -- simulate the near-certain one
  // once so it does not fall into the unsampled sum, replicate the one on the
  // fence -- is said, not written.
  circle((px(0.97), py(0.97)), radius: 0.09, fill: defect, stroke: none)
  circle((px(0.5), py(0.5)), radius: 0.09, fill: stat, stroke: none)
})
