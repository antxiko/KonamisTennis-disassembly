#!/usr/bin/env python3
"""Las pantallas del cartucho, montadas ejecutando lo que ejecuta la ROM.

No hay ninguna captura aqui dentro: se reproduce la secuencia de arranque tal
como la hace el cartucho -guion, replica y lista de tiles, en ese orden- y se
dibuja la VRAM que queda. Si el dibujo sale bien es porque los interpretes de
`guiones.py` son correctos, no porque se haya mirado una foto.

LA PANTALLA DE PORTADA, como la monta INIT:
    0x4137  guion 0x4686 .... patrones y colores
    0x413D  replica de VRAM 0x0000 -> 0x0800 (4095 bytes) .......... colores
    0x4146  replica de VRAM 0x2000 -> 0x2800 (4095 bytes) ......... patrones
    0x41AA  listas de tiles 0x45D1, cuatro seguidas ... la tabla de nombres

LA PISTA, como la monta 0x4234:
    0x4234  borrado de la tabla de nombres (0x441A)
    0x423E  cadena de guiones 0x49B5
    0x424C  replica de VRAM 0x0000 -> 0x0800
    0x4256  replica de VRAM 0x2000 -> 0x2800
    0x4263  lista de tiles 0x4FF1 ...................... la tabla de nombres

LA REPLICA es el truco mas bonito del cartucho. 0x442D copia byte a byte de
VRAM a VRAM, y le mandan copiar 4095 bytes de 0x0000 a 0x0800: como el origen
alcanza al destino a mitad de camino, lo que ya escribio se vuelve a leer, y
un solo bucle deja los TRES tercios de la pantalla iguales. Los patrones y los
colores de un tercio valen para los tres, y el cartucho se ahorra 4 KB.

Los registros del VDP los pone 0x411D con la tabla de 0x45C9:
    02 E2 0E 7F 07 76 03 E1
Y OJO CON ESTOS DOS, que es facil leerlos al reves. En SCREEN 2 el TMS9918 no
toma R3 y R4 como una direccion, sino como un bit de base y una mascara:

    R4 = 0x07  patrones = (R4 and 0x04) * 0x800 = 0x2000
    R3 = 0x7F  colores  = (R3 and 0x80) * 0x40  = 0x0000

o sea que este cartucho pone la tabla de COLORES DEBAJO de la de patrones, al
reves de la colocacion habitual. Leerlo del otro modo da una pantalla en la
que las formas se reconocen -porque los dos bloques son simetricos- pero los
colores salen a franjas, que es justo el sintoma.

El resto: nombres en 0x3800 (R2), patrones de sprite en 0x1800 (R6) y
atributos de sprite en 0x3B00 (R5).

Uso: pantallas.py <rom> <carpeta>          dibuja portada.png y pista.png
     pantallas.py <rom> <carpeta> --vram   ademas vuelca la VRAM cruda
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import guiones                                            # noqa: E402

ORG = 0x4000
GUION_PORTADA = 0x4686
LISTAS_PORTADA = 0x45D1
CADENA_PISTA = 0x49B5
LISTA_PISTA = 0x4FF1
REGISTROS_VDP = 0x45C9

PALETA = [
    (0, 0, 0), (0, 0, 0), (33, 200, 66), (94, 220, 120),
    (84, 85, 237), (125, 118, 252), (212, 82, 77), (66, 235, 245),
    (252, 85, 84), (255, 121, 120), (212, 193, 84), (230, 206, 128),
    (33, 176, 59), (201, 91, 186), (204, 204, 204), (255, 255, 255),
]


def replica(v, origen, destino, cuantos=0x0FFF):
    """0x442D: copia de VRAM a VRAM byte a byte, con el solape que replica."""
    o, d = origen & 0x3FFF, destino & 0x3FFF
    for _ in range(cuantos):
        v.b[d] = v.b[o]
        v.tocado[d] = 1
        o = (o + 1) & 0x3FFF
        d = (d + 1) & 0x3FFF


def borra_nombres(v):
    """0x441A: 3 x 256 bytes a cero en la tabla de nombres."""
    for i in range(768):
        v.b[0x3800 + i] = 0
        v.tocado[0x3800 + i] = 1


def portada(rom):
    v = guiones.Vram()
    guiones.guion(rom, GUION_PORTADA - ORG, v)
    replica(v, 0x0000, 0x0800)
    replica(v, 0x2000, 0x2800)
    borra_nombres(v)
    pos = LISTAS_PORTADA - ORG
    for _ in range(4):                      # 0x43DB: `ld b,004h`
        pos = guiones.lista_de_tiles(rom, pos, v)
    return v


def pista(rom):
    # El cartucho no borra los patrones al pasar del titulo a la pista: solo
    # borra la tabla de nombres (0x4234) y ejecuta el guion encima. La fuente
    # -las letras y las cifras- sigue puesta desde la portada, y el guion de la
    # pista no la vuelve a cargar. Asi que hay que partir de esa VRAM.
    v = portada(rom)
    borra_nombres(v)
    pos = CADENA_PISTA - ORG
    n = rom[pos]
    pos += 1
    for _ in range(n):
        pos = guiones.guion(rom, pos, v)
    replica(v, 0x0000, 0x0800)
    replica(v, 0x2000, 0x2800)
    guiones.lista_de_tiles(rom, LISTA_PISTA - ORG, v)
    return v


PATRONES = 0x2000        # (R4 and 0x04) * 0x800, con R4 = 0x07
COLORES = 0x0000         # (R3 and 0x80) * 0x40,  con R3 = 0x7F
NOMBRES = 0x3800         # R2 * 0x400, con R2 = 0x0E


def pinta(v):
    """La VRAM a una imagen de 256x192, como la saca el TMS9918 en SCREEN 2."""
    img = [[0] * 256 for _ in range(192)]
    for fila in range(24):
        tercio = fila // 8
        for col in range(32):
            tile = v.b[NOMBRES + fila * 32 + col]
            base = tercio * 0x800 + tile * 8
            for y in range(8):
                forma = v.b[PATRONES + base + y]
                color = v.b[COLORES + base + y]
                tinta, fondo = color >> 4, color & 0x0F
                for x in range(8):
                    on = (forma >> (7 - x)) & 1
                    img[fila * 8 + y][col * 8 + x] = tinta if on else fondo
    return img


def png(ruta, img, escala=3):
    import struct
    import zlib

    al, an = len(img) * escala, len(img[0]) * escala
    crudo = b""
    for fila in img:
        linea = b"".join(bytes(PALETA[c]) * escala for c in fila)
        crudo += (b"\0" + linea) * escala
    del al, an

    def trozo(tipo, datos):
        return (struct.pack(">I", len(datos)) + tipo + datos
                + struct.pack(">I", zlib.crc32(tipo + datos) & 0xFFFFFFFF))

    with open(ruta, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(trozo(b"IHDR", struct.pack(">IIBBBBB", len(img[0]) * escala,
                                           len(img) * escala, 8, 2, 0, 0, 0)))
        f.write(trozo(b"IDAT", zlib.compress(crudo, 9)))
        f.write(trozo(b"IEND", b""))


def main():
    if len(sys.argv) < 3:
        print(__doc__.strip())
        return 2
    rom = open(sys.argv[1], "rb").read()
    carpeta = sys.argv[2]
    os.makedirs(carpeta, exist_ok=True)

    for nombre, hacer in (("portada", portada), ("pista", pista)):
        v = hacer(rom)
        png(os.path.join(carpeta, nombre + ".png"), pinta(v))
        print("%s.png  (%d bytes de VRAM escritos)" % (nombre, sum(v.tocado)))
        if "--vram" in sys.argv:
            with open(os.path.join(carpeta, nombre + ".vram"), "wb") as f:
                f.write(bytes(v.b))
    return 0


if __name__ == "__main__":
    sys.exit(main())
