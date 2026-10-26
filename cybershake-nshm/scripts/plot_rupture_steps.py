"""The three steps of the multi-segment rupture generator, on one small fault system.

Feeds the "Sampled path, computed jump" slide. The system is made up: five
vertical strike-slip segments with stepovers of two to six kilometres, laid out
so that the jump graph has a cycle and the likeliest tree has to drop an edge.
Every number on the slide still comes from ~/src/rupture_generator itself:

1. Path. ``_jump_graph`` gives each pair of segments the Shaw--Dieterich jump
   probability for the gap between them, and ``_maximum_likelihood_tree``
   picks the likeliest tree, the maximum spanning tree over the log odds.
2. Fields. ``generate`` draws slip and onset on each segment; the slip on the
   hypocentre's segment is drawn here the way ``eqvis slip-panels`` draws it.
3. Jump. ``first_arrival`` times the front onto each child: parent onset at the
   departure cell plus the shear-wave crossing time, the earliest within reach.

Writes the slip panel as a PNG and everything the Typst schematics need (traces,
gaps, probabilities, tree, one worked jump) as JSON.

Run with the generator's own environment, as the Justfile does:

    uv run --project ~/src/rupture_generator --with matplotlib \
        python -I scripts/plot_rupture_steps.py --out-dir out/png
"""

import argparse
import dataclasses
import json
import tempfile
from pathlib import Path

import matplotlib.patheffects as patheffects
import matplotlib.pyplot as plt
import numpy as np
import pyproj
from matplotlib.colors import LinearSegmentedColormap
from rupture_generator import config as rupture_config
from rupture_generator.rupture.generator import JUMP_STREAM, _segment_rng, generate
from rupture_generator.rupture.propagator import _jump_graph

# Segment traces in kilometres east and north of ORIGIN, start to end. B continues
# A across a 2 km stepover, D branches off near their junction, and C and E carry
# the rupture on across wider gaps. A, B and D close a cycle.
TRACES_KM = {
    "A": ((0.0, 0.0), (30.0, 4.0)),
    "B": ((31.5, 5.5), (55.0, 9.0)),
    "C": ((57.5, 11.5), (75.0, 19.0)),
    "D": ((33.0, 0.5), (50.0, -8.0)),
    "E": ((80.0, 22.5), (95.0, 27.0)),
}
MAGNITUDES = {"A": 6.6, "B": 6.5, "C": 6.4, "D": 6.4, "E": 6.2}
ORIGIN_NZTM = (1_540_000.0, 5_180_000.0)  # mid-Canterbury, so NZTM covers it
HYPOCENTRE = {"segment": "A", "strike_fraction": 0.35, "dip_fraction": 0.6}
SEED = 2026
SPACING_KM = 0.2
LOWER_DEPTH_KM = 15.0

CONFIG = f"""
seed = {SEED}

[geometry]
path = "faults.geojson"
crs = "EPSG:2193"
spacing_km = {SPACING_KM}

[hypocentre]
segment = "{HYPOCENTRE["segment"]}"
strike_fraction = {HYPOCENTRE["strike_fraction"]}
dip_fraction = {HYPOCENTRE["dip_fraction"]}

[medium]
bottom_depth_km  = [1.0, 5.0, 15.0, 40.0]
shear_speed_km_s = [2.0, 3.0, 3.5, 3.8]
density_g_cm3    = [2.3, 2.6, 2.7, 2.8]

[source]
type = "per_fault"
magnitudes = {{ {", ".join(f"{k} = {v}" for k, v in MAGNITUDES.items())} }}
rakes = {{ {", ".join(f"{k} = 180.0" for k in MAGNITUDES)} }}

[propagation]
type = "likeliest"
"""

# Copied from eqvis_workflow/slip.py rather than imported, the convention in this
# tree: ColorBrewer YlOrRd with white in front, so a cell that did not slip reads as
# blank, and a darker red after, so the largest few stay tellable apart.
SLIP_RAMP = (
    "#ffffff",
    "#ffffcc",
    "#ffeda0",
    "#fed976",
    "#feb24c",
    "#fd8d3c",
    "#fc4e2a",
    "#e31a1c",
    "#bd0026",
    "#800026",
    "#4d0013",
)
HYPOCENTRE_COLOUR = "yellow"
CONTOUR_WIDTH = 0.9
CONTOUR_HALO = 2.2
ISOCHRONE_STEP_S = 2.0
ROBUST_RANGE = (0.01, 0.99)  # the ramp tops out at the 99th percentile


def write_inputs(folder: Path) -> Path:
    """Write the fault system's GeoJSON and rupture file, and return the latter."""
    to_wgs = pyproj.Transformer.from_crs("EPSG:2193", "EPSG:4326", always_xy=True)
    features = []
    for name, ends in TRACES_KM.items():
        coordinates = [
            to_wgs.transform(ORIGIN_NZTM[0] + 1e3 * x, ORIGIN_NZTM[1] + 1e3 * y)
            for x, y in ends
        ]
        (x0, y0), (x1, y1) = ends
        # Dip direction is right of strike; vertical, so it only fixes orientation.
        strike = np.degrees(np.arctan2(x1 - x0, y1 - y0))
        features.append(
            {
                "type": "Feature",
                "geometry": {"type": "LineString", "coordinates": coordinates},
                "properties": {
                    "name": name,
                    "dip_deg": 90.0,
                    "dip_direction_deg": float((strike + 90.0) % 360.0),
                    "upper_depth_km": 0.0,
                    "lower_depth_km": LOWER_DEPTH_KM,
                },
            }
        )
    geojson = {"type": "FeatureCollection", "features": features}
    (folder / "faults.geojson").write_text(json.dumps(geojson))
    (folder / "rupture.toml").write_text(CONFIG)
    return folder / "rupture.toml"


def plan_km(centre_km: np.ndarray) -> list[float]:
    """A cell centre in NZTM kilometres, as kilometres east and north of ORIGIN."""
    return [
        round(float(centre_km[0]) - ORIGIN_NZTM[0] / 1e3, 3),
        round(float(centre_km[1]) - ORIGIN_NZTM[1] / 1e3, 3),
    ]


def path_step(realisation, model) -> tuple[list[dict], list[list[str]]]:
    """Every gap in reach with its jump probability, and the likeliest tree's edges."""
    graph = _jump_graph(realisation, model)
    gaps = []
    for u, v in zip(*np.triu_indices(len(graph.faults), k=1), strict=True):
        if graph.weights[u, v] <= 0.0:
            continue
        a, b = graph.faults[u], graph.faults[v]
        near, far, gap_km = realisation[a].nearest_cells_to(realisation[b])
        k = int(np.argmin(gap_km))
        gaps.append(
            {
                "a": a,
                "b": b,
                "gap_km": round(float(gap_km[k]), 2),
                "p": round(float(graph.weights[u, v]), 2),
                "from": plan_km(realisation[a].centres[near[0][k], near[1][k]]),
                "to": plan_km(realisation[b].centres[far[0][k], far[1][k]]),
            }
        )
    tree = [[child, parent] for child, parent in realisation.tree.items() if parent]
    return gaps, tree


def jump_step(drawn, child: str, medium, model, seed: int) -> dict:
    """Redo ``first_arrival`` for one child, keeping the terms it adds up."""
    parent = drawn.tree[child]
    landings, departures, gap_km = drawn[child].geometry.nearest_cells_to(
        drawn[parent].geometry, interior=model.interior
    )
    reach_km = model.reach_km(
        float(gap_km.min()), _segment_rng(seed, JUMP_STREAM, child)
    )
    onset_s = drawn[parent].onset_s[departures]
    crossing_s = medium.crossing_time_s(
        drawn[parent].geometry.centres[departures],
        drawn[child].geometry.centres[landings],
    )
    arrival_s = np.where(gap_km <= reach_km, onset_s + crossing_s, np.inf)
    k = int(np.argmin(arrival_s))
    # The generator's own answer: the child's front starts at this time.
    assert np.isclose(arrival_s[k], drawn[child].onset_s.min(), atol=0.05)
    return {
        "parent": parent,
        "child": child,
        "gap_km": round(float(gap_km[k]), 2),
        "nearest_km": round(float(gap_km.min()), 2),
        "reach_km": round(float(reach_km), 2),
        "onset_s": round(float(onset_s[k]), 2),
        "crossing_s": round(float(crossing_s[k]), 2),
        "arrival_s": round(float(arrival_s[k]), 2),
        "candidates": int(np.isfinite(arrival_s).sum()),
    }


def plot_slip(segment, hypocentre, path: Path, dpi: int) -> None:
    """Slip on one segment with its isochrones, as eqvis slip-panels draws it."""
    slip = segment.slip_m
    onset = segment.onset_s
    ds, dd = segment.geometry.spacing_km
    ndip, nstrike = slip.shape
    extent = (0.0, nstrike * ds, ndip * dd, 0.0)
    hi = np.quantile(slip, ROBUST_RANGE[1])

    fig, ax = plt.subplots(figsize=(3.4, 1.95), layout="constrained")
    image = ax.imshow(
        slip,
        extent=extent,
        cmap=LinearSegmentedColormap.from_list("slip", SLIP_RAMP),
        vmin=0.0,
        vmax=hi,
        interpolation="nearest",
        aspect="equal",
    )
    strike_km = (np.arange(nstrike) + 0.5) * ds
    dip_km = (np.arange(ndip) + 0.5) * dd
    levels = np.arange(ISOCHRONE_STEP_S, onset.max(), ISOCHRONE_STEP_S)
    contours = ax.contour(
        strike_km, dip_km, onset, levels=levels, colors="black",
        linewidths=CONTOUR_WIDTH,
    )
    labels = ax.clabel(contours, fmt="%.0f s", fontsize=7.5, inline_spacing=2)
    for label in labels:
        label.set_path_effects(
            [patheffects.withStroke(linewidth=CONTOUR_HALO, foreground="white")]
        )
    ax.plot(
        hypocentre.strike_km, hypocentre.dip_km, marker="*", markersize=13,
        color=HYPOCENTRE_COLOUR, markeredgecolor="black", markeredgewidth=0.6,
    )
    ax.set_xlabel("Along strike (km)", fontsize=9)
    ax.set_ylabel("Down dip (km)", fontsize=9)
    ax.tick_params(labelsize=8)
    bar = fig.colorbar(image, ax=ax, extend="max", shrink=0.9, pad=0.02)
    bar.set_label("Slip (m)", fontsize=9)
    bar.ax.tick_params(labelsize=8)
    fig.savefig(path, dpi=dpi, transparent=True)
    plt.close(fig)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--dpi", type=int, default=300)
    args = parser.parse_args()
    args.out_dir.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as folder:
        path = write_inputs(Path(folder))
        config = rupture_config.load(path)
        config = dataclasses.replace(
            config,
            geometry=dataclasses.replace(
                config.geometry, path=str(Path(folder) / "faults.geojson")
            ),
        )
        scenario = rupture_config.build(config)

    realisation = scenario.realisation
    model = scenario.jump_model
    drawn = generate(
        realisation,
        scenario.medium,
        scenario.sources,
        scenario.model,
        seed=scenario.seed,
        jump_propagation_model=model,
    )
    gaps, tree = path_step(realisation, model)
    hypocentre = realisation.hypocentre
    root = drawn[hypocentre.segment]
    cell = root.geometry.cell_at(hypocentre.strike_km, hypocentre.dip_km)
    summary = {
        "segments": {
            name: {"trace": [list(end) for end in TRACES_KM[name]], "mw": MAGNITUDES[name]}
            for name in TRACES_KM
        },
        "hypocentre": {
            "segment": hypocentre.segment,
            "plan": plan_km(root.geometry.centres[cell]),
        },
        "gaps": gaps,
        "tree": tree,
        "jump": jump_step(drawn, "B", scenario.medium, model, scenario.seed),
    }
    (args.out_dir / "rupture-steps.json").write_text(json.dumps(summary, indent=2))
    plot_slip(root, hypocentre, args.out_dir / "rupture-steps-slip.png", args.dpi)
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()
