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

**Both of the two "left genuinely open" blocks from this pass got
resolved in a later pass** (pushed on directly rather than left as a
permanent hedge):

* `dat_E970` -- confirmed as part of a text-rendering subsystem.
  `ram_1800`/`ram_1A00` (its copy destinations) turned out to be generic
  1KB scratch RAM zero-cleared at boot and reused by multiple unrelated
  systems, not a dedicated array. The neighboring routine
  (`rom:sub_E94A`) confirmed the family: it reads a sibling table
  (`dat_FA1B`) byte-by-byte, subtracts a fixed offset to convert each
  into a small tile-code, and substitutes the same "blank" filler value
  for a zero/delimiter byte -- the shape of an encoded-message-to-tile-
  code string renderer (likely game-over/HUD text, given the
  neighboring code also touches `FruitTypeFloor` and branches on player
  number). The exact message content wasn't decoded.
* `dat_DE73` -- fully resolved as the ghost intersection turn-decision
  cost table. `rom:sub_DE2E` computes a preferred axis (horizontal or
  vertical, whichever has the bigger remaining distance to the target)
  as a direction code; `rom:L_DE15` then adds that code to each
  candidate exit direction at a junction and indexes this table for a
  small cost adjustment -- directions matching the preferred axis/sign
  score lowest (the table's `-1` diagonal). This is the concrete
  mechanism behind the classic Pac-Man ghost pathfinding rule ("lean
  toward the target on whichever axis is further off"), not just a
  vague "turn-bias" guess.

Four tiny blocks (`dat_F83C`, `dat_E9BD`, `dat_E9D4`, `dat_D49B`) still
have **zero static callers anywhere** in the traced code, yet each decodes
  cleanly as a small, coherent 6502 routine (a graphics-pointer reader,
  a generic page-copy loop, an index-times-4 helper, and a bare `JMP`
  respectively). No indirect-jump instruction (`JMP (...)`/`JSR (...)`)
  exists anywhere in the code traced so far that could explain reaching
  any of them dynamically -- so each is flagged, not asserted, as either
  genuinely unreached/dead code or a coincidental decode of real data.
  **UPDATE, much later in this document ("The orphan blocks, actually
  resolved"): live read-tapping settled it. Nothing in the cartridge
  ever reaches them -- that part of this note holds up -- but the
  Atari 7800 BIOS's own boot-time checksum routine reads all four,
  every session, entirely external to the game.**
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
`dat_DF21`'s 32-byte sub-blocks (one per wave, selected by `WaveCounter`
via a `dat_DFE4` remap -- **corrected here in place**: an earlier
version of this note said the block was also selected by
`MazeColorVariant`, which is wrong; closer reading of `rom:sub_DE8B`'s
tail shows `MazeColorVariant` is used *after* this copy for a
completely separate lookup, see below) are dual-purpose -- their last 4
bytes double as the mode-timer's initial schedule seed, copied into
`ram_216C`-`ram_216F` by the exact same `rom:sub_DE8B` copy that
installs the wall-color/attribute data (see "Nailing down the data
blocks" above). Confirmed with a probe (`tools/probe-modeschedule2.lua`)
against `run-02.inp`: for wave 0, the seed is exactly `$07,$A4,$19,$54`,
landing in `ram_216C`-`ram_216F` at the observed wave-start frame (1435)
-- matching the byte values hand-decoded from `dat_DF21` exactly.

**UPDATE 2: the apparent "refill" mystery, resolved -- it isn't a
refill at all.** The first two scheduled switches (at frames 4717 and
6651) consume that seed pair, after which `rom:sub_DB35`'s own code
resets `ModeTimerNext` to the `$FF` sentinel -- but live data showed it
getting new real values anyway, alternating between `$01,$A4` and
`$06,$54`. A prior pass flagged this as an unexplained gap ("no write
site exists in the traced code"), which was wrong -- it just hadn't
traced far enough. `rom:sub_DE8B` isn't game-start-only: it also runs
at *every* wave transition, reached through a second call path
(`rom:L_F6DA`/`rom:sub_CC73`, off the maze-clear sequence around
`rom:F6C6`) distinct from the game-start path found earlier. Each time
it runs, it re-seeds the *entire* mode-timer schedule fresh from that
wave's own `dat_DF21` sub-block -- not a partial refill of just
`ram_216E`/`ram_216F`. Live-confirmed with a third probe
(`tools/probe-schedulereseed.lua`): `WaveCounter` visibly advances
`0`->`1` at frame 6633, and `ram_216C`-`ram_216F` load wave 1's
`dat_DF21` tail (`$01,$A4,$06,$54`) at frame 6651 -- the very next
switch. Waves 1 and 2 happen to share an identical `dat_DF21` tail,
which is why the same pair of values kept reappearing and looked like a
2-value alternation rather than what it actually is: a fresh reseed
every wave.

**A genuine bonus find along the way:** `rom:sub_DE8B`'s tail, past the
main copy, does a *second*, independent lookup keyed by
`MazeColorVariant` (not `WaveCounter`): `dat_DFD1` -> `dat_DFC1`/
`dat_DFC2` -> `CruiseElroyThreshold1`/`CruiseElroyThreshold2`
(`ram_00F9`/`ram_00FA`, newly named) -- the exact two thresholds
`rom:sub_D777`'s Blinky/Cruise-Elroy check compares against (see
"Checking the ghost logic" above). This resolves where those thresholds
come from, left open in that earlier section: they're keyed by maze
color variant, not wave number directly. The actual speed-boost effect
itself is still not confirmed live against a real movement-speed
change.

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
**UPDATE: whether this port also has a dot-count-linked release,
resolved -- no.** `DotsEatenCount` (`ram_00AA`) is read in exactly two
places anywhere in this ROM: its own increment, and the Cruise Elroy
speed check. Never anywhere near `GhostReleaseTimeout`, `dat_E8AA`, or
the `GhostState`==4 release checks. This port's ghost-house release is
purely the two timer-based mechanisms above; there's no dot-count-
linked release the way the original arcade has.

## Dot and power-pellet scoring, found and live-verified

The one scoring question left open since the fruit/ghost-chain tables
were found: what actually happens when Pac-Man eats a dot or a power
pellet. It turned out not to go through `rom:sub_F61A` (the score-add
routine already found) via the same table-lookup shape the fruit and
ghost-chain paths use -- a grep for every `JSR sub_F61A` in the ROM
turns up only the 2 sites already documented. Dots and pellets go
through a third, simpler path instead: `rom:sub_F614`, which stages a
flat, un-looked-up point value directly and falls straight through into
`sub_F61A`.

`rom:sub_D1E5` reads the tile code at Pac-Man's own position (the same
tile buffer the maze renderer reads/writes, via `rom:sub_F5FF`) and
checks it: tile `$51` is a dot (10 points, a raw BCD delta of `1` at
the project's established x10 scale); tile `$52` or `$53` (checked
together by masking off the low bit) is a power pellet -- which calls
`rom:sub_DAC3` to start ghost-fright mode (see "Checking the ghost
logic" above) and awards a raw BCD delta of `4`, i.e. 40 points (not
the 50 a general Pac-Man expectation might predict -- the manual's own
fruit table never actually states a pellet value, so there was nothing
to contradict). Either way, control falls through into `rom:sub_D21C`,
which overwrites that tile with `$50` (the blank/filler code already
seen throughout `dat_FBBC`/`dat_FBDC`) so it can't be eaten twice,
advances `DotsEatenCount` (`ram_00AA`, newly named -- the same counter
the Cruise Elroy check reads), counts down `DotsUntilFruit`
(`ram_00AF`, newly named -- reaching empty triggers the fruit-
appearance routine, `rom:sub_D508`), resets `GhostReleaseTimeout` back
to 0, and advances a level-clear countdown.

**LIVE-VERIFIED against `run-02.inp`** (`tools/probe-doteat.lua`):
Score climbed by exactly 1 raw BCD unit per dot for 40 consecutive dots
while `DotsUntilFruit` decremented in perfect lockstep with
`DotsEatenCount` the entire way (their sum stayed constant at 56), then
jumped by more than 1 at frame 2144 -- the exact same frame
`GhostFrightFlag` was already independently confirmed flipping to `8`
for all four ghosts during the ghost-logic investigation. Two
independently-derived findings landing on the same frame again, same as
happened with the ghost-chain table earlier in this project.

## The extra-life threshold, found and live-verified

The last item on this project's original open-questions list.
`ExtraLifeCountdown` (`ram_004A`/`ram_004B`, newly named -- a 2-byte BCD
counter sitting immediately after `Score` in RAM) is seeded at game
start from the tail of `dat_D04C` (`$09,$99`, i.e. BCD `0999`) by
`rom:sub_CDD0` -- the same routine that zeroes the score itself, since
`dat_D04C`'s first 4 bytes are the score's own zeroed initial value and
the last 2 are this countdown's seed. Every score award (via
`rom:sub_F61A`) also subtracts the same points from this countdown in
the project's established x10-scaled BCD units; once it goes negative,
`rom:sub_F663` fires `rom:sub_F6E8` -- a bonus-life effect/jingle via
`rom:sub_EA36`. At the x10 scale, BCD `0999` is **9,990 points** -- close
to but not exactly the classic arcade's round 10,000, which is fine:
this port's own threshold is simply what it is. `rom:sub_F67E` is the
identical mechanism for player 2.

**LIVE-VERIFIED against `run-02.inp`** (`tools/probe-extralife.lua`):
`ExtraLifeCountdown` starts at exactly `0999` and decrements by the
exact point value of every scoring event seen -- 1 per dot, 4 at the
power-pellet frame (matching the newly-found 40-point pellet value
again), and larger drops matching each already-verified ghost-eaten
frame. The recording doesn't run long enough to see the threshold
actually cross zero, so the bonus-life trigger itself isn't observed
firing, but the countdown mechanism is fully confirmed. Not found:
which specific RAM byte holds the on-screen "lives remaining" count
that presumably increments when `sub_F6E8` fires -- it touches
`ram_00A3`/`ram_00A4`, but those are also reused as general level-
transition timing counters elsewhere, so they're likely just borrowed
for jingle/pause timing rather than being the lives counter itself.

## Cruise Elroy: a retraction, and the orphan blocks re-checked properly

The user pushed back on two points from the previous round, and both
pushbacks were right.

**The "live-confirmed Cruise Elroy activation" was wrong.** A prior
pass reported `ram_2144` (the Elroy speed code) for Blinky flipping
`0`->`1` at frame 21,685 in `run-02.inp` as proof the mechanism
activates in real play, and noted the observed value (1) didn't match
this project's own hand-read of `rom:D777`'s threshold branches
(expected 3 or 4) -- a "discrepancy left open." The user asked directly
whether that discrepancy might trace back to Elroy's requirement that
every ghost be out of the house first. Checking `rom:D777`'s code more
carefully turned up exactly that gate -- it checks `GhostState` for
slot 3 (the last-released ghost, standing in for all four) being `0`
before it even looks at the dots-remaining thresholds -- but that gate
turned out not to be the actual explanation. A follow-up probe cross-
checking `GhostFrightFlag` at the same frame showed it flipping to `8`
(frightened) on the *exact same frame* `ram_2144` flipped to `1`, and
both flipping back together later (`GhostFrightFlag` to `16`/eaten,
`ram_2144` to `0`). `ram_2144,X` is also written unconditionally by
`rom:sub_DAC3` (fright start) and `rom:sub_DAF8` (per-wave speed-
cadence wrap) -- nothing to do with Elroy at all. What got reported as
"Elroy activating" was a power pellet being eaten, full stop -- the
same RAM-slot-reuse trap this project has hit and documented before
(see `a7800-toolkit/docs/pitfalls.md`). Genuine Elroy activation (value
3 or 4) was never actually observed in this recording. Retracted in
place in both `annotations.json` (`rom:D777`, `rom:DEF7`) and here.

**The four orphan data blocks got a real second look, not a shrug.**
The previous round's "unresolved, likely dead code" verdict for
`dat_F83C`/`dat_E9BD`/`dat_E9D4`/`dat_D49B` rested on one check: no
`JMP`/`JSR` instruction targets them anywhere in the *disassembled
instruction text*. The user pointed out that's not the same as
checking for a RAM-vector-based indirect call, and asked directly
whether that had been checked. It hadn't -- so it was, properly, this
time: (1) a raw byte scan of the *entire* 16KB ROM (not just the
disassembled listing, since a hidden call could itself be sitting
inside a currently-misclassified data block) for `JSR`/`JMP` opcodes
with any of the four addresses as a literal operand -- **zero hits**;
(2) a scan for every occurrence of the `JMP (indirect)` opcode (`$6C`)
anywhere in the ROM, code or data alike, to catch a jump through a RAM
vector -- 14 raw hits, every one checked by hand and confirmed
coincidental (operand/data bytes that happen to equal `$6C`, e.g. the
low byte of address `$216C` inside real `CMP`/`LDA`/`STA` instructions
already traced, or bytes inside already-confirmed graphics/table data);
(3) a scan for the classic 6502 "RTS trick" (push a target address
minus one, then `RTS` into it) for all four addresses, both byte
orders -- no hits. This is a materially stronger negative result than
the original "grepped the listing" check, and it still comes up empty:
there is no indirect-call mechanism of any common shape anywhere in
this ROM. The four blocks remain flagged as unresolved rather than
resolved-by-elimination -- a real absence of evidence, not proof there
isn't some other mechanism this search didn't think to check for.

## The orphan blocks, actually resolved: it's the BIOS, not the game

The user's next question cut straight through all of the above: forget
searching for a caller in the ROM's static structure -- do any of the
recordings actually *reach or read* these bytes at all? That's a
directly answerable, empirical question, and a technique this project
hadn't used before answered it: `mem:install_read_tap` on each block's
exact byte range, run live against all 4 recordings, watching for any
touch at all rather than searching for a textual caller.

**Yes -- every recording reads all four blocks**, identically
(down to the exact hit count) regardless of the recording's length,
early in each run (roughly frame 14-160). That immediately rules out
"unreached dead code" as the explanation. What it actually is took one
more step to pin down. The read-tap's own reported PC was a constant,
suspicious-looking value (`$2404`, a RAM address) for every single hit
across all four blocks -- not a tap-timing artifact, it turned out:
peeking the stack at the moment of each read (the return address left
by whatever `JSR` got here) traced it to a real, live piece of 6502
code sitting *in RAM* at `$23FF`, called from a small dispatcher also
in RAM (`$238F`, `$23B7`, ...). That RAM code is self-modifying -- one
operand byte (which 256-byte ROM *page* to sweep) gets patched before
each call, observed live patched to `$E9`, `$F8`, and `$D4` across
different invocations -- sweeping an entire page byte-by-byte into an
accumulator and a lookup table. The shape of a checksum or integrity
pass, not meaningful execution of any one block's bytes as
instructions.

Tracing the RAM template itself back to its ROM source settled it
completely: its bytes match a fixed offset (1279) inside the actual
Atari 7800 **system BIOS** ROM file (`7800ntsc.u7` / `7800 BIOS (U).rom`
in the sibling `bios/` directory), confirmed by direct byte comparison,
not present anywhere in Ms. Pac-Man's own cartridge ROM. This is
BIOS-level cartridge-checksum code, copied into RAM and run once at
boot, sweeping several ROM pages (including the pages these four
blocks happen to sit on) -- entirely external to the game's own logic.

So the original "no caller found anywhere in this ROM" conclusion was
right about what it claimed (no in-cartridge caller exists -- confirmed
again here, since the JSR sites are in RAM, not ROM) and stays true;
it just wasn't the complete answer to whether the bytes get touched at
all. They do, every time, just never by the game. Not pursued further:
exactly what the BIOS's checksum is protecting or verifying, since
that's BIOS behavior and out of scope for a cartridge disassembly.

**One more question worth answering, even for code the game never
runs: what would each block actually *do* in relation to the game, if
it somehow executed?** None of the four turned out to be mysterious --
each fits cleanly into a system already found elsewhere, reading like
superseded utility code rather than a distinct, undiscovered feature:

* `dat_D49B` (`JMP $D5B9`) sits in reset-adjacent code, right next to
  another reset jump (`L_D498`). `$D5B9` is `rom:sub_D5B9`, a real,
  already-called routine -- part of the same wave-transition chain
  (`sub_CC73`) traced earlier -- that zeroes `ram_2110` and resets two
  position-scratch bytes to `$B0`. Executing this would just
  redundantly re-run a reset the game already performs through its
  normal path.
* `dat_E9BD` (the generic page-copy loop) copies N*256 bytes between
  two pointers using the same scratch-pointer convention (`$B0`-`$B3`)
  the tile-buffer and graphics-pointer routines use elsewhere -- but
  sized far bigger than anything the shipped game's actual bulk copies
  need (the maze bitmap load is 128 bytes, the display-list graphics
  copy ~88 bytes, both hand-unrolled fixed loops). Reads like a
  general-purpose copy utility superseded once the real data sizes
  were known.
* `dat_E9D4` (`X*4+24`) is the most concrete of the four: every per-
  actor array in this game (`GhostState`, `GhostFrightFlag`, the Elroy
  speed code) is 4 bytes apart, one byte per actor slot -- and `+24`
  lands exactly on `ram_2148`, a real, heavily-referenced (13 sites)
  per-actor array in that same block. Called with an actor slot in X,
  it would compute "the address of actor X's `ram_2148` slot" -- a
  reusable version of the `TXA`/`ASL A`/`ASL A` idiom the game writes
  inline elsewhere for other offsets in this same array stack.
* `dat_F83C` (the row-pointer lookup) reads the *same* per-row Maria
  graphics-pointer table (`dat_F52C`/`dat_F54B`) the NMI display-list
  builder uses, staging the result into `ram_00B0`/`ram_00B1` -- the
  same generic pointer pair `rom:sub_F5E9`/`rom:sub_F5FF` (tile
  read/write) and `rom:sub_F890` (sprite lookup) all consume. Called
  with a row index in Y, it would seed that pair ready to feed straight
  into one of those routines.

## Chasing the lives-remaining counter: a real search, a real dead end, and a bonus find

Pushed on the lives-remaining counter next. A screenshot of `run-02.inp`
confirms the manual's 5-lives claim visually -- 4 small icons at the
bottom-left (the "extra lives in reserve" the user pointed out reading
the icon row correctly), consistent with 5 total including the one in
play.

**The counter itself was not found, despite real effort, not a shrug.**
There's no `LDA #$05` (or `#$04`) anywhere in the ROM as a plausible
literal constant. A live baseline-and-diff scan of `ram_0040`-`ram_00FF`
at the moment real play begins turned up exactly one candidate matching
the expected value: `ram_0067 = 5`. A decisive test settled it: live-
patching `ram_0067` to `1` mid-recording and screenshotting immediately
before and after showed *no change* in the on-screen icon row -- ruled
out cleanly, by fault injection rather than by guessing. The lives
icons also don't appear to be spawned via a counted loop into
`rom:sub_EA36` (no such loop exists anywhere in the traced code) the
way a first guess might expect. Genuinely unresolved.

**A real, verified bonus find turned up along the way.** Tracing
`rom:sub_CCF9` (called right alongside the score-digit HUD renderer)
turned up `FruitTrayCount` (`ram_0084`, newly named) = `min(WaveCounter,
7) + 1` -- the classic Ms. Pac-Man "fruit tray": a row of icons at the
bottom-*right* (distinct from the lives icons at bottom-left) showing
every fruit type encountered so far this game. `rom:sub_CEAB` draws one
fixed icon plus `FruitTrayCount - 1` more from an 8-entry position
table, each spaced 24 pixels apart. **Live-verified**: a screenshot at
frame 2,200 (wave 0) shows an empty tray; a screenshot at frame 21,500
(wave 5) shows exactly 5 fruit icons, matching the formula precisely.

## UPDATE: the lives counter, actually found -- by tracing forward, not hunting

The user asked directly what the extra-life counter increments once
triggered. That question changed the search strategy -- instead of
scanning RAM for a byte matching an expected value (which had already
failed once, on `ram_0067`), trace *forward* from the one place already
known to increment on a bonus life: `rom:sub_F6E8`. That led straight
to `LivesRemaining` (`ram_00A4`, newly named) -- the same byte the
"real dead end" above had already touched and specifically dismissed
as "just a timing counter." That dismissal was wrong, and is corrected
in place in `annotations.json` (`rom:CA95`, `rom:F663`, `rom:CDEE`)
rather than quietly fixed.

`rom:sub_F79E` is the lives-icon renderer: clamps `LivesRemaining` at
5 and draws that many icons -- called at game start, during the post-
death pause sequence, and right after the extra-life jingle. **Live-
verified against `run-01.inp`** (`tools/probe-livesfound.lua`,
`tools/probe-livescross.lua`): `LivesRemaining` starts at 4 (matching
the icon tray), visibly drops across several deaths in the recording
(4->3->2->1), then **increments from 1 to 2 at frame 8,794** -- the
exact same frame `ExtraLifeCountdown` is seen resetting from a just-
crossed-zero value to a fresh ~9,962-point countdown, i.e. the extra-
life trigger firing live, in the same recording, cross-confirmed by
two independent bytes changing on the same frame. Later in the same
recording, `LivesRemaining` wraps from 0 to `$FF` (negative) on a final
death, triggering the game-over/respawn sequence before resetting to 4
for the next game -- the complete lives lifecycle, all live-verified
in one recording.

**Direct answer to the question asked**: once the extra-life trigger
fires, it increments `LivesRemaining` (`ram_00A4`) -- the exact same
counter the on-screen lives-icon row is drawn from, clamped at 5 icons
and redrawn by `rom:sub_F79E` every time it changes.

## Pushing on dat_C000: narrowed, not confirmed

Tried to settle the last big open item -- whether the large graphics-
signature block (`dat_C000`, 2,592 bytes) really is character/sprite
tile data -- using the toolkit's `dlwalk.py` against a live dump of
Maria's actual working display list (`ram_1F00`+, captured mid-game).

The maze wall row decodes as a real, legible display-list entry:
indirect character mode, 28 characters wide (matching the maze's known
row width), with its "graphics" pointer at `$1B10` -- which turned out
to be the *tile-code* buffer `rom:sub_F5E9`/`rom:sub_F5FF` already read
and write (the already-fully-solved autotile system), not raw pixel
data. That rules `dat_C000` out as the direct source for the maze
walls specifically.

For indirect character mode, the actual bitmap for each tile code
comes from `CHARBASE` (per the toolkit's own hardware docs: address =
`((CHARBASE + line) << 8) | character_number`). `CHARBASE` is written
exactly once anywhere in this ROM (`rom:CBE1`, to `$22`), which points
into RAM (`$2200`-`$29xx` across the character's scanlines) -- not
`$C000`. So under the one `CHARBASE` setting this game ever uses, its
indirect-mode character bitmaps aren't fetched directly from
`dat_C000` either. No bulk copy loop targeting that `$2200`-`$29FF`
range turned up to suggest a ROM-to-RAM relocation the way `dat_CF51`
and the maze bitmap both use.

Net result: narrowed, not confirmed. `dat_C000` is not the maze walls
and doesn't appear to be reached via the game's one `CHARBASE` setting
either -- still an open graphics-signature guess, just with two more
specific identities ruled out by live tracing rather than left
untested.

## dat_C000, actually confirmed as graphics -- found with the user, live, from a published page

The push above narrowed dat_C000 by elimination three times without
ever landing a positive identification. That changed once the
rendering attempts were published as a page and the user started
reading the images back directly -- catching real signal a
byte-frequency histogram alone couldn't surface, and steering the next
decode attempt with specifics ("the top almost looks like 4 ghosts",
"every other column is dead black or grey, try 8 bits/pixel") rather
than a vague "keep trying."

That feedback pointed at a 240-ish-row-10-to-20 range in a 24-bytes/row
rendering. Pulling the corresponding bytes and inspecting them directly
(not just rendering and eyeballing) found something decisive: **every
byte in a clean 242-byte run (`rom:C0D2`-`rom:C1C4`, offset 210-452 into
the block) is built entirely from 2-bit pairs that are binary `00` or
`11` -- never `01` or `10`.** That's not a rendering artifact or a
lucky guess at width -- it's a structural property of the bytes
themselves, independent of any width/orientation choice, and it means
only 2 of the 4 possible palette indices are used anywhere in that run:
the signature of genuine 2-color (not 4-color) graphics data, not a
coincidental byte pattern. Decoded at 2 bits/pixel, 24 bytes/row, in
clean black-and-white (since only those 2 indices ever appear), that
run shows four rounded-top, scallop-bottomed silhouettes -- ghost-
shaped -- matching exactly what the user had already spotted in a
noisier 4-level rendering.

The same binary-pair property holds for 48% of the bytes across the
*whole* 2,592-byte block (scattered, not one continuous run), with two
other substantial clean runs at `rom:C825`-`rom:C8ED` (200 bytes) and
`rom:C948`-`rom:CA20` (216 bytes, running right up to the `RESET`
vector) not yet independently rendered. The shapes' internal
"dashed"/textured look, rather than a solid fill, is most likely
deliberate checkerboard dithering rather than a decode error still
being slightly wrong -- this block's two single most common bytes
overall (`$55`, `$AA`) are themselves perfect alternating-bit patterns,
consistent with a 2-color dither used to fake an intermediate shade on
real hardware.

This is the first *positive* confirmation dat_C000 has had, after three
rounds of purely eliminative narrowing. Still open: the shapes show
mild residual diagonal drift (24 bytes/row is close but maybe not
exactly the right stride), exactly which game element these four
silhouettes are, and whether the other two clean runs decode as
cleanly once actually rendered.

**A follow-up push found more real structure without landing a final
clean image.** The user raised a specific, testable hypothesis: that
this might be several bit-planes stacked for a palette-driven animation
effect (cycling which plane "counts" via a palette change) rather than
one wide static image. Decomposing the confirmed 240-byte grid by its 4
constituent bit-pairs (instead of reading all 4 across as one row) as a
direct test of that turned up two more robust, reproducible facts: bit-
pair 0 (the top 2 bits of every byte) is exactly 0% set across all 240
bytes with zero exceptions -- one of the 4 conceptual "planes" is
entirely unused throughout this run -- and, independently, every 6th
byte (position 5/11/17/23 within each 24-byte row) is exactly `$00`,
meaning each row is really four 6-byte sub-groups (5 meaningful bytes +
1 blank/terminator), matching the "4 ghosts" read exactly as 4 separate
small graphics rather than one continuous image. Isolating each 5x10
sub-graphic individually (at the fuller 6-bit range those bytes
actually use, since the top 2 bits are unused) shows a rounded-top,
wider-middle, blocky-bottom silhouette consistent with a ghost outline,
but no clean internal detail (no obvious eyes) emerged at this
resolution. Whether the always-unused top bit-pair is a genuinely
unused 4th animation-frame slot, a hardware-reserved bit range, or just
this sprite not needing the full value range is still open.

## dat_C000 fully solved: it's the font, found by reading the intermission code

Every previous round on `dat_C000` guessed at pixel formats -- bit depths,
row widths, orientations, plane layouts -- and got closer without ever
landing it. The user cut that off with the right instruction: *"you will
need to see how the intermission code interprets and uses the images."*
That was exactly right, and it solved the block outright in one pass.

`rom:sub_E168` (the intermission setup, already known from the
live-verified cutscene work) calls `rom:sub_F890` twice before spawning
its actors. Reading `sub_F890` properly, it isn't a sprite-graphics
routine at all -- it writes a horizontal run of **tile codes** into the
same shared tile buffer the maze autotiler uses (`rom:sub_F5E9`),
driven by four parallel tables: start offset, length, screen row,
screen column. Its two source tables decode as plain English:

| | |
|---|---|
| `dat_F952` | `BLINKY` `PINKY` `INKY` `SUE` `MS PAC-MAN` `COPYRIGHT ATARI 1984` `WITH` `STARRING` `USE JOYSTICK TO` `CHANGE SETTINGS` `PLAYER ONE` `PLAYER TWO` `ONE PLAYER` `TWO PLAYER` + a 5-row title-logo tile grid |
| `dat_FA1B` | `TEDDY BEAR` `CHERRIES` `STRAWBERRY` `ORANGE` `PRETZEL` `APPLE` `PEAR` `BANANA` `ACT 1` `ACT 2` `ACT 3` `THEY MEET` `THE CHASE` `JUNIOR` `READY!` `GAME OVER` |

The eight fruit names appear in exactly the order of the fruit
point-value table found on day one. And the intermission calls resolve
precisely: variant 0 -> **"ACT 1" / "THEY MEET"**, variant 1 -> **"ACT 2"
/ "THE CHASE"**, variant 2 -> **"ACT 3" / "JUNIOR"** -- the arcade
Ms. Pac-Man intermission titles, read straight out of this ROM's bytes,
independently confirming the three-intermission structure that was
live-verified earlier from the other direction.

**The tile map, and where `dat_C000` fits.** The strings gave the
encoding directly: `$50`=space, `$51`=dot, `$52`/`$53`=power pellet,
`$54`-`$5D`=`0`-`9`, `$5E`-`$77`=`A`-`Z`, `$78`=`!`, `$7A`=`-`, and
`$7B`+ = maze wall pieces and title-logo tiles. Note `$51`/`$52`/`$53`:
those are *exactly* the dot and power-pellet codes the dot-eating
detector checks for, and `$50` is the blank it overwrites them with --
an independent cross-confirmation from a completely different
investigation.

Each tile's bitmap lives at **`rom:C0C0` + (tile - `$50`) x 6** -- five
bytes of 4-pixel-wide 2bpp data plus one pad byte. Rendered as a sheet,
that produces a fully legible font: digits, the complete alphabet,
punctuation, then the grey maze-wall autotile pieces. Rendering the
title-screen tile grid reproduces the **"MS PAC-MAN" logo**.

**This explains every earlier dead end at once.** The block is a
sequence of 6-byte glyph cells, so *any* arbitrary row width slices
across glyph boundaries -- at 24 bytes/row you see exactly four glyphs
per row, which is precisely the "4 ghosts" that were actually four
letters. Only 2 of 4 palette values ever appear because the font is
monochrome. The "every 6th byte is `$00`" discovery was the glyph cell's
own pad byte. Even the earlier `CHARBASE` puzzle fits: the game copies
this tile set into RAM and points `CHARBASE` there, which is why the
register never points at `$C000` directly.

Still open, and much smaller now: the 192 bytes at `rom:C000`-`rom:C0BF`,
before the `$50` tile sequence begins, are not part of the character set
and remain uncharacterised.

## What's still open

* ~~Whether the two small-integer-signature blocks (`dat_E342`,
  `dat_EB75`) really are maze/level layout data~~ -- **RESOLVED, and
  the answer is no.** See "Nailing down the data blocks" above: both are
  intermission-actor and actor-type-script parameter tables. The real
  maze wall layout lives in the `dat_FC7C` tail block as a compact
  bitmap, decoded via `dat_FBBC`/`dat_FBDC`.
* ~~Whether the large graphics-signature block (`dat_C000`) really is
  character/sprite tile data~~ -- **FULLY RESOLVED.** It is the game's
  character set: font glyphs (`0`-`9`, `A`-`Z`, punctuation) plus the
  maze wall and title-logo tiles, at `rom:C0C0` + (tile-`$50`)x6, six
  bytes per glyph. Found by tracing the intermission's text renderer
  rather than guessing pixel formats -- see "dat_C000 fully solved"
  above. Only the 192 bytes before `rom:C0C0` remain uncharacterised.
  *(Superseded earlier note:)* **CONFIRMED, partially.** See
  "dat_C000, actually confirmed as graphics" above: a 242-byte run
  (`rom:C0D2`-`rom:C1C4`) is structurally proven to be genuine 2-color
  graphics data (every byte's 2-bit pairs are binary `00`/`11`, never
  `01`/`10`), decoding into four ghost-shaped silhouettes -- found
  collaboratively with the user reading a published rendering page
  directly rather than a byte-frequency guess. Still open: two more
  clean runs in the same block not yet rendered, exactly which game
  element the silhouettes are, and the mild residual diagonal drift
  suggesting the row width isn't quite exact yet.
* ~~What each of the nineteen smaller mixed-signature blocks actually
  is~~ -- **RESOLVED.** 14 of the 19 traced to a real, callsite-
  confirmed identity in the data-blocks pass (see the table above), on
  top of `dat_CF51` resolved earlier. The remaining 4 (`dat_F83C`,
  `dat_E9BD`, `dat_E9D4`, `dat_D49B`) have no caller anywhere in this
  cartridge's own code -- confirmed twice, by two different techniques
  -- but live read-tapping settled what actually touches them: the
  Atari 7800 system BIOS's own boot-time cartridge-checksum routine,
  copied into RAM and run once per session, external to the game
  entirely. See "The orphan blocks, actually resolved" above.
* Why no `GCC(c)1984`-style signature string turned up in the tail
  block, unlike both sibling 16K/32K projects that checked.
* ~~Ghost behavior mechanics beyond what the manual states (chase/
  scatter/frightened timing, if this port implements anything beyond
  "turns blue when a pellet is eaten")~~ -- **RESOLVED.** See "Checking
  the ghost logic" above: all four ghosts' distinct arcade targeting
  personalities are identified and traced, along with the frightened-
  mode start/end mechanism, the scatter<->chase mode-switch handoff
  (including its full duration schedule, seeded fresh every wave from
  `dat_DF21`), and two independent ghost-house-release mechanisms --
  all live-verified against `run-02.inp`, not just statically traced.
  The Cruise Elroy speed-boost thresholds are also now found (keyed by
  `MazeColorVariant`, see "Mode switching" above), it's gated on
  `GhostState` for slot 3 (the last-released ghost) being fully out of
  the house before it even checks the dots-remaining thresholds, and
  its speed mechanism is traced: the code (`ram_2144,X`) is a Y-index
  into the same `ram_2150`+ block used for wall color and the mode-
  timer, sampling one bit per tick to gate whether the ghost's movement
  decision runs at all -- a duty-cycle throttle, not a distinct code
  path (see `rom:DEF7`'s comment). **A live-verification claim here was
  wrong and has been retracted in place** (see "Cruise Elroy: a
  retraction" below) -- genuine activation is still unconfirmed live.
  ~~Whether ghost-house release also has a dot-count-linked trigger~~ --
  **RESOLVED, no.** `DotsEatenCount` is read in exactly two places in
  this whole ROM, neither near the release code -- this port's release
  is purely the two timer-based mechanisms already found.
* ~~Actual point values for dots, power pellets, and ghosts~~ --
  **RESOLVED.** The ghost-chain table (200/400/800/1,600) and the fruit
  table were found first and live-verified. Dots (10 points) and power
  pellets (40 points) were the last piece -- see "Dot and power-pellet
  scoring, found and live-verified" above -- also live-verified, and
  tied directly into the already-solved ghost-fright-start mechanism.
* ~~Extra-life threshold, if one exists in this port~~ -- **RESOLVED.**
  9,990 points (BCD `0999` at the project's x10 scale), live-verified.
  See "The extra-life threshold, found and live-verified" above.
* ~~Which RAM byte holds the displayed lives-remaining count~~ --
  **RESOLVED.** `LivesRemaining` (`ram_00A4`) -- found by tracing
  forward from the extra-life trigger instead of hunting for a byte
  value (the first attempt, `ram_0067`, had already been ruled out by
  fault injection). Live-verified across a full lives lifecycle in one
  recording: starts at 4, drops on several deaths, increments on a
  live-confirmed extra-life award, and wraps negative on the final
  death. See "UPDATE: the lives counter, actually found" above. A real,
  verified bonus find (the fruit tray, `ram_0084`) also came out of the
  search.
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
