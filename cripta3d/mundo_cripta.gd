extends Node3D

## CRIPTA 3D — EL NÚCLEO DEL MUNDO.
##
## En ÓRBITA todo lo que se ve salía de un solo fichero de 1.400 líneas
## (`prueba3d/mundo_orbita.gd`). Aquí ese mismo trabajo está repartido en OCHO
## MÓDULOS (`cripta3d/mundo/<nombre>.gd`) para que ocho manos puedan rehacer el
## arte a la vez sin pisarse. Esto es lo único que comparten, y por eso NO
## DIBUJA NADA: da las medidas, las alturas, los materiales, el fuego y la caza,
## y carga los módulos.
##
## LO QUE DA (el contrato; está también en `cripta3d/LEEME.md`):
##
##   mesa, caza                 la mesa (`MesaCripta`) y la caza, o null
##   mat                        los materiales: `mat.dame("hierro")`, `mat.hay("x")`
##   entorno, entorno_reflejo   los `Environment` de las dos cámaras (los pone «entorno»)
##   luz_luna                   la luz de la luna (un `Light3D`), o null (la pone «entorno»)
##   mat_suelo                  el material del suelo que recibe el reflejo, o null
##   sacudida                   0..1: cuánto tiembla la cámara. Se apaga sola
##   latido                     0..1: la mesa entera acusa un golpe gordo. Se apaga solo
##   modulos                    nombre → instancia; `modulo("bola")` da null si falta
##   tiempo, r_bola             el reloj del mundo y el radio de la bola en unidades 3D
##   hundimiento_platillo       cuánto asoma la bola tragada por un platillo (×radio)
##   forzar_reserva             para probar: usa los materiales de reserva (`--reserva`)
##   en_web                     estamos en el navegador (o con `--como-web`): una sola
##                              variante por sombreador y ninguna sombra
##
##   calidad                    0 ALTA, 1 MEDIA, 2 BAJA: la que ha pedido la escena
##
##   E, H_PARED, H_ALTA, H_TUNEL          las medidas de la mesa
##   Y_SALA, Y_BOVEDA                     el suelo de la nave y por dónde cierra la bóveda
##   CAPA_BAJO_SUELO, CAPA_SIN_REFLEJO, CAPA_DETALLE   las capas de dibujo del reflejo
##
##   poner_calidad(n)           la escena la cambia; llama a `calidad(n)` de cada
##                              módulo y de cada cuerpo que la tenga
##   fuegos()                   las fichas de los fuegos dados de alta
##
##   a3(v, h)                   píxeles de mesa → unidades 3D
##   altura_capa(capa)          a qué altura está el suelo de una capa de la mesa
##   altura_en(punto)           a qué altura está el suelo en ese punto (el coro, H_ALTA)
##   altura_rampa(r, d)         la altura del raíl a `d` píxeles de su boca
##   altura_bola(b)             la altura a la que DEBERÍA estar el centro de la bola
##   posicion_bola(b)           dónde ESTÁ, con la altura ya suavizada
##   posicion_criatura(i)       el centro del cuerpo de la criatura `i`
##   chispear(...), onda(...)   los pide a «efectos», si está
##   luz_fuego(pos, e, alcance) una luz de fuego dada de alta para que parpadee
##   avivar(luz, cuanto)        fogonazo en un fuego ya dado de alta
##   latir(cuanto)              sube `latido`
##
## DOS COSAS QUE HACE ÉL Y NO UN MÓDULO, a propósito:
##
##   · SUAVIZA LA ALTURA DE LA BOLA. La simulación es plana: para ella la capa
##     es un entero. Aquí se le da cuerpo —sube pegada al raíl, CAE con peso
##     cuando se queda sin suelo— y se hace ANTES de mover ningún módulo, porque
##     de esa altura cuelgan la bola, su luz, la cámara, las almas y la criatura
##     que va dentro. Con cada uno suavizando por su cuenta irían a cinco
##     alturas distintas.
##   · HACE PARPADEAR EL FUEGO. Todas las llamas con el mismo ruido y cada una
##     con su fase, para que no haya una antorcha que respira y un brasero que
##     hace de intermitente. Por eso nadie escribe `light_energy` en una luz de
##     fuego: se pisa en cada cuadro. Para un fogonazo, `avivar`.

const MesaCripta := preload("res://cripta3d/mesa_cripta.gd")
const Criatura := preload("res://prueba3d/criatura.gd")
const Caza := preload("res://prueba3d/caza_orbita.gd")

## Un píxel de la mesa son 0,01 unidades 3D: la mesa mide 4 × 13.
const E := 0.01
const H_PARED := 0.16
## La tribuna del coro. Más alta que la estación de ÓRBITA (0,24): desde la
## cámara de juego, un escalón de un cuarto de unidad no se leía como otra planta.
const H_ALTA := 0.34
const H_TUNEL := -0.36
## LA SALA, que comparten tres módulos y por eso se mide aquí y no en cada uno:
## `Y_SALA` es el suelo de la nave, donde se apoya el bloque de la mesa (lo pone
## «arquitectura»; la bruma de «entorno» y los braseros de pie de «atrezzo» van
## sobre él); `Y_BOVEDA` es por donde cierra la bóveda, de donde cuelgan las
## cadenas y donde se acaban la niebla y los rayos. La primera vez «entorno»
## llevaba el suelo copiado a −0,42 y la bruma flotaba medio metro en el aire.
const Y_SALA := -0.9
const Y_BOVEDA := 7.0

## LAS CAPAS DE DIBUJO, que existen por la cámara del reflejo. Esa cámara mira
## la mesa desde debajo del suelo y solo ve la capa 1 (y la 8 de cerca):
##   1 (por defecto)  lo que se refleja en el suelo mojado
##   CAPA_BAJO_SUELO  lo que queda por debajo de y = 0 —el faldón del mueble, el
##                    suelo de la nave—. Si la cámara del reflejo lo viera, le
##                    saldría delante de todo: está de su lado del suelo
##   CAPA_SIN_REFLEJO lo que no merece reflejo: lo pintado a ras de suelo (su
##                    reflejo cae encima de sí mismo), las chispas y los rótulos.
##                    No es por gusto: en un navegador cada llamada de dibujo son
##                    unas treinta millonésimas de segundo, y el reflejo las repite
##   CAPA_DETALLE     lo menudo de las criaturas. El reflejo solo lo mira en las
##                    cámaras de cerca (`cripta_3d.gd`)
const CAPA_BAJO_SUELO := 2
const CAPA_SIN_REFLEJO := 4
const CAPA_DETALLE := 8

## El orden importa: el entorno va primero (los demás piden fuegos), el suelo
## antes que lo que se le pone encima, y los efectos al final.
const ORDEN: Array[String] = [
	"entorno", "suelo", "arquitectura", "atrezzo", "piezas", "railes", "bola", "efectos"]
const RUTA_MODULO := "res://cripta3d/mundo/%s.gd"
const RUTA_BIBLIOTECA := "res://cripta3d/materiales/biblioteca.gd"

## Qué cuerpo lleva cada especie de la caza. Si el fichero no existe todavía se
## usa el de ÓRBITA, que tiene el mismo contrato: el andamio funciona hoy y coge
## los cuerpos nuevos el día que aparezcan, sin tocar nada.
const CUERPOS := {
	"saltarin": "res://cripta3d/criaturas/brasa.gd",
	"gotita": "res://cripta3d/criaturas/brasa.gd",
	"escarabajo": "res://cripta3d/criaturas/calavera.gd",
	"corredor": "res://cripta3d/criaturas/espectro.gd",
}
const CUERPO_DE_ORBITA := "res://prueba3d/criatura_3d.gd"

## El color de una llama. Quien quiera otro se lo cambia a la luz que le devuelve
## `luz_fuego`: el parpadeo solo toca la energía.
const COLOR_FUEGO := Color(1.0, 0.60, 0.28)

var mesa: MesaCripta
var caza: Caza = null
## `Object` y no un tipo: puede ser la biblioteca de verdad o la de reserva.
var mat: Object = null
var entorno: Environment = null
var entorno_reflejo: Environment = null
## `Light3D` y no una direccional: la luna puede ser un foco que entra por el
## óculo, que es lo que es. La escena solo le toca `shadow_enabled`.
var luz_luna: Light3D = null
var mat_suelo: ShaderMaterial = null
## LA CALIDAD de los gráficos que ha pedido la escena: 0 ALTA, 1 MEDIA, 2 BAJA
## (`cripta_3d.gd`). Ver `poner_calidad`.
var calidad := 0
var sacudida := 0.0
var latido := 0.0
var modulos: Dictionary = {}
var tiempo := 0.0
var r_bola := 0.09
## Una bola dentro de un platillo queda con el centro a esta fracción de su
## radio por encima del suelo: 0,35 la deja hundida pero a la vista. Quien haga
## el sarcófago puede bajarla (−1,3 se la traga entera) desde su `montar`.
var hundimiento_platillo := 0.35
## Para probar: monta con los materiales de reserva aunque exista la biblioteca
## de verdad. Hay que ponerlo ANTES de `montar` (la escena lo hace con `--reserva`).
var forzar_reserva := false
## EN EL NAVEGADOR. Verdadero en el build web, y también con `-- --como-web`,
## que es como se ensaya en escritorio lo que solo pasa allí: las luces de
## relleno, el reflejo igualado y ninguna sombra (ver `_unificar_variantes`).
var en_web := OS.has_feature("web") or OS.get_cmdline_user_args().has("--como-web")
## Para medir: en web, sin las luces de relleno ni el reflejo igualado. Hay que
## ponerlo ANTES de `montar` (la escena lo hace con `--sin-relleno` o `?relleno=0`).
var sin_relleno := false

var _fuente: Font
## Bola → altura suavizada de su centro.
var _y_bola: Dictionary = {}
## Los fuegos dados de alta: {luz, energia, fase, golpe}. Y luz → su ficha.
var _fuegos: Array[Dictionary] = []
var _fuego_de: Dictionary = {}
## Los cuerpos de las criaturas, en el mismo orden que `caza.criaturas`.
var _bichos: Array[Node3D] = []

# ---------------------------------------------------------------- las medidas

func a3(v: Vector2, h: float = 0.0) -> Vector3:
	return Vector3(v.x * E, h, v.y * E)

func altura_capa(capa: int) -> float:
	if capa >= Mesa.CAPA_ALTA:
		return H_ALTA
	if capa <= Mesa.CAPA_TUNEL:
		return H_TUNEL
	return 0.0

## El suelo que hay en un punto de la mesa: el de la tribuna si cae dentro de
## una plataforma, el tablero si no.
func altura_en(punto: Vector2) -> float:
	if mesa == null:
		return 0.0
	for pl in mesa.plataformas:
		if pl.contiene(punto):
			return altura_capa(pl.capa)
	return 0.0

## La altura de un recorrido a `d` píxeles de su boca de entrada. Va de la capa
## de entrada a la de salida, y encima lleva el «lomo» de `mesa.info_rampas`:
## cuánto se levanta el raíl sobre sus dos bocas. Un túnel baja en vez de subir.
func altura_rampa(r: Rampa, d: float) -> float:
	var t := clampf(d / maxf(r.largo, 1.0), 0.0, 1.0)
	var base := lerpf(altura_capa(r.capa_entrada), altura_capa(r.capa_salida),
		smoothstep(0.0, 1.0, t))
	var subida := smoothstep(0.0, 70.0, d) * smoothstep(0.0, 70.0, r.largo - d)
	if r.subterranea:
		return base + H_TUNEL * subida
	var info: Dictionary = mesa.info_rampas.get(r.nombre, {})
	return base + float(info.get("lomo", 0.4)) * subida

## Dónde DEBERÍA estar el centro de la bola, sin suavizar.
func altura_bola(b: Bola) -> float:
	if b.rampa >= 0 and b.rampa < mesa.rampas.size():
		return altura_rampa(mesa.rampas[b.rampa], b.rampa_distancia) + r_bola
	if b.platillo >= 0 and b.platillo < mesa.platillos.size():
		return altura_en(mesa.platillos[b.platillo].centro) + r_bola * hundimiento_platillo
	return altura_capa(b.capa) + r_bola

## Dónde ESTÁ: es lo que hay que usar para dibujarla, seguirla o apuntarle.
func posicion_bola(b: Bola) -> Vector3:
	if b == null:
		return Vector3.ZERO
	return a3(b.pos, float(_y_bola.get(b, altura_bola(b))))

func posicion_criatura(indice: int) -> Vector3:
	if indice < 0 or indice >= _bichos.size():
		return Vector3.ZERO
	return _bichos[indice].call("centro")

func modulo(nombre: String) -> Object:
	return modulos.get(nombre)

## LA CALIDAD LLEGA A TODOS. La escena la cambia (tecla G, el vigilante de la
## web) y aquí se reparte: el módulo que tenga `calidad(n)` se entera y apaga lo
## suyo que pese —una sombra, la bruma, las pavesas, el desenfoque—. Antes la
## escena solo sabía tocar el brillo y la sombra de la luna, y en BAJA seguían
## dibujándose 550 llamadas de una sombra de fuego que nadie había apagado.
## 0 ALTA, 1 MEDIA, 2 BAJA. MEDIA y BAJA son lo que se ve en la web.
func poner_calidad(n: int) -> void:
	calidad = clampi(n, 0, 2)
	for nombre in ORDEN:
		var m: Object = modulos.get(nombre)
		if m != null and m.has_method("calidad"):
			m.call("calidad", calidad)
	for cuerpo in _bichos:
		if is_instance_valid(cuerpo) and cuerpo.has_method("calidad"):
			cuerpo.call("calidad", calidad)
	# En web, ninguna sombra: «entorno» acaba de repartir la suya (en ALTA se la
	# da a un fuego del campo) y aquí se le quita antes de que se dibuje nada.
	if en_web:
		for ficha in _fuegos:
			var que: Variant = ficha.get("luz")
			if is_instance_valid(que) and que is Light3D:
				(que as Light3D).shadow_enabled = false

## Los fuegos dados de alta, para quien reparte el presupuesto de luz («entorno»):
## una ficha por fuego, con "luz" (la OmniLight3D), "energia" (la de reposo, que
## es la que hay que cambiar: `light_energy` se pisa en cada cuadro), "fase" y
## "golpe". Es la misma lista, no una copia.
func fuegos() -> Array[Dictionary]:
	return _fuegos

# ------------------------------------------------- lo que se le pide a «efectos»

func chispear(punto: Vector2, altura: float, color: Color, cuantas: int) -> void:
	var fx: Object = modulos.get("efectos")
	if fx != null and fx.has_method("chispear"):
		fx.call("chispear", punto, altura, color, cuantas)

func onda(punto: Vector2, altura: float, color: Color, radio: float) -> void:
	var fx: Object = modulos.get("efectos")
	if fx != null and fx.has_method("onda"):
		fx.call("onda", punto, altura, color, radio)

func latir(cuanto: float) -> void:
	latido = maxf(latido, clampf(cuanto, 0.0, 1.0))

# ------------------------------------------------------------------- el fuego

## Crea una luz de fuego, la cuelga del mundo y la da de alta para que parpadee.
## `energia` es la de reposo: el núcleo la mueve alrededor de ese valor en cada
## cuadro, así que NO se escribe `light_energy` a mano. La devuelve para que
## quien la pide le ponga sombra, otro color o la mueva.
func luz_fuego(pos: Vector3, energia: float, alcance: float) -> OmniLight3D:
	var luz := OmniLight3D.new()
	luz.light_color = COLOR_FUEGO
	luz.light_energy = energia
	luz.omni_range = alcance
	luz.position = pos
	add_child(luz)
	# Cada una con su fase, y lejos unas de otras: con fases vecinas, dos
	# antorchas juntas suben y bajan a la vez y se nota el truco.
	var ficha := {"luz": luz, "energia": energia, "golpe": 0.0,
		"fase": 3.7 + float(_fuegos.size()) * 17.31}
	_fuegos.append(ficha)
	_fuego_de[luz] = ficha
	return luz

## Un fogonazo: el fuego sube de golpe y vuelve solo. `cuanto` de 0 a 1.
func avivar(luz: OmniLight3D, cuanto: float) -> void:
	if not is_instance_valid(luz):
		return
	var ficha: Dictionary = _fuego_de.get(luz, {})
	if not ficha.is_empty():
		ficha["golpe"] = maxf(float(ficha["golpe"]), cuanto)

static func _azar(n: int) -> float:
	return fposmod(sin(float(n) * 127.1 + 311.7) * 43758.5453, 1.0)

## Ruido de valor en una dimensión, de 0 a 1: suave, sin periodo que se note.
static func _ruido(x: float) -> float:
	var i := floori(x)
	var f := x - float(i)
	f = f * f * (3.0 - 2.0 * f)
	return lerpf(_azar(i), _azar(i + 1), f)

## Dos octavas: una lenta, que es la llama respirando, y una rápida y pequeña,
## que es el chisporroteo. Con una sola se ve un seno; con el rápido muy alto,
## un fluorescente roto.
func _parpadear(delta: float) -> void:
	var i := _fuegos.size() - 1
	while i >= 0:
		var ficha := _fuegos[i]
		i -= 1
		# Quien pidió la luz puede haberla liberado: se da de baja sola. Y se
		# comprueba ANTES de darle tipo, sobre el valor suelto: asignar un objeto
		# liberado a una variable con tipo ya es un error, y saldría uno por cuadro.
		var que: Variant = ficha["luz"]
		if not is_instance_valid(que):
			_fuego_de.erase(que)
			_fuegos.remove_at(i + 1)
			continue
		var luz: OmniLight3D = que
		var golpe: float = maxf(float(ficha["golpe"]) - delta * 4.5, 0.0)
		ficha["golpe"] = golpe
		var fase: float = ficha["fase"]
		var llama := 0.80 + 0.30 * _ruido(tiempo * 2.1 + fase) \
			+ 0.12 * _ruido(tiempo * 8.7 + fase * 2.3)
		luz.light_energy = float(ficha["energia"]) * (llama + latido * 0.30 + golpe * 4.0)
		# En web, ningún fuego con sombra (ver `_unificar_variantes`).
		if en_web and luz.shadow_enabled:
			luz.shadow_enabled = false

# -------------------------------------------------------------------- montaje

func montar(la_mesa: MesaCripta) -> void:
	mesa = la_mesa
	r_bola = mesa.p.radio_bola * E
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Georgia", "Constantia", "Cambria", "Times New Roman"])
	_fuente = f
	_montar_materiales()
	for nombre in ORDEN:
		_cargar_modulo(nombre)
	if entorno == null:
		_entorno_de_reserva()
	_aligerar_reflejo(self)
	if en_web and not sin_relleno:
		_unificar_variantes()

## UNA SOLA VARIANTE POR SOMBREADOR (solo en web). El renderizador Compatibility
## compila un PROGRAMA distinto del mismo sombreador por cada combinación de
## luces que le toca a una malla —con omni, con foco, con las dos, con ninguna—
## y otro más si el entorno de su cámara aplica la curva de tono dentro del
## sombreador en vez de después (`rasterizer_scene_gles3.cpp`: `DISABLE_LIGHT_OMNI`,
## `DISABLE_LIGHT_SPOT`, `APPLY_TONEMAPPING`). En escritorio da igual. En un
## navegador de Windows cada programa con luz son segundos de Direct3D
## (`banco_sombreadores.gd`), y la piedra, que está por toda la sala, acababa
## compilándose tres y cuatro veces.
##
##   · DOS LUCES DE RELLENO, una omni y un foco, que alcanzan la sala entera y
##     no alumbran nada: así a TODAS las mallas les tocan «omni y foco» y cada
##     sombreador se compila una vez. Van muy lejos a propósito: Godot reparte
##     las ocho luces de cada malla por cercanía, y la de relleno, que siempre
##     es la más lejana, solo ocupa un hueco que estaba libre.
##   · EL ENTORNO DEL REFLEJO, igualado al principal en lo único que cambia de
##     programa: que los efectos vayan «en el post». El principal lleva brillo y
##     ajustes; al del reflejo se le encienden unos ajustes NEUTROS (brillo,
##     contraste y saturación a 1), que dejan su imagen como estaba.
##
## Y NINGUNA SOMBRA: una luz con sombra obliga a cada material que alcanza a
## compilar otra pasada más (la aditiva). La apaga `_parpadear`, que ya recorre
## los fuegos en cada cuadro, porque «entorno» reparte la suya cuando quiere.
func _unificar_variantes() -> void:
	var lejos := Vector3(2.0, 60.0, 9.5)
	var omni := OmniLight3D.new()
	omni.name = "RellenoOmni"
	omni.position = lejos
	omni.omni_range = 200.0
	omni.light_energy = 0.0001
	omni.light_specular = 0.0
	omni.shadow_enabled = false
	add_child(omni)
	var foco := SpotLight3D.new()
	foco.name = "RellenoFoco"
	foco.position = lejos
	foco.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	foco.spot_range = 200.0
	foco.spot_angle = 80.0
	foco.light_energy = 0.0001
	foco.light_specular = 0.0
	foco.shadow_enabled = false
	add_child(foco)
	if entorno_reflejo != null and not entorno_reflejo.adjustment_enabled:
		entorno_reflejo.adjustment_enabled = true
		entorno_reflejo.adjustment_brightness = 1.0
		entorno_reflejo.adjustment_contrast = 1.0
		entorno_reflejo.adjustment_saturation = 1.0

## LOS MATERIALES. Si la biblioteca de verdad existe, es ella; si no —o si no
## carga—, una de reserva con la misma forma, para que el andamio se vea en gris
## desde el primer día y los módulos se escriban ya contra `mat.dame(...)`.
func _montar_materiales() -> void:
	if not forzar_reserva and ResourceLoader.exists(RUTA_BIBLIOTECA):
		var guion := load(RUTA_BIBLIOTECA) as GDScript
		if guion != null and guion.can_instantiate():
			var biblioteca: Variant = guion.new()
			if biblioteca is Object and (biblioteca as Object).has_method("dame"):
				mat = biblioteca
				return
		print("MUNDO: la biblioteca de materiales no carga o no tiene dame(): uso la de reserva")
	mat = Reserva.new()

## Carga un módulo y lo monta. Que falte uno, que no compile o que no tenga
## `montar` no para nada: se dice por la salida y se sigue con los demás, que es
## lo que deja trabajar en un módulo con otro a medio escribir. (`ruta` solo se
## pasa para probar esto mismo con un guion de fuera.)
func _cargar_modulo(nombre: String, ruta: String = "") -> void:
	if ruta == "":
		ruta = RUTA_MODULO % nombre
	if not ResourceLoader.exists(ruta):
		print("MUNDO: falta el módulo «%s» (%s): sigo sin él" % [nombre, ruta])
		return
	var guion := load(ruta) as GDScript
	if guion == null or not guion.can_instantiate():
		print("MUNDO: el módulo «%s» no carga (mira los errores de arriba): sigo sin él" % nombre)
		return
	var instancia: Variant = guion.new()
	if not (instancia is Object) or not (instancia as Object).has_method("montar"):
		print("MUNDO: el módulo «%s» no tiene montar(mundo): sigo sin él" % nombre)
		return
	modulos[nombre] = instancia
	(instancia as Object).call("montar", self)

## Si «entorno» no está, que al menos se vea algo y la escena tenga los dos
## `Environment` que da por hechos.
func _entorno_de_reserva() -> void:
	entorno = Environment.new()
	entorno.background_mode = Environment.BG_COLOR
	entorno.background_color = Color(0.03, 0.028, 0.03)
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.55, 0.57, 0.65)
	entorno.ambient_light_energy = 0.9
	entorno_reflejo = entorno.duplicate() as Environment
	var we := WorldEnvironment.new()
	we.environment = entorno
	add_child(we)

## Saca de la capa del reflejo lo que no lo necesita: lo que queda a ras de
## suelo, las partículas y los rótulos. Se hace UNA vez, al acabar de montar: lo
## que un módulo cree después —o lo que suba más tarde— no pasa por aquí, y si no
## debe reflejarse tiene que ponerse él la capa.
func _aligerar_reflejo(raiz: Node) -> void:
	if not is_inside_tree():
		print("MUNDO: se ha montado fuera del árbol: no puedo aligerar el reflejo")
		return
	for n in raiz.get_children():
		_aligerar_reflejo(n)
		var gi := n as GeometryInstance3D
		if gi == null or (gi.layers & 1) == 0:
			continue
		var fuera := gi is Label3D or gi is CPUParticles3D or gi is GPUParticles3D
		if not fuera:
			var caja: AABB = gi.global_transform * gi.get_aabb()
			fuera = caja.position.y + caja.size.y < 0.03
		if fuera:
			gi.layers = CAPA_SIN_REFLEJO

# ---------------------------------------------------------------- cada cuadro

func actualizar(delta: float) -> void:
	tiempo += delta
	sacudida = maxf(sacudida - delta * 4.0, 0.0)
	latido = maxf(latido - delta * 2.5, 0.0)
	_suavizar_bolas(delta)
	_parpadear(delta)
	_repartir_tintes()
	for nombre in ORDEN:
		var m: Object = modulos.get(nombre)
		if m != null:
			m.call("actualizar", delta)
	_actualizar_caza(delta)

## LA ALTURA DE LA BOLA. Sube a 6 unidades por segundo —pegada al raíl, sin que
## se note— y BAJA a 2,8: caerse de la tribuna o del final de un raíl tarda una
## décima larga, que es lo que hace que la bola pese. Una bola nueva nace ya a
## su altura.
func _suavizar_bolas(delta: float) -> void:
	var vivas := {}
	for b in mesa.bolas:
		if not b.viva:
			continue
		vivas[b] = true
		var destino := altura_bola(b)
		var y: float = _y_bola.get(b, destino)
		if destino < y:
			y = maxf(destino, y - 2.8 * delta)
		else:
			y = minf(destino, y + 6.0 * delta)
		_y_bola[b] = y
	for b in _y_bola.keys():
		if not vivas.has(b):
			_y_bola.erase(b)

## La bola que lleva una criatura dentro va de su color. Se dice EN CADA CUADRO
## y no al recogerla: así no hay nada que acordarse de apagar si la criatura se
## escapa, se asegura o la quitan con una tecla.
func _repartir_tintes() -> void:
	if caza == null:
		return
	var bolas: Object = modulos.get("bola")
	if bolas == null or not bolas.has_method("tenir"):
		return
	for i in _bichos.size():
		var c: Criatura = caza.criaturas[i]
		if c.estado == Criatura.Estado.EN_BOLA and c.portadora != null:
			bolas.call("tenir", c.portadora, _color_del_cuerpo(_bichos[i]))

# -------------------------------------------------------------------- la caza

## Pone en la mesa los cuerpos de las criaturas de una caza y escucha lo que les
## pasa, para darle chispa. La caza decide; esto solo lo enseña.
func montar_caza(la_caza: Caza) -> void:
	caza = la_caza
	for c: Criatura in caza.criaturas:
		var cuerpo := _crear_cuerpo(c.especie)
		if "t_cierre" in cuerpo:
			cuerpo.set("t_cierre", caza.t_cierre)
		if "t_volcada" in cuerpo:
			cuerpo.set("t_volcada", caza.t_volcada)
		if "arco_blindaje" in cuerpo:
			cuerpo.set("arco_blindaje", caza.arco_blindaje)
		add_child(cuerpo)
		cuerpo.call("montar", c, _fuente)
		_bichos.append(cuerpo)
	caza.criatura_aparecio.connect(_al_aparecer_criatura)
	caza.criatura_golpeada.connect(_al_golpear_criatura)
	caza.criatura_blindada.connect(_al_blindar_criatura)
	caza.criatura_volcada.connect(_al_volcar_criatura)
	caza.criatura_partida.connect(_al_partir_criatura)
	caza.criatura_reunida.connect(_al_reunir_criatura)
	caza.criatura_acorralada.connect(_al_acorralar_criatura)
	caza.criatura_recogida.connect(_al_recoger_criatura)
	caza.criatura_asegurada.connect(_al_asegurar_criatura)
	caza.criatura_escapada.connect(_al_escapar_criatura)
	caza.criatura_escondida.connect(_al_esconder_criatura)
	caza.criatura_asoma.connect(_al_asomar_criatura)
	caza.criatura_expulsada.connect(_al_expulsar_criatura)
	caza.criatura_rescatada.connect(_al_rescatar_criatura)
	caza.boca_tapada.connect(_al_tapar_boca)
	caza.susto_general.connect(_al_susto_general)
	caza.caza_completa.connect(_al_completar_caza)

func _crear_cuerpo(especie: String) -> Node3D:
	var ruta: String = CUERPOS.get(especie, "")
	if ruta != "" and ResourceLoader.exists(ruta):
		var guion := load(ruta) as GDScript
		if guion != null and guion.can_instantiate():
			var nuevo: Variant = guion.new()
			if nuevo is Node3D and (nuevo as Node3D).has_method("montar"):
				return nuevo
			if nuevo is Node:
				(nuevo as Node).free()
		print("MUNDO: el cuerpo %s no carga o no es un Node3D con montar(): uso el de ÓRBITA" % ruta)
	return (load(CUERPO_DE_ORBITA) as GDScript).new() as Node3D

func _cuerpo_de(c: Criatura) -> Node3D:
	return _bichos[c.indice]

func _color_del_cuerpo(cuerpo: Node3D) -> Color:
	if cuerpo != null and cuerpo.has_method("color"):
		return cuerpo.call("color")
	return Paleta.TIERRA_6

func _color_de(c: Criatura) -> Color:
	return _color_del_cuerpo(_cuerpo_de(c))

func _encender_boca(boca: int) -> void:
	var railes: Object = modulos.get("railes")
	if railes != null and railes.has_method("encender_boca"):
		railes.call("encender_boca", boca)

func _al_aparecer_criatura(c: Criatura, punto: Vector2) -> void:
	var col := _color_de(c)
	onda(punto, 0.02, col, 0.35)
	chispear(punto, 0.08, col, 8)

func _al_golpear_criatura(c: Criatura, punto: Vector2, fuerza: float,
		normal: Vector2) -> void:
	_cuerpo_de(c).call("golpear", normal)
	var col := _color_de(c)
	chispear(punto, 0.12, col, 14)
	onda(c.pos, 0.02, col, 0.45)
	sacudida = maxf(sacudida, clampf(fuerza / 1100.0, 0.35, 0.8))

## De frente, la calavera para la bola: salta esquirla de hueso, no fuego.
func _al_blindar_criatura(c: Criatura, punto: Vector2, fuerza: float) -> void:
	var cuerpo := _cuerpo_de(c)
	if cuerpo.has_method("blindar"):
		cuerpo.call("blindar")
	chispear(punto, 0.12, Paleta.TIERRA_6, 16)
	onda(punto, 0.02, Paleta.TIERRA_6, 0.28)
	sacudida = maxf(sacudida, clampf(fuerza / 900.0, 0.4, 0.9))

func _al_volcar_criatura(c: Criatura, punto: Vector2) -> void:
	var col := _color_de(c)
	onda(punto, 0.02, col, 0.55)
	chispear(punto, 0.10, col, 10)

func _al_partir_criatura(c: Criatura, punto: Vector2) -> void:
	var col := _color_de(c)
	onda(c.pos, 0.02, col, 0.6)
	chispear(punto, 0.12, col, 16)

func _al_reunir_criatura(c: Criatura, punto: Vector2) -> void:
	var col := _color_de(c)
	onda(punto, 0.02, col, 0.5)
	chispear(punto, 0.10, col, 12)

func _al_acorralar_criatura(c: Criatura) -> void:
	latir(1.0)
	onda(c.pos, 0.02, Paleta.ROJO_LUZ, 0.6)

## Al recogerla, unas almas van de la criatura a la bola: es lo que cuenta, sin
## una palabra, que ahora va DENTRO.
func _al_recoger_criatura(c: Criatura, punto: Vector2) -> void:
	var col := _color_de(c)
	onda(punto, 0.02, col, 0.4)
	var fx: Object = modulos.get("efectos")
	if c.portadora != null and fx != null and fx.has_method("soltar_almas"):
		fx.call("soltar_almas", a3(c.pos, 0.14), c.portadora, col, 7)

func _al_asegurar_criatura(c: Criatura, punto: Vector2) -> void:
	var col := _color_de(c)
	onda(punto, 0.02, col, 0.5)
	chispear(punto, 0.12, col, 12)
	if c.principal:
		# La entera, a salvo: onda doble desde la pala y la mesa late.
		onda(punto, 0.03, Paleta.TIERRA_6, 0.95)
		chispear(punto, 0.16, Paleta.TIERRA_6, 16)
		latir(1.0)
		sacudida = maxf(sacudida, 0.5)

func _al_escapar_criatura(_c: Criatura, punto: Vector2) -> void:
	onda(punto, 0.02, Paleta.GRIS_4, 0.5)

func _al_esconder_criatura(c: Criatura, punto: Vector2) -> void:
	_encender_boca(c.boca_entrada)
	onda(punto, 0.02, _color_de(c), 0.3)

## Medio segundo antes de salir, la boca por la que va a asomar se enciende: es
## el aviso que hace justo esperarla.
func _al_asomar_criatura(_c: Criatura, boca: int) -> void:
	_encender_boca(boca)

func _al_expulsar_criatura(c: Criatura, punto: Vector2) -> void:
	var col := _color_de(c)
	onda(punto, 0.02, col, 0.5)
	chispear(punto, 0.10, col, 12)

func _al_rescatar_criatura(c: Criatura, punto: Vector2) -> void:
	chispear(punto, 0.08, _color_de(c), 8)

func _al_tapar_boca(_boca: int, punto: Vector2) -> void:
	onda(punto, 0.02, Paleta.ROJO_LUZ, 0.26)

func _al_susto_general(cuanto: float) -> void:
	latir(clampf(cuanto * 4.0, 0.2, 1.0))
	# Y el aro del que tiene miedo parpadea: es lo que ata "le he dado a un
	# brasero" con "le ha subido el miedo". Un efecto se enseña donde se mide.
	for i in _bichos.size():
		var c: Criatura = caza.criaturas[i]
		if c.especie == "corredor" and c.activa and c.a_la_vista() \
				and _bichos[i].has_method("avisar_aro"):
			_bichos[i].call("avisar_aro")

func _al_completar_caza(_ola: int) -> void:
	latir(1.0)
	sacudida = maxf(sacudida, 0.6)
	var centro: Vector2 = caza.nodos[Caza.NODO_CENTRO]
	onda(centro, 0.03, Paleta.TIERRA_6, 1.4)
	onda(centro, 0.03, Paleta.ORO, 0.9)

func _actualizar_caza(delta: float) -> void:
	if caza == null:
		return
	for i in _bichos.size():
		var c: Criatura = caza.criaturas[i]
		var donde := Vector3.ZERO
		if c.estado == Criatura.Estado.EN_BOLA and c.portadora != null:
			donde = posicion_bola(c.portadora)
		_bichos[i].call("actualizar", delta, donde)

# -------------------------------------------------- los materiales de reserva

## LA BIBLIOTECA DE RESERVA. Solo entra si la de verdad
## (`cripta3d/materiales/biblioteca.gd`) falta o no carga, y tiene su misma
## forma: `dame(nombre, variante)` y `hay(nombre)`, los mismos catorce nombres y
## las mismas claves de variante. Así un módulo escrito contra la de verdad
## sigue funcionando el día que la de verdad se rompa: se ve feo, pero se ve.
##
## Son `StandardMaterial3D` lisos con el tinte de la paleta del juego. De las
## variantes solo entiende las cuatro que se pueden decir sin sombreador
## —tinte, emision, rugosidad y doble_cara—; las demás las acepta y las ignora.
## Igual que la de verdad: sin variante devuelve SIEMPRE la misma instancia, y
## con variante una por combinación. Quien vaya a ANIMAR un material —el ascua
## de un brasero— lo duplica antes, o se le encienden todos a la vez.
class Reserva extends RefCounted:
	const CLAVES: Array[String] = ["tinte", "escala", "vertice", "emision", "mojado",
		"desgaste", "suciedad", "semilla", "local", "veta", "juntas", "relieve",
		"rugosidad", "doble_cara", "depura"]

	var _base: Dictionary = {}
	var _cache: Dictionary = {}
	var _avisados: Dictionary = {}

	func _init() -> void:
		_poner("piedra", Paleta.PIEDRA_2, 0.0, 0.90)
		_poner("losa", Paleta.PIEDRA_1, 0.0, 0.55)
		_poner("hierro", Paleta.GRIS_2, 0.55, 0.58)
		_poner("oxido", Paleta.COBRE_2, 0.25, 0.85)
		_poner("bronce", Paleta.ORO_OSCURO, 0.80, 0.45)
		_poner("laton", Paleta.ORO, 0.90, 0.32)
		_poner("acero", Paleta.GRIS_4, 0.90, 0.30)
		_poner("madera", Paleta.TIERRA_3, 0.0, 0.80)
		_poner("hueso", Paleta.TIERRA_5, 0.0, 0.70)
		_poner("goma", Paleta.ROJO, 0.0, 0.62)
		_poner("cera", Paleta.TIERRA_6, 0.0, 0.50)
		_poner("carbon", Paleta.NEGRO, 0.0, 0.95)
		_poner("ascua", Paleta.ROJO_LUZ, 0.0, 0.70, Paleta.NARANJA, 2.4)
		_poner("arcano", Paleta.ARCANO_1, 0.0, 0.50, Paleta.ARCANO, 1.6)

	func _poner(nombre: String, tinte: Color, metal: float, rugosidad: float,
			emision: Color = Color.BLACK, energia: float = 0.0) -> void:
		var m := StandardMaterial3D.new()
		m.albedo_color = tinte
		m.metallic = metal
		m.roughness = rugosidad
		if energia > 0.0:
			m.emission_enabled = true
			m.emission = emision
			m.emission_energy_multiplier = energia
		_base[nombre] = m

	func _avisar(clave: String, texto: String) -> void:
		if not _avisados.has(clave):
			_avisados[clave] = true
			print(texto)

	func hay(nombre: String) -> bool:
		return _base.has(nombre)

	func dame(nombre: String, variante: Dictionary = {}) -> Material:
		if not _base.has(nombre):
			_avisar("material:" + nombre,
				"MATERIALES (reserva): no hay material «%s»; doy piedra" % nombre)
			nombre = "piedra"
		var m: StandardMaterial3D = _base[nombre]
		if variante.is_empty():
			return m
		var clave := nombre + "|" + str(variante)
		if _cache.has(clave):
			return _cache[clave]
		var copia := m.duplicate() as StandardMaterial3D
		for k: Variant in variante:
			var v: Variant = variante[k]
			match str(k):
				"tinte":
					if v is Color:
						copia.albedo_color = m.albedo_color * (v as Color)
						copia.emission = m.emission * (v as Color)
				"emision":
					# Como en la de verdad: la energía de lo que ya da luz, y en lo
					# demás una luz propia pareja, del color del fuego.
					if not m.emission_enabled:
						copia.emission = Paleta.NARANJA
					copia.emission_enabled = true
					copia.emission_energy_multiplier = maxf(float(v), 0.0)
				"rugosidad":
					copia.roughness = clampf(m.roughness * float(v), 0.04, 1.0)
				"doble_cara":
					if bool(v):
						copia.cull_mode = BaseMaterial3D.CULL_DISABLED
				_:
					if not CLAVES.has(str(k)):
						_avisar("clave:" + str(k),
							"MATERIALES (reserva): no conozco la variante «%s»" % str(k))
		_cache[clave] = copia
		return copia
