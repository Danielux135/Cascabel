class_name FuenteUI
extends RefCounted

## La fuente del juego: pixelart propia, generada por `fuente.py`.
##
## POR QUÉ EXISTE, versión larga, porque ha cambiado dos veces:
##
## 1. Todo cogía la fuente de reserva de Godot, que solo trae ASCII, así que
##    **ni los acentos ni la ñ se dibujaban**: "MANTÉN" salía "MANTN". Un glifo
##    que falta no da error, deja un hueco, y nadie mira un hueco.
## 2. El apaño fue una fuente del sistema, y era peor de lo que parecía: una
##    tipografía suave y antialiaseada alrededor de una mesa de pixelart no se
##    lee como el mismo juego. La cáscara se veía como una captura de dos
##    programas distintos pegados.
##
## Ahora la fuente es NUESTRA y es pixelart, como todo lo demás, y se genera por
## código igual que los sonidos: cambiar el grosor de una letra es cambiar una
## línea de `fuente.py` y volver a lanzarlo.
##
## LA REGLA DEL TAMAÑO: la celda mide 8 px de alto, así que la fuente se ve
## nítida a 8, 16, 24, 32 y 48 y SOLO ahí. Un 11 la escala por 1,375 y le come
## filas de píxeles a media letra. Por eso todo el texto del juego pasa por
## `tam()`, que redondea al múltiplo más cercano: es la misma regla de escalado
## por enteros que la mesa, aplicada a las letras.

const RUTA_HOJA := "res://assets/ui/fuente_cascabel.png"
const RUTA_METRICAS := "res://assets/ui/fuente_cascabel.json"

## Las letras que tiene que saber dibujar. Si falta una, la prueba lo dice.
const LETRAS := "áéíóúüñÁÉÍÓÚÜÑ¿¡·—×%"

static var _cache: Font = null
static var _alto: int = 8

## El alto de la celda, que es el tamaño natural de la fuente.
static func alto() -> int:
	obtener()
	return _alto

## Redondea un tamaño al múltiplo entero más cercano del alto de la celda. Es
## lo que impide que una letra se escale en fracciones.
static func tam(pedido: float) -> int:
	var u := alto()
	return maxi(u * int(round(pedido / float(u))), u)

static func obtener() -> Font:
	if _cache != null:
		return _cache
	_cache = _construir()
	return _cache

static func _construir() -> Font:
	var metricas := _leer_metricas()
	var imagen := _leer_hoja()
	if metricas.is_empty() or imagen == null:
		# Sin la hoja no hay fuente. Se cae a la de reserva para que el juego
		# arranque y se pueda leer el error, pero la prueba de castellano va a
		# fallar y decir exactamente esto.
		push_error("Falta la fuente: lanza `python3 fuente.py`")
		return ThemeDB.fallback_font

	_alto = int(metricas.get("alto", 8))
	var avance := int(metricas.get("avance", 6))
	var linea_base := int(metricas.get("linea_base", 7))
	var tamano := Vector2i(_alto, 0)

	var f := FontFile.new()
	f.fixed_size = _alto
	# Sin esto Godot interpola al escalar y la fuente deja de ser pixelart en
	# cuanto se pide un tamaño que no sea el natural.
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	f.set_texture_image(0, tamano, 0, imagen)
	f.set_cache_ascent(0, _alto, float(linea_base))
	f.set_cache_descent(0, _alto, float(_alto - linea_base))

	var glifos: Dictionary = metricas.get("glifos", {})
	for letra in glifos:
		var s := str(letra)
		if s.length() == 0:
			continue
		# En una fuente de mapa de bits el índice de glifo ES el código del
		# carácter: no hay tabla intermedia que se pueda descuadrar.
		var indice := s.unicode_at(0)
		var xy: Array = glifos[letra]
		f.set_glyph_texture_idx(0, tamano, indice, 0)
		f.set_glyph_uv_rect(0, tamano, indice,
			Rect2(float(xy[0]), float(xy[1]), float(avance), float(_alto)))
		f.set_glyph_size(0, tamano, indice, Vector2(avance, _alto))
		f.set_glyph_offset(0, tamano, indice, Vector2(0, -linea_base))
		# Vector2, no Vector3: el avance es cuánto corre el cursor y cuánto sube
		# o baja, y no tiene tercera componente.
		f.set_glyph_advance(0, _alto, indice, Vector2(avance, 0))
	return f

static func _leer_metricas() -> Dictionary:
	if not ResourceLoader.exists(RUTA_METRICAS) and not FileAccess.file_exists(RUTA_METRICAS):
		return {}
	var texto := FileAccess.get_file_as_string(RUTA_METRICAS)
	var crudo: Variant = JSON.parse_string(texto)
	return crudo as Dictionary if typeof(crudo) == TYPE_DICTIONARY else {}

## La hoja se lee como IMAGEN, no como textura importada: `set_texture_image`
## quiere un `Image`, y además así da igual cómo esté configurada la importación
## del PNG.
static func _leer_hoja() -> Image:
	if ResourceLoader.exists(RUTA_HOJA):
		var tex := load(RUTA_HOJA) as Texture2D
		if tex != null:
			return tex.get_image()
	return Image.load_from_file(RUTA_HOJA) if FileAccess.file_exists(RUTA_HOJA) else null

## ¿Sabe dibujar todo lo que necesita el castellano? Se comprueba de verdad, no
## se supone: una letra que falte deja un hueco y no da error.
static func tiene_castellano(f: Font = null) -> bool:
	var fuente := f if f != null else obtener()
	for i in LETRAS.length():
		if not fuente.has_char(LETRAS.unicode_at(i)):
			return false
	return true
