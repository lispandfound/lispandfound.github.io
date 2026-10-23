# /// script
# requires-python = ">=3.12"
# ///
"""Density metrics Vale's keyword rules cannot express, against one baseline.

The baseline is ~/Documents/phd-proposal, and only that. It is the longest
sample of the author's own connected prose, and calibrating to it rather than
to the earlier decks changed two conclusions: the em-dash, which the decks use
freely and which therefore looked like house style, runs at 1.7 per thousand
words in the proposal; and the negation-definition -- "X is not Y", then a
short sentence saying what it is -- appears zero times in 8,742 words.

Both are structural rather than lexical, so neither shipped Vale ruleset can
see them. A rate is only meaningful against the prose it is supposed to sound
like, which is why this prints the baseline alongside every target.
"""

import re
import subprocess
import sys
from pathlib import Path

# Counted together: `---` is what the Typst source writes and `—` is what the
# PDF renders, so a metric that sees only one of them reads zero on whichever
# file it was not written for. This script measures both, having once reported
# a clean zero on the speaker notes purely because they store the ASCII form.
PATTERNS = {
    "em-dash": r"—|–|(?<!-)---(?!-)|(?<![-\w])--(?![-\w])",
    "negation-definition": (
        r"\bis not (?:a|an|the|just)\b|\bare not (?:a|an|the|just)\b"
        r"|\bis not the same as\b|\bThat is not the\b"
    ),
}

BASELINE = Path.home() / "Documents/reproducible-data-talk/out/lint/baseline/phd-proposal.md"


def measure(path: Path) -> tuple[int, dict[str, int]]:
    text = path.read_text()
    words = len(text.split())
    return words, {
        name: len(re.findall(pat, text, re.IGNORECASE))
        for name, pat in PATTERNS.items()
    }


def report(path: Path, base_rates: dict[str, float] | None) -> None:
    words, counts = measure(path)
    print(f"\n{path.name}  ({words:,} words)")
    for name, count in counts.items():
        rate = count / words * 1000
        line = f"  {name:<22} {count:3d}   {rate:5.2f} /1k"
        if base_rates is not None:
            base = base_rates[name]
            ratio = "--" if base == 0 else f"{rate / base:.1f}x"
            flag = "  OVER" if (base == 0 and count) or (base and rate > 2 * base) else ""
            line += f"   baseline {base:5.2f}  ({ratio}){flag}"
        print(line)


def main() -> None:
    if not BASELINE.exists():
        sys.exit(f"no baseline at {BASELINE}; run `just lint-baseline` first")
    base_words, base_counts = measure(BASELINE)
    base_rates = {k: v / base_words * 1000 for k, v in base_counts.items()}

    print(f"baseline: {BASELINE.name} ({base_words:,} words, PhD proposal body)")
    report(BASELINE, None)
    for arg in sys.argv[1:]:
        report(Path(arg), base_rates)


if __name__ == "__main__":
    main()
