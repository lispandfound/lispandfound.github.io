// FAIR, as the four questions somebody else has to be able to answer.
//
// Importable:
//   #import "figures/fair.typ": fair
//
// Wilkinson et al. (2016), Scientific Data 3:160018. The gloss on each letter
// is deliberately the operational form rather than the principle's own wording:
// the audience has seen the poster, and what they have not seen is what each
// letter costs on a Tuesday afternoon.
//
// This slide is agreement, not argument. Nobody in the room disputes it, and
// the next two slides are about why they do not do it anyway -- so the tone
// here is "we all know this", drawn plainly and without emphasis colour.

#import "@preview/fletcher:0.5.8" as fletcher: diagram, edge, node
#import "../palette.typ": exact, perf, quiet, stat

#let fair = {
  set par(justify: false, first-line-indent: 0pt, leading: 0.45em)
  set text(8pt, hyphenate: false)

  let letter(col, ch, word, gloss) = node(
    (col, 0),
    align(center)[
      #text(size: 2.5em, weight: "bold", fill: stat)[#ch]
      #v(-3pt)
      #text(weight: "bold", size: 1.0em, fill: exact)[#word] \
      #v(2pt)
      #text(0.9em, fill: quiet.darken(25%))[#gloss]
    ],
    width: 34mm,
    height: 30mm,
    inset: 5pt,
    stroke: (thickness: 0.8pt, paint: quiet.lighten(30%)),
    fill: rgb(0, 0, 0, 3),
  )

  diagram(
    spacing: (5mm, 5mm),
    node-corner-radius: 3pt,
    letter(0, [F], [Findable], [it has an identifier \ somebody can search]),
    letter(1, [A], [Accessible], [they can retrieve it \ without asking you]),
    letter(2, [I], [Interoperable], [their software opens it \ without your code]),
    letter(3, [R], [Reusable], [it says what it is, \ and how it was made]),
  )
}
