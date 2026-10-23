// How our data used to reach the outside world, and why it did not.
//
// Importable:
//   #import "figures/old-pipeline.typ": old-pipeline
//
// The three boxes are the whole pipeline. The tarball sizes and the archive
// total are from a full rclone listing of the QuakeCoRE Dropbox
// (~/tmp/listing.json): 550,959 files, 215 TB, of which 125 TB sits inside
// 18,349 `.tar` files, the largest of them 370 GB.
//
// The sting is the last line and it is the honest part of the talk: the failure
// mode was not that outsiders could not use the archive. It is that WE could
// not. A 370 GB tarball is not a dataset, it is a backup, and nobody re-reads a
// backup.

#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "../palette.typ": defect, exact, quiet, stat

#let old-pipeline = {
  set par(justify: false, first-line-indent: 0pt, leading: 0.45em)
  set text(8pt, hyphenate: false)

  let stage(col, title, sub) = node(
    (col, 0),
    align(center)[
      #text(weight: "bold", size: 1.05em, fill: exact)[#title] \
      #v(2pt)
      #text(0.88em, fill: quiet.darken(25%))[#sub]
    ],
    width: 40mm,
    height: 20mm,
    inset: 5pt,
    stroke: (thickness: 0.8pt, paint: exact),
    fill: rgb(0, 0, 0, 5),
    name: label("s" + str(col)),
  )

  diagram(
    spacing: (11mm, 8mm),
    node-corner-radius: 3pt,
    edge-stroke: (thickness: 0.9pt),

    stage(0, [A box of code], [cluster modules, \ hard-coded paths, one shell]),
    stage(1, [`tar czf`], [one archive per \ campaign, per version]),
    stage(2, [Dropbox], [215 TB, \ 18,349 tarballs]),

    edge(<s0>, <s1>, "-|>"),
    edge(<s1>, <s2>, "-|>"),

    node(
      (1, 1),
      align(center, text(9pt, fill: defect, weight: "bold")[
        The largest single tarball is 370 GB. \
        #text(weight: "regular")[Outsiders could not use this. Neither could we.]
      ]),
      inset: 0pt,
    ),
  )
}
