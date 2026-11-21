extends "res://cripta3d/visor.gd"

## CRIPTA 3D — EL BANCO DEL ESPECTRO. El mismo plató que el visor (hereda de
## él), con otro guion de escenas: las que el visor no tiene y son del espectro.
##
##   python cripta3d/herramientas/godot3d.py escena res://cripta3d/criaturas/espectro_banco.tscn \
##       --fotogramas 800 -- --capturas=C:/ruta/salida
##
##   · escondido     dentro de la catacumba: solo la luz bajo la losa, corriendo
##   · asoma         sale de la catacumba (aparecer) con miedo a cuestas
##   · el miedo      cómo se cierra el cerco de sal: 0,25 · 0,5 · 0,85
##   · acorralado    el cerco barriéndose: al principio, a media y al final
##   · alerta        el respingo en dos tiempos (el tirón y la caída)
##
##   --todo        además, delante, todas las escenas del visor
##
## Del visor solo cambia `_guion_criatura` y EL ENCUADRE: el visor sigue a la
## criatura con un muelle (8/s) y, huyendo a 185 px/s o despedida por un golpe,
## se le queda atrás y la deja cortada en el borde (huir_0, golpe_1). Aquí la
## cámara va pegada al CENTRO DEL CUERPO, sin retraso. El guion del cuerpo y la
## especie se ponen aquí, para no tener que pasarlos.

func _ready() -> void:
	_guion = "res://cripta3d/criaturas/espectro.gd"
	_especie = "corredor"
	super._ready()

func _guion_criatura() -> Array:
	var S := Criatura.Estado
	var antes: Array = []
	if "--todo" in OS.get_cmdline_user_args():
		antes = super._guion_criatura()
	return antes + [
		{"nombre": "escondido", "estado": S.ESCONDIDA, "dur": 1.2, "tomas": [0.4, 1.0],
			"cam": "picado"},
		{"nombre": "escondido_juego", "estado": S.ESCONDIDA, "dur": 0.6, "tomas": [0.4],
			"cam": "juego"},
		{"nombre": "asoma", "estado": S.APARECER, "dur": 0.8, "tomas": [0.15, 0.32, 0.7],
			"cam": "tres_cuartos", "quieta": true, "miedo": 0.4},
		{"nombre": "miedo_025", "estado": S.CORRER, "dur": 0.6, "tomas": [0.5],
			"cam": "picado", "quieta": true, "miedo": 0.25},
		{"nombre": "miedo_050", "estado": S.CORRER, "dur": 0.6, "tomas": [0.5],
			"cam": "picado", "quieta": true, "miedo": 0.5},
		{"nombre": "miedo_085", "estado": S.HUIR, "dur": 0.6, "tomas": [0.5],
			"cam": "picado", "quieta": true, "miedo": 0.85},
		{"nombre": "acorralado", "estado": S.ACORRALADA, "dur": 5.0, "tomas": [0.6, 2.6, 4.6],
			"cam": "picado", "quieta": true, "miedo": 1.0},
		{"nombre": "acorralado_juego", "estado": S.ACORRALADA, "dur": 0.8, "tomas": [0.6],
			"cam": "juego", "quieta": true, "miedo": 1.0},
		{"nombre": "alerta", "estado": S.ALERTA, "dur": 0.6, "tomas": [0.08, 0.40],
			"cam": "tres_cuartos", "quieta": true},
	]

func _encuadrar(_delta: float, esc: Dictionary) -> void:
	var cam: Dictionary = CAMARAS.get(str(esc.get("cam", "tres_cuartos")), CAMARAS["tres_cuartos"])
	var centro: Vector3 = cuerpo.call("centro")
	_cam_centro = Vector3(centro.x, 0.0, centro.z)
	_cam_salto = false
	var k := 1.0 if str(esc.get("cam", "")) == "juego" else maxf(c.radio / 10.5, 1.0)
	camara.fov = float(cam["fov"])
	camara.position = _cam_centro + (cam["pos"] as Vector3) * k
	camara.look_at(_cam_centro + (cam["mira"] as Vector3) * k, Vector3.UP)
