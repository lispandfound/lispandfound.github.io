// The Cybershake NZ pipeline, end to end, with this work's two stages marked.
//
// Importable:
//   #import "figures/psha-pipeline.typ": psha-pipeline
//
// Four stages, in the order they run. The first two are shaded because they are
// what the rest of this talk is about; the marking follows the convention of
// Figures/psha-simulation-overview.typ in the proposal, where a single fill
// means "an area of study for this proposal".
//
// Each box carries what the stage EMITS rather than how it works -- the handoff
// is the thing a mixed audience needs in order to follow where a contribution
// sits, and the how is the next six slides.

#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "../palette.typ": exact, quiet, stat

#let psha-pipeline = {
  set par(justify: false, first-line-indent: 0pt, leading: 0.45em)
  set text(8pt, hyphenate: false)

  let stage(col, title, emits, mine) = node(
    (col, 0),
    align(center)[
      // Explicit fill, never `*...*`: metropolis recolours strong text, so
      // markup bold would come out accent-coloured in the deck and plain black
      // in the standalone PNG, and the PowerPoint would not match the PDF.
      #text(weight: "bold", fill: if mine { stat.darken(12%) } else { exact })[#title] \
      #text(0.82em, fill: quiet.darken(25%))[#emits]
    ],
    width: 34mm,
    // Pinned, not content-sized: one subtitle wraps to two lines and the rest
    // do not, and four boxes of three different heights read as a hierarchy
    // that is not there.
    height: 13mm,
    inset: 6pt,
    stroke: (thickness: if mine { 1.0pt } else { 0.7pt }, paint: if mine {
      stat
    } else {
      exact
    }),
    fill: if mine { stat.lighten(90%) } else { rgb(0, 0, 0, 5) },
    name: label("s" + str(col)),
  )

  diagram(
    spacing: (7mm, 6mm),
    node-corner-radius: 2.5pt,
    edge-stroke: (thickness: 0.8pt),

    stage(0, [Rupture selection], [which ruptures, and how many], true),
    stage(1, [Rupture generation], [slip, rise time, rupture time], true),
    stage(2, [Simulation], [ground motion at every site], false),
    stage(3, [PSHA], [hazard curves, exceedance rates], false),

    ..(0, 1, 2).map(c => edge(
      label("s" + str(c)),
      label("s" + str(c + 1)),
      "-|>",
    )),

    // Which two stages this talk is about.
    //
    // `enclose` binds to the two nodes themselves, so the box is their real
    // bounding box whatever they end up sized at. Drawing it as an edge between
    // guessed grid coordinates -- which is what this was -- means recomputing
    // the column pitch by hand every time a label changes length, and getting it
    // slightly wrong, which is exactly what happened.
    node(
      enclose: (<s0>, <s1>),
      stroke: (thickness: 0.9pt, paint: stat, dash: "dashed"),
      fill: none,
      inset: 4.5pt,
      corner-radius: 4pt,
      layer: -1,
      name: <mine>,
    ),
    // The one placed coordinate left, and it is derived rather than eyeballed:
    // x = 0.5 is exactly halfway between the two node centres.
    node(
      (0.5, 0.95),
      text(0.85em, fill: stat.darken(15%), weight: "bold")[this talk],
      stroke: none,
      fill: none,
      snap: false,
    ),
  )
}
