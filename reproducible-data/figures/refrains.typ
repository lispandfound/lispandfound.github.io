// The four things people say instead, in their own words.
//
// Importable:
//   #import "figures/refrains.typ": refrains
//
// These are quotes, near enough, and they are on the slide as quotes because
// the room has said all four -- and because a talk that pretends nobody has a
// reason not to share data is a talk nobody believes.
//
// Ordered by how much of the rest of the deck answers each: the first two are
// answered by the scale slides, the second two by the citation study.
//
// Drawn with a plain grid rather than fletcher. Fletcher's `node` takes a
// single stroke spec, so the left-accent bar these boxes want (`stroke: (left:
// ...)`) is a type error inside it -- and a figure that errors inside
// `measure()` reports zero width, which turns the deck's `fit` helper into a
// divide-by-zero a long way from the cause.

#import "../palette.typ": defect, exact, quiet

#let refrains = {
  set par(justify: false, first-line-indent: 0pt, leading: 0.55em)
  set text(8pt, hyphenate: false)

  let quote-box(body) = block(
    width: 100%,
    height: 15mm,
    inset: (x: 9pt, y: 7pt),
    radius: 2pt,
    stroke: (left: (thickness: 2.5pt, paint: defect)),
    fill: rgb(0, 0, 0, 4),
    align(left + horizon, text(size: 1.2em, fill: exact, style: "italic")[#body]),
  )

  block(width: 138mm, grid(
    columns: (1fr, 1fr),
    rows: (auto, auto),
    column-gutter: 7mm,
    row-gutter: 5mm,
    quote-box[“It is too much work.”],
    quote-box[“My data is too big for that.”],
    quote-box[“Nobody would use it anyway.”],
    quote-box[“I will put it up if somebody asks.”],
  ))
}
