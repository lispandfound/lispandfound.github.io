// Towards 2+ Hz: topography, variable mesh refinement and modular velocity
// models for physics-based ground motion simulation.
//
// Build:  typst compile main.typ      (or `just`)
// Watch:  typst watch main.typ
// Notes:  `just notes` (notes on a second screen) or `just pdfpc` (for pdfpc)
//
// Preamble follows ~/Documents/reproducible-data-talk/main.typ so this deck
// matches the existing ones. Speaker notes are `#say` blocks under each
// slide's heading: the slides carry almost no prose, because the argument is
// spoken and the written text is reserved for numbers that have to stay
// readable for as long as the slide is up.
//
// The audience is the ESNZ GMCM team: empirical ground motion modellers, not
// simulation people. Order: the hybrid method, the group's decade at 1 Hz and
// the NSHM goal; then three sections, each opened by a title-only section slide
// (`= Heading`): the solver (EMOD3D to SW4), the velocity model code, and the
// results. The solver and velocity model sections both run problem then
// solution. The deck ends on the 1 Hz against 2 Hz extension.

#import "@preview/touying:0.6.1": *
#import themes.metropolis: *

#import "figures/uniform-grid.typ": uniform-grid
#import "figures/refinement.typ": refinement
#import "figures/curvilinear-cartesian-grid.typ": curvilinear-cartesian-grid
#import "figures/nzcvm-pipeline.typ": nzcvm-pipeline
#import "figures/validation-design.typ": validation-design
#import "figures/icons.typ": icon-order, icon-refine, icon-topo
#import "figures/accuracy-order.typ": accuracy-order
#import "figures/research-loop.typ": research-loop
#import "figures/tomography-blend.typ": blend-plan, blend-stack
#import "figures/hybrid-method.typ": crossover-spectrum, hybrid-pipeline
#import "figures/study-timeline.typ": study-timeline
#import "figures/nshm-weights.typ": nshm-weights
#import "figures/sw4-cost.typ": sw4-cost
#import "palette.typ": defect, exact, perf, quiet, stat

// The metropolis section slide, with 12% side padding instead of 20%: at 20%
// "Changing our solver: EMOD3D to SW4" wraps and leaves "SW4" on a line alone.
#let section-slide(
  config: (:),
  level: 1,
  numbered: true,
  body,
) = touying-slide-wrapper(self => {
  let slide-body = {
    set std.align(horizon)
    show: pad.with(x: 12%, y: 20%)
    set text(size: 1.5em)
    stack(
      dir: ttb,
      spacing: 1em,
      text(self.colors.neutral-darkest, utils.display-current-heading(
        level: level,
        numbered: numbered,
        style: auto,
      )),
      block(
        height: 2pt,
        width: 100%,
        spacing: 0pt,
        components.progress-bar(
          height: 2pt,
          self.colors.primary,
          self.colors.primary-light,
        ),
      ),
    )
    text(self.colors.neutral-dark, body)
  }
  self = utils.merge-dicts(self, config-page(
    fill: self.colors.neutral-lightest,
  ))
  touying-slide(self: self, config: config, slide-body)
})

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [Towards 2+ Hz],
    subtitle: [topography, variable mesh refinement and modular velocity models
      for physics-based ground motion simulation],
    author: [Jake Faulkner],
    date: datetime.today(),
    institution: [University of Canterbury],
  ),
  config-common(
    datetime-format: "[day] [month repr:long] [year]",
    new-section-slide-fn: section-slide,
    // `--input notes=true` doubles each page: the slide, then its notes beside
    // it, for a presenter screen. The normal build is unaffected.
    show-notes-on-second-screen: if sys.inputs.at("notes", default: "false")
      == "true" { right } else { none },
  ),
  // Plain white, so the white-backed matplotlib figures sit flush on the slide.
  config-colors(neutral-lightest: white),
)

#set text(font: "Libertinus Serif", size: 20pt)
#show raw: set text(font: "DejaVu Sans Mono", size: 0.82em)

// Figures are drawn at document scale; the deck scales them at use.
//
// A hand-tuned percentage cannot know how wide its container is, so two figures
// side by side either leave a gap or collide the moment either one changes.
// `fit` measures the figure and scales it to the width it is actually given;
// `cap` bounds the enlargement so a small figure on a wide slide is not blown
// up to fill it.
#let fit(body, cap: 300%) = layout(size => {
  let m = measure(body)
  let f = calc.min(size.width / m.width * 100%, cap)
  align(center, scale(f, reflow: true, body))
})

#let big(body, cap: 188%) = fit(body, cap: cap)

// Speaker notes, sized for the presenter screen (`just notes`) rather than the
// slide: the longest note has to fit on one page beside its slide.
#let say(body) = speaker-note(setting: it => text(0.56em, it), body)

// One number, said once, at the size it deserves.
#let headline(value, caption, colour: stat, size: 2.4em) = align(center)[
  // Bounds edges, so a subscript or superscript in the value is counted in its
  // height and cannot run into the caption.
  #block(below: 0.4em, text(
    size: size,
    weight: "bold",
    fill: colour,
    top-edge: "bounds",
    bottom-edge: "bounds",
  )[#value])
  #text(size: 0.85em, fill: quiet.darken(25%))[#caption]
]

// A quiet aside under a figure -- the sentence a reader would ask for if the
// figure were on a poster and nobody were standing next to it.
#let note(body) = align(center, text(
  0.78em,
  fill: quiet.darken(20%),
  style: "italic",
)[#body])

// A quoted file, on the tinted panel the deck uses for "here is the actual
// thing". `align(left)` is not optional: the panel is usually inside an
// `align(center)`, and centred code is unreadable.
#let source-panel(accent, size, body) = block(
  fill: rgb(0, 0, 0, 5),
  stroke: (left: (thickness: 3pt, paint: accent)),
  inset: (x: 1.1em, y: 0.9em),
  radius: 2pt,
  width: 100%,
  align(left, text(size: size, body)),
)

// One panel of a "three changes" overview: a pictogram over a title and a
// one-line gloss. The pictogram box has a fixed height so the three titles line
// up however tall each drawing is.
#let panel(icon, title, gloss) = align(center)[
  #box(height: 5.2cm, width: 100%, align(center + horizon, fit(
    icon,
    cap: 150%,
  )))
  #v(0.5em)
  #box(height: 1.2em, text(0.9em, weight: "bold", fill: stat)[#title])
  #v(-0.3em)
  #text(0.72em, fill: quiet.darken(25%))[#gloss]
]

#let three-panels(..panels) = grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 1.4em,
  ..panels,
)

// A column of problem statements: each on its own card with a `defect` rule,
// so a problem slide reads as a list of things wrong, not as prose.
#let problems(..items) = align(center, block(width: 80%, stack(
  spacing: 0.7em,
  ..items
    .pos()
    .map(it => block(
      width: 100%,
      fill: defect.lighten(94%),
      stroke: (left: (thickness: 3pt, paint: defect)),
      inset: (x: 1em, y: 0.75em),
      radius: 2pt,
      align(left, text(0.95em)[#it]),
    )),
)))

// A numbered question card for the closing slide.
#let question(n, body) = block(
  fill: stat.lighten(93%),
  stroke: (thickness: 0.8pt, paint: stat.lighten(35%)),
  radius: 3pt,
  inset: (x: 12pt, y: 12pt),
  width: 100%,
  height: 100%,
  {
    text(1.6em, weight: "bold", fill: stat)[#n]
    v(0.2em)
    text(0.9em)[#body]
  },
)

#title-slide()

// ---------------------------------------------------------------------------
== The hybrid method
#say[
  Today simulations carry no weight in the National Seismic Hazard Model. This talk is about one lever for earning some: how much of the spectrum is physics rather than statistics.

  Our simulations use the hybrid method of Graves and Pitarka. One kinematic rupture drives two branches. Below the transition frequency, a full 3D wave-propagation simulation through the velocity model: basins, directivity, the real path. Above it, a stochastic method with a 1D path and random phase, and a Vs30-based site amplification applied to that branch only. Matched filters join the two.

  Three names for the rest of the talk. EMOD3D is our in-house 3D code, used for Cybershake so far. SW4 is an open-source code from Lawrence Livermore. NZCVM is the code that builds the 3D velocity model both of them run through.

  The catch: the grid spacing has to shrink with the transition frequency, and the cost goes as the grid spacing to the minus four. Double the transition from 1 to 2 Hz, and a uniform grid costs sixteen times as much.
]

#v(0.2em)
#big(hybrid-pipeline, cap: 150%)
#v(0.4em)
#grid(
  columns: (1.25fr, 1fr),
  column-gutter: 1.2em,
  align: horizon,
  big(crossover-spectrum, cap: 115%),
  [
    #align(center, text(1.05em)[$
      "cost" prop h^(-4) prop (f_t / V_(S, min))^4
    $])
    #v(0.3em)
    #headline([2× $f_t$ = 16×], [cost, on a uniform grid], colour: defect)
  ],
)

// ---------------------------------------------------------------------------
== A decade of hybrid simulations
#say[
  So where has the group been on that trade-off? Transition frequency against year: circles are validation studies against recordings, squares are Cybershake, the national simulation-based hazard runs.

  Validation settled at 100 metres and 1 Hz around 2016 and has stayed there. Cybershake has to run thousands of simulations, so it started at a quarter of a hertz and is only reaching 1 Hz with version 26, this year. The unified validation database in the shaded panel is the group's 1 Hz reference.

  Every one of these used a minimum shear-wave velocity of 500 metres a second. That floor is not geology: it is what a uniform grid could afford. This work, top right, is the first step to 2 Hz that does not come from halving the grid everywhere.
]

#v(0.3em)
#big(study-timeline, cap: 130%)
#v(0.3em)

// ---------------------------------------------------------------------------
== Goal: Simulations in the NSHM
#say[
  And this is where it is meant to go. In the 2022 NSHM, the ground-motion logic tree is entirely empirical models: simulations get no weight at all.

  For the next model, 2028 or 2030, we expect simulations to come in alongside the empirical models with a modest weight, first where data are thin: long periods, basins, large magnitudes. Further out, in the 2030s, the balance can tip.

  None of these heights are decided numbers. The point is the direction, and that every step along it has to be earned by validation against recordings.
]

#v(0.6em)
#big(nshm-weights, cap: 160%)
#v(0.4em)

// ===========================================================================
//  Part 1: the solver
// ===========================================================================

= Changing our solver: EMOD3D to SW4

// ---------------------------------------------------------------------------
== Limitations of EMOD3D
#say[
  Basin and site effects live in the top kilometre or two, and that is exactly where EMOD3D, and so every Cybershake run so far, had two limitations.

  The first is the grid. EMOD3D uses one grid spacing everywhere. That spacing is set by the slowest material near the surface, but it is paid for all the way down, fifty kilometres, where the rock is close to ten times faster.

  The second is the free surface. It is flat. The red dashed line is the real topography, and it is not in the model at all.
]

#v(0.6em)
#big(uniform-grid, cap: 170%)
#v(0.6em)
#note[Previous Cybershake NZ iterations: one grid spacing, one flat free surface.]

// ---------------------------------------------------------------------------
== What SW4 brings
#say[
  SW4 addresses both, and a third thing besides.

  A grid that is fine near the surface and coarse at depth. A top block that follows the real topography. And fourth-order accuracy right up to the free surface, where EMOD3D drops to second order.

  It also computes attenuation at every grid point rather than averaging it over blocks of cells. I will not spend time on that today, but it is one of the reasons the results differ.
]

#v(1.2em)
#three-panels(
  panel(
    icon-refine,
    [Variable mesh refinement],
    [Fine near the surface, coarse at depth],
  ),
  panel(icon-topo, [Topography], [A top block that follows the ground]),
  panel(icon-order, [Fourth order], [Up to and including the free surface]),
)

// ---------------------------------------------------------------------------
== Variable mesh refinement
#say[
  Refinement first. The grid spacing doubles at each interface going down. These are real numbers from an offshore magnitude 5.1 benchmark: even refined, the top kilometre and a half holds two thirds of all the grid points.

  On the right is why the blocks sit where they do. To carry 2 Hz at five points per wavelength, the spacing a depth needs is the slowest velocity there over ten. The black line is that requirement for a schematic minimum velocity profile. in orange, steps down through 50, 100, 200 and 400 metres, staying under it. EMOD3D, in red, keeps the 50 metres the surface needs all the way down.
]

#v(1.4em)
#big(refinement, cap: 165%)

// ---------------------------------------------------------------------------
== Compromises modelling topography on a flat free surface
#say[
  The second limitation. If the free surface is flat, the topography has to go somewhere. Top left is the truth: hills, a basin, and a flat marker horizon at 2.5 kilometres below sea level.

  Bulldozed, top right, cuts the model off at sea level: the hills and their near-surface material are gone. Squashed, bottom left, measures depth from the local surface: the hills survive, but the flat horizon now has the topography printed into it, upside down.

  Squashed-tapered, bottom right, is what the old workflow did. It is better, but it is still an approximation.
]

#align(center, image("figures/topography_representations.png", height: 88%))

// ---------------------------------------------------------------------------
== Topography on a curvilinear mesh
#say[
  SW4 does not need the approximation. The top of the model is a curvilinear mesh: a smooth map from a regular grid onto the region between the real surface and a flat interface. The free-surface condition is applied on a grid line that follows the topography, not on a staircase.

  Below the interface it is an ordinary Cartesian grid, where the stencil is cheap, so you only pay for the curvature where the surface is.

  For you this is a site question: ridge and valley amplification is in the 3D motion, not added afterwards.
]

#v(1.0em)
#big(curvilinear-cartesian-grid, cap: 130%)

// ---------------------------------------------------------------------------
== Fourth order, up to the free surface
#say[
  The third change is accuracy. Both codes are fourth order in space in the interior of the model. The difference is at the free surface.

  EMOD3D's free-surface treatment drops to second order, and it is second order in time everywhere. SW4 is fourth order in space and time, and its boundary treatment keeps the whole solution fourth-order accurate, free surface included.

  Why care about one row? It is where the shear-wave velocity is lowest, so the grid has the fewest points per wavelength. In GMM terms: the least accurate row was the one your stations sit on.

  The rule of thumb on the right: halve the grid spacing and a second-order error falls by four, a fourth-order error by sixteen.
]

#grid(
  columns: (1.7fr, 1fr),
  column-gutter: 1.2em,
  align: horizon,
  big(accuracy-order, cap: 160%),
  [
    #headline(
      [4× vs 16×],
      [Error reduction from halving $h$, \ second order against fourth],
      colour: stat,
    )
  ],
)
#v(0.4em)
#note[EMOD3D drops fourth order accuracy precisely where we want it most!.]

// ---------------------------------------------------------------------------
// TODO(jake): replace the 100 m + topography number with the current production
// figure after the performance work, if it has moved.
== The cost of these changes
#say[
  None of this is free. On the same benchmark event, EMOD3D takes about twenty-five minutes. SW4 out of the box took about forty hours, nearly a hundred times longer.

  Most of that gap was how the run was laid out on the node. Fixing it brings the 50 metre grid, which carries 2 Hz, to about three hours, and 100 metres with topography, which is what the validation runs use, to about an hour.

  On the right is what we are doing to close the rest: compiler optimisations to SW4 itself, choosing the refinement for each velocity model rather than one fixed layout, stability improvements that allow a larger time step, and moving from double to single precision.
]

#v(0.8em)
#grid(
  columns: (1.25fr, 1fr),
  column-gutter: 1.6em,
  align: horizon,
  big(sw4-cost, cap: 140%),
  {
    set text(0.78em)
    table(
      columns: (auto, auto),
      stroke: (x, y) => if y == 0 { (bottom: 0.8pt + exact) } else {
        (bottom: 0.4pt + quiet.lighten(40%))
      },
      inset: (x: 6pt, y: 8pt),
      align: left + horizon,
      text(weight: "bold", fill: exact)[Change],
      text(weight: "bold", fill: exact)[What it buys],

      [Compiler optimisations \ to SW4], [Faster core loops],
      [Mesh refinement chosen \ per velocity model],
      [No finer grid \ than the model needs],

      [Stability improvements], [A larger stable \ time step],
      [Double to single \ precision], [Half the memory \ and bandwidth],
    )
  },
)

// ===========================================================================
//  Part 2: the velocity model
// ===========================================================================

= NZVM codebase overhaul

// ---------------------------------------------------------------------------
== Limitations of the old code
#say[
  Now the velocity model. Our old code was tightly coupled to the format EMOD3D wants to simulate with. It is also slow, and difficult to change.

  SW4 needs a different input, so the switch breaks that code whether we like it or not. That makes this a once-in-a-decade opportunity: instead of patching it, build a velocity model codebase that is ready for the next ten years.
]

#v(1.4em)
#problems(
  [Tightly coupled to the format EMOD3D wants to simulate with],
  [Difficult to change: opaque to researchers, and a burden to SW team],
)
#v(1.2em)
#headline(
  [An opportunity],
  [SW4 breaks our code anyway: lets rebuild it for the next ten years],
  size: 1.75em,
)

// ---------------------------------------------------------------------------
== What the new code brings
#say[
  Here is the design. On the left, the dashed boxes are files: the EP2020 national tomography, one file per basin model, the Vs30 map, the elevation model.

  In the middle is a chain of layers, listed in a config file, each doing one job: blend the models by priority, taper the near surface from Vs30, clamp Vp over Vs, and Backus averaging.

  On the right, the same model is written for SW4 or for EMOD3D, which is what lets us run old and new workflows on identical input. The next three pairs of slides are the problems this design solves.
]

#v(0.4em)
#big(nzcvm-pipeline, cap: 150%)

// ---------------------------------------------------------------------------
== Problem: a software bottleneck
#say[
  First problem. A researcher wants to add a model or try a change, but the model is baked into the code, so one of us on the software team bakes it in.

  Now there is a parallel version to keep alive, every parameter change goes around the loop through us, and at the end it is often dropped, because merging it back was nobody's job. The researcher waits on us at every step, and we own work we did not design and cannot judge.
]

#v(1.6em)
#big(research-loop(after: false), cap: 150%)

// ---------------------------------------------------------------------------
== Solution: pushing complexity out of code into data
#say[
  The solution is to push complexity out of the code and into data. The researcher adds a model file, or writes a layer, without us. They iterate at their own pace, as many times as they like, and we integrate the end product once.

  The software team owns the core; the researcher owns the science. It also means you could test your own Vs30 map or site profile without asking us.
]

#v(1.6em)
#big(research-loop(after: true), cap: 150%)

// ---------------------------------------------------------------------------
== Problem: competing tomography models
#say[
  Second problem. Several competing tomography models exist for New Zealand, and more will come. Ayushi's preliminary results suggest there is no one-size-fits-all model: each is better in some regions than others.

  So we want to blend them. But blending means choosing what happens at the boundary between two regions: how wide the transition is, and which model wins where they overlap. That is a scientific decision, and it should be made by a researcher, not by a software engineer.
]

#grid(
  columns: (1.2fr, 1fr),
  column-gutter: 1.2em,
  align: horizon,
  problems(
    [Several competing tomography models, and more to come],
    [Preliminary results: no one model fits everywhere],
    [How do we blend tomography models together?],
  ),
  align(center, image("figures/tomography_coverage.png", height: 88%)),
)
// Generated by scripts/tomography_coverage.py. The Bassett 2025 outline is
// approximate: that model is not in nzcvm_data yet.

// ---------------------------------------------------------------------------
== Solution: alpha blending
#say[
  The solution borrows alpha blending from computer graphics. Every model carries a priority and a weight, alpha, at every point, set by the modeller. A query takes the highest priority first and composites down the list until the weights add up to one.

  On the left, the models stacked in query order, with alpha fading to zero at each regional border. On the right, what the query returns: each regional model replaces EP2020 inside and fades into it at its edges.

  New models are plug-and-play: drop a file in the directory and it sits over the existing ones. No config change, no code change.
]

#grid(
  columns: (1.35fr, 1fr),
  column-gutter: 1.0em,
  align: horizon,
  big(blend-stack, cap: 140%), big(blend-plan, cap: 140%),
)
#v(0.6em)
#note[$q = alpha_1 q_1 + (1 - alpha_1) q_2$, taken in priority order (Porter and Duff 1984). Model names are illustrative.]

// ---------------------------------------------------------------------------
== Problem: sub-grid features
#say[
  Third problem. The old code samples the velocity model at one point per grid cell, so features smaller than the grid spacing are either missed or smeared across a whole cell.

  On the left, a soft layer in the top 150 metres: the first point sample lands below it, and it vanishes. On the right, the thin edges of a basin vanish and only its thick middle survives, as a block.

  This is especially true of shallow basins like Wellington's: the current velocity model misses any basin that does not reach the depth of a grid point.
]

#v(0.6em)
#align(center, image("figures/backus_problem.png", height: 70%))
#note[Anything that falls between sampling depths is invisible to point sampling.]

// ---------------------------------------------------------------------------
== Solution: Backus averaging
#say[
  The solution is Backus averaging. Supersample inside each grid cell, then average the density, Vp, Vs, Qp and Qs of the samples in a physically consistent way, so the cell approximates its substructure.

  The orange dashed line now catches the soft surface layer, and the basin edge is graded wherever the grid lines fall. That moves the Z1.0 a model implies at a site, so it moves basin terms directly.
]

#align(center, image("figures/backus_averaging.png", height: 88%))

// ===========================================================================
//  Part 3: results
// ===========================================================================

= Evaluating the results

// ---------------------------------------------------------------------------
== Initial results: Taumarunui
#say[
  The initial results compare the new workflow against the existing pipeline, event by event, to understand which way each change pushes. Taumarunui, the recent magnitude 5.7, is typical. Bias against the recordings: SW4 in black, EMOD3D in orange, the NSHM 2022 model in blue.

  The general headline is that all these changes together give more amplification than the old workflow. Between one and about seven seconds SW4 is about 0.3 less biased in natural-log units, roughly 35 percent, well outside its confidence interval.

  The reasons, in rough order: better attenuation across velocity contrasts, Backus averaging representing shallow basins, higher-order accuracy at the surface, which is not accounted for here, and topographic effects.
]

#grid(
  columns: (0.85fr, 1.15fr),
  column-gutter: 1.0em,
  align: horizon,
  image("figures/taumarunui_bias.png", height: 88%),
  [
    #headline(
      [More amplification],
      [than the old workflow, \ in rough order of cause:],
      size: 1.7em,
    )
    #v(0.6em)
    #set text(0.82em)
    #enum(
      spacing: 0.7em,
      [Attenuation across velocity model contrasts],
      [Backus averaging representing shallow basins],
      [Higher-order accuracy at the surface \ #text(0.85em, fill: quiet.darken(20%))[(not accounted for here)]],
      [Topographic effects],
    )
  ],
)

// ---------------------------------------------------------------------------
// TODO(jake): confirm the event and station counts once the run list is final.
== Next: moderate crustal validation
#say[
  Next is validation proper: the new code on the events in Felipe's moderate crustal dataset, about fifty events of magnitude 5 to 6, compared against his published results. Both go through the mixed-effects residual analysis you would use: between-event, site-to-site, within-site.

  Our expectation is lower bias and lower site-to-site variability, from a year of improvements across the whole simulation workflow. If that holds, it is the green light for a Cybershake update next year.
]

#v(1.0em)
#big(validation-design, cap: 175%)
#v(0.8em)
#note[Expected: lower bias and $delta"S2S"$. If so, a green light for a Cybershake update next year.]

// ---------------------------------------------------------------------------
== Extension: 1 Hz against 2 Hz
#say[
  An extension already underway: what happens as the transition frequency goes up. The 2013 Cook Strait earthquake, magnitude 6.6, one SW4 simulation on the 50 metre grid, combined twice: once with the transition at 1 Hz, once at 2 Hz.

  Between 1 and 1.5 Hz the 1 Hz version is stochastic with the Vs30 amplification; the 2 Hz version is 3D, with no empirical site term. Most stations lose amplitude, about half across the domain, about thirty percent in Wellington.

  That is the inconsistency these results highlight: the low- and high-frequency paths treat site amplification differently, so 2 Hz is not yet a straight win over 1 Hz. That needs more work.
]
// Generated by plot_fas_comparison.py (BAND = 1-1.5 Hz).

#grid(
  columns: (1.3fr, 1fr),
  column-gutter: 1.2em,
  align: horizon,
  align(center, image("figures/fas_band_map.png", height: 92%)),
  [
    #headline(
      [×0.71],
      [Wellington, median EAS \ 2 Hz against 1 Hz],
      colour: perf,
    )
    #v(1.2em)
    #headline([×0.46], [Elsewhere in the domain], colour: quiet.darken(20%))
  ],
)

// ---------------------------------------------------------------------------
== Extension: Wellington basin resonance
#say[
  But select results in Wellington show what 2 Hz can add. TEPS and POTS, about two kilometres apart and both about 39 kilometres from the rupture; the 1 Hz version in black, the 2 Hz version in blue.

  Below about 0.6 Hz and above about 2.5 Hz the two are identical. At TEPS, a softer site, the 3D simulation roughly doubles the amplitude between 1 and 1.5 Hz: a basin resonance that a 1 Hz simulation cannot capture, because it hands that band to the stochastic method. At POTS, on stiffer ground, it drops by a quarter.

  Which is right is what the recorded site terms at these stations will tell us.
]
// Generated by plot_fas_comparison.py (BAND = 1-1.5 Hz).

#align(center, image("figures/fas_TEPS_POTS.png", height: 88%))
