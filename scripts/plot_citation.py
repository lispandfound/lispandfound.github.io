# /// script
# requires-python = ">=3.12"
# dependencies = ["matplotlib"]
# ///
"""What a data availability statement is worth, by what it actually says.

Colavizza, Hrynaszkiewicz, Staden, Whitaker & McGillivray (2020), PLOS ONE
15(4): e0230416. 531,889 articles across the PLOS and BMC journals, OLS with a
three-year citation window.

The chart is four bars because the headline number alone hides the finding that
answers the objections: once you control for the journal, a direct link to a
repository is the ONLY category still significantly associated with a citation
advantage. "Available on request" is not a weaker version of sharing. It is
measured here, and it does nothing.

Numbers are hard-coded from the paper rather than fetched, because they are a
published result rather than a live quantity, and a build with no network
should still produce the same slide.
"""

import argparse
from pathlib import Path

import matplotlib as mpl
import matplotlib.patches as mpatches
import matplotlib.pyplot as plt

# (label, gloss kept for the speaker notes, effect, is the effect significant)
# The three null rows are drawn at a nominal small height so that the bar is
# visible as "measured, and flat" rather than absent.
ROWS = [
    ("Restricted", "no data available", 0.0, False),
    ("On request", "email the authors", 0.0, False),
    ("In the paper", "a supplementary table", 0.0, False),
    ("A link to a repository", "a URL or a DOI", 25.36, True),
]
ERR = 1.07  # reported confidence on the 25.36% figure

PERF = "#1f6f5c"
QUIET = "#8a8f92"
EXACT = "#23373b"


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--dpi", type=int, default=300)
    args = ap.parse_args()

    mpl.rcParams.update({
        "font.family": "sans-serif",
        "font.sans-serif": ["DejaVu Sans"],
        "font.size": 12,
        "axes.edgecolor": EXACT,
        "text.color": EXACT,
        "xtick.color": EXACT,
        "ytick.color": EXACT,
    })

    fig, ax = plt.subplots(figsize=(7.6, 3.4), constrained_layout=True)
    y = list(range(len(ROWS)))

    for i, (_, _, effect, sig) in enumerate(ROWS):
        if sig:
            ax.barh(i, effect, xerr=ERR, color=PERF, height=0.66,
                    error_kw={"ecolor": EXACT, "capsize": 4, "lw": 1.2})
            ax.text(effect + ERR + 1.0, i, f"+{effect:.0f}%", va="center",
                    fontsize=15, fontweight="bold", color=PERF)
        else:
            ax.barh(i, 0.35, color=QUIET, alpha=0.55, height=0.66)
            ax.text(1.4, i, "no measurable effect", va="center", fontsize=11,
                    color=QUIET, style="italic")

    # The row label alone. An earlier version carried a second gloss column
    # ("email the authors", "a URL or a DOI") outside the axes, which matplotlib
    # placed off the canvas -- and which the four labels do not need.
    ax.set_yticks(y, [r[0] for r in ROWS], fontsize=12)

    ax.invert_yaxis()
    ax.set_xlim(0, 33)
    ax.set_xlabel("citations, against the average for the same journal")
    ax.axvline(0, color=EXACT, lw=1.0)

    for spine in ("top", "right", "left"):
        ax.spines[spine].set_visible(False)
    ax.tick_params(axis="y", length=0)
    ax.grid(axis="x", color=QUIET, alpha=0.25, lw=0.6)
    ax.set_axisbelow(True)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.out, dpi=args.dpi, transparent=True)
    print(f"wrote {args.out}")


if __name__ == "__main__":
    main()
