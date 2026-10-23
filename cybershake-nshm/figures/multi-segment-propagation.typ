// Heuristic rupture propagation over a multi-segment source, in plan view.
//
// Importable:
//   #import "figures/multi-segment-propagation.typ": multi-segment-propagation
//   #figure(fit-to-width(multi-segment-propagation), caption: [...])
//
// What the figure has to show:
//   1. an NSHM multi-segment rupture is a set of disjoint planar segments, not
//      a single connected plane, and it may branch;
//   2. the algorithm links them into a tree rooted at the hypocentre, using
//      endpoint proximity and strike continuity, so the traversal order and the
//      entry point of every segment are derived rather than hand-specified;
//   3. each segment enters the kinematic rupture generator with an entry time
//      t_k carried across the jump, which is what keeps rupture onset time
//      continuous over the whole source.
//
// Drawn at document scale and scaled up at use.

#import "@preview/cetz:0.4.2": canvas, draw

#let multi-segment-propagation = canvas(length: 1cm, {
  import draw: *

  set-style(
    stroke: (thickness: 0.5pt),
    mark: (fill: black, scale: 0.4),
    content: (padding: 0.1),
  )
  let lbl = 9pt

  // Surface traces: (start, end). Segment 4 branches off segment 2.
  let segs = (
    ((0.0, 0.4), (3.0, 1.1)),
    ((3.45, 1.25), (6.5, 1.25)),
    ((6.95, 1.4), (9.1, 3.0)),
    ((6.1, 0.35), (8.0, -1.05)),
  )
  let dip-width = 0.8 // plan-view extent of the down-dip projection

  let unit(a, b) = {
    let dx = b.at(0) - a.at(0)
    let dy = b.at(1) - a.at(1)
    let n = calc.sqrt(dx * dx + dy * dy)
    (dx / n, dy / n)
  }
  let add(p, v, s) = (p.at(0) + s * v.at(0), p.at(1) + s * v.at(1))
  let along(a, b, s) = add(a, unit(a, b), s)

  // --- fault planes, in plan view -------------------------------------------
  for (a, b) in segs {
    let u = unit(a, b)
    let n = (u.at(1), -u.at(0)) // dip direction, right of strike
    line(
      a,
      b,
      add(b, n, dip-width),
      add(a, n, dip-width),
      close: true,
      fill: rgb(0, 0, 0, 8),
      stroke: (thickness: 0.4pt, paint: gray),
    )
    line(a, b, stroke: (thickness: 1.3pt)) // surface trace
  }

  // --- propagation along each segment ---------------------------------------
  // Arrows sit just off the trace, on the side away from the fault plane.
  let prop-arrow(a, b, from, to) = {
    let u = unit(a, b)
    let n = (-u.at(1), u.at(0))
    line(
      add(along(a, b, from), n, 0.28),
      add(along(a, b, to), n, 0.28),
      mark: (end: "stealth"),
      stroke: (thickness: 0.8pt),
    )
  }

  let hypo = (5.0, 1.25) // on segment 2

  // Segment 2 ruptures bilaterally from the hypocentre.
  prop-arrow(hypo, segs.at(1).at(0), 0.25, 1.35)
  prop-arrow(hypo, segs.at(1).at(1), 0.25, 1.3)
  prop-arrow(segs.at(0).at(1), segs.at(0).at(0), 0.3, 2.6)
  prop-arrow(segs.at(2).at(0), segs.at(2).at(1), 0.3, 2.0)
  prop-arrow(segs.at(3).at(0), segs.at(3).at(1), 0.3, 2.0)

  // --- jumps between segments ------------------------------------------------
  let jump(p, q, label-body, anchor) = {
    line(
      p,
      q,
      mark: (end: "stealth"),
      stroke: (thickness: 0.7pt, dash: "dashed", paint: rgb("#B03A2E")),
    )
    circle(p, radius: 0.075, fill: rgb("#B03A2E"), stroke: none)
    circle(q, radius: 0.075, fill: rgb("#B03A2E"), stroke: none)
    content(
      ((p.at(0) + q.at(0)) / 2, (p.at(1) + q.at(1)) / 2),
      text(lbl, fill: rgb("#B03A2E"))[#label-body],
      anchor: anchor,
    )
  }

  jump(segs.at(1).at(0), segs.at(0).at(1), $t_1$, "south-east")
  jump(segs.at(1).at(1), segs.at(2).at(0), $t_3$, "south-west")
  jump((6.05, 1.25), segs.at(3).at(0), $t_4$, "west")

  // --- hypocentre -------------------------------------------------------------
  let star(c, r) = {
    let pts = range(0, 10).map(i => {
      let ang = 90deg - i * 36deg
      let rr = if calc.rem(i, 2) == 0 { r } else { r * 0.42 }
      (c.at(0) + rr * calc.cos(ang), c.at(1) + rr * calc.sin(ang))
    })
    line(..pts, close: true, fill: black, stroke: none)
  }
  star(hypo, 0.24)
  content(
    (hypo.at(0), hypo.at(1) + 0.42),
    text(lbl)[hypocentre, $t = 0$],
    anchor: "south",
  )

  // Segment names are deliberately absent. Which fault is "segment 3" carries
  // no argument -- what matters is the order, the branch, and the entry time --
  // and four extra labels crowd a figure that is already dense with arrows.
})
