class_name CamaraMesa
extends Camera2D

## Cámara vertical de la mesa. Las cuatro reglas de PLAN.md, y `objetivo()` es
## pura a propósito para poder comprobarlas en headless.

var p: ParametrosCamara
var alto_mesa: float = 700.0
var centro_x: float = 200.0
var y_actual: float = 0.0
## Desplazamiento de la sacudida. Va en `offset` de la cámara y no moviendo el
## nodo de la mesa: si se moviera la mesa, la cámara se movería con ella y la
## sacudida no se vería.
var sacudida := Vector2.ZERO

func _init(parametros: ParametrosCamara, el_alto: float, el_centro_x: float) -> void:
	p = parametros
	alto_mesa = el_alto
	centro_x = el_centro_x
	anchor_mode = Camera2D.ANCHOR_MODE_DRAG_CENTER
	y_actual = limite_abajo()
	_colocar()

func limite_arriba() -> float:
	return p.alto_visible * 0.5

func limite_abajo() -> float:
	return maxf(alto_mesa - p.alto_visible * 0.5, limite_arriba())

## Dónde querría estar la cámara ahora mismo. Sin suavizado ni estado.
func objetivo(bola_y: float, bola_vy: float, hay_bola: bool) -> float:
	if not hay_bola:
		return limite_abajo()
	# REGLA 2: por debajo de la línea de seguridad, anclada abajo y punto.
	if bola_y > alto_mesa - p.margen_ancla:
		return limite_abajo()
	# REGLA 1: si cae, se adelanta; si sube, no la persigue.
	var adelanto := p.adelanto if bola_vy > 0.0 else p.adelanto_subiendo
	return clampf(bola_y + adelanto, limite_arriba(), limite_abajo())

func avanzar(delta: float, bola_y: float, bola_vy: float, hay_bola: bool) -> void:
	var obj := objetivo(bola_y, bola_vy, hay_bola)
	var d := obj - y_actual
	# REGLA 4: zona muerta. Solo se mueve si el objetivo se ha ido lejos, y se
	# mueve hasta el borde de la zona, no hasta el centro.
	if absf(d) > p.zona_muerta:
		var borde := obj - signf(d) * p.zona_muerta
		var vel := p.suavizado if hay_bola else p.suavizado_reposo
		y_actual = lerpf(y_actual, borde, clampf(vel * delta, 0.0, 1.0))

	# Garantía dura de la REGLA 1: la bola no puede salirse de la pantalla por
	# quedarse la cámara atrás. Esto va ANTES del recorte a los límites de la
	# mesa, que manda: fuera de la mesa no hay nada que enseñar.
	if hay_bola:
		var media := p.alto_visible * 0.5
		y_actual = maxf(y_actual, bola_y + p.margen_bola - media)
		# Por arriba el margen es mayor: la franja del HUD tapa los primeros
		# 58 px de pantalla y la bola se escondía detrás en lo alto de la órbita.
		y_actual = minf(y_actual,
			bola_y + media - p.alto_franja_hud - p.margen_superior)
	y_actual = clampf(y_actual, limite_arriba(), limite_abajo())
	_colocar()

## La sacudida se actualiza a ritmo de fotograma, pero `avanzar` va con la
## física: hacer las dos cosas juntas dejaba la cámara con la posición de la
## bola de un fotograma antes, y en la órbita esos 22 px la metían tras el HUD.
func aplicar_sacudida(v: Vector2) -> void:
	sacudida = v
	offset = sacudida.round()

func _colocar() -> void:
	# REGLA 3: posición en píxeles enteros. Con posición fraccionaria, filtro
	# nearest y escalado entero, la mesa entera hierve.
	position = Vector2(roundf(centro_x), roundf(y_actual))
	offset = sacudida.round()

## Rectángulo de mesa que se está viendo. Para las pruebas y la depuración.
func rect_visible() -> Rect2:
	return Rect2(position.x - p.ancho_visible * 0.5,
		position.y - p.alto_visible * 0.5, p.ancho_visible, p.alto_visible)
