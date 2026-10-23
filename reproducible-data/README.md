# Reproducible and usable scientific data at scale

A 15-minute talk for earthquake engineers on research data: why published data
goes unused, the four habits that lose it, and five changes that make it
checkable by somebody else.

The subject is data practice, not our workflow. Every tool named is an example
of a category, and the deck is written so that somebody running MATLAB on a
departmental server can act on four of the five without adopting anything of
ours. If a revision starts to read like a product tour, that is the thing to
cut.

```sh
just          # data figures, then main.pdf
just watch    # live rebuild while editing
just slides   # one PNG per slide, for review
```

## Where the numbers come from

Nothing on a slide is asserted where it could be measured. Every figure below
names the thing it was read out of, so a claim can be checked without asking
the author what he meant.

| Claim | Source |
| --- | --- |
| FAIR | Wilkinson et al. (2016), *Scientific Data* 3:160018 |
| +25% citations for a repository link, and nothing for the other three | Colavizza, Hrynaszkiewicz, Staden, Whitaker & McGillivray (2020), *PLOS ONE* 15(4): e0230416 — 531,889 PLOS/BMC articles, three-year window |
| PGV map, 2016p858094 M#(w) 6.1, 51,895 sites | `eqvis map` over `~/tmp/validation_results_24-08/2016p858094/emod3d_full/intensity_measures.h5` |
| 81 events in the validation set | `~/tmp/im_database/` |
| 215 TB, 18,349 tarballs, the 370 GB one | full rclone listing of the QuakeCoRE Dropbox, `~/tmp/listing.json` (684,914 entries); largest file is `Public/Cybershake/v19p5/_v19p5_BB/AlpineF2K.tar` |
| Container contents and 1.7 GB | `ucgmsim/workflow`, `container/{Dockerfile,runner.def}`; `ls` of the built `runner.sif` |
| PyPI installs per month | pypistats, fetched at build time by `scripts/plot_pypi.py` |
| The xarray printout | `.../2016p858094/emod3d_full/intensity_measures.h5`, PGV group, `pint.quantify()` |
| The realisation excerpt and its 17-entry log | `~/tmp/validation_results_24-08/2016p858094/realisation.json` |
| 293 ruptures / 105 k stations / 1.6 B spectral values | `~/tmp/ims.duckdb`, the Cybershake pilot (18 GB) |
| Basin amplification, 21 basins, 8.4 M site values | same database, queried at build time by `scripts/plot_basin_amplification.py` |
| Which clusters have managed data transfer | the group's own operational experience of TACC, REANNZ HPC3, ESNZ Cascade, MareNostrum 5 and KISTI |

## The basin query

The slide's claim is that this answer did not exist before the database did, so
the query is worth reading. For every site inside a named basin it takes the
median log PGV, subtracts the median for rock sites in the same rupture-distance
band of the same rupture, and exponentiates. The distance banding is what makes
it an answer rather than an artefact: basins are where people live, people live
on flat ground near faults, and an unbanded basin-versus-rock comparison would
mostly measure that. 8.4 million site values, 293 ruptures, about a second.

## Speaker notes

Every slide has its notes as `// SAY:` comments immediately above it in
`main.typ`, the same convention as the other decks in `~/Documents`. The slides
carry almost no prose on purpose: the argument is spoken, and written text is
reserved for numbers that have to stay readable for as long as the slide is up.

## Prose linting

`just lint` runs Vale over the deck's prose with two AI-writing-tell rulesets
plus one local rule; `just metrics` prints the structural densities Vale cannot
express. Both are calibrated against `~/Documents/phd-proposal` and nothing
else — see `scripts/prose_metrics.py` for why that baseline and not the earlier
decks.

## Cut material

`figures/unused/` holds what came off the slides and why, including the
Figshare screenshot behind the 275 / 73 / 0 (off the slide because it names the
dataset's author, who may be in the room) and the SW4 waveform pair (the best
answer to "how did you know the runs were wrong?" if it comes up in questions).
