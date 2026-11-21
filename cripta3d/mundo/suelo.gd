extends RefCounted

## CRIPTA 3D · MÓDULO «suelo» · LAS LOSAS.
##
## QUÉ MONTA
##   · El tablero: un plano a y = 0 que cubre la mesa entera, de x = 0 a 400 y de
##     y = 548 a 1300 (píxeles de mesa), partido en BALDAS × HILADAS trozos.
##   · Su material (`suelo_losa.gdshader`): losas grandes y desiguales de piedra
##     pulida por el uso (la misma piedra de la biblioteca), adoquín en el pie,
##     agua solo en las juntas y al pie de las paredes —nunca en la zona de palas
##     ni en el camino de la bola—, con latón embutido, hollín, surcos y una rosa
##     de teselas. Lo mojado REFLEJA la mesa de verdad, sumado a la losa.
##   · Dos mapas cenitales HORNEADOS al arrancar (`suelo_mapas.gdshader`), que el
##     material multiplica: la oclusión al pie de cada pieza, el latón, los
##     surcos, el hollín, el uso y el rebaje de las bocas de la catacumba. Se
##     dibujan UNA vez en dos SubViewport; a los pocos cuadros se copian a
##     texturas con mipmaps y los SubViewport se sueltan.
##
## QUÉ RELLENA EN EL NÚCLEO
##   mundo.mat_suelo   el `ShaderMaterial` del suelo. La escena le pone:
##                       "reflejo"         la textura de la cámara espejo
##                       "fuerza_reflejo"  1.0 con reflejo, 0.0 sin él (calidad BAJA)
##
## SEÑALES QUE ESCUCHA   ninguna.
## FUNCIONES PÚBLICAS    `calidad(n)` (la llama el núcleo): las lecturas del reflejo.
##
## LO QUE NO PUEDE DEJAR DE HACER QUIEN LO REESCRIBA (heredado de la versión 0)
##   1. Rellenar `mundo.mat_suelo` con un material que tenga esos DOS parámetros
##      con esos nombres. `fuerza_reflejo` es un interruptor (la escena solo
##      escribe 1 o 0): cuánto refleja la losa es cosa del sombreador.
##   2. El reflejo se lee en `vec2(SCREEN_UV.x, 1.0 - SCREEN_UV.y)`: la cámara
##      espejo es la de juego reflejada en el plano y = 0. Por eso el suelo va
##      EXACTAMENTE a y = 0 y es plano: una losa levantada dos centímetros
##      refleja desde donde no está. Todo el relieve de aquí (juntas, biseles,
##      surcos, el rebaje) es de la NORMAL, no de la malla.
##   3. El suelo se ve SOLO DESDE ARRIBA (un `PlaneMesh`, una cara). La cámara
##      espejo mira desde abajo: si el suelo tuviera cara de abajo, taparía todo
##      el reflejo.
##   4. No hace sombra (la recibe) y va PARTIDO: Compatibility da 8 luces por
##      malla, y la mesa tiene más fuegos que eso. El dibujo va en coordenadas
##      de mundo para que los trozos no tengan costura.
##   5. Nada del suelo puede quedar por debajo de y = 0 en la capa 1: la cámara
##      espejo lo vería por delante de todo. Lo que baje, a `CAPA_BAJO_SUELO`.
##
## POR QUÉ UN SOMBREADOR PROPIO Y NO LA «losa» DE LA BIBLIOTECA. La biblioteca
## sabe hacer piedra en cualquier cara; el suelo necesita cosas que solo tiene
## el suelo (el aparejo irregular, el agua que busca lo bajo, el latón y la rosa
## de los mapas, el reflejo en reguero). Para que case con el sillar de las
## paredes lee las MISMAS tres texturas de ruido de `cripta3d/texturas/` y los
## mismos tintes de la paleta del juego.

const Nucleo := preload("res://cripta3d/mundo_cripta.gd")
const LOSA: Shader = preload("res://cripta3d/mundo/suelo_losa.gdshader")
const MAPAS: Shader = preload("res://cripta3d/mundo/suelo_mapas.gdshader")
const TEX_GRANO: Texture2D = preload("res://cripta3d/texturas/ruido_grano.png")
const TEX_CELDAS: Texture2D = preload("res://cripta3d/texturas/ruido_celdas.png")
const TEX_MANCHAS: Texture2D = preload("res://cripta3d/texturas/ruido_manchas.png")

## De dónde a dónde va el tablero, en píxeles de mesa. Arriba sobra un poco
## sobre el arco (570) para que el suelo llegue debajo de la pared del fondo.
const Y_ARRIBA := 548.0
const Y_ABAJO := 1300.0
## 4 × 6 trozos de 1 × 1,25 unidades: cada uno coge los fuegos que tiene cerca.
const BALDAS := 4
const HILADAS := 6
## Píxeles de mapa por píxel de mesa. El A lleva el latón y tiene que ser fino
## (1.024 de ancho: cuatro píxeles por milímetro de bola); el B es todo sombra
## suave y le basta la mitad.
const RES_A := 2.56
const RES_B := 1.28

## EL EMBLEMA: el nodo central de la plaza de la caza (`caza_orbita.gd`,
## NODO_CENTRO). Va escrito y no leído porque la caza se monta DESPUÉS que los
## módulos. Radio de las teselas, en píxeles de mesa.
const EMBLEMA := Vector2(214.0, 1018.0)
const RADIO_EMBLEMA := 42.0

## A cuántos píxeles de su boca pone «railes» la placa de la flecha (su
## `DIST_FLECHA`). Las guías de latón van detrás de la placa, en la misma línea.
## Copiado y no leído: un módulo no carga otro, y si «railes» no compila el suelo
## tiene que seguir saliendo. Al día con la tabla del remate (railes acercó las
## placas del tobogán y del coro y alejó la de la catacumba): con las viejas, los
## cheurones quedaban despegados de su placa o se le metían debajo.
const DIST_PLACA := {"orbita": 66.0, "cometa": 34.0, "estacion": 36.0, "gusano": 44.0}
const MEDIO_LARGO_PLACA := 18.5

## Las bocas de la catacumba: la entrada y la salida del túnel (los extremos del
## recorrido «gusano»). La boca la monta «railes»; aquí va el rebaje.
const RADIO_REBAJE := 21.0

## EL PIE DE LA MESA, que la revisión encontró muerto: entre las palas y el
## desagüe había cuatro o cinco losas enormes sin nada, y es lo que más ve el
## jugador. Ahora, de `Y_ADOQUIN` hacia abajo el suelo es adoquinado (lo cambia
## el sombreador), un listón doble de latón tapa la costura con las losas, y un
## cerco de latón rodea el pozo del desagüe (el aro de hierro remachado es de
## «arquitectura»: está a `y_drenaje + DESAGUE_FONDO`, en el centro). Todo a ras:
## nada de esto estorba a la bola. Las puntas de las palas en reposo llegan a
## y ≈ 1230: el listón va por debajo.
const Y_ADOQUIN := 1246.0
const DESAGUE_FONDO := 12.0
const CERCO_DESAGUE: Array[Vector2] = [Vector2(47.0, 3.0), Vector2(53.0, 1.2)]

## Los surcos, en píxeles de mesa: por donde la bola rueda despacio y siempre
## igual. Las calles de retorno (entre el muro y la goma), la lanzadera, lo que
## sueltan el tobogán, la escalera y la catacumba camino de las palas.
static func _surcos() -> Array[PackedVector2Array]:
	return [
		PackedVector2Array([Vector2(53, 1100), Vector2(81, 1136), Vector2(108, 1171), Vector2(117, 1188)]),
		PackedVector2Array([Vector2(328, 1101), Vector2(309, 1136), Vector2(290, 1170), Vector2(283, 1188)]),
		PackedVector2Array([Vector2(369, 1252), Vector2(369, 1100), Vector2(369, 965)]),
		PackedVector2Array([Vector2(58, 1040), Vector2(55, 1070), Vector2(53, 1100)]),
		PackedVector2Array([Vector2(330, 1088), Vector2(328, 1101)]),
		PackedVector2Array([Vector2(127, 1056), Vector2(131, 1105), Vector2(140, 1158)]),
		# Lo que se escapa entre las dos puntas camino del desagüe: dos surcos que
		# se juntan en el pozo. Dan uso (y por eso seco) al pie de la mesa.
		PackedVector2Array([Vector2(176, 1238), Vector2(188, 1266), Vector2(196, 1298)]),
		PackedVector2Array([Vector2(224, 1238), Vector2(212, 1266), Vector2(204, 1298)]),
	]

## Por dónde más juega la bola, para el pulido: centro, radios y peso.
const ZONAS_USO: Array[Vector4] = [
	Vector4(200, 1170, 125, 55), Vector4(200, 1085, 95, 90), Vector4(214, 1010, 115, 70),
	Vector4(160, 765, 75, 60), Vector4(165, 832, 60, 26), Vector4(369, 1110, 10, 170),
	Vector4(260, 930, 50, 60),
]
const PESOS_USO: Array[float] = [1.0, 0.75, 0.6, 0.5, 0.4, 0.8, 0.45]

var _mundo: Nucleo
var _mat: ShaderMaterial
## Los dos SubViewport de los mapas mientras no se han copiado a textura.
var _horno_a: SubViewport
var _horno_b: SubViewport
var _cuadros := 0
var _horneado := false

func montar(mundo: Node3D) -> void:
	_mundo = mundo as Nucleo
	_mat = _material()
	_mundo.mat_suelo = _mat
	# Para mirar las máscaras: `-- --suelo-depura=N` (los modos están en la
	# cabecera de `suelo_losa.gdshader`).
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--suelo-depura="):
			_mat.set_shader_parameter("depura", int(arg.get_slice("=", 1)))
	_hornear()
	var ancho := Mesa.ANCHO * Nucleo.E / float(BALDAS)
	var largo := (Y_ABAJO - Y_ARRIBA) * Nucleo.E / float(HILADAS)
	var plano := PlaneMesh.new()
	plano.size = Vector2(ancho, largo)
	for i in BALDAS:
		for j in HILADAS:
			var mi := MeshInstance3D.new()
			mi.mesh = plano
			mi.material_override = _mat
			mi.position = Vector3(ancho * (float(i) + 0.5), 0.0,
				Y_ARRIBA * Nucleo.E + largo * (float(j) + 0.5))
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_mundo.add_child(mi)

## Los mapas se dibujan en el primer cuadro; en el tercero ya están y se copian
## a texturas con mipmaps (de lejos el latón no chispea) y los SubViewport se
## sueltan. Si la copia no sale, el material sigue leyendo los SubViewport, que
## con UPDATE_ONCE guardan su imagen.
func actualizar(_delta: float) -> void:
	if _horneado:
		return
	_cuadros += 1
	if _cuadros < 3:
		return
	var a := _a_textura(_horno_a)
	var b := _a_textura(_horno_b)
	if a != null and b != null:
		_mat.set_shader_parameter("mapa_a", a)
		_mat.set_shader_parameter("mapa_b", b)
		_horno_a.queue_free()
		_horno_b.queue_free()
		_horneado = true
	elif _cuadros > 30:
		_horneado = true

## LA CALIDAD (la llama el núcleo, `poner_calidad`): 0 ALTA, 1 MEDIA, 2 BAJA.
## El suelo no tiene sombras ni mallas que apagar; lo que pesa es el reguero
## del reflejo, ocho lecturas por píxel en la superficie más grande de la
## pantalla. En MEDIA, cuatro (en BAJA no hay reflejo: la escena pone
## `fuerza_reflejo` a 0 y el bucle ni entra).
func calidad(n: int) -> void:
	if _mat != null:
		_mat.set_shader_parameter("muestras", 8 if n <= 0 else 4)

func _a_textura(vp: SubViewport) -> ImageTexture:
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		return null
	img.convert(Image.FORMAT_RGBA8)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

# ------------------------------------------------------------------ el material

func _material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = LOSA
	m.set_shader_parameter("fuerza_reflejo", 1.0)
	m.set_shader_parameter("tex_grano", TEX_GRANO)
	m.set_shader_parameter("tex_celdas", TEX_CELDAS)
	m.set_shader_parameter("tex_manchas", TEX_MANCHAS)
	m.set_shader_parameter("rect_mapa", Vector4(0.0, Y_ARRIBA * Nucleo.E,
		Mesa.ANCHO * Nucleo.E, (Y_ABAJO - Y_ARRIBA) * Nucleo.E))
	m.set_shader_parameter("paso_mapa", Nucleo.E / RES_A * 1.5)
	# La losa es LA piedra de la biblioteca (decisión 6 de la revisión: una sola
	# piedra): gris PARDO, PIEDRA_1 y PIEDRA_2. Antes el fondo era GRIS_1, que es
	# un gris azulado, y el suelo no parecía de la misma cantera que las paredes.
	# Los números son los de la cabecera de `materiales/biblioteca.gd` («LA
	# PIEDRA, para quien tenga sombreador propio»): la losa una tesitura por
	# debajo del sillar, y su misma mugre.
	m.set_shader_parameter("piedra_a", Paleta.PIEDRA_1.darkened(0.25))
	m.set_shader_parameter("piedra_b", Paleta.PIEDRA_1)
	m.set_shader_parameter("piedra_c", Paleta.PIEDRA_2)
	m.set_shader_parameter("z_adoquin", Y_ADOQUIN * Nucleo.E)
	# La elipse seca de las palas, de los ejes de las dos palas de abajo.
	var izq := _mundo.mesa.p.flipper_eje_izq
	var der := _mundo.mesa.p.flipper_eje_der
	m.set_shader_parameter("zona_palas", Vector4((izq.x + der.x) * 0.5 * Nucleo.E,
		(izq.y + 15.0) * Nucleo.E, ((der.x - izq.x) * 0.5 + 40.0) * Nucleo.E, 60.0 * Nucleo.E))
	var mugre := Paleta.PIEDRA_1.lerp(Paleta.TIERRA_1, 0.5).lerp(Paleta.VERDE_1, 0.15)
	m.set_shader_parameter("color_mugre", mugre.darkened(0.55))
	m.set_shader_parameter("color_hollin", Paleta.NEGRO.darkened(0.4))
	m.set_shader_parameter("color_laton", Paleta.ORO)
	m.set_shader_parameter("color_laton_viejo", Paleta.ORO_OSCURO)
	m.set_shader_parameter("color_cardenillo", Paleta.ORO_OSCURO.lerp(Paleta.VERDE_1, 0.6).darkened(0.3))
	m.set_shader_parameter("emblema", Vector3(EMBLEMA.x * Nucleo.E, EMBLEMA.y * Nucleo.E,
		RADIO_EMBLEMA * Nucleo.E))
	m.set_shader_parameter("tesela_hueso", Paleta.TIERRA_5.darkened(0.35))
	m.set_shader_parameter("tesela_ocre", Paleta.ORO_OSCURO.darkened(0.1))
	m.set_shader_parameter("tesela_teja", Paleta.COBRE_1.lerp(Paleta.ROJO, 0.4))
	m.set_shader_parameter("tesela_pizarra", Paleta.GRIS_1.darkened(0.25))
	m.set_shader_parameter("tesela_carbon", Paleta.NEGRO)
	return m

# ------------------------------------------------------------------- los mapas

func _hornear() -> void:
	var datos := _datos()
	var tam_a := Vector2i(roundi(Mesa.ANCHO * RES_A), roundi((Y_ABAJO - Y_ARRIBA) * RES_A))
	var tam_b := Vector2i(roundi(Mesa.ANCHO * RES_B), roundi((Y_ABAJO - Y_ARRIBA) * RES_B))
	_horno_a = _horno(tam_a, 0, datos)
	_horno_b = _horno(tam_b, 1, datos)
	_mat.set_shader_parameter("mapa_a", _horno_a.get_texture())
	_mat.set_shader_parameter("mapa_b", _horno_b.get_texture())

func _horno(tam: Vector2i, modo: int, datos: Dictionary) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = tam
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var lienzo := ColorRect.new()
	lienzo.position = Vector2.ZERO
	lienzo.size = Vector2(tam)
	var m := ShaderMaterial.new()
	m.shader = MAPAS
	m.set_shader_parameter("modo", modo)
	m.set_shader_parameter("rect_px", Vector4(0.0, Y_ARRIBA, Mesa.ANCHO, Y_ABAJO - Y_ARRIBA))
	for k: String in datos:
		m.set_shader_parameter(k, datos[k])
	lienzo.material = m
	vp.add_child(lienzo)
	_mundo.add_child(vp)
	return vp

## Todo lo que los mapas necesitan saber de la mesa, ya en sus uniformes.
func _datos() -> Dictionary:
	var mesa := _mundo.mesa
	# --- la oclusión: cada colisionador del tablero, con su sombra
	var capsulas: Array[PackedFloat32Array] = []
	for c: Colisionador in mesa.colisionadores:
		if not c.en_capa(Mesa.CAPA_TABLERO):
			continue
		var forma := _sombra_de(c)
		if forma.z <= 0.0:
			continue
		capsulas.append(PackedFloat32Array([c.a.x, c.a.y, c.b.x, c.b.y,
			c.radio + forma.x, forma.y, forma.z, 0.0]))
	# --- los surcos, tramo a tramo
	var surcos: Array[PackedFloat32Array] = []
	for linea in _surcos():
		for i in range(1, linea.size()):
			surcos.append(PackedFloat32Array([linea[i - 1].x, linea[i - 1].y,
				linea[i].x, linea[i].y, 7.0, 1.0, 0.0, 0.0]))
	# Lo que barre la punta de cada pala al subir y bajar: un arco rayado.
	for pala: Flipper in [mesa.flipper_izq, mesa.flipper_der]:
		if pala == null:
			continue
		var r := pala.longitud - 4.0
		var a0 := minf(pala.angulo_reposo, pala.angulo_activo)
		var a1 := maxf(pala.angulo_reposo, pala.angulo_activo)
		var antes := pala.eje + Vector2(cos(a0), sin(a0)) * r
		for i in range(1, 9):
			var a := lerpf(a0, a1, float(i) / 8.0)
			var ahora := pala.eje + Vector2(cos(a), sin(a)) * r
			surcos.append(PackedFloat32Array([antes.x, antes.y, ahora.x, ahora.y, 4.0, 0.55, 0.0, 0.0]))
			antes = ahora
	var ancho := maxi(maxi(capsulas.size(), surcos.size()), 1)
	var img := Image.create(ancho, 4, false, Image.FORMAT_RGBAF)
	for i in capsulas.size():
		var v := capsulas[i]
		img.set_pixel(i, 0, Color(v[0], v[1], v[2], v[3]))
		img.set_pixel(i, 1, Color(v[4], v[5], v[6], v[7]))
	for i in surcos.size():
		var v := surcos[i]
		img.set_pixel(i, 2, Color(v[0], v[1], v[2], v[3]))
		img.set_pixel(i, 3, Color(v[4], v[5], v[6], v[7]))

	# --- el latón: tres cheurones detrás de la placa de cada boca, menguando
	var flechas := PackedVector4Array()
	var formas := PackedVector4Array()
	var bocas := PackedVector4Array()
	for r: Rampa in mesa.rampas:
		if r.nombre == "gusano":
			bocas.append(Vector4(r.puntos[0].x, r.puntos[0].y, RADIO_REBAJE, 0.0))
			var sale := r.puntos[r.puntos.size() - 1]
			bocas.append(Vector4(sale.x, sale.y, RADIO_REBAJE, 0.0))
		if not DIST_PLACA.has(r.nombre):
			continue
		var boca := r.puntos[0]
		var hacia := r.tangente_en(0.0).normalized()
		var desde := flechas.size()
		for i in 3:
			var d := float(DIST_PLACA[r.nombre]) + MEDIO_LARGO_PLACA + 9.0 + float(i) * 13.0
			var c := boca - hacia * d
			# El que caería encima de la rosa o de otra cosa embutida, no se pone:
			# dos latones cruzados son un error de obra.
			if c.distance_to(EMBLEMA) < RADIO_EMBLEMA + 22.0 or _choca(c, flechas, desde):
				break
			flechas.append(Vector4(c.x, c.y, hacia.x, hacia.y))
			var s := 1.0 - float(i) * 0.16
			formas.append(Vector4(10.0 * s, 7.5 * s, 3.2, 0.0))
	# --- los aros: uno alrededor de cada brasero (donde acaba el hollín de
	# dentro) y dos ciñendo la rosa.
	var aros := PackedVector4Array()
	var braseros := PackedVector4Array()
	for b in mesa.bumpers:
		aros.append(Vector4(b.x, b.y, mesa.p.bumper_radio + 9.0, 1.8))
		braseros.append(Vector4(b.x, b.y, mesa.p.bumper_radio, 30.0))
	aros.append(Vector4(EMBLEMA.x, EMBLEMA.y, RADIO_EMBLEMA + 2.0, 3.0))
	aros.append(Vector4(EMBLEMA.x, EMBLEMA.y, RADIO_EMBLEMA + 6.5, 1.3))
	var pozo := Vector2(Mesa.ANCHO * 0.5, mesa.p.y_drenaje + DESAGUE_FONDO)
	for cerco in CERCO_DESAGUE:
		aros.append(Vector4(pozo.x, pozo.y, cerco.x, cerco.y))
	# El listón doble entre las losas y el adoquín.
	var bandas := PackedVector4Array([
		Vector4(0.0, Y_ADOQUIN, Mesa.ANCHO, Y_ADOQUIN),
		Vector4(0.0, Y_ADOQUIN + 4.5, Mesa.ANCHO, Y_ADOQUIN + 4.5)])
	var bandas_g := PackedVector4Array([Vector4(3.0, 0.0, 0.0, 0.0), Vector4(1.2, 0.0, 0.0, 0.0)])
	var zonas := PackedVector4Array()
	var pesos := PackedVector4Array()
	for i in ZONAS_USO.size():
		zonas.append(ZONAS_USO[i])
		pesos.append(Vector4(PESOS_USO[i], 0.0, 0.0, 0.0))

	return {
		"datos": ImageTexture.create_from_image(img),
		"n_capsulas": capsulas.size(), "n_surcos": surcos.size(),
		"flechas": _llenar(flechas, 16), "flechas_forma": _llenar(formas, 16),
		"n_flechas": mini(flechas.size(), 16),
		"aros": _llenar(aros, 12), "n_aros": mini(aros.size(), 12),
		"bandas": _llenar(bandas, 4), "bandas_g": _llenar(bandas_g, 4),
		"n_bandas": mini(bandas.size(), 4),
		"braseros": _llenar(braseros, 4), "n_braseros": mini(braseros.size(), 4),
		"bocas": _llenar(bocas, 4), "n_bocas": mini(bocas.size(), 4),
		"zonas": _llenar(zonas, 8), "zonas_peso": _llenar(pesos, 8),
		"n_zonas": mini(zonas.size(), 8),
	}

## La sombra que deja cada tipo de pieza: (cuánto engorda, alcance, fuerza), en
## píxeles de mesa. Las paredes son altas y tapan lejos; un poste, poco. Las
## palas se mueven: su sombra no se hornea. Un z de 0 = sin sombra.
func _sombra_de(c: Colisionador) -> Vector3:
	match c.tipo:
		Colisionador.Tipo.PARED:
			# Solo en el tablero (y no en el coro): el faldón de la tribuna.
			if c.capas != Colisionador.TODAS:
				return Vector3(0.0, 26.0, 0.9)
			return Vector3(0.0, 15.0, 0.8)
		Colisionador.Tipo.BUMPER:
			return Vector3(2.0, 14.0, 0.75)
		Colisionador.Tipo.SLINGSHOT:
			return Vector3(2.0, 11.0, 0.7)
		Colisionador.Tipo.POSTE:
			return Vector3(0.0, 9.0, 0.6)
		Colisionador.Tipo.TARGET:
			return Vector3(1.0, 8.0, 0.5)
	return Vector3.ZERO

## Si un cheurón nuevo cae encima de otro ya puesto de OTRA boca (los de la
## misma van a 13 px y se dejan).
func _choca(c: Vector2, puestas: PackedVector4Array, desde: int) -> bool:
	for i in desde:
		if c.distance_to(Vector2(puestas[i].x, puestas[i].y)) < 22.0:
			return true
	return false

## Un uniforme de lista se rellena entero: el que sobra, a cero.
func _llenar(lista: PackedVector4Array, cuantos: int) -> PackedVector4Array:
	var l := lista.duplicate()
	l.resize(cuantos)
	return l
