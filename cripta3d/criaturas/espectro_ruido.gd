extends SceneTree

## CRIPTA 3D — genera `espectro_ruido.png`, el ruido de la gelatina del espectro.
##
##     python cripta3d/herramientas/godot3d.py guion res://cripta3d/criaturas/espectro_ruido.gd
##     python cripta3d/herramientas/godot3d.py importar --lineas 5
##
## POR QUÉ HACE FALTA. El espectro calculaba su ruido en el sombreador (un ruido
## de valor 3D con ocho `hash` por lectura, y las volutas son tres lecturas
## retorcidas unas con otras): en un navegador, Direct3D despliega todo eso en
## cada variante y la gelatina tardaba casi 8 s en compilar. Con esta textura,
## cada lectura de ruido es UNA lectura de textura.
##
## POR QUÉ NO LAS TRES DE LA CASA (`cripta3d/texturas/ruido_*.png`). Son ruido
## 2D ya hecho (fBm, crestas, celdas), y lo del espectro es OTRA cosa: ruido de
## valor en 3D que se mueve con el tiempo por su tercera dimensión (las volutas
## SUBEN y se retuercen, no resbalan). Esta textura es la rejilla de azar de ese
## mismo ruido, guardada con el truco de las rodajas: la rodaja z de la rejilla
## es la textura desplazada (37, 17)·z, y G guarda lo que R tiene una rodaja más
## allá. Con el filtro lineal y la curva suave puesta a mano en la coordenada,
## una lectura da el ruido de valor 3D EXACTO (el mismo tipo, la misma curva, el
## mismo reparto); lo que cambia es el azar de cada nudo, o sea dónde cae cada
## voluta.
##
##   R  el azar del nudo (x, y)
##   G  el de (x + 37, y + 17): la rodaja siguiente
##   B  otro azar, suelto (los granos de sal: dónde cae el grano en su celda)
##   A  otro más (lo mismo, en la otra coordenada). Nunca 0: ver `_guardar` en
##      `materiales/generar_texturas.gd`.
##
## 256 × 256 y SIN mipmaps: se lee siempre con `textureLod(…, 0.0)` y a esa
## escala cada nudo ocupa varios píxeles (igual que el ruido por código, que
## tampoco se filtraba). Sin pérdida: un bloque de compresión de 4×4 serían
## dieciséis nudos promediados.

const TAM := 256
const RUTA := "res://cripta3d/criaturas/espectro_ruido.png"
## Lo que se desplaza la rejilla por cada rodaja. Los de siempre de este truco
## (primos con 256 y lejos de los bordes): con (1, 0) se verían las rodajas.
const SALTO := Vector2i(37, 17)

func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261121
	var azar := PackedByteArray()
	azar.resize(TAM * TAM)
	for k in TAM * TAM:
		azar[k] = rng.randi_range(0, 255)
	var bytes := PackedByteArray()
	bytes.resize(TAM * TAM * 4)
	for y in TAM:
		for x in TAM:
			var k := (y * TAM + x) * 4
			bytes[k] = azar[y * TAM + x]
			var xs := (x + SALTO.x) % TAM
			var ys := (y + SALTO.y) % TAM
			bytes[k + 1] = azar[ys * TAM + xs]
			bytes[k + 2] = rng.randi_range(0, 255)
			bytes[k + 3] = rng.randi_range(1, 255)
	var img := Image.create_from_data(TAM, TAM, false, Image.FORMAT_RGBA8, bytes)
	var err := img.save_png(ProjectSettings.globalize_path(RUTA))
	print("ESPECTRO: %s %s" % [RUTA, "guardada" if err == OK else "ERROR %d" % err])
	_ficha()
	quit()

## La ficha de importación, si no existe: sin pérdida, SIN mipmaps, sin tocar el
## alfa (es un dato) y sin que el editor la recomprima al verla en una malla.
func _ficha() -> void:
	var ficha := ProjectSettings.globalize_path(RUTA + ".import")
	if FileAccess.file_exists(ficha):
		return
	var f := FileAccess.open(ficha, FileAccess.WRITE)
	if f == null:
		print("  no puedo escribir ", ficha)
		return
	f.store_string("[remap]\n\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\n\n[params]\n\n"
		+ "compress/mode=0\nmipmaps/generate=false\nprocess/fix_alpha_border=false\n"
		+ "process/premult_alpha=false\ndetect_3d/compress_to=0\n")
	f.close()
