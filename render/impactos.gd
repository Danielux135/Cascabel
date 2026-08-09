class_name Impactos
extends RefCounted

## Onda expansiva, polvo y chispas.
##
## No es un nodo: la vista lo actualiza en `_process` y le pasa su propio
## CanvasItem en `dibujar()`. Así los efectos caen exactamente donde toca en el
## orden de dibujado (encima de la mesa, debajo de la bola y del HUD) sin tener
## que inventar otra capa por z_index.

var p: ParametrosImpacto
var rng := RandomNumberGenerator.new()

var _ondas: Array[Dictionary] = []
var _polvo: Array[Dictionary] = []
var _chispas: Array[Dictionary] = []

func _init(parametros: ParametrosImpacto = null) -> void:
	p = parametros if parametros != null else ParametrosImpacto.new()
	rng.randomize()

func vivos() -> int:
	return _ondas.size() + _polvo.size() + _chispas.size()

func limpiar() -> void:
	_ondas.clear()
	_polvo.clear()
	_chispas.clear()

# ------------------------------------------------------------------ disparar

func onda(pos: Vector2, color: Color, escala: float = 1.0) -> void:
	_ondas.append({"pos": pos, "col": color, "t": p.onda_duracion, "escala": escala})

## `direccion` es hacia dónde sale el material. Vector2.ZERO = en todas.
func polvo(pos: Vector2, direccion: Vector2, color: Color, escala: float = 1.0) -> void:
	var cuantos := maxi(int(roundf(float(p.polvo_cantidad) * escala)), 1)
	for _i in cuantos:
		var d := _direccion(direccion, p.polvo_dispersion)
		_polvo.append({
			"pos": pos,
			"vel": d * p.polvo_velocidad * rng.randf_range(0.5, 1.0),
			"t": p.polvo_duracion * rng.randf_range(0.7, 1.0),
			"vida": p.polvo_duracion,
			"col": color,
		})
	_recortar()

func chispas(pos: Vector2, direccion: Vector2, color: Color, escala: float = 1.0) -> void:
	var cuantos := maxi(int(roundf(float(p.chispa_cantidad) * escala)), 1)
	for _i in cuantos:
		var d := _direccion(direccion, p.chispa_dispersion)
		var v := p.chispa_velocidad * rng.randf_range(
			1.0 - p.chispa_variacion, 1.0 + p.chispa_variacion)
		_chispas.append({
			"pos": pos,
			"anterior": pos,
			"vel": d * v,
			"t": p.chispa_duracion * rng.randf_range(0.6, 1.0),
			"vida": p.chispa_duracion,
			"col": color,
		})
	_recortar()

func _direccion(base: Vector2, dispersion: float) -> Vector2:
	if base.length_squared() < 0.0001:
		return Vector2.RIGHT.rotated(rng.randf_range(-PI, PI))
	return base.normalized().rotated(rng.randf_range(-dispersion, dispersion))

## Tira lo más viejo cuando se acumula. Pasado el tope no se distingue nada
## nuevo, así que solo costaría.
func _recortar() -> void:
	var sobran := _polvo.size() + _chispas.size() - p.maximo_particulas
	while sobran > 0 and not _polvo.is_empty():
		_polvo.remove_at(0)
		sobran -= 1
	while sobran > 0 and not _chispas.is_empty():
		_chispas.remove_at(0)
		sobran -= 1

# ------------------------------------------------------------------- avanzar

func avanzar(delta: float) -> void:
	var frena_polvo := exp(-p.polvo_frenado * delta)
	var frena_chispa := exp(-p.chispa_frenado * delta)

	var vivas: Array[Dictionary] = []
	for o in _ondas:
		o["t"] -= delta
		if o["t"] > 0.0:
			vivas.append(o)
	_ondas = vivas

	vivas = []
	for d in _polvo:
		d["t"] -= delta
		if d["t"] <= 0.0:
			continue
		d["vel"] = (d["vel"] as Vector2) * frena_polvo \
			+ Vector2(0, p.polvo_gravedad * delta)
		d["pos"] = (d["pos"] as Vector2) + (d["vel"] as Vector2) * delta
		vivas.append(d)
	_polvo = vivas

	vivas = []
	for c in _chispas:
		c["t"] -= delta
		if c["t"] <= 0.0:
			continue
		c["anterior"] = c["pos"]
		c["vel"] = (c["vel"] as Vector2) * frena_chispa \
			+ Vector2(0, p.chispa_gravedad * delta)
		c["pos"] = (c["pos"] as Vector2) + (c["vel"] as Vector2) * delta
		vivas.append(c)
	_chispas = vivas

# ------------------------------------------------------------------- dibujar

func dibujar(lienzo: CanvasItem) -> void:
	# Polvo primero, que va por detrás: es lo que se queda posándose.
	for d in _polvo:
		var k: float = float(d["t"]) / float(d["vida"])
		var col: Color = d["col"]
		col.a = p.polvo_alfa * clampf(k * 1.4, 0.0, 1.0)
		var lado := p.polvo_tamano + int(roundf((1.0 - k) * float(p.polvo_crecimiento)))
		var esquina := ((d["pos"] as Vector2) - Vector2(lado, lado) * 0.5).round()
		lienzo.draw_rect(Rect2(esquina, Vector2(lado, lado)), col)

	for c in _chispas:
		var k: float = float(c["t"]) / float(c["vida"])
		var col: Color = c["col"]
		col.a = clampf(k * 1.6, 0.0, 1.0)
		lienzo.draw_line((c["anterior"] as Vector2).round(),
			(c["pos"] as Vector2).round(), col, p.chispa_grosor)

	# La onda encima de todo el material, que es lo que marca el punto.
	for o in _ondas:
		var k := 1.0 - float(o["t"]) / p.onda_duracion       # 0 -> 1
		var suave := 1.0 - pow(1.0 - k, 2.0)                 # sale rápido y frena
		var radio := roundf(lerpf(p.onda_radio_inicial,
			p.onda_radio_final * float(o["escala"]), suave))
		var col: Color = o["col"]
		col.a = p.onda_alfa * (1.0 - k)
		lienzo.draw_circle((o["pos"] as Vector2).round(), radio, col, false,
			lerpf(p.onda_grosor_inicial, p.onda_grosor_final, suave))
