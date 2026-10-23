# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib", "cartopy", "shapely"]
# ///
"""Who else has this problem: national hazard models with non-characteristic ruptures.

New Zealand (NSHM 2022) and the United States (UCERF3 for California, and the
NSHM23 national model that carried its inversion across the western US) both moved from a short list of
characteristic ruptures to a fault-system inversion over hundreds of thousands
of multi-fault ruptures. Simulating either catalogue runs into the same
selection problem, so the map is the slide's one argument: this is not a New
Zealand quirk.

A Pacific-centred Robinson projection, so both countries sit on one map without
the date line cutting New Zealand off from the United States.

Country outlines are Natural Earth 1:110m admin-0 (public domain), read from a
local GeoJSON:

    curl -sL -o /var/tmp/naturalearth/ne_110m_admin_0_countries.geojson \\
        https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_110m_admin_0_countries.geojson
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import cartopy.crs as ccrs
import matplotlib.pyplot as plt
from shapely.geometry import shape

# Deck palette (palette.typ): `stat` is what the talk is about, `quiet` the rest.
HIGHLIGHT = "#eb811b"
LAND = "#e3e4e5"
EDGE = "#ffffff"
INK = "#23373b"

# (ADM0_A3, label, anchor lon/lat for the label, alignment)
MODELS = [
    ("NZL", "New Zealand\nNSHM 2022", (-178.0, -38.0), "left"),
    ("USA", "United States\nUCERF3 / NSHM23", (-128.0, 30.0), "right"),
]


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--countries", type=Path,
                    default=Path("/var/tmp/naturalearth/ne_110m_admin_0_countries.geojson"))
    ap.add_argument("--out", type=Path, default=Path("out/png/world-map.png"))
    ap.add_argument("--dpi", type=int, default=300)
    args = ap.parse_args()

    features = json.loads(args.countries.read_text())["features"]
    highlighted = {code for code, *_ in MODELS}

    projection = ccrs.Robinson(central_longitude=-170)
    fig = plt.figure(figsize=(12, 5.6))
    ax = fig.add_subplot(projection=projection)
    ax.set_global()
    ax.spines["geo"].set_visible(False)
    for feature in features:
        code = feature["properties"]["ADM0_A3"]
        if code == "ATA":  # Antarctica: a third of the map for nothing
            continue
        ax.add_geometries([shape(feature["geometry"])], ccrs.PlateCarree(),
                          facecolor=HIGHLIGHT if code in highlighted else LAND,
                          edgecolor=EDGE, linewidth=0.4)
    ax.set_extent((-260, -20, -52, 75), ccrs.PlateCarree())

    for _, label, (lon, lat), ha in MODELS:
        name, model = label.split("\n")
        # Name above the anchor, model below it, both against the open ocean.
        ax.text(lon, lat, name, transform=ccrs.PlateCarree(), ha=ha, va="bottom",
                fontsize=17, color=INK, fontfamily="serif")
        ax.text(lon, lat, model, transform=ccrs.PlateCarree(), ha=ha, va="top",
                fontsize=17, color=HIGHLIGHT, fontweight="bold", fontfamily="serif")

    args.out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.out, dpi=args.dpi, bbox_inches="tight", pad_inches=0.02)
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
