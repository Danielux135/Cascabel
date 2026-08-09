class_name Combate
extends RefCounted

## El bucle de un combate, encima de la mesa. Sin mapa, sin reliquias, sin
## cáscara: solo esto hasta que uno de los dos muera.
##
## La regla de CONTEXTO: mientras la bola vive acumulas daño golpeando bumpers
## y targets; cuando drena se resuelve, le pegas al enemigo con lo acumulado y
## él contraataca. Ya no hay tres bolas contadas: las bolas son infinitas y lo
## que se agota es la vida del jugador.

signal dano_sumado(total: int, incremento: int, punto: Vector2)
signal golpe_resuelto(dano: int)
signal enemigo_ataca(dano: int)
signal bola_servida()
signal combate_terminado(victoria: bool)

enum Fase { LANZANDO, BOLA_VIVA, RESOLVIENDO_GOLPE, RESOLVIENDO_ATAQUE, VICTORIA, DERROTA }

var p: ParametrosCombate
var mesa: Mesa
var enemigo: Enemigo

var vida_jugador: int = 0
var dano_pendiente: int = 0
var fase: int = Fase.LANZANDO
## Lo último que se resolvió, para que la vista lo pueda enseñar.
var ultimo_golpe: int = 0
var ultimo_ataque: int = 0

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
	dano_pendiente = 0
	ultimo_golpe = 0
	ultimo_ataque = 0
	fase = Fase.LANZANDO
	_temporizador = 0.0
	mesa.reiniciar_targets()
	mesa.nueva_bola()

func terminado() -> bool:
	return fase == Fase.VICTORIA or fase == Fase.DERROTA

func avanzar(dt: float) -> void:
	mesa.avanzar(dt)
	if fase == Fase.LANZANDO and mesa.bola.viva and not mesa.bola.en_carril:
		fase = Fase.BOLA_VIVA
	if _temporizador > 0.0:
		_temporizador -= dt
		if _temporizador <= 0.0:
			_temporizador = 0.0
			_siguiente_fase()

# ------------------------------------------------------- acumular daño

func _acumulando() -> bool:
	return fase == Fase.LANZANDO or fase == Fase.BOLA_VIVA

func _sumar(dano: int, punto: Vector2) -> void:
	if not _acumulando():
		return
	dano_pendiente += dano
	dano_sumado.emit(dano_pendiente, dano, punto)

func _al_golpear_bumper(punto: Vector2, _fuerza: float) -> void:
	_sumar(p.dano_bumper, punto)

func _al_abatir_target(punto: Vector2, _banco: int) -> void:
	_sumar(p.dano_target, punto)

func _al_completar_banco(punto: Vector2, _banco: int) -> void:
	_sumar(p.dano_banco, punto)

# ------------------------------------------------------- resolución

## Drenar la bola es lo que cierra el turno: es el puente entre el pinball
## continuo y la estructura de combate.
func _al_drenar() -> void:
	if terminado():
		return
	ultimo_golpe = enemigo.recibir(dano_pendiente)
	dano_pendiente = 0
	fase = Fase.RESOLVIENDO_GOLPE
	golpe_resuelto.emit(ultimo_golpe)
	if not enemigo.vivo():
		fase = Fase.VICTORIA
		combate_terminado.emit(true)
		return
	_temporizador = p.pausa_golpe

func _siguiente_fase() -> void:
	match fase:
		Fase.RESOLVIENDO_GOLPE:
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
			mesa.nueva_bola()
			bola_servida.emit()
