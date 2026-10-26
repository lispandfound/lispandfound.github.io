# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib", "numpy", "h5py", "rasterio", "pyproj"]
# ///
"""A field-study ridge/reference ratio, recreated on the 1848 Marlborough simulation.

The paired-site experiment from the topographic-effects paper
(~/papers/moderate_crustal_topographic_effects, scripts/fig_paired_sites.py):
take the ratio of pSA (RotD50) at a ridge site to that at a nearby reference
site, as a field study would, and read it as topographic amplification. The
Otira pair is the paper's own, chosen there from the dense array with: outside
the supergrid, <= 5 km apart, |dVs30| <= 150 m/s, reference |H_1250| <= 10 m,
ridge H_1250 >= 40 m. Both sites exist in this run and neither sits in the
supergrid, so nothing is reselected.

Sugarloaf has no single reference. Its target is the run station nearest the
Kordia tower on the Port Hills summit, and its references are every station
that is flat at three scales (|H_1250| <= 10 m, |H_2500| <= 20 m,
|H_5000| <= 30 m), within 10 km, outside the supergrid and within 200 m/s in
Vs30. A reference flat at 1250 m alone can sit in a valley or on the massif at
the 2.5-5 km scale that 2-5 s waves see; the Vs30 window is what keeps the
Christchurch basin out. The ratio is drawn as the geometric mean over the
references, with their 16th-84th percentile as a band. A single-event
flat-site-against-flat-site version of the same ratio spreads 0.74-1.29
(P10-P90) at 2 s, so one pair inside that range says nothing.

What this figure CANNOT show, and the slide has to say: this event was run with
explicit topography only. There is no squashed (NT) companion, so the paper's
check -- the same ratio without topography, which measures how far the pair
departs from "similar site conditions" -- is absent. Everything here is T.

One event, so one curve per pair: no median, no interquartile band. The arm is
`prefilter` (SW4 source prefilter on, the 26.7.1Hz defaults). The run is
deterministic to ~1 Hz (bb flo = 1 Hz, SW4 prefilter corner 1.12 Hz), so only
periods of 1 s and longer are drawn.

The hillshade, contour and highway drawing is copied from fig_paired_sites.py
rather than imported, the convention in this tree; the DEM and the OSM state
highway extract are read from the paper repo's paths, read-only.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path

import h5py
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import LightSource

PAPER = Path("/home/jake/papers/moderate_crustal_topographic_effects")
DEM50 = Path("/var/tmp/copernicus/nz_dem_50m.tif")  # Copernicus GLO-30 at 50 m, NZTM
HIGHWAYS = PAPER / "data" / "raw" / "osm_state_highways" / "overpass.json"

# (label, file slug, ridge, reference). The reference is a station name, or a
# NeutralRefs rule that selects every qualifying station.
D_HILL = 1250.0  # m, diameter of the H_d averaging disk (Tiwari et al. Hill model)


@dataclass(frozen=True)
class NeutralRefs:
    radius: float  # m
    dvs30: float  # m/s
    max_h: tuple = ((1250.0, 10.0), (2500.0, 20.0), (5000.0, 30.0))  # (D, |H_D| limit), m


PAIRS = [
    ("Otira Viaduct", "otira", "fKtoMWL", "fKtnOWL"),
    ("Sugarloaf, Port Hills", "sugarloaf", "dwd0ICA", NeutralRefs(radius=10_000.0, dvs30=200.0)),
]
F_DET = 1.0  # Hz, LF/HF merge; shorter periods are the stochastic HF's, not drawn

plt.rcParams.update(
    {
        "font.family": "serif",
        "font.size": 13,
        "axes.linewidth": 0.8,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "xtick.major.width": 0.8,
        "ytick.major.width": 0.8,
        "xtick.color": "#52514e",
        "ytick.color": "#52514e",
        "axes.labelcolor": "#2b2b2b",
        "legend.frameon": False,
        "savefig.bbox": "tight",
    }
)

# Paper colours (style.py): T is black, the ridge the difference ink.
T_COLOUR = "black"
RIDGE_COLOUR = "#3b3b6b"
REF_COLOUR = "#8a8a8a"
ROAD_COLOUR = "#e8a33d"


def to_nztm(lon, lat):
    from pyproj import Transformer

    tr = Transformer.from_crs(4326, 2193, always_xy=True)
    return tr.transform(np.asarray(lon, float), np.asarray(lat, float))


def load_psa(path: Path, sites: list[str]) -> dict:
    """pSA RotD50 (g) per site, periods, and site metadata from intensity_measures.h5."""
    with h5py.File(path, "r") as f:
        g = f["pSA"]
        names = g["station"][:].astype(str)
        idx = {s: int(np.flatnonzero(names == s)[0]) for s in sites}
        rows = sorted(idx.values())
        pos = {r: k for k, r in enumerate(rows)}
        psa = g["rotd50"][rows, :]
        meta = {k: g[k][rows] for k in ("latitude", "longitude", "vs30", "supergrid_depth_gp", "rrup")}
        period = g["period"][:]
    out = {"period": period}
    for s, r in idx.items():
        out[s] = {"psa": psa[pos[r]], **{k: float(v[pos[r]]) for k, v in meta.items()}}
    return out


def select_references(path: Path, target: str, rule: NeutralRefs) -> list[str]:
    """Stations that satisfy `rule` around `target`, nearest first."""
    with h5py.File(path, "r") as f:
        g = f["pSA"]
        names = g["station"][:].astype(str)
        lat, lon = g["latitude"][:], g["longitude"][:]
        vs30, sg = g["vs30"][:], g["supergrid_depth_gp"][:]
    x, y = to_nztm(lon, lat)
    t = int(np.flatnonzero(names == target)[0])
    d = np.hypot(x - x[t], y - y[t])
    cand = np.flatnonzero((d <= rule.radius) & (sg == 0) & (np.abs(vs30 - vs30[t]) <= rule.dvs30))
    refs = [i for i in cand[np.argsort(d[cand])] if i != t
            and all(abs(relative_elevation(x[i], y[i], dh)[0]) <= lim for dh, lim in rule.max_h)]
    return [str(names[i]) for i in refs]


def relative_elevation(x: float, y: float, d: float = D_HILL) -> tuple[float, float]:
    """H_d and DEM elevation at one NZTM point, as terrain.relative_elevation does it:
    bilinear site elevation minus the mean over land pixel centres within d/2 of the
    site's nearest pixel centre (sea, DEM == 0, excluded)."""
    import rasterio
    from rasterio.windows import Window

    with rasterio.open(DEM50) as src:
        res = src.res[0]
        r_px = d / 2 / res
        n = int(np.ceil(r_px)) + 2
        col_f, row_f = ~src.transform * (x, y)
        rc, cc = int(np.floor(row_f)), int(np.floor(col_f))
        win = src.read(1, window=Window(cc - n, rc - n, 2 * n + 1, 2 * n + 1), boundless=True,
                       fill_value=0).astype(float)
    fr, fc = row_f - 0.5 - (rc - n), col_f - 0.5 - (cc - n)
    i0, j0 = int(np.floor(fr)), int(np.floor(fc))
    wr, wc = fr - i0, fc - j0
    z = (win[i0, j0] * (1 - wr) * (1 - wc) + win[i0 + 1, j0] * wr * (1 - wc)
         + win[i0, j0 + 1] * (1 - wr) * wc + win[i0 + 1, j0 + 1] * wr * wc)
    dr, dc = np.mgrid[-n : n + 1, -n : n + 1]
    disk = (np.hypot(dr, dc) <= r_px + 1e-9) & np.isfinite(win) & (win != 0)
    return float(z - win[disk].mean()), float(z)


def hillshade(ax, x0, x1, y0, y1) -> None:
    import rasterio
    from rasterio.windows import from_bounds

    with rasterio.open(DEM50) as src:
        win = from_bounds(x0, y0, x1, y1, src.transform)
        z = src.read(1, window=win, boundless=True, fill_value=0).astype(float)
    hs = LightSource(azdeg=315, altdeg=40).hillshade(z, vert_exag=1.5, dx=50, dy=50)
    rgb = plt.get_cmap("Greys_r")(np.clip((hs + 0.2) / 1.35, 0, 1))
    rgb[z <= 0] = (1, 1, 1, 1)  # sea
    ax.imshow(rgb, extent=(x0, x1, y0, y1), origin="upper", interpolation="bilinear")
    ax.contour(np.linspace(x0, x1, z.shape[1]), np.linspace(y1, y0, z.shape[0]), z,
               levels=np.arange(0, 4000, 250), colors="#6f6f6f", linewidths=0.35)


def highways(ax) -> None:
    """OSM state highways (paper extract); tunnels and shelters dashed."""
    if not HIGHWAYS.exists():
        print(f"no {HIGHWAYS}; skipping highways")
        return
    x0, x1 = ax.get_xlim()
    y0, y1 = ax.get_ylim()
    refs = set()
    for w in json.loads(HIGHWAYS.read_text())["elements"]:
        x, y = to_nztm([g["lon"] for g in w["geometry"]], [g["lat"] for g in w["geometry"]])
        if w["tags"].get("tunnel", "no") != "no":
            ax.plot(x, y, color="black", lw=1.2, ls=(0, (2, 1.5)), zorder=3)
        else:
            ax.plot(x, y, color="black", lw=2.6, solid_capstyle="round", zorder=3)
            ax.plot(x, y, color=ROAD_COLOUR, lw=1.6, solid_capstyle="round", zorder=3.1)
        if np.any((x > x0) & (x < x1) & (y > y0) & (y < y1)):
            refs.update(r.replace(" ", "") for r in w["tags"]["ref"].split(";") if r.startswith("SH"))
    if refs:
        ax.plot([], [], color=ROAD_COLOUR, lw=2, label=", ".join(sorted(refs, key=lambda r: (len(r), r))))
        ax.legend(loc="upper right", fontsize=17, handlelength=1.2, markerscale=0.7, frameon=True, framealpha=0.85,
                  borderpad=0.3, edgecolor="none")


def scale_bar(ax, km: float = 2, loc=(0.07, 0.07)) -> None:
    x0, x1 = ax.get_xlim()
    y0, y1 = ax.get_ylim()
    x, y = x0 + loc[0] * (x1 - x0), y0 + loc[1] * (y1 - y0)
    ax.plot([x, x + km * 1e3], [y, y], color="black", lw=3.5, solid_capstyle="butt", zorder=5)
    ax.text(x + km * 5e2, y + 0.015 * (y1 - y0), f"{km:g} km", ha="center", va="bottom", fontsize=17, zorder=5)


def m(v: float) -> str:
    return f"{round(v) + 0:.0f}".replace("-", "−")


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--data", type=Path, default=Path("/var/tmp/marlborough_1848"))
    ap.add_argument("--arm", default="prefilter")
    ap.add_argument("--out-dir", type=Path, default=Path("out/png"))
    ap.add_argument("--dpi", type=int, default=300)
    args = ap.parse_args()

    im_path = args.data / args.arm / "intensity_measures.h5"
    refs = {slug: select_references(im_path, ridge, ref) if isinstance(ref, NeutralRefs) else [ref]
            for _, slug, ridge, ref in PAIRS}
    sites = sorted({s for _, slug, ridge, _ in PAIRS for s in (ridge, *refs[slug])})
    ims = load_psa(im_path, sites)
    period = ims["period"]
    keep = (period >= 1 / F_DET) & (period <= 10)
    args.out_dir.mkdir(parents=True, exist_ok=True)

    # The slide lays each pair out as photo + map over a wide ratio plot, so
    # every panel is its own PNG and Typst does the composition. The ratio
    # plots share a y range so the two pairs read against each other.
    # ratios[slug] = (geometric mean, P16, P84) over the references; for a
    # single reference all three are the one ratio.
    ratios = {}
    for label, slug, ridge, _ in PAIRS:
        r, qs = ims[ridge], [ims[q] for q in refs[slug]]
        assert qs, f"{label}: no reference satisfies the rule"
        for s in (r, *qs):
            assert s["supergrid_depth_gp"] == 0, "pair site inside the supergrid"
            s["x"], s["y"] = to_nztm(s["longitude"], s["latitude"])
            s["h"], s["z"] = relative_elevation(s["x"], s["y"])
        dist = np.array([np.hypot(r["x"] - q["x"], r["y"] - q["y"]) for q in qs])
        ln = np.log(r["psa"]) - np.log([q["psa"] for q in qs])
        ratios[slug] = tuple(np.exp(v) for v in (ln.mean(0), *np.percentile(ln, [16, 84], axis=0)))
        print(f"{label}: ridge {ridge} ({r['latitude']:.4f}, {r['longitude']:.4f}) "
              f"H1250 {r['h']:.1f} m, z {r['z']:.0f} m, Vs30 {r['vs30']:.0f}; Rrup {r['rrup']:.0f} km; "
              f"{len(qs)} reference(s), {dist.min() / 1e3:.2f}-{dist.max() / 1e3:.2f} km away")
        for name, q in zip(refs[slug], qs):
            print(f"    ref {name} ({q['latitude']:.4f}, {q['longitude']:.4f}) H1250 {q['h']:.1f} m, "
                  f"z {q['z']:.0f} m, Vs30 {q['vs30']:.0f}")
        for t in (1, 2, 3, 5, 7.5, 10):
            k = int(np.argmin(np.abs(period - t)))
            gm, lo, hi = (a[k] for a in ratios[slug])
            print(f"    T = {period[k]:g} s: ridge/ref {gm:.3f} (P16-P84 {lo:.3f}-{hi:.3f})")

        # Map: centred on the pair, or on the target when the references
        # surround it.
        fig, axm = plt.subplots(figsize=(4.2, 4.2), constrained_layout=True)
        if len(qs) == 1:
            cx, cy = (r["x"] + qs[0]["x"]) / 2, (r["y"] + qs[0]["y"]) / 2
            half = max(3500.0, 0.5 * dist[0] + 2500)
        else:
            cx, cy = r["x"], r["y"]
            half = dist.max() + 1500
        hillshade(axm, cx - half, cx + half, cy - half, cy + half)
        axm.plot([q["x"] for q in qs], [q["y"] for q in qs], "o", ms=17 if len(qs) == 1 else 10,
                 mfc=REF_COLOUR, mec="white", mew=1.6 if len(qs) == 1 else 1.0, zorder=6, label="reference")
        axm.plot(r["x"], r["y"], "^", ms=20, mfc=RIDGE_COLOUR, mec="white", mew=1.6, zorder=7,
                 label="ridge")
        axm.set_xlim(cx - half, cx + half)
        axm.set_ylim(cy - half, cy + half)
        axm.set_aspect("equal")
        highways(axm)
        axm.set_xticks([])
        axm.set_yticks([])
        for sp in axm.spines.values():
            sp.set_visible(True)
            sp.set_linewidth(0.6)
            sp.set_color("#8a8a8a")
        scale_bar(axm, km=2 if half < 6000 else 5)
        # Separation, H_1250 and Vs30 go in the slide text: at the size the
        # map is shown, a caption drawn here would be unreadable.
        out = args.out_dir / f"marlborough-topo-{slug}-map.png"
        fig.savefig(out, dpi=args.dpi)
        plt.close(fig)
        print(f"wrote {out}")

    hi = max(ratios[slug][2][keep].max() for slug in ratios) * 1.05
    lo = min(0.9, min(ratios[slug][1][keep].min() for slug in ratios))
    for label, slug, _, _ in PAIRS:
        gm, p16, p84 = ratios[slug]
        fig, axr = plt.subplots(figsize=(6.4, 3.3), constrained_layout=True)
        axr.axhline(1, color="#8a8a8a", lw=1.0, zorder=1)
        if len(refs[slug]) > 1:
            axr.fill_between(period[keep], p16[keep], p84[keep], color=RIDGE_COLOUR, alpha=0.18, lw=0, zorder=2)
        axr.plot(period[keep], gm[keep], "-", color=T_COLOUR, lw=2.8, zorder=3)
        axr.set_xscale("log")
        ticks = [1, 2, 3, 5, 10]
        axr.set_xticks(ticks, [f"{t:g}" for t in ticks])
        axr.minorticks_off()
        axr.set_xlim(0.95, 10.5)
        axr.set_ylim(lo, hi)
        axr.set_ylabel("pSA ridge / reference", fontsize=15)
        axr.set_xlabel("Period, $T$ (s)", fontsize=15)
        axr.tick_params(labelsize=14)
        out = args.out_dir / f"marlborough-topo-{slug}-ratio.png"
        fig.savefig(out, dpi=args.dpi)
        plt.close(fig)
        print(f"wrote {out}")


if __name__ == "__main__":
    main()
