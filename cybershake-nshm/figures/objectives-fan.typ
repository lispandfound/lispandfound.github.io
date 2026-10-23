// One compute budget, four incompatible things to spend it on.
//
// Importable:
//   #import "figures/objectives-fan.typ": objectives-fan
//
// The objectives are taken from ~/src/sampling_notes/paper.tex:109-114 ("A
// Sampling Logic Tree for Rupture Selection in Cybershake NZ", Bradley &
// Faulkner).
//
// The top branch names who each weighting serves rather than where it lands.
// Population weighting concentrates the sample on cities; area weighting spreads
// it over territory, which is what distributed infrastructure -- transmission,
// road and rail networks -- is exposed to. The geographic consequence is real
// and is the evidence for the split (paper.tex:158 records the two views pulling
// density toward the North and South Islands respectively, with a visible effect
// at Southland sites), but it is the symptom, not the objective, so it belongs
// in what is said rather than on the box.
//
// The top branch is drawn split and the others are not, because the split is the
// strongest evidence available: it shows the objectives diverge even INSIDE PSHA,
// before any other stakeholder is considered.
//
// Layout notes, learned the hard way:
//
//   * Nothing here is placed by eye. Every node sits on a fletcher grid cell and
//     every edge is routed by fletcher between two named nodes. Parents sit at
//     the mean row of their children so they centre on them, which is the same
//     convention as Figures/sampling-logic-tree.typ in the proposal.
//   * The closing line is stacked BELOW the diagram, not placed inside it as a
//     free node. A node's width propagates into the grid even with `snap: false`,
//     so a wide caption silently stretches whichever columns it spans and pushes
//     the fan out of shape -- this is the same trap documented in
//     qcam-poster/figures/rupture-logic-tree.typ, where the legend is kept
//     outside `diagram` for exactly this reason.
//   * The right-hand column is content-sized. Forcing a width there made the
//     column as wide as the longest phrase and left the shorter ones stranded.

#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "../palette.typ": crustal, exact, hikurangi, quiet

#let objectives-fan = {
  set par(justify: false, first-line-indent: 0pt, leading: 0.45em)
  set text(7pt, hyphenate: false)

  let want(body) = text(style: "italic", fill: quiet.darken(30%), body)

  // Rows. The hazard branch splits across two rows and centres between them;
  // the other three objectives take one row each.
  let r-people = 0
  let r-area = 1
  let r-hazard = (r-people + r-area) / 2
  let r-surrogate = 2.2
  let r-scenario = 3.2
  let r-coverage = 4.2
  let r-root = (r-hazard + r-surrogate + r-scenario + r-coverage) / 4

  let singles = (
    (r-surrogate, [Surrogate \ training], want[
      broad coverage in $M_w$, $R_"rup"$, $V_(s 30)$, geometry
    ]),
    (r-scenario, [Scenario \ analysis], want[a prescribed set of events, re-used]),
    (r-coverage, [Fault \ coverage], want[every fault represented at least once]),
  )

  let key(prefix, row) = label(prefix + str(calc.round(row * 10)))

  diagram(
    spacing: (11mm, 6mm),
    node-corner-radius: 2.5pt,
    node-stroke: (thickness: 0.7pt),
    node-fill: rgb(0, 0, 0, 5),
    node-inset: 5pt,
    edge-stroke: (thickness: 0.6pt),

    // --- the budget -------------------------------------------------------
    node(
      (0, r-root),
      align(center)[#text(weight: "bold", fill: exact)[One compute budget]],
      width: 24mm,
      name: <root>,
    ),

    // --- the hazard branch, which splits ----------------------------------
    node(
      (1, r-hazard),
      align(center)[Hazard \ estimation],
      width: 26mm,
      stroke: (thickness: 0.9pt, paint: exact),
      name: <hazard>,
    ),
    edge(<root>, <hazard>, "-|>"),

    node(
      (2, r-people),
      [weight sites by #text(weight: "bold", fill: black)[people] #h(1fr) #text(fill: hikurangi)[$arrow.r$ cities]],
      width: 46mm,
      stroke: (thickness: 0.7pt, paint: hikurangi),
      fill: hikurangi.lighten(92%),
      name: <people>,
    ),
    node(
      (2, r-area),
      [weight sites by #text(weight: "bold", fill: black)[area] #h(1fr) #text(fill: crustal.darken(12%))[$arrow.r$ infrastructure]],
      width: 46mm,
      stroke: (thickness: 0.7pt, paint: crustal),
      fill: crustal.lighten(92%),
      name: <area>,
    ),
    edge(<hazard>, <people>, "-|>"),
    edge(<hazard>, <area>, "-|>"),

    // --- the three that do not ---------------------------------------------
    ..singles
      .map((( row, objective, wants)) => (
        node((1, row), align(center, objective), width: 26mm, name: key("o", row)),
        node((2, row), wants, stroke: none, fill: none, name: key("w", row)),
        edge(<root>, key("o", row), "-|>"),
        edge(
          key("o", row),
          key("w", row),
          "-|>",
          stroke: (thickness: 0.6pt, paint: quiet),
        ),
      ))
      .flatten(),
  )
}
