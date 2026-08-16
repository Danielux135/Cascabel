extends SceneTree

## Mide el campo de pines CON FÍSICA DE VERDAD:
##   godot --headless --path . --script tests/medir_pines.gd
##
## Esto no es una prueba: no falla, imprime tablas. Existe porque los perfiles
## de `medir_balance.gd` y `medir_daniel.gd` no tienen física dentro, así que no
## saben cuántos pines toca una bola —y sin ese número, meter "pines" en un
## perfil sería inventárselo—.
##
## Tres medidas, y cada una contesta una pregunta distinta:
##   A. ¿Se acuña la bola en la bóveda?   (la que puede tirar la tanda entera)
##   B. ¿Cuántos pines toca una entrada de racimo?  (el número que va al perfil)
##   C. ¿Cambia la duración de bola?      (si sube, el balance entero se mueve)

const DT := 1.0 / 120.0
const SEMILLAS := [7, 13, 271, 4242, 90210, 31337, 55, 808, 1234, 99]

var _pines := 0
var _bumpers := 0

func _initialize() -> void:
	var m := Mesa.new()
	print("")
	print("CAMPO DE PINES  ·  %d pines · paso mínimo %.1f px · bola %.0f px"
		% [m.pines.size(), m.paso_minimo_pines(), m.p.radio_bola * 2.0])
	print("")
	_dibujar(m)
	_a_acunarse(m)
	_b_tiro_desde_la_cuna()
	_c_duracion_y_drenaje()
	_d_por_donde_se_entra()
	quit()

# ------------------------------------------------------------------ el mapa

func _dibujar(m: Mesa) -> void:
	print("  la bóveda, de x=20 a x=380 y de y=650 a y=880")
	var alto := 12
	var ancho := 72
	var lienzo: Array[PackedStringArray] = []
	for _f in alto:
		var fila := PackedStringArray()
		for _c in ancho:
			fila.append(" ")
		lienzo.append(fila)
	var poner := func(v: Vector2, ch: String) -> void:
		var c := int(round((v.x - 20.0) / 360.0 * float(ancho - 1)))
		var f := int(round((v.y - 650.0) / 230.0 * float(alto - 1)))
		if f >= 0 and f < alto and c >= 0 and c < ancho:
			lienzo[f][c] = ch
	for c in m.colisionadores:
		if c.tipo != Colisionador.Tipo.PARED:
			continue
		for t in 9:
			poner.call(c.a.lerp(c.b, float(t) / 8.0), "-")
	for b in m.bumpers:
		poner.call(b, "O")
	for pl in m.platillos:
		poner.call(pl.centro, "P")
	for v in m.pines:
		poner.call(v, "*")
	for fila in lienzo:
		print("  |" + "".join(fila) + "|")
	print("")

# ---------------------------------------------------- A. ¿se acuña la bola?

## Se sueltan bolas dentro de la bóveda desde todas partes y a todas las
## velocidades, y se mira CUÁNTO TARDAN EN SALIR. El ball search está apagado a
## propósito: con él puesto, una bola acuñada saldría a los 2 s y la medida
## diría que todo va bien tapando justo lo que se quiere ver.
func _a_acunarse(_m: Mesa) -> void:
	print("A · ¿SE ACUÑA? — 600 bolas soltadas dentro de la bóveda, sin ball search")
	var rng := RandomNumberGenerator.new()
	var peor := 0.0
	var atascadas := 0
	var suma := 0.0
	for s in SEMILLAS:
		rng.seed = s
		for _i in 60:
			var m := Mesa.new()
			m.p.busqueda_tiempo = 1e9
			var b := m.bola
			b.en_carril = false
			b.viva = true
			b.pos = Vector2(rng.randf_range(60.0, 340.0), rng.randf_range(690.0, 750.0))
			b.vel = Vector2(rng.randf_range(-400.0, 400.0), rng.randf_range(-500.0, 200.0))
			var t := 0.0
			while t < 20.0 and b.viva and b.pos.y < 800.0:
				m.avanzar(DT)
				t += DT
			suma += t
			peor = maxf(peor, t)
			if t >= 20.0:
				atascadas += 1
	print("   salida media %.2f s · la peor %.2f s · atascadas (>20 s): %d de 600"
		% [suma / 600.0, peor, atascadas])
	print("   %s" % ("bien: la bóveda se vacía sola" if atascadas == 0
		else "MAL: hay dónde acuñarse, y eso tira la tanda"))
	print("")

# ------------------------------------------- B. el tiro de verdad: desde la cuna

## EL TIRO QUE SÍ EXISTE. La bóveda está por encima del racimo, así que ahí solo
## se llega subiendo, y el único tiro repetible de la mesa es el de la bola
## atrapada en la cuna: está medido en `prueba_sim.gd` que sube a y=787.
##
## Montado igual que esa prueba, a propósito: si el tiro que se mide aquí no
## fuera el mismo que la batería da por bueno, este número no diría nada.
##
## Se mide la ALTURA que alcanza y qué toca, con las dos palas y con la bola
## posada en varios puntos de la cuna: un tiro sale distinto según dónde se
## asiente, y esa dispersión es justo la que decide si la bóveda se toca o no.
func _b_tiro_desde_la_cuna() -> void:
	print("B · TIRO DESDE LA CUNA — el único tiro repetible de la mesa")
	for izquierda in [true, false]:
		var alturas: Array[float] = []
		var pines_total := 0
		var bumpers_total := 0
		var con_pin := 0
		var intentos := 0
		for k in 21:
			var m := Mesa.new()
			_pines = 0
			_bumpers = 0
			m.pin_golpeado.connect(func(_p: Vector2, _f: float) -> void: _pines += 1)
			m.bumper_golpeado.connect(func(_p: Vector2, _f: float) -> void: _bumpers += 1)
			m.nueva_bola()
			m.bola.en_carril = false
			var f := m.flipper_izq if izquierda else m.flipper_der
			f.pulsado = true
			for _i in int(0.35 / DT):
				m.avanzar(DT)
			var dir := Vector2(cos(f.angulo), sin(f.angulo))
			var normal := Vector2(-dir.y, dir.x)
			if not izquierda:
				normal = -normal
			# Dónde se posa la bola en la pala: de 0,45 a 0,65 del largo. La cuna
			# la asienta en 0,53, y este barrido es el temblor real del tiro.
			var donde := 0.45 + 0.01 * float(k)
			m.bola.pos = f.eje + dir * (m.p.flipper_longitud * donde) \
				- normal * (m.p.flipper_radio + m.p.radio_bola - 0.5)
			m.bola.vel = Vector2.ZERO
			for _i in int(1.2 / DT):
				m.avanzar(DT)
			if m.flipper_atrapando == null:
				continue
			intentos += 1
			f.pulsado = false
			for _i in int(0.12 / DT):
				m.avanzar(DT)
			f.pulsado = true
			var t := 0.0
			var alto := 9999.0
			while m.bola.viva and t < 6.0:
				m.avanzar(DT)
				t += DT
				if m.bola.libre():
					alto = minf(alto, m.bola.pos.y)
			alturas.append(alto)
			pines_total += _pines
			bumpers_total += _bumpers
			if _pines > 0:
				con_pin += 1
		if intentos == 0:
			print("   pala %s: no se atrapa ni una vez" % ["izquierda" if izquierda else "derecha"])
			continue
		alturas.sort()
		var media := 0.0
		for a in alturas:
			media += a
		print("   pala %-10s · sube a y=%.0f de media (la mejor %.0f, la peor %.0f)"
			% ["izquierda" if izquierda else "derecha", media / float(alturas.size()),
			alturas[0], alturas[alturas.size() - 1]])
		print("                 · %.1f pines y %.1f bumpers por tiro · %d de %d tocan pin"
			% [float(pines_total) / float(intentos), float(bumpers_total) / float(intentos),
			con_pin, intentos])
	print("")
	print("   La bóveda empieza en y=%.0f. Si el tiro no pasa de ahí, los pines"
		% (Mesa.new().p.pin_y + Mesa.new().p.pin_alto_fila))
	print("   son decoración por mucho que el campo esté bien puesto.")
	print("")

# --------------------------------------------------- C. duración y drenaje

## LO QUE DE VERDAD HAY QUE VIGILAR, y no son los pines: es el racimo girado.
## Un racimo que por fin encadena tiene a la bola más tiempo arriba, y la
## duración de bola y el reparto del drenaje son los dos números de los que
## cuelga la tabla de enemigos entera (`ESTADO.md`, Mediciones).
##
## Las tres configuraciones se miden EN LA MISMA EJECUCIÓN y con las mismas
## semillas: comparar contra un número escrito en ESTADO.md sería comparar
## contra otra versión del motor.
func _c_duracion_y_drenaje() -> void:
	print("C · DURACIÓN Y DRENAJE — 200 lanzamientos a tope, sin tocar las palas")
	print("   %-24s %10s %8s %9s %8s" % ["", "duración", "pines", "outlane", "centro"])
	for caso in [
			{"que": "racimo de espaldas", "giro": 0.0, "pines": false},
			{"que": "racimo girado", "giro": 60.0, "pines": false},
			{"que": "racimo girado + pines", "giro": 60.0, "pines": true}]:
		var suma := 0.0
		var pines_total := 0
		var outlane := 0
		for s in SEMILLAS:
			for i in 20:
				var par := ParametrosMesa.new()
				par.bumper_giro = float(caso["giro"])
				if not bool(caso["pines"]):
					par.pin_filas = 0
					par.pin_cedazo_filas = 0
				var m := Mesa.new(par)
				m.rng.seed = s * 1000 + i
				_pines = 0
				m.pin_golpeado.connect(func(_p: Vector2, _f: float) -> void: _pines += 1)
				# ENTRANDO AL RACIMO, no desde el lanzador. Un lanzamiento a
				# tope engancha la órbita y sale por la izquierda sin pasar por
				# los bumpers, así que medirlo desde ahí no ve el racimo: las
				# tres columnas salían idénticas hasta la milésima.
				m.nueva_bola()
				var b := m.bola
				b.en_carril = false
				var rng := RandomNumberGenerator.new()
				rng.seed = s * 1000 + i
				b.pos = m.p.bumper_centro + Vector2(rng.randf_range(-16.0, 16.0), 120.0)
				b.vel = Vector2(rng.randf_range(-60.0, 60.0), -rng.randf_range(600.0, 1100.0))
				var t := 0.0
				var ultimo := Vector2.ZERO
				while t < 60.0 and m.bola.viva:
					m.avanzar(DT)
					t += DT
					if m.bola.libre():
						ultimo = m.bola.pos
				suma += t
				pines_total += _pines
				# Por dónde se ha ido: pegada a una banda es outlane, por el
				# medio es el hueco entre palas.
				if ultimo.x < 70.0 or ultimo.x > 330.0:
					outlane += 1
		print("   %-24s %9.2fs %8.1f %8d%% %7d%%"
			% [caso["que"], suma / 200.0, float(pines_total) / 200.0,
			outlane * 100 / 200, (200 - outlane) * 100 / 200])
	print("")
	print("   Lo que no puede pasar: que la duración se dispare (la bola vive")
	print("   arriba y el reloj del enemigo deja de apretar) o que el reparto")
	print("   outlane/centro se mueva mucho (el drenaje es el corazón del balance).")
	print("")

# ------------------------------------------------- D. por qué ruta se entra

## LA PREGUNTA QUE DECIDE SI LA BÓVEDA VALE ALGO. Está por encima del racimo, o
## sea que solo se llega subiendo, y el tiro desde la cuna no llega. Así que
## quedan tres rutas: salir de un recorrido, salir del platillo, o que te suba
## un bumper. Se mide cada una por separado en vez de fiarlo a un jugador de
## mentira que no sabe jugar.
func _d_por_donde_se_entra() -> void:
	print("D · POR QUÉ RUTA SE ENTRA EN LA BÓVEDA")
	var m0 := Mesa.new()
	var techo: float = m0.p.pin_y + float(maxi(m0.p.pin_filas - 1, 0)) * m0.p.pin_alto_fila
	print("   (la fila de abajo de la bóveda está en y=%.0f)" % _fila_baja(m0))
	for i in m0.rampas.size():
		_ruta_rampa(i, (m0.rampas[i] as Rampa).nombre)
	_ruta_platillo()
	_ruta_racimo()
	print("")

func _fila_baja(m: Mesa) -> float:
	var baja := 0.0
	for v in m.pines:
		baja = maxf(baja, v.y)
	return baja

## Una bola que sale de un recorrido: se mete en la rampa por su boca y se la
## deja terminar. Lo que se cuenta es lo que toca DESPUÉS de salir.
func _ruta_rampa(indice: int, nombre: String) -> void:
	var rng := RandomNumberGenerator.new()
	var pines_total := 0
	var con_pin := 0
	var alto := 9999.0
	var intentos := 60
	for k in intentos:
		rng.seed = 100 + k
		var m := Mesa.new()
		_pines = 0
		m.pin_golpeado.connect(func(_p: Vector2, _f: float) -> void: _pines += 1)
		var r := m.rampas[indice] as Rampa
		var b := m.bola
		b.en_carril = false
		b.viva = true
		b.pos = r.puntos[0]
		b.vel = (r.puntos[1] - r.puntos[0]).normalized() \
			* rng.randf_range(r.velocidad_minima + 60.0, 1300.0)
		var t := 0.0
		while t < 12.0 and b.viva:
			m.avanzar(DT)
			t += DT
			if b.libre():
				alto = minf(alto, b.pos.y)
			if b.libre() and b.pos.y > 1100.0:
				break
		pines_total += _pines
		if _pines > 0:
			con_pin += 1
	print("   %-22s %5.1f pines · %d de %d tocan · lo más alto y=%.0f"
		% [nombre, float(pines_total) / float(intentos), con_pin, intentos, alto])

func _ruta_platillo() -> void:
	var pines_total := 0
	var con_pin := 0
	var alto := 9999.0
	var intentos := 40
	for k in intentos:
		var m := Mesa.new()
		_pines = 0
		m.pin_golpeado.connect(func(_p: Vector2, _f: float) -> void: _pines += 1)
		var pl := m.platillos[0] as Platillo
		var b := m.bola
		b.en_carril = false
		b.viva = true
		b.pos = pl.centro + Vector2(0.0, 30.0 + float(k) * 0.5)
		b.vel = Vector2(0.0, -420.0)
		var t := 0.0
		while t < 12.0 and b.viva:
			m.avanzar(DT)
			t += DT
			if b.libre():
				alto = minf(alto, b.pos.y)
			if b.libre() and b.pos.y > 1100.0:
				break
		pines_total += _pines
		if _pines > 0:
			con_pin += 1
	print("   %-22s %5.1f pines · %d de %d tocan · lo más alto y=%.0f"
		% ["platillo", float(pines_total) / float(intentos), con_pin, intentos, alto])

## La entrada al racimo, montada igual que `_prueba_racimo` de la batería pero
## desde ABAJO, que es de donde llega la bola en una partida: la de la batería
## la deja caer desde arriba y eso ahora atravesaría la bóveda antes de entrar.
func _ruta_racimo() -> void:
	var rng := RandomNumberGenerator.new()
	var pines_total := 0
	var bumpers_total := 0
	var con_pin := 0
	var alto := 9999.0
	var intentos := 200
	for k in intentos:
		rng.seed = 500 + k
		var m := Mesa.new()
		_pines = 0
		_bumpers = 0
		m.pin_golpeado.connect(func(_p: Vector2, _f: float) -> void: _pines += 1)
		m.bumper_golpeado.connect(func(_p: Vector2, _f: float) -> void: _bumpers += 1)
		var b := m.bola
		b.en_carril = false
		b.viva = true
		b.pos = m.p.bumper_centro + Vector2(rng.randf_range(-14.0, 14.0), 120.0)
		b.vel = Vector2(rng.randf_range(-60.0, 60.0), -rng.randf_range(600.0, 1000.0))
		var t := 0.0
		while t < 8.0 and b.viva:
			m.avanzar(DT)
			t += DT
			if b.libre():
				alto = minf(alto, b.pos.y)
			if b.libre() and b.pos.y > 1000.0:
				break
		pines_total += _pines
		bumpers_total += _bumpers
		if _pines > 0:
			con_pin += 1
	print("   %-22s %5.1f pines · %d de %d tocan · lo más alto y=%.0f · %.1f bumpers"
		% ["racimo desde abajo", float(pines_total) / float(intentos), con_pin,
		intentos, alto, float(bumpers_total) / float(intentos)])
