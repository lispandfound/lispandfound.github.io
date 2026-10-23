// What a Cybershake campaign costs, on a log core-hour axis.
//
// Importable:
//   #import "figures/scale-ladder.typ": scale-ladder
//
// Three concrete campaigns rather than three abstract categories, because the
// comparison only means something if each bar is a thing that was actually run
// or actually costed:
//
//   Cybershake NZ v25.6   200 m, NSHM 2010,  16,043 simulations   4.7e6
//   NSHM 2022 pilot       100 m, NSHM 2022,     293 simulations   3.7e6  measured
//   every NSHM 2022 rupture once
//                         100 m, NSHM 2022,   7,122 simulations   1.4e8
//
// Counted in SIMULATIONS, not ruptures, and deliberately so. Core-hours scale
// with how many simulations were run, so that is the only unit under which the
// three bars are comparable. It also keeps the slide from contradicting the
// timeline two slides earlier: NSHM 2010 has 536 characteristic ruptures, and
// v25.6's 16,043 is 29.9 per rupture -- which is the N(Mw) rule's own mean
// (it spans 14 to 68, and 536 x 30 = 16,080). So 16,043 is realisations across
// the 2010 catalogue, not distinct ruptures.
//
// The two readings to take off it:
//   * the 293-rupture pilot cost 79% of the ENTIRE v25.6 campaign;
//   * running NSHM 2022 once is 30x the entire v25.6 campaign, and 1.6x the
//     largest allocation anyone can apply for.
//
// Per simulation the first two bars are 293 core-hours against 12,765, a factor
// of 44. Dropping 200 m to 100 m accounts for 16 of it; the remaining 2.7x is
// composition, since v25.6 spans a whole catalogue including small cheap events
// while the pilot is 293 large crustal ruptures, Mw 6.7 to 8.4. Worth having
// ready before someone in the room divides one by the other.
//
// The pilot bar is the measured one: 293 EMOD3D runs at exactly the target
// resolution (h = 100 m, inferred as sqrt(domain_area_km2 / (nx*ny)) across all
// 293), summing to 3.74e6 core-hours. The third bar scales that observation over
// the catalogue with the fitted model log10(core_hours) = 0.342 Mw + 1.562,
// giving 1.407e8.

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": defect, exact, perf, quiet

#let scale-ladder = canvas(length: 1cm, {
  import draw: *

  set-style(
    stroke: (thickness: 0.5pt),
    mark: (fill: black, scale: 0.4),
    content: (padding: 0.1),
  )
  let lbl = 7pt

  let lo = 6 // log10 core-hours at the left edge
  let hi = 9
  let W = 11.5
  let px(v) = (calc.log(v) - lo) / (hi - lo) * W

  let bar-h = 0.6
  let gap = 2.08
  let rows = (
    (
      4.7e6,
      exact,
      [Cybershake NZ v25.6],
      [200 m · NSHM 2010 · 16,043 simulations],
      [$4.7 times 10^6$],
    ),
    (
      3.74e6,
      perf,
      [NSHM 2022 pilot],
      [100 m · NSHM 2022 · 293 simulations · #text(weight: "bold", fill: perf.darken(15%))[measured]],
      [$3.7 times 10^6$],
    ),
    (
      1.407e8,
      defect,
      [Every NSHM 2022 rupture, once],
      [100 m · NSHM 2022 · 7,122 simulations],
      [$1.4 times 10^8$],
    ),
  )

  // --- axis ------------------------------------------------------------------
  let y0 = gap - 0.86
  line((0, y0), (W + 0.3, y0), mark: (end: "stealth"))
  for e in range(6, 10) {
    let x = px(calc.pow(10.0, e))
    line((x, y0), (x, y0 - 0.12), stroke: (thickness: 0.4pt, paint: quiet))
    content((x, y0 - 0.2), text(lbl, fill: quiet)[$10^#e$], anchor: "north")
  }
  content((W / 2, y0 - 0.72), text(lbl)[core-hours], anchor: "north")

  // --- bars ------------------------------------------------------------------
  for (i, (v, col, name, detail, amount)) in rows.enumerate() {
    let y = (rows.len() - i) * gap
    rect(
      (0, y - bar-h / 2),
      (px(v), y + bar-h / 2),
      fill: col.lighten(78%),
      stroke: (thickness: 0.6pt, paint: col),
    )
    // No white backing plate. The EuroHPC rule sits at 10^7.95 and the longest
    // label ends well short of it, so nothing needs masking -- and a white plate
    // on a transparent-background PNG shows as an opaque island the moment the
    // slide behind it is not white.
    content(
      (0.04, y + bar-h / 2 + 0.12),
      [
        #text(lbl, fill: col.darken(15%), weight: "bold")[#name] \
        #text(lbl - 1pt, fill: quiet.darken(30%))[#detail]
      ],
      anchor: "south-west",
    )
    content(
      (px(v) + 0.18, y),
      text(lbl, fill: col.darken(15%))[#amount],
      anchor: "west",
    )
  }

  // --- the ceiling -----------------------------------------------------------
  let xe = px(9.0e7)
  line(
    (xe, y0 - 0.02),
    (xe, (rows.len() + 0.34) * gap),
    stroke: (thickness: 0.9pt, paint: black, dash: "dashed"),
  )
  content(
    (xe, (rows.len() + 0.38) * gap),
    text(lbl, weight: "bold")[largest EuroHPC call \~$9 times 10^7$],
    anchor: "south",
  )
})
