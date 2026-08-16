class_name NodoSonido
extends Node

## Reproduce los wav de assets/sonido/, generados por sonidos.py.
##
## Va con un banco de voces en rueda porque en una bola buena se solapan cuatro
## o cinco golpes: con un solo reproductor, cada bumper cortaría al anterior y
## el racimo sonaría a un solo clic.

const RUTA := "res://assets/sonido/%s.wav"
const VOCES := 14

## Ajuste por sonido. `db` es el volumen final y `tono` cuánto se desafina al
## azar cada vez: los que suenan muchas veces seguidas necesitan variación o el
## oído los convierte en un zumbido. Los que suenan una vez van clavados.
const AJUSTES := {
	"bumper":        {"db": -3.0, "tono": 0.10},
	"target":        {"db": -4.0, "tono": 0.08},
	"banco":         {"db": -1.0, "tono": 0.00},
	"atrapar":       {"db": -7.0, "tono": 0.00},
	"flipper":       {"db": -9.0, "tono": 0.06},
	"rampa_entrada": {"db": -3.0, "tono": 0.02},
	"rampa_salida":  {"db": -3.0, "tono": 0.02},
	"rampa_fuerte":  {"db": -1.0, "tono": 0.03},
	"platillo":      {"db": -2.0, "tono": 0.00},
	"combo":         {"db":  1.0, "tono": 0.00},
	"reloj":         {"db": -4.0, "tono": 0.00},
	"atrasar":       {"db": -1.0, "tono": 0.00},
	"ataque":        {"db":  0.0, "tono": 0.00},
	"drenaje":       {"db": -2.0, "tono": 0.00},
	"muerte":        {"db":  0.0, "tono": 0.00},
}

## Sonidos con reproductor propio, fuera de la rueda. El arpegio del
## multiplicador dura medio segundo y en ese medio segundo caben catorce
## golpes de racimo: en la rueda se lo llevaba por delante su propio banco.
##
## El reloj y su golpe van igual, y por el mismo motivo: los tres son
## información, no adorno, y los tres suenan justo cuando hay más ruido.
const PROPIOS := ["combo", "reloj", "ataque", "atrasar"]

var _voces: Array[AudioStreamPlayer] = []
var _propias: Dictionary = {}
var _streams: Dictionary = {}
var _siguiente: int = 0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	for nombre in AJUSTES:
		var ruta: String = RUTA % nombre
		if ResourceLoader.exists(ruta):
			_streams[nombre] = load(ruta)
		else:
			push_warning("Falta %s. Se genera con: python sonidos.py" % ruta)
	for _i in VOCES:
		var v := AudioStreamPlayer.new()
		add_child(v)
		_voces.append(v)
	for nombre in PROPIOS:
		var v := AudioStreamPlayer.new()
		add_child(v)
		_propias[nombre] = v

## `tono_extra` multiplica el tono por encima de la variación del sonido. Se
## usa para que el arpegio del multiplicador suene más agudo cuanto más alto es
## el tramo: el mismo sonido pero subiendo, que es lo que pide el oído.
func reproducir(nombre: String, tono_extra: float = 1.0) -> void:
	var stream: AudioStream = _streams.get(nombre)
	if stream == null:
		return
	var ajuste: Dictionary = AJUSTES.get(nombre, {})
	var v: AudioStreamPlayer = _propias.get(nombre)
	if v == null:
		v = _voces[_siguiente]
		_siguiente = (_siguiente + 1) % _voces.size()
	v.stream = stream
	v.volume_db = float(ajuste.get("db", 0.0))
	var tono: float = float(ajuste.get("tono", 0.0))
	var base := 1.0 if tono <= 0.0 else _rng.randf_range(1.0 - tono, 1.0 + tono)
	v.pitch_scale = clampf(base * tono_extra, 0.2, 4.0)
	v.play()
