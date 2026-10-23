# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib", "numpy", "pyproj"]
# ///
"""Two real rupture geometries, side by side: a curved interface and a multi-segment.

The preview slide for the rupture generator. Both panels are real geometry, not
sketches:

* left, the Hikurangi subduction interface as the CFM ships it -- a GOCAD TSurf
  of 5,218 vertices and 9,236 triangles, spanning 699 x 617 km and reaching 75 km
  depth. This is the surface the generator fits a plane to, samples on, and
  projects back onto.
* right, NSHM 2022 rupture 354822 -- 26 planes across four named faults
  (Hororata, Kowai-View Hill, Starvation-Ashley, Torlesse), the same rupture the
  key-idea slide uses, so the audience has already met it.

Greyscale throughout, with per-face Lambertian shading from a fixed light. A
surface drawn in one flat tone reads as a cutout; shading is what makes the
curvature of the interface legible at all, and it is the whole point of the left
panel.

Vertical exaggeration is applied and stated on the panels: the interface is
nearly ten times wider than it is deep, so at true scale the curvature this
figure exists to show would be invisible.
"""

from __future__ import annotations

import argparse
import gzip
import sqlite3
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from mpl_toolkits.mplot3d.art3d import Poly3DCollection
from pyproj import Transformer

plt.rcParams.update(
    {
        "font.family": "serif",
        "font.size": 8,
        # bbox="tight" is load-bearing: the title and caption are placed
        # outside the axes rect, so a plain save clips them.
        "savefig.bbox": "tight",
    }
)

# A single light, high and to the north-west, the convention for shaded relief.
LIGHT = np.array([-0.45, 0.55, 0.70])
LIGHT /= np.linalg.norm(LIGHT)
BASE_GREY = 0.90          # tone of a fully-lit face
FLOOR = 0.24              # a face turned away is never pure black
EDGE = "#5a5955"
TEXT = "#0b0b0b"


def shade(tris: np.ndarray, depth_weight: float = 0.0) -> np.ndarray:
    """Per-face grey: Lambertian relief, optionally mixed with a depth ramp.

    Pure Lambertian shading is right for flat planes, but on a finely
    triangulated surface the facet-to-facet normal jitter reads as speckle and
    swamps the large-scale form. Mixing in a depth ramp puts the overall shape
    back in charge -- shallow light, deep dark -- while the shading keeps the
    relief that stops it looking like a flat cutout.

    Parameters
    ----------
    tris : np.ndarray
        ``(n_face, n_vertex, 3)`` polygon coordinates, z positive up.
    depth_weight : float
        Share of the tone taken from depth rather than from the light.

    Returns
    -------
    np.ndarray
        ``(n_face, 3)`` RGB greys.
    """
    a, b, c = tris[:, 0], tris[:, 1], tris[:, 2]
    n = np.cross(b - a, c - a)
    norm = np.linalg.norm(n, axis=1, keepdims=True)
    n = np.divide(n, norm, out=np.zeros_like(n), where=norm > 0)
    # Faces may wind either way; the surface is one-sided so take |cos|.
    lam = np.abs(n @ LIGHT)

    if depth_weight > 0:
        z = tris[..., 2].mean(axis=1)
        lo, hi = z.min(), z.max()
        shallow = (z - lo) / max(hi - lo, 1.0)
        lam = (1.0 - depth_weight) * lam + depth_weight * shallow

    tone = FLOOR + (BASE_GREY - FLOOR) * lam
    return np.repeat(tone[:, None], 3, axis=1)


def read_tsurf(path: Path) -> tuple[np.ndarray, np.ndarray]:
    """Vertices and triangle indices from a gzipped GOCAD TSurf."""
    verts: list[list[float]] = []
    index: dict[int, int] = {}
    tris: list[list[int]] = []
    with gzip.open(path, "rt") as fh:
        for line in fh:
            p = line.split()
            if not p:
                continue
            if p[0] in ("VRTX", "PVRTX"):
                index[int(p[1])] = len(verts)
                verts.append([float(p[2]), float(p[3]), float(p[4])])
            elif p[0] == "TRGL":
                tris.append([index[int(p[i])] for i in (1, 2, 3)])
    return np.asarray(verts), np.asarray(tris)


def rupture_planes(db_path: Path, rupture_id: int) -> np.ndarray:
    """``(n_plane, 4, 3)`` corner coordinates in NZTM metres, z positive up."""
    db = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
    rows = db.execute(
        """SELECT top_left_lat, top_left_lon, top_right_lat, top_right_lon,
                  bottom_right_lat, bottom_right_lon, bottom_left_lat,
                  bottom_left_lon, top_depth, bottom_depth
           FROM fault_plane fp
           JOIN rupture_faults rf ON rf.fault_id = fp.fault_id
           WHERE rf.rupture_id = ?""",
        (rupture_id,),
    ).fetchall()
    to_nztm = Transformer.from_crs("EPSG:4326", "EPSG:2193", always_xy=True)
    quads = []
    for tl_a, tl_o, tr_a, tr_o, br_a, br_o, bl_a, bl_o, ztop, zbot in rows:
        corners = [(tl_o, tl_a, ztop), (tr_o, tr_a, ztop), (br_o, br_a, zbot), (bl_o, bl_a, zbot)]
        quads.append([[*to_nztm.transform(lon, lat), -z] for lon, lat, z in corners])
    return np.asarray(quads)


def frame(ax, pts: np.ndarray, exaggeration: float, elev: float, azim: float) -> None:
    """Centre the view on `pts`, with a stated vertical exaggeration."""
    lo, hi = pts.reshape(-1, 3).min(axis=0), pts.reshape(-1, 3).max(axis=0)
    mid = (lo + hi) / 2
    span = max(hi[0] - lo[0], hi[1] - lo[1])
    ax.set_xlim(mid[0] - span / 2, mid[0] + span / 2)
    ax.set_ylim(mid[1] - span / 2, mid[1] + span / 2)
    ax.set_zlim(lo[2], hi[2])
    depth = max(hi[2] - lo[2], 1.0)
    # `zoom` crops the generous default margin Matplotlib leaves round a 3D
    # axes, which otherwise wastes most of the panel.
    ax.set_box_aspect((1, 1, depth / span * exaggeration), zoom=1.12)
    ax.view_init(elev=elev, azim=azim)
    ax.set_axis_off()


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--tsurf",
        type=Path,
        default=Path.home() / "src/rupture_generator-hybrid/examples/cfm/Hikurangi.ts.gz",
    )
    ap.add_argument("--db", type=Path, default=Path.home() / "src/NSHM2022DB/nshmdb.db")
    ap.add_argument("--rupture", type=int, default=354822)
    ap.add_argument("--out", type=Path, default=Path("out/png/generator-preview.png"))
    ap.add_argument("--dpi", type=int, default=600)
    args = ap.parse_args()

    fig = plt.figure(figsize=(11.6, 2.9))

    # --- left: the curved interface ------------------------------------------
    verts, tris = read_tsurf(args.tsurf)
    faces = verts[tris]
    ax1 = fig.add_subplot(1, 2, 1, projection="3d", computed_zorder=False)
    ax1.add_collection3d(
        Poly3DCollection(
            faces,
            facecolors=shade(faces, depth_weight=0.55),
            edgecolors="none",
            linewidths=0,
        )
    )
    EXAG_INTERFACE = 6.0
    frame(ax1, verts, exaggeration=EXAG_INTERFACE, elev=24, azim=-62)
    ax1.set_title("Curved interface", loc="center", fontsize=10, fontweight="bold", pad=-2)
    ax1.text2D(
        0.5, 0.03,
        f"Hikurangi, CFM triangulation · {len(tris):,} faces · {EXAG_INTERFACE:g}× vertical",
        transform=ax1.transAxes, ha="center", fontsize=7.5, color="#52514e",
    )

    # --- right: the multi-segment rupture ------------------------------------
    quads = rupture_planes(args.db, args.rupture)
    ax2 = fig.add_subplot(1, 2, 2, projection="3d", computed_zorder=False)
    ax2.add_collection3d(
        Poly3DCollection(
            quads, facecolors=shade(quads), edgecolors=EDGE, linewidths=0.35
        )
    )
    EXAG_RUPTURE = 2.2
    frame(ax2, quads, exaggeration=EXAG_RUPTURE, elev=24, azim=-62)
    ax2.set_title("Multi-segment rupture", loc="center", fontsize=10, fontweight="bold", pad=-2)
    ax2.text2D(
        0.5, 0.03,
        f"NSHM 2022 rupture {args.rupture} · {len(quads)} planes, four faults"
        f" · {EXAG_RUPTURE:g}× vertical",
        transform=ax2.transAxes, ha="center", fontsize=7.5, color="#52514e",
    )

    # The two axes are deliberately overlapped. A 3D axes reserves a square box
    # in x/y, and neither object fills its own: the interface sits left of centre
    # in its box and the rupture right of centre, so back to back they leave a
    # wide empty gutter. Overlapping the boxes closes it without clipping either,
    # because the overlap falls entirely in the empty margins.
    # The interface sits left of centre in its box, so its axes is pushed right;
    # the rupture sits right of centre, so its axes is pushed left.
    ax1.set_position([0.035, 0.02, 0.565, 0.96])
    ax2.set_position([0.355, 0.02, 0.565, 0.96])
    args.out.parent.mkdir(parents=True, exist_ok=True)
    # Transparent, so the panel does not sit on a white plate against the
    # off-white slide background.
    fig.savefig(args.out, dpi=args.dpi, transparent=True)
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
