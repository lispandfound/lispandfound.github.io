# /// script
# requires-python = ">=3.12"
# dependencies = ["matplotlib", "requests"]
# ///
"""Monthly downloads of the toolchain packages, from pypistats.

The number is the argument: nobody at QuakeCoRE asked for these installs, and
none of them went through us. That is what "virality" means on the slide, and
it is the one claim in the talk that would be worthless as an assertion.

Fetched at build time and cached to a JSON next to the figure, so a build with
no network reuses the last numbers rather than failing -- and so the date the
figure was made is recorded alongside them.
"""

import argparse
import json
import time
from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
import requests

# Every ucgmsim package the workflow depends on that is published. The one
# omission is Empirical_Engine, which is still install-from-git -- it is named
# on the slide rather than quietly dropped.
PACKAGES = [
    "source-modelling",
    "qcore-utils",
    "velocity-modelling",
    "im-calculation",
    "nshmdb",
    "oq-wrapper",
]

STAT = "#eb811b"
EXACT = "#23373b"
QUIET = "#8a8f92"


def fetch(cache: Path) -> dict[str, int]:
    """Monthly downloads per package, falling back to the cache on failure."""
    got: dict[str, int] = {}
    for name in PACKAGES:
        try:
            r = requests.get(
                f"https://pypistats.org/api/packages/{name}/recent", timeout=10
            )
            r.raise_for_status()
            got[name] = r.json()["data"]["last_month"]
        except Exception as exc:  # noqa: BLE001 -- any failure means "use cache"
            print(f"  {name}: {exc}")
        # pypistats rate-limits, and six packages in a row trips it.
        time.sleep(1.5)

    if cache.exists():
        previous = json.loads(cache.read_text())["downloads"]
        for name in PACKAGES:
            got.setdefault(name, previous.get(name, 0))

    cache.parent.mkdir(parents=True, exist_ok=True)
    cache.write_text(
        json.dumps(
            {"fetched": time.strftime("%Y-%m-%d"), "downloads": got},
            indent=2,
        )
    )
    return got


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--dpi", type=int, default=600)
    args = ap.parse_args()

    downloads = fetch(args.out.parent / "pypi-downloads.json")
    items = sorted(downloads.items(), key=lambda kv: kv[1])

    mpl.rcParams.update({
        "font.family": "sans-serif",
        "font.sans-serif": ["DejaVu Sans"],
        "font.size": 11,
        "axes.edgecolor": EXACT,
        "text.color": EXACT,
        "xtick.color": EXACT,
        "ytick.color": EXACT,
    })

    fig, ax = plt.subplots(figsize=(6.4, 3.2), constrained_layout=True)
    y = range(len(items))
    ax.barh(list(y), [v for _, v in items], color=STAT, height=0.68)
    ax.set_yticks(
        list(y),
        [k for k, _ in items],
        fontsize=10,
        family="DejaVu Sans Mono",
    )

    for i, (_, v) in enumerate(items):
        ax.text(v + max(downloads.values()) * 0.015, i, f"{v:,}", va="center", fontsize=10)

    ax.set_xlabel("installs per month")
    for spine in ("top", "right", "left"):
        ax.spines[spine].set_visible(False)
    ax.tick_params(axis="y", length=0)
    ax.set_xlim(0, max(downloads.values()) * 1.18)
    ax.grid(axis="x", color=QUIET, alpha=0.25, lw=0.6)
    ax.set_axisbelow(True)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.out, dpi=args.dpi, transparent=True)
    print(f"{args.out}  {downloads}")


if __name__ == "__main__":
    main()
