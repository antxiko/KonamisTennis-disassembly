# Empezar

Desensamblado comentado de **Konami's Tennis**, el RC-720 de Konami para MSX,
un cartucho de 16 KB en la página 1 (0x4000–0x7FFF). Vuelve a ensamblar dando
la ROM exacta, byte a byte, y sus 16.384 bytes están todos explicados.

## El cartucho no está aquí

Ningún repositorio distribuye el juego. Pon tu propio volcado en la raíz como
`tennis.rom`, 16384 bytes, sha256

    68bec8172d816025a21dd47482e9413fd8bd726b2cafb49236ca58a65c73e07f

`make comprueba` lo verifica.

## Qué hace cada orden

    make            traza el flujo, monta el listado, lo reensambla y pasa los tests
    make verify     la prueba que decide: reensamblar tiene que devolver la ROM
    make sanity     que no quede un byte sin explicar, y que ningún dato salga como código
    make densidad   cuánto está comentado, rutina por rutina
    make web        rehace este sitio desde la ROM y las notas

## Cómo está montado

El listado no se edita a mano: `tools/mkasm.py` lo genera a partir de un trazado
del flujo y de un fichero de notas ancladas a direcciones, así que los
comentarios sobreviven a un retrazado. El trazador sigue el flujo desde los
puntos de entrada; los que no puede deducir solo —sobre todo el gancho de la
interrupción— están declarados en `src/tennis.entries`, cada uno con su
justificación.

Las imágenes de la portada no son capturas. Las dibuja `tools/graficos.py`
ejecutando en Python los pasos del propio cartucho: los dos intérpretes de
pantalla de `tools/guiones.py`, la copia de VRAM a VRAM de 0x442D y el
descompresor de sprites de 0x5932. Y no se dan por buenas: `graficos.py
--comprueba` vuelca la VRAM del emulador y la compara byte a byte.
