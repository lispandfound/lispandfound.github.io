# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib", "numpy", "geopandas", "pyarrow"]
# ///
"""The key idea: ruptures in, hazard contribution out, ranked.

Three real NSHM 2022 crustal ruptures, their real geometries, and their real
contributions to exceedance at one real site -- Christchurch, CBGS -- at the
10%-in-50-year threshold. Nothing here is schematic except the box in the middle.

The figure is built around one fact, and it is the whole argument:

    id 71972   Mw 8.53   Alpine Fault, 103 segments, 911 km across   12% of top
    id 354822  Mw 7.49   Hororata / Torlesse, 19 segments             top
    id 156695  Mw 6.99   CenPeg1n2, a single fault                    70% of top

The largest earthquake in the model is the one that matters LEAST to
Christchurch, and a moderate rupture in the foothills next door matters most.
Magnitude ranks these 8.53 > 7.49 > 6.99. Hazard ranks them 7.49 > 6.99 > 8.53.
No single-variable heuristic recovers that; the ground-motion model does it by
construction, because it knows where the site is.

Site weighting is deliberately out of scope -- this is one site.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import geopandas as gpd
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import FancyBboxPatch

plt.rcParams.update(
    {
        "font.family": "serif",
        "font.size": 8,
        "axes.linewidth": 0.6,
        "savefig.bbox": "tight",
    }
)

EXACT = "#23373b"
LAND = "#eeece8"
LAND_EDGE = "#c3c1bc"
MUTED = "#78776f"

# id -> (colour, label, short description)
PICKS = {
    71972: ("#2a78d6", "Alpine Fault", "103 segments"),
    354822: ("#eb6834", "Hororata – Torlesse", "19 segments"),
    156695: ("#1baf7a", "CenPeg1n2", "single fault"),
}
SITE = (1569284.0, 5180329.2)  # CBGS, Christchurch, NZTM2000
TARGET_RATE = 1.0 / 475.0
COAST = Path.home() / "Downloads" / "lds-nz-coastlines-and-islands-polygons-topo-150k-SHP.zip"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--repo", type=Path, default=Path.home() / "src" / "monte_carlo_hazard_estimation_code"
    )
    ap.add_argument("--out", type=Path, default=Path("out/png/key-idea.png"))
    ap.add_argument("--dpi", type=int, default=600)
    args = ap.parse_args()

    slice_ = np.load(args.repo / "report" / "figures" / "site_slice.npz")
    haz, rup, mag, rate = slice_["hazard"], slice_["rupture"], slice_["mag"], slice_["rate"]
    total = haz[:, :, 0].sum(axis=1) + slice_["subduction"][:, 0] + slice_["distributed"][:, 0]
    t = int(np.argmin(np.abs(total - TARGET_RATE)))
    contribution = haz[t, :, 0]

    ruptures = gpd.read_parquet(args.repo / "data" / "ruptures.parquet").xs(3, level="fault_system")
    rows = []
    for rid, (colour, name, note) in PICKS.items():
        k = int(np.where(rup == rid)[0][0])
        rows.append(
            dict(
                rid=rid,
                colour=colour,
                name=name,
                note=note,
                mw=float(mag[k]),
                rate=float(rate[k]),
                lp=float(contribution[k]),
                geom=ruptures.geometry.loc[rid],
            )
        )
    by_mag = sorted(rows, key=lambda r: -r["mw"])
    by_haz = sorted(rows, key=lambda r: -r["lp"])

    fig = plt.figure(figsize=(12.4, 3.7))
    gs = fig.add_gridspec(1, 3, width_ratios=[1.20, 0.80, 1.12], wspace=0.02)
    ax_map, ax_mid, ax_bar = (fig.add_subplot(gs[i]) for i in range(3))

    # --- the ruptures, at true relative scale --------------------------------
    frame = gpd.GeoDataFrame(geometry=[r["geom"] for r in rows], crs=ruptures.crs)
    minx, miny, maxx, maxy = frame.total_bounds
    # A small pad, and the panel width below is chosen to match the data aspect.
    # The Alpine rupture runs diagonally from Fiordland to the lower North
    # Island, so its bounding box carries two large empty ocean corners; any
    # extra padding multiplies that dead space and shoves the rest of the figure
    # right.
    pad = 0.025 * max(maxx - minx, maxy - miny)
    try:
        coast = gpd.read_file(COAST).to_crs(ruptures.crs)
        coast.plot(ax=ax_map, facecolor=LAND, edgecolor=LAND_EDGE, linewidth=0.4, zorder=0)
    except Exception as exc:  # noqa: BLE001
        print(f"note: coastline unavailable ({exc}); drawing ruptures without it")

    for r in rows:
        gpd.GeoSeries([r["geom"]], crs=ruptures.crs).plot(
            ax=ax_map, facecolor=r["colour"], edgecolor=r["colour"], linewidth=0.5, alpha=0.85, zorder=3
        )
    ax_map.plot(*SITE, marker="*", ms=13, mfc="white", mec="black", mew=0.9, zorder=5, ls="none")
    ax_map.annotate(
        "Christchurch",
        SITE,
        textcoords="offset points",
        xytext=(9, -3),
        fontsize=8,
        fontweight="bold",
        zorder=5,
    )
    ax_map.set_xlim(minx - pad, maxx + pad)
    ax_map.set_ylim(miny - pad, maxy + pad)
    ax_map.set_aspect("equal")
    ax_map.set_axis_off()
    ax_map.set_title("three ruptures", loc="left", fontsize=9, style="italic", color=MUTED)

    # Magnitude labels, in descending magnitude so the input ordering is explicit.
    for i, r in enumerate(by_mag):
        ax_map.annotate(
            f"$M_w$ {r['mw']:.2f}",
            (0.015, 0.965 - 0.062 * i),
            xycoords="axes fraction",
            fontsize=9,
            fontweight="bold",
            color=r["colour"],
        )

    # --- the box -------------------------------------------------------------
    # Padded limits so the arrows can run past the box on both sides without
    # being clipped at the axes edge.
    ax_mid.set_xlim(-0.14, 1.14)
    ax_mid.set_ylim(0, 1)
    ax_mid.set_axis_off()
    ax_mid.add_patch(
        FancyBboxPatch(
            (0.20, 0.26), 0.60, 0.48,
            boxstyle="round,pad=0.02,rounding_size=0.03",
            facecolor=EXACT, edgecolor="none", zorder=2,
        )
    )
    # Three lines, not two: the middle panel is narrow and "ground-motion model"
    # on one line is wider than the box can be made without crowding the arrows.
    ax_mid.text(0.5, 0.605, "NSHM 2022\nground-motion\nlogic tree", ha="center", va="center",
                color="white", fontsize=8.5, fontweight="bold", linespacing=1.3, zorder=3)
    ax_mid.text(0.5, 0.365, "magnitude, distance,\nsite condition", ha="center", va="center",
                color="#b9c2c4", fontsize=7, linespacing=1.3, zorder=3)
    # One block arrow each side rather than three thin ones fanning out. The fan
    # implied a correspondence between a particular rupture and a particular bar,
    # which is wrong -- the order changes across the box, so any such pairing
    # would have to cross. `arrowstyle="simple"` is sized in POINTS via
    # mutation_scale, so the head stays proportionate however the panel is
    # stretched; a FancyArrow in data units comes out squat here, because one y
    # unit is nearly twice one x unit in this axes.
    flow = dict(
        arrowstyle="simple,head_width=0.72,head_length=0.62,tail_width=0.30",
        facecolor="#a9a8a2", edgecolor="none", mutation_scale=30,
    )
    ax_mid.annotate("", xy=(0.17, 0.5), xytext=(-0.14, 0.5),
                    annotation_clip=False, arrowprops=flow)
    ax_mid.annotate("", xy=(1.14, 0.5), xytext=(0.83, 0.5),
                    annotation_clip=False, arrowprops=flow)

    # --- ranked contributions ------------------------------------------------
    # Plotted in units of 1e-5 /yr so the axis carries plain numbers instead of a
    # detached "1e-5" offset label in the corner.
    ys = np.arange(len(by_haz))[::-1]
    top = by_haz[0]["lp"]
    for y, r in zip(ys, by_haz):
        v = r["lp"] * 1e5
        ax_bar.barh(y, v, height=0.5, color=r["colour"], alpha=0.28,
                    edgecolor=r["colour"], linewidth=0.9, zorder=3)
        ax_bar.annotate(
            f"$M_w$ {r['mw']:.2f}   {r['name']}\n{v:.2f}   ·   {r['lp']/top*100:.0f}% of top",
            (v, y), textcoords="offset points", xytext=(7, 0), va="center",
            fontsize=8, color=r["colour"], fontweight="bold", zorder=4,
        )
    ax_bar.set_ylim(-0.6, len(by_haz) - 0.4)
    ax_bar.set_xlim(0, top * 1e5 * 1.95)
    ax_bar.set_yticks([])
    ax_bar.set_xlabel("contribution to exceedance rate  $\\lambda P$   ($\\times 10^{-5}$ /yr)",
                      fontsize=8, color=MUTED)
    ax_bar.tick_params(labelsize=7.5, colors=MUTED, width=0.6)
    for side in ("top", "right", "left"):
        ax_bar.spines[side].set_visible(False)
    ax_bar.spines["bottom"].set_color("#c9c8c3")
    ax_bar.set_title("ranked by hazard contribution", loc="left", fontsize=9, style="italic", color=MUTED)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.out, dpi=args.dpi)
    print(f"wrote {args.out}")
    for r in by_haz:
        print(f"  {r['rid']:>7d}  Mw {r['mw']:.2f}  lambdaP {r['lp']:.3e}  {r['name']}")


if __name__ == "__main__":
    main()
