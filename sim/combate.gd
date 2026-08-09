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
signal bola_servida()
signal combate_terminado(victoria: bool)

enum Fase { LANZANDO, BOLA_VIVA, DRENADA, RESOLVIENDO_ATAQUE, VICTORIA, DERROTA }

var p: ParametrosCombate
var mesa: Mesa
var enemigo: Enemigo

var vida_jugador: int = 0
## Golpes seguidos sin drenar. Es lo que manda en el multiplicador.
var golpes: int = 0
## Lo que lleva hecho la bola que está en juego, solo para poder enseñarlo.
var dano_de_la_bola: int = 0
var ultimo_ataque: int = 0
var fase: int = Fase.LANZANDO

var _temporizador: float = 0.0

func _init(parametros: ParametrosCombate = null, la_mesa: Mesa = null) -> void:
	p = parametros if parametros != null else ParametrosCombate.new()
	mesa = la_mesa if la_mesa != null else Mesa.new()
	mesa.bumper_golpeado.connect(_al_golpear_bumper)
	mesa.target_abatido.connect(_al_abatir_target)
	mesa.banco_completado.connect(_al_completar_banco)
	mesa.bola_drenada.connect(_al_drenar)

func iniciar(el_enemigo: Enemigo) -> void:
	enemigo = el_enemigo
	vida_jugador = p.vida_jugador
	golpes = 0
	dano_de_la_bola = 0
	ultimo_ataque = 0
	fase = Fase.LANZANDO
	_temporizador = 0.0
	mesa.reiniciar_targets()
	mesa.nueva_bola()
	combo_cambiado.emit(1, 0)

func terminado() -> bool:
	return fase == Fase.VICTORIA or fase == Fase.DERROTA

## El multiplicador que corresponde ahora mismo al número de golpes seguidos.
func multiplicador() -> int:
	var factor := 1
	for tramo in p.tramos_combo:
		if golpes >= int((tramo as Dictionary)["golpes"]):
			factor = int((tramo as Dictionary)["factor"])
	return factor

func avanzar(dt: float) -> void:
	mesa.avanzar(dt)
	if fase == Fase.LANZANDO and mesa.bola.viva and not mesa.bola.en_carril:
		fase = Fase.BOLA_VIVA
	if _temporizador > 0.0:
		_temporizador -= dt
		if _temporizador <= 0.0:
			_temporizador = 0.0
			_siguiente_fase()

# ------------------------------------------------------------- golpear

func _en_juego() -> bool:
	return fase == Fase.LANZANDO or fase == Fase.BOLA_VIVA

## `suma_golpe` distingue un impacto de una bonificación: completar un banco da
## daño pero no es un golpe, y contarlo inflaría el combo por partida doble con
## el target que lo cierra.
func _golpear(base: int, punto: Vector2, suma_golpe: bool) -> void:
	if not _en_juego():
		return
	if suma_golpe:
		var antes := multiplicador()
		golpes += 1
		var ahora := multiplicador()
		if ahora != antes:
			combo_cambiado.emit(ahora, golpes)
	var dano := base * multiplicador()
	dano_de_la_bola += enemigo.recibir(dano)
	dano_infligido.emit(dano, multiplicador(), punto)
	if not enemigo.vivo():
		_ganar()

func _al_golpear_bumper(punto: Vector2, _fuerza: float) -> void:
	_golpear(p.dano_bumper, punto, true)

func _al_abatir_target(punto: Vector2, _banco: int) -> void:
	_golpear(p.dano_target, punto, true)

func _al_completar_banco(punto: Vector2, _banco: int) -> void:
	_golpear(p.dano_banco, punto, false)

# ------------------------------------------------------------- resolución

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
	if golpes > 0:
		golpes = 0
		combo_cambiado.emit(1, 0)
	fase = Fase.DRENADA
	_temporizador = p.pausa_drenaje

func _siguiente_fase() -> void:
	match fase:
		Fase.DRENADA:
			ultimo_ataque = enemigo.ataque
			vida_jugador = maxi(vida_jugador - ultimo_ataque, 0)
			fase = Fase.RESOLVIENDO_ATAQUE
			enemigo_ataca.emit(ultimo_ataque)
			if vida_jugador <= 0:
				fase = Fase.DERROTA
				combate_terminado.emit(false)
				return
			_temporizador = p.pausa_ataque
		Fase.RESOLVIENDO_ATAQUE:
			fase = Fase.LANZANDO
			dano_de_la_bola = 0
			mesa.nueva_bola()
			bola_servida.emit()
