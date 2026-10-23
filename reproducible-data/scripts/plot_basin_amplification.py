# /// script
# requires-python = ">=3.12"
# dependencies = ["duckdb", "matplotlib"]
# ///
"""Basin amplification across the whole Cybershake pilot, from one query.

For every site inside a named sedimentary basin, how much larger is the peak
ground velocity than at rock sites the same distance from the same rupture?
The distance banding is what makes it an answer rather than an artefact: basins
are where people live, people live on flat ground near faults, and a raw
basin-versus-rock comparison would mostly measure that.

This is the slide's argument in one number: 8.3 million site-values, 293
ruptures, 21 basins, distance-controlled, in about two seconds. Assembled by
hand from per-run CSVs it is an afternoon of scripting, and nobody does it for
293 runs, which is why the answer did not exist before the database did.
"""

import argparse
import time
from pathlib import Path

import duckdb
import matplotlib as mpl
import matplotlib.pyplot as plt

DB = Path.home() / "tmp/ims.duckdb"

# `rotd50` because it is the orientation-independent component an engineer would
# quote. The rrup floor of 5 km keeps the near-source band from being a single
# site, and log2 half-steps give bands that are narrow where the attenuation is
# steep and wide where it is flat.
QUERY = """
WITH site AS (
  SELECT s.run_id, st.basin,
         floor(log2(GREATEST(rs.rrup, 5)) * 2) / 2 AS dist_band,
         ln(s.PGV) AS lnpgv
  FROM scalars s
  JOIN run_stations rs ON rs.run_id = s.run_id AND rs.station = s.station
  JOIN stations st     ON st.station = s.station
  WHERE s.component = 'rotd50' AND s.PGV > 0
),
band AS (
  SELECT run_id, dist_band, median(lnpgv) FILTER (basin IS NULL) AS rock
  FROM site GROUP BY 1, 2
)
SELECT si.basin,
       count(DISTINCT si.run_id)          AS ruptures,
       count(*)                           AS site_values,
       exp(median(si.lnpgv - b.rock))     AS amplification
FROM site si JOIN band b USING (run_id, dist_band)
WHERE si.basin IS NOT NULL AND b.rock IS NOT NULL
GROUP BY 1 HAVING count(*) > 100000
ORDER BY amplification DESC
"""

STAT = "#eb811b"
EXACT = "#23373b"
QUIET = "#8a8f92"
PERF = "#1f6f5c"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--dpi", type=int, default=300)
    ap.add_argument("--db", type=Path, default=DB)
    ap.add_argument("--top", type=int, default=12)
    args = ap.parse_args()

    con = duckdb.connect(str(args.db), read_only=True)
    start = time.perf_counter()
    rows = con.sql(QUERY).fetchall()
    elapsed = time.perf_counter() - start

    total_values = sum(r[2] for r in rows)
    n_basins = len(rows)
    rows = rows[: args.top]
    names = [r[0] for r in rows]
    amp = [r[3] for r in rows]

    mpl.rcParams.update({
        "font.family": "sans-serif",
        "font.sans-serif": ["DejaVu Sans"],
        "font.size": 11,
        "axes.edgecolor": EXACT,
        "text.color": EXACT,
        "xtick.color": EXACT,
        "ytick.color": EXACT,
    })

    fig, ax = plt.subplots(figsize=(7.4, 4.0), constrained_layout=True)
    y = range(len(names))
    ax.barh(list(y), amp, color=STAT, height=0.72)
    ax.set_yticks(list(y), names, fontsize=10)
    ax.invert_yaxis()

    for i, v in enumerate(amp):
        ax.text(v + 0.03, i, f"{v:.2f}×", va="center", fontsize=10, color=EXACT)

    # No amplification is 1.0, not 0, so the bars are read against that line and
    # the axis starts there.
    ax.axvline(1.0, color=EXACT, lw=1.0)
    ax.set_xlim(1.0, max(amp) * 1.12)
    ax.set_xlabel("PGV, relative to rock at the same rupture distance")

    for spine in ("top", "right", "left"):
        ax.spines[spine].set_visible(False)
    ax.tick_params(axis="y", length=0)
    ax.grid(axis="x", color=QUIET, alpha=0.25, lw=0.6)
    ax.set_axisbelow(True)

    ax.set_title(
        f"{n_basins} basins  ·  293 ruptures  ·  "
        f"{total_values / 1e6:.1f} million site values  ·  {elapsed:.1f} s",
        fontsize=10,
        color=QUIET,
        loc="left",
        pad=8,
    )

    args.out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.out, dpi=args.dpi, transparent=True)
    print(f"{args.out}  ({elapsed:.2f}s, {n_basins} basins, {total_values:,} values)")


if __name__ == "__main__":
    main()
