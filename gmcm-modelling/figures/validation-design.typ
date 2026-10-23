// The validation run: one event set, two workflows, one residual model. The
// reference is Felipe Kuncar's published results on his moderate crustal
// dataset, so the comparison is against numbers already in the literature.
//
// Importable:
//   #import "figures/validation-design.typ": validation-design
//
// Both workflows share the source (same SRF) and the stochastic high-frequency
// component, so a change in the residuals is attributable to the low-frequency
// side -- solver, grid and velocity model -- and not to the source. That is the
// design from ~/notes/20260729T101536--validation-of-sw4-workflow, rung 3.
//
// The residual decomposition is written in the notation the GMCM team already
// uses (Al Atik et al. 2010): between-event, site-to-site, within-site.

#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "../palette.typ": exact, quiet, stat

#let validation-design = {
  set par(justify: false, first-line-indent: 0pt, leading: 0.45em)
  set text(8pt, hyphenate: false)

  let box(pos, body, paint, name, width: 36mm) = node(
    pos,
    align(center, body),
    width: width,
    inset: 6pt,
    stroke: (thickness: 0.9pt, paint: paint),
    name: name,
  )

  diagram(
    spacing: (12mm, 7mm),
    node-corner-radius: 3pt,
    edge-stroke: (thickness: 0.9pt),

    box(
      (0, 0.5),
      [
        #text(weight: "bold", fill: exact)[Moderate crustal dataset] \
        #text(
          0.85em,
          fill: quiet.darken(25%),
        )[Kuncar, GMDB events, \ $M_w$ 5--6]
      ],
      exact,
      <events>,
    ),

    box(
      (1, 0),
      [
        #text(weight: "bold", fill: exact)[Published results] \
        #text(
          0.85em,
          fill: quiet.darken(25%),
        )[Kuncar et al., \ EMOD3D, 100 m, 1 Hz]
      ],
      exact,
      <old>,
      width: 42mm,
    ),
    box(
      (1, 1),
      [
        #text(weight: "bold", fill: stat)[New workflow] \
        #text(
          0.85em,
          fill: quiet.darken(25%),
        )[SW4 + NZCVM, refinement, \ topography, Backus, 100 m, 1 Hz]
      ],
      stat,
      <new>,
      width: 42mm,
    ),

    box(
      (2, 0.5),
      [
        #text(weight: "bold", fill: exact)[Mixed-effects residuals] \
        #v(2pt)
      ],
      exact,
      <mera>,
      width: 44mm,
    ),

    edge(<events>, <old>, "-|>"),
    edge(<events>, <new>, "-|>"),
    edge(<old>, <mera>, "-|>"),
    edge(<new>, <mera>, "-|>"),

    node(
      (1, 1.75),
      text(
        0.9em,
        fill: quiet.darken(20%),
        style: "italic",
      )[Same source, same stochastic HF],
      inset: 0pt,
    ),
  )
}
