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
	print("PLANTA ALTA  ·  %d palas · %d bumpers · %d bancos · umbral en (%.0f,%.0f)"
		% [_palas_altas(m), m.bumpers.size(), m.bancos.size(),
		m.p.umbral_boca.x, m.p.umbral_boca.y])
	print("")
	_a_se_entra()
	_b_que_pasa_arriba()
	_c_se_caza_al_volver()
	quit()

func _palas_altas(m: Mesa) -> int:
	var n := 0
	for f in m.flippers:
		if f.eje.y < 660.0:
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

## La bola se mete por el umbral y se juega la caza entera CON PALAS, que es lo
## que la diferencia de la versión de pines: allí solo existía el temporizador y
## daba igual lo que hicieras. Aquí lo que se mide es si la planta alta se
## comporta como una mesa —golpes, y una bola que se pierde si no la juegas— o
## como un pasillo.
##
## El jugador de mentira es el mismo de siempre: aporrea las dos palas cuando la
## bola baja. No juega bien; sirve para saber si la mesa RESPONDE.
func _b_que_pasa_arriba() -> void:
	print("B · ARRIBA — 60 cazas enteras, con un jugador que aporrea las palas")
	var rng := RandomNumberGenerator.new()
	var golpes := 0
	var duracion := 0.0
	var por_drenaje := 0
	var por_tiempo := 0
	var mejor := 0
	var quietas := 0
	for s in SEMILLAS:
		rng.seed = s
		for _i in 10:
			var m := Mesa.new()
			var n := [0]
			var fin := [0]
			m.bumper_golpeado.connect(func(_p: Vector2, _f: float) -> void: n[0] += 1)
			m.target_abatido.connect(func(_p: Vector2, _b: int) -> void: n[0] += 1)
			m.girador_girado.connect(func(_p: Vector2, _i: int, _f: float) -> void: n[0] += 1)
			m.slingshot_golpeado.connect(func(_p: Vector2, _f: float) -> void: n[0] += 1)
			m.caza_terminada.connect(func(_p: Vector2) -> void: fin[0] += 1)
			var b := m.bola
			b.en_carril = false
			b.viva = true
			b.pos = m.p.umbral_boca
			b.vel = Vector2(rng.randf_range(-40.0, 40.0),
				-rng.randf_range(m.p.umbral_velocidad_minima + 60.0, 700.0))
			var t := 0.0
			var t0 := -1.0
			var pulso := 0.0
			var quieta := 0.0
			while t < m.p.caza_tiempo + 8.0 and b.viva:
				pulso -= DT
				if b.libre() and b.pos.y > m.p.arena_y_pala - 70.0 and b.vel.y > 0.0 \
						and pulso <= 0.0:
					pulso = 0.14
				var izq: bool = pulso > 0.0 and b.pos.x < 200.0
				var der: bool = pulso > 0.0 and b.pos.x >= 200.0
				m.flipper_alto_izq.pulsado = izq
				m.flipper_alto_der.pulsado = der
				m.avanzar(DT)
				t += DT
				if m.en_caza and t0 < 0.0:
					t0 = t
				if m.en_caza and b.libre() and b.velocidad() < 40.0:
					quieta += DT
				if fin[0] > 0:
					duracion += t - t0
					break
			golpes += n[0]
			mejor = maxi(mejor, n[0])
			if quieta > 1.5:
				quietas += 1
			if fin[0] > 0:
				if m.caza_por_drenaje:
					por_drenaje += 1
				else:
					por_tiempo += 1
	print("   golpes por caza: %.1f de media (%d el mejor)" % [float(golpes) / 60.0, mejor])
	print("   dura %.1f s de media (el tope son %.0f)"
		% [duracion / 60.0, Mesa.new().p.caza_tiempo])
	print("   acaba por DRENAR arriba %d veces y por AGOTAR el tiempo %d"
		% [por_drenaje, por_tiempo])
	print("   cazas con la bola muerta más de 1,5 s: %d de 60" % quietas)
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
