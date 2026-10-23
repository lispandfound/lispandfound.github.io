"""Point sampling versus Backus averaging of a velocity model onto an FD grid.

Renders figures/backus_averaging.png.

Panel (a) is a 1D profile: the true medium contains a soft lens thinner than the
grid spacing h. A single point query at the centre of each cell either misses a
thin layer entirely or lands inside it and applies it to the whole cell; supersampling
the cell and taking the harmonic mean of the shear modulus reproduces the long-wavelength response of the
layering, which is the quantity Backus (1962) shows a long wave actually sees.

Panels (b) and (c) are the same comparison in two dimensions, for a shallow
basin whose edges thin to well below h.

Run:  python scripts/backus_averaging.py

Copied from ~/Documents/phd-proposal/Figures/ and adapted for the slides. The
original averaged mu arithmetically; this version takes the harmonic mean.
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
        "xtick.major.width": 0.6,
        "ytick.major.width": 0.6,
        "savefig.dpi": 400,
        "figure.dpi": 150,
    }
)

POINT_C = "#23373b"  # point sample
BACKUS_C = "#eb811b"  # Backus average
TRUE_C = "0.35"

H = 0.4  # grid spacing, km
N_SUB = 200  # supersamples per cell
RHO = 2.4  # constant density: it cancels, but keep the moduli explicit


# --- 1D medium ---------------------------------------------------------------
def vs_1d(z):
    """True Vs (km/s) as a function of depth (km). Cells are H = 0.4 km and
    sampled at their centres (0.2, 0.6, 1.0, ... km). The one soft feature is a
    0.15 km layer at the surface -- a thin basin in profile -- which lies above
    the first sampling depth. (A deeper soft lens used to sit here too; its
    Backus average read as a slow region far below the basin.)"""
    z = np.asarray(z, dtype=float)
    vs = np.full(z.shape, 3.10)
    vs = np.where(z < 1.30, 2.20, vs)
    vs = np.where(z < 0.15, 0.40, vs)  # thin soft surface layer
    return vs


def cell_values_1d(z_top):
    """Point-sampled and Backus-averaged Vs for a cell of thickness H whose top
    is at z_top."""
    # A grid point stands for its cell, so the point sample is at the centre.
    point = vs_1d(z_top + H / 2)
    sub = z_top[:, None] + (np.arange(N_SUB)[None, :] + 0.5) * H / N_SUB
    mu = RHO * vs_1d(sub) ** 2
    # Backus: the effective shear modulus is the harmonic mean, <1/mu>^-1.
    return point, np.sqrt(1.0 / (1.0 / mu).mean(axis=1) / RHO)


# --- 2D medium ---------------------------------------------------------------
def vs_2d(x, z):
    """True Vs (km/s). A shallow basin thinning to nothing at its edges, over
    a gradient. (A buried soft layer used to sit here too; it changed the
    Backus panel below the basin and read as an unexplained deep change, and
    the 1D profile already makes that point.)"""
    basin = np.where(
        (x > 5.0) & (x < 25.0),
        0.35 * np.sin(np.pi * np.clip((x - 5.0) / 20.0, 0.0, 1.0)) ** 1.3,
        0.0,
    )
    vs = 2.00 + 0.40 * z
    vs = np.where(z < basin, 0.45, vs)
    return vs


# =============================================================================
fig = plt.figure(figsize=(7.1 * 1.25, 3.9 * 1.25))
gs = fig.add_gridspec(
    2, 2, width_ratios=(1.18, 1.85), height_ratios=(1, 1),
    left=0.075, right=0.885, bottom=0.135, top=0.90, wspace=0.30, hspace=0.34,
)
ax_a = fig.add_subplot(gs[:, 0])
ax_b = fig.add_subplot(gs[0, 1])
ax_c = fig.add_subplot(gs[1, 1], sharex=ax_b)

# --- (a) the 1D profile ------------------------------------------------------
Z_MAX_1D = 2.0
zz = np.linspace(0.0, Z_MAX_1D, 4000)
z_tops = np.arange(0.0, Z_MAX_1D, H)
point, backus = cell_values_1d(z_tops)


def staircase(z_tops, values):
    zs, vs = [], []
    for zt, v in zip(z_tops, values):
        zs += [zt, zt + H]
        vs += [v, v]
    return np.array(vs), np.array(zs)


ax_a.plot(vs_1d(zz), zz, color=TRUE_C, lw=1.0, label="true")
vp, zp = staircase(z_tops, point)
vb, zb = staircase(z_tops, backus)
ax_a.plot(vp, zp, color=POINT_C, lw=1.4, label="point sample")
ax_a.plot(vb, zb, color=BACKUS_C, lw=1.4, ls=(0, (4, 1.6)), label="Backus average")
ax_a.plot(point, z_tops + H / 2, ls="none", marker="o", ms=3.4, mfc="white",
          mec=POINT_C, mew=1.0)

ax_a.set_xlim(0.0, 3.4)
ax_a.set_ylim(Z_MAX_1D, 0.0)
ax_a.set_xlabel("$V_S$ (km/s)")
ax_a.set_ylabel("depth (km)")
ax_a.set_title("(a) 1D profile", fontsize=8.0*FS, pad=3)
ax_a.tick_params(labelsize=7.0*FS)
# One row under the whole figure: inside the profile the labels sit on the
# lines at slide size, and a column under it makes the figure too tall.
fig.legend(*ax_a.get_legend_handles_labels(), loc="upper center",
           bbox_to_anchor=(0.5, 0.0), ncol=3, fontsize=6.4*FS, frameon=False,
           handlelength=1.6)

# --- (b), (c) the 2D cross-section ------------------------------------------
X_MAX, Z_MAX_2D = 30.0, 2.0
nx = 400
x_edges = np.linspace(0.0, X_MAX, nx + 1)
x_mid = 0.5 * (x_edges[:-1] + x_edges[1:])
z_edges = np.arange(0.0, Z_MAX_2D + H / 2, H)
z_tops2 = z_edges[:-1]

XM, ZT = np.meshgrid(x_mid, z_tops2)
point_2d = vs_2d(XM, ZT + H / 2)

sub = (np.arange(N_SUB) + 0.5) * H / N_SUB
mu = RHO * vs_2d(XM[..., None], ZT[..., None] + sub) ** 2
backus_2d = np.sqrt(1.0 / (1.0 / mu).mean(axis=-1) / RHO)

norm = Normalize(vmin=0.4, vmax=3.0)
cmap = plt.get_cmap("Blues")

xs_fine = np.linspace(0.0, X_MAX, 800)
basin_base = np.where(
    (xs_fine > 5.0) & (xs_fine < 25.0),
    0.35 * np.sin(np.pi * np.clip((xs_fine - 5.0) / 20.0, 0.0, 1.0)) ** 1.3,
    0.0,
)

for ax, field, title in (
    (ax_b, point_2d, "(b) Point sample at each cell centre"),
    (ax_c, backus_2d, "(c) Backus average over each cell"),
):
    mesh = ax.pcolormesh(x_edges, z_edges, field, cmap=cmap, norm=norm)
    ax.plot(xs_fine, basin_base, color="0.15", lw=0.8)
    ax.set_ylim(Z_MAX_2D, 0.0)
    ax.set_title(title, fontsize=8.0*FS, pad=3)
    ax.set_ylabel("depth (km)")
    ax.tick_params(labelsize=7.0*FS)

ax_b.tick_params(labelbottom=False)
ax_c.set_xlabel("distance (km)")

cax = fig.add_axes([0.902, 0.135, 0.016, 0.53])
cb = fig.colorbar(mesh, cax=cax)
cb.set_label("$V_S$ (km/s)", fontsize=7.5*FS)
cb.ax.tick_params(labelsize=7.0*FS)
cb.outline.set_linewidth(0.5)

fig.savefig("figures/backus_averaging.png", bbox_inches="tight")
print("wrote figures/backus_averaging.png")


# =============================================================================
# The problem on its own, for the slide before Backus is introduced: the same
# medium and the same point sampling, without the averaged answer.
fig2 = plt.figure(figsize=(7.1 * 1.25, 3.9 * 1.25 * 0.62))
gs2 = fig2.add_gridspec(1, 2, width_ratios=(1.0, 1.85), wspace=0.32)
ax_p = fig2.add_subplot(gs2[0, 0])
ax_q = fig2.add_subplot(gs2[0, 1])

ax_p.plot(vs_1d(zz), zz, color=TRUE_C, lw=1.0, label="true")
ax_p.plot(vp, zp, color=POINT_C, lw=1.4, label="point sample")
ax_p.plot(point, z_tops + H / 2, ls="none", marker="o", ms=3.4, mfc="white",
          mec=POINT_C, mew=1.0)
ax_p.set_xlim(0.0, 3.4)
ax_p.set_ylim(Z_MAX_1D, 0.0)
ax_p.set_xlabel("$V_S$ (km/s)")
ax_p.set_ylabel("depth (km)")
ax_p.tick_params(labelsize=7.0*FS)
ax_p.legend(loc="lower left", fontsize=6.4*FS, frameon=False, handlelength=1.6)

mesh2 = ax_q.pcolormesh(x_edges, z_edges, point_2d, cmap=cmap, norm=norm)
ax_q.plot(xs_fine, basin_base, color="0.15", lw=0.8, label="true basin")
ax_q.set_ylim(Z_MAX_2D, 0.0)
ax_q.set_xlabel("distance (km)")
ax_q.tick_params(labelsize=7.0*FS)
ax_q.set_title("a basin edge, point sampled", fontsize=8.0*FS, pad=3)
cb2 = fig2.colorbar(mesh2, ax=ax_q)
cb2.set_label("$V_S$ (km/s)", fontsize=7.5*FS)
cb2.ax.tick_params(labelsize=7*FS)

fig2.savefig("figures/backus_problem.png", bbox_inches="tight")
print("wrote figures/backus_problem.png")
