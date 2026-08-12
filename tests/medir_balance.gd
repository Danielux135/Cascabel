extends SceneTree

## Mide el balance del combate SIN abrir ventana:
##   godot --headless --path . --script tests/medir_balance.gd
##
## Esto NO es una prueba: no falla nunca, solo imprime una tabla. Existe porque
## la tabla de enemigos había que rehacerla a ojo y a ojo es como se llevaba
## puesta dos veces. Ahora los números salen del código de combate DE VERDAD
## —`Combate`, sus tramos de combo y su reloj— y lo único de mentira es el
## jugador.
##
## El jugador de mentira: un perfil no juega con las palas, describe lo que una
## bola PRODUCE. No hace falta física para medir la economía del combate, y
## meter la mesa dentro haría que el resultado dependiera de que la bola rebote
## igual en dos ejecuciones. Los perfiles están calibrados contra lo único que
## había medido de verdad en ESTADO.md: una bola buena hace ~160 con 13 golpes
## a ×3, y una bola dura ~10 s.
##
## Se mide contra el objetivo de `DISEÑO.md` §9: un run son 12-15 combates con
## 60 de vida que NO se cura entre ellos, así que lo que decide si la tabla vale
## es LA VIDA PERDIDA POR COMBATE, no cuánto tarda en morir el enemigo.
##
## EL MODELO QUE SALIÓ DE LA PRIMERA MEDIDA, que es lo que permitió escribir la
## tabla en vez de tantearla. Cuadra al punto con lo que imprime esto:
##
##     bolas  = techo(vida_enemigo / daño_por_bola)
##     tiempo = duración_de_bola × vida_enemigo / daño_por_bola
##     relojes = suelo(tiempo / reloj_carga)
##     vida perdida = (bolas − 1) × drenaje + relojes × ataque
##
## Con daño por bola medido: malo 16, normal 123, bueno 310. Esos 19× entre las
## puntas son el multiplicador de combo y el número de golpes multiplicándose
## entre sí, y son la razón de que el balance no se pueda arreglar solo con la
## vida de los enemigos: la vida divide, pero la brecha entre perfiles no.
##
## De ahí salen los dos umbrales con los que está escrita la tabla:
##   · 442 de vida es donde un jugador normal empieza a comer DOS golpes de
##     reloj en vez de uno. Ningún enemigo normal lo pasa; los jefes sí, y por
##     eso un jefe se nota.
##   · el golpe de reloj cobra el ataque entero, así que el ataque pesa mucho
##     más que la vida. Un ataque 16 sobre 60 de vida era un cuarto de la barra
##     de una sola vez.

## Aquí no hay física: el combate solo cuenta tiempo para el reloj, y el reloj
## dura 18 s. A 60 pasos por segundo la cuenta sale igual que a 120 y el barrido
## tarda la mitad. La mesa de verdad sigue yendo a 120 en `prueba_sim.gd`.
const DT := 1.0 / 60.0

## Cuántas veces se repite cada combate. Los perfiles son deterministas, así que
## con una basta; queda por si algún día llevan azar.
const REPETICIONES := 1

## Un perfil de jugador es lo que produce UNA bola suya, y cuánto dura.
##
## `golpes` son impactos de bumper —el relleno del combo—, `targets` los que
## pide apuntar, `bancos` cerrar los tres de una fila, y luego los recorridos.
## `segundos` es lo que la bola aguanta en juego, que es lo que decide cuántos
## golpes de reloj comes: es el número que de verdad manda en la vida perdida.
##
## Calibrado: estos perfiles dan 16, 123 y 310 de daño por bola. El de en medio
## es una bola decente y el bueno queda algo por encima de la única bola que
## había medida en ESTADO.md (160 con 13 golpes a ×3), o sea que "bueno" aquí es
## jugar bien SOSTENIDAMENTE, bola tras bola, no tener una bola buena suelta.
const PERFILES := [
	{
		"nombre": "malo",
		"segundos": 6.0,
		"golpes": 4, "targets": 1, "bancos": 0,
		"orbitas": 0, "retornos": 0, "canones": 0, "platillos": 0,
	},
	{
		"nombre": "normal",
		"segundos": 10.0,
		"golpes": 9, "targets": 2, "bancos": 0,
		"orbitas": 1, "retornos": 1, "canones": 0, "platillos": 0,
	},
	{
		"nombre": "bueno",
		"segundos": 16.0,
		"golpes": 14, "targets": 4, "bancos": 1,
		"orbitas": 1, "retornos": 1, "canones": 1, "platillos": 1,
	},
]

## Tope de bolas por combate. Si un enemigo lo alcanza es que es un muro, y eso
## es justo lo que hay que ver.
const MAX_BOLAS := 40

func _initialize() -> void:
	var catalogo := CatalogoEnemigos.cargar()
	print("")
	print("MEDIDA DE BALANCE  ·  vida del jugador %d  ·  reloj %.0f s"
		% [ParametrosCombate.new().vida_jugador, ParametrosCombate.new().reloj_carga])
	print("")
	for perfil in PERFILES:
		_medir_perfil(perfil as Dictionary, catalogo)
	_resumen_del_run(catalogo)
	_multiplicadores(catalogo)
	_barrido(catalogo)
	quit(0)

## Copia de los parámetros de combate. Hace falta porque cada `Combate` se queda
## con el objeto que le pasas y le escribe encima la vida: reutilizar uno entre
## medidas contaminaría la siguiente.
func _copiar(base: ParametrosCombate) -> ParametrosCombate:
	var p := ParametrosCombate.new()
	if base == null:
		return p
	p.vida_jugador = base.vida_jugador
	p.dano_bumper = base.dano_bumper
	p.dano_target = base.dano_target
	p.dano_banco = base.dano_banco
	p.dano_girador = base.dano_girador
	p.dano_rampa = base.dano_rampa
	p.dano_rampa_fuerte = base.dano_rampa_fuerte
	p.dano_platillo = base.dano_platillo
	p.tramos_combo = base.tramos_combo.duplicate(true)
	p.reloj_carga = base.reloj_carga
	p.reloj_aviso = base.reloj_aviso
	p.factor_ataque_drenaje = base.factor_ataque_drenaje
	p.platillo_atrasa_reloj = base.platillo_atrasa_reloj
	return p

# ----------------------------------------------------- esquemas de combo

## Cuánto da de sí tocar el multiplicador, medido en vez de discutido.
##
## De dónde sale la pregunta: la brecha de daño por bola entre jugar mal y
## jugar bien era de 19 veces, y descomponerla dio que solo 2,6 de esas veces
## son el multiplicador. Las otras 8,4 son cuántos eventos produce una bola, o
## sea cuánto la aguantas viva, que ES la habilidad y no se puede tocar sin
## quitar el juego. Así que esto mide el techo de lo que se puede arreglar por
## aquí antes de gastar sesiones en ello.
const ESQUEMAS := [
	{"nombre": "plano", "tramos": [{"golpes": 0, "factor": 1}]},
	{"nombre": "suave", "tramos": [
		{"golpes": 0, "factor": 1}, {"golpes": 8, "factor": 2}]},
	{"nombre": "actual", "tramos": []},
]

func _multiplicadores(catalogo: Array) -> void:
	print("── esquemas de multiplicador (tabla actual) ────────────────")
	print("  daño por bola de cada perfil, y qué pasa en runs de verdad")
	print("  %-8s %7s %7s %7s" % ["esquema", "malo", "normal", "bueno"])
	for esquema in ESQUEMAS:
		var pc := ParametrosCombate.new()
		if not (esquema as Dictionary)["tramos"].is_empty():
			pc.tramos_combo = ((esquema as Dictionary)["tramos"] as Array).duplicate(true)
		var danos: Array[int] = []
		for perfil in PERFILES:
			danos.append(_dano_por_bola(perfil as Dictionary, pc))
		var semillas := [SEMILLAS[0], SEMILLAS[1], SEMILLAS[2]]
		var n := _runs(PERFILES[1] as Dictionary, catalogo, ParametrosRun.new(), semillas, pc)
		var b := _runs(PERFILES[2] as Dictionary, catalogo, ParametrosRun.new(), semillas, pc)
		print("  %-8s %7d %7d %7d   normal %d/3 %4.1f nodos   bueno %d/3 vida %s   brecha %.1fx" % [
			str((esquema as Dictionary)["nombre"]), danos[0], danos[1], danos[2],
			int(n["acabados"]), float(n["nodos"]),
			int(b["acabados"]),
			("%.0f" % float(b["vida_final"])) if int(b["acabados"]) > 0 else "—",
			float(danos[2]) / float(maxi(danos[0], 1))])
	print("")

## Daño que hace UNA bola del perfil, contra un saco sin vida que se acabe. Es
## el número del que sale todo lo demás: las bolas que cuesta un enemigo son su
## vida entre esto.
func _dano_por_bola(perfil: Dictionary, base: ParametrosCombate) -> int:
	var p := _copiar(base)
	p.vida_jugador = 1000000
	var c := Combate.new(p)
	c.iniciar(Enemigo.new({"nombre": "Saco", "vida": 100000000, "ataque": 1}))
	_jugar_una_bola(c, perfil)
	return c.dano_de_la_bola

# ------------------------------------------------------------------- medida

func _medir_perfil(perfil: Dictionary, catalogo: Array) -> void:
	print("── jugador %s ─────────────────────────────────────────────" % perfil["nombre"])
	print("  %-20s %5s %6s %7s %7s %7s" % [
		"enemigo", "pv", "bolas", "seg", "relojes", "vida-"])
	for datos in catalogo:
		var r := _un_combate(perfil, datos as Dictionary)
		print("  %-20s %5d %6d %7.0f %7d %7d" % [
			str((datos as Dictionary).get("nombre", "?")),
			int((datos as Dictionary).get("vida", 0)),
			int(r["bolas"]), float(r["segundos"]),
			int(r["relojes"]), int(r["vida_perdida"])])
	print("")

## Un combate entero contra un enemigo, con vida de jugador infinita para poder
## medir lo que CUESTA aunque no se pueda pagar. Si se cortara al morir, un
## enemigo imposible y uno duro darían el mismo número.
func _un_combate(perfil: Dictionary, datos: Dictionary,
		base: ParametrosCombate = null) -> Dictionary:
	var p := _copiar(base)
	p.vida_jugador = 1000000
	var c := Combate.new(p)
	c.iniciar(Enemigo.new(datos))

	var relojes := [0]
	var perdida := [0]
	# Se cuenta el ataque de verdad y se le pregunta al combate de dónde vino.
	# Contar los avisos de 3-2-1 daría de más: el platillo puede sacar al reloj
	# de la cuenta atrás y volver a meterlo, y eso avisa dos veces y pega una.
	c.enemigo_ataca.connect(func(d: int) -> void:
		perdida[0] += d
		if c.ultimo_ataque_por_reloj:
			relojes[0] += 1)

	var bolas := 0
	var segundos := 0.0
	while not c.terminado() and bolas < MAX_BOLAS:
		bolas += 1
		segundos += _jugar_una_bola(c, perfil)
		if c.terminado():
			break
		# Drenar: se pierde el combo y el enemigo contraataca. Las pausas de
		# resolución corren aparte porque el reloj NO avanza en ellas.
		_drenar(c)
		_avanzar(c, p.pausa_drenaje + p.pausa_ataque + 4.0 * DT)
	return {
		"bolas": bolas,
		"segundos": segundos,
		"relojes": relojes[0],
		"vida_perdida": perdida[0],
	}

## Reparte los eventos del perfil a lo largo de la bola y deja correr el reloj
## entre ellos. El reparto importa: si todos los golpes cayeran de golpe al
## principio, el combo subiría antes y el enemigo moriría con menos reloj.
func _jugar_una_bola(c: Combate, perfil: Dictionary) -> float:
	c.mesa.bola.en_carril = false
	c.avanzar(DT)

	var eventos: Array[String] = []
	for _i in int(perfil["golpes"]):
		eventos.append("bumper")
	for _i in int(perfil["targets"]):
		eventos.append("target")
	for _i in int(perfil["bancos"]):
		eventos.append("banco")
	for _i in int(perfil["orbitas"]):
		eventos.append("orbita")
	for _i in int(perfil["retornos"]):
		eventos.append("retorno")
	for _i in int(perfil["canones"]):
		eventos.append("canon")
	for _i in int(perfil["platillos"]):
		eventos.append("platillo")
	_barajar_estable(eventos)

	var total := float(perfil["segundos"])
	var hueco := total / float(maxi(eventos.size(), 1))
	var gastado := 0.0
	for e in eventos:
		_avanzar(c, hueco)
		gastado += hueco
		if c.terminado():
			return gastado
		_evento(c, e)
		if c.terminado():
			return gastado
	return gastado

## Un orden fijo pero mezclado, para que los targets no salgan todos seguidos.
## Determinista a propósito: dos ejecuciones tienen que dar la misma tabla, o no
## se puede comparar un cambio de números con el anterior.
func _barajar_estable(lista: Array[String]) -> void:
	var salida: Array[String] = []
	var i := 0
	while not lista.is_empty():
		i = (i + 3) % lista.size()
		salida.append(lista[i])
		lista.remove_at(i)
	lista.assign(salida)

func _evento(c: Combate, cual: String) -> void:
	var punto := Vector2(200, 800)
	match cual:
		"bumper": c.mesa.bumper_golpeado.emit(punto, 500.0)
		"target": c.mesa.target_abatido.emit(punto, 0)
		"banco": c.mesa.banco_completado.emit(punto, 0)
		"platillo": c.mesa.platillo_expulsado.emit(punto, 0)
		_: _rampa(c, cual, punto)

## Las rampas pagan al salir, y cada una paga distinto. Se busca la que tenga el
## premio que toca en vez de fijar un índice: si mañana cambia el orden de las
## rampas en la mesa, la medida sigue midiendo lo mismo.
func _rampa(c: Combate, cual: String, punto: Vector2) -> void:
	var premio := Rampa.Premio.MULTIPLICADOR
	if cual == "canon":
		premio = Rampa.Premio.DANO_FUERTE
	elif cual == "retorno":
		premio = Rampa.Premio.DANO
	for i in c.mesa.rampas.size():
		if (c.mesa.rampas[i] as Rampa).premio == premio:
			c.mesa.rampa_salida.emit(punto, i)
			return

func _drenar(c: Combate) -> void:
	c.mesa.bola.viva = false
	c.mesa.bola.vel = Vector2.ZERO
	c.mesa.bola_drenada.emit()

func _avanzar(c: Combate, segundos: float) -> void:
	for _i in int(segundos / DT):
		c.avanzar(DT)

# ------------------------------------------------------------------- el run

## Lo anterior mide combates sueltos; esto mide lo único que decide si la tabla
## vale: si con 60 de vida que NO se cura llegas al final. Un enemigo puede
## estar perfecto y la tabla estar rota igual, porque lo que mata es la SUMA.
##
## Se juegan runs de verdad: el `Mapa` real los genera, con sus élites, sus
## jefes y su reparto por actos, y el jugador de mentira los recorre eligiendo
## rama. Antes esto promediaba el catálogo entero y mentía en las dos puntas:
## el acto I es más blando que la media y un jefe con 1,8× de vida es mucho más
## duro que cualquier enemigo suelto de la tabla.
##
## La rama se elige con la regla más tonta posible —la primera— a propósito.
## Un jugador que elija bien lo tendrá más fácil que esto, así que lo que sale
## aquí es la COTA MALA de cada perfil, y eso es lo que interesa: si el peor
## camino se puede aguantar, el bueno también.
func _resumen_del_run(catalogo: Array) -> void:
	var pr := ParametrosRun.new()
	var pc := ParametrosCombate.new()
	print("── runs de verdad (mapa generado, %d semillas) ─────────────" % SEMILLAS.size())
	print("  %d de vida  ·  descansos de +%d  ·  élite ×%.2f vida  ·  jefe ×%.2f"
		% [pc.vida_jugador, int(round(float(pc.vida_jugador) * pr.curacion_descanso)),
			pr.factor_vida_elite, pr.factor_vida_jefe])
	print("")
	print("  %-7s %8s %9s %11s %s" % [
		"jugador", "acaba", "nodos", "vida final", "dónde muere"])
	for perfil in PERFILES:
		_medir_runs(perfil as Dictionary, catalogo)
	print("")

const SEMILLAS := [13, 271, 4242, 90210, 31337]

# ------------------------------------------------------------------ barrido

## Busca la combinación que cumple el objetivo en vez de que la busque yo a
## mano. Dos mandos:
##   · una escala global sobre la vida de TODOS los enemigos, que es la forma
##     honesta de mover la dificultad sin descolocar el orden de la tabla
##   · `factor_vida_jefe`, aparte, porque un jefe cruza el umbral de los dos
##     golpes de reloj y por eso no escala como los demás
##
## El objetivo, que es lo que decidió Daniel: `normal` acaba el run justo y
## `bueno` con holgura. En la rejilla eso se lee como normal 3-5 de 5 acabados
## con poca vida, y bueno 5 de 5.
## Baja hasta 0,35 porque el reloj fino SUBE la presión absoluta y hubo que
## seguir bajando: al afinar el grano se le quita a todo el mundo el último
## trozo de carga que cada combate se dejaba sin cobrar, y ese trozo era regalo
## para los dos perfiles. Afinar cierra la razón entre jugadores; no baja el
## nivel. Son dos mandos distintos y por eso van en dos ejes distintos.
## Ahora van CENTRADAS EN 1,0, que es la configuración elegida y ya escrita en
## `data/enemigos.json` y `parametros_combate.gd`. El barrido dejó de ser una
## búsqueda a ciegas y pasó a ser el margen alrededor del punto elegido: sirve
## para ver cuánto aguanta el balance si mañana se toca algo, y para volver a
## encontrar el punto si se toca de verdad.
const ESCALAS_VIDA := [1.20, 1.10, 1.00, 0.90, 0.80]
## El ataque, que hasta ahora iba pegado a la vida. Es el que pone cuánto duele
## cada golpe de reloj, mientras que la vida pone cuántos comes.
const ESCALAS_ATAQUE := [1.0, 0.85]
## En cuántos trozos se parte el reloj. 1 es el de ahora (18 s, ataque entero);
## 3 es cargar en 6 s y pegar un tercio.
##
## El daño por segundo NO cambia con esto: lo único que cambia es EL TAMAÑO DEL
## ESCALÓN, y ese escalón resultó ser el problema. Con 18 s, un combate de
## jugador bueno (9-19 s) caía por debajo del umbral y se llevaba el combate
## gratis, mientras que uno normal (22-29 s) lo cruzaba siempre: la diferencia
## de castigo entre los dos era de cero a uno, una razón infinita, por un grano
## demasiado grueso y no porque uno jugara infinitamente mejor. Eso es también
## lo que hacía que bajar la vida de los enemigos SEPARARA a los perfiles en vez
## de acercarlos: metía los combates del bueno por debajo del umbral.
## 1 es el reloj tal y como está configurado ahora (9 s). Se deja el 2 para
## poder ver de un vistazo qué pasaría afinándolo todavía más.
const FINURAS_RELOJ := [1, 2]

func _barrido(catalogo: Array) -> void:
	var semillas := [SEMILLAS[0], SEMILLAS[1], SEMILLAS[2]]
	print("── barrido: escala de vida × finura del reloj ─────────────")
	print("  objetivo: normal acaba justo, bueno con holgura (%d-%d de vida)"
		% [int(VIDA_BUENO_MIN), int(VIDA_BUENO_MAX)])
	print("")
	print("  %5s %5s %6s  %-24s %-20s" % [
		"vida", "atq", "reloj", "normal", "bueno"])
	for escala in ESCALAS_VIDA:
		for atq in ESCALAS_ATAQUE:
			for finura in FINURAS_RELOJ:
				var pr := ParametrosRun.new()
				var pc := _reloj_fino(int(finura))
				var escalado := _escalar(catalogo, escala, int(finura), atq)
				var n := _runs(PERFILES[1] as Dictionary, escalado, pr, semillas, pc)
				var b := _runs(PERFILES[2] as Dictionary, escalado, pr, semillas, pc)
				print("  %5.2f %5.2f %5.1fs  %d/%d acaba, %4.1f nodos    %d/%d acaba, vida %-4s%s" % [
					escala, atq, pc.reloj_carga,
					int(n["acabados"]), semillas.size(), float(n["nodos"]),
					int(b["acabados"]), semillas.size(),
					("%.0f" % float(b["vida_final"])) if int(b["acabados"]) > 0 else "—",
					"   <<<" if _cumple(n, b, semillas.size()) else ""])
	print("")
	print("  <<< marca las filas que cumplen el objetivo")
	print("")

## `normal` tiene que acabar la mayoría de las veces pero no siempre, y `bueno`
## siempre. Si normal acaba 3 de 3 el run es un paseo; si acaba 0 o 1, es el
## muro que ya teníamos.
##
## Y `bueno` tiene TECHO además de suelo, que es lo que a esta comprobación le
## faltaba la primera vez: acabar con 60 de 60 no es "holgura", es que el juego
## ha dejado de tocarte. Sin el techo, el barrido daba por buenas las filas de
## abajo, donde `normal` acaba porque nadie le hace nada a nadie. Una condición
## que solo mira un lado siempre encuentra una respuesta, y por eso mentía.
## En FRACCIÓN de la vida máxima, no en puntos. Estaban escritos como 20 y 45
## sobre una vida de 60, y al triplicar la escala de daño el criterio se quedó
## midiendo otra cosa sin avisar: `bueno` acababa con 125 de 180 —justo donde
## queríamos— y el barrido no marcaba ni una fila, porque 125 es mayor que 45.
## Un umbral escrito en unidades absolutas caduca en cuanto se toca la escala.
const VIDA_BUENO_MIN := 0.33
const VIDA_BUENO_MAX := 0.75

func _cumple(n: Dictionary, b: Dictionary, total: int) -> bool:
	var na := int(n["acabados"])
	if na < total - 1 or na > total:
		return false
	if int(b["acabados"]) != total:
		return false
	var maxima := float(ParametrosCombate.new().vida_jugador)
	var vb := float(b["vida_final"]) / maxf(maxima, 1.0)
	return vb >= VIDA_BUENO_MIN and vb <= VIDA_BUENO_MAX

## El reloj partido en `finura` trozos, con todo lo demás compensado para que la
## presión por segundo quede IGUAL. Si no se compensara, esto no mediría el
## tamaño del escalón: mediría subir la dificultad, que es otra cosa.
func _reloj_fino(finura: int) -> ParametrosCombate:
	var pc := ParametrosCombate.new()
	if finura <= 1:
		return pc
	pc.reloj_carga = pc.reloj_carga / float(finura)
	# El aviso tiene que caber dentro de la carga, o estaría avisando siempre.
	pc.reloj_aviso = minf(pc.reloj_aviso, pc.reloj_carga * 0.4)
	# El ataque del enemigo baja a un `finura`-avo (se hace en `_escalar`), así
	# que este factor sube otro tanto para dejar el coste de DRENAR donde
	# estaba. Sin esto el barrido movería dos cosas a la vez y no se sabría
	# cuál de las dos hizo el efecto.
	pc.factor_ataque_drenaje = pc.factor_ataque_drenaje * float(finura)
	return pc

## Copia el catálogo con la vida escalada y el ataque partido en `finura`
## trozos. Copia, no toca: el catálogo original se sigue usando en las otras
## medidas de la misma ejecución.
func _escalar(catalogo: Array, escala: float, finura: int = 1,
		escala_ataque: float = 1.0) -> Array:
	var salida: Array = []
	for datos in catalogo:
		var copia: Dictionary = (datos as Dictionary).duplicate()
		copia["vida"] = maxi(int(round(float(copia.get("vida", 100)) * escala)), 1)
		# El ataque se divide por la finura para que el daño por segundo no
		# cambie, y aparte se escala por lo que pida el barrido. Con enteros
		# pequeños el redondeo pesa: un ataque 5 partido en 3 se queda en 2, que
		# es un 20% más de lo que tocaría. Se asume, pero está aquí escrito
		# porque explica que las filas de finura 3 salgan algo más duras.
		var a := float(copia.get("ataque", 10)) * escala_ataque / float(maxi(finura, 1))
		copia["ataque"] = maxi(int(round(a)), 1)
		salida.append(copia)
	return salida

func _medir_runs(perfil: Dictionary, catalogo: Array) -> void:
	var r := _runs(perfil, catalogo, ParametrosRun.new(), SEMILLAS)
	print("  %-7s %5d/%d %9.1f %11s %s" % [
		str(perfil["nombre"]), int(r["acabados"]), SEMILLAS.size(), float(r["nodos"]),
		("%.0f" % float(r["vida_final"])) if int(r["acabados"]) > 0 else "—",
		"—" if str(r["muertes"]) == "" else str(r["muertes"])])

## Juega `semillas.size()` runs y devuelve el resumen. Separado del impreso para
## que el barrido pueda llamarlo cientos de veces sin ensuciar la salida.
func _runs(perfil: Dictionary, catalogo: Array, pr: ParametrosRun,
		semillas: Array, base: ParametrosCombate = null) -> Dictionary:
	var acabados := 0
	var nodos := 0
	var vida_final := 0
	var muertes: Array[String] = []
	for semilla in semillas:
		var r := Run.new(pr, _copiar(base), catalogo, int(semilla))
		while not r.terminada():
			var opciones := r.opciones()
			if opciones.is_empty():
				break
			var nodo := r.elegir(opciones[0])
			if nodo == null:
				break
			if not nodo.es_combate():
				continue
			# Vida infinita dentro del combate y el descuento a mano después: si
			# se dejara morir al jugador dentro, el combate se cortaría y no se
			# sabría cuánto COSTABA de verdad ese enemigo.
			var res := _un_combate(perfil, nodo.enemigo, base)
			var restante: int = r.vida - int(res["vida_perdida"])
			r.resolver_combate(restante > 0, maxi(restante, 0))
			if restante <= 0:
				muertes.append("acto %d fila %d" % [nodo.acto + 1, nodo.fila + 1])
				break
		nodos += r.nodos_superados
		if r.victoria:
			acabados += 1
			vida_final += r.vida
	return {
		"acabados": acabados,
		"nodos": float(nodos) / float(maxi(semillas.size(), 1)),
		"vida_final": float(vida_final) / float(maxi(acabados, 1)),
		"muertes": ", ".join(muertes),
	}
