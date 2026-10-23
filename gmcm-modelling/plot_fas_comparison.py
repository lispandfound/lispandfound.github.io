"""FAS from the 1 Hz and 2 Hz runs, in the eqvis_workflow figure vocabulary.

Run with the eqvis environment:

    uv run --project ~/src/eqvis_workflow python plot_fas_comparison.py

Writes two figures:

- ``figures/fas_TEPS_POTS.png``: EAS at TEPS and POTS from both runs, and the log
  ratio between them, laid out like ``eqvis spectra --diff``.
- ``figures/fas_band_map.png``: the band-averaged (``BAND``) ln[EAS(2 Hz) / EAS(1 Hz)]
  at every station, laid out like ``eqvis map --diff``, with a Wellington zoom.

Both keep the eqvis colours and layout, but every text size is multiplied by FS
so the figures stay readable on a projector at the size the deck shows them.
"""

import matplotlib.patheffects as patheffects
import matplotlib.pyplot as plt
import numpy as np
import shapely
import xarray as xr
from matplotlib.colors import BoundaryNorm
from matplotlib.ticker import FuncFormatter

from eqvis_workflow.constants import COMPARISON_BLUE
from eqvis_workflow.data import open_ims
from eqvis_workflow.geography import (
    basins_in_view,
    draw_basins,
    draw_geometry,
    fill_land,
    load_basins,
    load_coastline,
)
from eqvis_workflow.raster import symmetric_norm, label_ratios

RUNS = {"1 Hz": "intensity_measures_1Hz.h5", "2 Hz": "intensity_measures_2Hz.h5"}
STATIONS = ("TEPS", "POTS")
BAND = (1.0, 1.5)
# Hybrid LF/HF crossover of each run.
TRANSITIONS = (1.0, 2.0)
WELLINGTON = (174.70, -41.36, 175.00, -41.10)  # west, south, east, north
DPI = 300
# Text scale for the slides: eqvis sizes are for a figure read at arm's length.
FS = 1.9
plt.rcParams["font.size"] = 9 * FS

tree = open_ims(RUNS["2 Hz"])
fas = {name: open_ims(path)["FAS"].to_dataset() for name, path in RUNS.items()}
# The 1 Hz run covers the whole grid; keep only the stations both runs share.
fas["1 Hz"] = fas["1 Hz"].sel(station=fas["2 Hz"].station.values)
eas_1, eas_2 = fas["1 Hz"].eas, fas["2 Hz"].eas
frequency = eas_2.frequency.values
log_ratio = np.log(eas_2) - np.log(eas_1)
in_band = (eas_2.frequency >= BAND[0]) & (eas_2.frequency <= BAND[1])
band_ratio = log_ratio.where(in_band).mean("frequency")
coast = load_coastline()


def style_axis(axis: plt.Axes) -> None:
    axis.grid(True, which="both", lw=0.3, color="#e8e8e8")
    for spine in axis.spines.values():
        spine.set_linewidth(0.6)
    axis.tick_params(labelsize=8 * FS)


# --- Figure 1: spectra at TEPS and POTS ----------------------------------------
# No info panel or locator map: the slide title and the speaker carry those.
fig, axd = plt.subplot_mosaic(
    [["spec_TEPS", "spec_POTS"], ["ratio_TEPS", "ratio_POTS"]],
    figsize=(12, 6.3),
    height_ratios=[1.7, 1],
    layout="constrained",
)
for station in STATIONS:
    spectrum, ratio = axd[f"spec_{station}"], axd[f"ratio_{station}"]
    ratio.sharex(spectrum)
    if station != STATIONS[0]:
        spectrum.sharey(axd[f"spec_{STATIONS[0]}"])
        ratio.sharey(axd[f"ratio_{STATIONS[0]}"])
    spectrum.tick_params(labelbottom=False)
    one, two = eas_1.sel(station=station).values, eas_2.sel(station=station).values
    residual = log_ratio.sel(station=station).values

    # Gap shaded by which run is larger, as in ``eqvis spectra``.
    for where, colour in ((two > one, COMPARISON_BLUE), (two <= one, "#4a4a4a")):
        spectrum.fill_between(
            frequency, one, two, where=where, color=colour, alpha=0.18, lw=0, zorder=1
        )
    spectrum.plot(frequency, one, color="black", lw=1.0, zorder=3, label="1 Hz")
    spectrum.plot(frequency, two, color=COMPARISON_BLUE, lw=1.0, zorder=4, label="2 Hz")

    for axis in (spectrum, ratio):
        axis.axvspan(*BAND, color="#f0f0f0", zorder=0)
        for transition, style in zip(TRANSITIONS, ("--", ":")):
            axis.axvline(
                transition,
                color="red",
                zorder=2,
                linestyle=style,
                label=f"{transition:g} Hz transition" if axis is spectrum else None,
            )
    spectrum.set_xscale("log")
    spectrum.set_yscale("log")
    spectrum.set_xlim(0.05, 20)
    spectrum.set_ylim(1e-4, None)
    vs30 = float(eas_2.vs30.sel(station=station))
    rrup = float(eas_2.rrup.sel(station=station))
    spectrum.set_title(
        f"{station}   $V_{{S30}}$ {vs30:.0f} m/s   $R_{{rup}}$ {rrup:.0f} km", fontsize=10 * FS
    )
    style_axis(spectrum)

    ratio.axhline(0, color="#6b6b6b", lw=0.8, zorder=3)
    for guide, mark in ((np.log(2), "×2"), (-np.log(2), "÷2")):
        ratio.axhline(guide, color="#9a9a9a", lw=0.6, ls=":", zorder=3)
        ratio.annotate(
            mark,
            xy=(0.998, guide),
            xycoords=("axes fraction", "data"),
            fontsize=6 * FS,
            color="#6b6b6b",
            ha="right",
            va="bottom",
        )
    for where, colour in ((residual > 0, COMPARISON_BLUE), (residual <= 0, "#4a4a4a")):
        ratio.fill_between(
            frequency, 0, residual, where=where, color=colour, alpha=0.35, lw=0, zorder=1
        )
    ratio.plot(frequency, residual, color="black", lw=0.5, zorder=2)
    mean = float(band_ratio.sel(station=station))
    ratio.plot(
        BAND, [mean, mean], color="#c1272d", lw=2.0, solid_capstyle="butt", zorder=5
    )
    ratio.set_xlabel("frequency (Hz)")
    style_axis(ratio)
    print(f"{station}: {BAND[0]:g}-{BAND[1]:g} Hz mean ln ratio {mean:+.2f} (x{np.exp(mean):.2f})")

axd[f"spec_{STATIONS[0]}"].set_ylabel("EAS (g·s)")
axd[f"spec_{STATIONS[0]}"].legend(fontsize=8 * FS, frameon=False, loc="lower left")
axd[f"ratio_{STATIONS[0]}"].set_ylabel("ln[2 Hz / 1 Hz]")
fig.savefig("figures/fas_TEPS_POTS.png", dpi=DPI, bbox_inches="tight")
print("wrote figures/fas_TEPS_POTS.png")


# --- Figure 2: band-averaged change, mapped ------------------------------------
lon, lat, values = (
    eas_2.longitude.values,
    eas_2.latitude.values,
    band_ratio.values,
)
boundaries = symmetric_norm(values, 10)
colormap = plt.get_cmap("RdBu_r")
norm = BoundaryNorm(boundaries, colormap.N, extend="both")
domain = shapely.from_wkt(tree.attrs["domain"])
basins = load_basins()
degrees = FuncFormatter(lambda v, _: f"{v:g}°")


def draw_stations(axis: plt.Axes, size: float) -> plt.cm.ScalarMappable:
    return axis.scatter(
        lon,
        lat,
        c=values,
        cmap=colormap,
        norm=norm,
        marker="^",
        s=size,
        ec="black",
        lw=0.6,
        zorder=6,
    )


def draw_land(axis: plt.Axes, view: tuple[float, float, float, float]) -> None:
    if coast is not None:
        fill_land(axis, coast, view)
    if basins:
        draw_basins(axis, basins_in_view(basins, view), shapely.box(*view), 1e-3)
    draw_geometry(axis, tree.attrs)
    # Last, so the domain and basin outlines cannot widen the view.
    axis.set_xlim(view[0], view[2])
    axis.set_ylim(view[1], view[3])
    axis.set_aspect(1 / np.cos(np.radians((view[1] + view[3]) / 2)))


fig, ax = plt.subplots(figsize=(6.6, 6.9), layout="constrained")
view = domain.bounds
draw_land(ax, view)
stations = draw_stations(ax, 40)
ax.xaxis.set_major_formatter(degrees)
ax.yaxis.set_major_formatter(degrees)
ax.tick_params(labelsize=9 * FS)
for spine in ax.spines.values():
    spine.set_linewidth(0.6)
# No title: the slide carries it.

# Wellington is too crowded to read at domain scale: magnify it.
axins = ax.inset_axes([0.02, 0.56, 0.42, 0.42])
draw_land(axins, WELLINGTON)
draw_stations(axins, 60)
axins.set_xticks([])
axins.set_yticks([])
for spine in axins.spines.values():
    spine.set_linewidth(0.7)
ax.indicate_inset_zoom(axins, edgecolor="#333333", lw=0.7, alpha=0.9)
# Only the two stations the next slide zooms into are named, at slide size.
# Both sit at the inset's west edge, so the names go east, into the harbour side.
for station, (dx, dy) in zip(STATIONS, ((22, -14), (22, 14))):
    i = int(np.flatnonzero(eas_2.station.values == station)[0])
    axins.annotate(
        station,
        (lon[i], lat[i]),
        xytext=(dx, dy),
        textcoords="offset points",
        ha="left",
        va="top" if dy < 0 else "bottom",
        fontsize=8 * FS,
        fontweight="bold",
        path_effects=[patheffects.withStroke(linewidth=3, foreground="white")],
        # A leader, because the CBD cluster puts several triangles under each name.
        arrowprops=dict(arrowstyle="-", lw=1.2, color="black", shrinkA=0, shrinkB=4),
        zorder=7,
    )

colorbar = fig.colorbar(
    stations, ax=ax, orientation="horizontal", shrink=0.6, pad=0.04, aspect=35
)
colorbar.set_label(
    f"ln[2 Hz / 1 Hz], mean over {BAND[0]:g}-{BAND[1]:g} Hz", fontsize=9 * FS
)
# Every other level, so the enlarged labels do not run together.
colorbar.set_ticks(boundaries[::2])
colorbar.set_ticklabels([f"{b:g}" for b in boundaries[::2]], fontsize=7 * FS)
label_ratios(colorbar, fontsize=7 * FS)
fig.savefig("figures/fas_band_map.png", dpi=DPI, bbox_inches="tight")
print("wrote figures/fas_band_map.png")
