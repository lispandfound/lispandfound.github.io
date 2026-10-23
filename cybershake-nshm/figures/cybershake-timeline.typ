// Cybershake NZ and the NSHM, 2010 to now.
//
// Importable:
//   #import "figures/cybershake-timeline.typ": cybershake-timeline
//
// Two lanes, because two things are being tracked and they advance
// independently: the source model below the axis, the simulation campaign above
// it. Reading the gaps between them is the point -- a source model lands, and
// the simulation that can afford it arrives years later at a coarser
// resolution than anyone wants.
//
// Events and their sources, all from ~/Documents/phd-proposal:
//   2010  NSHM 2010, 536 characteristic ruptures        @stirling2012national
//         (the "2010 update"; the BSSA paper is 2012)
//   2019  Cybershake NZ v19.5, h = 400 m, f_max 0.25 Hz,
//         27,481 sites, 11,362 realisations, NSHM 2010  @bradley2019cybershakenz
//   2022  NSHM 2022, 7,162 rate-bearing ruptures of
//         450,745                                       @gerstenberger2024seismicity
//   2024  Advancements in Cybershake NZ                 @abbasnejardfard2024cybershake
//   2025  v25.6: h = 200 m, NSHM 2010, 16,043 simulations, 4.7e6 core-hours
//                                                        @abbasnejardfard2025subduction
//   now   h = 100 m on NSHM 2022; 293-rupture pilot measured at that resolution
//
// Events are placed at the year the model or study is NAMED for, not the year
// its paper appeared -- NSHM 2010 was published in 2012 and NSHM 2022 in 2024,
// and putting them at 2012 and 2024 would misdraw the very gap the figure is
// about.

#import "@preview/cetz:0.4.2": canvas, draw
#import "../palette.typ": exact, quiet, stat

#let cybershake-timeline = canvas(length: 1cm, {
  import draw: *

  set-style(
    stroke: (thickness: 0.5pt),
    mark: (fill: black, scale: 0.35),
    content: (padding: 0.08),
  )
  let lbl = 7pt

  let y0 = 2009.0
  let y1 = 2027.1
  let W = 13.4
  let px(y) = (y - y0) / (y1 - y0) * W

  // --- the axis --------------------------------------------------------------
  line((0, 0), (W + 0.3, 0), mark: (end: "stealth"), stroke: (thickness: 0.9pt))
  for y in (2015, 2020, 2025) {
    line((px(y), -0.1), (px(y), 0.1), stroke: (thickness: 0.6pt, paint: quiet))
    content(
      (px(y), -0.16),
      text(lbl - 0.5pt, fill: quiet.darken(20%))[#y],
      anchor: "north",
    )
  }

  // No lane captions. Which lane is which is already unambiguous from the event
  // names -- "NSHM" below, "Cybershake" above -- and naming them twice spends
  // width on the left that the first event's label wants.

  // An event: a dot on the axis, a stem, and a two-line label at the stem's end.
  let event(
    year,
    height,
    col,
    title,
    detail,
    anchor: "south",
    emphasis: false,
    dx: 0.0,
  ) = {
    let x = px(year)
    line(
      (x, 0),
      (x, height),
      stroke: (thickness: 0.6pt, paint: col.lighten(25%)),
    )
    circle((x, 0), radius: if emphasis { 0.13 } else { 0.09 }, fill: col, stroke: (
      thickness: 0.8pt,
      paint: white,
    ))
    content(
      (x + dx, height),
      align(if anchor == "south" { center } else { left })[
        #text(lbl, weight: "bold", fill: col.darken(12%))[#title] \
        #text(lbl - 0.8pt, fill: quiet.darken(30%))[#detail]
      ],
      anchor: anchor,
    )
  }

  // --- source model, below ---------------------------------------------------
  event(2010, -0.72, exact, [NSHM 2010], [536 characteristic ruptures], anchor: "north")
  event(2022, -0.72, exact, [NSHM 2022], [7,162 rate-bearing of 450,745], anchor: "north")

  // --- simulation, above -----------------------------------------------------
  // 2024 and 2025 are close enough that centred labels would collide, so the
  // later one is stemmed higher and set left-anchored off its own stem.
  event(2019, 0.72, quiet.darken(15%), [Cybershake NZ v19.5], [$h = 400$ m, NSHM 2010])
  // Anchored south-east so the label extends left of its own stem: "today" is
  // only ten months later and its stem would otherwise run through this label.
  event(
    2025.5,
    0.72,
    quiet.darken(15%),
    [Cybershake NZ v25.6],
    [$h = 200$ m, NSHM 2010],
    anchor: "south-east",
    dx: 0.14,
  )
  event(
    2026.35,
    2.05,
    stat,
    [today],
    [$h = 100$ m on NSHM 2022],
    anchor: "south-east",
    emphasis: true,
    dx: 0.14,
  )
})
