// Cybershake NZ: where it has been, what stands between it and the NSHM, and
// what has changed since June. A 15-minute talk.
//
// Build:  typst compile main.typ
// Watch:  typst watch main.typ
//
// Preamble copied from ~/Documents/presentation/rung1.typ so this deck matches
// the existing ones. Speaker notes are `// SAY:` comments above each slide, the
// same convention as those decks -- the slides themselves carry almost no prose,
// because the argument is spoken and the written text is reserved for values
// that have to stay readable for as long as the slide is up.
//
// Arc: the past (a decade of hybrid simulations) and the goal (simulations in
// the NSHM); the three problems in the way, a few slides each; what has changed
// since June; the 1848 Marlborough rupture as a demonstration of all of it; and
// the next twelve months. The sampling and rupture-generation slides are cut
// down from the August 2026 version of this deck (git history); the solver and
// topography figures come from ~/src/gmcm_modelling_talk.
//
// Budget: ~15 slides, ~1,900 words of notes, about a minute a slide.

#import "@preview/touying:0.6.1": *
#import themes.metropolis: *

#import "figures/study-timeline.typ": study-timeline
#import "figures/nshm-weights.typ": nshm-weights
#import "figures/multi-segment-propagation.typ": multi-segment-propagation
#import "figures/source-complexity.typ": source-complexity
#import "figures/refinement.typ": refinement
#import "figures/topography-squashing.typ": topography-squashing
#import "figures/icons.typ": icon-layers, icon-refine, icon-topo
#import "palette.typ": defect, exact, perf, quiet, stat

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [Cybershake NZ: towards simulations in the NSHM],
    subtitle: [rupture selection, multi-segment ruptures, and the physics in between],
    author: [Jake Faulkner],
    date: datetime.today(),
    institution: [University of Canterbury],
  ),
  config-common(datetime-format: "[day] [month repr:long] [year]"),
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
// `cap` bounds the enlargement so a small figure on a wide slide is not blown up
// to fill it.
#let fit(body, cap: 300%) = layout(size => {
  let m = measure(body)
  let f = calc.min(size.width / m.width * 100%, cap)
  align(center, scale(f, reflow: true, body))
})

#let big(body, cap: 188%) = fit(body, cap: cap)

// A quiet line under a figure.
#let note(body) = align(center, text(0.6em, fill: quiet.darken(30%))[#body])

// Stand-in for a figure that is still being made. Typst cannot test whether a
// file exists, so a slide whose PNG is pending uses this until it lands.
#let pending(body, height: 80%) = block(
  width: 100%,
  height: height,
  stroke: (thickness: 0.8pt, paint: quiet, dash: "dashed"),
  radius: 3pt,
  align(center + horizon, text(
    0.7em,
    fill: quiet.darken(20%),
    style: "italic",
  )[#body]),
)

// A card naming one problem, or one change. Fixed height so a row of them lines
// up however long each gloss is.
#let card(title, body, accent: stat, height: 6.4cm) = block(
  fill: accent.lighten(93%),
  stroke: (top: (thickness: 3pt, paint: accent)),
  radius: 2pt,
  inset: (x: 12pt, y: 12pt),
  width: 100%,
  height: height,
  {
    text(0.85em, weight: "bold", fill: accent.darken(15%))[#title]
    v(0.4em)
    set text(0.76em)
    body
  },
)

// One change since June: a pictogram over a card.
#let change(icon, title, body) = stack(
  spacing: 0.5em,
  box(height: 3.6cm, width: 100%, align(center + horizon, fit(
    icon,
    cap: 110%,
  ))),
  card(title, body, accent: perf, height: 4.2cm),
)

#title-slide()

// SAY: A decade in one picture. Transition frequency against year -- the
// frequency above which our simulations hand over from 3D physics to a
// stochastic model. Circles are validation studies against recordings, squares
// are Cybershake, the national simulation-based hazard runs.
// Validation settled at 100 metres and 1 Hz around 2016 and has stayed there.
// Cybershake has to run thousands of simulations, so it started at a quarter of
// a hertz in 2017 and has worked up by halving the grid: 400 metres, 200, and
// now 100 metres and 1 Hz with v26. Each halving costs sixteen times as much.
// The panel on the right is what is in preparation, and the last entry is the
// one this talk is about: Cybershake on the NSHM 2022 source model.
== A decade of hybrid simulations

#v(0.3em)
#big(study-timeline, cap: 130%)

// SAY: And this is why. In NSHM 2022 the ground-motion logic tree is entirely
// empirical models: simulations carry no weight. For the next model we expect
// them to come in alongside the empirical models with a modest weight, first
// where data are thin -- long periods, basins, large magnitudes. Further out the
// balance can tip.
// The heights are not decided numbers. The point is the direction, and that each
// step has to be earned against recordings.
== Goal: simulations in the NSHM

#v(0.6em)
#big(nshm-weights, cap: 160%)

// SAY: Three things stand in the way, and the rest of the talk is a few slides
// on each.
// First, which ruptures. NSHM 2022 has seven thousand rate-bearing ruptures and
// we cannot simulate them all at the resolution we want, so we have to
// choose, and the rule we choose with matters.
// Second, how to build them. The 2022 ruptures are multi-segment: up to a
// hundred planes across many faults, with gaps between them. Our rupture
// generator took one plane at a time.
// Third, the physics in between. The ground-motion science in our workflow is
// overdue for an update: the free surface is flat, so topography is
// approximated away, and the transition frequency has been stuck at 1 Hz.
== Three things in the way

#v(1.2em)
#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 1em,
  card([1 · Rupture selection], [
    How do we select which ruptures to simulate?
  ]),
  card([2 · Multi-segment ruptures], [
    Once we have the ruptures, *how* do we simulate them?
  ]),
  card([3 · Ground-motion science], [
    How do we get the most out of what we do simulate?
  ]),
)

= Rupture selection

// SAY: The problem first. The trend in seismic hazard has been towards more
// complex sources. The older models were characteristic: the idea, from Schwartz
// and Coppersmith in 1984, that a fault ruptures end to end in its own
// characteristic earthquake. NSHM 2010 had 536 of them.
// The current models are not. They take the whole fault network and allow every
// rupture it permits -- many segments, jumping the gaps between faults,
// branching -- and an inversion sets the rates. More segments, more complex
// geometry. And the next step may be joint ruptures: crustal faults rupturing
// together with a curved subduction interface.
// And there is a tension in that trend. The more complex the ruptures, the more
// pressure on empirical ground-motion models: a multi-fault rupture that jumps
// and branches is a long way from the data they were fitted to. That is part of
// what is driving the push towards simulation-based hazard.
// But for simulation, every rupture is a full 3D wave-propagation run, and there
// are far too many to simulate them all. The same trend that makes simulation
// necessary makes simulating everything impossible.
== Trends in seismic source modelling
#v(0.2em)
#big(source-complexity, cap: 150%)
#v(1fr)
// The tension: the same trend pushes towards simulation and makes simulating
// everything impossible. Two cards facing each other across a "but".
#let side(accent, title, body) = block(
  width: 100%,
  fill: accent.lighten(93%),
  stroke: (left: (thickness: 3pt, paint: accent)),
  inset: (x: 0.9em, y: 0.55em),
  radius: 2pt,
  {
    text(0.72em, weight: "bold", fill: accent.darken(10%))[#title]
    linebreak()
    text(0.72em)[#body]
  },
)
#grid(
  columns: (1fr, auto, 1fr),
  column-gutter: 0.8em,
  align: horizon,
  side(exact, [Empirical models under pressure], [
    complex ruptures sit outside calibration range, \ driving the push to simulated hazard
  ]),
  text(0.9em, style: "italic", fill: quiet.darken(25%))[but],
  side(defect, [Simulation can't run them all], [
    every simulation is too expensive to run 1000's
  ]),
)
#v(0.5em)

// SAY: And New Zealand is not alone here. The United States made the same move
// first: UCERF3, the California model -- carried across the western US by the
// 2023 national model, NSHM23 -- replaced a short list of characteristic
// ruptures with a fault-system inversion over a quarter of a million
// multi-fault ruptures. NSHM 2022 did the same for New Zealand: seven thousand
// rate-bearing ruptures, against 536 in 2010.
// With that many more events it is obvious that we cannot simulate them all,
// and anyone simulating either model faces the same question: which ruptures do
// we pick? So we have to be smarter about how we choose them.
== Not just a New Zealand problem

#v(0.2em)
#align(center, image("out/png/world-map.png", height: 86%))
#note[countries are beginning to adopt non-characteristic models]

// SAY: So the question for this section. We want to simulate the ruptures that
// matter for hazard -- but which ruptures matter is exactly what the hazard
// calculation would tell us, and we have not run it yet. Simulations are how we
// were going to compute it. That circularity is the problem.
== The question

#v(1fr)
#align(center, block(width: 85%, text(1.5em, style: "italic", fill: exact)[
  How do we select the meaningful ruptures to simulate, from hazard we haven't computed yet?
]))
#v(1fr)

// SAY: The current rule sets the number of realisations from magnitude alone.
// Here is why that is the wrong variable. Three real NSHM 2022 ruptures: the
// full Alpine Fault at 8.5, a nineteen-segment Canterbury foothills rupture at
// 7.5, and a single fault under Christchurch at 7.0. Ask an empirical
// ground-motion model what each contributes to hazard at Christchurch, and the
// order inverts: the foothills rupture is largest, and the Alpine Fault, the
// biggest event in the model, is at twelve percent of it.
// No function of magnitude, area or rate can produce that ranking. The
// ground-motion model can, because it is the only one that knows where the site
// is. So: use the empirical model to decide which ruptures are worth simulating.
// Not to replace the simulations -- to rank them.
== Let the empirical model rank the ruptures

#v(-0.1em)
#align(center, image("out/png/key-idea.png", width: 99%))

// SAY: What it buys: error against core-hours actually spent, at three South
// Island sites. Green is uniform sampling, blue dashed the magnitude rule,
// orange the GMM-ranked sampling logic tree -- which splits the budget between
// covering the hazard and reducing its variance, with weights the way the NSHM
// weights its own branches.
// At about a thousand simulations the magnitude rule is at twenty-three, forty
// and sixteen percent error. The logic tree is at seven, ten and five. Three to
// four times more accurate for the same spend.
== What smarter selection buys

#v(0.15em)
#align(center, image("out/png/core_hour_efficiency.png", width: 94%))

= Multi-segment ruptures

// SAY: Once a rupture is chosen it has to be built. On the right is one NSHM
// 2022 rupture: twenty-six planes across four faults. The planes do not meet --
// there are real gaps the rupture has to jump. On the left, the Hikurangi
// interface as the Community Fault Model ships it, curved in two directions.
// Neither of these is something the planar kinematic generator could take.
== What we have to build

#v(-0.1em)
#align(center, image("out/png/generator-preview.png", width: 99%))

// SAY: For multi-segment ruptures the new generator does two things. The path
// through the segments is sampled, from Shaw--Dieterich jump probabilities,
// exactly from the distribution over trees rooted at the hypocentre -- not
// greedily and not by hand. And the jump point is computed: the rupture leaves a
// fault from where its front arrests, and the onset time carries across the
// jump, so rupture time is continuous over the whole source. The previous
// realisation files record a jump point fitted by closest approach; we discard
// it and recompute it.
// You will see this happen in a few minutes.
== Sampled path, computed jump

#v(0.4em)
#big(multi-segment-propagation, cap: 200%)
#note[bootstrapped multi-segment rupture model from existing rupture generators]

= Since June

== Four changes since June

#v(0.8em)
#grid(
  columns: (1fr, 1fr, 1fr, 1fr),
  column-gutter: 0.8em,
  change(icon-layers, [Velocity model], [
    Replaced: models assembled from data, not baked into code.
  ]),
  change(icon-topo, [Topography], [
    Explicit, on a curvilinear free surface.
  ]),
  change(icon-refine, [Solver], [
    EMOD3D swapped wholesale for SW4, with mesh refinement.
  ]),
  change(fit(multi-segment-propagation, cap: 60%), [Rupture generator], [
    New, publicly available, multi-segment.
  ]),
)

= Ground-motion science

// SAY: Topography. With a flat free surface the topography has to go somewhere.
// On the left is the truth: the top of the model is a curvilinear mesh that
// follows the real surface, over an ordinary Cartesian grid, and the slow
// near-surface layers sit at their real depth under hills and valleys alike.
// On the right is what previous Cybershake runs did, squashed-tapered: the
// surface is flattened to sea level and the column from the hilltop down to a
// taper depth is squeezed into the space below it. Same layers, but under every
// hill they come out thinner -- the slow material is squashed, so the site
// looks stiffer than it is, exactly where topography would amplify. Basins get
// it twice over. An elevated basin like Hanmer sits high, so its sediments are
// compressed in proportion to how high it sits: the basin we simulate is
// shallower than the real one, and basin amplification is underpredicted.
// With the conforming mesh, ridge, valley and basin response are all in the 3D
// motion, not added afterwards.
== Topography: from approximated to explicit

#v(1.2em)
#big(topography-squashing, cap: 200%)
#note[same layers and basin; the flat grid squashes them thinner the higher they sat]

// SAY: And the transition frequency. To carry a frequency the grid has to
// resolve the slowest material, and cost goes as grid spacing to the minus four:
// 2 Hz on a uniform grid is sixteen times 1 Hz. The way out is that the slow
// material is only near the surface. Variable mesh refinement doubles the
// spacing at each interface going down -- 50, 100, 200, 400 metres -- and stays
// under what a 2 Hz wave needs at every depth, where the old code paid for the
// surface spacing all the way to 50 kilometres. Even refined, two thirds of the
// grid points are in the top kilometre and a half.
== Towards 2 Hz: variable mesh refinements

#v(1.0em)
#big(refinement, cap: 165%)


// SAY: How far we have come since June. Four changes, each of which is a
// project in its own right.
// TODO(jake): say which of these are in the production workflow yet.
// The velocity model is replaced: a new codebase that assembles tomography,
// basin and geotechnical models from configuration, so researchers can plug in
// a model without touching code. Topography is explicit. The solver is swapped
// wholesale, EMOD3D for SW4, which is what makes the topography and the
// refinement possible. And the rupture generator is new and public, with the
// multi-segment algorithm from two sections ago.
// TODO(jake): link for the public rupture generator.

= Showcase: Marlborough 1848

#text(0.55em, fill: quiet.darken(20%))[Source geometry: Aisling O'Kane (VUW)]

// SAY: One event with every change in it: the 1848 Marlborough
// earthquake, Mw 7.2 here, run in SW4 with explicit topography through the new
// velocity model.
// The rupture starts at the star and runs both ways along the fault: north to
// the coast at Blenheim, south and round the bend at the southern end. Then the
// rupture is over, the Wairau basin under Blenheim keeps ringing for another
// twenty seconds after the fault has stopped, and
// waves run out across Cook Strait. Last, the strongest shaking felt: strong in
// Wellington and Nelson, moderate in Christchurch.
// TODO(jake): the rupture is three segments (Awatere NE1, NE2, Barefell), but
// the movie draws them as one continuous trace, so no jump is visible. Either
// re-render with the segments drawn or keep this framing.
== Marlborough 1848, in SW4 with topography

// Three stills from out/marlborough-highlight.mp4 in place of the video, cut
// with ffmpeg at 7.5 s, 11.5 s and 19.5 s.
// The rupture is the large frame; the other two stack beside it at half height.
#let still(slug, caption, height) = stack(
  spacing: 0.3em,
  image("out/png/marlborough-still-" + slug + ".png", height: height),
  text(0.55em, fill: quiet.darken(25%))[#caption],
)

#v(1fr)
#align(center, grid(
  columns: 2,
  column-gutter: 0.6em,
  still("rupture", [Rupture runs both ways along the fault segments], 9.6cm),
  stack(
    spacing: 0.5em,
    still("basin", [Rupture over; the Wairau basin keeps ringing], 4.2cm),
    still("endcard", [Strongest shaking felt], 4.2cm),
  ),
))
#v(1fr)

// SAY: Topography, at two places where it matters. On the left, the Otira
// Viaduct: the main road over the Southern Alps between Canterbury and the West
// Coast, a viaduct on the floor of a steep alpine gorge. On the right, Brooklyn,
// a hillside suburb of Wellington, the capital. The experiment is the one a field
// study would do: spectral acceleration at a ridge site over a reference site a
// few kilometres away, with near-identical Vs30, so topography is the main
// difference between them.
// Otira: a 160 metre ridge above the SH73 valley gets 1.2 to 1.6 times the
// shaking of the valley floor between 1 and 5 seconds, peaking near 2.8 times at
// 2 seconds -- a period our earlier 0.5 Hz runs handed to the stochastic method
// and could not see. One event at 150 km, so treat the peak as one sample.
// Brooklyn's 45 metres of relief barely registers: within a few percent of one
// at 3 seconds, about 1.25 near 2 seconds. Both sit on the ensemble
// from our 81-event topography study.
// (Prefilter arm. Explicit topography only: this event has no flat-surface
// companion run, so the paper's NT check is not available here.)
== Topography on this rupture: Otira Viaduct and Wellington

// One column per ridge/reference pair: what is there, where the two sites sit,
// and the ratio, drawn large. The panels are separate PNGs from
// scripts/plot_marlborough_topo.py so the photos can sit beside the maps.
#let pair(name, gloss, sites, photo, slug, credit) = stack(
  spacing: 0.35em,
  {
    text(0.8em, weight: "bold", fill: exact)[#name]
    h(0.5em)
    text(0.6em, fill: quiet.darken(25%))[#gloss]
  },
  align(right, text(0.5em, fill: quiet.darken(25%))[#sites]),
  grid(
    columns: (1.33fr, 1fr),
    column-gutter: 0.4em,
    align: horizon,
    image(photo, height: 4.4cm, width: 100%, fit: "cover"),
    image("out/png/marlborough-topo-" + slug + "-map.png", height: 4.4cm),
  ),
  image("out/png/marlborough-topo-" + slug + "-ratio.png", width: 100%),
  text(0.38em, fill: quiet)[Photo: #credit],
)

#v(0.1em)
#grid(
  columns: (1fr, 1fr),
  column-gutter: 1.2em,
  pair(
    [Otira Viaduct],
    [highway through the Southern Alps],
    [2.9 km apart · $H_(1250)$ 163 / 1 m · $V_(S 30)$ 850 / 801 m/s · $R_"rup"$ 153 km],
    "figures/photos/otira-viaduct.jpg",
    "otira",
    [David Palmer, CC BY-SA 4.0, via Wikimedia Commons],
  ),
  pair(
    [Brooklyn, Wellington],
    [hillside suburb of the capital],
    [1.3 km apart · $H_(1250)$ 45 / 1 m · $V_(S 30)$ 719 / 715 m/s · $R_"rup"$ 59 km],
    "figures/photos/brooklyn-1977.jpg",
    "brooklyn",
    [Archives New Zealand (1977), CC BY 2.0, via Wikimedia Commons],
  ),
)

// SAY: And the sum total: everything that changed, against the empirical
// logic tree NSHM 2022 would use for this rupture. Spectral acceleration at 3
// seconds, a period the 3D simulation resolves well, as the log of simulated
// over the logic-tree prediction, at fifty-seven thousand sites.
// On average the simulation is about twice the empirical model: an event term
// of plus 0.76, a bit under one sigma. It is high at Blenheim and Wellington
// alike, and roughly flat with distance, so most of it is a level offset rather
// than a difference in attenuation.
// On top of that offset is the pattern the empirical model cannot have: a
// strong band running southwest along the ranges, and the Taranaki side of the
// North Island below the prediction.
// TODO(jake): check the band along strike to the SW (directivity off the
// southern bend, or the Southern Alps?) and whether +0.76 is the source,
// before saying why. Event term is an unweighted site mean, not mixed-effects.
== The sum total, against the logic tree

// The event term comes from the script's JSON, so the slide cannot drift from
// the figure.
#let residual = json("out/png/marlborough-residual.json")

#grid(
  columns: (auto, 1fr),
  column-gutter: 1.2em,
  align: horizon,
  image("out/png/marlborough-residual-map.png", height: 92%),
  stack(
    spacing: 0.8em,
    align(center, text(2.6em, weight: "bold", fill: exact)[
      #if residual.event_term >= 0 [+]#residual.event_term
    ]),
    image("out/png/marlborough-residual-distance.png", width: 100%),
  ),
)

// SAY: The next twelve months. On the physics: a transition frequency of 2 Hz
// and above, which the refinement now makes affordable. The domain reduction
// method, so we can run a small, fine domain around a site inside a large,
// coarse one. And the inputs: the new Bassett velocity model, a new Vs30 model,
// and more sedimentary basins.
// On the source: the rupture generator gets joint ruptures and curved
// ruptures, through the same code as the multi-segment crustal ones.
// TODO(jake): one line on what "joint ruptures" means here.
// Then: the selected NSHM 2022 ruptures, through all of it.
== The next twelve months

#v(0.8em)
#grid(
  columns: (1fr, 1fr),
  column-gutter: 1.2em,
  card([Wave propagation], height: 7.4cm, [
    #set text(1.25em)
    - 2+ Hz transition frequency
    - Domain reduction method (DRM)
    - New Bassett tomography model
    - New $V_(upright(S) 30)$ model
    - More sedimentary basins
  ]),
  card([Source], height: 7.4cm, [
    #set text(1.25em)
    - Rupture generator: joint ruptures and curved ruptures
  ]),
)
