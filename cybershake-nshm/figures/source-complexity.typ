// The trend in seismic source models: from characteristic ruptures to
// non-characteristic, multi-fault ones, and next, possibly, joint ruptures.
//
// Importable:
//   #import "figures/source-complexity.typ": source-complexity
//
// Three stages along one arrow, each a plan-view sketch over a name and the
// model it stands for. Schematic: the traces are drawn, not real faults. The
// numbers under the second stage are real (NSHM 2010 and 2022, as on the
// timeline slide); the third stage is labelled as future work on purpose.
//
//   characteristic   Schwartz & Coppersmith (1984): a fault ruptures end to end
//                    in its "characteristic" earthquake. NSHM 2010, 536 ruptures.
//   multi-fault      UCERF3 (2014), NSHM 2022: an inversion over every rupture
//                    the fault network allows; 7,162 rate-bearing in NSHM 2022.
//   joint            crustal faults rupturing together with a curved
//                    subduction interface. Not in a national model yet.
//
// Drawn at document scale and scaled up at use.

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": defect, exact, quiet, stat

#let source-complexity = canvas(length: 1cm, {
  import draw: *

  let lbl = 8pt
  let trace = (thickness: 1.4pt, paint: exact)
  let ruptured = (thickness: 2.2pt, paint: stat)
  let plane = rgb(0, 0, 0, 10)
  let W = 4.2 // width of one stage
  let gap = 1.0

  // A fault trace with its down-dip projection, in plan view.
  let fault(a, b, s: trace, depth: 0.45) = {
    let dx = b.at(0) - a.at(0)
    let dy = b.at(1) - a.at(1)
    let n = calc.sqrt(dx * dx + dy * dy)
    let (nx, ny) = (dy / n * depth, -dx / n * depth)
    line(
      a,
      b,
      (b.at(0) + nx, b.at(1) + ny),
      (a.at(0) + nx, a.at(1) + ny),
      close: true,
      fill: plane,
      stroke: (thickness: 0.3pt, paint: quiet.lighten(30%)),
    )
    line(a, b, stroke: s)
  }

  let caption(x, title, model) = {
    content(
      (x + W / 2, -0.55),
      text(lbl + 1.5pt, weight: "bold", fill: exact)[#title],
      anchor: "north",
    )
    content(
      (x + W / 2, -1.1),
      text(lbl, fill: stat.darken(10%))[#model],
      anchor: "north",
    )
  }

  // --- 1. characteristic: one fault, one rupture -----------------------------
  let x1 = 0.0
  fault((x1 + 0.4, 1.0), (x1 + 3.8, 1.9), s: ruptured)
  fault((x1 + 0.9, 2.9), (x1 + 3.2, 3.3))
  caption(x1, [Characteristic], [Schwartz & Coppersmith 1984 · NSHM 2010])

  // --- 2. multi-fault: segments linked across gaps, branching ----------------
  let x2 = W + gap
  fault((x2 + 0.1, 1.2), (x2 + 1.3, 1.55), s: ruptured)
  fault((x2 + 1.5, 1.7), (x2 + 2.7, 1.75), s: ruptured)
  fault((x2 + 2.9, 1.9), (x2 + 4.0, 2.7), s: ruptured)
  fault((x2 + 2.6, 1.35), (x2 + 3.6, 0.55))
  fault((x2 + 0.6, 3.0), (x2 + 2.2, 3.4), s: ruptured)
  fault((x2 + 2.4, 3.45), (x2 + 3.4, 3.3))
  caption(x2, [Multi-fault], [UCERF3 · NSHM 2022])

  // --- 3. joint: crustal faults with a curved interface ----------------------
  let x3 = 2 * (W + gap)
  // the interface, curved in plan view, with depth contours
  for (k, c) in ((0, 0.0), (1, 0.55), (2, 1.1)) {
    bezier(
      (x3 + 0.3 + c, 0.4),
      (x3 + 1.4 + c, 3.6),
      (x3 + 0.2 + c, 1.6),
      (x3 + 1.6 + c, 2.4),
      stroke: (
        thickness: if k == 0 { 1.4pt } else { 0.4pt },
        paint: if k == 0 { stat } else {
          stat.lighten(40%)
        },
        dash: if k == 0 { none } else { "dashed" },
      ),
    )
  }
  fault((x3 + 2.3, 1.1), (x3 + 3.3, 2.0), s: ruptured)
  fault((x3 + 3.4, 2.15), (x3 + 4.1, 3.2), s: ruptured)
  caption(x3, [Joint], [future models?])

  // --- the trend --------------------------------------------------------------
  line(
    (0.2, 4.15),
    (3 * W + 2 * gap - 0.2, 4.15),
    mark: (end: "stealth", fill: quiet.darken(20%)),
    stroke: (thickness: 1pt, paint: quiet.darken(20%)),
  )
  content(
    (3 * W / 2 + gap, 4.3),
    text(lbl, fill: quiet.darken(25%), style: "italic")[
      increasing source complexity over time to reflect understanding of rupture dynamics
    ],
    anchor: "south",
  )
})
