// Standalone renderer for one figure, for checking a diagram at full size or
// exporting it as a PNG.
//
//   typst compile --input fig=refinement export.typ out/png/refinement.png \
//     --format png --ppi 300
//
// Same pattern as ~/Documents/rupture-sampling-talk/export.typ: one wrapper and a
// dictionary, importing the same `#let` the deck does.

#import "figures/uniform-grid.typ": uniform-grid
#import "figures/refinement.typ": refinement
#import "figures/curvilinear-cartesian-grid.typ": curvilinear-cartesian-grid
#import "figures/nzcvm-pipeline.typ": nzcvm-pipeline
#import "figures/validation-design.typ": validation-design
#import "figures/accuracy-order.typ": accuracy-order
#import "figures/attenuation-cells.typ": attenuation-cells
#import "figures/research-loop.typ": research-loop
#import "figures/tomography-blend.typ": blend-plan, blend-stack
#import "figures/sw4-cost.typ": sw4-cost

#let figures = (
  "uniform-grid": uniform-grid,
  "refinement": refinement,
  "sw4-cost": sw4-cost,
  "curvilinear-cartesian-grid": curvilinear-cartesian-grid,
  "nzcvm-pipeline": nzcvm-pipeline,
  "validation-design": validation-design,
  "accuracy-order": accuracy-order,
  "attenuation-cells": attenuation-cells,
  "research-loop-1": research-loop(after: false),
  "research-loop-2": research-loop(after: true),
  "blend-stack": blend-stack,
  "blend-plan": blend-plan,
)

#set page(width: auto, height: auto, margin: 4mm, fill: none)
#set text(font: "Libertinus Serif")
#figures.at(sys.inputs.at("fig"))
