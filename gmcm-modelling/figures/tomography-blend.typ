// Blending tomography models by priority and alpha, in two views.
//
// Importable:
//   #import "figures/tomography-blend.typ": blend-stack, blend-plan
//
// The real picture is 4D (three space dimensions plus alpha). Here each model
// is flattened to a 2D sheet in plan, and the third dimension is used for the
// query order:
//
//   blend-stack  an exploded isometric view. Sheets are stacked by priority,
//                EP2020 (255) at the bottom, the highest-priority model on
//                top. Alpha is drawn as nested bands on each sheet's border,
//                fading to transparent at the edge.
//   blend-plan   the same models seen from above, composited in priority
//                order -- which is exactly what a query does: the top sheet is
//                taken first, then whatever alpha is left over is filled from
//                the sheets below, until it reaches one.
//
// The bands are nested rectangles of one colour. Drawing a rectangle of
// opacity a over one of accumulated opacity A gives A + a (1 - A), so the
// per-band opacities (1/4, 1/3, 1/2, 1) build accumulated alphas of exactly
// 0.25, 0.5, 0.75 and 1 from the edge inwards. Drawing the sheets bottom-up with
// these alphas is the "over" operator, so the plan view's overlap colours are
// the real composite, not an artist's impression.
//
// Illustrative: the regional models, their footprints and their priorities are
// made up. EP2020's priority (255) and the tomography range (128-255) are
// NZCVM's.

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": exact, mechanisms, quiet, stat

// (name, priority, colour, x0, y0, x1, y1), bottom of the stack first.
#let models = (
  ([EP2020], 255, mechanisms.at(0), 0.0, 0.0, 6.0, 4.0),
  ([Regional B], 220, mechanisms.at(2), 2.7, 1.1, 5.5, 3.6),
  ([Regional A], 200, stat, 0.6, 0.5, 3.7, 3.1),
)

// Border band width, and the per-band opacities that accumulate to
// 0.25 / 0.5 / 0.75 / 1 from the edge in.
#let band = 0.22
#let band-opacity = (0.25, 1 / 3, 0.5, 1.0)

#let with-opacity(c, a) = c.transparentize((1 - a) * 100%)

// Nested bands for one model, drawn through a projection `P(x, y)`. EP2020
// covers the whole domain at alpha one, so it gets a single uniform sheet --
// drawn at reduced opacity only so it reads as the background, not because its
// alpha is below one.
#let sheet(P, m, draw) = {
  let (name, pr, c, x0, y0, x1, y1) = m
  let quad(x0, y0, x1, y1, fill) = draw.line(
    P(x0, y0), P(x1, y0), P(x1, y1), P(x0, y1),
    close: true,
    fill: fill,
    stroke: none,
  )
  if pr == 255 {
    quad(x0, y0, x1, y1, with-opacity(c, 0.55))
  } else {
    for (k, a) in band-opacity.enumerate() {
      let d = k * band
      quad(x0 + d, y0 + d, x1 - d, y1 - d, with-opacity(c, a))
    }
  }
  draw.line(P(x0, y0), P(x1, y0), P(x1, y1), P(x0, y1), close: true, stroke: (thickness: 0.8pt, paint: c.darken(20%)))
}

#let blend-stack = canvas(length: 1cm, {
  import draw: *

  let lbl = 9pt
  let gap = 1.7
  // Oblique projection of a sheet at height z: plan y runs up and to the right.
  let proj(z) = (x, y) => (x + 0.55 * y, 0.32 * y + z)

  for (i, m) in models.enumerate() {
    let z = i * gap
    let P = proj(z)
    // Drop lines from a regional sheet's corners to the EP2020 sheet, so its
    // footprint on the background is visible.
    if i > 0 {
      let (_, _, c, x0, y0, x1, y1) = m
      for (x, y) in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)) {
        line(P(x, y), proj(0)(x, y), stroke: (thickness: 0.5pt, paint: c.darken(10%), dash: "dashed"))
      }
    }
    sheet(P, m, draw)
    let (name, pr, c, _, _, _, _) = m
    content(
      proj(z)(6.0, 2.0),
      // Explicit weight, not *strong*: metropolis recolours strong text.
      text(lbl, weight: "bold", fill: c.darken(25%))[#name],
      anchor: "west",
      padding: 0.35,
    )
  }

  // Query order, down the stack.
  let qx = -0.6
  line((qx, 2 * gap + 1.2), (qx, 0.2), stroke: (thickness: 1pt, paint: quiet), mark: (end: "stealth", fill: quiet, scale: 0.6))
  content((qx - 0.15, gap + 0.7), text(lbl, fill: quiet.darken(20%))[Query \ order], anchor: "east")
})

#let blend-plan = canvas(length: 1cm, {
  import draw: *

  let lbl = 9pt
  let P = (x, y) => (x, y)
  // Bottom-up, so each sheet composites over the ones below it.
  for m in models { sheet(P, m, draw) }
  content((3.0, -0.3), text(lbl, fill: quiet.darken(20%))[Plan view, composited], anchor: "north")

  // Alpha key: one swatch per band, edge to interior.
  let kx = 6.5
  let acc = (0.25, 0.5, 0.75, 1.0)
  content((kx, 3.9), text(lbl, fill: exact)[$alpha$ at a border], anchor: "south-west")
  for (k, a) in acc.enumerate() {
    let y = 3.3 - k * 0.55
    rect((kx, y), (kx + 0.45, y + 0.4), fill: with-opacity(stat, a), stroke: (thickness: 0.4pt, paint: quiet))
    content((kx + 0.6, y + 0.2), text(lbl - 1pt)[#calc.round(a, digits: 2)], anchor: "west")
  }
  content((kx, 3.3 - 3 * 0.55 - 0.2), text(lbl - 1pt, fill: quiet.darken(20%))[edge #sym.arrow.b interior], anchor: "north-west")
})
