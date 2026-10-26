// The three steps of the multi-segment rupture generator, on one made-up system.
//
// Importable:
//   #import "figures/rupture-steps.typ": rupture-plan, jump-graph, jump-timing
//   #let steps = json("out/png/rupture-steps.json")
//   #rupture-plan(steps)
//
// Every number comes from scripts/plot_rupture_steps.py, which runs
// ~/src/rupture_generator on the system and writes the JSON:
//   rupture-plan  the system in plan view, each gap in reach labelled in km;
//   jump-graph    step 1: one node per segment, each edge its jump probability,
//                 the likeliest tree (maximum spanning tree) drawn heavy;
//   jump-timing   step 3: the worked jump from the hypocentre's segment onto
//                 the next, timed as first_arrival times it.
// Step 2 is the slip panel, rupture-steps-slip.png, from the same script.
//
// Drawn at document scale and scaled up at use.

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": exact, quiet, stat

#let jump-red = rgb("#B03A2E")

#let mid(trace) = (
  (trace.at(0).at(0) + trace.at(1).at(0)) / 2,
  (trace.at(0).at(1) + trace.at(1).at(1)) / 2,
)

#let star(c, r, paint: yellow) = {
  import draw: *
  let pts = range(0, 10).map(i => {
    let ang = 90deg - i * 36deg
    let rr = if calc.rem(i, 2) == 0 { r } else { r * 0.42 }
    (c.at(0) + rr * calc.cos(ang), c.at(1) + rr * calc.sin(ang))
  })
  line(..pts, close: true, fill: paint, stroke: (thickness: 0.3pt, paint: black))
}

// Kilometres to canvas units: the system is about 95 km by 35 km.
#let km = 0.1

#let in-tree(steps, a, b) = steps.tree.any(e => (
  (e.at(0) == a and e.at(1) == b) or (e.at(0) == b and e.at(1) == a)
))

#let rupture-plan(steps) = canvas(length: 1cm, {
  import draw: *
  let p(xy) = (xy.at(0) * km, xy.at(1) * km)

  for (name, seg) in steps.segments {
    let (a, b) = seg.trace
    line(p(a), p(b), stroke: (thickness: 1.6pt, paint: exact, cap: "round"))
    // Name on the side away from its neighbours: below for the two that run
    // under the others, above for the rest.
    let below = name in ("A", "D")
    content(
      p(mid(seg.trace)),
      text(10pt, weight: "bold", fill: exact)[#name],
      anchor: if below { "north" } else { "south" },
      padding: 0.12,
    )
  }

  // Three gaps meet at the A/B/D junction, so each label there is pushed
  // off its gap to its own side; the rest sit beside their gap.
  let label-anchor = (
    "A-B": "south-east",
    "A-D": "north-east",
    "B-D": "west",
    "B-C": "north-west",
    "C-E": "north-west",
  )
  for gap in steps.gaps {
    let (f, t) = (p(gap.from), p(gap.to))
    line(f, t, stroke: (thickness: 0.6pt, paint: jump-red))
    content(
      ((f.at(0) + t.at(0)) / 2, (f.at(1) + t.at(1)) / 2),
      text(8pt, fill: jump-red)[#calc.round(gap.gap_km, digits: 1) km],
      anchor: label-anchor.at(gap.a + "-" + gap.b, default: "west"),
      padding: 0.1,
    )
  }

  star(p(steps.hypocentre.plan), 0.3)

  // Scale bar, 10 km.
  let (x0, y0) = (0.0, -0.75)
  line((x0, y0), (x0 + 10 * km, y0), stroke: (thickness: 0.8pt, paint: quiet))
  content((x0 + 5 * km, y0), text(7pt, fill: quiet.darken(20%))[10 km], anchor: "north", padding: 0.08)
})

// Step 1. Nodes sit at the segments' midpoints, so the graph keeps the plan's
// shape and a reader can match each node to its fault above.
#let jump-graph(steps) = canvas(length: 1cm, {
  import draw: *
  let node(name) = {
    let c = mid(steps.segments.at(name).trace)
    (c.at(0) * km, c.at(1) * km)
  }

  for gap in steps.gaps {
    let (a, b) = (node(gap.a), node(gap.b))
    let tree = in-tree(steps, gap.a, gap.b)
    line(a, b, stroke: if tree {
      (thickness: 1.8pt, paint: stat)
    } else {
      (thickness: 0.6pt, paint: quiet, dash: "dashed")
    })
    // Tree edges carry their label on the line; the dropped edge is short and
    // dashed, so its label stands beside it rather than hiding it.
    content(
      ((a.at(0) + b.at(0)) / 2, (a.at(1) + b.at(1)) / 2),
      anchor: if tree { "center" } else { "east" },
      padding: if tree { 0 } else { 0.08 },
      box(fill: white, inset: 1pt, text(
        8pt,
        fill: if tree { stat.darken(25%) } else { quiet.darken(10%) },
      )[#calc.round(gap.p, digits: 2)]),
    )
  }

  for (name, _) in steps.segments {
    circle(node(name), radius: 0.27, fill: white, stroke: (thickness: 0.8pt, paint: exact))
    content(node(name), text(8.5pt, weight: "bold", fill: exact)[#name])
  }
})

// Step 3. The jump from parent to child, drawn face-on: the parent's onset
// isochrones reach its far edge, candidate crossings fan out to the child, and
// the earliest arrival within reach starts the child's front.
#let jump-timing(steps) = canvas(length: 1cm, {
  import draw: *
  let j = steps.jump
  let (w, h) = (2.4, 1.5) // plane size, canvas units
  let gap = 1.0
  let child-dy = 0.35 // the child sits offset, as a stepover does

  // Parent plane with isochrones closing in on its far edge. The front comes
  // from a hypocentre off to the left, so each isochrone is an arc about a
  // centre outside the plane, cut where it meets the top and bottom edges.
  rect((0, 0), (w, h), fill: rgb(0, 0, 0, 6), stroke: (thickness: 0.5pt, paint: exact))
  let centre = (-1.5, h / 2)
  for r in (2.0, 2.7, 3.4) {
    let half = calc.asin((h / 2) / r)
    arc(
      centre,
      start: -half,
      stop: half,
      radius: r,
      anchor: "origin",
      stroke: (thickness: 0.35pt, paint: quiet),
    )
  }
  content((w / 2, h), text(8.5pt, weight: "bold", fill: exact)[#j.parent], anchor: "south", padding: 0.08)

  // Child plane.
  let cx = w + gap
  rect((cx, child-dy), (cx + w * 0.6, h + child-dy), fill: rgb(0, 0, 0, 6), stroke: (thickness: 0.5pt, paint: exact))
  content((cx + w * 0.3, h + child-dy), text(8.5pt, weight: "bold", fill: exact)[#j.child], anchor: "south", padding: 0.08)

  // Candidate crossings, grey, then the earliest, heavy.
  for (yd, yl) in ((0.15, 0.5), (0.45, 0.6), (1.1, 1.3), (1.35, 1.75)) {
    line((w, yd), (cx, yl), stroke: (thickness: 0.4pt, paint: quiet, dash: "dotted"))
  }
  let (d, l) = ((w, 0.75), (cx, 0.95))
  line(d, l, mark: (end: "stealth", fill: jump-red, scale: 0.4), stroke: (thickness: 1.1pt, paint: jump-red))
  circle(d, radius: 0.05, fill: jump-red, stroke: none)

  content(
    d,
    box(fill: white, inset: 1pt, text(7.5pt, fill: exact)[#j.onset_s s]),
    anchor: "north-east",
    padding: 0.06,
  )
  content(
    ((w + cx) / 2, 0.85),
    text(7.5pt, fill: jump-red)[+#j.crossing_s s],
    anchor: "north",
    padding: 0.1,
  )
  content(
    (cx + 0.08, 0.95),
    text(7.5pt, weight: "bold", fill: jump-red)[#j.arrival_s s],
    anchor: "west",
  )
})
