extends SceneTree
## LAS NUEVE RAMPAS: qué sube cada una, con qué velocidad se entra en ella
## jugando, y qué haría cada `velocidad_escape` candidata con esas entradas.
##
##   godot --headless --path . --script tests/sonda_rampas.gd
##
## No es una prueba: imprime tablas. Existe porque poner cuesta a una rampa es
## poner un número CONTRA UNA DISTRIBUCIÓN, y la distribución no se adivina: con
## 640, la subida a la isla tenía la frontera en 384 contra un enganche mínimo de
## 300 y todo lo que enganchaba coronaba. La tabla C es la que impide repetirlo.
##
## La mitad B usa DOS maniquíes a propósito, porque miden cosas distintas:
##   - el que APORREA entra en lo que está en el camino de la bola (la órbita,
##     el racimo). En `retorno` y en `canon` no entra nunca: son tiros apuntados.
##   - el que ATRAPA y suelta da tiros de pala enteros, que es lo que produce
##     las entradas rápidas.
const DT := 1.0 / 120.0
const BOLAS := 90
const CAZAS := 60
const _ESPERA_TIRO := 0.5
const CANDIDATOS := [0.0, 600.0, 700.0, 800.0, 900.0, 950.0, 1000.0, 1100.0, 1200.0, 1400.0]

var _ent := {}      # nombre -> Array de [velocidad, subida] de las ENTRADAS
## Y las veces que la bola PASA por una boca yendo hacia dentro sin llegar a
## entrar: rozándola de lejos, o por debajo de `velocidad_minima`. Es la
## población de "tiros a esa rampa", y hace falta porque en `retorno` y en
## `canon` ningún maniquí acierta lo bastante para llenar una muestra.
var _pas := {}

func _initialize() -> void:
	print("")
	_geometria()
	_jugar()
	_tabla_entradas()
	_tabla_pases()
	_barrido()
	quit()

func _geometria() -> void:
	var m := Mesa.new(ParametrosMesa.new())
	print("=== A · GEOMETRÍA: cuánto sube cada rampa desde cada boca ===")
	print("   rampa            largo  sube(+)  sube(-)   min ent.  bidir  tipo")
	for r0 in m.rampas:
		var r := r0 as Rampa
		var s2 := r.subida_maxima(-1) if r.bidireccional else -1.0
		var tipo := "TUBO"
		if r.subterranea:
			tipo = "TUNEL"
		elif r.abierta:
			tipo = "CARRIL"
		print("   %-15s %5.0f   %6.0f   %6s   %8s  %-5s  %s"
			% [r.nombre, r.largo, r.subida_maxima(1),
			("%.0f" % s2) if s2 >= 0.0 else "—",
			("INF" if r.velocidad_minima == INF else "%.0f" % r.velocidad_minima),
			"sí" if r.bidireccional else "no", tipo])
	print("")
	print("   «sube» = de la boca al punto MÁS ALTO de la curva, en px de mesa. Es el")
	print("   denominador de la cuenta de energía: por debajo de %.0f la cuesta se apaga"
		% Rampa.SUBIDA_MINIMA)
	print("   sola, y por eso los dos túneles y el regreso no se pueden fallar.")
	print("")

## Cuenta un paso por la boca: cerca, yendo en la dirección de la rampa y con
## velocidad de tiro. El radio es el doble del de enganche a propósito — un tiro
## que roza la boca es el mismo tiro que uno que la acierta, y aquí lo que se
## está midiendo es a qué velocidad LLEGA la bola a ese sitio, no si entra.
func _mirar_bocas(m: Mesa) -> void:
	var b := m.bola
	if not b.libre():
		return
	var v := b.velocidad()
	if v < 80.0:
		return
	var dir := b.vel / v
	for j in m.rampas.size():
		var r := m.rampas[j] as Rampa
		for sentido in ([1, -1] if r.bidireccional else [1]):
			var tang := r.tangente_en(0.0) if sentido > 0 else -r.tangente_en(r.largo)
			if b.pos.distance_to(r.boca(sentido)) > r.entrada_radio * 2.0:
				continue
			if dir.dot(tang) < 0.45:
				continue
			if not _pas.has(r.nombre):
				_pas[r.nombre] = []
			(_pas[r.nombre] as Array).append([v, sentido])
			return

func _apuntar(m: Mesa) -> void:
	m.rampa_entrada.connect(func(_pt: Vector2, j: int) -> void:
		var nom: String = (m.rampas[j] as Rampa).nombre
		if not _ent.has(nom):
			_ent[nom] = []
		(_ent[nom] as Array).append([m.bola.rampa_velocidad, m.bola.rampa_subida]))

func _jugar() -> void:
	var p := ParametrosMesa.new()
	print("=== B · CON QUÉ VELOCIDAD SE ENTRA, JUGANDO ===")
	print("   %d bolas abajo (mitad aporreando, mitad atrapando) + %d cazas arriba"
		% [BOLAS, CAZAS])
	for s in BOLAS:
		var atrapa := (s % 2) == 1
		var rng := RandomNumberGenerator.new()
		rng.seed = 31000 + s
		var m := Mesa.new(p)
		m.rng.seed = 31000 + s
		_apuntar(m)
		m.nueva_bola()
		m.cargar_lanzador(p.tiempo_carga_lanzador * rng.randf_range(0.7, 1.0))
		m.soltar_lanzador()
		var b := m.bola
		var t := 0.0
		var pulso := 0.0
		var quieta := 0.0
		var solo_izq := (s % 4) < 2
		while t < 40.0 and b.viva:
			if atrapa:
				var posada: bool = b.libre() and m.flipper_atrapando != null
				quieta = quieta + DT if posada else 0.0
				var sube: bool = b.libre() and b.pos.y > p.y_drenaje - 260.0 \
					and quieta < _ESPERA_TIRO
				m.flipper_izq.pulsado = sube and (solo_izq or b.pos.x < Mesa.ANCHO * 0.5)
				m.flipper_der.pulsado = sube and (not solo_izq or b.pos.x >= Mesa.ANCHO * 0.5)
				if quieta >= _ESPERA_TIRO:
					quieta = 0.0
			else:
				pulso -= DT
				if b.libre() and b.pos.y > p.y_drenaje - 260.0 and b.vel.y > 0.0 \
						and pulso <= 0.0:
					pulso = 0.14
				m.flipper_izq.pulsado = pulso > 0.0 and b.pos.x < Mesa.ANCHO * 0.5
				m.flipper_der.pulsado = pulso > 0.0 and b.pos.x >= Mesa.ANCHO * 0.5
			m.flipper_alto_izq.pulsado = m.flipper_izq.pulsado
			m.flipper_alto_der.pulsado = m.flipper_der.pulsado
			m.avanzar(DT)
			t += DT
			_mirar_bocas(m)
	for s in CAZAS:
		var rng := RandomNumberGenerator.new()
		rng.seed = 90000 + s
		var m := Mesa.new(p)
		m.rng.seed = 90000 + s
		_apuntar(m)
		var b := m.bola
		b.en_carril = false
		b.viva = true
		b.pos = p.umbral_boca
		b.vel = Vector2(rng.randf_range(-40.0, 40.0),
			-rng.randf_range(p.umbral_velocidad_minima + 60.0, 700.0))
		var fin := [0]
		m.caza_terminada.connect(func(_pt: Vector2) -> void: fin[0] += 1)
		var t := 0.0
		var pulso := 0.0
		while t < p.caza_tiempo + 8.0 and b.viva and fin[0] == 0:
			pulso -= DT
			if b.libre() and b.pos.y > p.arena_y_pala - 70.0 and b.vel.y > 0.0 \
					and pulso <= 0.0:
				pulso = 0.14
			m.flipper_alto_izq.pulsado = pulso > 0.0 and b.pos.x < Mesa.ANCHO * 0.5
			m.flipper_alto_der.pulsado = pulso > 0.0 and b.pos.x >= Mesa.ANCHO * 0.5
			m.avanzar(DT)
			t += DT
			_mirar_bocas(m)

func _ordenadas(nom: String) -> Array:
	var v := []
	for e in (_ent.get(nom, []) as Array):
		v.append(float(e[0]))
	v.sort()
	return v

func _tabla_pases() -> void:
	var m := Mesa.new(ParametrosMesa.new())
	print("   Y LO MISMO CONTANDO LOS ROCES, no solo las entradas: a qué velocidad")
	print("   LLEGA la bola a cada boca yendo hacia dentro. `retorno` y `canon` son")
	print("   tiros apuntados y ningún maniquí los mete, así que su calibración sale")
	print("   de aquí — de lo que la mesa produce en ese sitio, no de dos muestras.")
	print("   rampa              n   min   p25  mediana   p75   max")
	for r0 in m.rampas:
		var r := r0 as Rampa
		var o := []
		for e in (_pas.get(r.nombre, []) as Array):
			o.append(float(e[0]))
		o.sort()
		if o.is_empty():
			print("   %-15s %4d   (nunca pasa por ahí)" % [r.nombre, 0])
			continue
		print("   %-15s %4d  %4.0f  %4.0f    %5.0f  %4.0f  %4.0f"
			% [r.nombre, o.size(), o[0], o[int(o.size() * 0.25)],
			o[o.size() / 2], o[int(o.size() * 0.75)], o[o.size() - 1]])
	print("")

func _tabla_entradas() -> void:
	var m := Mesa.new(ParametrosMesa.new())
	print("   rampa              n   min   p25  mediana   p75   max   sube")
	for r0 in m.rampas:
		var r := r0 as Rampa
		var o := _ordenadas(r.nombre)
		if o.is_empty():
			print("   %-15s %4d   (nunca se entra)                    %5.0f"
				% [r.nombre, 0, r.subida_maxima(1)])
			continue
		print("   %-15s %4d  %4.0f  %4.0f    %5.0f  %4.0f  %4.0f   %5.0f"
			% [r.nombre, o.size(), o[0], o[int(o.size() * 0.25)],
			o[o.size() / 2], o[int(o.size() * 0.75)], o[o.size() - 1],
			r.subida_maxima(1)])
	print("")

## Qué haría cada candidato con las entradas de verdad. Se calcula sobre la
## población medida en vez de rejugar la mesa por candidato: el fallo depende
## SOLO de `v_entrada` contra `escape·0,6`, y dónde se suelta es la misma cuenta
## de energía despejada. Rejugar seis veces daría los mismos números y 20 min.
func _barrido() -> void:
	var m := Mesa.new(ParametrosMesa.new())
	print("=== C · QUÉ HARÍA CADA `velocidad_escape` CON ESAS ENTRADAS ===")
	print("   «cae a» = a qué fracción de la SUBIDA se suelta la bola que falla, de")
	print("   media. Cerca de 1 es quedarse a medias de verdad; cerca de 0 es que la")
	print("   rampa te escupe en la boca, que se lee como un rebote y no como fallar.")
	for r0 in m.rampas:
		var r := r0 as Rampa
		var e := _ent.get(r.nombre, []) as Array
		var de_roces := false
		if e.size() < 15:
			# Muestra corta: se calibra con los roces que HABRÍAN entrado, o sea
			# los que van por encima del mínimo de enganche. Es la misma
			# población, medida con el radio de la boca al doble.
			e = []
			for par in (_pas.get(r.nombre, []) as Array):
				if float(par[0]) >= r.velocidad_minima:
					e.append(par)
			de_roces = true
		if e.is_empty():
			continue
		print("")
		print("   %s  (n=%d%s, sube %.0f/%.0f)"
			% [r.nombre.to_upper(), e.size(), " · de ROCES" if de_roces else "",
			r.subida_maxima(1),
			r.subida_maxima(-1) if r.bidireccional else r.subida_maxima(1)])
		print("      escape  frontera   falla   cae a   nunca corona")
		for esc0 in CANDIDATOS:
			var esc := float(esc0)
			var frontera := esc * Rampa.UMBRAL_CORONA
			var falla := 0
			var suma := 0.0
			var imposible := true
			for par in e:
				var v: float = par[0]
				var sub: float = r.subida_maxima(int(par[1]))
				if esc <= 0.0 or sub < Rampa.SUBIDA_MINIMA:
					imposible = false
					continue
				if v >= frontera:
					imposible = false
					continue
				falla += 1
				suma += clampf((v * v) / (frontera * frontera), 0.0, 1.0)
			var pct := 100.0 * float(falla) / float(e.size())
			print("      %6.0f  %8.0f  %5.0f %%  %5s   %s"
				% [esc, frontera, pct,
				("%.0f %%" % (100.0 * suma / float(maxi(falla, 1)))) if falla > 0 else "—",
				"SÍ ← inútil" if imposible else ""])
	print("")
