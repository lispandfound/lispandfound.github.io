"""Four representations of near-surface velocities under a flat free surface.

Renders figures/topography_representations.png.

The synthetic medium is defined once, in absolute elevation: a weathered
sedimentary cover that follows the ground surface, a basement whose top drops
away beneath a sedimentary basin, and a deeper unit whose top sits at a constant
elevation of -2.5 km. That last horizon is the diagnostic one -- it is flat in
the earth, so any curvature it picks up in a panel is distortion introduced by
the representation, not geology.

    True              free surface follows the topography (curvilinear grid)
    Bulldozed         flat free surface at sea level; material above it dropped
    Squashed          column shifted by h(x), so the ground surface maps to z=0
    Squashed-tapered  the same shift, tapered linearly to zero by z_taper

Run:  python scripts/topography_representations.py

Copied from ~/Documents/phd-proposal/Figures/ and adapted for the slides.
"""

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import Normalize

# Slide version, for the GMCM talk: text scaled by FS so it stays readable on a
# projector at the size the deck shows the figure, and colours taken from the
# deck palette (palette.typ).
FS = 2.2

plt.rcParams.update(
    {
        "font.family": "serif",
        "font.serif": ["Libertinus Serif", "DejaVu Serif"],
        "mathtext.fontset": "cm",
        "font.size": 8 * FS,
        "axes.linewidth": 0.6,
        "xtick.direction": "out",
        "ytick.direction": "out",
        "xtick.major.width": 0.6,
        "ytick.major.width": 0.6,
        "savefig.dpi": 400,
        "figure.dpi": 150,
    }
)

# --- the medium, in absolute elevation -------------------------------------
X_MIN, X_MAX = 0.0, 40.0
Z_MAX = 4.0  # maximum simulation depth plotted, km
E_MIN, E_MAX = -Z_MAX, 1.8  # elevation window for the "true" panel
Z_TAPER = 2.0  # taper depth for the squashed-tapered representation, km
DEEP_TOP = -2.5  # elevation of the deep marker horizon, km


def topography(x):
    """Ground surface elevation h(x) in km."""
    return (
        1.15 * np.exp(-(((x - 9.0) / 4.5) ** 2))
        + 0.55 * np.exp(-(((x - 18.0) / 2.6) ** 2))
        + 0.10 * np.exp(-(((x - 31.0) / 7.0) ** 2))
    )


def basement_top(x):
    """Top of basement B(x): 0.35 km below the surface, deepening in the basin."""
    return topography(x) - 0.35 - 1.60 * np.exp(-(((x - 30.0) / 4.2) ** 2))


def vs_true(x, e):
    """Shear-wave velocity (km/s) of the medium at horizontal position x and
    absolute elevation e. NaN above the ground surface."""
    h = topography(x)
    b = basement_top(x)
    cover_thickness = np.maximum(h - b, 1e-3)
    frac = np.clip((h - e) / cover_thickness, 0.0, 1.0)

    vs = np.full(np.broadcast(x, e).shape, np.nan, dtype=float)
    in_cover = (e <= h) & (e > b)
    in_basement = (e <= b) & (e > DEEP_TOP)
    in_deep = e <= DEEP_TOP

    vs = np.where(in_cover, 0.45 + 0.75 * frac, vs)
    vs = np.where(in_basement, 2.55 + 0.30 * (b - e), vs)
    vs = np.where(in_deep, 3.55, vs)
    return vs


# --- the four representations ----------------------------------------------
# Each maps a simulation depth z (positive down from the flat free surface)
# onto the absolute elevation the velocity model is queried at.
def elevation_query(x, z, mode):
    h = topography(x)
    if mode == "bulldozed":
        return -z
    if mode == "squashed":
        return h - z
    if mode == "squashed-tapered":
        return h * np.clip(1.0 - z / Z_TAPER, 0.0, 1.0) - z
    raise ValueError(mode)


def horizon_depth(x, elevation, mode):
    """Simulation depth at which a horizon of constant absolute `elevation`
    appears, under a given representation. Inverts elevation_query in z."""
    h = topography(x)
    if mode == "bulldozed":
        return np.full_like(h, -elevation)
    if mode == "squashed":
        return h - elevation
    if mode == "squashed-tapered":
        # e = h(1 - z/z_t) - z  ->  z = (h - e) / (1 + h/z_t)   for z < z_t
        z = (h - elevation) / (1.0 + h / Z_TAPER)
        return np.where(z < Z_TAPER, z, -elevation)
    raise ValueError(mode)


# --- figure -----------------------------------------------------------------
nx, nz = 600, 420
x = np.linspace(X_MIN, X_MAX, nx)
z = np.linspace(0.0, Z_MAX, nz)
e_grid = np.linspace(E_MIN, E_MAX, nz)
XX, ZZ = np.meshgrid(x, z)
XE, EE = np.meshgrid(x, e_grid)

norm = Normalize(vmin=0.4, vmax=3.6)
cmap = plt.get_cmap("Blues")  # sequential, one hue, light (slow) -> dark (fast)

fig, axes = plt.subplots(
    2, 2, figsize=(7.1 * 1.25, 4.6 * 1.25), sharex=True, layout="constrained"
)

panels = [
    ("(a) True", None),
    ("(b) Bulldozed", "bulldozed"),
    ("(c) Squashed", "squashed"),
    ("(d) Squashed–tapered", "squashed-tapered"),
]

for ax, (title, mode) in zip(axes.ravel(), panels):
    if mode is None:
        field = vs_true(XE, EE)
        mesh = ax.pcolormesh(XE, EE, field, cmap=cmap, norm=norm, shading="auto")
        ax.plot(x, topography(x), color="0.15", lw=1.0)
        ax.axhline(DEEP_TOP, color="0.15", lw=0.7, ls=(0, (4, 2)))
        ax.set_ylim(E_MIN, E_MAX)
        ax.set_ylabel("elevation (km)")
        ax.axhline(0.0, color="0.45", lw=0.5, ls=(0, (1, 2)))
        ax.annotate(
            "sea level",
            xy=(0.6, 0.0),
            xytext=(0.6, -0.55),
            fontsize=6.5*FS,
            color="0.35",
        )
    else:
        field = vs_true(XX, elevation_query(XX, ZZ, mode))
        mesh = ax.pcolormesh(XX, ZZ, field, cmap=cmap, norm=norm, shading="auto")
        ax.plot([X_MIN, X_MAX], [0, 0], color="0.15", lw=1.0)
        # Where the flat marker horizon ends up under this representation ...
        ax.plot(x, horizon_depth(x, DEEP_TOP, mode), color="0.15", lw=0.7,
                ls=(0, (4, 2)))
        # ... against where it truly is.
        ax.axhline(-DEEP_TOP, color="#b3242b", lw=1.8, ls=(0, (1, 1.6)))
        ax.set_ylim(Z_MAX, 0.0)
        # One depth label per row is enough; the right column shares it.
        if ax in axes[:, 0]:
            ax.set_ylabel("depth (km)")

    ax.set_title(title, fontsize=8.0*FS, pad=3)
    ax.set_xlim(X_MIN, X_MAX)
    ax.tick_params(labelsize=7.0*FS)

for ax in axes[1]:
    ax.set_xlabel("distance (km)")

# Annotations that carry the argument of the figure.



# Shared legend for the two horizon lines, and the colour bar.
handles = [
    plt.Line2D([], [], color="0.15", lw=0.7, ls=(0, (4, 2)),
               label="horizon as represented"),
    plt.Line2D([], [], color="#b3242b", lw=1.8, ls=(0, (1, 1.6)),
               label="its true depth"),
]
fig.legend(
    handles=handles,
    loc="outside lower center",
    ncol=2,
    frameon=False,
    fontsize=6.8*FS,
)

cb = fig.colorbar(mesh, ax=axes, shrink=0.8, aspect=25)
cb.set_label("$V_S$ (km/s)", fontsize=7.5*FS)
cb.ax.tick_params(labelsize=7.0*FS)
cb.outline.set_linewidth(0.5)

fig.savefig("figures/topography_representations.png", bbox_inches="tight")
print("wrote figures/topography_representations.png")
