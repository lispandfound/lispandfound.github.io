// The recipe, travelling with the result.
//
// Importable:
//   #import "figures/provenance.typ": provenance
//
// Both halves are verbatim from
// validation_results_24-08/2016p858094/realisation.json: 23 sections, 55 kB.
// The top half is what the file SAYS -- an excerpt across four of the sections,
// elided where a section is long, so the audience can see it is ordinary
// readable text rather than a binary blob. The bottom half is what the file
// RECORDS about itself: every tool that touched it appended its name, the
// `git describe` version of the code that ran, and the timestamp.
//
// The container paths in the last line are left in deliberately. They are the
// evidence that this ran inside the pinned image rather than on somebody's
// login shell -- recorded by the file, not claimed by the speaker.

#import "../palette.typ": exact, quiet, stat

#let provenance = {
  set par(justify: false, first-line-indent: 0pt, leading: 0.5em)
  set text(8pt, hyphenate: false)
  set block(spacing: 0pt)

  let mono(body, size: 0.78em, fill: exact) = text(
    font: "DejaVu Sans Mono",
    size: size,
    fill: fill,
  )[#body]

  block(
    stroke: (thickness: 1.0pt, paint: stat),
    radius: 3pt,
    inset: 0pt,
    clip: true,
    width: 132mm,
    {
      block(
        width: 100%,
        fill: stat,
        inset: (x: 9pt, y: 5pt),
        text(fill: white, weight: "bold")[
          #mono("realisation.json", fill: white) #h(0.5em) one text file, 23
          sections, 55 kB. The entire input to the run.
        ],
      )

      // What it says.
      block(
        width: 100%,
        inset: (x: 10pt, y: 7pt),
        align(left, mono(size: 0.72em)[
          ```json
          "magnitudes":     { "2016p858094": 6.0898276 },
          "rakes":          { "2016p858094": 171 },
          "domain":         { "depth": 39, "duration": 153.58,
                              "domain": [ {"latitude": -43.151, "longitude": 169.369}, ... ] },
          "velocity_model": { "version": "2.07", "min_vs": 0.5, "vs30": 500.0,
                              "topo_type": "SQUASHED_TAPERED", ... },
          ```
        ]),
      )

      // What it records about itself.
      block(
        width: 100%,
        fill: rgb(0, 0, 0, 5),
        inset: (x: 10pt, y: 7pt),
        stroke: (top: (thickness: 0.6pt, paint: stat.lighten(45%))),
        {
          text(0.85em, weight: "bold", fill: quiet.darken(30%))[
            #sym.dots.h and its own log, 17 entries deep
          ]
          v(4pt)
          align(left, mono(size: 0.68em)[
            ```json
            { "utility":   "realisation-to-srf",
              "version":   "0.1.dev1492+ga2eb23d05",
              "timestamp": "2026-08-25T07:06:28",
              "args":      ["/realisation/R1/realisation.json",
                            "--genslip-path", "/EMOD3D/tools/genslip_v5.6.2"] }
            ```
          ])
        },
      )
    },
  )
}
