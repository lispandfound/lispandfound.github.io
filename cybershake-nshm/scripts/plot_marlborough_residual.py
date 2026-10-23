"""The 1848 Marlborough simulation against the NSHM 2022 empirical model, pSA(3 s).

Run with the eqvis environment, from the talk root:

    uv run --project ~/src/eqvis_workflow python -I scripts/plot_marlborough_residual.py

Drawn in the eqvis_workflow figure vocabulary, reusing its pieces rather than
copying them: ``open_ims``/``select_im``/``select_empirical`` to read the run and
its stored NSHM 2022 prediction, ``rasterise`` for the interpolated, coast-clipped
field, ``fixed_symmetric_norm`` + ``label_ratios`` for the diverging colour bar
with its ×2 / ×½ factors on top, ``draw_coastline``/``draw_geometry`` for the
shore, domain, source outline and hypocentre, and ``Display`` to size the text for
a projector. ``eqvis map --diff`` itself cannot do this: it differences two IM
files, not a run against the ``pSA/empirical/<model>`` group it carries.

The residual is ln(SA_sim / SA_NSHM) -- the ``map --diff`` order, run 1 over run
2 -- with SA_sim the simulated RotD50 (``pSA/rotd50``) and the NSHM term
``pSA/empirical/NSHM2022/mean``, which is stored as the mean of ln SA, so no
further logging. ``std_Total`` is its total sigma of ln SA; the sigma-normalised
residual is printed only. The right panel is the binned mean residual with a
±1σ band of the between-site scatter in each bin, not the model's sigma. The
file does not record which logic-tree branches were combined or how.

The arm is ``prefilter``. 3 s is a stored period. Sites inside the SW4 supergrid
(supergrid_depth > 0) are dropped before interpolation. Distance is the stored
Rrup. One event, so the mean residual over sites is its between-event term
(unweighted: the dense array over-samples the populated areas).

eqvis has no town set of its own, so the towns are listed here. Five names do
not need its automatic placer (which, at slide text sizes, pushed them off their
markers in the crowded Sounds), so each gets a fixed offset beside its marker,
with the white halo eqvis gives every map label.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import BoundaryNorm
from matplotlib.ticker import FuncFormatter, MaxNLocator

from eqvis_workflow.constants import EMPIRICAL_BLUE, SIM_CLOUD_GREY, SIM_ONE_BLACK
from eqvis_workflow.data import im_label, open_ims, select_empirical, select_im
from eqvis_workflow.display import Display
from eqvis_workflow.geography import draw_coastline, draw_geometry, load_coastline
from eqvis_workflow.raster import fixed_symmetric_norm, label_ratios, rasterise
import matplotlib.patheffects as patheffects

PERIOD = 3.0  # s
LIMIT = 1.5  # ln units, symmetric colour limit
MODEL = "NSHM2022"  # the group in the IM file
SHOWN = "NSHM"  # how the figure names it
TOWNS = {  # name: (lon, lat), label offset in points, ha, va
    "Nelson": ((173.284, -41.271), (-5, 0), "right", "center"),
    "Blenheim": ((173.954, -41.514), (6, -1), "left", "top"),
    "Wellington": ((174.776, -41.286), (5, 0), "left", "center"),
    "Kaikōura": ((173.681, -42.400), (5, 0), "left", "center"),
    "Christchurch": ((172.637, -43.532), (5, 0), "left", "center"),
}
NEAR_KM = 5.0  # "town area" radius for the printed town residuals
# The slide: drawn at 13.33 x 7.5 in, shown about a metre tall and read from the
# back of a lecture theatre. Display turns that into the text scale (~1.9x).
DESIGN = (13.33, 7.5)
SHOWN_HEIGHT = 100.0  # cm
VIEWING_DISTANCE = 5.0  # m


def running_mean(x, y, edges, least=30):
    """Mean and standard deviation of y in each bin of x with enough sites."""
    mid, mu, sd = [], [], []
    for a, b in zip(edges[:-1], edges[1:]):
        m = (x >= a) & (x < b)
        if m.sum() >= least:
            mid.append(np.sqrt(a * b))
            mu.append(y[m].mean())
            sd.append(y[m].std(ddof=1))
    return np.array(mid), np.array(mu), np.array(sd)


def km_from(lon, lat, lon0, lat0):
    dx = (lon - lon0) * 111.195 * np.cos(np.radians(lat0))
    return np.hypot(dx, (lat - lat0) * 111.195)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--data", type=Path, default=Path("/var/tmp/marlborough_1848"))
    ap.add_argument("--arm", default="prefilter")
    ap.add_argument("--out-dir", type=Path, default=Path("out/png"))
    ap.add_argument("--dpi", type=int, default=300)
    args = ap.parse_args()

    tree = open_ims(args.data / args.arm / "intensity_measures.h5")
    sim, selection = select_im(tree, "pSA", "rotd50", PERIOD, None)
    mean, sigma = select_empirical(tree, "pSA", MODEL, selection)
    assert (mean.station.values == sim.station.values).all(), "sim/GMM station order differ"
    period = selection["period"]
    label = im_label("pSA", selection)

    keep = (sim.supergrid_depth.values == 0) & (sim.values > 0) & np.isfinite(mean.values)
    lon, lat = sim.longitude.values[keep], sim.latitude.values[keep]
    rrup = sim.rrup.values[keep]
    res = np.log(sim.values[keep]) - mean.values[keep]
    sig = sigma.values[keep]
    z = res / sig
    event = float(res.mean())

    print(f"T = {period:g} s; {keep.sum()} sites ({(~keep).sum()} dropped: supergrid / invalid)")
    print(f"ln residual: mean {event:+.3f}, median {np.median(res):+.3f}, sd {res.std(ddof=1):.3f}; "
          f"5-95% [{np.percentile(res, 5):+.2f}, {np.percentile(res, 95):+.2f}]")
    print(f"  exp(mean) = {np.exp(event):.2f}; median sigma_T = {np.median(sig):.3f}")
    print(f"normalised by sigma_T: mean {z.mean():+.3f}, median {np.median(z):+.3f}")
    for name, ((tlon, tlat), *_) in TOWNS.items():
        m = km_from(lon, lat, tlon, tlat) <= NEAR_KM
        if m.any():
            print(f"  {name}: {m.sum()} sites within {NEAR_KM:g} km, median ln res {np.median(res[m]):+.3f} "
                  f"(IQR {np.percentile(res[m], 25):+.2f} .. {np.percentile(res[m], 75):+.2f}), "
                  f"median z {np.median(z[m]):+.2f}, Rrup {np.median(rrup[m]):.0f} km")
    for a, b in ((0, 10), (10, 30), (30, 60), (60, 100), (100, 200), (200, 1e4)):
        m = (rrup >= a) & (rrup < b)
        if m.any():
            print(f"  Rrup {a:g}-{b:g} km: n={m.sum()}, median ln res {np.median(res[m]):+.3f}")

    display = Display.for_figure(DESIGN, args.dpi, SHOWN_HEIGHT, VIEWING_DISTANCE)
    display.report(DESIGN)

    coast = load_coastline()
    grid_lon, grid_lat, grid = rasterise(lon, lat, res, coast)
    boundaries = fixed_symmetric_norm(LIMIT, 10)
    colormap = plt.get_cmap("RdBu_r")
    norm = BoundaryNorm(boundaries, colormap.N, extend="both")

    # Two figures, one per panel, cropped tight: the slide lays them out and
    # prints the headline itself (from the JSON written below), so neither
    # panel carries whitespace the slide cannot use.
    width, height = display.size
    fig, ax = plt.subplots(figsize=(0.55 * width, height), layout="constrained")
    figr, axr = plt.subplots(figsize=(0.6 * width, 0.62 * height), layout="constrained")

    # --- Map, as `eqvis map --diff` draws it ---------------------------------
    mesh = ax.pcolormesh(grid_lon, grid_lat, grid, cmap=colormap, norm=norm, rasterized=True)
    view = (grid_lon.min(), grid_lat.min(), grid_lon.max(), grid_lat.max())
    if coast is not None:
        draw_coastline(ax, coast, view, display)
    draw_geometry(ax, tree.attrs, display)
    ax.set_xlim(view[0], view[2])
    ax.set_ylim(view[1], view[3])
    ax.set_aspect(1 / np.cos(np.radians(lat.mean())))
    degrees = FuncFormatter(lambda v, _: f"{v:g}°")
    ax.xaxis.set_major_formatter(degrees)
    ax.yaxis.set_major_formatter(degrees)
    for axis in (ax.xaxis, ax.yaxis):
        axis.set_major_locator(MaxNLocator(nbins=display.ticks(7)))
    ax.tick_params(labelsize=8)
    for spine in ax.spines.values():
        spine.set_linewidth(display.mark(0.6))

    colorbar = fig.colorbar(mesh, ax=ax, orientation="horizontal", shrink=0.85, pad=0.02,
                            aspect=display.mark(35))
    colorbar.set_label(f"ln[{label}$_{{sim}}$ / {label}$_{{{SHOWN}}}$]", fontsize=10)
    shown = display.keep(list(boundaries), max(3, display.ticks(len(boundaries))))
    colorbar.set_ticks(shown)
    colorbar.set_ticklabels([f"{b:g}" for b in shown], fontsize=8)
    label_ratios(colorbar, fontsize=6.5)

    halo = [patheffects.withStroke(linewidth=2.0, foreground="white")]
    for name, ((tlon, tlat), offset, ha, va) in TOWNS.items():
        if not (view[0] < tlon < view[2] and view[1] < tlat < view[3]):
            continue
        ax.plot(tlon, tlat, "o", ms=display.mark(6), mfc="white", mec="black", mew=display.mark(1.0),
                zorder=6)
        ax.annotate(name, (tlon, tlat), textcoords="offset points", xytext=offset, ha=ha, va=va,
                    fontsize=8, path_effects=halo, zorder=7)

    # --- Residual against Rrup, as `eqvis distance` panels draw it ----------
    edges = np.geomspace(max(rrup.min(), 0.5), rrup.max() * 1.001, 22)
    mid, mu, sd = running_mean(rrup, res, edges)
    # The band is the between-site scatter in each distance bin, not the
    # model's sigma. The model is the zero line, in its own colour and dash.
    axr.fill_between(mid, mu - sd, mu + sd, color=SIM_CLOUD_GREY, lw=0, zorder=1)
    axr.axhline(0, color=EMPIRICAL_BLUE, lw=display.mark(1.4), ls="--", zorder=3)
    axr.plot(mid, mu, color=SIM_ONE_BLACK, lw=display.mark(2.4), zorder=4)
    axr.set_xscale("log")
    axr.set_xticks([1, 10, 100], ["1", "10", "100"])
    axr.set_xlim(edges[0], edges[-1])
    axr.set_ylim(-2, 3)
    axr.grid(True, which="both", lw=0.3, color="#dddddd", zorder=0)
    axr.set_xlabel("R$_{rup}$ (km)", fontsize=9)
    axr.set_ylabel(f"ln[{label}$_{{sim}}$ / {label}$_{{{SHOWN}}}$]", fontsize=9)
    axr.tick_params(labelsize=8)
    for spine in axr.spines.values():
        spine.set_linewidth(display.mark(0.6))
    axr.legend(
        handles=[
            plt.Line2D([], [], color=SIM_ONE_BLACK, lw=display.mark(2.4), label="mean"),
            plt.Rectangle((0, 0), 1, 1, color=SIM_CLOUD_GREY, lw=0, label="±1σ between sites"),
            plt.Line2D([], [], color=EMPIRICAL_BLUE, ls="--", lw=display.mark(1.4), label=SHOWN),
        ],
        loc="lower left", fontsize=7, frameon=False,
    )

    args.out_dir.mkdir(parents=True, exist_ok=True)
    for figure, name in ((fig, "map"), (figr, "distance")):
        out = args.out_dir / f"marlborough-residual-{name}.png"
        figure.savefig(out, dpi=display.dpi, bbox_inches="tight", pad_inches=0.03)
        print(f"wrote {out}")
    # The headline number, for the slide to print rather than retype.
    headline = args.out_dir / "marlborough-residual.json"
    headline.write_text(json.dumps({"event_term": round(event, 2), "period": float(period),
                                    "sites": int(keep.sum())}))
    print(f"wrote {headline}")


if __name__ == "__main__":
    main()
