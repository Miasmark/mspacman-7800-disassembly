# Ms. Pac-Man (Atari 7800) disassembly

A byte-identical disassembly and memory-map investigation of *Ms. Pac-Man*
(NTSC, Atari, 1987), built with
[a7800-toolkit](https://github.com/Miasmark/a7800-toolkit) and MAME as a
live-verification instrument, not just a static reader.

**This repo does not contain the ROM.** Supply your own legally-owned dump
(`Ms Pac-Man (NTSC) (Atari) (1987) (E42FC700).a78`, alongside a 7800 BIOS)
to reproduce anything here. The disassembly listing itself (`src/rom.asm`)
isn't committed either -- it's fully generated from
[`annotations.json`](annotations.json) plus the ROM, and regenerating it is
one command (below).

## Start here

[`docs/FINDINGS.md`](docs/FINDINGS.md) is the real deliverable: a narrative
of what's been confirmed live in MAME, what's still just a hint, and what
was actively distrusted, tested, and in several cases retracted rather
than assumed. [`annotations.json`](annotations.json) is the
machine-readable form of the same knowledge.

Every byte of the ROM is classified as code or a declared data block, and
all 23 data blocks are identified. Solved and live-verified: the full
ghost AI (all four arcade targeting personalities, frightened mode, the
scatter/chase timer, two ghost-house release mechanisms), every scoring
path (dots, power pellets, fruit, ghost chains, the 9,990-point extra
life), the per-wave speed curve, the fruit and maze progressions, the
three intermissions, and the complete character set -- font glyphs plus
maze, pen and title-logo tiles.

The wrong turns are deliberately left in place next to the corrections,
because several of them were the most instructive part of the work: a
"live-verified" claim that turned out to be two routines writing the same
RAM slot, a confident "MARIA must be DMA-ing this" inference undone by an
indirect load, a "solved completely" that covered less than half the block
it claimed, and a day-one anomaly that was really a false negative from
searching only the first few bytes.

A privately-held, unlicensed historical source for this game exists (the
same archive the sibling projects' reference sources came from), and was
handled the way those projects settled on: held off until the independent
work was substantially complete, then used strictly as a check -- never as
the origin of a finding, never quoted or copied in. That cross-check has
now been done and is written up at the end of `docs/FINDINGS.md`: broad
corroboration (the character set, the text renderer, all four ghost
targeting personalities, the fruit-selection floor), one apparent
disagreement that dissolved on closer questioning and left the ROM reading
standing, and one genuine numeric difference left unreconciled rather than
forced to agree.

Working discipline, same as the sibling projects: every claim about what a
byte range does should be checked live before it's trusted, not just
pattern-matched from a probe script carried over from a previous project.
Every `annotations.json` change is followed by JSON validation, `disasm.py`
regeneration, and a `verify.py` byte-identical round-trip check.

## Reproducing it

```
# from this directory, with the toolkit checked out as a sibling (adjust
# the path below to wherever you have it) and your own ROM copy dropped in:

python3 ../a7800-toolkit/tools/disasm.py "Ms Pac-Man (NTSC) (Atari) (1987) (E42FC700).a78" -c annotations.json -o src
python3 ../a7800-toolkit/tools/verify.py "Ms Pac-Man (NTSC) (Atari) (1987) (E42FC700).a78" -d src
# -> ROUND-TRIP PASSED
```

`src/rom.asm` is then a full listing, byte-identical when reassembled.

Add `--gaps` for a text report of every byte reached as neither code nor a
declared data block, or `--map` for the same picture as a heatmap (green
code, blue declared data, red gap -- needs Pillow):

```
python3 ../a7800-toolkit/tools/disasm.py "Ms Pac-Man (NTSC) (Atari) (1987) (E42FC700).a78" -c annotations.json -o src --gaps --map
```

![Coverage map](docs/img/coverage-map.png)

## Recording a session

Live findings in this project come from replaying a MAME input
recording (a deterministic button-press log, not video, and not
copyrighted content) against a PC/frame-tagged Lua probe -- the same
technique the sibling projects used throughout. Four recordings
(`run-01.inp` through `run-04.inp`) are committed here, and most live
findings cite specific frames in one of them -- they're what makes the
claims in `docs/FINDINGS.md` reproducible rather than assertions.

```
./"Record Session.command"        # play, Esc to stop -> next free run-NN.inp
./"Play Recording.command" run-01 # watch a recording play back
```

Manual (mechanics reference, scoring table, ghost behavior):
https://atariage.com/manual_html_page.php?SoftwareID=2142

## Layout

| | |
|---|---|
| `annotations.json` | The recipe. Feed it to `disasm.py` to get the listing. |
| `docs/FINDINGS.md` | The narrative -- read this first. |
| `docs/img/` | `coverage-map.png` (regenerate with `disasm.py --map`). |
| `tools/` | This project's own probe scripts. |
| `Play Recording.command`, `Record Session.command` | Double-click launchers for replaying/recording a session (macOS + MAME on `PATH`). |

Not committed (see `.gitignore`): the ROM, the generated `src/rom.asm` and
`build/`, and the probe scripts' regeneratable output manifests -- all
reproducible from the ROM and a recording.
