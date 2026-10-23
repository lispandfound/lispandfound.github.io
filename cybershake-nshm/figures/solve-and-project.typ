// Curved ruptures, in three steps: fit a plane, sample on it, project back.
//
// Importable:
//   #import "figures/solve-and-project.typ": solve-and-project
//
// Drawn in cross-section, which is how a subduction interface is normally read.
// The field living on the surface is drawn as ticks standing off it, with a
// fixed amplitude list so the same "field" appears in panels 2 and 3 and the
// reader can see it is carried across rather than redrawn.
//
// The claim: a curved interface needs no separate rupture model. It enters the
// same generator as a crustal fault, so results are comparable across tectonic
// types instead of coming out of two codebases.
//
// The cost of the approach is stated on the slide rather than hidden here: the
// solve happens in the plane, so path lengths are short by the surface's own
// stretch. Measured on the CFM interfaces that is a median of -0.14 to +0.03 s
// against ruptures 143-255 s long (rupture_generator-hybrid README, "Known
// limits").

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": exact, quiet, stat

#let solve-and-project = canvas(length: 1cm, {
  import draw: *

  set-style(
    stroke: (thickness: 0.5pt),
    mark: (fill: black, scale: 0.35),
    content: (padding: 0.08),
  )
  let lbl = 7pt

  let W = 3.05 // panel width
  let PAD = 1.25 // gap between panels

  // The interface profile, and the plane that best fits it over the same span.
  let depth(x) = -0.075 * x * x
  let plane(x) = -0.30 * x + 0.20

  let n = 40
  let curve-pts(f, x0: 0.0, x1: 3.0) = range(0, n + 1).map(i => {
    let x = x0 + (x1 - x0) * i / n
    (x, f(x))
  })

  // One fixed draw, reused in panels 2 and 3 so the field is visibly the same.
  let amps = (
    0.30, 0.46, 0.38, 0.21, 0.33, 0.52, 0.44, 0.26,
    0.18, 0.35, 0.50, 0.41, 0.28,
  )

  // Ticks standing off a surface, normal to it, representing a sampled field.
  let field-on(f, ox, col) = {
    for (i, a) in amps.enumerate() {
      let x = 0.12 + i * (2.76 / (amps.len() - 1))
      let h = 0.0001
      let dy = (f(x + h) - f(x - h)) / (2 * h)
      let nn = calc.sqrt(1 + dy * dy)
      let (nx, ny) = (-dy / nn, 1 / nn)
      line(
        (ox + x, f(x)),
        (ox + x + a * nx * 0.55, f(x) + a * ny * 0.55),
        stroke: (thickness: 1.1pt, paint: col),
      )
    }
  }

  let title(ox, num, body) = {
    content(
      (ox + W / 2, 1.28),
      text(lbl, weight: "bold")[#num#h(0.25em)#body],
      anchor: "north",
    )
  }

  // --- 1. fit --------------------------------------------------------------
  let o1 = 0.0
  title(o1, [1.], [fit a plane by SVD])
  line(..curve-pts(depth).map(((x, y)) => (o1 + x, y)), stroke: (
    thickness: 1.5pt,
    paint: exact,
  ))
  line(
    (o1 + 0, plane(0)),
    (o1 + 3, plane(3)),
    stroke: (thickness: 1.1pt, paint: stat, dash: "dashed"),
  )
  // Labelled at the left end: the plane and the curve converge on the right,
  // so a label there sits on top of the interface it is meant to contrast with.
  content(
    (o1 + 0.02, plane(0) + 0.16),
    text(lbl, fill: stat.darken(10%))[best-fit plane],
    anchor: "south-west",
  )
  content(
    (o1 + 0.05, depth(0.6) - 0.42),
    text(lbl, fill: exact)[curved interface],
    anchor: "north-west",
  )

  // --- 2. sample -----------------------------------------------------------
  let o2 = W + PAD
  title(o2, [2.], [sample on the plane])
  // Redrawn flat, because that is what the solvers see.
  let flat(x) = 0.0
  line(
    (o2 + 0, 0),
    (o2 + 3, 0),
    stroke: (thickness: 1.5pt, paint: stat),
  )
  field-on(flat, o2, quiet.darken(20%))

  // --- 3. project ----------------------------------------------------------
  let o3 = 2 * (W + PAD)
  title(o3, [3.], [project back])
  line(..curve-pts(depth).map(((x, y)) => (o3 + x, y)), stroke: (
    thickness: 1.5pt,
    paint: exact,
  ))
  field-on(depth, o3, quiet.darken(20%))

  // --- the arrows between panels --------------------------------------------
  for ox in (W, 2 * W + PAD) {
    line(
      (ox + 0.28, 0.05),
      (ox + PAD - 0.28, 0.05),
      mark: (end: "stealth"),
      stroke: (thickness: 0.8pt, paint: quiet.darken(20%)),
    )
  }
})
