// Reproducible and usable scientific data at scale.
//
// Build:  typst compile main.typ      (or `just`, which rebuilds the data figures first)
// Watch:  typst watch main.typ
//
// Preamble follows ~/Documents/rupture-sampling-talk/main.typ so this deck
// matches the existing ones. Speaker notes are `// SAY:` comments above each
// slide: the slides carry almost no prose, because the argument is spoken and
// the written text is reserved for numbers that have to stay readable for as
// long as the slide is up.
//
// The audience is earthquake engineers, not programmers, and the working
// assumption throughout is that they are right to be sceptical, so every claim
// is attached to a number measured from something on disk. The two figures that
// carry live numbers (out/png/supergrid.png and out/png/pypi.png) are
// regenerated from the source data at build time rather than pasted in.
//
// The argument is about research data, not about our workflow. Every tool named
// here is an example of a category, and the slides are written so that somebody
// running MATLAB on a departmental server can act on four of the five changes
// without adopting anything of ours. If a version of this deck starts to read
// like a product tour, that is the thing to cut.

#import "@preview/touying:0.6.1": *
#import themes.metropolis: *

#import "figures/fair.typ": fair
#import "figures/refrains.typ": refrains
#import "figures/old-pipeline.typ": old-pipeline
#import "figures/changes.typ": changes
#import "figures/container-stack.typ": container-stack
#import "figures/provenance.typ": provenance
#import "figures/duckdb-shape.typ": duckdb-shape
#import "figures/transfer-gap.typ": transfer-gap
#import "palette.typ": defect, exact, perf, quiet, stat

#show: metropolis-theme.with(
  aspect-ratio: "16-9",
  config-info(
    title: [Reproducible and usable scientific data at scale],
    subtitle: [lessons from Cybershake and validation research],
    author: [Jake Faulkner],
    date: datetime(year: 2026, month: 8, day: 30),
    institution: [University of Canterbury],
  ),
  config-common(datetime-format: "[day] [month repr:long] [year]"),
)

#set text(font: "Libertinus Serif", size: 20pt)
#show raw: set text(font: "DejaVu Sans Mono", size: 0.82em)

// Figures are drawn at document scale; the deck scales them at use.
//
// A hand-tuned percentage cannot know how wide its container is, so two figures
// side by side either leave a gap or collide the moment either one changes.
// `fit` measures the figure and scales it to the width it is actually given;
// `cap` bounds the enlargement so a small figure on a wide slide is not blown
// up to fill it.
#let fit(body, cap: 300%) = layout(size => {
  let m = measure(body)
  let f = calc.min(size.width / m.width * 100%, cap)
  align(center, scale(f, reflow: true, body))
})

#let big(body, cap: 188%) = fit(body, cap: cap)

// One number, said once, at the size it deserves. Used where the slide's whole
// content is a quantity and a caption.
#let headline(value, caption, colour: stat) = align(center)[
  #block(below: 0.32em, text(size: 2.4em, weight: "bold", fill: colour)[#value])
  #text(size: 0.85em, fill: quiet.darken(25%))[#caption]
]

// A quiet aside under a figure -- the sentence a reader would ask for if the
// figure were on a poster and nobody were standing next to it.
#let note(body) = align(center, text(0.78em, fill: quiet.darken(20%), style: "italic")[#body])

// A quoted file, on the tinted panel the deck uses for "here is the actual
// thing". `align(left)` is not optional: the panel is usually inside an
// `align(center)`, and centred code is unreadable.
#let source-panel(accent, size, body) = block(
  fill: rgb(0, 0, 0, 5),
  stroke: (left: (thickness: 3pt, paint: accent)),
  inset: (x: 1.1em, y: 0.9em),
  radius: 2pt,
  width: 100%,
  align(left, text(size: size, body)),
)

#title-slide()

// ---------------------------------------------------------------------------
// SAY: I am going to start with the part nobody in this room disagrees with.
// SAY: We should publish our data, and we should publish it so that somebody
// SAY: else can actually use it. Findable, accessible, interoperable,
// SAY: reusable. You have all seen this poster.
// SAY: What I want you to notice is the second half of each of those glosses.
// SAY: Every one of them is about somebody who is not you. Somebody searching
// SAY: without knowing your name. Somebody retrieving without emailing you.
// SAY: Somebody opening the file without your code. That is the whole standard,
// SAY: and it is not controversial.
== We already agree on this

#v(0.9em)
#big(fair, cap: 165%)
#v(1.0em)
#note[Wilkinson et al. (2016). Nobody argues with it. Almost nobody does it.]

// ---------------------------------------------------------------------------
// SAY: So here is what we say instead. I have said all four of these, and I
// SAY: suspect you have too.
// SAY: It is too much work: I have a paper to finish and this is a week I do
// SAY: not have. My data is too big: FAIR is fine for a spreadsheet of test
// SAY: results, but I have terabytes. Nobody would use it: it is a niche
// SAY: dataset for a niche problem. And the most reasonable-sounding one of
// SAY: all: I will put it up if somebody asks, and then I will do the work
// SAY: properly, for a real user.
// SAY: These are not stupid objections. Three of the four are testable, and
// SAY: somebody has tested them.
== What we say instead

#v(1.0em)
#big(refrains, cap: 160%)

// ---------------------------------------------------------------------------
// SAY: This is half a million papers across the PLOS and BMC journals. They
// SAY: sorted every one by what its data availability statement actually said,
// SAY: and counted citations over three years against the average for the same
// SAY: journal.
// SAY: Restricted: nothing. Available on request: nothing. A table in the
// SAY: supplement: nothing. A link to a repository: twenty-five percent.
// SAY: Look at the second bar, because that is the one that kills the refrain.
// SAY: "I will put it up if somebody asks" sounds like a weaker version of
// SAY: sharing that gets you most of the benefit. It was measured, and it does
// SAY: nothing.
// SAY: Nobody asks. And this answers the third refrain too, the one about
// SAY: nobody using it, because the effect is the use.
// SAY: This is a correlation, not an experiment. Nobody randomised it. But the
// SAY: gradient is the interesting part: the three rows that cost you nothing
// SAY: buy you nothing, and the one that takes an afternoon is the one that
// SAY: moves.
== Three of those are testable

#v(0.5em)
#align(center, image("out/png/citation.png", width: 82%))
#v(0.5em)
#note[Colavizza et al. (2020), #emph[PLOS ONE]. 531,889 articles, three-year citation window.]

// ---------------------------------------------------------------------------
// SAY: Which leaves "my data is too big". So let me put our cards on the table,
// SAY: because if that objection holds anywhere it should hold here.
// SAY: This is one earthquake from our validation set. Ground velocity at
// SAY: fifty-two thousand sites. There are eighty-one events in that set, and
// SAY: that is the SMALL study. It is the one we use to check ourselves
// SAY: against recordings.
// SAY: The pilot for the next Cybershake is two hundred and ninety-three
// SAY: ruptures at up to a hundred thousand sites each. A full Cybershake is
// SAY: tens of thousands of simulations.
// SAY: So: yes. It is big. That has never been the reason.
== "My data is too big"

#grid(
  columns: (1.4fr, 1fr),
  column-gutter: 1.1em,
  align: horizon,
  image("figures/pgv_2016p858094.png", height: 100%),
  [
    #headline([51,895], [sites, in this one earthquake])

    #v(0.7em)

    #headline([81], [events in the validation set])

    #v(0.7em)

    #headline([293], [ruptures in the Cybershake pilot])

    #v(0.9em)

    #text(fill: quiet.darken(20%), size: 0.88em)[A full Cybershake is tens of
    thousands of simulations. Big has never been the reason.]
  ],
)

// ---------------------------------------------------------------------------
// SAY: And for years we were terrible at this, so I am not lecturing anybody.
// SAY: Here was the pipeline. A box of code that only ran on one cluster,
// SAY: because it named specific modules and specific paths. Then tar. Then
// SAY: Dropbox.
// SAY: Two hundred and fifteen terabytes, eighteen thousand tarballs. The
// SAY: largest single one is three hundred and seventy gigabytes. To look at
// SAY: one station in it, you download all of it.
// SAY: And here is the part that actually changed my mind. It was not that
// SAY: outsiders could not use this. It is that WE could not. When I wanted a
// SAY: number out of a run from three years ago, the honest answer was that it
// SAY: would be quicker to run it again. That makes it a backup rather than an
// SAY: archive, and nobody re-reads a backup.
== We were terrible at this

#v(0.9em)
#big(old-pipeline, cap: 170%)

// ---------------------------------------------------------------------------
// SAY: So: five changes. Read the top line of each box, not the technology
// SAY: underneath. The top line is the thing that matters; the technology is
// SAY: just what we happened to use, and yours can differ.
// SAY: Four of these five you could start this afternoon without adopting
// SAY: anything of ours.
== Five changes

#v(1.1em)
#big(changes(), cap: 175%)
#v(1.0em)
#note[Read the top line of each box. The technology underneath is only what we chose.]

// ---------------------------------------------------------------------------
// SAY: One. Pin the environment. Everything the analysis needs is inside one
// SAY: file: the operating system, the exact Python, our packages pinned to a
// SAY: git commit, the compiled tools. You copy that file to a machine and run
// SAY: it.
// SAY: The reason this matters is not tidiness. Our environment used to be a
// SAY: shell script that named a specific Python module on a specific cluster.
// SAY: When that module was retired, the method was gone. Not the results. The
// SAY: method.
// SAY: The dashed box is the honest part: the MPI solvers still use the host's
// SAY: network fabric, because nothing portable can. So this is not magic. But
// SAY: everything except the solver stopped being the machine's business.
== Pin the environment

#v(0.7em)
#big(container-stack, cap: 185%)
#v(0.7em)
#note[Built from a recipe in version control, tagged with the commit it was built from.]

// ---------------------------------------------------------------------------
// SAY: Two. Publish the tools. These are last month's installs of our packages
// SAY: from the public Python index. Anyone can type one command and have our
// SAY: rupture code on their laptop, with no account, no cluster and no email
// SAY: to me.
// SAY: I can't tell you who these people are, and some fraction of it is
// SAY: continuous integration. But it is not us. We are maybe five people, and
// SAY: this is sixteen hundred installs of one package in a month.
// SAY: Remember the refrain that nobody would use it. Nobody asked us for any
// SAY: of these.
== Publish the tools

#v(0.3em)
#align(center, image("out/png/pypi.png", width: 74%))
#v(0.2em)
#note[Last 30 days, from the public package index. Nobody asked us for any of these.]

// ---------------------------------------------------------------------------
// SAY: Three. Let the data describe itself. This is one group out of a real
// SAY: intensity measure file from the validation runs, and the printout is
// SAY: literally what you get when you open it.
// SAY: Fifty-two thousand stations. And look at what travels WITH the numbers:
// SAY: latitude, rupture distance, Joyner-Boore distance, site velocity, basin
// SAY: depth. Units on every one of them. Seven components of motion, named.
// SAY: You do not need my code and you do not need to ask me what a column
// SAY: means.
// SAY: This is NetCDF, which your climate colleagues have used for thirty
// SAY: years. MATLAB, R, Python and ArcGIS all open it today. That is the "I"
// SAY: in FAIR, and it costs nothing at write time.
== Let the data describe itself

#v(0.3em)
#grid(
  columns: (1.62fr, 1fr),
  column-gutter: 1.0em,
  align: horizon,
  // Verbatim from
  //   xr.open_datatree(...)["PGV"].pint.quantify()
  // on validation_results_24-08/2016p858094/emod3d_full/intensity_measures.h5.
  // Rows are elided to fit; nothing is added. The units and the site terms are
  // exactly what the file hands back, which is the whole claim.
  source-panel(stat, 0.56em)[
    ```
    <xarray.Dataset> Size: 10MB      Group: /PGV
    Dimensions:   (station: 51895)
    Coordinates:
      * station   (station) <U7      'ADCS' 'AICS' ... 'rvpcATA'
        latitude  (station) float32  [deg]  -43.90 -42.77 ...
        rrup      (station) float64  [km]   173.8  47.55 ...
        rjb       (station) float64  [km]   171.2  45.90 ...
        vs30      (station) float64  [m/s]  431.0  299.0 ...
        z1pt0     (station) float64  [km]   0.1781 0.3156 ...
    Data variables:
        000       (station) float64  [cm/s] 0.2937 0.4598 ...
        090       (station) float64  [cm/s] 0.2507 0.8212 ...
        ver       (station) float64  [cm/s] 0.1144 0.1146 ...
        rotd50    (station) float64  [cm/s] 0.2701 0.6205 ...
    Attributes:
        name:         PGV
        description:  Peak ground velocity
    ```
  ],
  [
    #text(fill: stat, weight: "bold")[NetCDF.] The format atmospheric science
    has used for thirty years.

    #v(0.5em)

    Opens in MATLAB, R, Python and ArcGIS #emph[today], with no code of ours.

    #v(0.5em)

    #text(fill: quiet.darken(20%), size: 0.9em)[The distances, the site terms
    and the units are *in the file*. Nobody has to be told.]
  ],
)

// ---------------------------------------------------------------------------
// SAY: Four. If you take one thing from this talk, take this one. Keep the
// SAY: recipe with the result.
// SAY: Every run we do is described by one JSON file. This is a piece of a real
// SAY: one. The magnitude. The rake. The domain, its depth and how long we
// SAY: simulated for. The velocity model, by version number, with the settings
// SAY: it was built under. Twenty-three sections like that, fifty-five
// SAY: kilobytes, and it is the ONLY input to the run. It is text, and it is in
// SAY: version control.
// SAY: But look at the bottom half. Every tool that touched this file appended
// SAY: its own name, the exact version of the code that ran, the time, and the
// SAY: arguments it was given. The file wrote its own provenance.
// SAY: And look at those paths: slash realisation, slash EMOD3D. That is
// SAY: inside the container. The file is telling you it ran in the pinned
// SAY: environment. I did not have to write that down and hope I was honest.
// SAY: This is what turns "we ran a simulation" into something you can check.
== Keep the recipe with the result

#v(0.6em)
#big(provenance, cap: 205%)

// ---------------------------------------------------------------------------
// SAY: Five. Once every run is a self-describing file with its recipe attached,
// SAY: you can pour all of them into one database. This is the Cybershake
// SAY: pilot: two hundred and ninety-three ruptures, a hundred and five
// SAY: thousand sites, a hundred and eleven periods. One point six billion
// SAY: spectral values, in one file, on my laptop.
// SAY: So here is a question I asked it. For every site sitting in a
// SAY: sedimentary basin, how much bigger is the shaking than at rock sites the
// SAY: same distance from the same rupture? Distance-controlled, because basins
// SAY: are where people live and people live on flat ground near faults.
// SAY: Canterbury: two and a half times. Palmerston North: two. Twenty-one
// SAY: basins, eight and a half million site values, across all two hundred and
// SAY: ninety-three ruptures.
// SAY: That took one second. Assembled by hand out of per-run CSVs it is an
// SAY: afternoon of scripting, and so nobody does it for two hundred and
// SAY: ninety-three runs, which is why this answer did not exist before the
// SAY: database did.
// SAY: The formats are what make a question like this cost a second instead of
// SAY: a week. That is the whole reason to care about them.
== A question you would not have asked

#v(0.2em)
#grid(
  columns: (1fr, 1.72fr),
  column-gutter: 0.9em,
  align: horizon,
  [
    #duckdb-shape
    #v(0.8em)
    #text(size: 0.86em, fill: quiet.darken(25%))[Basin sites against rock sites
    at the same rupture distance, over every rupture in the pilot.]
  ],
  image("out/png/basins.png", width: 100%),
)

// ---------------------------------------------------------------------------
// SAY: One last thing, and it is the piece I underestimated for years.
// SAY: We are all comfortable asking a cluster for compute. You write a
// SAY: proposal, you get core hours, everyone understands the unit. Nobody asks
// SAY: the same cluster what its data transfer looks like.
// SAY: These are the five machines we run on. Two of them have a managed,
// SAY: restartable, parallel transfer service on dedicated hardware. Three of
// SAY: them, you log into a head node and run scp, and when it dies at ninety
// SAY: percent you start again.
// SAY: I am not saying the other three are badly run. I am saying we never
// SAY: asked, so it never got provisioned.
// SAY: And the arithmetic is brutal: exascale compute with gigascale data
// SAY: transfer is gigascale compute. You are bound by the slowest part, and
// SAY: right now the slowest part is the one nobody costed.
// SAY: So when you ask for the allocation, ask for the transfer too.
== Ask for the data transfer too

#v(0.6em)
#big(transfer-gap, cap: 150%)

#v(0.9em)
#align(center)[
  #text(size: 1.06em, fill: defect, weight: "bold")[Exascale compute with
  gigascale data transfer is gigascale compute.]
]
