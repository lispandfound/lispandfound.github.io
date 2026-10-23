# Towards 2+ Hz — GMCM talk

A 30-minute talk (22 slides and 3 section headers after the title, about 2,200 words of notes) for the ESNZ GMCM team on objective 2: variable mesh refinement,
explicit topography, Backus averaging and the 2 Hz transition, and the software
behind them (SW4 and NZCVM). It opens on the hybrid method, the group's decade
at 1 Hz and the NSHM goal, then runs three sections: changing the solver
(EMOD3D to SW4), the velocity model codebase overhaul, and evaluating the
results, ending on the 1 Hz against 2 Hz extension (2013 Cook Strait). The
solver and velocity model sections are each a problem slide, then solutions.

```sh
just          # main.pdf
just watch    # live rebuild while editing
just slides   # one PNG per slide, for review
just notes    # main-notes.pdf: each slide with its speaker notes beside it
just pdfpc    # main.pdfpc: notes for presenting main.pdf with pdfpc
```

Speaker notes are `#say[...]` blocks under each slide's heading in `main.typ`.
Open items are `// TODO(jake):` comments.

## What is where

| Path | What |
|---|---|
| `main.typ` | the deck |
| `palette.typ` | shared colours, ported from `~/Documents/reproducible-data-talk/palette.typ` |
| `figures/uniform-grid.typ` | cetz: the previous uniform grid and flat free surface |
| `figures/refinement.typ` | cetz: SW4 refinement blocks with the benchmark point shares, and the spacing a schematic minimum V_S profile requires at 2 Hz against SW4's steps and EMOD3D's constant h |
| `figures/curvilinear-cartesian-grid.typ` | cetz: copied from `~/Documents/qcam-poster/figures/` |
| `figures/nzcvm-pipeline.typ` | fletcher: data files → layer chain → SW4 / EMOD3D writers |
| `figures/validation-design.typ` | fletcher: GMDB events → two workflows → mixed-effects residuals |
| `figures/icons.typ` | cetz pictograms for the "What SW4 brings" overview: refinement, topography, fourth order (the attenuation and NZCVM icons are unused) |
| `figures/sw4-cost.typ` | cetz: SW4 run time relative to EMOD3D on the benchmark event, log scale |
| `figures/accuracy-order.typ` | cetz: order of accuracy in the rows under the free surface, EMOD3D against SW4 |
| `figures/attenuation-cells.typ` | cetz: coarse-grained mechanisms against every mechanism at every point |
| `figures/research-loop.typ` | fletcher: how a velocity model change happens, before and after; staged over two slides |
| `figures/tomography-blend.typ` | cetz: models as 2D sheets, stacked by priority (isometric) and composited by alpha (plan view) |
| `figures/modeller-comparison.typ` | empirical against physics-based, term by term; staged over two slides |
| `figures/hybrid-method.typ` | fletcher pipeline and cetz crossover spectrum for the hybrid method |
| `figures/q-mechanisms.typ` | cetz: springs and dashpots, and Debye peaks summing to a near-constant $1/Q$ |
| `figures/study-timeline.typ` | cetz: transition frequency against year for the group's validation and Cybershake studies |
| `export.typ` | renders one figure standalone: `--input fig=<name>` |
| `figures/taumarunui*.png`, `figures/canterbury_fence.png` | copied from the QCAM poster and `~/src/nzcvm/docs/images/`; no script here to regenerate them |
| `scripts/backus_averaging.py`, `scripts/topography_representations.py` | regenerate `figures/backus_averaging.png`, `figures/backus_problem.png` and `figures/topography_representations.png`; adapted from `~/Documents/phd-proposal/Figures/` with slide-sized text and deck colours. The Backus script now takes the harmonic mean of μ (the original averaged it arithmetically) and samples at cell centres (the original sampled at cell tops, which caught the basin at the surface) |
| `scripts/tomography_coverage.py` | regenerates `figures/tomography_coverage.png`: the NZ coastline (eqvis cache), the national models as background, the Chow 2020 footprint from `~/src/nzcvm_data` (cells where the CHOW2020/EP2020 mix differs from EP2020), and an APPROXIMATE Bassett 2025 outline (that model is not in nzcvm_data yet) |
| `plot_fas_comparison.py` | regenerates `figures/fas_band_map.png` and `figures/fas_TEPS_POTS.png` from `intensity_measures_{1,2}Hz.h5`, in the `~/src/eqvis_workflow` style; run with `uv run --project ~/src/eqvis_workflow python plot_fas_comparison.py` |

## Numbers on the slides, and where they came from

| Claim | Source |
|---|---|
| Refinement blocks: 50/100/200/400 m, depth ranges, 66/19/13/2 % of points | `~/notes/20260703T130738--sw4-optimisation-notes`, "Benchmark" (2012p578973) |
| ~40 h vanilla SW4 on the benchmark | same note; `~/notes/presentations/sw4_compute.org` |
| ~3 h after process placement and tuning, same 50 m grid | same note, "Re-enabling 50m refinements" (5000 steps/h) |
| ≈ 1 h at 100 m with topography | same note, "Topography with 100m" (9500 steps/h) |
| 50 m with topography is about 6 h and "not realistic at this stage" | same note, "Topography with 50m" and "Takeaways" |
| Validation set: about 50 Mw 5–6 events at 100 m (1 Hz) with topography | validation note, rung 4; optimisation note, "Next Steps" |
| Vs30 site amplification is applied to the stochastic branch only | `~/src/workflow/workflow/scripts/bb_sim.py` (`amplify_waveform` on `hf` before the filters) |
| Cook Strait 2 Hz run: 50 m to 5 km, 100 m to 25 km, then 200 m; min V_S 0.5 km/s; `bb.flo = 2` | `realisation.json` |
| Cook Strait 1 Hz file is the same simulation combined at 1 Hz | inferred: its EAS matches the 2 Hz file exactly below about 0.6 Hz and above about 2.5 Hz. It is not the 100 m run in `~/src/comparison_runs_50m_100m/2013p543824` |
| ×0.71 Wellington, ×0.46 elsewhere, TEPS ×1.96, POTS ×0.76 (1–1.5 Hz) | `plot_fas_comparison.py`; Wellington is lat −41.4 to −41.05, lon 174.6 to 175.1 |
| Previous workflow at 1 Hz | `~/notes/20260729T101536--validation-of-sw4-workflow` (100 m ⇒ 1 Hz) |
| Layer names and behaviour | `~/src/nzcvm/README.md`, "Layers" and "Output formats" |
| TOML on the plug-and-play slide | `~/src/nzcvm/examples/2014p240655.toml`, plus the `backus` example from `nzcvm/config/layers/backus.py` |
| Taumarunui figures | `~/Documents/qcam-poster/figures/` |
| Same source and same stochastic HF across both workflows | validation note, rung 3 |
| EMOD3D: 4th order in space, 2nd order in the row under the free surface, 2nd order in time | Graves (1996), *BSSA* 86(4), staggered-grid velocity-stress scheme |
| EMOD3D attenuation: eight mechanisms coarse-grained over a 2×2×2 block | Day & Bradley (2001), *BSSA* 91(3) |
| SW4: 4th order in space and time; the summation-by-parts boundary closure keeps the solution 4th-order accurate overall, free surface included (its boundary rows are locally 2nd order) | Sjögreen & Petersson (2012), *J. Sci. Comput.*; SW4 user's guide |
| SW4 attenuation: every SLS mechanism at every grid point, three in our runs | Petersson & Sjögreen (2012), *Commun. Comput. Phys.*; SW4 user's guide |
| Priority ranges (basins 0–127, tomography 128–255) and alpha compositing | `~/src/nzcvm` model and query docs |
| The GTL snippet | illustrative, written against the public layer interface in `~/src/nzcvm/examples/near_fault.py` |

## Still to fill in

- Event and station counts for the moderate crustal run (the notes say "about
  fifty events", from `~/notes/20260729T101536--validation-of-sw4-workflow`).
- Whether the 100 m + topography runtime has moved since the performance work.
- The blending slide's regional model names are made up; swap in Ayushi's real
  ones if she is happy to have them shown.

## Staged slides

The section headers are level-one headings (`= Title`), which the metropolis
theme renders as title-only section slides. The problem and solution slides for
the research loop use the same figure (`research-loop(after: false/true)`); the
after row is drawn hidden on the problem slide, so the before row does not move
between them.

## The SW4 section

It describes what the method does, not how either code is written: no file,
function or module names, on the slides or in the speaker notes. Keep it that
way.

## Timeline sources

Every point on "A decade of hybrid simulations". The h and f_t values were
checked against the text named in the last column. UCIR is the UC research
repository (ir.canterbury.ac.nz).

| Point | Citation | h | f_t | Where the numbers are stated |
|---|---|---|---|---|
| Canterbury sequence | Razafindrakoto, Bradley & Graves (2016), NZSEE Conf. | 100 m | 1 Hz | the paper itself |
| Kaikōura | Bradley, Razafindrakoto & Polak (2017), *SRL* 88(3), doi:10.1785/0220160225 | 200 m | 0.5 Hz | secondary: Bradley (2019) *SDEE* |
| v17.8, v17.9 | Tarbali et al. (2017), QCAM poster, UCIR 10092/15894; Tarbali et al. (2018), NZSEE | 400 m | 0.25 Hz | the poster and paper |
| Christchurch | Razafindrakoto, Bradley & Graves (2018), *BSSA* 108(4), doi:10.1785/0120170388 | 100 m | 1 Hz | secondary: Bradley (2019) *SDEE*; Kuncar thesis ch. 2 |
| v19.5 | Bradley et al. (2019), SCEC poster; (2020) NZSEE | 400 m | 0.25 Hz | NZSEE 2020 (h); SCEC poster (f_t) |
| Canterbury, small Mw | Lee et al. (2020), *Earthq. Spectra* 36(2), doi:10.1177/8755293019891718 | 100 m | 1 Hz | the paper itself |
| v20.8, subduction | Motha et al. (2020), QCAM poster, UCIR 10092/101435 | 200 m | 0.5 Hz | the poster |
| Moderate Mw 5–7 | Lee, Bradley, Paterson, Motha & Graves (2021), NZSEE | 200 m | 0.5 Hz | the paper itself |
| NZ-wide, small Mw | Lee et al. (2022), *Earthq. Spectra* 38(4), doi:10.1177/87552930221109297 | 100 m | 1 Hz | secondary: Kuncar thesis ch. 3 |
| Site effects | Kuncar et al. (2025), *Earthq. Spectra* 41(2), doi:10.1177/87552930241301059 | 100 m | 1 Hz | Kuncar thesis ch. 2 (UCIR 10092/108910) |
| Subduction | Dupuis, Lee & Bradley (2025), *Earthq. Spectra* 41(5), doi:10.1177/87552930251353816 | 100 m | 1 Hz | Dupuis thesis ch. 3 (UCIR 10092/109371) |
| v25.6 | Abbasnejadfard et al. (2025), QCAM abstract; Bradley, Abbasnejadfard et al. (2026), *Earthq. Spectra* 42(4), doi:10.1002/esp4.70120 | 200 m | 0.5 Hz | the abstract and the paper's abstract |

| v26 (in-preparation panel) | Cybershake NZ v26, to be published in 2026 | 100 m | 1 Hz | supplied by Jake; not yet published |
| Unified validation database (in-preparation panel) | Small, moderate and large magnitude validation database | 100 m | 1 Hz | supplied by Jake; not yet published. Also the reference on the validation slide |
| NSHM 2022 sources (in-preparation panel) | Cybershake NZ on the NSHM 2022 source model, late 2026 to early 2027 | 100 m | 1 Hz | supplied by Jake; not yet published |

**Left off the chart:**
- Scenario-only studies: Alpine Fault AF8 (2017), Hope Fault (2019) and the Hikurangi scenarios.
- Cybershake v22.4 and the 2022 Hikurangi poster: the grid spacing and transition frequency they print contradict each other.
- The later Kuncar (2025, 2026) validation papers, which use the same 100 m and 1 Hz.

**Unconfirmed:**
- Cybershake v25.11 (NZSEE 2026, 100 m South Island): only the title is known, not the transition frequency. Check whether it is the same campaign as v26.
- Minimum V_S for v19.5, v20.8 and the 2026 paper: not stated. The slide's note therefore says "every study that states it".
