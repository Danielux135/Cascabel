extends SceneTree

## Mide LA PLANTA ALTA rehecha (`CAZA.md` §6), y contesta la única pregunta que
## cierra su geometría:
##
##   > ¿Cuánto de los 20 s de bonus se juega, y cuántas veces hay que sujetar al
##   > jugador para que llegue al final?
##
## **La pregunta cambió al jugarla.** Antes era "cuánto tardas en drenar", con el
## objetivo de 3-4 s de `CAZA.md` §6. Daniel la probó y tumbó el planteamiento:
## *"es extremadamente fácil drenar e irte de la zona de caza"*, *"esta fase
## debería sentirse como un bonus, algo especial, no algo tan fácil de perder"*.
## Con salvabolas, la duración es SIEMPRE el tope, así que medir la duración ya no
## dice nada: lo que dice algo es cuántas veces te salva la mesa —o sea cuánto
## bonus tiras— y cuánto llegas a tocar mientras estás ahí.
##
##   godot --headless --path . --script tests/medir_planta_alta.gd
##
## No es una prueba: imprime tablas. Y mide DOS jugadores, que es lo que faltaba
## en `medir_caza.gd` — con un solo maniquí no se puede ver una brecha, porque
## una brecha son dos números.
##
## OJO CON EL BARRIDO: `Mesa.new()` copia los parámetros dentro de cada
## colisionador al construirse, así que tocar `m.p` después no hace nada. Por eso
## aquí se construye un `ParametrosMesa` nuevo por fila y se le pasa al
## constructor, que es el único momento en el que la geometría lo lee.

const DT := 1.0 / 120.0
const SEMILLAS := [7, 13, 271, 4242, 90210, 31337]
const POR_SEMILLA := 10

## Lo que sale de jugar una caza entera.
class Caza:
	var duracion: float = 0.0
	var por_drenaje := false
	var golpes: int = 0
	var recorridos: int = 0
	var en_rampa: float = 0.0
	var arriba: float = 0.0
	## Cuántas veces ha tenido que sujetarte la mesa, y cuándo la primera. La
	## primera importa aparte: si llega enseguida, lo que falla no son las palas,
	## es POR DÓNDE TE SUELTA el umbral.
	var salvadas: int = 0
	var primera_salvada: float = -1.0

func _initialize() -> void:
	print("")
	var base := ParametrosMesa.new()
	print("PLANTA ALTA · pala %.0f de largo, ejes a %.0f · hueco libre %.1f px"
		% [base.pala_alta_largo, base.pala_alta_separacion, _hueco(base)])
	print("")
	_a_los_dos_jugadores()
	_b_donde_se_juega()
	_c_barrido()
	quit()

## El hueco que queda entre las dos puntas en reposo, que es el objetivo de
## verdad: es por donde se drena, o sea el reloj de la caza.
func _hueco(p: ParametrosMesa) -> float:
	var avance := p.pala_alta_largo * cos(deg_to_rad(p.flipper_reposo_izq))
	return p.pala_alta_separacion - avance * 2.0 - p.flipper_radio * 2.0

# ------------------------------------------------------- los dos jugadores

## APORREA: pulsa las dos palas a ciegas cuando la bola baja. No juega, reacciona.
## Es el suelo de la brecha.
func _aporrea(m: Mesa, b: Bola, pulso: float) -> float:
	pulso -= DT
	if b.libre() and b.pos.y > m.p.arena_y_pala - 70.0 and b.vel.y > 0.0 \
			and pulso <= 0.0:
		pulso = 0.14
	m.flipper_alto_izq.pulsado = pulso > 0.0 and b.pos.x < Mesa.ANCHO * 0.5
	m.flipper_alto_der.pulsado = pulso > 0.0 and b.pos.x >= Mesa.ANCHO * 0.5
	return pulso

## ATRAPA: sube LAS DOS PALAS cuando la bola baja, y las mantiene hasta que la
## tiene posada. Es la técnica del juego —`CLAUDE.md`: mantener el flipper sigue
## siendo mantener el flipper— y es el techo de la brecha.
##
## LAS DOS, y no la del lado por el que cae, y esa corrección cambia la medida:
## subir solo una es apostar por dónde va a bajar la bola, o sea un maniquí con
## suerte. Un jugador que no quiere perder la bola sube las dos y decide después.
## Con una sola, el "jugador bueno" perdía la bola por el lado contrario y la
## brecha medía lo mal que adivinaba el maniquí, no lo que da la mesa.
##
## Y suelta al cabo de `_ESPERA_TIRO` con la bola quieta encima: atrapar y no
## tirar nunca no es jugar bien, es esconderse — y además dejaría la medida de
## golpes y recorridos a cero, que es lo que pasó en la primera pasada.
const _ESPERA_TIRO := 0.9

func _atrapa(m: Mesa, b: Bola, quieta: float) -> float:
	var posada: bool = b.libre() and m.flipper_atrapando != null
	quieta = quieta + DT if posada else 0.0
	# Con la bola posada y ya mirada, se suelta: soltar la pala es el tiro.
	var sube: bool = b.libre() and b.pos.y > m.p.arena_y_pala - 150.0 \
		and quieta < _ESPERA_TIRO
	m.flipper_alto_izq.pulsado = sube
	m.flipper_alto_der.pulsado = sube
	return 0.0 if quieta >= _ESPERA_TIRO else quieta

## Una caza entera, desde que la bola sale del umbral hasta que se acaba.
func _jugar(p: ParametrosMesa, semilla: int, i: int, atrapa: bool) -> Caza:
	var rng := RandomNumberGenerator.new()
	rng.seed = semilla * 1000 + i
	var m := Mesa.new(p)
	var salida := Caza.new()
	m.bumper_golpeado.connect(func(_pt: Vector2, _f: float) -> void: salida.golpes += 1)
	m.rampa_salida.connect(func(_pt: Vector2, j: int) -> void:
		if j != m.regreso and j != m.umbral:
			salida.recorridos += 1)
	var fin := [0]
	m.caza_terminada.connect(func(_pt: Vector2) -> void: fin[0] += 1)
	m.bola_salvada.connect(func(_pt: Vector2, n: int) -> void: salida.salvadas = n)
	var b := m.bola
	b.en_carril = false
	b.viva = true
	b.pos = p.umbral_boca
	b.vel = Vector2(rng.randf_range(-40.0, 40.0),
		-rng.randf_range(p.umbral_velocidad_minima + 60.0, 700.0))
	var t := 0.0
	var t0 := -1.0
	var pulso := 0.0
	var quieta := 0.0
	while t < p.caza_tiempo + 8.0 and b.viva and fin[0] == 0:
		if atrapa:
			quieta = _atrapa(m, b, quieta)
		else:
			pulso = _aporrea(m, b, pulso)
		m.avanzar(DT)
		t += DT
		if m.en_caza:
			if t0 < 0.0:
				t0 = t
			if salida.salvadas > 0 and salida.primera_salvada < 0.0:
				salida.primera_salvada = t - t0
			if not b.libre():
				salida.en_rampa += DT
			elif b.pos.y < p.arena_y_pala - 120.0:
				salida.arriba += DT
	salida.duracion = t - maxf(t0, 0.0)
	salida.por_drenaje = m.caza_por_drenaje
	return salida

func _tanda(p: ParametrosMesa, atrapa: bool) -> Array:
	var cazas: Array[Caza] = []
	for s in SEMILLAS:
		for i in POR_SEMILLA:
			cazas.append(_jugar(p, s, i, atrapa))
	return cazas

func _media(cazas: Array, campo: String) -> float:
	var suma := 0.0
	for c in cazas:
		suma += float(c.get(campo))
	return suma / float(cazas.size())

func _drenan(cazas: Array) -> int:
	var n := 0
	for c in cazas:
		if (c as Caza).por_drenaje:
			n += 1
	return n

# --------------------------------------------------------- A. la brecha

func _a_los_dos_jugadores() -> void:
	print("A · EL BONUS — 60 cazas por jugador")
	print("   jugador     dura   salvadas  1ª a los   golpes  recorridos")
	var p := ParametrosMesa.new()
	for perfil in [{"n": "aporrea", "a": false}, {"n": "atrapa ", "a": true}]:
		var cazas := _tanda(p, bool(perfil["a"]))
		print("   %s   %5.1f s   %6.1f    %5.1f s   %6.1f      %6.1f"
			% [perfil["n"], _media(cazas, "duracion"), _media(cazas, "salvadas"),
			_primera(cazas), _media(cazas, "golpes"), _media(cazas, "recorridos")])
	print("   con salvabolas la caza dura siempre el tope (%.0f s): lo que informa"
		% p.caza_tiempo)
	print("   son las salvadas, y sobre todo CUÁNDO llega la primera.")
	print("")

## Cuándo llega la primera salvada, contando solo las cazas en las que hubo. Si
## sale por debajo del segundo, el problema no son las palas: es que el umbral te
## suelta apuntando al desagüe.
func _primera(cazas: Array) -> float:
	var suma := 0.0
	var n := 0
	for c in cazas:
		if (c as Caza).primera_salvada >= 0.0:
			suma += (c as Caza).primera_salvada
			n += 1
	return suma / maxf(float(n), 1.0)

# ------------------------------------------------- B. ¿dónde se juega?

## LA PREGUNTA QUE NO ESTABA, y es la que decide si la planta alta se juega o se
## mira: una bola metida en una curva no es una bola en juego. Con cuatro
## recorridos arriba, la planta puede dar números buenísimos de duración y ser un
## tobogán en el que no tocas nada.
func _b_donde_se_juega() -> void:
	print("B · DÓNDE SE PASA EL TIEMPO — 60 cazas, jugador que aporrea")
	var p := ParametrosMesa.new()
	var cazas := _tanda(p, false)
	var dura := _media(cazas, "duracion")
	var rampa := _media(cazas, "en_rampa")
	var arriba := _media(cazas, "arriba")
	print("   dentro de un recorrido: %.1f s de %.1f (%.0f %%)"
		% [rampa, dura, rampa * 100.0 / maxf(dura, 0.001)])
	print("   por encima de la zona de palas: %.1f s (%.0f %%)"
		% [arriba, arriba * 100.0 / maxf(dura, 0.001)])
	print("")

# ----------------------------------------------------------- C. el barrido

## Los dos diales de `CAZA.md` §6, y se barren JUNTOS porque lo que se juega no
## es ninguno de los dos: es el hueco que dejan entre las puntas.
func _c_barrido() -> void:
	print("C · BARRIDO — largo × separación, 60 cazas por celda")
	print("   largo  separ  hueco   salvadas: aporrea / atrapa   golpes")
	for fila in [[46.0, 136.0], [54.0, 128.0], [54.0, 136.0], [54.0, 144.0],
			[64.0, 136.0], [64.0, 152.0]]:
		var p := ParametrosMesa.new()
		p.pala_alta_largo = float(fila[0])
		p.pala_alta_separacion = float(fila[1])
		var malos := _tanda(p, false)
		var buenos := _tanda(p, true)
		print("   %5.0f  %5.0f  %5.1f        %5.1f  /  %5.1f          %5.1f"
			% [fila[0], fila[1], _hueco(p), _media(malos, "salvadas"),
			_media(buenos, "salvadas"), _media(malos, "golpes")])
	print("")
