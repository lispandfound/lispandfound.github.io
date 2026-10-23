// An excerpt of the NSHM 2022 source-model logic tree, redrawn.
//
// Importable:
//   #import "figures/nshm-logic-tree.typ": nshm-logic-tree
//
// Redrawn rather than screenshotted so that it shares a visual grammar with
// `sampling-logic-tree.typ` on the other half of the slide -- the analogy is the
// whole point of the slide, and it only lands if the two diagrams look like the
// same kind of object.
//
// Two real branch axes of the crustal seismicity rate model, deformation model
// and time dependence, which multiply. It is an EXCERPT and the title says so:
// the full tree carries further axes (scaling relation, moment-rate scaling,
// b-value) and the ground-motion characterisation tree is separate again.
//
// Weights are deliberately SYMBOLIC. Putting invented numbers on the NSHM's own
// tree in front of the NSHM team would be worse than useless, and the symbolic
// form also sets up the contrast: on the sampling side the weights are stated.

#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "../palette.typ": exact, quiet

#let nshm-logic-tree = {
  set par(justify: false, first-line-indent: 0pt, leading: 0.45em)
  set text(7pt, hyphenate: false)

  diagram(
    spacing: (8mm, 5mm),
    node-corner-radius: 2.5pt,
    node-stroke: (thickness: 0.7pt, paint: exact),
    node-fill: rgb(0, 0, 0, 5),
    node-inset: 5pt,
    edge-stroke: (thickness: 0.6pt),

    ..(
      (1, [deformation model]),
      (2, [time dependence]),
    ).map(((col, body)) => node(
      (col, -1),
      text(style: "italic", fill: quiet.darken(25%), body),
      stroke: none,
      fill: none,
    )),

    node(
      (0, 1.5),
      align(center)[#text(weight: "bold", fill: exact)[NSHM 2022] \ crustal source model \ #text(0.85em, fill: quiet.darken(20%))[(excerpt)]],
      width: 30mm,
      name: <root>,
    ),

    node((1, 0.5), align(center)[geologic], width: 24mm, name: <d1>),
    node((1, 2.5), align(center)[geodetic], width: 24mm, name: <d2>),
    edge(<root>, <d1>, "-|>", label: $p_1$, label-pos: 0.5),
    edge(<root>, <d2>, "-|>", label: $p_2$, label-pos: 0.5),

    node((2, 0), align(center)[time-independent], width: 30mm, name: <t1>),
    node((2, 1), align(center)[time-dependent], width: 30mm, name: <t2>),
    node((2, 2), align(center)[time-independent], width: 30mm, name: <t3>),
    node((2, 3), align(center)[time-dependent], width: 30mm, name: <t4>),

    edge(<d1>, <t1>, "-|>", label: $p_(1 1)$, label-pos: 0.55, label-sep: 2pt),
    edge(<d1>, <t2>, "-|>", label: $p_(1 2)$, label-pos: 0.55, label-sep: 2pt),
    edge(<d2>, <t3>, "-|>", label: $p_(2 1)$, label-pos: 0.55, label-sep: 2pt),
    edge(<d2>, <t4>, "-|>", label: $p_(2 2)$, label-pos: 0.55, label-sep: 2pt),
  )
}
