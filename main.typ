// Rupture sampling and rupture generation for NSHM 2022.
//
// Build:  typst compile main.typ
// Watch:  typst watch main.typ
//
// Preamble copied from ~/Documents/presentation/rung1.typ so this deck matches
// the existing ones. Speaker notes are `// SAY:` comments above each slide, the
// same convention as those decks -- the slides themselves carry almost no prose,
// because the argument is spoken and the written text is reserved for values
// that have to stay readable for as long as the slide is up.

#import "@preview/touying:0.6.1": *
#import themes.metropolis: *

#import "figures/psha-pipeline.typ": psha-pipeline
#import "figures/cybershake-timeline.typ": cybershake-timeline
#import "figures/scale-ladder.typ": scale-ladder
#import "figures/magnitude-blind.typ": magnitude-blind
#import "figures/bias-variance-curves.typ": bias-variance-curves
#import "figures/two-strategies.typ": two-strategies
#import "figures/objectives-fan.typ": objectives-fan
#import "figures/nshm-logic-tree.typ": nshm-logic-tree
#import "figures/sampling-logic-tree.typ": sampling-logic-tree
#import "figures/solve-and-project.typ": solve-and-project
#import "figures/multi-segment-propagation.typ": multi-segment-propagation
#import "palette.typ": defect, exact, perf, quiet, stat

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [Which ruptures should we simulate, and how do we build them?],
    subtitle: [a sampling logic tree for Cybershake NZ, and multi-segment and curved rupture generation],
    author: [Jake Faulkner],
    date: datetime(year: 2026, month: 8, day: 25),
    institution: [University of Canterbury],
  ),
  config-common(datetime-format: "[day] [month repr:long] [year]"),
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

// A tinted panel marking one of the two departures from the genslip framework.
#let addition(title, body) = block(
  fill: stat.lighten(93%),
  stroke: (thickness: 0.8pt, paint: stat.lighten(35%)),
  radius: 3pt,
  inset: (x: 8pt, y: 7pt),
  width: 100%,
  {
    text(0.62em, weight: "bold", fill: stat.darken(15%))[#title]
    v(0.25em)
    body
  },
)

#title-slide()

// SAY: Orientation before anything else, because the two halves of this talk sit
// in different places in one pipeline.
// Across the top: you choose which ruptures to run, you build each one as a
// finite-fault model, you simulate it, and you turn the ground motions into
// hazard. Four stages. Everything I have to say is about the first two -- I am
// not touching the wave solver and I am not touching how the hazard integral is
// assembled.
// Underneath, where we are. Two lanes: the source model below, the simulation
// campaign above, and the gap between them is the story. NSHM 2010: 536
// characteristic ruptures. Cybershake NZ v19.5 simulates it -- nine years later,
// at 400 metre resolution. NSHM 2022 lands with 7,162 rate-bearing ruptures out
// of nearly half a million. The campaign is at 200 metres and has just brought
// subduction sources in. And today we are pointing a 100 metre model at NSHM
// 2022.
// Every step down in grid spacing is a factor of sixteen in cost, and the source
// model got two orders of magnitude bigger on the way. That is the squeeze the
// next four slides are about.
== Where this sits

#v(-0.1em)
#fit(psha-pipeline, cap: 168%)
#v(1.1em)
#fit(cybershake-timeline, cap: 150%)

= Sampling

// SAY: Three campaigns, and every number here is either measured or costed off
// measurements -- none of it is an order-of-magnitude hand-wave.
// Top bar: Cybershake NZ v25.6. The current campaign -- 200 metre grid, NSHM
// 2010 source, sixteen thousand simulations -- 4.7 million core-hours. That is
// what a COMPLETE Cybershake campaign costs today.
// Middle bar: our NSHM 2022 pilot. 293 simulations. At 100 metres. 3.7 million
// core-hours, measured, not estimated. Read those two against each other: we
// spent nearly eighty percent of an entire campaign on 293 simulations.
// Per simulation that is 293 core-hours against 12,765 -- a factor of 44. Halving
// the grid is sixteen of it; the rest is that v25.6 spans a whole catalogue
// including small cheap events while the pilot is large crustal ruptures only.
// Bottom bar: every rate-bearing rupture in NSHM 2022, once each, at 100 metres.
// 140 million core-hours. Thirty times the entire v25.6 campaign, and past the
// dashed line, which is the largest allocation anyone in Europe can apply for.
// And one realisation each is not a hazard estimate -- it is one sample per
// rupture. So we are not going to simulate the catalogue. We are going to sample
// it, and the only question that matters is how.
== A complete campaign buys 293 ruptures at 100 m

#v(-0.2em)
#big(scale-ladder)

// SAY: Here is how Cybershake NZ decides how many realisations a rupture gets.
// It is a function of magnitude and of nothing else. Above Mw 8 it saturates at
// 68 realisations.
// Now: these two ruptures. Both above 8, so both get 68. On this curve they are
// not two points, they are ONE point -- they differ by 0.03 in magnitude.
// But one of them is the Alpine fault at one in thirty thousand years, and the
// other is a seven-fault Wellington combination at one in three point two
// MILLION years. Two orders of magnitude apart in how often they happen.
// Same sampling weight. And the rarer one costs 68% more to simulate, because
// it is slightly bigger. We are spending more compute on the rupture that
// matters less. Not by accident -- by construction, because rate is not an
// input to the rule.
== The rule is a function of magnitude and nothing else

#v(-0.2em)
// Two stages. Stage one is the rule on its own; stage two adds the pair it
// cannot distinguish. The hidden elements still occupy their space in stage one
// (see the figure's header), so the axes do not shift between the two.
#only("1", big(magnitude-blind(pair: false)))
#only("2-", big(magnitude-blind(pair: true)))

// SAY: This is the whole idea, and it is not complicated.
// Three real ruptures from NSHM 2022, drawn to scale. In blue, a full Alpine
// Fault rupture -- a hundred and three segments, nine hundred kilometres across,
// magnitude 8.53. The biggest earthquake in the model. In orange, a
// nineteen-segment rupture in the Canterbury foothills, magnitude 7.49. In
// green, a single fault more or less underneath Christchurch, magnitude 6.99.
// Put them through an empirical ground-motion model, which knows magnitude,
// distance and site condition, and ask what each one contributes to the
// exceedance rate at Christchurch.
// The order comes back inverted. The foothills rupture is the largest
// contributor. The little single fault next door is at seventy-one percent of
// it. And the full Alpine Fault -- the biggest event in the model -- is at
// twelve percent. It is far away, and it is rare.
// Magnitude ranks these 8.53, 7.49, 6.99. Hazard ranks them 7.49, 6.99, 8.53.
// No function of magnitude alone can produce that ordering. No function of area
// alone, no function of rate alone. The ground-motion model produces it by
// construction, because it is the only one of them that knows where the site is.
// That is the claim: use the empirical model to decide which ruptures are worth
// simulating. It is not a substitute for simulating them -- it has no basins, no
// topography, no directivity -- but it is more than good enough to rank them.
== The key idea

#v(-0.1em)
#align(center, image("out/png/key-idea.png", width: 99%))

// SAY: Every one of these rules is guessing at the same number.
// Horizontal: how many ruptures you simulate. Vertical: how much of this site's
// hazard you actually cover. The gap to the top is the bias -- and I mean that
// literally, bias in this estimator is the summed hazard of the ruptures you
// never ran.
// Blue is ranking by magnitude: the New Zealand rule. It is ALSO the SCEC area
// rule -- area is a deterministic function of magnitude under the scaling
// relation, so the two rank the catalogue identically. Spearman rho of exactly
// one. Two institutions, one heuristic.
// Green is ranking by rate, which is the Poisson-catalogue instinct.
// Orange is ranking by what the empirical ground-motion model says the rupture
// actually contributes at this site.
// At five hundred ruptures: forty percent, fifty-two, eighty-six. The empirical
// model roughly doubles the hazard you cover for the same compute.
// So: magnitude, area, rate. Every one of them is a one-variable regression onto
// hazard. We re-invented bad GMPEs. Thirty years of empirical ground-motion
// modelling already solved this, and we can just use it.
// The assumption, and say it before someone asks: the GMM is not the simulator.
// The simulations exist precisely because they add basin response, topography,
// directivity. The claim is only that the two agree in AGGREGATE across many
// sites and ruptures -- enough to rank ruptures, nowhere near enough to replace
// simulating them.
== Every rule is guessing at the same number

#v(-0.15em)
#align(center, image("out/png/hazard-coverage.png", width: 99%))

// SAY: If we are going to use the empirical model, notice it hands us two
// quantities per rupture, not one.
// Left: divide out the rate. Hazard contribution goes like P -- straight line,
// biggest when the rupture almost certainly exceeds. Variance goes like root
// P one-minus-P -- an arch, peaking at a half.
// These are not the same ruptures. A rupture that almost certainly exceeds
// carries a lot of hazard and almost no uncertainty: you already know the
// answer. But you still have to run it ONCE, or it falls into the unsampled sum
// and becomes bias. A rupture on the fence carries the uncertainty, and that is
// where running it repeatedly pays.
// So bias is a question about coverage and variance is a question about
// replication, and no single allocation is optimal for both.
// Right: two strategies out of one model, and a weight between them that is the
// modeller's to set.
// (Both branches ship now. The weight is a quarter on variance, three quarters
// on bias -- the next slide but one has the numbers.)
== Two strategies out of one model

#v(-0.1em)
#grid(
  columns: (1fr, 1fr),
  column-gutter: 1.1em,
  align: horizon,
  fit(bias-variance-curves, cap: 205%),
  fit(two-strategies, cap: 160%),
)

// SAY: The obvious fix is "sample proportional to rate", or "minimise hazard
// variance". But that presumes there is one objective. There is not.
// Cybershake output is not only used for PSHA. Surrogate modelling needs broad
// coverage in magnitude, distance, site condition, geometry -- a hazard-variance
// objective will not give you that. Scenario work wants prescribed events.
// And we owe the fault-geometry people at least one rupture on every fault.
// The top branch is the important one: even INSIDE PSHA the objectives diverge.
// Weight sites by population and you are sampling for cities. Weight by area and
// you are sampling for distributed infrastructure -- transmission, road and rail
// -- which is exposed over territory rather than at points. In practice the
// first pulls density toward the North Island and the second toward the South,
// with a visible effect at Southland sites. Same physics, same code, different
// answer, and there is no fact of the matter about which is correct -- it
// depends on who is asking. So we stopped trying to find the objective
// function.
== One budget, several incompatible objectives

#v(-0.1em)
#big(objectives-fan, cap: 178%)

// SAY: Instead we do what this room already does with epistemic uncertainty.
// On the left is an excerpt of your own source-model tree: deformation model
// crossed with time dependence, weights stated, branches combined.
// On the right is ours, deliberately the same shape. Level one is tectonic type
// -- 0.25 against 0.75, which is not a stakeholder statement, it is how far we
// trust the subduction workflow relative to crustal.
// Everything on the right is computed from lambda and P, and P is not something
// we have before simulating -- we estimate it from the NSHM 2022 empirical
// ground-motion model, as a surrogate for the simulations. That is the move from
// four slides ago: the surrogate is not a substitute, it has no basins or
// topography, but it agrees well enough in aggregate to RANK ruptures, and a
// ranking is all an allocation needs.
// Level two is the objective crossed with the site weighting. Note the split:
// variance gets a quarter, bias three quarters. That is not a hunch. Error here
// is bias-dominated, and we swept the split -- RMSE bottoms out somewhere around
// an eighth to a quarter on variance and climbs steeply above it. There is a
// physical reason too: the Neyman weight comes from empirical ground-motion
// models, whose sigma is a good deal larger than a simulation's, so it
// overstates the variance there is to reduce.
// Within each objective, population against area, half and half -- the
// disagreement from two slides ago, left unresolved on purpose.
// One honest caveat, and it is the line under the figure. The bias leaves are
// not independent of the variance leaves: they rank only the ruptures the
// variance leaves did not already cover. We tried it independently first and it
// made things WORSE -- the two rankings correlate at nought point nine six, so
// they duplicate each other, total coverage falls and bias goes up. So this is a
// sequence of conditional allocations, not a set of independent alternatives.
== Borrow the grammar you already use

#v(-0.35em)
#grid(
  columns: (1fr, 1.06fr),
  column-gutter: 0.7em,
  align: horizon,
  fit(nshm-logic-tree, cap: 170%),
  fit(sampling-logic-tree, cap: 170%),
)
#v(-0.05em)
#align(center, text(0.58em, fill: quiet.darken(30%))[
  bias leaves rank only the ruptures the variance leaves did not sample
])

// SAY: And here is what it buys, on the only test that matters: error against
// core-hours actually spent, at three South Island sites, crustal ruptures only.
// Green is naive uniform sampling. Blue dashed is the magnitude rule. Orange is
// the logic tree.
// At twenty million core-hours -- about a thousand simulations -- the magnitude
// rule sits at twenty-three, forty and sixteen percent error. The logic tree is
// at seven, ten and five. Between three and four times more accurate for the
// same spend, and that gap widens as the budget grows.
// Two things to be honest about. The grey subtitle on each panel is the share of
// hazard we are not simulating at all -- subduction and background seismicity --
// which is sixty-three percent at Christchurch. That sets a floor no sampling
// scheme can get under. And these curves are the crustal problem only, weighted
// to South Island sites, because that is the part we have measured cost for.
== What the tree buys

#v(0.15em)
#align(center, image("out/png/core_hour_efficiency.png", width: 94%))

= Rupture generation

// SAY: Before the mechanics, here is what we are actually building. Both of
// these are real geometry, not sketches.
// On the left, the Hikurangi interface exactly as the Community Fault Model
// ships it -- nine thousand triangles, seven hundred kilometres across, reaching
// seventy-five kilometres down. Curved in two directions. That is the surface
// the generator has to put a slip distribution on.
// On the right, one NSHM 2022 rupture: twenty-six planes across four faults,
// Hororata, Kowai-View Hill, Starvation-Ashley and Torlesse. It is the same
// rupture from the key-idea slide. Note the planes do not meet -- there are real
// gaps the rupture has to jump.
// Vertical is exaggerated on both, six times on the left and just over two on
// the right, and it says so on the panels. At true scale the interface is ten
// times wider than it is deep and the curvature would be invisible.
// Neither of these is something the planar kinematic generator can take.
== What we have to build

#v(-0.1em)
#align(center, image("out/png/generator-preview.png", width: 99%))

// SAY: Second half. Same model, different problem: once you have chosen a
// rupture, you have to build it.
// The row along the top is the kinematic rupture generator you already know --
// slip as a von Karman field, rise time and rupture time partly correlated with
// it, rake drawn independently. We rebuilt that, and I want to be clear that it
// is a reimplementation: same statistical model, von Karman, Hurst 0.75, Mai and
// Beroza corner lengths. We get the same field by a different route. That is a
// credibility claim, not a contribution.
// The two shaded boxes are the contributions.
// Left: curved ruptures. We fit a plane to the interface by SVD, sample every
// field on that flat plane exactly as we would for a crustal fault, and project
// back. The subduction interface goes through the SAME generator -- so results
// are comparable across tectonic types instead of coming out of two codebases.
// Worth volunteering, because someone will ask: we solve in the plane, so path
// lengths are short by the surface's own stretch. Measured on the CFM
// interfaces that is a median of minus 0.14 to plus 0.03 seconds, against
// ruptures that last two to four minutes. Small, and it is on the record.
// Right: multi-segment. Two things. The path is SAMPLED, from Shaw-Dieterich
// jump probabilities, drawn exactly from the distribution over trees -- not
// greedily, not by hand, and fixed before any field is drawn so the path depends
// on geometry and not on the noise. And the jump point is COMPUTED: the rupture
// leaves the parent fault from where its front arrests, not from where the two
// faults happen to be closest. That matters to you specifically, because the
// realisation files you supply record a jump point fitted by closest approach --
// we discard it and recompute it.
== Two additions to a framework you already know

#v(-0.45em)
#align(center, image("out/png/fields-row.png", width: 87%))
#v(0.45em)

#grid(
  columns: (1.12fr, 1fr),
  column-gutter: 0.8em,
  align: top,
  addition(
    [Curved ruptures: solve and project],
    fit(solve-and-project, cap: 122%),
  ),
  addition(
    [Multi-segment: sampled path, computed jump],
    fit(multi-segment-propagation, cap: 88%),
  ),
)

// SAY: [video] Watch the order the faults go in, and watch where each jump
// leaves the previous fault -- it leaves from the tip where the front arrested,
// which moves depending on where the hypocentre was. Neither of those was
// prescribed. Run it again with a different seed and you get a different tree.
== Multi-segment rupture

#v(1fr)
#align(center, text(0.7em, fill: quiet.darken(20%))[
  #emph[video]
])
#v(1fr)
#align(center, text(0.6em, fill: quiet.darken(30%))[
  rupture path drawn from the Shaw--Dieterich jump probabilities; jump points computed, not supplied
])

// SAY: [video] And the interface. This went through the same generator as a
// crustal fault -- fitted plane, sampled flat, projected back. Note the outline
// is not a rectangle: about a third of the bounding box is off the interface,
// and the taper follows the real edge rather than the box.
== Curved rupture

#v(1fr)
#align(center, text(0.7em, fill: quiet.darken(20%))[
  #emph[video]
])
#v(1fr)
#align(center, text(0.6em, fill: quiet.darken(30%))[
  Hikurangi interface: same generator as a crustal fault, solved on the fitted plane and projected back
])
