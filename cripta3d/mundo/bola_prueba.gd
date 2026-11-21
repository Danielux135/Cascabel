extends "res://cripta3d/cripta_3d.gd"

## CRIPTA 3D · la bola · LA ESCENA DE PRUEBA de los módulos «bola» y «efectos».
## Es la escena de siempre con tres mandos más, para mirar la bola de cerca y en
## multibola sin tener que jugar (en las capturas no hay teclado, y la tecla M
## no existe):
##
##   --bola-cerca[=D]     la cámara sigue a la primera bola a D unidades (0,55),
##                        desde arriba y del lado del jugador, como la de juego
##                        pero pegada
##   --multibola=T        a los T segundos suelta tres bolas más, de una en una
##   --tenir=I            a los 6 s fuerza que la criatura I (0 espectro,
##                        1 brasa, 2 calavera) se meta en la bola, sin esperar a
##                        la demo (la caza de verdad: almas y todo). Ojo: el
##                        piloto la asegura enseguida y la bola vuelve a su color
##   --ciclo-tinte        sin caza: tiñe la primera bola con el color del cuerpo
##                        de cada criatura, tres segundos cada una a partir de
##                        los 4 s (brasa, calavera, espectro). Es para mirar la
##                        ranura encendida con calma
##
##   --efectos=X,Y        dispara a mano, cada segundo desde los 2,3 s, los efectos
##                        de seis sucesos en ese punto de la mesa (en px): brasero,
##                        lápida, caída, escudo, golpe al espectro y la campana.
##                        Con `--ojo/--mira` apuntando allí y `--cada=0.5`, cada
##                        suceso sale dos veces: a 0,2 s y a 0,7 s
##
##   --desde=T            las capturas empiezan a los T s en vez de a los 2 (para
##                        mirar de cerca, con `--cada` corto, lo que pasa tarde)
##
##   python cripta3d/herramientas/godot3d.py escena res://cripta3d/mundo/bola_prueba.tscn --fotogramas 600 -- --capturas=C:/ruta --bola-cerca --cada=0.5
##
## No es del juego: no la carga nadie.

var _cerca := 0.0
var _multibola := -1.0
var _tenir := -1
var _sueltas := 0
var _rendida := false
var _ciclo := false
var _punto_fx := Vector2(-1.0, -1.0)
var _fx_hechos := 0
var _desde := -1.0
var _mis_capturas := ""
var _hechas := 0

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--bola-cerca"):
			_cerca = 0.55
			if arg.contains("="):
				_cerca = float(arg.get_slice("=", 1))
		elif arg.begins_with("--multibola="):
			_multibola = float(arg.get_slice("=", 1))
		elif arg.begins_with("--efectos="):
			var t := arg.get_slice("=", 1).split(",")
			_punto_fx = Vector2(float(t[0]), float(t[1]))
		elif arg.begins_with("--desde="):
			_desde = float(arg.get_slice("=", 1))
		elif arg == "--ciclo-tinte":
			_ciclo = true
		elif arg.begins_with("--tenir="):
			_tenir = int(arg.get_slice("=", 1))
	super._ready()
	# Las capturas las hago yo: las de la escena empiezan siempre a los 2 s.
	if _desde >= 0.0 and _dir_capturas != "":
		_mis_capturas = _dir_capturas
		_dir_capturas = ""

func _process(delta: float) -> void:
	if _multibola >= 0.0 and _sueltas < 3 and _tiempo > _multibola + 0.5 * float(_sueltas):
		mesa.soltar_bola_extra()
		_sueltas += 1
	# Solo se recoge una criatura rendida: primero se rinde (la brasa no se
	# rinde: se parte, y lo que se recoge es una de sus dos ascuas), luego se
	# recoge. Antes de los 5 s las criaturas todavía no han salido.
	if _tenir >= 0 and _tiempo > 5.0 and not _rendida:
		var c: Criatura = caza.criaturas[_tenir]
		caza.forzar(mesa, c, "golpe" if c.especie == "saltarin" else "rendir")
		_rendida = true
	# Se insiste cada cuadro hasta que entre: una ascua recién partida tarda en
	# poder recogerse.
	if _tenir >= 0 and _tiempo > 6.2:
		var c: Criatura = caza.criaturas[_tenir]
		var quien: Array = [c]
		if c.partida:
			quien = caza.mitades(c)
		for g: Criatura in quien:
			caza.forzar(mesa, g, "recoger")
			if g.estado == Criatura.Estado.EN_BOLA:
				print("PRUEBA: %s va dentro de la bola a los %.1f s" % [g.especie, _tiempo])
				_tenir = -1
				break
		if _tiempo > 12.0:
			print("PRUEBA: no he podido meter la criatura %d en la bola" % _tenir)
			_tenir = -1
	if _ciclo and _tiempo > 4.0 and not mesa.bolas.is_empty():
		var orden: Array[int] = [1, 2, 0]
		var cual := orden[mini(int((_tiempo - 4.0) / 3.0), 2)]
		var bola_mod: Object = mundo.modulo("bola")
		if bola_mod != null:
			bola_mod.call("tenir", mesa.bolas[0], mundo._color_del_cuerpo(mundo._bichos[cual]))
	if _punto_fx.x >= 0.0 and _fx_hechos < 6 and _tiempo > 2.3 + float(_fx_hechos):
		_disparar_efecto(_fx_hechos)
		_fx_hechos += 1
	super._process(delta)
	if _cerca > 0.0 and not mesa.bolas.is_empty():
		var p := mundo.posicion_bola(mesa.bolas[0])
		var ojo := p + Vector3(0.12, 0.62, 0.62).normalized() * _cerca
		camara.fov = 38.0
		camara.look_at_from_position(ojo, p, Vector3.UP)
		camara_reflejo.fov = 38.0
		camara_reflejo.cull_mask = 1 | MundoCripta.CAPA_DETALLE
		camara_reflejo.look_at_from_position(Vector3(ojo.x, -ojo.y, ojo.z),
			Vector3(p.x, -p.y, p.z), Vector3.UP)
	if _mis_capturas != "" and _tiempo > _desde + float(_hechas) * _cada and _hechas < 12:
		_capturar("%s/v%d_%02d.png" % [_mis_capturas, vista, _hechas])
		_hechas += 1

func _disparar_efecto(cual: int) -> void:
	var fx: Object = mundo.modulo("efectos")
	if fx == null:
		return
	var p := _punto_fx
	match cual:
		0:
			fx.call("_al_golpear_brasero", p, 700.0)
		1:
			fx.call("_al_abatir", p, 0)
		2:
			fx.call("_al_caer", p, 1, 0)
		3:
			fx.call("_al_abatir", p, 1)
		4:
			var col := mundo._color_del_cuerpo(mundo._bichos[0])
			mundo.chispear(p, 0.12, col, 14)
			mundo.onda(p, 0.02, col, 0.45)
		5:
			fx.call("_al_tocar_campana", p, 4.0)
