"""Where New Zealand's tomography models overlap, for the "competing tomography
models" slide.

Renders figures/tomography_coverage.png.

- The national models (EP2010, EP2020, EP2025) are all defined on the same
  165-180 E, 48-33 S grid, so they are drawn as one background over the whole
  country.
- The Chow et al. (2020) North Island adjoint model is drawn from the data: its
  footprint is every cell where ~/src/nzcvm_data's CHOW2020_EP2020_MIX differs
  from EP2020 at 8 km depth.
- Bassett et al. (2025), the Hikurangi margin model, is not in nzcvm_data yet
  (its README says "in progress"), so its outline is APPROXIMATE: a hand-drawn
  polygon over the margin from Cook Strait to East Cape, dashed and labelled as
  such.

The coastline is the NZ outline eqvis_workflow caches at
~/.cache/eqvis/coastline_nz.b64 (base64 of gzip'd WKB).

Run:  uv run --with matplotlib --with numpy --with shapely --with h5py \\
          python scripts/tomography_coverage.py
"""

import base64
import gzip
from pathlib import Path

import h5py
import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import numpy as np
import shapely

EXACT, STAT, PERF, QUIET = "#23373b", "#eb811b", "#1f6f5c", "#8a8f92"
FS = 3.2

plt.rcParams.update(
    {
        "font.family": "serif",
        "font.serif": ["Libertinus Serif", "DejaVu Serif"],
        "font.size": 8 * FS,
        "savefig.dpi": 300,
    }
)

TOMO = Path.home() / "src/nzcvm_data/tomography"
COAST = Path.home() / ".cache/eqvis/coastline_nz.b64"
VIEW = (166.0, 180.6, -47.4, -34.2)  # west, east, south, north

coast = shapely.from_wkb(gzip.decompress(base64.b64decode(COAST.read_text())))

# Chow 2020 footprint: where the mix departs from EP2020.
with h5py.File(TOMO / "EP2020/ep2020.h5") as ep, h5py.File(
    TOMO / "CHOW2020_EP2020_MIX/chow2020_ep2020_mix.h5"
) as mix:
    lat = ep["-8/latitudes"][()]
    lon = ep["-8/longitudes"][()]
    chow = np.abs(mix["-8/vs"][()] - ep["-8/vs"][()]) > 1e-3

# Approximate Hikurangi margin outline (see module docstring).
bassett = np.array(
    [
        (174.6, -41.9),
        (176.6, -42.6),
        (179.6, -39.4),
        (179.4, -37.2),
        (178.2, -37.0),
        (176.2, -39.6),
        (174.6, -41.9),
    ]
)

fig, ax = plt.subplots(figsize=(6.2, 6.8), layout="constrained")
# National background: every land polygon, filled.
for poly in shapely.get_parts(coast):
    if poly.geom_type != "Polygon" or poly.area < 1e-3:
        continue
    x, y = poly.exterior.xy
    ax.fill(x, y, fc="#dde3e4", ec=EXACT, lw=0.8, zorder=1)

# The mix equals EP2020 at scattered cells inside the Chow domain too, so draw
# the domain as the hull of every differing cell rather than the raw mask.
la, lo = np.nonzero(chow)
hull = shapely.MultiPoint(np.column_stack([lon[lo], lat[la]])).convex_hull
ax.fill(*hull.exterior.xy, fc=STAT, alpha=0.35, ec=STAT, lw=2.0, zorder=2)
ax.plot(*bassett.T, color=PERF, lw=2.4, ls=(0, (5, 3)), zorder=4)

kw = dict(fontsize=8 * FS, zorder=5)
ax.text(168.6, -40.4, "EP2010,\nEP2020,\nEP2025:\nnational", color=EXACT, ha="center", **kw)
ax.text(172.8, -36.4, "Chow\n2020", color=STAT, ha="right", weight="bold", **kw)
ax.text(178.2, -43.0, "Bassett\n2025", color=PERF, ha="center", va="top", weight="bold", **kw)

ax.set_xlim(VIEW[0], VIEW[1])
ax.set_ylim(VIEW[2], VIEW[3])
ax.set_aspect(1 / np.cos(np.radians(-40.8)))
ax.set_axis_off()

fig.savefig("figures/tomography_coverage.png", bbox_inches="tight", facecolor="white")
print("wrote figures/tomography_coverage.png")
