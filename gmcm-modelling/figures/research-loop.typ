// How a velocity-model idea gets from a researcher into a simulation, before
// and after NZCVM.
//
// Importable:
//   #import "figures/research-loop.typ": research-loop
//   #research-loop(after: false)   // the old path only
//   #research-loop(after: true)    // both paths
//
// Staged over two slides. The "after" row is drawn in both stages but hidden in
// the first (transparent strokes, hidden text), so both stages have identical
// extents and the old row does not move under the audience on the reveal. If
// you add anything to the after row, route it through `reveal` so it is hidden --
// not omitted -- in stage one.

#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "../palette.typ": defect, exact, quiet, stat

#let research-loop(after: true) = {
  set par(justify: false, first-line-indent: 0pt, leading: 0.45em)
  set text(8pt, hyphenate: false)

  let clear = rgb(0, 0, 0, 0)
  let reveal(paint) = if after { paint } else { clear }
  let vis(body) = if after { body } else { hide(body) }

  let step(pos, title, sub, paint, name, visible: true) = node(
    pos,
    {
      let b = align(center)[
        #text(weight: "bold", fill: paint)[#title] \
        #text(0.85em, fill: quiet.darken(25%))[#sub]
      ]
      if visible { b } else { vis(b) }
    },
    width: 33mm,
    height: 15mm,
    inset: 5pt,
    stroke: (
      thickness: 0.9pt,
      paint: if visible { paint } else { reveal(paint) },
    ),
    name: name,
  )

  let row-label(pos, body, paint, visible: true) = node(
    pos,
    {
      let b = text(9pt, weight: "bold", fill: paint)[#body]
      if visible { b } else { vis(b) }
    },
    inset: 0pt,
    width: 16mm,
  )

  diagram(
    spacing: (8mm, 12mm),
    node-corner-radius: 3pt,
    edge-stroke: (thickness: 0.9pt),

    // --- before --------------------------------------------------------
    row-label((0, 0), [Before], exact),
    step((1, 0), [Researcher], [Has a model to \ add or change], exact, <b1>),
    step((2, 0), [Software team], [Bakes it \ into the code], exact, <b2>),
    step(
      (3, 0),
      [Parallel version],
      [Maintained for \ the experiment],
      exact,
      <b3>,
    ),
    step(
      (4, 0),
      [Maybe dropped],
      [All the extra parallel work for nothing!],
      defect,
      <b4>,
    ),
    edge(<b1>, <b2>, "-|>"),
    edge(<b2>, <b3>, "-|>"),
    edge(<b3>, <b4>, "-|>"),
    edge(
      <b3>,
      <b1>,
      "-|>",
      bend: 35deg,
      stroke: (paint: quiet, dash: "dashed"),
      label: text(7.5pt, fill: quiet.darken(20%))[Every change],
      label-side: right,
    ),

    // --- after ----------------------------------------------------------
    row-label((0, 1.6), [After], stat, visible: false),
    step(
      (1, 1.6),
      [Researcher],
      [Adds a model file \ or a layer],
      stat,
      <a1>,
      visible: false,
    ),
    step(
      (2, 1.6),
      [Iterates],
      [On their own, \ at their own pace],
      stat,
      <a2>,
      visible: false,
    ),
    step(
      (4, 1.6),
      [Software team],
      [Integrates \ the end product],
      stat,
      <a4>,
      visible: false,
    ),
    edge(<a1>, <a2>, "-|>", stroke: (paint: reveal(black))),
    edge(<a2>, <a1>, "-|>", bend: -40deg, stroke: (
      paint: reveal(quiet),
      dash: "dashed",
    )),
    edge(<a2>, <a4>, "-|>", stroke: (paint: reveal(black))),
  )
}
