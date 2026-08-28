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

## Four recordings, and concrete hints from the user

Four recordings are in the repo, made across a few sessions as the user
found more worth capturing. True lengths confirmed up front this time,
per the lesson the Galaga project paid for at real cost (never trust an
early exit threshold as "the recording's length" -- let playback exhaust
naturally against a generous cap and read MAME's own summary line only
once that's actually happened):

| recording | true length | ~real time |
|---|---|---|
| `run-01.inp` | 25,826 frames | ~7.2 min |
| `run-02.inp` | 22,383 frames | ~6.2 min |
| `run-03.inp` | 9,902 frames | ~2.75 min |
| `run-04.inp` | 6,069 frames | ~1.7 min |

Recorded here as concrete, falsifiable targets for the first live probes,
the same role gameplay hints played in every sibling project so far:

* **There's a level-select feature -- a "Teddy Bear" starting level runs
  slowly.** The user could begin a session directly from the Teddy Bear
  maze (the first name in both the fruit-scoring and maze-naming
  sequences per the manual) rather than always starting from the default
  first level, and reports the game runs *slowly* when started this way.
  A concrete, checkable claim: find whatever selects a starting
  level/difficulty, and find what specifically slows the game down in
  that state -- a deliberate "practice/slow" mode, a side effect of
  however level-select is implemented, or something else.
* **Intermission animations exist, tied to specific level wins.** The
  user reports a couple of intermission (cutscene) animations, appearing
  after winning the Strawberry and Apple levels specifically. Classic
  Ms. Pac-Man's arcade cutscenes trigger after levels 2, 5, and 9 --
  worth checking directly against this port's own level-naming sequence
  (Teddy Bear/Cherries/Strawberry/Orange/Pretzel/Apple/Pear/Banana, i.e.
  Strawberry is the 3rd named level and Apple the 6th) rather than
  assuming the arcade's own numbering carries over unchanged.
* **The maze/level name sequence plateaus at Banana, not the manual's
  "random fruit."** The manual says the maze-naming sequence moves to
  "random fruit mazes" once Banana is exhausted; the user instead
  reports the display *stayed* on Banana after clearing that level. A
  concrete, checkable claim: find whatever advances the level-name/maze
  index, and see whether it genuinely caps out (clamped, not wrapping or
  randomizing) rather than assuming the manual's own description holds
  for this port. **RESOLVED -- see "The Banana lock, solved" below, and
  it turned out not to be a manual-vs-ROM divergence at all:** the
  "random fruit" mechanism is real and works as described; it's tied to
  the player's own title-screen starting-level choice in a way that
  produces a genuine always-Banana outcome specifically when Banana was
  that starting choice.

## First live pass: the fruit point-value table, found by grepping for `SED` and confirmed exactly against the manual

Went after the user's "Teddy Bear gave 50 points" hint directly, using
the same technique that opened up the Galaga project's own score
mechanism: grep the static disassembly for `SED` (BCD arithmetic) rather
than diffing RAM blindly. Only 4 sites in the whole ROM -- a short list,
not a haystack.

`rom:sub_F61A` is the score-add routine itself: it BCD-adds a staged
4-byte value into the current player's score (`Score`, `ram_0046-0049`,
or `Score2` for the other player). Only the low two bytes of that staged
value (`ScoreDeltaHi`/`ScoreDeltaLo`, `ram_00BB`/`ram_00BC`) are ever set
by any caller -- so every point award in this game funnels through just
those two bytes before the add happens.

Tracing backward from there to the actual award sites turned up two
paired lookup tables, both indexed by a small live counter and both at
the same x10-per-BCD-unit scale this project's Galaga sibling
independently discovered in its own score accumulator:

* **The fruit table** (`dat_E0EB`/`dat_E0F3`, indexed by
  `CurrentFruitType`, `ram_2116`) matches the manual's fruit-scoring
  table *exactly*, all 8 entries: Teddy Bear 50, Cherries 100,
  Strawberry 200, Orange 500, Pretzel 700, Apple 1,000, Pear 2,000,
  Banana 5,000.
* **The ghost-chain table** (`dat_E0E3`/`dat_E0E7`, indexed by
  `GhostChainCount`, `ram_00FE`) reads 200/400/800/1,600 -- the classic
  arcade Pac-Man ghost-eating progression, not stated in this port's own
  manual at all.

**Live-verified, not just read off the table.** A PC-tagged write-tap on
`ScoreDeltaHi`/`ScoreDeltaLo` across the Teddy Bear level in `run-02.inp`
caught the exact award: at frame 3,011, both bytes are set to `$00`/`$05`
(`CurrentFruitType` confirmed `0` at that instant) right as the
on-screen score jumps from 2,160 to 2,210 -- a clean +50. A screenshot
at that exact frame shows Ms. Pac-Man directly overlapping a distinct
brown, round, eyeless sprite at the ghost-house exit (all four ghosts
have the same two-eye pattern; this doesn't), consistent with the fruit
item itself. A second award later in the same recording (frame 7,372,
`CurrentFruitType` confirmed `1`) comes to exactly +100, matching the
table's Cherries entry. The first three ghost-chain values were also
caught live (frames 2,239/2,492/2,613), lining up with a "200"
score-popup screenshotted directly during the same search.

**What this doesn't settle:** what actually sets `CurrentFruitType` --
i.e. what decides which fruit appears when -- and whether it's capped at
7 (Banana) or can go higher. A separate byte this project had guessed
might be "the level index" (`ram_2124`, feeding a different, much
larger table via `rom:sub_E159`) turned out not to behave like a small
level counter at all when checked live (values like 47, 38, 111 showed
up, not a clean 0-7) -- that guess is retracted rather than left
standing; what `ram_2124` and its table actually are is still open. This
is the natural next step toward the user's third hint (whether the
level-name sequence really clamps at Banana).

## The Banana lock, solved: not a manual-vs-ROM divergence at all

Followed the natural next step straight through, and it turned out to
be a much better answer than "the manual is wrong about this port" --
the mechanism is exactly what the manual describes, and the user's own
specific playthrough triggered a genuine edge case of it.

`rom:sub_D508` is where `CurrentFruitType` gets chosen for a new level:
below wave 8, it's set directly to the wave number -- a clean march
through the 8 named fruits, matching the manual's own sequence. At wave
8 and beyond, the manual's own claim ("random fruit mazes") kicks in
structurally: a PRNG call, masked to 0-7, picks a fruit -- **but the
result has to satisfy `result >= FruitTypeFloor` (`ram_0040`, newly
named) via a rejection-sampling retry loop, or it's discarded and
re-rolled.**

`FruitTypeFloor` turns out to be the exact same byte the title screen's
level-select cursor writes to -- the "TEDDY BEAR" / "PRETZEL" / etc.
setting the user can cycle through with the joystick before starting a
game (`rom:sub_E85B` increments it up to a clamp of 7; `rom:sub_E86A`
decrements it down to a floor of 0). Whatever starting level the player
picks becomes a **permanent lower bound on every "random" fruit draw for
the rest of that game.** Starting from Banana (`FruitTypeFloor = 7`)
leaves exactly one value that can ever pass the retry check: 7. Every
wave-9-plus draw is Banana -- forced, not by chance.

**Live-confirmed and cross-validated across all four recordings**, each
one landing on a different point along the same mechanism:

| recording | starting level | `FruitTypeFloor` | fruit types seen post-wave-8 |
|---|---|---|---|
| `run-01` | Banana | 7 | **locked at 7 (Banana)** for the rest of the recording -- tens of thousands of frames, many waves |
| `run-03` | Pear | 6 | oscillates between 6 and 7 only -- the exact two values `>=6` |
| `run-04` | Pretzel | 5 | oscillates among 5, 6, 7 |
| `run-02` | Teddy Bear | 0 | genuinely varied (0, 1, 2, 3, 4, 6 all seen) -- the unconstrained case |

The pattern degrades exactly as the formula predicts as the starting
floor rises, from "fully random" at floor 0 to "always the same fruit"
at floor 7. **The manual's "random fruit" claim is true in general** --
this project's own earlier-flagged "discrepancy" was really just one
specific playthrough's starting choice producing a degenerate,
single-outcome case of a genuinely-random mechanism, not a bug, and not
a port divergence from the manual after all.

## The maze-change schedule, and a first data block resolved

The user suggested chasing the intermission hint might help classify
some of the day-one data blocks. It did -- for a different table than
the intermissions themselves, which are still unfound, but a real,
concrete result all the same.

`WaveCounter` advancing on every level clear turns out to have a
companion, `MazeScheduleIndex` (`ram_00A7`), which wraps from 14 back
down to 6 rather than to 0 -- so after an initial 0-13 run-up, it cycles
through 6-13 forever. It indexes `dat_D03A` (14 bytes:
`$FF,$FF,$00,$FF,$FF,$01,$FF,$FF,$FF,$02,$FF,$FF,$FF,$02`): `$FF` means
"keep the current maze," anything else is a real maze index passed to
`rom:sub_E0FB` to reload it. Reading the non-`$FF` positions directly:
**maze changes happen exactly at wave-index 2 and 5 -- Strawberry and
Apple, matching the user's hint precisely** -- plus two more at 9 and 13
(both loading maze 2) that weren't mentioned, plausibly because by wave
9+ `CurrentFruitType` has already left the named sequence and these
transitions may not carry the same visual weight. After wave 13, the
repeating 6-13 cycle keeps landing on maze 2 forever -- the maze stops
changing once the player is far enough in, the same "permanently
locked" shape as the Banana fruit mechanism above, just for maze layout
instead of fruit type.

A companion table (`dat_D02C`, feeding `MazeColorVariant`/`ram_00A5`)
cycles cleanly through all 4 values rather than mostly repeating --
possibly the actual "four different maze patterns" selector the manual
describes, not yet confirmed against what it controls on screen.

**A real data block resolved along the way:** tracing `rom:sub_E0FB`
led to `rom:sub_CD5E`, which copies `dat_CF51` -- one of the day-one
"mixed-signature" blocks this project couldn't classify further at the
time -- directly into `$1F00+`, the working display area Maria renders
from. Confirmed graphics/display-list data, not a jump or parameter
table. First concrete resolution of one of the nineteen originally-
unclassified small blocks.

**What's still missing:** the intermission animation itself, as
distinct from the maze-layout change. `sub_E0FB` (called at the same
transition points) reads as a general maze-reset/reload routine --
nothing yet identified inside it as cutscene-specific. The maze-change
schedule is a strong structural lead (it lines up with the user's hint
exactly), but it isn't the intermission itself until something more is
found.

## What's still open

* ~~Whether the two small-integer-signature blocks (`dat_E342`,
  `dat_EB75`) really are maze/level layout data~~ -- **PARTIALLY
  ANSWERED, and probably wrong as originally framed.** `dat_E342` is
  read via `rom:sub_E159`, indexed by `ram_2124` -- but `ram_2124` was
  checked live and does *not* behave like a small per-level index (see
  above), so this is more likely a different kind of table entirely
  (possibly per-object or per-frame data, given the values seen). Not
  maze layout in the "2D grid of wall/path tiles" sense originally
  guessed. What it actually is remains open.
* Whether the large graphics-signature block (`dat_C000`) really is
  character/sprite tile data -- not yet rendered or cross-checked
  against known 7800 graphics-mode bit-plane conventions.
* ~~What each of the nineteen smaller mixed-signature blocks actually
  is~~ -- **ONE RESOLVED.** `dat_CF51` is confirmed graphics/display-list
  data, copied into Maria's working display area at maze-load time (see
  "The maze-change schedule" above). The other eighteen remain open.
* Why no `GCC(c)1984`-style signature string turned up in the tail
  block, unlike both sibling 16K/32K projects that checked.
* Ghost behavior mechanics beyond what the manual states (chase/scatter/
  frightened timing, if this port implements anything beyond "turns
  blue when a pellet is eaten") -- entirely unconfirmed against the
  ROM's own bytes so far.
* ~~Actual point values for dots, power pellets, and ghosts~~ --
  **PARTIALLY ANSWERED.** The ghost-chain table is now found and mostly
  live-verified (200/400/800/1,600, see above). Dots and power pellets
  themselves are still unconfirmed -- the fruit/ghost tables were found
  first because `SED` search led straight to them; dot-eating almost
  certainly goes through the same `ScoreDeltaHi`/`ScoreDeltaLo` staging
  bytes but hasn't been traced to its own specific call site yet.
* Extra-life threshold, if one exists in this port.
* ~~The Teddy Bear level-select starting point, and what specifically
  slows the game down when starting from it~~ -- **PARTIALLY ANSWERED.**
  The level-select screen and the Teddy Bear fruit value are confirmed
  live (see above). What specifically makes the game run *slowly* when
  started this way is still open -- not yet investigated.
* ~~Where the intermission animations live, and whether they really do
  trigger after the Strawberry and Apple level wins specifically~~ --
  **PARTIALLY ANSWERED.** The maze-change schedule (`dat_D03A`) fires at
  exactly wave-index 2 and 5 -- Strawberry and Apple -- matching the
  user's hint precisely, a strong structural lead. What's still missing:
  the intermission animation itself, as distinct from the maze-layout
  reload; `rom:sub_E0FB` (called at the same transitions) reads as a
  general reset routine with nothing yet identified as cutscene-specific
  inside it.
* ~~Whether the maze/level name sequence genuinely clamps at Banana
  rather than moving to "random fruit" as the manual describes~~ --
  **RESOLVED, and not a manual-vs-ROM divergence at all.** See "The
  Banana lock, solved." The random-fruit mechanism the manual describes
  is real and confirmed; a rejection-sampling retry loop ties it to
  whatever starting level the player picked on the title screen,
  producing a degenerate always-Banana outcome specifically when Banana
  itself was the starting choice -- exactly the case in `run-01.inp`.
* What `ram_2124` and the large table it indexes (`dat_E342` onward)
  actually are, now that "level index into maze data" is retracted as
  the likely explanation.
* The private reference source stays unconsulted, per the plan -- see
  `README.md`.
