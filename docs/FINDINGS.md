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

**Update: the intermission animation itself, found.** It was sitting in
`rom:sub_E0FB` the whole time -- easy to walk past on a first read
because the same routine also handles the mundane "clear old sprites,
set the new maze index" housekeeping. Past that setup, it stores three
special actor sprites (`rom:sub_E168`, reading `dat_E348`/`dat_E34B`/
`dat_E354`/`dat_E35D` for slots 0/1/2) and then **blocks in a wait
loop** -- `JSR sub_CB25` (the general per-frame update) called
repeatedly until `ActorActiveFlags` (`ram_1D00`, newly named -- the same
per-actor "is this slot alive" array `rom:sub_EA36` also reads) reaches
zero. Only once that happens does `sub_E0FB` return and the normal
"load the next maze" sequence proceed.

**Live-verified, not just read off the code.** Screenshotted the actual
animation in `run-02.inp` at the Strawberry level win (frames
13,400-13,540, wave-index 2->3): a Pac-Man-like character and a
Ms. Pac-Man-like character with a ghost, moving across an otherwise
black screen with no maze walls -- the classic Ms. Pac-Man "hallway"
intermission. `ActorActiveFlags` reads `1` throughout that exact window
and drops to `0` at frame 13,510, right before the next screenshot shows
the new maze rendering in.

The other two milestone waves (9 and 13, both loading maze 2) run
through the identical code path and should trigger the same animation,
though the user only reported the Strawberry/Apple ones -- plausibly
because by wave 9+ the named fruit sequence has already ended (see "The
Banana lock" above) and those transitions are less memorable, not
because the mechanism differs.

## Why the Teddy Bear start "runs slowly" -- solved, and it's not a special mode

The last piece of the user's original three hints. The mechanism turned
out to connect directly to two things already found: the title-screen
level-select cursor (`FruitTypeFloor`) and `WaveCounter`.

`rom:CC01` (new game setup, right after the "ONE PLAYER" choice) copies
`FruitTypeFloor` -- the same byte the level-select cursor writes on the
title screen -- straight into `WaveCounter`. So choosing a starting
level on the title screen doesn't just pick a fruit icon and a maze
(as "The Banana lock" section above covers); **it seeds the real
difficulty/wave counter itself.** Choosing Teddy Bear starts the game at
`WaveCounter=0`, the very first wave of the game's normal progression --
there's no separate "practice"/"slow" mode bit anywhere in this.

`WaveCounter` was already known to drive the fruit-type and maze-change
schedules. It turns out it also drives movement speed, through a table
that hadn't been examined yet: `rom:sub_DAA7` clamps `WaveCounter` to a
max index of 19 and uses it to index `dat_DCF9` (20 bytes), landing in
`WaveSpeedPeriod` (`ram_00F3`, newly named). **`dat_DCF9[0]` -- wave 0,
i.e. the Teddy Bear start -- is `$C0` (192), by far the largest value in
the whole table** (next is `$B4`/180 at wave 1, then it falls into the
`$1E`-`$96`/30-150 range from wave 4 on).

`WaveSpeedPeriod` gets copied into `SpeedCountdown` (`ram_00DC`) every
time Pac-Man's actor is (re)spawned for a wave. `rom:sub_DC44` -- the
actual movement-cadence gate -- decrements `SpeedCountdown` once every
other frame and only fires a real movement step when the counter's
current value matches one of five fixed checkpoints in a pair of small
tables (`dat_DC6B`/`dat_DC70`). Since there are always exactly five
checkpoints no matter how big the starting period is, a period of 192
spreads those same five steps across far more real frames than a period
of 60 does -- directly, mechanically slower on-screen movement, not a
different code path or a distinct mode.

**Live-verified in `run-02.inp`** (the Teddy Bear-start recording): at
frame 2144, exactly where the recorded player's real game begins (after
an attract-mode demo round that cycles through unrelated wave values),
`SpeedCountdown` loads to 192 and visibly counts down 1 per 2 frames.
Later in the same recording, wave 4 loads a period of 90 (frame ~19,291)
and wave 5 loads 60 (frame ~21,369) -- each countdown visibly faster
than the last, confirming the period value really does behave as a
speed dial across the whole recording, not just at wave 0. Wave 0's 192
is the single slowest period in the entire table, which is exactly why
starting on Teddy Bear specifically stood out to the user: it's the
slowest tier of the game's ordinary per-wave speed curve, just reached
directly from the title screen instead of by playing through it.

This closes all three of the user's original gameplay hints, plus the
intermission-code half of hint 2 found separately above.

## Nailing down the data blocks

The user asked to push on the remaining unclassified data blocks. Of the
23 originally-declared blocks, this pass traced every caller for every
block that had one (most did -- only 4 tiny blocks turned out to have
*no* static caller anywhere), read the calling code, and cross-checked
the byte content against what that code does with it. Almost none of it
turned out to be a literal maze grid; instead this ROM's "level data" is
mostly the *machinery around* the mazes -- graphics-pointer tables,
collision math, actor-parameter tables -- with the actual maze wall
layout hiding in compact bitmap form inside the tail block.

**The real maze layout, found.** `rom:sub_FC18` indexes a 4-entry
pointer table by `MazeColorVariant` to get one of `$FCC8`/`$FD7C`/
`$FE30`/`$FEE4` (all inside the `dat_FC7C` tail block) and copies 128
bytes from there into `ram_1C00` (`MazeBitmapBuffer`, newly named) -- a
compact bitwise encoding of the maze's walls, one bit per cell.
`rom:sub_FC00` reads it a byte at a time and unpacks each byte's 8 bits
through `rom:sub_FBAA`, which uses `dat_FBBC`/`dat_FBDC` (autotile-style
lookup tables) to pick the correct wall-corner/edge tile code for each
bit position and pokes it into the screen's tile buffer via a pointer
that advances by 28 bytes (the maze's row width) per row. This is the
actual maze-layout data the user expected most of the ROM to hold --
just encoded as a compact wall bitmap decoded through an autotiler, not
stored as a literal per-cell grid the way the original guess assumed.
`dat_FBBC` and `dat_FBDC` hold the *same set* of tile-code values in
genuinely different orders (not a mirror of each other), consistent
with Ms. Pac-Man's mazes not being simple left-right mirrors the way
the original Pac-Man's was.

**This also fully overturns the original "maze data" guess.** Both
blocks originally guessed as small-integer maze/collision data
(`dat_E342`, `dat_EB75`) turned out to be something else entirely, once
their actual callers were traced instead of just their byte-frequency
signature:

* `dat_E342` is read by `rom:sub_E159` via `LDX ram_2124` with *no*
  index -- i.e. actor slot 0's own position byte, which `rom:sub_E0FB`
  sets to a small 0/1/2 maze-variant index right before calling this.
  `dat_E342` ($02,$04,$08 -- power-of-two flags) and sibling `dat_E345`
  ($03,$06,$09) select per-maze-variant type/flag parameters for the two
  actors `sub_E159` spawns. The many other small 3-entry tables declared
  across this whole 759-byte span follow the same shape and almost
  certainly supply the rest of the position/type parameters for the
  already-solved intermission animation (`rom:sub_E0FB`/`rom:sub_E168`,
  see above) -- this whole block is intermission-actor setup data.
* `dat_EB75`/`dat_EB8A` form a type-to-pointer table (low/high bytes)
  read by `rom:sub_EB3A`, part of the actor-management family around
  `sub_EA36`/`ActorActiveFlags`. Given an actor-type code, it produces a
  16-bit ROM pointer; the immediately neighboring `sub_EB1E` reads a
  similar pointer into `AUDV0` (the sound volume register), suggesting
  these per-type pointers lead to each actor type's own animation-and-
  sound script.

This also resolves the earlier retraction about `ram_2124`: `sub_DA32`
(called at game/life reset) copies a 4-entry initial-position table
(`dat_DCCD`/`dat_DCD1`) into `ram_2120,X`/`ram_2124,X` for the 4 actor
slots. `ram_2124,X` really is each actor's own live position coordinate
-- the original retraction was right that it's not a small level index,
but the large values seen live (47/38/111) are just the actor having
moved since its small reset value was set, not evidence against a
position byte at all.

**Everything else traced this pass, briefly:**

| Block | What it turned out to be |
|---|---|
| `dat_F52C`/`dat_F54B` | Per-row Maria graphics-pointer table (lo/hi), read live inside `ENTRY_Nmi`'s display-list construction every vblank. |
| `dat_F8C6` | Sprite/character-ID -> frame-group remap table, read by the shared sprite dispatcher `sub_F890` (~19 call sites). |
| `dat_DF21` | Per-maze-color-variant wall attribute/palette data, copied into the maze's color RAM by `sub_DE8B` -- likely the manual's "four maze patterns" in ROM form. |
| `dat_D614` | A 4-step (-1,-1,+1,+1) sub-pixel movement-smoothing delta cycle. |
| `dat_D3E1`/`dat_D3ED` | Per-direction/phase starting-offset table for (re)spawning an actor. |
| `dat_E0DD` | A 6-entry diamond-shaped collision-hitbox falloff table, shared by both the fruit-eating and ghost-collision distance checks. |
| `dat_F5A6` | The joystick raw-SWCHA-nibble to direction-code decode table. |
| `dat_E9F7` | The standard 4-direction (+1,0,-1,0) unit movement-delta table. |
| `dat_E8AA` | Per-ghost-slot staggered ghost-house release-delay thresholds (9/12/15/18) -- a first concrete hint at ghost-release timing. |
| `dat_DC6B`/`dat_DC70` | Already known from the speed investigation -- the movement-cadence checkpoint tables `sub_DC44` uses. |

**Left genuinely open, honestly:**

* `dat_E970` -- fills a 32-byte RAM buffer pair, contains embedded ROM-
  address-shaped byte pairs mixed with small integers; plausibly a HUD/
  attract-text row template, not decoded further.
* `dat_DE73` -- a 4x4 matrix with a distinctive -1-diagonal/+1-band
  shape, read inside actor-targeting math; plausible ghost-AI turn-bias
  table, not traced to a specific decision.
* Four tiny blocks (`dat_F83C`, `dat_E9BD`, `dat_E9D4`, `dat_D49B`) have
  **zero static callers anywhere** in the traced code, yet each decodes
  cleanly as a small, coherent 6502 routine (a graphics-pointer reader,
  a generic page-copy loop, an index-times-4 helper, and a bare `JMP`
  respectively). No indirect-jump instruction (`JMP (...)`/`JSR (...)`)
  exists anywhere in the code traced so far that could explain reaching
  any of them dynamically -- so each is flagged, not asserted, as either
  genuinely unreached/dead code or a coincidental decode of real data.
* `dat_C000` -- still just a byte-frequency guess (graphics/tile sheet),
  though two other candidate identities (maze bitmap, maze color data)
  are now ruled out by this pass, narrowing what it's left to be.

## Checking the ghost logic

Asked to check on the ghost behavior beyond what the manual states. This
turned into the richest single trace of the project so far -- most of
the classic arcade Pac-Man ghost AI is intact and identifiable in this
port, right down to the four ghosts' distinct targeting personalities --
and, unlike most of the data-block work, it didn't stay a purely static
trace: a probe (`tools/probe-ghostlogic.lua`) against `run-02.inp`
confirmed the core state machine live.

**Two independent per-ghost bytes drive everything**, both 4-slot arrays
(one entry per ghost, X=0-3):

* `GhostState` (`ram_2138,X`, newly named) -- the ghost's high-level
  situation: 0 = normal roaming, 1 = eaten, eyes heading back to the
  house, 2 = arrived at the door/re-entering, 3 = bobbing inside the
  house before settling, 4 = confined, waiting to be released.
* `GhostFrightFlag` (`ram_2140,X`, newly named) -- independent of state:
  `$00` = not frightened, `$08` = frightened and vulnerable (the exact
  value the eaten-ghost scoring check at `rom:E078` requires -- CONFIRMED
  by the code, not just a guess), `$10` = set immediately after this
  specific ghost gets eaten, as part of its own state-1 transition (an
  earlier working guess that `$10` meant a "flashing, about to expire"
  warning sub-state didn't survive closer tracing and is retracted here
  rather than left standing).

**LIVE-VERIFIED against `run-02.inp`.** All four `GhostFrightFlag`s flip
`0`->`8` in the same frame (frame 2144 -- the same frame the earlier
speed investigation identified as where real, non-attract-demo play
begins) -- a single, simultaneous fright-start event as predicted.
`GhostFrightFlag` hits exactly `16` at frames 2240, 2493, and 2614 --
matching, near-exactly (within a frame, from sampling at frame
boundaries), the three ghost-eaten events *already* live-verified
independently back when the ghost-chain point table was found (frames
2239/2492/2613, see `rom:E084`'s comment) -- two independently-derived
pieces of evidence landing on the same frames. `GhostState` for the
eaten slot then runs exactly the predicted cycle: `1` (eaten) -> `3`
(bobbing in house) -> `4` (confined) -> `2` (exiting) -> `0` (roaming
again) -- confirmed repeating multiple times across the recording (e.g.
slot 1 at frames 2240/2324/2435/2493/2665, then again at 5124 onward).
One nuance the live data added that the static trace alone didn't
distinguish: an eaten ghost's `GhostFrightFlag` clears back to `0` at
its own pace as it makes its way home (via the "arrived home" cleanup,
`rom:sub_D9FE`), not all at once -- which fits `rom:sub_DAF8`'s global
wrap-driven clear explicitly skipping `GhostState` 1 and 3 (already-
eaten/mid-transit ghosts), so only *still-roaming* ghosts are affected
by the global timer. `ChaseModeFlag` was also confirmed to genuinely
toggle `0`/`1` throughout the recording (first flips to `1` at frame
1435, matching wave-start, then keeps alternating roughly every
500-3,000 frames for the rest of the run) -- the scatter/chase handoff
mechanism is real and active, even though its duration schedule's
actual values remain unfound.

**The per-ghost movement dispatcher** (`rom:sub_D713`, called once per
ghost per movement step) picks a behavior in priority order: `GhostState
!= 0` always wins (head for the house door); then `GhostFrightFlag != 0`
(pure random wandering, `rom:sub_D72F`); then a single global
`ChaseModeFlag` (`ram_00FF`, newly named) decides between the real
targeting AI and an alternate mode.

**The real targeting AI (`rom:sub_D777`, `ChaseModeFlag`==0) replicates
all four arcade ghost personalities, keyed off the ghost's own slot
number:**

* Slot 0 ("Blinky", the fallthrough default): targets Pac-Man's current
  position directly, with an extra check that sets a nonzero speed-boost
  code as dots run low -- a plausible Cruise Elroy implementation, not
  yet live-verified as an actual speed change.
* Slot 1 ("Pinky"): targets a fixed offset ahead of Pac-Man in his
  current facing direction -- the textbook "ambush" algorithm.
* Slot 2 ("Inky"): targets *twice* the vector from Blinky's own position
  to a point ahead of Pac-Man -- the textbook double-vector algorithm,
  reproduced exactly (including using Blinky's live position as an
  input, the detail that makes Inky's behavior depend on where Blinky
  is, not just Pac-Man).
* Slot 3 ("Sue"/Clyde): measures actual distance from itself to Pac-Man
  for a distance-gated chase-or-flee decision -- the textbook
  Clyde/Sue algorithm.

**The alternate mode** (`rom:sub_D74A`, `ChaseModeFlag`!=0) is entered
once at the start of every wave (`rom:sub_DA32`) and is the shape of
scatter mode -- but only slots 2 and 3 get an actual fixed corner target
in this routine; slots 0 and 1 fall through to the same random-walk
primitive frightened ghosts use. Flagged rather than fully explained:
either a genuine simplification in this port, or a misattribution of
which slot maps to which ghost that a live check would clear up.

**Frightened mode starts and ends through two different, asymmetric
mechanisms.** It starts all at once: `rom:sub_DAC3` (power-pellet-eaten
handler, called from `rom:L_D1FD`) sets `GhostFrightFlag` to `$08` for
every eligible ghost in one shot. It ends *implicitly*, with no
independent countdown at all -- `rom:sub_DAF8`, called every time the
per-wave movement-cadence counter (`SpeedCountdown`/`WaveSpeedPeriod`,
the same mechanism the "runs slowly" investigation found) completes a
full cycle, clears `GhostFrightFlag` back to 0 for every eligible ghost.
Since `WaveSpeedPeriod` shrinks in later waves, this one piece of
plumbing produces *both* effects the manual and general Pac-Man
knowledge would predict independently: movement gets faster **and**
fright duration gets shorter as the game progresses, from the exact
same per-wave table (`dat_DCF9`) -- not two separate mechanics, one
elegant reuse.

**Mode switching (scatter<->chase) is a queued, timed handoff.**
`rom:sub_D69B` (once per frame) advances an elapsed-time counter pair
(`ram_00FB`/`ram_00FC`) and, once it crosses a scheduled target
(`ModeTimerTargetLo`/`Hi`, `ram_216C`/`ram_216D`), calls `rom:sub_DB35`:
sets `ChaseModeFlag` back to 0 (or, symmetrically, back to 1 next time)
and forces every ghost still roaming normally to reverse direction --
the classic arcade tell of a mode switch -- then shifts a single queued
next-duration (`ModeTimerNextLo`/`Hi`, `ram_216E`/`ram_216F`) into the
current target. The firing check isn't a clean 16-bit compare -- it's
two independent 8-bit gates ANDed together, with `ram_00FC` wrapping
0-255 repeatedly and `ram_00FB` only advancing on that wrap -- so once
`ram_00FB` first clears its threshold (permanently, since it only
grows), the effective trigger becomes "next time `ram_00FC`'s repeating
climb crosses its own threshold".

**UPDATE: the schedule's actual values, found and live-verified.**
`dat_DF21`'s per-maze-color-variant 32-byte blocks are dual-purpose --
their last 4 bytes double as the mode-timer's initial schedule seed,
copied into `ram_216C`-`ram_216F` by the exact same `rom:sub_DE8B` copy
that installs the wall-color/attribute data (see "Nailing down the data
blocks" above). Confirmed with a second probe
(`tools/probe-modeschedule2.lua`) against `run-02.inp`: for
`MazeColorVariant` 0, the seed is exactly `$07,$A4,$19,$54`, landing in
`ram_216C`-`ram_216F` at the observed wave-start frame (1435) --
matching the byte values hand-decoded from `dat_DF21` exactly. The
first two scheduled switches (at frames 4717 and 6651) consume that
seed pair, after which `rom:sub_DB35`'s own code resets `ModeTimerNext`
to the `$FF` sentinel -- but live data shows it getting **refilled**
anyway, alternating between `$01,$A4` and `$06,$54` at every subsequent
switch for the rest of the recording (16+ switches total, well past
what a 2-entry queue should allow). **Not found:** the refill's write
site. No instruction anywhere in the ~52% of code traced so far writes
anything but `$FF` into `ram_216E`/`ram_216F`, so whatever refills it
with real values lives in the ~48% not yet reached as code -- a
concrete, addressable lead (the exact bytes and timing are now known)
for whoever picks this up next.

**Ghost-house release has two mechanisms, not one.** The normal path
(found earlier) is `dat_E8AA`'s per-slot staggered thresholds
(9/12/15/18). This pass found a second, independent one:
`GhostReleaseTimeout` (`ram_00F8`) counts up against a `WaveCounter`-
scaled threshold (240 frames early, 180 later) and, once reached, force-
releases whichever of slots 1-3 is still confined -- a time-based
fallback distinct from the staggered threshold, matching the arcade's
classic dual dot-count/timeout release design (an earlier informal
guess had mislabeled this same routine as a "fright-mode duration
timer" before this pass traced it properly -- that guess never made it
into `annotations.json`, so there's nothing to retract there, but it's
worth naming as a wrong turn corrected before being written down).
Whether this port *also* has a dot-count-linked release wasn't found
this pass.

## What's still open

* ~~Whether the two small-integer-signature blocks (`dat_E342`,
  `dat_EB75`) really are maze/level layout data~~ -- **RESOLVED, and
  the answer is no.** See "Nailing down the data blocks" above: both are
  intermission-actor and actor-type-script parameter tables. The real
  maze wall layout lives in the `dat_FC7C` tail block as a compact
  bitmap, decoded via `dat_FBBC`/`dat_FBDC`.
* Whether the large graphics-signature block (`dat_C000`) really is
  character/sprite tile data -- not yet rendered or cross-checked
  against known 7800 graphics-mode bit-plane conventions. Two other
  candidate identities (maze bitmap, maze color/attribute data) were
  ruled out this pass, narrowing but not yet confirming it.
* ~~What each of the nineteen smaller mixed-signature blocks actually
  is~~ -- **MOSTLY RESOLVED.** 14 of the 19 traced to a real, callsite-
  confirmed identity this pass (see the table above), on top of
  `dat_CF51` resolved earlier. 4 tiny blocks remain genuinely open --
  no static caller exists anywhere, so their code-shaped byte content is
  flagged as a hypothesis, not a finding (see above).
* Why no `GCC(c)1984`-style signature string turned up in the tail
  block, unlike both sibling 16K/32K projects that checked.
* ~~Ghost behavior mechanics beyond what the manual states (chase/
  scatter/frightened timing, if this port implements anything beyond
  "turns blue when a pellet is eaten")~~ -- **MOSTLY RESOLVED.** See
  "Checking the ghost logic" above: all four ghosts' distinct arcade
  targeting personalities are identified and traced, along with the
  frightened-mode start/end mechanism, the scatter<->chase mode-switch
  handoff, and a second ghost-house-release mechanism -- and the core
  state machine (fright start/end, the eaten-ghost state cycle, the
  chase/scatter toggle) is now live-verified against `run-02.inp`, not
  just statically traced. The scatter/chase duration schedule's *initial*
  values are now found too (seeded from `dat_DF21`'s tail bytes -- see
  "Mode switching" above), though what refills the schedule after the
  first two switches is still an open, now precisely-scoped lead (known
  exact byte values and timing, just not the write site, which must be
  in the ~48% of code not yet reached). Also still open: the Cruise
  Elroy speed-boost effect (the code path is identified but not checked
  against an actual speed change); and whether ghost-house release also
  has a dot-count-linked trigger alongside the two timer-based
  mechanisms found.
* ~~Actual point values for dots, power pellets, and ghosts~~ --
  **PARTIALLY ANSWERED.** The ghost-chain table is now found and mostly
  live-verified (200/400/800/1,600, see above). Dots and power pellets
  themselves are still unconfirmed -- the fruit/ghost tables were found
  first because `SED` search led straight to them; dot-eating almost
  certainly goes through the same `ScoreDeltaHi`/`ScoreDeltaLo` staging
  bytes but hasn't been traced to its own specific call site yet.
* Extra-life threshold, if one exists in this port.
* ~~The Teddy Bear level-select starting point, and what specifically
  slows the game down when starting from it~~ -- **RESOLVED.** The
  title-screen level-select cursor seeds `WaveCounter` directly at game
  start, and `WaveCounter` indexes a per-wave movement-speed-period
  table (`dat_DCF9`) whose wave-0 entry is the single largest/slowest
  value in the table -- see "Why the Teddy Bear start 'runs slowly'"
  above, live-verified against `run-02.inp`.
* ~~Where the intermission animations live, and whether they really do
  trigger after the Strawberry and Apple level wins specifically~~ --
  **RESOLVED.** `rom:sub_E0FB` sets up three special actor sprites and
  blocks in a wait loop until they finish, called exactly at the
  wave-index 2/5/9/13 maze-change points (`dat_D03A`) -- live-verified
  with a screenshot of the actual animation and `ActorActiveFlags`
  (`ram_1D00`) tracking it frame-for-frame in `run-02.inp`.
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
