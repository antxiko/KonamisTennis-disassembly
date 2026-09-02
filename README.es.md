# Konami's Tennis (Konami, RC-720) — desensamblado comentado

Desensamblado comentado del cartucho MSX de 16 KB, reproducible byte a byte.

**[Leer el trabajo →](https://antxiko.github.io/KonamisTennis-disassembly/es/)**
· [In English](README.md)

    make            # traza, monta el listado, lo reensambla y pasa los tests
    make verify     # la prueba que decide: reensamblar tiene que devolver la ROM
    make sanity     # que no quede un byte sin explicar
    make densidad   # cuánto está comentado, rutina por rutina
    make web        # rehace el sitio

La ROM **no se distribuye aquí**. Pon tu propio volcado en la raíz como
`tennis.rom`, 16384 bytes, sha256

    68bec8172d816025a21dd47482e9413fd8bd726b2cafb49236ca58a65c73e07f

`make comprueba` lo verifica.

## Cómo está

| | |
|---|---|
| reensambla byte a byte | sí |
| bytes explicados | 16.384 de 16.384 (100 %) |
| código trazado | 7.882 bytes |
| datos identificados | 8.502 bytes en 314 rangos con nombre |
| comentado | 1379 comentarios de línea, 32,4 % |
| rutinas por debajo del 10 % | 0 de 492 |

Las anotaciones viven aparte del listado, ancladas a la dirección que
describen, así que sobreviven a un retrazado. Lo que hay en el `.notes`:

| | |
|---|---|
| etiquetas con nombre | 492 |
| comentarios anclados | 1368 |
| rangos de datos con explicación | 314 |

Y las imágenes del sitio no son capturas: las pinta Python ejecutando los mismos
intérpretes que corre el Z80, y están comprobadas contra la VRAM de openMSX a lo
largo de **137.260 bytes con cero diferencias**.

## Qué hay aquí

- `src/tennis.asm` — el listado; generado, no escrito a mano
- `src/tennis.notes` — las anotaciones, ancladas a direcciones
- `src/tennis.entries` — los puntos de entrada, cada uno justificado
- `docs/` — el sitio, en inglés y castellano
- `tools/` — el trazador, el montador del listado, los dos intérpretes de
  pantalla y el descompresor de sprites que dibujan las imágenes desde la ROM

## El trabajo

| | |
|---|---|
| [Empezar](docs/es/EMPEZAR.md) | qué hace falta y qué hace cada orden |
| [El juego](docs/es/EL-JUEGO.md) | dos menús, cuatro fichas de 41 bytes y la cuenta del tenis |
| [El cartucho](docs/es/EL-CARTUCHO.md) | la cabecera, la tabla de colores debajo de los patrones, y por qué no lleva la marca oculta |
| [El código](docs/es/EL-CODIGO.md) | los dos intérpretes de pantalla, las figuras de cinco sprites y el sonido |
| [Hallazgos](docs/es/HALLAZGOS.md) | un bucle para tres tercios, los ojos del juez y una raqueta que no dibuja nadie |
| [En el emulador](docs/es/EN-EL-EMULADOR.md) | qué se puede medir, y cómo |
| [Preguntas abiertas](docs/es/PREGUNTAS-ABIERTAS.md) | lo que no está cerrado |

Ver `AVISO-LEGAL.md`.
