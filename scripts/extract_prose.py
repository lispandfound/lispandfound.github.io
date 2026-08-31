# /// script
# requires-python = ">=3.12"
# ///
"""Pull the deck's prose out of main.typ so Vale can lint it.

Vale has no Typst parser, and two of the rules that matter here -- the
reality-adverb and hedge-cascade density checks -- count occurrences per BLOCK.
Concatenating every `// SAY:` line into one paragraph therefore measures the
density of the whole talk against a threshold meant for one paragraph, and
fires on notes that are individually fine. So each slide's notes become their
own block, separated by a blank line, which is the unit a listener actually
hears.

The slide text itself comes from the PDF (see the Justfile), because that is
the only thing that knows what survived layout.
"""

import pathlib
import sys

src = pathlib.Path(sys.argv[1]).read_text().splitlines()
out: list[str] = []
block: list[str] = []

for line in src:
    if line.startswith("// SAY:"):
        block.append(line[len("// SAY:") :].strip())
    elif block:
        out.append(" ".join(block))
        block = []
if block:
    out.append(" ".join(block))

pathlib.Path(sys.argv[2]).write_text("\n\n".join(out) + "\n")
print(f"{len(out)} note blocks -> {sys.argv[2]}")
