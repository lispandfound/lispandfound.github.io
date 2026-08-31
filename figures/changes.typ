// The five changes, named by what each one is FOR rather than by what we
// installed.
//
// Importable:
//   #import "figures/changes.typ": changes
//
// The technology is the subtitle on purpose. None of these five is specific to
// this group, and a talk that leads with the product names is a talk about our
// workflow -- which is not the argument. Somebody running MATLAB on a
// departmental server can do four of the five this afternoon.
//
// `changes(active: 2)` dims every box but the third, so the same figure is
// reusable as a progress strip without a second drawing to keep in sync.

#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "../palette.typ": exact, quiet, stat

#let changes(active: none) = {
  set par(justify: false, first-line-indent: 0pt, leading: 0.45em)
  set text(8pt, hyphenate: false)

  let items = (
    ([Pin the environment], [a container]),
    ([Publish the tools], [a package index]),
    ([Let the data \ describe itself], [NetCDF]),
    ([Keep the recipe \ with the result], [one JSON file]),
    ([Make it queryable, \ not browsable], [a database]),
  )

  let change(col, name, what) = {
    let on = active == none or active == col
    node(
      (col, 0),
      align(center)[
        #text(
          weight: "bold",
          size: 1.02em,
          fill: if on { exact } else { quiet.lighten(30%) },
        )[#name] \
        #v(2.5pt)
        #text(0.88em, fill: if on { stat.darken(12%) } else {
          quiet.lighten(30%)
        })[#what]
      ],
      width: 28mm,
      height: 21mm,
      inset: 5pt,
      stroke: (
        thickness: if on { 1.0pt } else { 0.6pt },
        paint: if on { stat } else { quiet.lighten(40%) },
      ),
      fill: if on { stat.lighten(92%) } else { rgb(0, 0, 0, 2) },
    )
  }

  diagram(
    spacing: (4mm, 4mm),
    node-corner-radius: 3pt,
    ..items.enumerate().map(((i, it)) => change(i, it.at(0), it.at(1))),
  )
}
