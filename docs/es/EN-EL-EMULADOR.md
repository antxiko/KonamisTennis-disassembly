# En el emulador

Las imágenes de la portada están dibujadas desde la ROM, no capturadas. Mirarlas
no basta para darlas por buenas, así que se comprueban contra la VRAM que el VDP
tiene de verdad.

## El volcado

    "C:/Program Files/openMSX/openmsx.exe" -machine Philips_VG_8020 \
        -cart tennis.rom -script tools/omsx_vram.tcl

`tools/omsx_vram.tcl` deja correr el juego y, en doce instantes, escribe los
16 KB de VRAM, los ocho registros del VDP y las variables de trabajo que dicen
qué se estaba dibujando. No pone **ningún punto de ruptura**: los volcados van
por reloj emulado, que es lo único que no ahoga al emulador.

Los primeros se toman a los nueve segundos, no a los tres: antes de eso el
cartucho está a medio pintar el título y la VRAM no es comparable con nada.

## La comparación

    python tools/graficos.py --comprueba tennis.rom 0x4000 work/omsx

    12 volcados, 137.260 bytes comparados, 0 distintos

De la comparación se dejan fuera dos cosas, las dos con su razón. Los volcados
tomados antes de que INIT cargue los registros del VDP, porque la pantalla
todavía no está montada. Y los 32 bytes de color de los tiles 0xA5 a 0xA8, que
son el rótulo de falta: 0x746F alterna dos juegos de color sobre ellos cada
siete cuadros, así que su valor depende del cuadro exacto del volcado.

## Lo que cazó esa comparación

Es lo que destapó que las tablas de patrones y colores se estaban leyendo al
revés. Las formas salían bien —se leía "Konami's Tennis"— pero los colores
llegaban a franjas. La VRAM coincidía byte a byte; el error estaba en cómo se
leía.

Y es lo que enseñó que el guion de la pista no lleva la fuente. Montar la pista
sobre una VRAM vacía dejaba 1.514 bytes distintos, y todos eran letras y
cifras. El cartucho no borra los patrones al pasar del título a la pista: sólo
borra la tabla de nombres, en 0x4234. Partir de la VRAM del título, como hace
el cartucho, llevó esas 1.514 diferencias a cero.

## Siguiendo al recogepelotas

`work/sigue_sprites.tcl` sigue 0xE03A, 0xE03B y 0xE03C y los atributos de sprite
de 0x3B3C. En dos minutos de demostración el recogepelotas no sale nunca: le
hace falta 0xE0C0 o 0xE044 puestos, y no pasa ninguna de las dos. Escribiendo
0xE0C0 a mano desde el depurador sale, y sus cuatro sprites se mueven con él
—que es como "es de sprites" dejó de ser una lectura del código y pasó a ser
algo visto.
