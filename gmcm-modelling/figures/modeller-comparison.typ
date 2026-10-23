// What an empirical modeller and a physics-based modeller each have to get
// right, term by term.
//
// Importable:
//   #import "figures/modeller-comparison.typ": modeller-comparison
//   #modeller-comparison(updates: false)   // the two columns
//   #modeller-comparison(updates: true)    // plus what this talk changes
//
// Staged over two slides. The third column is laid out in both stages and
// hidden in the first, so the table does not reflow on the reveal.
//
// Rows are ordered the way an empirical model is written down -- source, path,
// site -- then the three things a GMM developer always asks about: usable
// period range, the variance decomposition, and what it costs to evaluate.
// Every physics-based row except the source one is something this talk
// updates; the source row is there so the audience sees it was not forgotten.

#import "../palette.typ": exact, quiet, stat

#let modeller-comparison(updates: true) = {
  set par(justify: false, leading: 0.4em)
  set text(0.72em)

  let vis(body) = if updates { body } else { hide(body) }
  let head(body, paint) = text(weight: "bold", fill: paint)[#body]
  let term(body) = text(weight: "bold", fill: exact)[#body]
  let upd(body) = vis(text(fill: stat)[#body])
  let none-here = vis(text(fill: quiet, style: "italic")[Other objectives])

  table(
    columns: (0.7fr, 1.35fr, 1.55fr, 1.35fr),
    stroke: (x, y) => if y == 0 { (bottom: 0.8pt + exact) } else { (bottom: 0.4pt + quiet.lighten(40%)) },
    inset: (x: 6pt, y: 7pt),
    align: left + horizon,
    [],
    head([Empirical model], exact),
    head([Physics-based simulation], exact),
    vis(head([What this talk updates], stat)),

    term[Source], [Magnitude, rake and depth scaling terms], [Kinematic rupture: slip, rise time, rupture velocity], none-here,
    term[Path], [Geometric spreading, anelastic attenuation], [3D velocity and $Q$ model, attenuation in the solver], upd[Blended tomography; attenuation at every grid point],
    term[Site], [$V_(S 30)$, $Z_(1.0)$ and basin terms], [Near-surface velocities, basins and topography], upd[Basin models, GTL layers, topography, Backus averaging],
    term[Bandwidth], [Usable periods of the processed records], [Grid spacing and lowest $V_S$ set the highest frequency], upd[Refinement and fourth order, for 2 Hz],
    term[Variability], [$tau$, $phi_"S2S"$, $phi_"SS"$ from regression], [The same decomposition, from validation residuals], upd[Full moderate crustal validation],
    term[Cost], [Curating the data; fitting is cheap], [Core-hours scale as $h^(-4)$], upd[SW4 performance work],
  )
}
