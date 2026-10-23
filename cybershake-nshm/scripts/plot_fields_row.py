# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib", "numpy"]
# ///
"""The four kinematic fields, drawn as one row for a slide.

This is the *unshaded* middle of the rupture-generation slide: the part of the
pipeline that is genslip's framework and that the audience already accepts. It
is drawn so the two additions either side of it have something to be additions
*to*.

NOTE: this is a demonstration of the correlation structure, not output from
either genslip or the hybrid generator. The von Karman sampler is the one from
~/Documents/phd-proposal/scripts/plot_vonkarman_slip.py, copied rather than
imported because that is the convention in this tree; the rupture time is a
radial approximation with a correlated perturbation, not an eikonal solve. Say
so in the caption if the figure is ever used to make a quantitative point.

The composition follows plot_slip_rise_rake.py: rise time and rupture time are
partly correlated with slip, rake is drawn independently with the same
distribution parameters. Correlations are the production values --
rho_rise = 0.9 and rho_onset = 0.8 in stages.py -- so the visual relationship
between the panels is the real one.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import BoundaryNorm
from matplotlib.ticker import MaxNLocator

# Jake's figure conventions: serif, hairline rules, sequential maps for
# non-negative quantities and a diverging map for anything zero-mean.
plt.rcParams.update(
    {
        "font.family": "serif",
        "font.size": 8,
        "axes.linewidth": 0.6,
        "xtick.major.width": 0.6,
        "ytick.major.width": 0.6,
        "savefig.bbox": "tight",
    }
)

# Discrete levels, not continuous ramps: Brendon reads a map by counting bands,
# and a continuous ramp makes "how much bigger is this patch than that one" a
# judgement about shade rather than a count. Same construction as
# ~/src/eqvis_workflow/src/eqvis_workflow/raster.py:discrete_norm -- round level
# boundaries from MaxNLocator over the robust 1-99% range, then a BoundaryNorm
# that extends past the top so a clipped high tail still reads as "off the
# scale". Only the top: every field drawn here is non-negative and its lowest
# boundary is zero, so a low-end arrow would advertise underflow that cannot
# happen.
N_LEVELS = 8

SLIP_CMAP = "hot_r"
RISE_CMAP = "YlGnBu"
TIME_CMAP = "Blues"
RAKE_CMAP = "viridis"

HURST = 0.75  # sampling.py:46
RHO_RISE = 0.9  # stages.py, rise_time_field
RHO_ONSET = 0.8  # stages.py, onset_perturbation
COV = 0.75  # stages.py, slip_pattern


def von_karman_field(n_s, n_d, d_s, d_d, hurst, a_s, a_d, phase):
    """A standardised von Karman field on a regular grid.

    Parameters
    ----------
    n_s, n_d : int
        Cell counts along strike and down dip.
    d_s, d_d : float
        Cell spacing along strike and down dip, in km.
    hurst : float
        Hurst exponent.
    a_s, a_d : float
        Correlation lengths along strike and down dip, in km.
    phase : np.ndarray
        Unit-modulus complex phase field, shape ``(n_d, n_s)``.

    Returns
    -------
    np.ndarray
        Zero-mean, unit-variance field of shape ``(n_d, n_s)``.
    """
    k_s = 2.0 * np.pi * np.fft.fftfreq(n_s, d=d_s)
    k_d = 2.0 * np.pi * np.fft.fftfreq(n_d, d=d_d)
    ks, kd = np.meshgrid(k_s, k_d, indexing="xy")
    k2 = (a_s * ks) ** 2 + (a_d * kd) ** 2
    amplitude = np.sqrt(a_s * a_d / (1.0 + k2) ** (hurst + 1.0))
    field = np.fft.ifft2(amplitude * phase).real
    return (field - field.mean()) / field.std()


def correlate(a, b, rho):
    """Blend two standardised fields to a stated correlation."""
    out = rho * a + np.sqrt(1.0 - rho**2) * b
    return (out - out.mean()) / out.std()


def taper(n_d, n_s, cells=6):
    """Product of four cosine edge ramps, as in ``stages.taper_edges``."""
    ramp = lambda n: np.clip(  # noqa: E731
        0.5 * (1 - np.cos(np.pi * np.minimum(np.arange(n), cells) / cells)), 0, 1
    )
    rs, rd = ramp(n_s), ramp(n_d)
    return np.outer(np.minimum(rd, rd[::-1]), np.minimum(rs, rs[::-1]))


def discrete(values, cmap_name, n_levels=N_LEVELS, vmin=0.0, vmax=None, extend="max"):
    """Round level boundaries and a matching BoundaryNorm for ``values``.

    Follows eqvis_workflow's `discrete_norm`: the range is the 1-99% quantile
    band rather than the extremes, so a single outlying cell cannot flatten the
    whole scale, and `MaxNLocator` picks boundaries a reader can do arithmetic
    with.
    """
    finite = values[np.isfinite(values)]
    lo = vmin if vmin is not None else float(np.quantile(finite, 0.01))
    hi = vmax if vmax is not None else float(np.quantile(finite, 0.99))
    if not hi > lo:
        hi = lo + (abs(lo) or 1.0) * 0.1
    levels = MaxNLocator(n_levels).tick_values(lo, hi)
    cmap = plt.get_cmap(cmap_name)
    return levels, BoundaryNorm(levels, cmap.N, extend=extend), cmap


def keep(values, count):
    """Thin ``values`` to ``count`` evenly spaced entries, ends included."""
    count = max(2, count)
    if count >= len(values):
        return list(values)
    last = len(values) - 1
    return [values[round(i * last / (count - 1))] for i in range(count)]


def bar(ax, im, unit, levels):
    """A short horizontal colourbar under a wide, shallow panel.

    Vertical bars are the wrong shape here: the fault is 40 x 15 km, so a
    full-height bar beside a panel is taller than the panel is and reads as the
    dominant object in the figure.
    """
    cb = ax.figure.colorbar(
        im, ax=ax, orientation="horizontal", fraction=0.075, pad=0.04, aspect=28
    )
    cb.outline.set_linewidth(0.6)
    cb.ax.tick_params(labelsize=6.5, width=0.6, length=2.5, pad=1.5)
    # Ticks sit ON the level boundaries -- a discrete bar whose ticks fall
    # mid-band is worse than a continuous one, because it implies boundaries
    # that are not there. Thinned to what fits at this size.
    shown = keep(list(levels), 5)
    cb.set_ticks(shown)
    cb.set_ticklabels([f"{b:g}" for b in shown])
    cb.set_label(unit, fontsize=6.5, labelpad=1.5)
    return cb


def panel(ax, data, cmap_name, title, unit):
    levels, norm, cmap = discrete(data, cmap_name)
    im = ax.imshow(
        data, cmap=cmap, origin="upper", aspect="equal", extent=(0, 40, 15, 0), norm=norm
    )
    ax.set_title(title, loc="left", fontweight="bold", fontsize=8.5, pad=4)
    ax.set_xticks([])
    ax.set_yticks([])
    bar(ax, im, unit, levels)
    return im


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", type=Path, default=Path("out/png/fields-row.png"))
    ap.add_argument("--seed", type=int, default=20260825)
    ap.add_argument("--dpi", type=int, default=600)
    args = ap.parse_args()

    length, width, spacing = 40.0, 15.0, 0.1
    n_s, n_d = int(length / spacing), int(width / spacing)
    a_s, a_d = 6.0, 3.0

    rng = np.random.default_rng(args.seed)

    def phase():
        z = rng.normal(size=(n_d, n_s)) + 1j * rng.normal(size=(n_d, n_s))
        return z / np.abs(z)

    kw = dict(n_s=n_s, n_d=n_d, d_s=spacing, d_d=spacing, hurst=HURST, a_s=a_s, a_d=a_d)
    z_slip = von_karman_field(**kw, phase=phase())
    z_rise = correlate(z_slip, von_karman_field(**kw, phase=phase()), RHO_RISE)
    z_ons = correlate(z_slip, von_karman_field(**kw, phase=phase()), RHO_ONSET)
    z_rake = von_karman_field(**kw, phase=phase())

    edge = taper(n_d, n_s, cells=int(2.0 / spacing))

    # Slip: 1 + cov*Z, truncated at zero, tapered, scaled to a mean of 100 cm.
    slip = np.maximum(1.0 + COV * z_slip, 0.0) * edge
    slip *= 100.0 / slip[slip > 0].mean()

    # Rise time: sqrt(slip) weighting, normalised to a ~2 s mean.
    rise = np.maximum(1.0 + COV * z_rise, 0.0) ** 0.5
    rise *= 2.0 / rise.mean()

    # Rupture time: radial distance over a depth-reduced speed, perturbed by a
    # field correlated with slip -- high-slip patches rupture slightly early.
    xs = np.linspace(0, length, n_s)
    ds = np.linspace(0, width, n_d)
    xx, dd = np.meshgrid(xs, ds)
    hyp = (14.0, 9.0)
    vr = 2.6 * (0.6 + 0.4 * np.clip(dd / 6.5, 0, 1))
    onset = np.hypot(xx - hyp[0], dd - hyp[1]) / vr
    onset = np.maximum(onset - 0.35 * z_ons, 0.0)

    rake = 170.0 + 15.0 * z_rake

    fig, axes = plt.subplots(1, 4, figsize=(13.2, 2.95), constrained_layout=True)

    panel(axes[0], slip, SLIP_CMAP, "Slip", "cm")
    panel(axes[1], rise, RISE_CMAP, "Rise time", "s")

    time_levels, _, _ = discrete(onset, TIME_CMAP)
    panel(axes[2], onset, TIME_CMAP, "Rupture time", "s")
    # Contours on the colour boundaries, so the bands and the lines are the
    # same partition of the field rather than two competing ones.
    axes[2].contour(
        xx, dd, onset, levels=time_levels, colors="k", linewidths=0.4
    )
    axes[2].plot(*hyp, marker="*", ms=9, mfc="white", mec="k", mew=0.7, ls="none")

    # Rake as a quiver field, subsampled so the arrows stay readable.
    step = int(1.6 / spacing)
    sub = (slice(None, None, step), slice(None, None, step))
    ang = np.deg2rad(rake[sub])
    dev = np.abs(rake[sub] - 170.0)
    rake_levels, rake_norm, rake_cmap = discrete(dev, RAKE_CMAP)
    q = axes[3].quiver(
        xx[sub],
        dd[sub],
        np.cos(ang),
        np.sin(ang),
        dev,
        cmap=rake_cmap,
        norm=rake_norm,
        pivot="mid",
        scale=17,
        width=0.006,
        headwidth=3.2,
        headlength=4.0,
    )
    axes[3].set_xlim(0, 40)
    axes[3].set_ylim(15, 0)
    axes[3].set_aspect("equal")
    axes[3].set_title("Rake", loc="left", fontweight="bold", fontsize=8.5, pad=4)
    axes[3].set_xticks([])
    axes[3].set_yticks([])
    for s in axes[3].spines.values():
        s.set_linewidth(0.6)
    bar(axes[3], q, r"$|\lambda - \lambda_0|$  (deg)", rake_levels)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.out, dpi=args.dpi)
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
