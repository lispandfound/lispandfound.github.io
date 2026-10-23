// The sampling logic tree, as implemented.
//
// Importable:
//   #import "figures/sampling-logic-tree.typ": sampling-logic-tree
//
// Structure and weights are the ones ACTUALLY RUN, read back from the
// `sampling_logic_tree` root attribute of data/density.h5:
//
//   subduction [hikurangi, puysegur]  0.25 -+- population variance  0.125
//   crustal    [crustal]              0.75  |  area       variance  0.125
//                                           |  population bias      0.375
//                                           +- area       bias      0.375
//
// Two things this figure has to get across beyond the weights.
//
// 1. Variance takes only a quarter. Error is bias-dominated, and the Neyman
//    weight is computed from empirical GMMs whose sigma exceeds a simulation's,
//    so it overstates the variance there is to reduce. A weight sweep put the
//    RMSE minimum near 0.125-0.25 and rising steeply above it.
//
// 2. The bias leaves are drawn AFTER the variance leaves and the arrow between
//    them says so. They are not independent: a bias leaf ranks only the
//    ruptures the variance leaves did not already cover. Without that the two
//    duplicate each other -- their rankings correlate at rho = 0.96 -- coverage
//    falls and bias rises. This is a real departure from "independent models
//    combined under weights" and the figure should not pretend otherwise.
//
// The dashed `magnitude-binned` leaf of the previous version is gone. It made
// the point that a new objective is a weight rather than a rewrite; the bias
// branch now demonstrates that instead of promising it, and five leaves per
// branch is more than this slide can hold.

#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "../palette.typ": crustal, defect, exact, hikurangi, quiet, stat

#let sampling-logic-tree = {
  set par(justify: false, first-line-indent: 0pt, leading: 0.45em)
  set text(7pt, hyphenate: false)

  // (row offset, objective colour, objective, site weighting, weight)
  let leaf-spec = (
    (-1.5, stat, [variance], [population], [0.125]),
    (-0.5, stat, [variance], [area], [0.125]),
    (0.5, defect, [bias], [population], [0.375]),
    (1.5, defect, [bias], [area], [0.375]),
  )

  let branch(row, name, systems, weight, col) = {
    let b = label("b" + str(row))
    (
      node(
        (1, row),
        align(center)[
          #text(weight: "bold", fill: col.darken(15%))[#name] \
          #text(0.85em, fill: quiet.darken(20%))[#systems]
        ],
        width: 30mm,
        stroke: (thickness: 0.9pt, paint: col),
        fill: col.lighten(92%),
        name: b,
      ),
      edge(
        <root>,
        b,
        "-|>",
        label: text(weight: "bold")[#weight],
        label-pos: 0.5,
      ),
    )
  }

  // Four leaves per branch, one row apart, at +/-0.5 and +/-1.5 of the branch
  // row. A leaf box is about 6 mm tall, so the row pitch has to clear that or
  // they touch; the branch rows are then 5 apart to keep the two fans 2 rows
  // clear of one another. The previous three-leaf spacing of +/-0.55 does not
  // survive a fourth leaf at any pitch.
  let leaves(row) = {
    let b = label("b" + str(row))
    leaf-spec
      .enumerate()
      .map((( i, (dr, col, objective, weighting, w))) => {
        let n = label("l" + str(row) + "x" + str(i))
        (
          node(
            (2, row + dr),
            [
              #text(weight: "bold", fill: col.darken(12%))[#objective]
              #h(0.35em) · #h(0.35em) #weighting
            ],
            width: 36mm,
            stroke: (thickness: 0.8pt, paint: col.lighten(30%)),
            fill: col.lighten(94%),
            name: n,
          ),
          edge(b, n, "-|>", label: w, label-pos: 0.38, label-sep: 2.5pt),
        )
      })
      .flatten()
  }

  diagram(
    spacing: (10mm, 7mm),
    node-corner-radius: 2.5pt,
    node-stroke: (thickness: 0.7pt),
    node-fill: rgb(0, 0, 0, 5),
    node-inset: 5pt,
    edge-stroke: (thickness: 0.6pt),

    ..(
      (1, [tectonic type]),
      (2, [objective · site weighting]),
    ).map(((col, body)) => node(
      (col, -2.4),
      text(style: "italic", fill: quiet.darken(25%), body),
      stroke: none,
      fill: none,
    )),

    node(
      (0, 2.5),
      align(center)[
        #text(weight: "bold", fill: exact)[Rupture sampling] \
        #text(0.85em, fill: quiet.darken(20%))[5,000 simulations]
      ],
      width: 30mm,
      stroke: (thickness: 0.9pt, paint: exact),
      fill: exact.lighten(94%),
      name: <root>,
    ),

    ..branch(0, [subduction], [hikurangi, puysegur], [0.25], hikurangi),
    ..branch(5, [crustal], [crustal], [0.75], crustal),
    ..leaves(0),
    ..leaves(5),
  )
}
