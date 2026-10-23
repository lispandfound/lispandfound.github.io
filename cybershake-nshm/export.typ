// Standalone renderer for one figure, for PNG export into PowerPoint.
//
//   typst compile --input fig=scale-ladder export.typ out/png/scale-ladder.png \
//     --format png --ppi 300
//
// One parameterised wrapper rather than a file per figure, so a new figure costs
// one line in the dictionary below and cannot drift out of step with the deck --
// both this and main.typ import the same `#let` from the same file.

#import "figures/bias-variance-curves.typ": bias-variance-curves
#import "figures/two-strategies.typ": two-strategies
#import "figures/psha-pipeline.typ": psha-pipeline
#import "figures/cybershake-timeline.typ": cybershake-timeline
#import "figures/scale-ladder.typ": scale-ladder
#import "figures/magnitude-blind.typ": magnitude-blind
#import "figures/objectives-fan.typ": objectives-fan
#import "figures/nshm-logic-tree.typ": nshm-logic-tree
#import "figures/sampling-logic-tree.typ": sampling-logic-tree
#import "figures/solve-and-project.typ": solve-and-project
#import "figures/multi-segment-propagation.typ": multi-segment-propagation

#let figures = (
  "bias-variance-curves": bias-variance-curves,
  "two-strategies": two-strategies,
  "psha-pipeline": psha-pipeline,
  "cybershake-timeline": cybershake-timeline,
  "scale-ladder": scale-ladder,
  "magnitude-blind-1": magnitude-blind(pair: false),
  "magnitude-blind-2": magnitude-blind(pair: true),
  "objectives-fan": objectives-fan,
  "nshm-logic-tree": nshm-logic-tree,
  "sampling-logic-tree": sampling-logic-tree,
  "solve-and-project": solve-and-project,
  "multi-segment-propagation": multi-segment-propagation,
)

#let name = sys.inputs.at("fig", default: none)
#if name == none or name not in figures {
  panic(
    "set --input fig=<name>; known: " + figures.keys().join(", "),
  )
}

// Transparent background: PowerPoint slides are not always white, and a figure
// with a baked-in white plate shows its edges the moment the theme changes.
#set page(width: auto, height: auto, margin: 5mm, fill: none)
#set text(font: "Libertinus Serif")

#figures.at(name)
