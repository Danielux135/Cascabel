extends SceneTree

## Mide la zona alta: el umbral, la arena y el regreso.
##   godot --headless --path . --script tests/medir_caza.gd
##
## No es una prueba: imprime tablas. Contesta las tres preguntas que deciden si
## la caza existe de verdad:
##   A. ¿Se puede ENTRAR? (si no, la arena es decorado carísimo)
##   B. ¿Pasa algo arriba, y la bola no se atasca ni se queda muerta?
##   C. ¿Se puede CAZAR la bola al volver? (bajar no puede costar la bola)

const DT := 1.0 / 120.0
const SEMILLAS := [7, 13, 271, 4242, 90210, 31337]

var _pines := 0
var _cazas := 0
var _fin := 0

func _initialize() -> void:
	print("")
	var m := Mesa.new()
	print("ZONA ALTA  ·  %d pines en la arena · umbral en (%.0f,%.0f) · caza de %.0f s"
		% [_pines_arriba(m), m.p.umbral_boca.x, m.p.umbral_boca.y, m.p.caza_tiempo])
	print("")
	_a_se_entra()
	_b_que_pasa_arriba()
	_c_se_caza_al_volver()
	quit()

func _pines_arriba(m: Mesa) -> int:
	var n := 0
	for v in m.pines:
		if v.y < 660.0:
			n += 1
	return n

# ------------------------------------------------------------- A. ¿se entra?

## Desde el racimo, que es la única ruta: el umbral está al otro lado de la
## bóveda y a la bóveda solo se llega con un empujón bueno de los bumpers.
func _a_se_entra() -> void:
	print("A · ¿SE ENTRA? — 240 entradas al racimo desde abajo")
	var rng := RandomNumberGenerator.new()
	var entradas := 0
	var intentos := 0
	for s in SEMILLAS:
		rng.seed = s
		for _i in 40:
			var m := Mesa.new()
			_cazas = 0
			m.caza_empezada.connect(func(_p: Vector2) -> void: _cazas += 1)
			var b := m.bola
			b.en_carril = false
			b.viva = true
			b.pos = m.p.bumper_centro + Vector2(rng.randf_range(-16.0, 16.0), 120.0)
			b.vel = Vector2(rng.randf_range(-60.0, 60.0), -rng.randf_range(600.0, 1100.0))
			var t := 0.0
			while t < 6.0 and b.viva and _cazas == 0:
				m.avanzar(DT)
				t += DT
				if b.libre() and b.pos.y > 1000.0:
					break
			intentos += 1
			if _cazas > 0:
				entradas += 1
	print("   se abre la caza en %d de %d entradas (%.0f %%)"
		% [entradas, intentos, float(entradas) * 100.0 / float(intentos)])
	print("   %s" % ("bien: es difícil pero se llega" if entradas > 0
		else "MAL: nadie va a ver la arena nunca"))
	print("")

# --------------------------------------------------- B. ¿qué pasa ahí arriba?

## La bola se mete en el umbral a mano y se deja correr la caza entera. Lo que
## se mira: cuánto traquetea, si se queda muerta en un rincón, y si el
## temporizador la devuelve como dice.
func _b_que_pasa_arriba() -> void:
	print("B · ARRIBA — 60 cazas enteras, entrando por el umbral")
	var rng := RandomNumberGenerator.new()
	var pines := 0
	var quietas := 0
	var no_vuelven := 0
	var mejor := 0
	var peor_pines := 999
	for s in SEMILLAS:
		rng.seed = s
		for _i in 10:
			var m := Mesa.new()
			m.p.busqueda_tiempo = 1e9   # sin red: que se vea si se queda muerta
			m = Mesa.new(m.p)
			_pines = 0
			_fin = 0
			m.pin_golpeado.connect(func(_p: Vector2, _f: float) -> void: _pines += 1)
			m.caza_terminada.connect(func(_p: Vector2) -> void: _fin += 1)
			var b := m.bola
			b.en_carril = false
			b.viva = true
			b.pos = m.p.umbral_boca
			b.vel = Vector2(rng.randf_range(-40.0, 40.0),
				-rng.randf_range(m.p.umbral_velocidad_minima + 60.0, 700.0))
			var t := 0.0
			var quieta := 0.0
			while t < m.p.caza_tiempo + 6.0 and b.viva:
				m.avanzar(DT)
				t += DT
				if m.en_caza and b.libre() and b.velocidad() < 40.0:
					quieta += DT
				if _fin > 0 and b.libre() and b.pos.y > 1000.0:
					break
			pines += _pines
			mejor = maxi(mejor, _pines)
			peor_pines = mini(peor_pines, _pines)
			if quieta > 1.5:
				quietas += 1
			if _fin == 0:
				no_vuelven += 1
	print("   pines por caza: %.1f de media (la mejor %d, la peor %d)"
		% [float(pines) / 60.0, mejor, peor_pines])
	print("   cazas con la bola muerta más de 1,5 s: %d de 60" % quietas)
	print("   cazas que no terminan: %d de 60" % no_vuelven)
	print("")

# ------------------------------------------------- C. ¿se caza al volver?

## LA PREGUNTA QUE PUEDE TIRAR EL MODO. Bajar 500 px cayendo llega a 1500 px/s y
## un humano reacciona en 250 ms; el cañón ya se tuvo que ablandar a la mitad
## por eso mismo. Si el regreso escupe la bola incazable, la caza es un impuesto.
func _c_se_caza_al_volver() -> void:
	print("C · EL REGRESO — 60 vueltas, ¿llega la bola a una pala y a qué velocidad?")
	var rng := RandomNumberGenerator.new()
	var llegan := 0
	var suma_v := 0.0
	var suma_ms := 0.0
	var perdidas := 0
	for s in SEMILLAS:
		rng.seed = s
		for _i in 10:
			var m := Mesa.new()
			var b := m.bola
			b.en_carril = false
			b.viva = true
			b.pos = m.p.umbral_boca
			b.vel = Vector2(rng.randf_range(-40.0, 40.0), -520.0)
			var t := 0.0
			# OJO: `salida` es un Array de un elemento a propósito. Un lambda de
			# GDScript captura las locales POR VALOR, así que con un float suelto
			# la asignación de dentro no sale del lambda y la medida dice que el
			# regreso no salta nunca. Está en CLAUDE.md, "Trampas".
			var salida := [-1.0]
			var v_salida := 0.0
			m.rampa_salida.connect(func(_p: Vector2, i: int) -> void:
				if i == m.regreso:
					salida[0] = 0.0)
			while t < 30.0 and b.viva:
				m.avanzar(DT)
				t += DT
				if salida[0] >= 0.0:
					if v_salida <= 0.0:
						v_salida = b.velocidad()
					salida[0] += DT
					# ¿Ha llegado a la zona de una pala?
					if b.pos.distance_to(m.p.flipper_eje_izq) < 80.0 \
							or b.pos.distance_to(m.p.flipper_eje_der) < 80.0:
						llegan += 1
						suma_v += v_salida
						suma_ms += salida[0] * 1000.0
						break
					if b.pos.y > 1290.0:
						perdidas += 1
						break
			if salida[0] < 0.0:
				perdidas += 1
	if llegan > 0:
		print("   llega a una pala en %d de 60 vueltas" % llegan)
		print("   sale a %.0f px/s y tarda %.0f ms en llegar (un humano reacciona en 250)"
			% [suma_v / float(llegan), suma_ms / float(llegan)])
	else:
		print("   MAL: no llega a la pala ni una vez")
	print("   se pierde sin tocar pala: %d de 60" % perdidas)
	print("")
