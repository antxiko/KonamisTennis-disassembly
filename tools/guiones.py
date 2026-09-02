#!/usr/bin/env python3
"""Los dos interpretes de pantalla del cartucho, rehechos en Python.

El cartucho no guarda las pantallas como un volcado de VRAM: las guarda como
GUIONES, listas de ordenes que un interprete de la ROM va ejecutando contra el
VDP. Hay dos, y este fichero los reproduce paso a paso para poder (a) saber
DONDE ACABA cada guion -que es lo que el presupuesto de bytes necesita- y
(b) reconstruir la VRAM que dejan, que es de donde salen los dibujos.

  LISTA DE TILES (0x43EA en la ROM). Cadena de entradas; cada una empieza por
  la direccion de VRAM en dos bytes (big-endian, con el bit de escritura ya
  puesto) y sigue con bytes que van al puerto de datos:
      0xFE [n] [b]  escribe n veces el byte b
      0xFF          fin de la entrada; si el siguiente byte es otro 0xFF,
                    fin de la lista
      resto         el byte, tal cual

  GUION (0x445F en la ROM). Empieza por el numero de bloques, y cada bloque
  lleva un comando:
      0  bytes crudos con RLE, escape 0x11 [n] [b]
      1  patrones por indice en la tabla de 0x489D, ocho bytes cada uno
      3  pares [n] [b] de relleno
      *  un patron de ocho bytes repetido n veces

La direccion de VRAM se guarda como la pasa la ROM a SETWRT, o sea con basura
en los dos bits altos: la BIOS hace (H and 0x3F) or 0x40, asi que aqui se
enmascara igual, con 0x3FFF.
"""
import sys

ORG = 0x4000
# Cada vez que un guion apunta a bytes de la ROM -patrones por indice del
# comando 1, o el patron suelto del comando *- se anota aqui, para saber que
# tramos del cartucho hacen falta ademas del guion mismo.
USOS = []
TAB_PATRONES = 0x489D   # tabla de patrones de ocho bytes, indexada por el
                        # comando 1 (0x44B5: `ld hl,0489dh`, + indice*8)


class Vram:
    """Los 16 KB de VRAM, y por donde va el puntero de escritura."""

    def __init__(self):
        self.b = bytearray(0x4000)
        self.p = 0
        self.tocado = bytearray(0x4000)

    def sitio(self, dir_):
        self.p = dir_ & 0x3FFF

    def escribe(self, v):
        self.b[self.p] = v
        self.tocado[self.p] = 1
        self.p = (self.p + 1) & 0x3FFF


def lista_de_tiles(rom, pos, vram=None):
    """Ejecuta una lista de tiles. Devuelve la posicion tras el ultimo byte."""
    while True:
        dir_ = (rom[pos] << 8) | rom[pos + 1]
        pos += 2
        if vram:
            vram.sitio(dir_)
        while True:
            b = rom[pos]
            if b == 0xFE:
                n, val = rom[pos + 1] or 256, rom[pos + 2]
                pos += 3
                if vram:
                    for _ in range(n):
                        vram.escribe(val)
                continue
            if b == 0xFF:
                pos += 1
                break
            if vram:
                vram.escribe(b)
            pos += 1
        # Un 0xFF pegado al que cerro la entrada cierra la lista entera.
        if rom[pos] == 0xFF:
            return pos + 1


def guion(rom, pos, vram=None):
    """Ejecuta un guion. Devuelve la posicion tras el ultimo byte."""
    bloques = rom[pos] or 256
    pos += 1
    for _ in range(bloques):
        cmd = rom[pos]
        pos += 1

        if cmd == 0:                                    # bytes crudos con RLE
            n = rom[pos] or 256
            pos += 1
            for _ in range(n):
                dir_ = (rom[pos] << 8) | rom[pos + 1]
                pos += 2
                cuenta = rom[pos] or 256
                pos += 1
                if vram:
                    vram.sitio(dir_)
                while cuenta:
                    b = rom[pos]
                    if b == 0x11:
                        veces, val = rom[pos + 1] or 256, rom[pos + 2]
                        pos += 3
                        for _ in range(veces):
                            if vram:
                                vram.escribe(val)
                            cuenta -= 1
                            if cuenta == 0:
                                break
                    else:
                        if vram:
                            vram.escribe(b)
                        pos += 1
                        cuenta -= 1

        elif cmd == 1:                                  # patrones por indice
            n = rom[pos] or 256
            pos += 1
            for _ in range(n):
                dir_ = (rom[pos] << 8) | rom[pos + 1]
                pos += 2
                if vram:
                    vram.sitio(dir_)
                while rom[pos] != 0xFF:
                    i = rom[pos]
                    pos += 1
                    o = TAB_PATRONES - ORG + i * 8
                    USOS.append(("patron-indexado", o + ORG, 8, i))
                    if vram:
                        for k in range(8):
                            vram.escribe(rom[o + k])
                pos += 1

        elif cmd == 3:                                  # pares de relleno
            # Ojo: aqui la cuenta es de PARES, no de grupos, y hay UNA sola
            # direccion para todos (0x44D7: `ld b,(hl)` y un unico L_4505).
            n = rom[pos] or 256
            pos += 1
            dir_ = (rom[pos] << 8) | rom[pos + 1]
            pos += 2
            if vram:
                vram.sitio(dir_)
            for _ in range(n):
                veces, val = rom[pos] or 256, rom[pos + 1]
                pos += 2
                if vram:
                    for _ in range(veces):
                        vram.escribe(val)

        else:                                           # un patron repetido
            # 0x44EA: direccion, cuantas veces, y el puntero al patron -este
            # en little-endian, que lo lee `ld e,(hl) / ld d,(hl)`-. Cinco
            # bytes justos; el patron se repite sin avanzar.
            dir_ = (rom[pos] << 8) | rom[pos + 1]
            pos += 2
            veces = rom[pos] or 256
            pos += 1
            org_pat = rom[pos] | (rom[pos + 1] << 8)
            pos += 2
            USOS.append(("patron-suelto", org_pat, 8, veces))
            if vram:
                vram.sitio(dir_)
                o = org_pat - ORG
                for _ in range(veces):
                    for k in range(8):
                        vram.escribe(rom[o + k])

    return pos


def main():
    if len(sys.argv) < 4:
        print(__doc__.strip())
        print("\nUso: guiones.py <rom> lista|guion|cadena <dir> [cuantos]")
        return 2
    rom = open(sys.argv[1], "rb").read()
    que = sys.argv[2]
    dir_ = int(sys.argv[3], 16)
    cuantos = int(sys.argv[4]) if len(sys.argv) > 4 else 1
    pos = dir_ - ORG
    v = Vram()

    if que == "cadena":
        # Como lo hace 0x423E: el primer byte dice cuantos guiones seguidos.
        n = rom[pos]
        pos += 1
        print("cadena de %d guiones en 0x%04X" % (n, dir_))
        for i in range(n):
            ini = pos
            pos = guion(rom, pos, v)
            print("  guion %d: 0x%04X..0x%04X  (%d bytes)"
                  % (i + 1, ini + ORG, pos + ORG, pos - ini))
    else:
        for i in range(cuantos):
            ini = pos
            pos = (lista_de_tiles if que == "lista" else guion)(rom, pos, v)
            print("%s %d: 0x%04X..0x%04X  (%d bytes)"
                  % (que, i + 1, ini + ORG, pos + ORG, pos - ini))
    print("acaba en 0x%04X ; %d bytes de VRAM tocados"
          % (pos + ORG, sum(v.tocado)))
    if USOS:
        print()
        print("apunta a estos bytes de la ROM:")
        vistos = {}
        for cual, dir_, n, extra in USOS:
            k = (cual, dir_, n)
            vistos[k] = vistos.get(k, 0) + 1
        for (cual, dir_, n), veces in sorted(vistos.items(), key=lambda x: x[0][1]):
            print("  0x%04X..0x%04X  %-16s x%d" % (dir_, dir_ + n, cual, veces))
    return 0


if __name__ == "__main__":
    sys.exit(main())
