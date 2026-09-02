# Findings

## It defends itself against copies by writing on itself

In the whole ROM there is **exactly one** instruction that writes into the
cartridge's own page, and it is at 0x7A31: `ld (0409ah),a`, with A zero.

The address is not just any address. **0x409A is the `ret` that ends the
interrupt handler**, and at 0x409B, right behind it, INIT begins.

In a cartridge nothing happens: ROM will not take a write. In a copy loaded into
RAM that `ret` becomes a `nop`, the interrupt runs straight on into INIT, and
**the game restarts on every frame**. Nothing is checked and nothing is
announced; it simply stops working.

And it fires late — on winning a game — so a copy looks fine for a good while.
It is the same idea the **RC-701** of this series uses, where it goes with an
`ldir` over the dispatcher. Here it is unpatched and working.

## The screen's three thirds, with a single loop

0x442D copies VRAM to VRAM byte by byte, and is asked for **4,095** bytes from
0x0000 to 0x0800. Since the destination runs 0x800 ahead of the source, past the
first block it is reading what it has just written. One loop, three identical
thirds, 4 KB of data saved. Done twice: colours, then patterns.

## The colour table underneath the pattern table

`R4 = 0x07` puts the patterns at 0x2000 and `R3 = 0x7F` the colours at 0x0000,
because in SCREEN 2 those registers are a base bit and a mask, not an address.
Read the other way round, the shapes still come out — the two blocks are
symmetric — but the colours arrive in bands. That is the symptom.

## The chair umpire follows the ball with his eyes

He is 2x2 tiles of the name table, not a sprite. 0x6ED2 reads the ball's
position in 0xE0B7, splits the court into three with 0x48 and 0x78, and picks
one of the three faces at 0x715D. Only the eyes differ.

## The opponent misses on purpose

0x6BE9 does `ld a,r`. R is the DRAM refresh counter, which the Z80 advances on
every instruction, so it cannot be predicted. Rotated twice, it is the wobble in
the opponent's aim — and 0x6BEE leaves it at zero on half the frames.

## The difficulty rises with the rally

0xE20A counts the strokes. 0x6E3B halves it, caps it at fifteen, and looks it up
in one of the three sixteen-step curves at 0x6E67. The longer the point runs,
the better the machine plays.

## Six bytes of code in the sprite table

0x4272 asks for 22 bytes of sprite attributes from 0x7890, where there are only
16 of data. The six that follow are the start of the routine at 0x78A0, and they
go straight into VRAM at 0x3B3C, where they stay for the whole match. It does
not show, because the patterns they point at are empty.

## A racket nobody draws

Nine bytes at 0x61F5 decompress into a valid 16x16 sprite — a small racket. The
word 0x61F5 appears nowhere in the ROM, in either byte order, and every pattern
pointer is a 16-bit word. It matches none of the 189 patterns that are drawn.

## Every counter at zero means 256

The scripts are full of zero lengths, and they are not empty blocks: `djnz` with
B at zero runs 256 times. Read them as zeros and the script goes out of step
within a few blocks.

## PLY and MSX, or 1UP and 2UP

With one player the board reads PLY and MSX; with two people, 1UP and 2UP — the
six tiles at 0x7760 and the six at 0x7766. The court script leaves **CPU**
written in that cell and the game paints over it.

The alphabet is not ASCII: A is 0xD1 and on from there, with no Q, and with **X
out of order at 0xE8**, behind the Y. Digits are 0xF0 plus the digit.
