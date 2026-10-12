#!/usr/bin/env python3
"""La musica del cartucho, ejecutando su motor de sonido (ver motor_musica.py).

Pide el sonido con `arranca_sonido` (0x7A68, A = numero; `suena`, 0x7A4C, es la
entrada que filtra por la demo) y corre `reproduce` (0x7AFC), que la
interrupcion llama cada cuadro. Tres voces de 11 bytes desde 0xE211; la copia
del registro 7 del PSG, en 0xE210.
Uso:  musica.py registros 0x8E [cuadros] | mp3 0x8E f.mp3 | todas docs/audio
      musica.py barrido 0x80 0xFF | emu
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import motor_musica  # noqa: E402
from motor_musica import P  # noqa: E402

TABLA = "ninguna llamada directa: está en la tabla de pistas"

PIEZAS = [
    P(0x8E, "El juego ganado", "Game won", "`acaba_el_juego`"),
    P(0x91, "El final del partido", "The end of the match",
      "`fin_del_partido`: rótulo de cierre y vuelta al título"),
    P(0x94, "El principio del partido", "The start of the match",
      "`monta_la_pista`"),
] + [P(n, "Pista 0x%02X de la tabla" % n, "Table track 0x%02X" % n, TABLA)
     for n in (0x8F, 0x90, 0x92, 0x93, 0x95, 0x96)]

PAGINA = motor_musica.pagina_basica(
    "`reproduce`, 0x7AFC, y `arranca_sonido`, 0x7A68, que le reparte los "
    "canales; lo llama la interrupción",
    "`reproduce`, 0x7AFC, and `arranca_sonido`, 0x7A68, which hands it the "
    "channels; the interrupt calls it",
    "C-BIOS MSX1 japonés",
    [("el juego ganado (0x8E) entero, 146 cuadros",
      "game won (0x8E), whole, 146 frames"),
     ("el final del partido (0x91) entero, 362 cuadros",
      "the end of the match (0x91), whole, 362 frames")],
    [("Cómo se pide una pieza",
      "`suena` recibe el número en A: los sonidos 1, 2 y 3 suenan siempre y "
      "el resto solo con alguien jugando (0xE002); `arranca_sonido` reserva "
      "los canales. Por encima de 0x81 es música y se lleva los tres. Los "
      "canales ocupan 11 bytes cada uno desde 0xE211 y 0xE210 guarda la "
      "copia del mezclador del PSG, que el arranque deja en 0xB8. Las "
      "pistas «de la tabla» están en la tabla de pistas pero ninguna "
      "rutina las pide con un `ld a`; se omiten la 0x8C y la 0x8D, de "
      "minutos de duración, y la 0x97, que es silencio.",
      "How a piece is asked for",
      "`suena` takes the number in A: sounds 1, 2 and 3 always play and the "
      "rest only with someone playing (0xE002); `arranca_sonido` reserves the "
      "channels. Above 0x81 it is music and takes all three. The channels "
      "take 11 bytes each from 0xE211 and 0xE210 holds the copy of the PSG "
      "mixer, which start-up leaves at 0xB8. The tracks marked «in the "
      "table» are in the track table but no routine asks for them with an "
      "`ld a`; 0x8C and 0x8D, minutes long, and 0x97, which is silence, are "
      "left out.")])

CFG = dict(rom="tennis.rom", org=0x4000, frame=0x7AFC, pide=0x7A68,
           ram=(0xE210, 0xE234), ram0=[(0xE210, 0xB8)],
           excluye=[0xE21A, 0xE225, 0xE230], hz=60, psg0={7: 0xB8},
           piezas=PIEZAS, pagina=PAGINA,
           cotejado=[(0x8E, 146, None), (0x91, 362, None)])

if __name__ == "__main__":
    sys.exit(motor_musica.main(CFG, sys.argv[1:]))
