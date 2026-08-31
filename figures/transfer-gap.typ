// Where the clusters we actually run on stand on moving the data.
//
// Importable:
//   #import "figures/transfer-gap.typ": transfer-gap
//
// The five machines are the ones this group has run production or pilot work on.
// The right-hand column is whether the site offers a managed, parallel,
// restartable transfer service on dedicated data-transfer nodes -- Globus, in
// practice -- as opposed to logging into a head node and running `scp`.
//
// Two of five. That ratio is the slide. The argument is not that the other
// three are badly run; it is that data movement is not yet something we think
// to ask for when we ask for an allocation, so it does not get provisioned, so
// the throughput of a campaign is set by the slowest part nobody costed.

#import "../palette.typ": defect, exact, perf, quiet, stat

#let transfer-gap = {
  set par(justify: false, first-line-indent: 0pt, leading: 0.5em)
  set text(8pt, hyphenate: false)
  set block(spacing: 0pt)

  let row(site, where, has) = (
    text(fill: exact, weight: "bold")[#site],
    text(0.95em, fill: quiet.darken(25%))[#where],
    if has {
      text(fill: perf, weight: "bold")[yes]
    } else {
      text(fill: defect, weight: "bold")[no]
    },
  )

  block(
    stroke: (thickness: 0.8pt, paint: exact),
    radius: 3pt,
    inset: 0pt,
    clip: true,
    width: 116mm,
    {
      block(
        width: 100%,
        fill: exact,
        inset: (x: 9pt, y: 5pt),
        grid(
          columns: (1fr, auto),
          align: (left + horizon, right + horizon),
          text(fill: white, weight: "bold")[Clusters we run on],
          text(fill: white, weight: "bold")[managed data transfer?],
        ),
      )
      table(
        columns: (auto, 1fr, auto),
        stroke: none,
        align: (left + horizon, left + horizon, right + horizon),
        inset: (x: 9pt, y: 5.5pt),
        fill: (_, y) => if calc.odd(y) { rgb(0, 0, 0, 4) },

        ..row([TACC], [Texas], true),
        ..row([REANNZ HPC3], [New Zealand], true),
        ..row([ESNZ Cascade], [New Zealand], false),
        ..row([MareNostrum 5], [Barcelona], false),
        ..row([KISTI], [Korea], false),
      )
    },
  )
}
