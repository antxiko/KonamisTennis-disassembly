# Konami's Tennis (Konami, RC-720) — a commented disassembly

A commented disassembly of the 16 KB MSX cartridge, reproducible byte for byte.

**[Read the work →](https://antxiko.github.io/KonamisTennis-disassembly/)**
· [En castellano](README.es.md)

    make            # traces, builds the listing, reassembles it and runs the tests
    make verify     # the test that decides: reassembling must give back the ROM
    make sanity     # that not one byte is left unexplained
    make densidad   # how much is commented, routine by routine
    make web        # rebuilds the site

The ROM is **not distributed here**. Put your own dump in the root as
`tennis.rom`, 16384 bytes, sha256

    68bec8172d816025a21dd47482e9413fd8bd726b2cafb49236ca58a65c73e07f

`make comprueba` checks it.

## Where it stands

| | |
|---|---|
| reassembles byte for byte | yes |
| bytes explained | 16,384 of 16,384 (100%) |
| traced code | 7,882 bytes |
| identified data | 8,502 bytes across 314 named ranges |
| commented | 1379 line comments, 32.4% |
| routines below 10% | 0 of 492 |

The annotations live apart from the listing, anchored to the address they
describe, so they survive a re-trace. What the `.notes` holds:

| | |
|---|---|
| named labels | 492 |
| anchored comments | 1368 |
| explained data ranges | 314 |

And the site's pictures are not captures: Python paints them by running the same
interpreters the Z80 runs, and they are checked against openMSX's VRAM across
**137,260 bytes with zero differences**.

## What is here

- `src/tennis.asm` — the listing; generated, not hand-written
- `src/tennis.notes` — the annotations, anchored to addresses
- `src/tennis.entries` — the entry points, each one justified
- `docs/` — the site, in English and Spanish
- `tools/` — the tracer, the listing builder, the two screen interpreters and
  the sprite decompressor that draw the site's images from the ROM

## The work

| | |
|---|---|
| [Getting started](docs/GETTING-STARTED.md) | what you need and what each command does |
| [The game](docs/THE-GAME.md) | two menus, four 41-byte player records and the tennis count |
| [The cartridge](docs/THE-CARTRIDGE.md) | the header, the colour table underneath the patterns, and why it carries no hidden mark |
| [The code](docs/THE-CODE.md) | the two screen interpreters, the five-sprite figures and the sound |
| [Findings](docs/FINDINGS.md) | one loop for three thirds, the umpire's eyes and a racket nobody draws |
| [In the emulator](docs/IN-THE-EMULATOR.md) | what can be measured, and how |
| [Open questions](docs/OPEN-QUESTIONS.md) | what is not settled yet |

See `LEGAL-NOTICE.md`.
