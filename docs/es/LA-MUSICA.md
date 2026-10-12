# La música

Todo lo que suena aquí sale de ejecutar el motor de sonido del cartucho (`reproduce`, 0x7AFC, y `arranca_sonido`, 0x7A68, que le reparte los canales; lo llama la interrupción) en un Z80 emulado, cuadro a cuadro y a 60 por segundo, igual que lo llama el juego. Lo que el motor escribe en el PSG pasa a sonido con un AY-3-8910 (`tools/musica.py`). Cada MP3 es la pieza entera hasta donde vuelve a empezar, más 8 segundos de la vuelta apagándose; las que no se repiten acaban donde acaba el motor.

## Cotejado con openMSX

Las escrituras al PSG se han comparado cuadro a cuadro con las de openMSX (C-BIOS MSX1 japonés). En todos los cuadros el PSG queda igual:

- el juego ganado (0x8E) entero, 146 cuadros;
- el final del partido (0x91) entero, 362 cuadros.

El timbre no está cotejado: es el de un AY-3-8910 de manual, no una grabación del emulador. Las sondas están en `tools/omsx_psg.tcl` y `tools/coteja_psg.py`.

## Cómo se pide una pieza

`suena` recibe el número en A: los sonidos 1, 2 y 3 suenan siempre y el resto solo con alguien jugando (0xE002); `arranca_sonido` reserva los canales. Por encima de 0x81 es música y se lleva los tres. Los canales ocupan 11 bytes cada uno desde 0xE211 y 0xE210 guarda la copia del mezclador del PSG, que el arranque deja en 0xB8. Las pistas «de la tabla» están en la tabla de pistas pero ninguna rutina las pide con un `ld a`; se omiten la 0x8C y la 0x8D, de minutos de duración, y la 0x97, que es silencio.

## Las músicas

**El juego ganado** (0x8E)

Lo pide `acaba_el_juego`; dura 2,4 s.

<audio controls preload="none" src="../audio/musica_8E.mp3?v=8ee5b46c"></audio>

**El final del partido** (0x91)

Lo pide `fin_del_partido`: rótulo de cierre y vuelta al título; dura 6,0 s.

<audio controls preload="none" src="../audio/musica_91.mp3?v=1d56e815"></audio>

**El principio del partido** (0x94)

Lo pide `monta_la_pista`; dura 6,0 s.

<audio controls preload="none" src="../audio/musica_94.mp3?v=9e9a038d"></audio>

**Pista 0x8F de la tabla** (0x8F)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,0 s.

<audio controls preload="none" src="../audio/musica_8F.mp3?v=851023ac"></audio>

**Pista 0x90 de la tabla** (0x90)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,0 s.

<audio controls preload="none" src="../audio/musica_90.mp3?v=8c39e54f"></audio>

**Pista 0x92 de la tabla** (0x92)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,0 s.

<audio controls preload="none" src="../audio/musica_92.mp3?v=5c3e8ce7"></audio>

**Pista 0x93 de la tabla** (0x93)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,0 s.

<audio controls preload="none" src="../audio/musica_93.mp3?v=45eaa584"></audio>

**Pista 0x95 de la tabla** (0x95)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,0 s.

<audio controls preload="none" src="../audio/musica_95.mp3?v=c270a5bb"></audio>

**Pista 0x96 de la tabla** (0x96)

Lo pide ninguna llamada directa: está en la tabla de pistas; dura 6,0 s.

<audio controls preload="none" src="../audio/musica_96.mp3?v=d37589df"></audio>
