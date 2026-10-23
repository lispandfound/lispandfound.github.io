# /// script
# requires-python = ">=3.12"
# dependencies = ["duckdb", "matplotlib", "numpy"]
# ///
"""The payoff figure: the supergrid defect, recovered by one query.

Four of the SW4 runs in the 24-08 validation set placed the seismic source
inside the supergrid absorbing layer, where SW4 solves a deliberately modified
wave equation. The symptom is long-period energy that never decays, so the
statistic that exposes it is the per-station log ratio pSA(20 s) / pSA(1 s),
taken as SW4's median excess over EMOD3D for the same event.

The bars are computed here, at build time, from the composite database rather
than pasted in -- so the slide cannot drift from the data, and so the timing
printed on it is a timing of the query that actually produced it.
"""

import argparse
import time
from pathlib import Path

import duckdb
import matplotlib as mpl
import matplotlib.pyplot as plt

DB = Path.home() / "src/eqvis_workflow/ims.duckdb"

# The whole analysis. It is on the slide verbatim, so it is written to be read
# by someone who does not write SQL: one row per station per solver, then the
# difference of the two medians.
QUERY = """
WITH ratio AS (
  SELECT r.event, l.value AS solver, p.station,
         ln(max(p.pSA) FILTER (p.period = 20.0))
       - ln(max(p.pSA) FILTER (p.period =  1.0)) AS lr
  FROM psa p
  JOIN runs r       ON r.run_id = p.run_id
  JOIN run_labels l ON l.run_id = r.run_id AND l.name = 'solver'
  WHERE p.period IN (1.0, 20.0) AND p.component = 'geom'
  GROUP BY 1, 2, 3
)
SELECT event,
       median(lr) FILTER (solver = 'sw4')
     - median(lr) FILTER (solver = 'emod3d') AS excess
FROM ratio
GROUP BY 1
HAVING excess IS NOT NULL
ORDER BY excess DESC
"""

# The events whose source sits within a supergrid width of the domain edge.
# From the migration audit in ~/src/simulation_validation: these four are the
# offshore ones, where nothing on the seaward side forced the domain wider than
# the 2 km fault buffer.
AFFECTED = {"2018p829286", "2016p661400", "2014p933337", "3125077"}

DEFECT = "#b3242b"
QUIET = "#8a8f92"
EXACT = "#23373b"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--dpi", type=int, default=600)
    ap.add_argument("--db", type=Path, default=DB)
    args = ap.parse_args()

    con = duckdb.connect(str(args.db), read_only=True)
    start = time.perf_counter()
    rows = con.sql(QUERY).fetchall()
    elapsed = time.perf_counter() - start
    n_psa = con.sql("SELECT count(*) FROM psa").fetchone()[0]

    events = [e for e, _ in rows]
    excess = [x for _, x in rows]
    colours = [DEFECT if e in AFFECTED else QUIET for e in events]

    mpl.rcParams.update({
        "font.family": "sans-serif",
        "font.sans-serif": ["DejaVu Sans"],
        "font.size": 11,
        "axes.edgecolor": EXACT,
        "axes.labelcolor": EXACT,
        "text.color": EXACT,
        "xtick.color": EXACT,
        "ytick.color": EXACT,
    })

    fig, ax = plt.subplots(figsize=(7.2, 3.6), constrained_layout=True)
    y = range(len(events))
    ax.barh(list(y), excess, color=colours, height=0.72)
    ax.set_yticks(list(y), events, fontsize=9)
    ax.invert_yaxis()
    ax.axvline(0, color=EXACT, lw=0.8)
    ax.set_xlabel("SW4 excess long-period energy   (median $\\ln$ pSA$_{20s}$/pSA$_{1s}$)")

    for spine in ("top", "right"):
        ax.spines[spine].set_visible(False)
    ax.spines["left"].set_visible(False)
    ax.tick_params(axis="y", length=0)
    ax.grid(axis="x", color=QUIET, alpha=0.25, lw=0.6)
    ax.set_axisbelow(True)

    # The finding: the top four are exactly the four offshore events, and
    # nothing about the query knew that. Colour alone carries the grouping --
    # a bracket in the margin collides with the event labels, and the callout
    # already says "the four" -- and the callout sits in the clear space to the
    # right of the short bars rather than on top of the long ones.
    n_bad = sum(e in AFFECTED for e in events)
    ax.annotate(
        "the four events whose source\nsat inside the absorbing layer",
        xy=(max(excess) * 0.53, n_bad - 1.35),
        color=DEFECT,
        fontsize=10,
        fontweight="bold",
        ha="left",
        va="center",
        linespacing=1.35,
    )

    ax.set_title(
        f"{n_psa / 1e6:.0f} million spectral values  ·  one query  ·  {elapsed:.2f} s",
        fontsize=10,
        color=QUIET,
        loc="left",
        pad=8,
    )

    args.out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.out, dpi=args.dpi, transparent=True)
    print(f"{args.out}  ({elapsed:.3f}s query, {len(events)} events)")


if __name__ == "__main__":
    main()
