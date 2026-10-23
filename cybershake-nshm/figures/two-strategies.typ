// Two allocations out of one empirical model, and the dial between them.
//
// Importable:
//   #import "figures/two-strategies.typ": two-strategies
//
// The empirical ground-motion logic tree already gives, per rupture and per
// site, the two quantities the sampling problem needs: the rate lambda and the
// exceedance probability P. Everything else here is arithmetic on those.
//
//   bias reduction      n ∝ lambda P                minimises the unsampled sum
//   variance reduction  n ∝ lambda sqrt(P (1 - P))  Neyman allocation
//
// Both branches are drawn solid and symmetric. The figure states the framework,
// not an inventory of what has been coded: the two allocations follow from the
// same model and the argument is that a modeller chooses between them.
//
// Both branches now ship, at w = 0.75 on bias and 0.25 on variance. Two things
// that figure does not show and the speaker should: the split is not 50/50
// because error is bias-dominated and the Neyman weight is computed from
// empirical GMM sigma, which exceeds a simulation's; and the two are not
// independent -- the bias branch ranks only what the variance branch left
// uncovered, because the two rankings correlate at rho = 0.96 and independent
// branches duplicated each other.

#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "../palette.typ": defect, exact, quiet, stat

#let two-strategies = {
  set par(justify: false, first-line-indent: 0pt, leading: 0.45em)
  set text(7.5pt, hyphenate: false)

  diagram(
    spacing: (7mm, 9mm),
    node-corner-radius: 3pt,
    node-stroke: (thickness: 0.8pt),
    node-fill: rgb(0, 0, 0, 5),
    node-inset: 6pt,
    edge-stroke: (thickness: 0.7pt),

    node(
      (0.5, 0),
      align(center)[
        #text(weight: "bold", fill: exact)[NSHM 2022 ground-motion logic tree] \
        #text(0.85em, fill: quiet.darken(25%))[per rupture, per site: $lambda$ and $P$]
      ],
      width: 62mm,
      name: <gmm>,
    ),

    node(
      (0, 1),
      align(center)[
        #text(weight: "bold", fill: defect.darken(10%))[Bias reduction] \
        $n prop lambda P$
      ],
      width: 40mm,
      stroke: (thickness: 0.9pt, paint: defect),
      fill: defect.lighten(93%),
      name: <bias>,
    ),
    node(
      (1, 1),
      align(center)[
        #text(weight: "bold", fill: stat.darken(12%))[Variance reduction] \
        $n prop lambda sqrt(P (1 - P))$
      ],
      width: 40mm,
      stroke: (thickness: 0.9pt, paint: stat),
      fill: stat.lighten(92%),
      name: <var>,
    ),
    edge(<gmm>, <bias>, "-|>"),
    edge(<gmm>, <var>, "-|>"),

    node(
      (0.5, 2),
      align(center)[
        #text(weight: "bold", fill: exact)[Weighted blend] \
        #text(0.85em, fill: quiet.darken(25%))[the modeller's dial]
      ],
      width: 44mm,
      name: <blend>,
    ),
    edge(<bias>, <blend>, "-|>", label: $w = 0.75$),
    edge(<var>, <blend>, "-|>", label: $0.25$),
  )
}
