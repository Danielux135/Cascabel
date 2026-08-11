class_name Flipper
extends RefCounted

## Cápsula que gira alrededor de un eje.
##
## EL DETALLE QUE HACE TODO EL TACTO: el flipper no rebota, empuja. Aquí se
## calcula la velocidad de la superficie en el punto de contacto (ω × r) y se
## devuelve en el contacto para que el solver resuelva el impulso contra la
## velocidad RELATIVA de la bola. Un flipper quieto solo rebota (ω = 0, así que
## la velocidad relativa es la de la bola); uno en movimiento lanza.
## Si esto se toca, el juego se siente muerto.

var eje: Vector2
var longitud: float
var radio: float
var restitucion: float
## Rozamiento de la goma de la pala. Es alto: es lo que sostiene la bola en la
## cuna cuando la mantienes arriba, sin frenarla a mano.
var friccion: float = 0.0
var angulo_reposo: float      # radianes
var angulo_activo: float
var velocidad_giro: float     # rad/s

var angulo: float
var omega: float = 0.0
var pulsado := false

func _init(
		p_eje: Vector2,
		p_longitud: float,
		p_radio: float,
		p_restitucion: float,
		p_reposo_grados: float,
		p_activo_grados: float,
		p_velocidad_giro: float) -> void:
	eje = p_eje
	longitud = p_longitud
	radio = p_radio
	restitucion = p_restitucion
	angulo_reposo = deg_to_rad(p_reposo_grados)
	angulo_activo = deg_to_rad(p_activo_grados)
	velocidad_giro = p_velocidad_giro
	angulo = angulo_reposo

func avanzar(dt: float) -> void:
	var objetivo := angulo_activo if pulsado else angulo_reposo
	var anterior := angulo
	var delta := objetivo - angulo
	var paso := velocidad_giro * dt
	angulo = objetivo if absf(delta) <= paso else angulo + signf(delta) * paso
	omega = (angulo - anterior) / dt if dt > 0.0 else 0.0

func punta() -> Vector2:
	return eje + Vector2(cos(angulo), sin(angulo)) * longitud

## Hacia dónde saldría disparada una bola apoyada aquí si soltases y volvieses a
## dar. Es la MISMA cuenta que hace el solver —la velocidad de la superficie en
## el punto de contacto, ω × r— con la ω que tendría la pala subiendo. O sea que
## no es una aproximación para dibujar: es la dirección de verdad.
##
## Sirve para enseñar la cuna. No le da ninguna habilidad al gesto de mantener
## el flipper, que es invariante: solo enseña lo que ya iba a pasar.
func direccion_de_disparo(pos_bola: Vector2) -> Vector2:
	var d := punta() - eje
	var t := clampf((pos_bola - eje).dot(d) / d.length_squared(), 0.0, 1.0)
	var contacto := eje + d * t
	var r := contacto - eje
	if r.length_squared() < 1e-6:
		return Vector2.UP
	# El sentido del barrido al subir: del ángulo de reposo al activo.
	var sentido := signf(angulo_activo - angulo_reposo)
	return Vector2(-r.y, r.x).normalized() * sentido

func consultar(pos: Vector2, _vel: Vector2, radio_bola: float, salida: Array) -> void:
	var d := punta() - eje
	var t := clampf((pos - eje).dot(d) / d.length_squared(), 0.0, 1.0)
	var c := eje + d * t
	var v := pos - c
	var dist := v.length()
	var suma := radio + radio_bola
	if dist >= suma:
		return
	var n := v / dist if dist > 1e-4 else Vector2.UP
	var punto_contacto := pos - n * radio_bola
	# r = vector del eje al punto de contacto; ω × r en 2D con Y hacia abajo
	var r := punto_contacto - eje
	var velocidad_superficie := Vector2(-r.y, r.x) * omega
	salida.append(Contacto.new(
		n, suma - dist, punto_contacto, velocidad_superficie,
		restitucion, 0.0, 0.0, Colisionador.Tipo.FLIPPER, self, friccion))
