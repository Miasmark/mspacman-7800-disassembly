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
was actively distrusted and flagged rather than assumed. This is day one of
the project, so read it as a starting map, not a finished one.
[`annotations.json`](annotations.json) is the machine-readable form of the
same knowledge.

A privately-held, unlicensed historical source for this game exists (the
same archive the sibling projects' reference sources came from), following
the same methodology those projects settled into: hold off consulting it
until independent work is substantially done, then use it strictly as a
check -- never as the origin of a finding, never quoted or copied in.

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
technique the sibling projects used throughout. `.inp` files aren't
committed until at least one exists; add them to `.gitignore`'s
exceptions if that changes.

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
