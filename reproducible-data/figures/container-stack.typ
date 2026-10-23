// What is inside runner.sif, and what is left outside it.
//
// Importable:
//   #import "figures/container-stack.typ": container-stack
//
// Contents are from ucgmsim/workflow: container/Dockerfile (Ubuntu, Python
// 3.13.12 built from source, the venv at /sw/venv) and container/runner.def
// (the EMOD3D source tools compiled at build time). The size is the real
// artefact on disk.
//
// The two things outside the box are the honest part of the slide. The MPI
// solvers still link the host's MPI, so this is not a claim that the container
// makes the machine irrelevant -- it is a claim that everything ELSE stopped
// being the machine's business.

#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "../palette.typ": exact, perf, quiet, stat

#let container-stack = {
  // Stacked blocks inherit paragraph spacing, which opens a blank strip
  // between the header and the first row of a panel. These panels are drawn
  // as abutting blocks on purpose, so the spacing is zeroed for the figure.
  set block(spacing: 0pt)
  set par(justify: false, first-line-indent: 0pt, leading: 0.5em)
  set text(8pt, hyphenate: false)

  let mono(body) = text(font: "DejaVu Sans Mono", size: 0.85em)[#body]

  let layer(name, detail) = block(
    width: 100%,
    inset: (x: 7pt, y: 4.5pt),
    stroke: (top: (thickness: 0.5pt, paint: stat.lighten(55%))),
    grid(
      columns: (1fr, auto),
      align: (left + horizon, right + horizon),
      text(fill: exact)[#name],
      text(0.9em, fill: quiet.darken(20%))[#detail],
    ),
  )

  grid(
    columns: (58mm, 34mm),
    column-gutter: 7mm,
    align: horizon,

    // Inside.
    block(
      stroke: (thickness: 1.0pt, paint: stat),
      radius: 3pt,
      inset: 0pt,
      clip: true,
      {
        block(
          width: 100%,
          fill: stat,
          inset: (x: 7pt, y: 5pt),
          text(fill: white, weight: "bold")[
            #mono[runner.sif] #h(0.4em) one file, 1.7 GB
          ],
        )
        layer([Ubuntu + system libraries], mono[apt])
        layer([Python], mono[3.13.12])
        layer([Our six packages], mono[pinned to a commit])
        layer([EMOD3D source tools], mono[genslip, srf2stoch])
      },
    ),

    // Outside, and why.
    block(
      stroke: (thickness: 0.7pt, paint: quiet, dash: "dashed"),
      radius: 3pt,
      inset: (x: 7pt, y: 6pt),
      align(left)[
        #text(weight: "bold", fill: quiet.darken(25%))[Still the host's]
        #v(3pt)
        #text(0.9em, fill: quiet.darken(25%))[
          The MPI solvers. They link the machine's own network fabric, and
          nothing portable can.
        ]
      ],
    ),
  )
}
