# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib", "numpy", "geopandas", "pyarrow"]
# ///
"""How much of a site's hazard you cover, ranked by each rupture-selection rule.

The argument of the slide. Bias in this estimator is exactly the summed hazard of
the ruptures you never simulated -- `bias = hazard[:, ~sampled].sum(axis=1)` in
report/make_efficiency_figure.py:704 -- so "fraction of hazard covered" IS the
complement of the bias term, not a proxy for it. The gap between a curve and
100% is the bias you are left with.

Four orderings, and the point is how far apart they are:

  magnitude   the New Zealand Cybershake rule, N(Mw) = 27 Mw - 148
  area        the SCEC Cybershake rule, A/16 hypocentres
  rate        a Poisson-catalogue ordering
  GMM hazard  rank by the empirical ground-motion model's own estimate of what
              each rupture contributes to exceedance at this site

Magnitude and area are drawn as ONE curve because they are one rule: area is a
deterministic function of magnitude under the scaling relation, and the two rank
the catalogue identically (Spearman rho = 1.0000, checked, not assumed).

The load-bearing assumption, which belongs on the slide and not buried here: the
empirical model is not the simulator. Simulations exist because they add basin
response, topography and directivity that a GMM does not have. The claim is only
that the two agree in AGGREGATE across many sites and ruptures -- enough to rank
ruptures by importance, not enough to replace simulating them.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import geopandas as gpd
import matplotlib.pyplot as plt
import numpy as np

plt.rcParams.update(
    {
        "font.family": "serif",
        "font.size": 8,
        "axes.linewidth": 0.6,
        "xtick.major.width": 0.6,
        "ytick.major.width": 0.6,
        "xtick.color": "#78776f",
        "ytick.color": "#78776f",
        "axes.labelcolor": "#52514e",
        "axes.edgecolor": "#e6e5e1",
        "legend.frameon": False,
        "savefig.bbox": "tight",
    }
)

# Categorical slots from report/make_efficiency_figure.py, so a colour means the
# same thing here as it does in the efficiency figure.
MW_AREA = "#2a78d6"
RATE = "#1baf7a"
GMM = "#eb6834"
MUTED = "#a8a7a1"
TEXT = "#0b0b0b"

SITES = ("CBGS", "APPS", "NELS")
SITE_NAMES = {"CBGS": "Christchurch", "APPS": "Arthur's Pass", "NELS": "Nelson"}
TARGET_RATE = 1.0 / 475.0  # 10% in 50 years


def coverage(contribution: np.ndarray, key: np.ndarray) -> np.ndarray:
    """Cumulative share of hazard when ruptures are taken in ``key`` order."""
    order = np.argsort(key)[::-1]
    return np.cumsum(contribution[order]) / contribution.sum() * 100.0


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--repo",
        type=Path,
        default=Path.home() / "src" / "monte_carlo_hazard_estimation_code",
    )
    ap.add_argument("--out", type=Path, default=Path("out/png/hazard-coverage.png"))
    ap.add_argument("--budget", type=int, default=500, help="ruptures marked on the axis")
    ap.add_argument("--dpi", type=int, default=600)
    args = ap.parse_args()

    slice_ = np.load(args.repo / "report" / "figures" / "site_slice.npz")
    haz = slice_["hazard"]  # (threshold, rupture, site)
    mag, rate, rup = slice_["mag"], slice_["rate"], slice_["rupture"]
    ruptures = gpd.read_parquet(args.repo / "data" / "ruptures.parquet")
    area = ruptures.xs(3, level="fault_system")["area"].reindex(rup).to_numpy()

    n_rup = haz.shape[1]
    fig, axes = plt.subplots(1, 3, figsize=(11.0, 4.15), sharey=True, constrained_layout=True)

    for s, (ax, code) in enumerate(zip(axes, SITES)):
        total = haz[:, :, s].sum(axis=1) + slice_["subduction"][:, s] + slice_["distributed"][:, s]
        idx = int(np.argmin(np.abs(total - TARGET_RATE)))
        contribution = haz[idx, :, s]

        n = np.arange(1, n_rup + 1)
        # Random order is the no-information floor: in expectation you capture
        # hazard in proportion to how many ruptures you ran.
        ax.plot(n, n / n_rup * 100, lw=0.7, ls=(0, (1, 2)), color=MUTED, zorder=1)

        for key, colour, label in (
            (mag, MW_AREA, "magnitude  =  area"),
            (rate, RATE, "rate"),
            (contribution, GMM, "GMM hazard"),
        ):
            ax.plot(n, coverage(contribution, key), lw=1.5, color=colour, label=label, zorder=3)

        ax.axvline(args.budget, lw=0.7, color=TEXT, ls=(0, (4, 3)), zorder=2)
        ax.set_xscale("log")
        ax.set_xlim(10, n_rup)
        ax.set_ylim(0, 100)
        ax.set_title(
            f"{code} — {SITE_NAMES[code]}", loc="left", fontweight="bold", fontsize=8.5, pad=3
        )
        ax.set_xlabel("ruptures simulated")
        for side in ("top", "right"):
            ax.spines[side].set_visible(False)
        ax.grid(axis="y", lw=0.5, color="#e6e5e1", zorder=0)
        ax.set_axisbelow(True)

        # The three numbers the slide is actually about.
        for key, colour in ((mag, MW_AREA), (rate, RATE), (contribution, GMM)):
            v = coverage(contribution, key)[args.budget - 1]
            ax.plot([args.budget], [v], "o", ms=3.4, color=colour, zorder=4)
            # A light plate, because where two curves run close the label would
            # otherwise sit on top of one of them.
            ax.annotate(
                f"{v:.0f}%",
                (args.budget, v),
                textcoords="offset points",
                xytext=(6, -1),
                fontsize=8,
                fontweight="bold",
                color=colour,
                bbox=dict(boxstyle="square,pad=0.15", fc="white", ec="none", alpha=0.85),
                zorder=5,
            )

        # The complement of the covered fraction is the bias, so name it once.
        if s == 0:
            top = coverage(contribution, mag)[args.budget - 1]
            ax.annotate(
                "",
                xy=(args.budget * 1.65, 100),
                xytext=(args.budget * 1.65, top),
                arrowprops=dict(arrowstyle="<->", lw=0.7, color=TEXT),
            )
            ax.text(
                args.budget * 1.9,
                (100 + top) / 2,
                "unsimulated\nhazard = bias",
                fontsize=7.5,
                color=TEXT,
                va="center",
                bbox=dict(boxstyle="square,pad=0.2", fc="white", ec="none", alpha=0.85),
                zorder=5,
            )

    axes[0].set_ylabel("hazard covered")
    axes[0].set_yticks([0, 25, 50, 75, 100])
    axes[0].set_yticklabels(["0", "25%", "50%", "75%", "100%"])
    axes[1].annotate(
        f"{args.budget} ruptures",
        (args.budget, 3),
        textcoords="offset points",
        xytext=(4, 0),
        fontsize=7.5,
        color=TEXT,
    )
    handles, labels = axes[0].get_legend_handles_labels()
    fig.legend(handles, labels, loc="outside lower center", ncol=3, fontsize=8.5)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.out, dpi=args.dpi)
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
