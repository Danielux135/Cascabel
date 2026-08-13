class_name Combate
extends RefCounted

## El bucle de un combate, encima de la mesa. Sin mapa, sin reliquias, sin
## cáscara: solo esto hasta que uno de los dos muera.
##
## El daño se aplica EN VIVO: cada bumper y cada target le pegan al enemigo en
## el momento. Lo que se acumula es el multiplicador de combo, que sube con los
## golpes seguidos sin drenar y vuelve a x1 en cuanto la bola se pierde.
## Drenar sigue siendo lo que cierra el turno: el enemigo contraataca.
##
## O sea que aguantar la bola no guarda daño para el final, sino que hace que
## cada golpe siguiente valga más. Es la misma idea de CONTEXTO —quien aguanta
## la bola más tiempo pega más fuerte— pero se ve mientras juegas en vez de al
## drenar.

signal dano_infligido(dano: int, multiplicador: int, punto: Vector2)
signal combo_cambiado(multiplicador: int, golpes: int)
signal enemigo_ataca(dano: int)
## El reloj entra en la cuenta atrás. `segundos` va 3, 2, 1 y salta una sola vez
## por número: el aviso es para que el golpe no llegue de la nada.
signal reloj_avisa(segundos: int)
## El platillo le ha quitado carga al reloj. `segundos` es lo que ha ganado el
## jugador, para poder enseñárselo.
signal reloj_atrasado(segundos: float)
signal bola_servida()
## El golpe ha salido CRÍTICO. Va aparte del daño porque tiene que enseñarse
## aparte: si solo cambiara el número, el jugador no lee "he tenido suerte", lee
## "el daño de este juego es aleatorio", que es lo peor que puede creer de un
## juego de habilidad.
signal golpe_critico(punto: Vector2, dano: int)
## Te han curado. Existe para poder enseñar el "+N": una curación que no sale en
## pantalla es exactamente la avería del platillo.
signal curado(cantidad: int, punto: Vector2)
## La red de seguridad ha comido un drenaje. Igual: si no se anuncia, parece que
## el juego se ha olvidado de castigarte.
signal drenaje_perdonado()
## Misión completada: es la ÚNICA forma de ganar una reliquia. Quien lo recoge
## para la ruleta con la rareza que corresponda.
signal mision_completada(mision: Mision)
## Misión nueva puesta en la tele, o progreso dentro de una. Para poder
## enseñarlo: una misión que no se ve en la tele no existe.
signal mision_cambiada(mision: Mision)
## Se ha perdido el progreso de una misión por drenar. Se anuncia porque si no
## el jugador ve el contador a cero y cree que es un fallo.
signal mision_reiniciada(mision: Mision)
signal combate_terminado(victoria: bool)

enum Fase { LANZANDO, BOLA_VIVA, DRENADA, RESOLVIENDO_ATAQUE, VICTORIA, DERROTA }

var p: ParametrosCombate
var mesa: Mesa
var enemigo: Enemigo
## Las reliquias que trae el jugador. Nunca es null: una bolsa vacía devuelve el
## neutro de cada modificador, así que un combate sin reliquias se comporta
## exactamente igual que antes de que existieran. Eso es lo que permite que las
## medidas viejas sigan valiendo.
var bolsa := BolsaReliquias.new()

var vida_jugador: int = 0
## Golpes seguidos sin drenar. Es lo que manda en el multiplicador.
var golpes: int = 0
## Lo que lleva hecho la bola que está en juego, solo para poder enseñarlo.
var dano_de_la_bola: int = 0
var ultimo_ataque: int = 0
## Si el último ataque vino del reloj o del drenaje. Solo para poder contarlo.
var ultimo_ataque_por_reloj: bool = false
var fase: int = Fase.LANZANDO

## Carga del reloj del enemigo, de 0 a 1. Sube mientras la bola está en juego y
## al llegar a 1 el enemigo pega, drenes o no.
var carga_reloj: float = 0.0

var _temporizador: float = 0.0
## Último segundo avisado, para no repetir el aviso en cada fotograma.
var _aviso_dado: int = -1
## Si el siguiente golpe es el primero de esta bola. Es el gancho "al empezar la
## bola", y se consume al golpear, no al servir: si se consumiera al servir, una
## bola que no toca nada se llevaría el premio por el camino.
var _primer_golpe := true
## La red de seguridad se gasta una vez por combate, no por bola: si fuera por
## bola dejaría de existir el drenaje.
var _red_gastada := false
## Drenajes de este combate. Es lo que mira la condición `sin_drenar`.
var drenajes: int = 0

# --------------------------------------------------------------- la medida
#
# EL INSTRUMENTO, y hace falta porque el balance se ha calibrado dos veces
# contra un jugador que no existe. `tests/medir_balance.gd` inventa tres
# perfiles y el de en medio hace 312 de daño por bola; Daniel no es ese perfil,
# y por eso la tabla salió imposible aunque la aritmética estuviera bien.
#
# Esto mide al jugador de verdad mientras juega, y los dos números que saca
# —daño por bola y segundos por combate— son exactamente los que necesita el
# modelo para escribir la tabla de enemigos EXACTA en una pasada.

var bolas_jugadas: int = 0
var dano_total: int = 0
var tiempo_jugado: float = 0.0

## Daño por bola de verdad, el número que calibra todo lo demás.
func dano_por_bola() -> float:
	return float(dano_total) / float(maxi(bolas_jugadas, 1))

## Probabilidad de crítico ahora mismo, con lo que sumen las reliquias. Existe
## como función pública porque el HUD la escribe: una estadística que no se ve
## no se lee como estadística, se lee como que el daño es aleatorio.
func prob_critico() -> float:
	return clampf(bolsa.suma("suma_prob_critico", p.prob_critico), 0.0, 1.0)

## Y por cuánto multiplica un crítico.
func factor_critico() -> float:
	return maxf(bolsa.suma("suma_factor_critico", p.factor_critico), 1.0)

# ------------------------------------------------------------- las misiones

## La escalera de misiones de este combate, una por rareza y de menos a más.
## `Run` la sortea y se la pasa al empezar; sin ella el combate se juega igual,
## solo que sin premio, y eso es lo que permite que las medidas de balance sigan
## corriendo sin catálogo.
var escalera: Array[Mision] = []
## En qué escalón vas. Cuando pasa del último, ya no hay más que ganar aquí.
var nivel_mision: int = 0
## Golpes contados de cada paso de la misión actual.
var progreso: Array[int] = []

func mision() -> Mision:
	if nivel_mision < 0 or nivel_mision >= escalera.size():
		return null
	return escalera[nivel_mision]

## Cuántas veces llevas del paso `i` de la misión actual.
func llevas(i: int) -> int:
	return progreso[i] if i >= 0 and i < progreso.size() else 0

## El paso en el que está la misión ahora mismo. Con `orden`, es el primero sin
## terminar; sin `orden`, todos cuentan a la vez y esto solo sirve para pintar.
func paso_actual() -> int:
	var m := mision()
	if m == null:
		return -1
	for i in m.tiros.size():
		if llevas(i) < m.veces(i):
			return i
	return -1

func _init(parametros: ParametrosCombate = null, la_mesa: Mesa = null) -> void:
	p = parametros if parametros != null else ParametrosCombate.new()
	mesa = la_mesa if la_mesa != null else Mesa.new()
	mesa.bumper_golpeado.connect(_al_golpear_bumper)
	mesa.target_abatido.connect(_al_abatir_target)
	mesa.banco_completado.connect(_al_completar_banco)
	mesa.girador_girado.connect(_al_girar_girador)
	mesa.rampa_salida.connect(_al_salir_de_rampa)
	mesa.platillo_expulsado.connect(_al_salir_del_platillo)
	mesa.bola_drenada.connect(_al_drenar)

## `vida_inicial` a -1 arranca a tope, que es lo que quiere el banco de pruebas.
## Dentro de un run se le pasa la vida que traiga el jugador: no se cura entre
## combates, y eso es lo que hace que el mapa tenga decisiones.
func iniciar(el_enemigo: Enemigo, vida_inicial: int = -1,
		las_misiones: Array[Mision] = []) -> void:
	enemigo = el_enemigo
	escalera = las_misiones.duplicate()
	nivel_mision = 0
	_rearmar_progreso()
	vida_jugador = vida_maxima() if vida_inicial < 0 else vida_inicial
	golpes = 0
	dano_de_la_bola = 0
	ultimo_ataque = 0
	ultimo_ataque_por_reloj = false
	fase = Fase.LANZANDO
	_temporizador = 0.0
	_aviso_dado = -1
	_primer_golpe = true
	_red_gastada = false
	drenajes = 0
	bolas_jugadas = 1
	dano_total = 0
	tiempo_jugado = 0.0
	_publicar_contexto()
	# El gancho "al entrar en combate": una reliquia puede regalarte barra de
	# reloj. Se limita para que no se pueda empezar con el reloj a punto de
	# sonar ni con más de una barra entera de ventaja.
	carga_reloj = clampf(bolsa.suma("suma_reloj_inicial"), -1.0, 0.9)
	golpes = int(round(bolsa.suma("suma_golpes_inicio")))
	_publicar_contexto()
	mesa.reiniciar_targets()
	mesa.nueva_bola()
	combo_cambiado.emit(multiplicador(), golpes)
	mision_cambiada.emit(mision())

# ------------------------------------------------------------- las misiones

func _hay_progreso() -> bool:
	for n in progreso:
		if n > 0:
			return true
	return false

func _rearmar_progreso() -> void:
	progreso.clear()
	var m := mision()
	if m == null:
		return
	for _i in m.tiros.size():
		progreso.append(0)

## Le apunta un tiro a la misión. Lo llaman los mismos ganchos que ya reparten
## el daño, con el nombre del tiro: `Combate` no tiene un `if` por misión, tiene
## un contador. Una misión nueva es una fila más en el JSON.
func _apuntar(tiro: String) -> void:
	var m := mision()
	if m == null or not _en_juego():
		return
	var toco := false
	for i in m.tiros.size():
		if m.tiro(i) != tiro or llevas(i) >= m.veces(i):
			continue
		# Con `orden`, un paso solo cuenta si los anteriores están hechos. Y un
		# tiro que no toca NO rompe el progreso: romperlo castiga dos veces —ya
		# has perdido la posición— y hace que se deje de intentar la misión.
		if m.orden and i != paso_actual():
			continue
		progreso[i] += 1
		toco = true
		break
	if not toco:
		return
	if paso_actual() < 0:
		_completar_mision(m)
	else:
		mision_cambiada.emit(m)

func _completar_mision(m: Mision) -> void:
	nivel_mision += 1
	_rearmar_progreso()
	mision_completada.emit(m)
	mision_cambiada.emit(mision())

func terminado() -> bool:
	return fase == Fase.VICTORIA or fase == Fase.DERROTA

## Lo que las reliquias condicionales necesitan saber del combate, en fracciones
## de 0 a 1 salvo el multiplicador y los drenajes.
##
## Se publica en vez de que la bolsa mire dentro de `Combate` a propósito: así la
## lista de lo que una condición PUEDE mirar es esta función y solo esta, y una
## reliquia nueva no puede acabar dependiendo de un detalle interno del combate.
func _publicar_contexto() -> void:
	bolsa.contexto["vida"] = float(vida_jugador) / float(maxi(vida_maxima(), 1))
	bolsa.contexto["reloj"] = clampf(carga_reloj, 0.0, 1.0)
	bolsa.contexto["drenajes"] = float(drenajes)
	bolsa.contexto["enemigo"] = 1.0 if enemigo == null \
		else float(enemigo.vida) / float(maxi(enemigo.vida_maxima, 1))
	bolsa.contexto["multiplicador"] = float(multiplicador())

## La vida máxima del jugador, con lo que le sumen las reliquias.
func vida_maxima() -> int:
	return maxi(p.vida_jugador + int(round(bolsa.suma("suma_vida_maxima"))), 1)

## Los tramos del combo tal y como quedan con las reliquias encima.
##
## Se construye en vez de tocar `p.tramos_combo` a propósito: los parámetros son
## la mesa, no la partida. Si una reliquia escribiera dentro de `p`, el efecto
## sobreviviría al run y contaminaría la siguiente medida —que es exactamente la
## trampa de `Mesa.new()` copiando parámetros, ya apuntada en CLAUDE.md—.
func tramos() -> Array:
	var adelanto := int(round(bolsa.suma("suma_adelanto_tramo")))
	var lista: Array = []
	for tramo in p.tramos_combo:
		var d: Dictionary = (tramo as Dictionary).duplicate()
		# El tramo x1 arranca en 0 golpes y ahí no hay nada que adelantar.
		if int(d["golpes"]) > 0:
			d["golpes"] = maxi(int(d["golpes"]) - adelanto, 1)
		lista.append(d)
	var extra := int(round(bolsa.suma("suma_tramos_extra")))
	for _i in extra:
		var ultimo: Dictionary = lista[lista.size() - 1]
		lista.append({
			"golpes": int(ultimo["golpes"]) + p.golpes_tramo_extra,
			"factor": int(ultimo["factor"]) + 1,
		})
	return lista

## El multiplicador que corresponde ahora mismo al número de golpes seguidos.
func multiplicador() -> int:
	var factor := 1
	for tramo in tramos():
		if golpes >= int((tramo as Dictionary)["golpes"]):
			factor = int((tramo as Dictionary)["factor"])
	return factor

## Segundos que le quedan al reloj para pegar. Con una reliquia que frene el
## reloj, la barra que falta son MÁS segundos: si esto no lo contara, el aviso
## de 3-2-1 saltaría cuando quedaran 3,5 y mentiría justo en el momento en el
## que el jugador lo está usando.
func reloj_restante() -> float:
	var ritmo := maxf(bolsa.factor("factor_carga_reloj"), 0.001)
	return maxf((1.0 - carga_reloj) * reloj_carga() / ritmo, 0.0)

## Los segundos que tarda en cargar el reloj DE ESTE enemigo. Cada uno tiene el
## suyo; el parámetro general es solo el de reserva.
func reloj_carga() -> float:
	if enemigo != null and enemigo.reloj > 0.0:
		return enemigo.reloj
	return p.reloj_carga

func avanzar(dt: float) -> void:
	mesa.avanzar(dt)
	if fase == Fase.LANZANDO and mesa.bola.viva and not mesa.bola.en_carril:
		fase = Fase.BOLA_VIVA
	# El reloj corre solo mientras se juega. En las pausas de resolución el
	# jugador no tiene la bola, y cobrarle ahí sería cobrarle por esperar.
	if _en_juego():
		tiempo_jugado += dt
		_avanzar_reloj(dt)
	if _temporizador > 0.0:
		_temporizador -= dt
		if _temporizador <= 0.0:
			_temporizador = 0.0
			_siguiente_fase()

# ------------------------------------------------------------- el reloj

func _avanzar_reloj(dt: float) -> void:
	# Las reliquias que tocan el reloj lo hacen aquí y solo aquí: no cambian
	# `reloj_carga`, cambian lo rápido que sube la barra. Así el aviso de 3-2-1 y
	# los segundos que se enseñan siguen saliendo del mismo sitio.
	carga_reloj += dt * bolsa.factor("factor_carga_reloj") / maxf(reloj_carga(), 0.001)
	if carga_reloj >= 1.0:
		carga_reloj = 0.0
		_aviso_dado = -1
		_atacar(enemigo.ataque, true)
		return
	var restante := reloj_restante()
	if restante <= p.reloj_aviso:
		var segundos := int(ceil(restante))
		if segundos != _aviso_dado:
			_aviso_dado = segundos
			reloj_avisa.emit(segundos)

# ------------------------------------------------------------- golpear

func _en_juego() -> bool:
	return fase == Fase.LANZANDO or fase == Fase.BOLA_VIVA

## `suma_golpe` distingue un impacto de una bonificación: completar un banco da
## daño pero no es un golpe, y contarlo inflaría el combo por partida doble con
## el target que lo cierra.
##
## `escala` dice si a este golpe le toca el multiplicador. NO le toca al relleno
## —bumpers y giradores—, y sí a todo lo que hay que buscar: targets, bancos,
## rampas y platillo. Está medido en `tests/medir_balance.gd` por qué: el
## multiplicador se aplicaba también a lo que sale solo, así que dar tumbos por
## el racimo con el combo alto pagaba como apuntar. El relleno sigue SUBIENDO el
## combo —aguantar la bola sigue siendo lo que lo sube, que es el pilar— pero ya
## no cobra de él.
##
## `factor_local` es lo que aporte la reliquia de ESE tiro concreto —el cañón,
## el banco—, y entra multiplicando junto al factor global. Los tres sitios donde
## las reliquias tocan un golpe son estos tres argumentos y ninguno más: si
## mañana hace falta un cuarto, es que hay un gancho nuevo.
func _golpear(base: int, punto: Vector2, suma_golpe: bool, escala: bool = true,
		factor_local: float = 1.0) -> void:
	if not _en_juego():
		return
	# El contexto se refresca ANTES de sumar el golpe: una reliquia que pide
	# combo alto tiene que mirar el combo con el que llegabas, no el que este
	# mismo golpe acaba de dar. Si no, el golpe que cruza el umbral se cobraría
	# a sí mismo el premio de haberlo cruzado.
	_publicar_contexto()
	if suma_golpe:
		var antes := multiplicador()
		golpes += 1
		var ahora := multiplicador()
		if ahora != antes:
			combo_cambiado.emit(ahora, golpes)
	var dano_f := float(base) * float(multiplicador() if escala else 1) \
		* factor_local * bolsa.factor("factor_dano_global")
	# El gancho "al empezar la bola" se cobra en el primer impacto de verdad.
	if _primer_golpe:
		_primer_golpe = false
		dano_f *= bolsa.factor("factor_primer_golpe")
	# El crítico. La probabilidad base sale de los parámetros y las reliquias la
	# suman encima, así que "más críticos" es un eje de build sin código nuevo.
	var critico := bolsa.azar("suma_prob_critico", p.prob_critico)
	if critico:
		dano_f *= factor_critico()
	# Suelo de 1: un factor por debajo de 1 no puede convertir un golpe en nada,
	# o el jugador vería impactos que no hacen daño y lo leería como un fallo.
	var dano := maxi(int(round(dano_f)), 1)
	var aplicado := enemigo.recibir(dano)
	dano_de_la_bola += aplicado
	dano_total += aplicado
	dano_infligido.emit(dano, multiplicador(), punto)
	if critico:
		golpe_critico.emit(punto, dano)
	if not enemigo.vivo():
		_ganar()

## El relleno —bumpers y giradores— sigue sin cobrar del multiplicador, que es
## lo medido en la fase 3. Una reliquia puede darle la vuelta a eso, y es de las
## pocas que cambian CÓMO juegas y no cuánto pegas: con ella el racimo pasa de
## ser el sitio donde subes el combo a ser el sitio donde lo gastas.
func _escala_relleno() -> bool:
	return bolsa.bandera("bandera_relleno_escala")

func _al_golpear_bumper(punto: Vector2, _fuerza: float) -> void:
	_apuntar("bumper")
	_golpear(p.dano_bumper, punto, true, _escala_relleno(),
		bolsa.factor("factor_dano_relleno"))

func _al_abatir_target(punto: Vector2, _banco: int) -> void:
	_apuntar("target")
	_robar_reloj(bolsa.suma("suma_robo_reloj_target"))
	_golpear(p.dano_target + int(round(bolsa.suma("suma_dano_target"))), punto, true)

func _al_completar_banco(punto: Vector2, _banco: int) -> void:
	_apuntar("banco")
	_robar_reloj(bolsa.suma("suma_robo_reloj_banco"))
	_sumar_golpes(int(round(bolsa.suma("suma_golpes_banco"))))
	_golpear(p.dano_banco + int(round(bolsa.suma("suma_dano_banco"))), punto, false,
		true, bolsa.factor("factor_dano_banco"))

func _al_girar_girador(punto: Vector2, _indice: int, _fuerza: float) -> void:
	_apuntar("girador")
	_golpear(p.dano_girador, punto, true, _escala_relleno(),
		bolsa.factor("factor_dano_relleno"))

## Lo que cobra CUALQUIER recorrido completado: rampas y platillo. Va aparte del
## daño porque no todas las reliquias de recorrido pagan en daño —una cura, otra
## sube el combo— y meterlas en `_golpear` obligaría a un argumento por cada una.
func _premio_de_recorrido() -> void:
	_sumar_golpes(int(round(bolsa.suma("suma_golpes_por_recorrido"))))
	var cura := int(round(bolsa.suma("suma_vida_por_recorrido")))
	if cura > 0:
		var antes := vida_jugador
		vida_jugador = mini(vida_jugador + cura, vida_maxima())
		if vida_jugador > antes:
			curado.emit(vida_jugador - antes, mesa.bola.pos)

## Suma golpes al combo sin pegar. Es lo que hace que "cerrar un banco sube el
## combo" no tenga que ser un caso especial dentro de `_golpear`.
func _sumar_golpes(cuantos: int) -> void:
	if cuantos <= 0:
		return
	var antes := multiplicador()
	golpes += cuantos
	var ahora := multiplicador()
	if ahora != antes:
		combo_cambiado.emit(ahora, golpes)

## Las rampas pagan al SALIR, no al entrar: el premio es completarlas. Y cada
## una paga una cosa distinta, que es lo que las hace tres tiros de verdad.
func _al_salir_de_rampa(punto: Vector2, indice: int) -> void:
	_premio_de_recorrido()
	var comun := bolsa.factor("factor_dano_recorrido")
	match (mesa.rampas[indice] as Rampa).premio:
		Rampa.Premio.MULTIPLICADOR:
			_apuntar("orbita")
			_subir_tramo(punto, comun * bolsa.factor("factor_dano_orbita"))
		Rampa.Premio.DANO_FUERTE:
			_apuntar("canon")
			_golpear(p.dano_rampa_fuerte, punto, true, true,
				comun * bolsa.factor("factor_dano_canon"))
		_:
			_apuntar("retorno")
			_golpear(p.dano_rampa, punto, true,
				true, comun * bolsa.factor("factor_dano_retorno"))

## Sube el multiplicador un tramo de golpe, sin tener que encadenar los golpes
## que harían falta. Si ya está en el último, se queda donde está y solo paga
## el daño.
func _subir_tramo(punto: Vector2, factor_local: float = 1.0) -> void:
	var antes := multiplicador()
	for tramo in tramos():
		if int((tramo as Dictionary)["factor"]) > antes:
			golpes = maxi(golpes, int((tramo as Dictionary)["golpes"]))
			break
	var ahora := multiplicador()
	if ahora != antes:
		combo_cambiado.emit(ahora, golpes)
	# Sin sumar golpe: los golpes ya los ha puesto el salto de tramo.
	_golpear(p.dano_rampa, punto, false, true, factor_local)

## Y el platillo al escupir, que es donde está el golpe. Pero su premio de
## verdad no es el golpe: es atrasar el reloj. Es el único tiro que paga en algo
## que no es daño, y hace falta que lo haya para que la mesa tenga decisiones y
## no solo números.
func _al_salir_del_platillo(punto: Vector2, _indice: int) -> void:
	if not _en_juego():
		return
	_apuntar("platillo")
	_premio_de_recorrido()
	_robar_reloj(p.platillo_atrasa_reloj * bolsa.factor("factor_platillo"))
	_golpear(p.dano_platillo, punto, true, true,
		bolsa.factor("factor_dano_recorrido") * bolsa.factor("factor_dano_platillo"))

## Le quita carga al reloj y lo anuncia. Sale de dentro del platillo porque
## ahora hay reliquias que roban reloj desde otros sitios —un target, un banco—
## y el aviso tiene que rearmarse igual desde todos.
func _robar_reloj(fraccion: float) -> void:
	if fraccion <= 0.0:
		return
	var antes := carga_reloj
	carga_reloj = maxf(carga_reloj - fraccion, 0.0)
	if is_equal_approx(antes, carga_reloj):
		return
	# Si el aviso ya había saltado y el robo lo saca de la cuenta atrás, se
	# rearma: si no, la próxima cuenta atrás llegaría sin avisar.
	if reloj_restante() > p.reloj_aviso:
		_aviso_dado = -1
	# En segundos de verdad, o sea contando lo que frenen las reliquias: es el
	# número que se le enseña al jugador junto a la barra.
	reloj_atrasado.emit((antes - carga_reloj) * reloj_carga()
		/ maxf(bolsa.factor("factor_carga_reloj"), 0.001))

# ------------------------------------------------------------- resolución

## Cuánto cura ganar este combate, en puntos. Se resuelve en `Run`, que es quien
## lleva la vida entre combates; aquí solo se calcula para poder enseñarlo.
func curacion_al_ganar() -> int:
	return int(round(float(vida_maxima()) * bolsa.suma("suma_curacion_al_matar")))

func _ganar() -> void:
	fase = Fase.VICTORIA
	_temporizador = 0.0
	# Se retira la bola: el combate ha terminado y no tiene sentido que siga
	# rodando y sumando golpes contra un enemigo muerto.
	mesa.bola.viva = false
	mesa.bola.vel = Vector2.ZERO
	combate_terminado.emit(true)

## Drenar la bola es lo que cierra el turno: se pierde el combo y el enemigo
## contraataca.
func _al_drenar() -> void:
	if terminado():
		return
	# La red de seguridad: el primer drenaje del combate no cuesta ni vida ni
	# combo. No salva la bola —la bola se ha perdido igual, y eso es invariante—
	# solo el castigo. Una vez por combate: por bola dejaría de existir drenar.
	_publicar_contexto()
	if bolsa.bandera("bandera_red_de_seguridad") and not _red_gastada:
		_red_gastada = true
		drenaje_perdonado.emit()
		fase = Fase.RESOLVIENDO_ATAQUE
		_temporizador = p.pausa_drenaje
		return
	drenajes += 1
	# Las misiones que piden aguantar la bola se reinician aquí. Es lo que
	# separa una arcana de una rara sin pedir más tiros: la habilidad es
	# aguantar la bola, `DISEÑO.md` §2.
	var m := mision()
	if m != null and m.sin_drenar and _hay_progreso():
		_rearmar_progreso()
		mision_reiniciada.emit(m)
	if golpes > 0:
		# El combo cae a cero salvo que una reliquia guarde parte. Cero sigue
		# siendo el caso normal: drenar tiene que doler, y lo que se conserva es
		# el efecto de una reliquia concreta, no una amabilidad del sistema.
		golpes = int(float(golpes)
			* clampf(bolsa.suma("suma_golpes_conservados"), 0.0, 1.0))
		combo_cambiado.emit(multiplicador(), golpes)
	fase = Fase.DRENADA
	_temporizador = p.pausa_drenaje

## El golpe del enemigo, venga del reloj o del drenaje. El del reloj cae en
## mitad de la bola y no para nada: la bola sigue rodando y tú sigues jugando.
func _atacar(dano: int, por_reloj: bool) -> void:
	_publicar_contexto()
	# Lo que pega el enemigo puede bajarlo una reliquia. Se aplica AQUÍ y no en
	# los dos sitios que llaman: el golpe del reloj y el del drenaje son el mismo
	# golpe cobrado por dos motivos, y una armadura que solo parase uno de los
	# dos sería imposible de explicar.
	dano = int(round(float(dano) * bolsa.factor("factor_ataque_enemigo")))
	ultimo_ataque = maxi(dano, 0)
	ultimo_ataque_por_reloj = por_reloj
	vida_jugador = maxi(vida_jugador - ultimo_ataque, 0)
	enemigo_ataca.emit(ultimo_ataque)
	if vida_jugador <= 0:
		fase = Fase.DERROTA
		_temporizador = 0.0
		mesa.bola.viva = false
		mesa.bola.vel = Vector2.ZERO
		combate_terminado.emit(false)

## Drenar pega menos que el reloj: ya no es la única presión del combate.
func _dano_drenaje() -> int:
	return maxi(int(round(float(enemigo.ataque) * p.factor_ataque_drenaje
		* bolsa.factor("factor_drenaje"))), 1)

func _siguiente_fase() -> void:
	match fase:
		Fase.DRENADA:
			fase = Fase.RESOLVIENDO_ATAQUE
			_atacar(_dano_drenaje(), false)
			if fase == Fase.DERROTA:
				return
			_temporizador = p.pausa_ataque
		Fase.RESOLVIENDO_ATAQUE:
			fase = Fase.LANZANDO
			dano_de_la_bola = 0
			bolas_jugadas += 1
			_primer_golpe = true
			# El gancho "al empezar la bola": una reliquia puede servirte la bola
			# con combo ya puesto. Se aplica al servir y no al drenar, para que
			# la bola perdonada por la red de seguridad también lo reciba.
			_sumar_golpes(maxi(int(round(bolsa.suma("suma_golpes_inicio"))) - golpes, 0))
			mesa.nueva_bola()
			bola_servida.emit()
