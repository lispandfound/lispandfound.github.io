// What is in the composite database, and the one question it can answer that a
// directory of files cannot.
//
// Importable:
//   #import "figures/duckdb-shape.typ": duckdb-shape
//
// Every number is read out of ~/tmp/ims.duckdb -- the Cybershake intensity
// measures, built by `eqvis ingest` from the per-run NetCDF files. The database
// is therefore a cache of the files rather than a replacement for them, which
// matters for the slide: nothing here asks anyone to give up the file they
// already have.
//
// 1.59 billion is the number the slide is for. It is not a number you can hold
// in a spreadsheet, in a directory of CSVs, or in your head, and it is what one
// ordinary national-scale study now produces.

#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "../palette.typ": exact, perf, quiet, stat

#let duckdb-shape = {
  // Stacked blocks inherit paragraph spacing, which opens a blank strip
  // between the header and the first row of a panel. These panels are drawn
  // as abutting blocks on purpose, so the spacing is zeroed for the figure.
  set block(spacing: 0pt)
  set par(justify: false, first-line-indent: 0pt, leading: 0.5em)
  set text(8pt, hyphenate: false)

  let mono(body) = text(font: "DejaVu Sans Mono", size: 0.85em)[#body]

  let stat-cell(value, unit, what) = align(center)[
    #text(size: 1.9em, weight: "bold", fill: stat.darken(10%))[#value]#text(
      size: 1.0em,
      weight: "bold",
      fill: stat.darken(10%),
    )[#unit] \
    #v(1pt)
    #text(0.92em, fill: quiet.darken(25%))[#what]
  ]

  block(
    stroke: (thickness: 1.0pt, paint: stat),
    radius: 3pt,
    inset: 0pt,
    clip: true,
    width: 100mm,
    {
      block(
        width: 100%,
        fill: stat,
        inset: (x: 8pt, y: 5pt),
        text(fill: white, weight: "bold")[
          #mono[ims.duckdb] #h(0.4em) one file, 18 GB
        ],
      )
      block(
        inset: (x: 8pt, y: 9pt),
        grid(
          columns: (1fr, 1fr, 1fr, 1fr),
          column-gutter: 4pt,
          stat-cell[293][][ruptures],
          stat-cell[105][ k][stations],
          stat-cell[111][][periods],
          stat-cell[1.6][ B][spectral values],
        ),
      )
    },
  )
}
