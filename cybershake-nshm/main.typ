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
#import "figures/rupture-steps.typ": jump-graph, jump-timing, rupture-plan
#import "figures/source-complexity.typ": source-complexity
#import "figures/refinement.typ": refinement
#import "figures/topography-squashing.typ": topography-squashing
#import "figures/icons.typ": icon-layers, icon-refine, icon-topo
#import "palette.typ": defect, exact, perf, quiet, stat

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [Cybershake NZ: towards simulations in the NSHM],
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

// Scale a figure to fill a box of fixed height, whichever of its width or
// height runs out first.
#let fill-box(body, height) = box(height: height, width: 100%, layout(size => {
  let m = measure(body)
  let f = calc.min(size.width / m.width, size.height / m.height) * 100%
  align(center + horizon, scale(f, reflow: true, body))
}))

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

// SAY: How the new generator builds a multi-segment rupture, in three steps,
// on a small made-up system: five segments, stepovers of two to six kilometres.
// Every number here is the generator's own output.
// One, the path. Each gap gets a Shaw--Dieterich jump probability, certain
// under a kilometre and decaying over three. The rupture is a tree rooted at
// the hypocentre; we can sample trees exactly from that distribution, or take
// the likeliest, which is the maximum spanning tree -- heavy here. The B--D
// link closes a cycle, so the tree drops it.
// Two, the fields. Each segment draws its own slip and onset, scaled to its
// own magnitude: this is A, with the front spreading from the star.
// Three, the jump. The child starts where the front first reaches it: the
// parent's onset at the departure cell plus the shear-wave crossing time,
// earliest over every pair within reach. The front leaves A at 7.1 seconds,
// crosses in 0.65, and B starts at 7.8. Rupture time is continuous over the
// whole source. The previous realisation files record a jump point fitted by
// closest approach; we discard it and recompute it.
// You will see this happen in a few minutes.
== Sampled path, computed jump

#let steps = json("out/png/rupture-steps.json")
#let step(n, title, figure, caption) = stack(
  spacing: 0.35em,
  text(0.7em, weight: "bold", fill: stat)[#n #h(0.2em) #text(fill: exact)[#title]],
  fill-box(figure, 3.9cm),
  align(center, text(0.5em, fill: quiet.darken(30%))[#caption]),
)

#v(-0.3em)
#fill-box(rupture-plan(steps), 5.2cm)
#v(0.2em)
#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 1em,
  step(1, [Path], jump-graph(steps), [
    Jump probability $P(d) = e^(-(d - delta) \/ d_0)$ on every gap; \
    the likeliest tree is the maximum spanning tree
  ]),
  step(2, [Fields], image("out/png/rupture-steps-slip.png", height: 3.9cm), [
    Slip and onset drawn on each segment, \
    scaled to its own magnitude
  ]),
  step(3, [Jump], jump-timing(steps), [
    Child starts at the earliest parent onset \
    plus crossing time, within reach
  ]),
)

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
#note[An unexpected difference: elevated basins suffer under traditional squashed-tapered topographic surrogate]

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
// with ffmpeg at 7.5 s, 11.5 s and 19.5 s and cropped to the same 1080 x 780
// window on the action (x offsets 470, 280 and 450, y offset 165, of
// 1920 x 1080), so the three sit side by side at one size. The crop drops the
// movie's title, clock and colourbar, so the captions carry the clock.
#let still(slug, caption) = stack(
  spacing: 0.4em,
  image("out/png/marlborough-still-" + slug + ".png", width: 100%),
  align(center, text(0.55em, fill: quiet.darken(25%))[#caption]),
)

#v(1fr)
#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 0.6em,
  still("rupture", [14 s: rupture propagating over multi-segment fault]),
  still("basin", [27 s: rupture over, reverberation in the Nelson basin]),
  still("endcard", [Strongest shaking felt]),
)
#v(1fr)

// SAY: Topography, at two places where it matters. On the left, the Otira
// Viaduct: the main road over the Southern Alps between Canterbury and the West
// Coast, a viaduct on the floor of a steep alpine gorge. On the right,
// Sugarloaf, the summit of the Port Hills above Christchurch, under the 121
// metre Kordia transmission tower. The experiment is the one a field study
// would do: spectral acceleration at a site over reference sites a few
// kilometres away, with similar Vs30, so topography is the main difference
// between them. The references have to be flat at every scale the waves see,
// not just locally: every site flat at the 1, 2.5 and 5 km scales. A site that
// looks flat close up can sit in a valley at the 5 km scale, and valleys shake
// less, so a valley reference inflates the ratio.
// Otira: the road runs along the floor of the gorge; the ridge station is
// 950 metres higher, three kilometres east. Against flat sites, the slopes
// above the road shake 1.5 to 2.2 times as hard between 1 and 3 seconds -- a
// band our earlier 0.5 Hz runs handed to the stochastic method and could not
// see. The valley floor at the viaduct goes the other way: about half at
// 2 seconds. So the hazard to this road is what comes down the slopes onto
// it. At these periods that means large, deep-seated landslides like Falling
// Mountain in 1929; rockfall is a short-period problem the simulation doesn't
// resolve. The viaduct is not simply shielded, though: at 1 second it is
// about 1.5 times a flat site.
// Absolute shaking here is small, 0.01 g at 150 km. What carries over to a
// close event, an Alpine Fault rupture, is the ratio. Only three flat sites
// qualify in this terrain, so treat it as one sample.
// At Sugarloaf that is fifteen rock sites round the flanks and the harbour;
// the Vs30 condition is what keeps the Christchurch basin out.
// Sugarloaf: nothing at 1 to 2 seconds, then the ratio climbs to about 1.6 at
// 3 seconds and peaks near 2.4 at 4 seconds, above every one of the fifteen
// references. The field arrays on the Port Hills saw ridge amplification at
// 1 to 3 hertz, from the crest's own shape. This is a different scale: the
// whole massif, five to ten kilometres across, amplifying at 3 to 5 seconds.
// Same hill, different feature, depending on the period you look at.
// (Prefilter arm. Explicit topography only: this event has no flat-surface
// companion run, so the paper's NT check is not available here.)
== Topography on this rupture: Otira Viaduct and the Port Hills

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
    [key pass through Alps],
    [ridge 1840 m, viaduct 891 m · 3 flat references, 2–11 km · $V_(S 30)$ 850 / 801 m/s · $R_"rup"$ 153 km],
    "figures/photos/otira-viaduct.jpg",
    "otira",
    [David Palmer, CC BY-SA 4.0, via Wikimedia Commons],
  ),
  pair(
    [Sugarloaf, Port Hills],
    [Christchurch, over tunnel to major port],
    [15 flat rock references, 2–9 km · $H_(1250)$ 95 m · $V_(S 30)$ 1038 / 839–1033 m/s · $R_"rup"$ 168 km],
    "figures/photos/sugarloaf-bowenvale.jpg",
    "sugarloaf",
    [Michal Klajban, CC BY-SA 4.0, via Wikimedia Commons],
  ),
)

// SAY: And the sum total: everything that changed, against the empirical
// logic tree NSHM 2022 would use for this rupture. Spectral acceleration at 3
// seconds, a period the 3D simulation resolves well, as the log of simulated
// over the logic-tree prediction, at fifty-seven thousand sites.
// On average the simulation is about twice the empirical model: an event term
// of plus 0.76, a bit under one sigma. It is high at Blenheim and Wellington
// alike. On the right, the simulated 3-second motion itself in g against
// distance: the density of stations, and the geometric mean through them.
// On top of that offset is the pattern the empirical model cannot have: a
// strong band running southwest along the ranges, and the Taranaki side of the
// North Island below the prediction.
// TODO(jake): check the band along strike to the SW (directivity off the
// southern bend, or the Southern Alps?) and whether +0.76 is the source,
// before saying why. Event term is an unweighted site mean, not mixed-effects.
== The sum total, against the logic tree

#grid(
  columns: (auto, 1fr),
  column-gutter: 1.2em,
  align: horizon,
  image("out/png/marlborough-residual-map.png", height: 92%),
  image("out/png/marlborough-residual-distance.png", width: 100%),
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
    - Joint crustal-subduction ruptures
    - Curved ruptures
  ]),
)
