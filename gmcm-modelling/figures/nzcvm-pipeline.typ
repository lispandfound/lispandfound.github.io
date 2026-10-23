// The NZCVM build: data in, a small core, a configurable layer chain, a writer.
//
// Importable:
//   #import "figures/nzcvm-pipeline.typ": nzcvm-pipeline
//
// Layer names and behaviour are from ~/src/nzcvm/README.md ("Layers" and
// "Output formats"). Layers run in the order the config lists them, outermost
// first, and `query` is always last -- so the chain is drawn as a stack the
// request passes down through, not as a sequence of arrows between layers,
// which would imply a data-flow order the code does not have.
//
// The data column is dashed on purpose: those are files, not code. Adding a
// basin is dropping a file in that column.

#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "../palette.typ": exact, quiet, stat

#let nzcvm-pipeline = {
  set par(justify: false, first-line-indent: 0pt, leading: 0.45em)
  set text(8pt, hyphenate: false)

  let data(pos, title, sub, name) = node(
    pos,
    align(center)[
      #text(weight: "bold", fill: exact)[#title] \
      #text(0.85em, fill: quiet.darken(25%))[#sub]
    ],
    width: 34mm,
    inset: 5pt,
    stroke: (thickness: 0.8pt, paint: exact, dash: "dashed"),
    fill: rgb(0, 0, 0, 4),
    name: name,
  )

  let layer(body) = block(
    width: 100%,
    inset: (x: 4pt, y: 3pt),
    radius: 2pt,
    fill: stat.lighten(88%),
    align(center, text(0.95em)[#body]),
  )

  diagram(
    spacing: (12mm, 5mm),
    node-corner-radius: 3pt,
    edge-stroke: (thickness: 0.9pt),

    data((0, 0), [Tomography], [Multiple blended tomography models], <tomo>),
    data((0, 1), [Basin models], [True 3D basin models], <basins>),
    data((0, 2), [$V_(S 30)$ map], [Geotechnical layer], <vs30>),
    data((0, 3), [Topographic modelling], [], <dem>),

    node(
      (1, 1.5),
      align(center)[
        #text(
          weight: "bold",
          fill: stat,
          size: 1.1em,
        )[Independent composable layers] \
        #v(3pt)
        #layer[`backus` #h(2pt) Super-sampling]
        #layer[`clamp` #h(2pt) $V_P \/ V_S$ bounds]
        #layer[`ely` #h(2pt) $V_(S 30)$ taper]
        #layer[`offshore`, `coastline`]
        #layer[`query` #h(2pt) Blend by priority]
        #layer[+ third party support for plugins]
      ],
      width: 44mm,
      inset: 6pt,
      stroke: (thickness: 1pt, paint: stat),
      name: <chain>,
    ),

    node(
      (2, 1),
      align(center)[#text(weight: "bold", fill: exact)[SW4] \ #text(
          0.85em,
          fill: quiet.darken(25%),
        )[sfile]],
      width: 24mm,
      inset: 5pt,
      stroke: (thickness: 0.8pt, paint: exact),
      name: <sw4>,
    ),
    node(
      (2, 1.5),
      align(center)[#text(weight: "bold", fill: exact)[EMOD3D] \ #text(
          0.85em,
          fill: quiet.darken(25%),
        )[Binary files]],
      width: 24mm,
      inset: 5pt,
      stroke: (thickness: 0.8pt, paint: exact),
      name: <emod3d>,
    ),

    node(
      (2, 2),
      align(center)[#text(weight: "bold", fill: exact)[Third party by plugin]],
      width: 24mm,
      inset: 5pt,
      stroke: (thickness: 0.8pt, paint: exact),
      name: <others>,
    ),

    edge(<tomo>, <chain>, "-|>"),
    edge(<basins>, <chain>, "-|>"),
    edge(<vs30>, <chain>, "-|>"),
    edge(<dem>, <chain>, "-|>"),
    edge(<chain>, <sw4>, "-|>"),
    edge(<chain>, <emod3d>, "-|>"),
    edge(<chain>, <others>, "-|>"),
  )
}
