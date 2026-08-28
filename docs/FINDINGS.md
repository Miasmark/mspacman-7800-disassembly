# Ms. Pac-Man -- findings so far

`Ms Pac-Man (NTSC) (Atari) (1987) (E42FC700).a78`, 16K linear, no banking,
mapped at `$C000-$FFFF` (the upper half of the 7800's 32K address window --
the same pattern the 16K sibling projects, Centipede and Dig Dug, used).
Everything below is reproducible with the
[a7800-toolkit](../../a7800-toolkit/README.md) against `annotations.json`
in this folder:

```
python3 ../a7800-toolkit/tools/disasm.py "Ms Pac-Man (NTSC) (Atari) (1987) (E42FC700).a78" -c annotations.json -o src
python3 ../a7800-toolkit/tools/verify.py "Ms Pac-Man (NTSC) (Atari) (1987) (E42FC700).a78" -d src
```

Static coverage from `tools/init.py`'s first pass (vectors only, no manual
work yet) is **52.4%** as traced code (8589/16384 bytes, 3973 instructions)
-- notably higher than any of the three sibling 16K/32K projects started
with. As of this same first day, every remaining byte is also accounted
for (`disasm.py --gaps` reports none left) -- see "Every gap closed on
day one" below for what that took and what it turned up. Round-trip is
byte-identical.

Vectors: `NMI $F34D` `RESET $CA20` `IRQ $F41C`.

Manual (mechanics reference, scoring table, ghost behavior):
https://atariage.com/manual_html_page.php?SoftwareID=2142 -- fruit/bonus
scoring table given in full (Teddy Bear 50, Cherries 100, Strawberry 200,
Orange 500, Pretzel 700, Apple 1,000, Pear 2,000, Banana 5,000, then
random fruit worth 100-5,000 once the fruit sequence runs out), but no
point values given for dots, power pellets, or ghosts themselves. Four
ghosts named Blinky, Inky, Pinky, and Sue; the only behavioral detail
given is that eating an energy pill turns them "blue" and vulnerable,
with no chase/scatter states described. Four maze patterns exist, tied
to the same names as the fruit sequence (Teddy Bear through Banana),
with random-fruit mazes following once that sequence is exhausted -- the
manual doesn't say whether mazes rotate on a fixed schedule or some other
rule. Five lives per game; no extra-life threshold given. Escape tunnels
let Ms. Pac-Man exit one side of the maze and re-enter the other. Facts
only, not consulted for anything beyond this summary list -- kept
separate from the ROM's own bytes throughout the work below.

## Methodology note

A privately-held, unlicensed historical source for this game exists (the
same archive the sibling projects' reference sources came from). Same
plan as the more recent sibling project: hold off consulting it until
independent work here is substantially done, so that whatever agrees or
disagrees can be compared against a genuinely independent effort.

## Every gap closed on day one -- but for a different reason than Galaga's

`tools/init.py`'s first pass already reached 52.4% of the ROM as code
just from the three vector entry points -- itself notable, well above
where any sibling project started. `disasm.py --gaps` reported 23
separate unreached ranges totaling 7,795 bytes (47.6% of the ROM).

Before declaring any of them, swept for the failure mode this project's
sibling projects all learned to check for: does any `JSR`/`JMP` anywhere
in the already-traced code land inside one of these ranges? Checked
every JSR/JMP target in the file against all 23 ranges at once (not
spot-checked) -- zero hits. No stray reachable code hiding in a "data"
gap.

Unlike Galaga (where every gap turned out to already carry a real `dat_`
cross-reference from traced code, just needing block declarations), most
of these 23 ranges have **no incoming reference from any 6502 instruction
at all** -- consistent with the 7800's Maria chip DMA-ing character/
sprite graphics directly out of ROM without ever needing a 6502 `LDA` to
touch them, not a red flag the way an actually-unreferenced *code* gap
would be. A byte-frequency pass (the same cheap first filter used on
Galaga's blocks) split the 23 ranges into three rough families:

* **One large graphics-like block** (`dat_C000`, 2,592 bytes, sitting
  immediately before `RESET` at the very base of the mapped ROM window):
  96 distinct byte values, dominated by `$00`/`$55`/`$54`/`$15`/`$AA`/`$FF`
  -- the same dense, few-values-repeated bit-plane signature the sibling
  16K projects' actual character sheets showed. A strong candidate for
  sprite/tile graphics, not decoded into individual tiles yet.
* **Two small-integer-dominated blocks** (`dat_E342`, 759 bytes, and
  `dat_EB75`, 1,961 bytes): values cluster in the 0-8 range rather than
  showing the bit-plane pattern above. A real candidate for maze-layout
  or collision-map data (small per-cell tile-type IDs), matching the
  user's own expectation going into this project that most of the ROM
  should be level data -- flagged as a lead, not a conclusion; nothing
  about grid dimensions or tile meaning has been decoded yet.
* **Nineteen smaller, mixed-signature blocks** (11 bytes to 487 bytes
  each): scattered byte distributions consistent with jump tables,
  pointer tables, or other code-adjacent parameter data, the same family
  most of Galaga's own smaller gaps turned out to be.

The tail block (`dat_FC7C`, 900 bytes, running to the ROM's own top)
contains the hardware vectors at `$FFFA-$FFFF`, byte-verified against the
already-declared entries -- the same reason this shows as a gap in every
sibling project. One real difference worth recording rather than
glossing over: **no ASCII copyright/signature string** turned up in a
quick check of this tail block, unlike the `GCC(c)1984` string found in
the same relative position in both the Dig Dug and Galaga projects. Not
explained yet -- could mean a different code/publisher signature exists
elsewhere in this ROM, or that this particular port simply doesn't carry
one the same way.

**Net for day one:** every byte accounted for, a real structural lead on
where level/maze data might live, and an honest count against the user's
"most of the ROM should be level data" expectation -- 47.6% declared as
data blocks, a substantial fraction but not literally "most" of the ROM
by byte count, and not yet confirmed that the small-integer blocks
specifically *are* maze data rather than something else with a similar
byte-frequency signature.

## What's still open

* Whether the two small-integer-signature blocks (`dat_E342`,
  `dat_EB75`) really are maze/level layout data -- the leading
  candidate, not yet decoded into an actual grid.
* Whether the large graphics-signature block (`dat_C000`) really is
  character/sprite tile data -- not yet rendered or cross-checked
  against known 7800 graphics-mode bit-plane conventions.
* What each of the nineteen smaller mixed-signature blocks actually is.
* Why no `GCC(c)1984`-style signature string turned up in the tail
  block, unlike both sibling 16K/32K projects that checked.
* Ghost behavior mechanics beyond what the manual states (chase/scatter/
  frightened timing, if this port implements anything beyond "turns
  blue when a pellet is eaten") -- entirely unconfirmed against the
  ROM's own bytes so far.
* Actual point values for dots, power pellets, and ghosts -- the manual
  gives the fruit table only.
* Extra-life threshold, if one exists in this port.
* The private reference source stays unconsulted, per the plan -- see
  `README.md`.
