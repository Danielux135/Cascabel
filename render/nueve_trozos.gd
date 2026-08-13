class_name NueveTrozos
extends RefCounted

## El renderizador de marcos de nueve trozos: LA pieza técnica de la Fase 5.
##
## Un marco es un PNG partido en nueve regiones: cuatro esquinas que no se
## estiran, cuatro bordes que se REPITEN en un eje, y un centro que se repite en
## los dos. Con eso un solo atlas sirve para paneles, botones, barra de tareas,
## tooltips y cuadros de diálogo a cualquier tamaño.
##
## LA REGLA QUE NO SE PUEDE ROMPER: **se repite, no se estira.** Estirar un
## pixelart lo destruye —los píxeles dejan de ser cuadrados y el marco deja de
## pertenecer al mismo juego que la mesa—. Godot lo hace con
## `draw_texture_rect(..., tile: true)`, y por eso los bordes del atlas están
## dibujados sin remates ni tornillos en las puntas: un detalle cerca del final
## de una tira se convierte en un patrón que se repite cada 30 px y canta.
##
## Y LA SEGUNDA: **todo en píxeles enteros.** Las posiciones se redondean antes
## de dibujar. Con filtro nearest y escalado entero, medio píxel de marco es una
## línea que hierve alrededor de toda la ventana.
##
## Los trozos se cargan de una carpeta con nombres fijos:
##   esq_si  esq_sd  esq_ii  esq_id      (esquinas: superior/inferior izq/der)
##   borde_sup  borde_inf  borde_izq  borde_der
##   relleno
##
## OJO CON EL ATLAS: los trozos tienen que estar cortados en REJILLA FIJA, no
## por silueta. `procesar.py` recorta por silueta por defecto, que es lo correcto
## para un icono y lo peor posible para esto: cada trozo sale con un tamaño
## distinto según lo que ocupe su dibujo, y entonces las esquinas no cuadran con
## los bordes. Para un marco hay que procesarlo con `--tira 3 --filas 3`.
## `grosor()` avisa de eso comprobando que las cuatro esquinas midan igual.

const NOMBRES := ["esq_si", "esq_sd", "esq_ii", "esq_id",
	"borde_sup", "borde_inf", "borde_izq", "borde_der", "relleno"]

var trozos: Dictionary = {}
## De dónde salió, para poder decirlo cuando algo no cuadre.
var ruta: String = ""

## Carga un marco de una carpeta. Los trozos que falten se quedan a null y el
## marco se dibuja con lo que haya: un panel sin esquinas sigue siendo legible,
## y es mejor que no dibujar nada mientras el arte está a medias.
static func cargar(carpeta: String) -> NueveTrozos:
	var m := NueveTrozos.new()
	m.ruta = carpeta
	for n in NOMBRES:
		var r := "%s/%s.png" % [carpeta.trim_suffix("/"), n]
		m.trozos[n] = load(r) as Texture2D if ResourceLoader.exists(r) else null
	return m

func tiene(n: String) -> Texture2D:
	return trozos.get(n) as Texture2D

func completo() -> bool:
	for n in NOMBRES:
		if tiene(n) == null:
			return false
	return true

## El grosor del marco por cada lado, sacado de las esquinas. Devuelve
## `Vector4(izq, arriba, der, abajo)`.
##
## Sale de las ESQUINAS y no de los bordes porque las esquinas son las que no se
## estiran: ellas mandan. Si los bordes miden otra cosa, se repiten dentro del
## hueco que dejan las esquinas y se recortan, que es lo que hace `tile`.
func grosor() -> Vector4:
	var si := tiene("esq_si")
	var id := tiene("esq_id")
	var izq := float(si.get_width()) if si != null else 0.0
	var arriba := float(si.get_height()) if si != null else 0.0
	var der := float(id.get_width()) if id != null else izq
	var abajo := float(id.get_height()) if id != null else arriba
	return Vector4(izq, arriba, der, abajo)

## ¿Están las cuatro esquinas cortadas a la misma medida? Si no, el atlas se
## cortó por silueta en vez de en rejilla fija y el marco no va a cuadrar.
func esquinas_cuadran() -> bool:
	var lados: Array[Vector2] = []
	for n in ["esq_si", "esq_sd", "esq_ii", "esq_id"]:
		var t := tiene(n)
		if t == null:
			return false
		lados.append(Vector2(t.get_width(), t.get_height()))
	for v in lados:
		if not v.is_equal_approx(lados[0]):
			return false
	return true

## Dibuja el marco dentro de `caja`. `tinte` sirve para apagarlo cuando el panel
## no es el que importa ahora mismo.
func dibujar(en: CanvasItem, caja: Rect2, tinte: Color = Color.WHITE) -> void:
	var g := grosor()
	# Con una caja más pequeña que el propio marco no se dibuja el relleno: se
	# encogen los bordes. Un marco de 47 px por lado en un botón de 60 no cabe.
	var r := Rect2(caja.position.round(), caja.size.round())
	var izq := minf(g.x, r.size.x * 0.5)
	var arr := minf(g.y, r.size.y * 0.5)
	var der := minf(g.z, r.size.x * 0.5)
	var aba := minf(g.w, r.size.y * 0.5)

	var centro := Rect2(r.position + Vector2(izq, arr),
		Vector2(maxf(r.size.x - izq - der, 0.0), maxf(r.size.y - arr - aba, 0.0)))

	_repetir(en, tiene("relleno"), centro, tinte)
	_repetir(en, tiene("borde_sup"), Rect2(centro.position.x, r.position.y,
		centro.size.x, arr), tinte)
	_repetir(en, tiene("borde_inf"), Rect2(centro.position.x, r.end.y - aba,
		centro.size.x, aba), tinte)
	_repetir(en, tiene("borde_izq"), Rect2(r.position.x, centro.position.y,
		izq, centro.size.y), tinte)
	_repetir(en, tiene("borde_der"), Rect2(r.end.x - der, centro.position.y,
		der, centro.size.y), tinte)
	# Las esquinas van LAS ÚLTIMAS y sin repetir: son las que rematan y no pueden
	# quedar tapadas por un borde que se pase de largo.
	_pegar(en, tiene("esq_si"), Vector2(r.position.x, r.position.y), tinte)
	_pegar(en, tiene("esq_sd"), Vector2(r.end.x - der, r.position.y), tinte)
	_pegar(en, tiene("esq_ii"), Vector2(r.position.x, r.end.y - aba), tinte)
	_pegar(en, tiene("esq_id"), Vector2(r.end.x - der, r.end.y - aba), tinte)

## El hueco de dentro: donde va el contenido del panel.
func interior(caja: Rect2) -> Rect2:
	var g := grosor()
	return Rect2(caja.position + Vector2(g.x, g.y),
		Vector2(maxf(caja.size.x - g.x - g.z, 0.0),
			maxf(caja.size.y - g.y - g.w, 0.0))).abs()

func _repetir(en: CanvasItem, tex: Texture2D, caja: Rect2, tinte: Color) -> void:
	if tex == null or caja.size.x <= 0.0 or caja.size.y <= 0.0:
		return
	# `tile` es lo que hace que esto sea un marco de nueve trozos y no un marco
	# estirado. Pide que el CanvasItem permita repetición de textura.
	en.draw_texture_rect(tex, Rect2(caja.position.round(), caja.size.round()),
		true, tinte)

func _pegar(en: CanvasItem, tex: Texture2D, donde: Vector2, tinte: Color) -> void:
	if tex == null:
		return
	en.draw_texture(tex, donde.round(), tinte)
