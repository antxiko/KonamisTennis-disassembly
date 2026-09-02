# The game

Konami's Tennis is a 1984 cartridge for the MSX. One court, seen from behind
the baseline, and up to four players on it.

## The two menus

The title screen offers **PLAY SELECT** with three options: `1PLAYER`,
`2PLAYERS` and `DOUBLES`. The chosen one goes into 0xE00E, and it is the number
the whole cartridge asks about afterwards — 0x5894 compares it against 2 and
0x589A against 3, and between those two comparisons the entire game decides
whether there is a partner on court.

If nobody touches anything, the clock at 0xE001 runs out and the machine plays
against itself: that is the demo.

Then comes **GAME SELECT**, with 1, 2 or 3. It lands in 0xE0DA and picks which
of the three difficulty curves the opponent uses.

## The four players

Every player has a **41-byte record**. There are four of them, at 0xE100,
0xE130, 0xE160 and 0xE190, and 0x57BE copies them out of the table at 0x57EB
when the match starts. In the record live the position, the pose, the flags,
and the twenty bytes of sprite attributes that 0x5920 dumps to the VDP.

Bit 0 of byte 12 is what separates a human from the machine: 0x588F tests it,
and every routine that reads the controls asks first.

The colours of the five layers are in the record too, which is why players 3
and 4 have **magenta hair** where 1 and 2 have black.

## The scoring

0x7932 keeps the tennis count. 0xE030 and 0xE031 hold the two players' points,
and the routine walks the ladder: at three each it is deuce (0x79F1), at four
it is advantage, and losing it drops both back to three. Six closes the game.

The board itself shows 00, 15, 30, 40 and A, taken from the table of pointers
at 0x76D7.

Games won go into 0xE032 and 0xE035, and six of them win the set — which
0x7A48 records in 0xE048.

## What the court holds

The umpire in his chair, on the left, and the ball boy on the right, are not
decoration in the same sense: the **umpire is tiles**, a 2x2 block of the name
table that changes its eyes to follow the ball, and the **ball boy is sprites**,
who comes out when the ball is left rolling, fetches it and walks back to his
spot.
