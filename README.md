# Presentations

Talks written in [Typst](https://typst.app) with the touying slide package.
Every push to `main` builds each one as an HTML deck and a PDF and publishes
them to GitHub Pages at <https://lispandfound.github.io/>, under a profile page
that also lists publications, posters and software. Each talk lives at
`/<folder>/`.

| Folder | Talk |
|---|---|
| `cybershake-nshm/` | Cybershake NZ: towards simulations in the NSHM |
| `reproducible-data/` | Reproducible and usable scientific data at scale |
| `gmcm-modelling/` | Towards 2+ Hz: topography, variable mesh refinement and modular velocity models |

Each talk is self-contained: `main.typ`, its figures, and a `Justfile` (`just`
in the folder builds it). `reproducible-data` and `cybershake-nshm` keep their
history from their old repositories.

## Figures are committed

Most figures are made from simulation data that is not in this repo (it runs to
gigabytes), so the generated PNGs are committed and CI only runs Typst. To
regenerate one, run its script in the talk's `scripts/` folder against the
data; each script's header says where the data lives.

## The site

```sh
python3 tools/build_site.py        # -> site/
python3 -m http.server -d site     # browse it at localhost:8000
```

The index page is a profile: about, publications, posters, conference
submissions, software and talks.
`tools/build_site.py` holds the lists; add a folder to `TALKS` to publish a new
talk, and add papers, posters, conference submissions and software releases to
`PUBLICATIONS`, `POSTERS`, `CONFERENCE` and `SOFTWARE` by hand.
`tools/make_html.py` turns one deck into an HTML slideshow (`s` opens the
speaker view; any `<video>` metadata in the deck becomes a playing video) and
works on its own:

```sh
cd cybershake-nshm && uv run ../tools/make_html.py --title "..."   # -> out/html/
```

Speaker notes are read from either convention used here: `// SAY:` comment
blocks above a `== Title`, or `#say[...]` under it.
