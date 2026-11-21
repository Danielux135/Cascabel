extends RefCounted

## CRIPTA 3D · MÓDULO «entorno» · LA LUZ, EL AIRE Y EL ACABADO
##
## Es el módulo que decide si esto se lee como una maqueta fotografiada o como
## un juguete en una caja negra. No pone ni una pieza de la mesa: pone lo que
## hay ENTRE las piezas y la cámara.
##
## QUÉ MONTA
##   · EL `Environment` de la cámara de juego y su gemelo para la del reflejo.
##     ES DE NOCHE: el fondo, los negros y la niebla lejana son azul noche muy
##     oscuro (cerca de #05070C), nunca granate; el calor lo pone el fuego donde
##     hay fuego. Fondo: un cielo (`entorno_cielo.gdshader`) que a la vista es
##     casi negro y frío, y que solo en los REFLEJOS (el mapa de radiancia) lleva
##     una franja de fuego baja y la luna. Ambiente frío y muy bajo. Curva de tono
##     (AgX por defecto; `--tono=aces` para comparar), brillo con umbral ALTO
##     (solo pasan fuego, ascuas y ojos) y niebla de profundidad y de altura.
##   · LA LUNA: un FOCO (`SpotLight3D`) puesto detrás del óculo del ábside
##     (0,95 ; 1,55 ; 5,94), que apunta por él al centro de la mesa y deja un
##     CHARCO frío y alargado en mitad del campo, de z≈7,5 a z≈10,5, con el
##     borde blando y poco brillo especular (el suelo mojado repetía el canto y,
##     visto bajo, era la elipse de un foco de teatro que llegaba a la pala
##     izquierda). SIN SOMBRA: cuesta cero y es igual en las tres calidades.
##     *Probado y quitado:* una direccional con sombra. Costaba la mitad del
##     fotograma (unas 1.100 llamadas y 1,1 M de triángulos en ALTA), rayaba el
##     campo con la sombra de los raíles —camuflaje para la bola—, salía en
##     dientes de sierra, y en MEDIA y BAJA (la web) se quedaba sin sombra y
##     bañaba la cripta entera, que es justo lo contrario de «entra por el óculo».
##     Un foco detrás del muro no alumbra la cara de dentro del ábside (la tiene
##     de espaldas), así que no necesita sombra para no atravesarlo.
##   · EL RAYO DE LUNA: una malla con un sombreador que integra el aire
##     iluminado por dentro (`entorno_rayo.gdshader`), con la sombra de la reja
##     del óculo y humo que baja. *Quitados:* los dos rayos que caían de la
##     bóveda a los lados de la nave. Con la sala cerrada por arriba (la bóveda de
##     «arquitectura», a `Y_BOVEDA`) la luna solo puede entrar por el óculo.
##   · EL ÓCULO QUE BRILLA: detrás de la reja, una tarjeta azul luna
##     (`entorno_oculo.gdshader`), y en la boca un halo de cara a la cámara
##     (`entorno_halo.gdshader`) que empalma con el arranque del rayo. Antes, desde
##     la mesa, el hueco era un disco más oscuro que el muro. Necesitan el `oculo`
##     de «arquitectura», así que se montan en el primer `actualizar`.
##   · EL LAVADO DE LA BÓVEDA: una omni fría, débil y sin sombra junto al óculo,
##     que insinúa el cuarto de esfera del ábside (estaba a 1 de 255).
##   · EL POLVO del rayo (solo se ve donde lo toca la luna) y unas PAVESAS que
##     se escapan de los braseros. Todo en `MultiMesh` y movido en el
##     sombreador: cero trabajo por cuadro aquí.
##   · LA BRUMA: sábanas de niebla a ras del suelo de la nave (`Y_SALA`), que
##     reciben la luz de verdad (al lado de un fuego se encienden en naranja).
##     Encima del tablero no hay ninguna: la mesa se juega limpia.
##   · EL FUEGO: el RELLENO de la zona de palas, un foco cálido desde detrás del
##     jugador (los braseros de su lado, fuera de cuadro), y la JERARQUÍA de
##     todos los fuegos de la mesa (ver «El fuego» abajo).
##   · El posprocesado de pantalla NO se monta aquí: es
##     `cripta3d/materiales/post.gdshader`, que lo pone la escena. Pero es de
##     este módulo y va a juego con la curva de tono de aquí.
##
## QUÉ RELLENA EN EL NÚCLEO (la escena `cripta_3d.gd` lo lee tal cual)
##   mundo.entorno           el de la cámara de juego
##   mundo.entorno_reflejo   el de la cámara del reflejo (sin curva ni brillo)
##   mundo.luz_luna          el foco de la luna (sin sombra)
##
## SEÑALES QUE ESCUCHA
##   mesa.descarga_empezada  la campana mayor toca: el golpe suelta polvo de la
##                           bóveda (el del rayo cae más deprisa y brilla) y aviva
##                           las pavesas.
## FUNCIONES PÚBLICAS
##   calidad(n)              0 ALTA, 1 MEDIA, 2 BAJA (la llama el núcleo, en
##                           `poner_calidad`). Ver «La calidad» abajo.
##
## LO QUE NO PUEDE DEJAR DE HACER QUIEN LO REESCRIBA
##   1. Rellenar las tres variables de arriba y colgar su `WorldEnvironment` del
##      mundo. Sin `entorno`, el núcleo pone uno de reserva plano y feo.
##   2. `entorno_reflejo` va SIN curva de tono y SIN brillo: su imagen no va a la
##      pantalla, va al suelo, y el suelo pasa luego por las dos cosas. Con ellas
##      el reflejo se quema dos veces. Por eso se duplica ANTES de ponerlas.
##   3. La escena le toca dos mandos por la calidad de los gráficos:
##      `entorno.glow_enabled` y `background_mode` (en BAJA puede pasarlo a
##      `BG_COLOR`: `background_color` tiene que valer siempre, aunque el fondo
##      sea un cielo; por eso es el color de la mitad de abajo del cielo). La
##      sombra de la luna YA NO la toca: como este módulo tiene `calidad(n)`, la
##      escena se la deja (y la luna no lleva sombra en ninguna calidad).
##
## LA CALIDAD (decisión: MEDIA y BAJA son la web y tienen que ser la misma cripta)
##   ALTA   todo, y la ÚNICA sombra de fuego, para un fuego DEL CAMPO.
##   MEDIA  sin sombra de fuego; la bruma, solo la capa baja y la del fondo.
##   BAJA   además, la bruma solo en la capa baja y sin el desenfoque de maqueta
##          del posprocesado. La luna, el rayo, el polvo, las pavesas, la niebla
##          y la jerarquía del fuego son los mismos en las tres: es lo que hace
##          que se lea como la misma cripta.
##   4. El fuego se pide con `mundo.luz_fuego(pos, energia, alcance)`, que lo da
##      de alta para que parpadee. NO se anima `light_energy` a mano: el núcleo la
##      escribe en cada cuadro. Para un fogonazo, `mundo.avivar(luz, cuanto)`.
##   5. Compatibility aplica 8 luces omni/foco por malla como mucho. Cada fuego
##      con alcance largo le quita sitio a los demás en todo lo que toca.
##   6. No hay luz sin motivo (`LEEME.md`): el relleno viene de FUERA de cuadro,
##      del lado del jugador, donde ninguna cámara llega. *Probado y quitado:* dos
##      resplandores bajos a los lados de la nave; desde la cámara cenital se veían
##      como dos charcos naranjas sin nada que los encendiera.
##
## EL FUEGO: LA JERARQUÍA
##   Las luces de fuego las dan de alta los otros módulos (antorchas, braseros,
##   velas) cuando se montan, que es DESPUÉS que este. Así que el reparto se hace
##   en `actualizar`, cada vez que cambia el número de fuegos, sobre
##   `mundo.fuegos()`. A cada fuego se le cambia la energía DE REPOSO (la ficha,
##   "energia": `light_energy` la pisa el núcleo en cada cuadro) según dónde está:
##     campo (braseros de juego, coro, escudos)   × 1
##     ábside (las dos antorchas, el sarcófago)   × MULT_ABSIDE      (la mitad)
##     albardilla (braseros de las esquinas y la
##       luz de su farol, en la columna)           × MULT_ALBARDILLA  (algo más de
##                                                  la mitad, con la caída lenta)
##     sala (braseros de pie)                      × MULT_SALA        (algo más de
##                                                  un cuarto, y con más alcance)
##   El campo es |x − 2| ≤ MEDIO_CAMPO (1,7): las bandas están a 1,8 y el farol
##   de la esquina cuelga a 1,84. Con el corte en 1,85 contaba como campo.
##   La energía original se guarda en la ficha ("energia_propia") y la cuenta se
##   hace siempre desde ella, así que repartir dos veces no rebaja dos veces.
##   Antes todas pesaban lo mismo: veinte llamas iguales y la piedra, el latón y
##   la madera del mismo naranja, sin dónde mirar.
##   LA SOMBRA DE FUEGO: una sola, solo para un fuego DEL CAMPO y solo en ALTA.
##   Antes se la daba a la luz que más pesaba aunque estuviera fuera del campo:
##   una de la sala se la quitaba a los braseros y pintaba discos negros.

const Nucleo := preload("res://cripta3d/mundo_cripta.gd")
const SH_CIELO: Shader = preload("res://cripta3d/mundo/entorno_cielo.gdshader")
const SH_RAYO: Shader = preload("res://cripta3d/mundo/entorno_rayo.gdshader")
const SH_POLVO: Shader = preload("res://cripta3d/mundo/entorno_polvo.gdshader")
const SH_PAVESAS: Shader = preload("res://cripta3d/mundo/entorno_pavesas.gdshader")
const SH_BRUMA: Shader = preload("res://cripta3d/mundo/entorno_bruma.gdshader")
const SH_OCULO: Shader = preload("res://cripta3d/mundo/entorno_oculo.gdshader")
const SH_HALO: Shader = preload("res://cripta3d/mundo/entorno_halo.gdshader")
const SH_POST := "res://cripta3d/materiales/post.gdshader"
const TEX_MANCHAS: Texture2D = preload("res://cripta3d/texturas/ruido_manchas.png")

# ------------------------------------------------------------------- la escena
## Estos números son los mismos que usa «arquitectura» para abrir el óculo: si
## se mueve uno, se mueven los dos.
const OCULO := Vector3(0.95, 1.55, 5.94)
const R_OCULO := 0.28
const DIANA_LUNA := Vector3(2.00, 0.0, 9.00)
## Hacia dónde VA la luz de la luna (sin normalizar: del óculo a la diana).
const DIR_LUNA := Vector3(1.05, -1.55, 3.06)

# -------------------------------------------------------------------- la luna
const COLOR_LUNA := Color(0.58, 0.70, 1.0)
## El foco va RETRASADO detrás del óculo, sobre el eje del rayo: así su cono
## pasa por el hueco y el charco cae donde cae el rayo que se ve.
const LUNA_DETRAS := 1.0
## A dónde apunta el eje del foco. Algo más cerca del ábside que la diana del
## rayo: el cono cae rasante (25°) y se alarga hacia el jugador, así que con el
## eje en la diana el charco se iba hasta las palas. Con este, de z≈7,5 a z≈11.
## Estaba en z = 9,2 y, visto bajo (RASANTE, el asiento), la punta de la elipse
## llegaba a la pala izquierda: 0,35 más hacia el ábside y acaba antes.
const MIRA_LUNA := Vector3(1.85, 0.0, 8.85)
## Medido en la RASANTE: con 2,6 el campo (68) pasaba a la zona de palas (60), y
## la decisión es que las palas nunca estén por debajo del resto del campo.
## Con el canto más blando (`spot_angle_attenuation` 0,32) el cono reparte menos
## fuera del eje y el campo de la RASANTE bajó de 72 a 61: 2,15 lo devuelve a la
## altura de las palas sin pasarlas.
const ENERGIA_LUNA := 2.15
const ANGULO_LUNA := 12.0
const COLOR_RAYO := Color(0.62, 0.74, 1.0)
const FUERZA_RAYO := 1.4

# -------------------------------------------------------------------- el fuego
## Menos saturado que el de antes (1,0 ; 0,54 ; 0,24): con aquel, la piedra, el
## latón, la madera y el hueso salían del mismo naranja y no se distinguían. La
## llama sigue naranja (es su malla); la LUZ es más blanca, y la piedra se queda
## gris parda cerca del fuego en vez de pasar a latón.
const COLOR_FUEGO := Color(1.0, 0.66, 0.40)
## La jerarquía (ver la cabecera).
const MULT_ABSIDE := 0.5
## Los fuegos de la ALBARDILLA (los braseros de las esquinas, con su luz dentro
## del farol de la columna). Se creía que iban a la mitad y que había que
## bajarlos a un tercio; en realidad iban ENTEROS (ver `_peso_zona`), y en la
## RASANTE pesaban lo mismo que los tres braseros del campo. *Probado y quitado:*
## un tercio, y también la mitad a secas: se apagaban los osarios y los
## capiteles de calaveras, que solo los alumbra esta luz (en la gira, los
## rincones de la sala se quedaban sin osario). Lo que compite con los braseros
## del campo es el corro caliente PEGADO a la llama, no la luz que llega lejos;
## así que se baja la energía y, además, la caída con la distancia
## (`ATENUACION_ALBARDILLA`, 1/d^0,5 en vez de 1/d): cerca de la llama queda
## en torno a un tercio de lo que era y a la distancia de los osarios, un 60 %.
const MULT_ALBARDILLA := 0.55
const ATENUACION_ALBARDILLA := 0.5
const MULT_SALA := 0.3
## Media anchura de lo que es CAMPO, desde el eje x = 2. Las bandas van de 0,2 a
## 3,8 (1,8): lo que queda más afuera es albardilla.
const MEDIO_CAMPO := 1.7
## No más: los braseros de pie están a unas 2 unidades del mueble, y con un
## alcance mayor entrarían en las mallas del campo y le quitarían sitio a las
## luces que sí son suyas (Compatibility: 8 por malla).
const ALCANCE_SALA := 3.0

# ------------------------------------------------------------------ el aire
## Azul noche, oscuro. Era marrón rojizo (0,16 ; 0,10 ; 0,064) y la niebla
## lejana, el fondo y las sombras de la sala salían granates: una luna azul
## sobre un cielo granate no casa, y los oscuros se leían como barro.
## *Probado y quitado:* (0,030 ; 0,040 ; 0,068). El suelo de la nave está casi
## un metro dentro de la niebla de altura, así que la nave ENTERA toma este
## color: tan oscuro, la sala salía negra (el 57–81 % de la imagen por debajo del
## 3 %) y la bruma no se veía. Es noche, no negro: un azul que se lea.
const COLOR_NIEBLA := Color(0.060, 0.078, 0.125)
const DENSIDAD_NIEBLA := 0.020

var _mundo: Nucleo
var _tono := "agx"
var _calidad := 0
var _rayos: Array[ShaderMaterial] = []
var _polvos: Array[ShaderMaterial] = []
var _pavesas: ShaderMaterial = null
## Las sábanas de bruma con su nivel: se ven si `nivel >= calidad`.
var _brumas: Array[MeshInstance3D] = []
var _niveles_bruma: Array[int] = []
var _fuegos_vistos := -1
## El cielo detrás de la reja y el halo de la boca. Se montan en el primer
## `actualizar`: necesitan el `oculo` de «arquitectura», que se monta después.
var _cielo_oculo: ShaderMaterial = null
var _halo_oculo: ShaderMaterial = null
var _oculo_hecho := false
var _agitacion := 0.0
var _avivado := 0.0

func montar(mundo: Node3D) -> void:
	_mundo = mundo as Nucleo
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tono="):
			_tono = arg.trim_prefix("--tono=").to_lower()
	_montar_ambiente()
	_montar_luna()
	_montar_rayos()
	_montar_pavesas()
	_montar_bruma()
	_montar_fuegos()
	_montar_boveda()
	if _mundo.mesa != null and _mundo.mesa.has_signal("descarga_empezada"):
		_mundo.mesa.descarga_empezada.connect(_al_tocar_campana)

func actualizar(delta: float) -> void:
	_repartir_fuego()
	_agitacion = maxf(_agitacion - delta * 0.35, 0.0)
	_avivado = maxf(_avivado - delta * 0.5, 0.0)
	# La luna respira con nubes que no se ven: muy poco y muy despacio, para que
	# el haz esté vivo sin que nadie lo vea encenderse y apagarse.
	var t := _mundo.tiempo
	var nubes := 0.86 + 0.08 * sin(t * 0.21) + 0.06 * sin(t * 0.57 + 1.7)
	if not _oculo_hecho:
		_oculo_hecho = true
		_montar_oculo()
	for m in _rayos:
		m.set_shader_parameter("vida", nubes)
	# El cielo del óculo y su halo respiran con el rayo: son la misma luna.
	for m: ShaderMaterial in [_cielo_oculo, _halo_oculo]:
		if m != null:
			m.set_shader_parameter("vida", nubes)
	for m in _polvos:
		m.set_shader_parameter("agitacion", _agitacion)
	if _pavesas != null:
		_pavesas.set_shader_parameter("avivar", maxf(_avivado, _mundo.latido * 0.6))

func _al_tocar_campana(_punto: Vector2, _segundos: float) -> void:
	_agitacion = 1.0
	_avivado = 1.0

## LA CALIDAD (ver la cabecera). La llama el núcleo al arrancar y cada vez que
## cambia, DESPUÉS de que la escena toque el brillo y el fondo.
func calidad(n: int) -> void:
	_calidad = clampi(n, 0, 2)
	# La luna no lleva sombra en ninguna: así es igual en las tres.
	if _mundo.luz_luna != null:
		_mundo.luz_luna.shadow_enabled = false
	# La sombra de fuego se reparte otra vez con la calidad nueva.
	_fuegos_vistos = -1
	_repartir_fuego()
	for i in _brumas.size():
		if is_instance_valid(_brumas[i]):
			_brumas[i].visible = _niveles_bruma[i] >= _calidad
	var post := _material_post()
	if post != null:
		post.set_shader_parameter("maqueta", 0.0 if _calidad >= 2 else 1.0)

## El posprocesado lo pone la escena en su `pantalla` (no es de este mundo):
## se busca por ahí y, si no está o es otro sombreador, no se toca nada.
func _material_post() -> ShaderMaterial:
	var vp := _mundo.get_viewport()
	if vp == null or vp.get_parent() == null:
		return null
	var pantalla: Variant = vp.get_parent().get("pantalla")
	if not (pantalla is CanvasItem):
		return null
	var m := (pantalla as CanvasItem).material as ShaderMaterial
	if m == null or m.shader == null or m.shader.resource_path != SH_POST:
		return null
	return m

# ------------------------------------------------------------------- el ambiente

func _montar_ambiente() -> void:
	var entorno := Environment.new()
	var mat_cielo := ShaderMaterial.new()
	mat_cielo.shader = SH_CIELO
	mat_cielo.set_shader_parameter("hacia_luna", -DIR_LUNA.normalized())
	var cielo := Sky.new()
	cielo.sky_material = mat_cielo
	# El cielo no cambia: se hornea una vez y pequeño. El metal lo refleja
	# borroso de todas formas.
	cielo.radiance_size = Sky.RADIANCE_SIZE_128
	cielo.process_mode = Sky.PROCESS_MODE_QUALITY
	entorno.sky = cielo
	entorno.background_mode = Environment.BG_SKY
	# El color de la mitad de abajo del cielo, azul noche: es el que queda si la
	# calidad pasa el fondo a color liso (punto 3 de la cabecera).
	entorno.background_color = Color(0.020, 0.027, 0.046)
	entorno.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	# Ambiente frío y MUY bajo: la noche que hay fuera del charco de luna y lejos
	# del fuego. Sin él, la sombra sería un agujero negro; con más, lo baña todo.
	# Sube un poco respecto a cuando la luna era direccional (0,20), porque aquella
	# alumbraba la sala entera y este foco solo el charco.
	entorno.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	entorno.ambient_light_color = Color(0.30, 0.37, 0.56)
	# Medido: con 0,24 la sala salía negra (el 52–81 % de la imagen por debajo
	# del 3 %); con esto se leen las siluetas de pilares, barriles y braseros.
	entorno.ambient_light_energy = 0.50

	# LA NIEBLA. De profundidad, poca —a la distancia de la mesa se come un
	# 15 %—, y de ALTURA por debajo del tablero: el suelo de la nave se hunde en
	# ella y la mesa se queda flotando en una tarima de bruma. Fría y oscura: el
	# calor de abajo lo ponen las sábanas de bruma, que sí reciben el fuego.
	entorno.fog_enabled = true
	entorno.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	entorno.fog_light_color = COLOR_NIEBLA
	entorno.fog_light_energy = 1.0
	# Sin dispersión de sol: solo la tiene una direccional, y ya no hay.
	entorno.fog_sun_scatter = 0.0
	entorno.fog_density = DENSIDAD_NIEBLA
	entorno.fog_sky_affect = 0.45
	entorno.fog_height = -0.05
	# Menos que antes (1,1): la nave está ahora a −0,9 y no a −0,42, el doble de
	# hondo dentro de la niebla, y con 1,1 se tragaba los barriles y los braseros.
	entorno.fog_height_density = 0.6

	# El del reflejo se saca AQUÍ, antes de la curva de tono y del brillo.
	_mundo.entorno_reflejo = entorno.duplicate() as Environment

	# LA CURVA DE TONO. AgX trata mejor el fuego: una llama que se pasa de luz
	# va hacia el blanco amarillento, como en una foto, en vez de quedarse en un
	# naranja saturado de plástico (ACES); y sus sombras no se van al negro tan
	# deprisa. Con `--tono=aces` se compara.
	if _tono == "aces":
		entorno.tonemap_mode = Environment.TONE_MAPPER_ACES
		entorno.tonemap_white = 6.0
		entorno.tonemap_exposure = 0.95
	else:
		entorno.tonemap_mode = Environment.TONE_MAPPER_AGX
		entorno.tonemap_white = 8.0
		entorno.tonemap_exposure = 1.5

	# EL BRILLO, con el umbral alto: solo lo pasan las llamas, las ascuas, las
	# pavesas y los ojos. El metal mojado con un reflejo de fuego roza el umbral
	# y se queda en un destello, que es lo que tiene que hacer.
	entorno.glow_enabled = true
	entorno.glow_normalized = false
	entorno.glow_intensity = 0.75
	entorno.glow_strength = 1.0
	entorno.glow_bloom = 0.0
	entorno.glow_hdr_threshold = 1.35
	entorno.glow_hdr_scale = 2.0
	entorno.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	var niveles: Array[float] = [0.0, 0.35, 1.0, 0.7, 0.55, 0.0, 0.0]
	for i in niveles.size():
		entorno.set_glow_level(i, niveles[i])

	entorno.adjustment_enabled = true
	entorno.adjustment_brightness = 1.0
	entorno.adjustment_contrast = 1.03
	entorno.adjustment_saturation = 0.92

	# FORWARD+ (solo se prueba; la web es Compatibility): ahí hay oclusión de
	# pantalla y suma sin cambiar el carácter. En Compatibility no existe y
	# encenderla no haría nada, pero así queda claro que es a propósito.
	if RenderingServer.get_current_rendering_method() != "gl_compatibility":
		entorno.ssao_enabled = true
		entorno.ssao_radius = 0.45
		entorno.ssao_intensity = 1.6
		entorno.ssao_power = 1.3
		entorno.ssao_light_affect = 0.15
		# Ahí el brillo trabaja con el alto rango de verdad y una chispa de efectos
		# se abría en una bola blanca del tamaño de un brasero: umbral más alto.
		entorno.glow_hdr_threshold = 2.0
		entorno.glow_intensity = 0.55

	_mundo.entorno = entorno
	var we := WorldEnvironment.new()
	we.environment = entorno
	_mundo.add_child(we)

# -------------------------------------------------------------------- la luna

## LA LUNA ES UN FOCO QUE ENTRA POR EL ÓCULO, Y NO HACE SOMBRA (ver la cabecera).
## Detrás del muro, sobre el eje del rayo: alumbra lo que el óculo deja ver —el
## charco del campo, la campana y los raíles que lo cruzan— y nada más. Las
## caras de dentro del ábside lo tienen a la espalda y se quedan con el fuego.
func _montar_luna() -> void:
	var eje := DIR_LUNA.normalized()
	var luna := SpotLight3D.new()
	luna.light_color = COLOR_LUNA
	luna.light_energy = ENERGIA_LUNA
	# El suelo mojado devuelve el charco como un brillo frío: que se note, sin
	# plantar una segunda luna en las losas. Estaba a 0,7 y el brillo del suelo
	# repetía el canto del cono: visto bajo, la elipse dura de un foco de teatro.
	luna.light_specular = 0.35
	luna.spot_range = 12.0
	# Caída con la distancia blanda: el cono llega rasante y la punta lejana del
	# charco está al doble de lejos que la cercana. Con la caída física (1) el
	# charco era un foco en la punta del ábside y nada abajo.
	luna.spot_attenuation = 0.45
	luna.spot_angle = ANGULO_LUNA
	# Borde blando (por debajo de 1 la caída empieza antes): un canto duro es un
	# foco de teatro, no luz de luna a través de una piedra. La caída es
	# 1 − rim^a, y su pendiente en el canto vale `a`: con 0,55 el arco seguía
	# limpio desde el asiento; con 0,32 se deshace.
	luna.spot_angle_attenuation = 0.32
	luna.shadow_enabled = false
	_mundo.add_child(luna)
	luna.look_at_from_position(OCULO - eje * LUNA_DETRAS, MIRA_LUNA, Vector3.UP)
	_mundo.luz_luna = luna

# ------------------------------------------------------------------- los rayos

## EL DEL ÓCULO: del centro del óculo al centro de la mesa. Un poco más estrecho
## que el hueco en la boca (la reja come borde) y algo más ancho abajo: la luna
## no es un punto y el haz se abre.
func _montar_rayos() -> void:
	var eje := DIR_LUNA.normalized()
	var largo := (DIANA_LUNA - OCULO).length()
	_rayo(OCULO, eje, largo, R_OCULO * 0.94, R_OCULO * 1.30, FUERZA_RAYO, 1.0, 110)

func _rayo(origen: Vector3, eje: Vector3, largo: float, r0: float, r1: float,
		fuerza: float, reja: float, motas: int) -> void:
	var lado_u := eje.cross(Vector3.UP).normalized()
	var lado_v := lado_u.cross(eje).normalized()
	var m := ShaderMaterial.new()
	m.shader = SH_RAYO
	m.set_shader_parameter("ruido", TEX_MANCHAS)
	m.set_shader_parameter("color", COLOR_RAYO)
	m.set_shader_parameter("fuerza", fuerza)
	m.set_shader_parameter("origen", origen)
	m.set_shader_parameter("eje", eje)
	m.set_shader_parameter("lado_u", lado_u)
	m.set_shader_parameter("lado_v", lado_v)
	m.set_shader_parameter("largo", largo)
	m.set_shader_parameter("radio_0", r0)
	m.set_shader_parameter("radio_1", r1)
	m.set_shader_parameter("reja", reja)
	# Los de la bóveda, parejos: con el eje denso de el del óculo se veían como
	# una barra de luz maciza, y lejos y finos tienen que ser una neblina.
	m.set_shader_parameter("nucleo", 2.0 if reja > 0.9 else 1.0)
	var mi := MeshInstance3D.new()
	mi.mesh = _cono(origen, eje, lado_u, lado_v, largo, r0, r1)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.layers = Nucleo.CAPA_SIN_REFLEJO
	_mundo.add_child(mi)
	_rayos.append(m)

	# Su polvo: cada mota guarda dónde está DENTRO del haz (u, v, t); el
	# sombreador la lleva al mundo y la hace derivar.
	var pm := ShaderMaterial.new()
	pm.shader = SH_POLVO
	pm.set_shader_parameter("color", COLOR_RAYO.lerp(Color(1.0, 1.0, 1.0), 0.35))
	pm.set_shader_parameter("origen", origen)
	pm.set_shader_parameter("eje", eje)
	pm.set_shader_parameter("lado_u", lado_u)
	pm.set_shader_parameter("lado_v", lado_v)
	pm.set_shader_parameter("largo", largo)
	pm.set_shader_parameter("radio_0", r0)
	pm.set_shader_parameter("radio_1", r1)
	pm.set_shader_parameter("fuerza", 1.6 * fuerza / FUERZA_RAYO)
	var azar := RandomNumberGenerator.new()
	azar.seed = 7919 + motas
	var mm := _multimalla(motas)
	for i in motas:
		var ang := azar.randf() * TAU
		var r := sqrt(azar.randf())
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY,
			Vector3(cos(ang) * r, sin(ang) * r, azar.randf())))
		mm.set_instance_custom_data(i, Color(azar.randf(), azar.randf(), azar.randf(), azar.randf()))
	_colgar_multimalla(mm, pm)
	_polvos.append(pm)

## El cono por el que se mira el haz, en coordenadas de mundo. Algo más ancho que
## el haz (el sombreador pone a cero lo que sobra) y más largo por los dos lados:
## por arriba se mete en el muro y por abajo atraviesa el suelo, y la
## profundidad de la escena lo corta en los dos sitios sin costura.
##
## Godot toma como cara de delante la que se ve en el sentido de las agujas del
## reloj; aquí cada triángulo se ordena mirando su normal contra la de fuera, así
## que no depende de hacia dónde se recorra el aro.
func _cono(origen: Vector3, eje: Vector3, lado_u: Vector3, lado_v: Vector3,
		largo: float, r0: float, r1: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lados := 24
	var tramos := 6
	var t0 := -0.08
	var t1 := 1.12
	var puntos: Array[PackedVector3Array] = []
	for a in tramos + 1:
		var tn := lerpf(t0, t1, float(a) / float(tramos))
		var r := lerpf(r0, r1, clampf(tn, 0.0, 1.0)) * 1.10
		var aro := PackedVector3Array()
		for k in lados:
			var ang := TAU * float(k) / float(lados)
			aro.append(origen + eje * (tn * largo) + (lado_u * cos(ang) + lado_v * sin(ang)) * r)
		puntos.append(aro)
	for a in tramos:
		for k in lados:
			var k2 := (k + 1) % lados
			_triangulo(st, puntos[a][k], puntos[a][k2], puntos[a + 1][k], origen, eje)
			_triangulo(st, puntos[a][k2], puntos[a + 1][k2], puntos[a + 1][k], origen, eje)
	return st.commit()

func _triangulo(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		origen: Vector3, eje: Vector3) -> void:
	var centro := (a + b + c) / 3.0
	var d := centro - origen
	var fuera := (d - eje * d.dot(eje)).normalized()
	# Con la cara de delante en sentido horario, su normal es (c − a) × (b − a).
	if (c - a).cross(b - a).dot(fuera) < 0.0:
		var x := b
		b = c
		c = x
	for p: Vector3 in [a, b, c]:
		var q := p - origen
		st.set_normal((q - eje * q.dot(eje)).normalized())
		st.add_vertex(p)

func _multimalla(n: int) -> MultiMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = n
	return mm

func _colgar_multimalla(mm: MultiMesh, m: ShaderMaterial) -> void:
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = m
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.layers = Nucleo.CAPA_SIN_REFLEJO
	# Las transformaciones no son posiciones de verdad (las lleva al mundo el
	# sombreador): sin una caja a mano, Godot las recortaría por estar «fuera».
	mmi.custom_aabb = AABB(Vector3(-8.0, -2.0, -2.0), Vector3(20.0, 10.0, 20.0))
	_mundo.add_child(mmi)

# ------------------------------------------------------------------- el óculo

## EL ÓCULO BRILLA (decisión 2 del remate). Es el motivo de toda la luz fría y,
## desde la mesa, se veía como un disco oscuro: el muro tiene 0,42 de grueso,
## la cámara de juego mira el hueco a unos 40° de su eje y lo que asomaba era el
## cielo casi negro o el propio taladro en sombra. Dos mallas sin luz:
##   · EL CIELO (`entorno_oculo.gdshader`): un disco azul luna en el plano del
##     muro, a FONDO_CIELO detrás de la cara, justo detrás de la reja (que está a
##     0,11 y se recorta negra encima). Tan poco hondo que se ve aun mirando de
##     lado; lo que sobra queda dentro de la piedra.
##   · EL HALO (`entorno_halo.gdshader`): aire que brilla en la boca, de cara a
##     la cámara, que empalma el cielo con el arranque del rayo.
## Ni sombra ni reflejo, y lo mismo en las tres calidades.
const FONDO_CIELO := 0.15
const FUERZA_CIELO := 0.52
const FUERZA_HALO := 0.32
const RADIO_HALO := 0.62

func _montar_oculo() -> void:
	var luz := DIR_LUNA.normalized()
	# El óculo que publica «arquitectura»: la cara del muro, con Z hacia dentro.
	var base := Transform3D()
	var arq: Object = _mundo.modulo("arquitectura")
	if arq != null:
		var v: Variant = arq.get("oculo")
		if v is Transform3D:
			base = v
	if base.is_equal_approx(Transform3D()):
		# Sin arquitectura: un muro de cara a la luz, en horizontal, por OCULO.
		var w := Vector3(luz.x, 0.0, luz.z).normalized()
		base = Transform3D(Basis(Vector3.UP.cross(w), Vector3.UP, w), OCULO)
	var giro := base.basis.orthonormalized()
	var n := giro.z
	if n.dot(luz) < 0.0:
		n = -n
	# Hacia atrás A LO LARGO DE LA LUZ, que es como va taladrado el hueco.
	var cielo_en := base.origin - luz * (FONDO_CIELO / maxf(luz.dot(n), 0.2))

	_cielo_oculo = ShaderMaterial.new()
	_cielo_oculo.shader = SH_OCULO
	_cielo_oculo.set_shader_parameter("ruido", TEX_MANCHAS)
	_cielo_oculo.set_shader_parameter("color", COLOR_LUNA)
	_cielo_oculo.set_shader_parameter("fuerza", FUERZA_CIELO)
	var disco := QuadMesh.new()
	disco.size = Vector2.ONE * (R_OCULO + 0.12) * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = disco
	mi.material_override = _cielo_oculo
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.layers = Nucleo.CAPA_SIN_REFLEJO
	_mundo.add_child(mi)
	mi.global_transform = Transform3D(giro, cielo_en)

	_halo_oculo = ShaderMaterial.new()
	_halo_oculo.shader = SH_HALO
	_halo_oculo.set_shader_parameter("color", COLOR_RAYO)
	_halo_oculo.set_shader_parameter("fuerza", FUERZA_HALO)
	var tarjeta := QuadMesh.new()
	tarjeta.size = Vector2.ONE * RADIO_HALO * 2.0
	var mh := MeshInstance3D.new()
	mh.mesh = tarjeta
	mh.material_override = _halo_oculo
	mh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mh.layers = Nucleo.CAPA_SIN_REFLEJO
	# Se gira en el sombreador: aquí solo cuenta dónde está. Sin caja de sobra
	# Godot la recortaría al girarla fuera de su plano.
	mh.extra_cull_margin = RADIO_HALO
	_mundo.add_child(mh)
	mh.global_position = base.origin + n * 0.06

# ------------------------------------------------------------------ la bóveda

## LA BÓVEDA NO SE ILUMINA: SE INSINÚA (decisión 3). El ambiente frío llega
## arriba, pero el cuarto de esfera del ábside quedaba a cero (la franja alta del
## fotograma, a 1 de 255 desde el pie de la mesa). Un lavado frío tenue junto al
## óculo: es la luna que rebota en el derrame del hueco y sube por la bóveda. Una
## omni débil, SIN sombra y sin brillo especular, con el alcance justo para no
## bajar a la campana ni al campo (así no le quita sitio a ningún fuego en las 8
## luces por malla). El rebote cálido de los nervios lo pone «arquitectura» en su
## color de vértice.
const LAVADO_BOVEDA := 0.45
const ALCANCE_LAVADO := 1.5

func _montar_boveda() -> void:
	var lavado := OmniLight3D.new()
	lavado.light_color = COLOR_LUNA
	lavado.light_energy = LAVADO_BOVEDA
	lavado.light_specular = 0.0
	lavado.omni_range = ALCANCE_LAVADO
	lavado.omni_attenuation = 1.0
	lavado.shadow_enabled = false
	lavado.position = Vector3(1.3, 4.05, 6.3)
	_mundo.add_child(lavado)

# ----------------------------------------------------------------- las pavesas

## Seis por brasero, saliendo de su ascua. Si la mesa no tiene braseros, nada.
func _montar_pavesas() -> void:
	if _mundo.mesa == null or _mundo.mesa.bumpers.is_empty():
		return
	var por_brasero := 6
	var n := _mundo.mesa.bumpers.size() * por_brasero
	var mm := _multimalla(n)
	var azar := RandomNumberGenerator.new()
	azar.seed = 4242
	for i in n:
		var centro: Vector2 = _mundo.mesa.bumpers[floori(float(i) / float(por_brasero))]
		var p := _mundo.a3(centro, 0.20) + Vector3(azar.randf_range(-0.07, 0.07), 0.0,
			azar.randf_range(-0.07, 0.07))
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
		mm.set_instance_custom_data(i, Color(azar.randf(), azar.randf(), azar.randf(), azar.randf()))
	_pavesas = ShaderMaterial.new()
	_pavesas.shader = SH_PAVESAS
	_colgar_multimalla(mm, _pavesas)

# ------------------------------------------------------------------- la bruma

## Sábanas de niebla tendidas sobre el suelo de la nave, a los dos lados de la
## mesa y detrás del ábside, a dos alturas y cada una con su viento. Por encima
## del tablero NO hay ninguna: la mesa se juega limpia.
##
## Las alturas se miden desde `Nucleo.Y_SALA`. *Avería que no daba error:* aquí
## estaba copiado el suelo a −0,42 y la nave está a −0,9; la bruma flotaba medio
## metro en el aire y los barriles y los pilares la cruzaban por la cintura.
##
## El último número de cada sábana es su NIVEL de calidad: 2 se ve en las tres,
## 1 en ALTA y MEDIA, 0 solo en ALTA.
func _montar_bruma() -> void:
	var y := Nucleo.Y_SALA
	var lado := 4.4
	var n := 0
	for capa in 2:
		# A 0,10 y 0,30 del suelo de verdad no se veía: el fundido con lo de detrás
		# se la comía entera (se queda en un 6 % de opacidad).
		var h := y + (0.18 if capa == 0 else 0.44)
		for x0: float in [-0.25 - lado, 4.25]:
			for z0: float in [3.2, 7.5, 11.8]:
				_sabana(Vector3(x0 + lado * 0.5, h, z0 + lado * 0.5), Vector2(lado, lado), n,
					2 if capa == 0 else 0)
				n += 1
	# Una tercera capa, más alta, solo al fondo de los lados: la que funde el pie
	# de los muros del fondo con el suelo.
	for x0: float in [-0.25 - lado, 4.25]:
		_sabana(Vector3(x0 + lado * 0.5, y + 0.62, 6.2), Vector2(lado, 3.4), n, 0)
		n += 1
	# Detrás del ábside, más alta: es la que funde el muro con el fondo.
	_sabana(Vector3(2.0, y + 0.75, 3.4), Vector2(8.0, 3.2), n, 1)
	_sabana(Vector3(2.0, y + 1.35, 2.6), Vector2(9.0, 3.0), n + 1, 0)

func _sabana(centro: Vector3, tam: Vector2, n: int, nivel: int) -> void:
	var m := ShaderMaterial.new()
	m.shader = SH_BRUMA
	m.set_shader_parameter("ruido", TEX_MANCHAS)
	m.set_shader_parameter("semilla", float(n) * 0.37)
	var giro := float(n) * 2.39
	m.set_shader_parameter("viento", Vector2(cos(giro), sin(giro)) * (0.008 + 0.004 * float(n % 3)))
	m.set_shader_parameter("densidad", 0.45 if centro.y < Nucleo.Y_SALA + 0.3 else 0.26)
	# El corte con lo que atraviesa ya lo evita el fundido por ALTURA del
	# sombreador; este, el de pantalla, solo quita el filo y se queda corto.
	m.set_shader_parameter("fundido", 0.15)
	# El grosor con que vela lo que tiene debajo (ver el sombreador): nunca más que
	# lo que la separa del suelo, o la capa baja dejaría el suelo casi limpio.
	m.set_shader_parameter("grosor", clampf((centro.y - Nucleo.Y_SALA) * 0.85, 0.07, 0.25))
	var plano := PlaneMesh.new()
	plano.size = tam
	var mi := MeshInstance3D.new()
	mi.mesh = plano
	mi.material_override = m
	mi.position = centro
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.layers = Nucleo.CAPA_SIN_REFLEJO
	_mundo.add_child(mi)
	_brumas.append(mi)
	_niveles_bruma.append(nivel)

# -------------------------------------------------------------------- el fuego

## LA LUZ DE ESTE MÓDULO: el RELLENO de la zona de palas, que es lo que hace
## que se juegue. Viene de los braseros del lado del jugador, fuera de cuadro
## (punto 6 de la cabecera), con poco brillo especular para que no plante un sol
## en el suelo mojado.
func _montar_fuegos() -> void:
	# El relleno es un FOCO y no una omni: desde detrás del jugador, una omni
	# lo bastante fuerte para las palas quemaba el marco de delante, que tenía
	# pegado. Un foco lejano reparte parejo sobre la zona de palas y deja el marco
	# en el borde del cono. No parpadea: es la suma de varios fuegos lejanos.
	#
	# LA ZONA DE PALAS ES LO MÁS LEGIBLE DE LA MESA (decisión 5). Medida antes:
	# 19–27 de luminancia media (0–255) contra 63–71 del ábside, la franja más
	# oscura del campo justo donde se decide la partida. Por eso este foco es
	# ahora la luz de fuego más fuerte de la escena y apunta a las palas, no a la
	# mitad del campo; y su cono, más cerrado, se queda en la zona de palas sin
	# subir a calentar el resto (la piedra del campo es de la luna y los braseros).
	var relleno := SpotLight3D.new()
	relleno.light_color = COLOR_FUEGO.lerp(Color(1.0, 0.88, 0.74), 0.30)
	relleno.light_energy = 22.0
	relleno.light_specular = 0.3
	relleno.spot_range = 9.0
	# Con la caída muy suave: con un canto duro se veía como un arco de luz en el
	# marco de la izquierda, y eso delata el foco de teatro. Y apuntando a las
	# palas por arriba: con el eje más abajo, lo más claro de la mesa era el pie,
	# por debajo de las palas, donde la bola ya está perdida.
	# Lo bastante abierto para llegar al carril del lanzador (x≈3,7, z≈12,6):
	# con 27° se quedaba a oscuras, porque antes lo alumbraba la luna direccional.
	relleno.spot_angle = 33.0
	relleno.spot_angle_attenuation = 1.8
	relleno.shadow_enabled = false
	_mundo.add_child(relleno)
	relleno.look_at_from_position(Vector3(2.0, 3.2, 14.6), Vector3(2.0, 0.0, 11.55), Vector3.UP)

## Cuánto pesa un fuego según dónde está (la jerarquía de la cabecera).
static func _peso_zona(p: Vector3) -> float:
	var fuera := absf(p.x - 2.0)
	if fuera > 2.6 or p.y < Nucleo.Y_SALA + 0.6:
		return MULT_SALA
	# Por fuera de las bandas y encima del mueble: la albardilla (y el farol de
	# la columna, que es la luz de su brasero). *Avería que no daba error:* el
	# corte estaba en 1,85 y el farol cuelga en x = 0,16 y 3,84 (1,84 del eje):
	# las dos luces de las esquinas contaban como DEL CAMPO, a energía entera, y
	# hasta podían quitarle la sombra a los braseros. Las bandas están a 1,8.
	if fuera > MEDIO_CAMPO:
		return MULT_ALBARDILLA
	if p.z < 7.0:
		return MULT_ABSIDE
	return 1.0

## Un fuego es DEL CAMPO si está encima del tablero de juego.
static func _del_campo(p: Vector3) -> bool:
	return absf(p.x - 2.0) <= MEDIO_CAMPO and p.z >= 7.0 and p.z <= 12.8 and p.y > -0.2

## LA JERARQUÍA DEL FUEGO (ver la cabecera). Se rehace solo cuando cambia el
## número de fuegos dados de alta o la calidad.
func _repartir_fuego() -> void:
	var fichas: Array[Dictionary] = _mundo.fuegos()
	if fichas.size() == _fuegos_vistos:
		return
	_fuegos_vistos = fichas.size()
	var mejor: OmniLight3D = null
	var mejor_peso := 0.0
	for ficha in fichas:
		var que: Variant = ficha.get("luz")
		if not is_instance_valid(que) or not (que is OmniLight3D):
			continue
		var luz: OmniLight3D = que
		if luz.light_color.is_equal_approx(Nucleo.COLOR_FUEGO):
			luz.light_color = COLOR_FUEGO
		if not ficha.has("energia_propia"):
			ficha["energia_propia"] = float(ficha.get("energia", 1.0))
		var propia: float = ficha["energia_propia"]
		var zona := _peso_zona(luz.global_position)
		ficha["energia"] = propia * zona		# Un fuego de la sala, a un cuarto pero con más alcance: con el suyo (2,3)
		# y un cuarto de la energía no llegaba ni al suelo de alrededor, y el
		# brasero ardía sobre negro. Así deja un corro tenue y ancho.
		if zona <= MULT_SALA and luz.omni_range < ALCANCE_SALA:
			luz.omni_range = ALCANCE_SALA
		# La albardilla: menos corro pegado a la llama, la misma luz a lo lejos.
		if is_equal_approx(zona, MULT_ALBARDILLA):
			luz.omni_attenuation = ATENUACION_ALBARDILLA
		luz.shadow_enabled = false
		# La sombra, para el fuego del campo que más alumbra cerca del centro.
		if _del_campo(luz.global_position):
			var d := Vector2(luz.global_position.x - 2.0, luz.global_position.z - 9.4).length()
			var peso := propia * luz.omni_range / (1.0 + d)
			if peso > mejor_peso:
				mejor_peso = peso
				mejor = luz
	if mejor != null and _calidad == 0:
		mejor.shadow_enabled = true
		mejor.shadow_bias = 0.04
		mejor.shadow_normal_bias = 1.5
		mejor.shadow_blur = 1.5
