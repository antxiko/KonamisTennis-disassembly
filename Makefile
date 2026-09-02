# Konami's Tennis (Konami, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# La ROM no se distribuye. Hace falta en la raiz como tennis.rom, y
# `make comprueba` verifica el sha256.

ROM      = tennis.rom
SHA      = 68bec8172d816025a21dd47482e9413fd8bd726b2cafb49236ca58a65c73e07f
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = KONAMI'S TENNIS - Konami - MSX1 - cartucho RC-720 de 16 KB en la pagina 1

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Konami's Tennis (Konami, RC-720) para MSX, 16384 bytes exactos."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/tennis.trace.json: $(ROM) $(SRC)/tennis.entries $(SRC)/tennis.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/tennis.entries \
	        $(WORK)/tennis $(SRC)/tennis.nocode

trace: $(WORK)/tennis.trace.json

listado: $(WORK)/tennis.trace.json $(SRC)/tennis.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/tennis.trace.json \
	        $(SRC)/tennis.notes work/msx.sym $(SRC)/tennis.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/tennis.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/tennis.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/tennis.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/tennis.trace.json $(SRC)/tennis.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/tennis.entries $(SRC)/tennis.notes \
	        $(SRC)/tennis.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

densidad:
	@python3 tools/densidad.py $(SRC)/tennis.asm

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

# Dibuja los bloques de datos graficos declarados en el .notes, para MIRARLOS.
imagenes: $(ROM)
	@mkdir -p work/gfx
	python3 tools/dibuja.py $(ROM) $(ORG) $(SRC)/tennis.notes work/gfx

# LA WEB
#
# Bilingue: el ingles en docs/ y el castellano en docs/es/. Las paginas se
# escriben en markdown y se convierten con md2html.py; la portada la monta
# make_web.py, que declara las cifras medidas de ESTE cartucho.
web: $(ROM)
	@test -f tools/graficos.py && python3 tools/graficos.py $(ROM) $(ORG) docs/imagenes || echo '  (aun no hay graficos.py)'
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py docs/imagenes docs/index.html en
	python3 tools/make_web.py docs/imagenes docs/es/index.html es
	python3 tools/check_enlaces.py docs

clean:
	rm -rf $(WORK)/tennis.trace.json $(WORK)/tennis.blocks

.PHONY: all comprueba trace listado verify sanity test densidad imagenes web clean
