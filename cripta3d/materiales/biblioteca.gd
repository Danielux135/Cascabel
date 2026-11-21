extends RefCounted

## CRIPTA 3D — LA BIBLIOTECA DE MATERIALES. De aquí sale TODA superficie de la
## mesa. Nadie crea un `StandardMaterial3D` suelto: se pide aquí, y si falta uno
## se añade aquí. Es lo único que impide que seis módulos hagan seis mesas.
##
##     var mat := Biblioteca.new()                       # una vez, en el núcleo
##     malla.material_override = mat.dame("hierro")
##     pala.material_override = mat.dame("hierro", {"local": true, "vertice": true})
##     nucleo.material_override = mat.dame("ascua", {"emision": 3.5})
##
## LOS NOMBRES: piedra, losa, hierro, oxido, bronce, laton, acero, madera, hueso,
## goma, cera, carbon (opacos, un solo sombreador: `superficie.gdshaderinc`) y
## ascua, arcano (los que dan luz: `ascua.gdshader`).
##
## LA VARIANTE (todas las claves son opcionales):
##   "tinte"      Color   multiplica el color (y la luz, en ascua y arcano)
##   "escala"     float   lo que mide el detalle, en unidades de mundo: el lado de
##                        una tesela de grano. Regla: más o menos el tamaño de la
##                        pieza; en paredes y suelo, de 0,8 a 1,2
##   "vertice"    bool    usa el color de vértice: R oclusión (1 al aire, 0 en el
##                        hueco), G canto (1 en el filo), B libre (en cera, carbón,
##                        ascua y arcano: cuánta luz propia). Por defecto NO: una
##                        malla sin color de vértice lo trae blanco, y saldría toda
##                        ella «canto»
##   "emision"    float   la energía de ascua y arcano; en carbón, el fuego de las
##                        grietas; en cualquier otro, luz propia pareja
##   "mojado"     0..1    el nivel del agua: 0,3 húmedo, 0,6 con charcos, 1 anegado
##   "desgaste"   0..1    cuánto se pelan los cantos
##   "suciedad"   0..1    cuánta mugre: huecos, juntas y parches
##   "semilla"    float   mueve el ruido de sitio (para piezas iguales con «local»)
##   "local"      bool    el dibujo va pegado a la pieza y no al mundo. OBLIGADO en
##                        todo lo que se mueve (palas, torno, lápidas, la bola): si
##                        no, la pieza resbala por dentro de su propia textura
##   "veta"       Vector3 hacia dónde corre la veta de la madera o el cepillado del
##                        metal (por defecto, el eje X)
##   "juntas"     Vector3 el sillar: largo, alto y fondo, en unidades de mundo.
##                        `Vector3.ZERO` las quita (la losa las trae puestas)
##   "relieve"    float   multiplica el relieve (1 = el del perfil)
##   "rugosidad"  float   multiplica la rugosidad (menos de 1 = más pulido)
##   "doble_cara" bool    YA NO CAMBIA NADA: se acepta y avisa una vez. Era otro
##                        programa entero (8,8 s de compilar en un navegador) por
##                        un modo de render que no pedía ningún módulo, y pasarlo
##                        todo a dos caras rompería la bóveda (es de una cara para
##                        que la cámara cenital la atraviese). Una malla que tenga
##                        que verse por detrás lleva las caras de detrás en la
##                        propia malla (los mismos triángulos, al revés)
##   "reflejo"    Texture2D  SOLO EL SUELO: la imagen de la cámara espejo (la de
##                        juego, simétrica por debajo del suelo). Con ella lo mojado
##                        refleja la mesa de verdad. "fuerza_reflejo" (float) dice
##                        cuánto; si no se da, 0,6
##   "oclusion"   Texture2D  SOLO EL SUELO: la oclusión horneada vista desde arriba
##                        (canal R, 1 = al aire). Va con "oclusion_rect" (Rect2): el
##                        rectángulo de mundo —x, z, ancho, fondo— que cubre el mapa
##   "depura"     int     pinta una máscara en vez del material: 1 canto,
##                        2 suciedad, 3 oclusión, 4 mojado, 5 normal
##
## UNA SOLA PIEDRA (decisión 6 de la tanda de arreglos). La primera crítica vio
## cinco piedras: cada módulo pedía la suya con su «escala» (de 0,18 a 1,4: el
## grano cambiaba ocho veces de tamaño de una pared a la de al lado) y su
## «tinte» (de 0,42 a 0,95). Por eso, en «piedra» y en «losa»:
##   - «escala» NO cambia el grano: el grano mide siempre PIEDRA_GRANO (0,55 de
##     tesela). La escala que se pida solo agranda o achica las manchas grandes,
##     con freno (de ×0,75 a ×1,35).
##   - «tinte» llega a medias: se queda PIEDRA_FRENO_TINTE (0,55) de lo que se
##     aparte del blanco. Un módulo oscurece o aclara su piedra; no la cambia.
##   - «juntas»: true pone el sillar del ábside (PIEDRA_SILLAR, 0,62 × 0,30 ×
##     0,42). Una cara GRANDE y lisa sin juntas (más de un metro de piedra de una
##     pieza) se lee como encimera: quien la tenga, que pida juntas.
## LA PIEDRA, para quien tenga sombreador propio (el suelo) y quiera ir a juego:
##   tintes   PIEDRA_1 (oscuro), PIEDRA_2 (medio), PIEDRA_3 (claro); la losa, una
##            tesitura más abajo: PIEDRA_1 oscurecido un 25 %, PIEDRA_1, PIEDRA_2.
##            Mugre: PIEDRA_1 hacia TIERRA_1 con una pizca de VERDE_1. Juntas y
##            grietas, NEGRO. Gris pardo: nada de azul ni de naranja en el albedo
##   grano    tesela de 0,55 (el detalle más fino, de 3 a 5 mm); manchas grandes
##            de 2,2 de tesela (borrones de medio metro a un metro); celdas
##            (picado y grietas) de 0,1. Sin moteado fino de alto contraste: ese
##            moteado es lo que la hacía «granito de encimera» o «fieltro»
##   rugosidad 0,9 en seco (0,8 la losa); mojada baja hasta 0,035 en el charco
##   relieve  suave (0,34 del grano, 0,14 de las celdas): de cerca se ve el
##            picado; de lejos no queda «corteza»
##
## OTRAS DOS NORMAS que ya no dependen de quien pide:
##   - «hierro» no baja de escala 0,22, y su martillado va a celdas del doble:
##     el golpe de martillo mide de 3 a 6 cm. Más fino brillaba a pellizcos,
##     como papel de aluminio (y en el remate seguía «moteado»). Y lo pulido sale
##     SOLO del canal G («roce_ruido» bajo): sin color de vértice, el hierro no
##     se pela; con «vertice», se pela donde la malla dice filo.
##   - con «vertice», EL CANTO LO DICE LA MALLA (canal G) y el sombreador ya no
##     lo saca del giro de la normal: un tubo fino gira más que un bisel y salía
##     canto entero (ver «leopardo» en `superficie.gdshaderinc`).
##
## Sin variante devuelve SIEMPRE la misma instancia. Con variante, una instancia
## por combinación: pedir dos veces lo mismo no crea dos materiales.
##
## CÓMO SE AÑADE UN MATERIAL: una entrada más en `_definir()`. Si lo que pide no
## se puede decir con los mandos del sombreador, se añade el mando allí; no se
## escribe otro sombreador para una sola superficie.

## UN SOLO PROGRAMA DE SUPERFICIE PARA LA MESA. Lo que cada `uniform` enciende se
## compila igual aunque no lo pida nadie, y en un navegador cada programa con
## luz son segundos de pantalla congelada (ver la cabecera de
## `superficie.gdshaderinc`). Por eso la depuración y el espejo del suelo, que
## la mesa no usa, no van en él: si alguien los pide, se arma aquí al vuelo un
## programa con `#define DEPURA` o `#define REFLEJO` (sin fichero, para que el
## banco de sombreadores no los cuente como de la mesa) y solo lo paga quien lo
## pide.
const SUPERFICIE: Shader = preload("res://cripta3d/materiales/superficie.gdshader")
const RUTA_SUPERFICIE := "res://cripta3d/materiales/superficie.gdshaderinc"
## El ascua no recibe luz (`unshaded`): de 6,7 s a 0,7 en el banco con ANGLE.
const ASCUA: Shader = preload("res://cripta3d/materiales/ascua.gdshader")
const TEX_GRANO: Texture2D = preload("res://cripta3d/texturas/ruido_grano.png")
const TEX_CELDAS: Texture2D = preload("res://cripta3d/texturas/ruido_celdas.png")
const TEX_MANCHAS: Texture2D = preload("res://cripta3d/texturas/ruido_manchas.png")
## Los cortes de zona del reparto del fuego, para la luz de la costra del ascua.
const Entorno := preload("res://cripta3d/mundo/entorno.gd")
## Cuánta luz recibe la costra del ascua según dónde esté: (campo, ábside,
## albardilla, sala). El campo es la referencia (1) y queda igual. Medido con las
## cajas del crítico de gira6 (luminancia del lecho de carbón, gira5 → con 8,7 en
## todos → con estos pesos): brasero de pie der. 53,5 → 69,0 → 54,8; izq. 28,3 →
## 37,5 → 28,4; desde la cenital 67,6 → 80,4 → 69,8; esquina 59,5 → 60,5 → 59,8.
## Con 0,55 y 0,3 (los del reparto del fuego) el carbón de la sala seguía rojo:
## la luz de la costra no cae como la de Godot, así que los pesos se miden, no se
## copian.
const PESO_SITIO := Vector4(1.0, 0.5, 0.3, 0.1)

## Las claves de variante que se entienden. Una que no esté aquí avisa una vez y
## se ignora: una clave mal escrita no da error, deja el material como estaba, y
## eso se diagnostica como «la variante no hace nada».
const CLAVES: Array[String] = ["tinte", "escala", "vertice", "emision", "mojado", "desgaste",
	"suciedad", "semilla", "local", "veta", "juntas", "relieve", "rugosidad", "doble_cara", "depura",
	"reflejo", "fuerza_reflejo", "oclusion", "oclusion_rect"]

## UNA SOLA PIEDRA (ver la cabecera): lo que mide y cómo es la piedra de la
## cripta. Quien tenga sombreador propio (el suelo) se alinea con estos números.
const PIEDRA_GRANO := 0.55          # la tesela del grano fino, en unidades de mundo
const PIEDRA_MANCHAS := 2.2         # la tesela de la variación grande (manchas, humedad)
const PIEDRA_FRENO_TINTE := 0.55    # qué parte del tinte de un módulo llega a la piedra
const PIEDRA_RUGOSIDAD := 0.9       # seca; mojada baja sola
const PIEDRA_SILLAR := Vector3(0.62, 0.30, 0.42)   # «juntas»: true — el sillar del ábside

var _perfiles: Dictionary = {}
var _cache: Dictionary = {}
var _avisados: Dictionary = {}
## `--depura-materiales=N` en la línea de órdenes de la escena pinta la máscara
## N («depura») en TODOS los opacos de la mesa a la vez. Es para diagnosticar en
## la escena de verdad, con las mallas de los módulos y su color de vértice, lo
## que el muestrario no puede enseñar (de dónde sale una mancha, qué es canto).
var _depura_todo := 0
## Los programas armados al vuelo («DEPURA», «REFLEJO», «DEPURA REFLEJO»): uno por
## combinación, como los materiales.
var _programas: Dictionary = {}

func _init() -> void:
	_perfiles = _definir()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--depura-materiales="):
			_depura_todo = int(arg.trim_prefix("--depura-materiales="))

# ------------------------------------------------------------------- lo público

func dame(nombre: String, variante: Dictionary = {}) -> Material:
	var quien := nombre
	if not _perfiles.has(quien):
		_avisar("material:" + nombre, "BIBLIOTECA: no hay material «%s»; doy piedra. Los que hay: %s" % [
			nombre, ", ".join(nombres())])
		quien = "piedra"
	var clave := _clave(quien, variante)
	if _cache.has(clave):
		return _cache[clave]
	var m := _crear(quien, variante)
	m.resource_name = clave
	_cache[clave] = m
	return m

func hay(nombre: String) -> bool:
	return _perfiles.has(nombre)

func nombres() -> PackedStringArray:
	var lista := PackedStringArray()
	for n: String in _perfiles:
		lista.append(n)
	return lista

# ------------------------------------------------------------------ la fábrica

func _clave(nombre: String, variante: Dictionary) -> String:
	if variante.is_empty():
		return nombre
	var claves: Array = variante.keys()
	claves.sort()
	var partes := PackedStringArray([nombre])
	for k: Variant in claves:
		partes.append("%s=%s" % [str(k), _texto(variante[k])])
	return "|".join(partes)

func _texto(v: Variant) -> String:
	match typeof(v):
		TYPE_BOOL:
			return "1" if v else "0"
		TYPE_INT, TYPE_FLOAT:
			return "%.4f" % float(v)
		TYPE_COLOR:
			return (v as Color).to_html(true)
		TYPE_VECTOR2:
			return "%.4f,%.4f" % [v.x, v.y]
		TYPE_VECTOR3:
			return "%.4f,%.4f,%.4f" % [v.x, v.y, v.z]
		TYPE_OBJECT:
			# Una textura: vale su identidad, no su contenido.
			return "obj%d" % (v as Object).get_instance_id() if v != null else "nada"
	return str(v)

func _avisar(clave: String, texto: String) -> void:
	if _avisados.has(clave):
		return
	_avisados[clave] = true
	push_warning(texto)
	print(texto)

func _crear(nombre: String, variante: Dictionary) -> ShaderMaterial:
	var perfil: Dictionary = _perfiles[nombre]
	var es_ascua: bool = perfil["_sombreador"] == "ascua"
	var m := ShaderMaterial.new()
	if es_ascua:
		m.shader = ASCUA
	else:
		var con_depura := _depura_todo > 0 or int(variante.get("depura", 0)) > 0
		var con_reflejo := false
		for k: String in ["reflejo", "fuerza_reflejo", "oclusion", "oclusion_rect"]:
			con_reflejo = con_reflejo or variante.has(k)
		m.shader = _superficie(con_depura, con_reflejo)
	if bool(variante.get("doble_cara", false)):
		_avisar("doble_cara", "BIBLIOTECA: «doble_cara» ya no cambia nada (un solo programa de superficie, de una cara). Si la malla se tiene que ver por detrás, lleva las caras de detrás en la propia malla.")
	m.set_shader_parameter("tex_grano", TEX_GRANO)
	m.set_shader_parameter("tex_celdas", TEX_CELDAS)
	m.set_shader_parameter("tex_manchas", TEX_MANCHAS)
	for k: String in perfil:
		if not k.begins_with("_"):
			m.set_shader_parameter(k, perfil[k])
	m.set_shader_parameter("marco", _marco(variante.get("veta", perfil.get("_veta", Vector3.RIGHT))))
	if _depura_todo > 0 and not es_ascua:
		m.set_shader_parameter("depura", _depura_todo)

	for k: Variant in variante:
		var v: Variant = variante[k]
		match str(k):
			"tinte":
				if v is Color:
					var t: Color = v
					if perfil.has("_freno_tinte"):
						# UNA SOLA PIEDRA: el tinte de un módulo acerca o aleja su piedra
						# de la de todos, pero no la hace otra (ver la cabecera).
						t = Color(1.0, 1.0, 1.0).lerp(t, float(perfil["_freno_tinte"]))
					m.set_shader_parameter("tinte", t)
			"escala":
				var e := maxf(float(v), 0.01)
				if perfil.has("_escala_fija"):
					# UNA SOLA PIEDRA: el grano no se mueve. La escala que pide el
					# módulo solo agranda o achica las manchas grandes, y con freno.
					var fija := float(perfil["_escala_fija"])
					m.set_shader_parameter("escala_manchas",
						float(perfil["escala_manchas"]) * clampf(sqrt(e / fija), 0.75, 1.35))
				else:
					m.set_shader_parameter("escala", maxf(e, float(perfil.get("_escala_min", 0.0))))
			"vertice":
				m.set_shader_parameter("usa_vertice", 1.0 if bool(v) else 0.0)
			"emision":
				m.set_shader_parameter(str(perfil.get("_emision", "emision")), maxf(float(v), 0.0))
			"mojado":
				if not es_ascua:
					m.set_shader_parameter("mojado", clampf(float(v), 0.0, 1.0))
			"desgaste":
				if not es_ascua:
					m.set_shader_parameter("desgaste", clampf(float(v), 0.0, 1.0))
			"suciedad":
				m.set_shader_parameter("suciedad", clampf(float(v), 0.0, 1.0))
			"semilla":
				var s := float(v)
				m.set_shader_parameter("desfase", Vector3(s * 3.71, s * 1.37, s * 2.53))
			"local":
				m.set_shader_parameter("en_local", 1.0 if bool(v) else 0.0)
			"veta":
				pass    # ya está en el marco
			"juntas":
				if not es_ascua:
					m.set_shader_parameter("bloque", _sillar(v))
			"relieve":
				m.set_shader_parameter("relieve", float(perfil.get("relieve", 0.5)) * float(v))
				if not es_ascua:
					m.set_shader_parameter("relieve_celdas", float(perfil.get("relieve_celdas", 0.0)) * float(v))
			"rugosidad":
				if not es_ascua:
					m.set_shader_parameter("rugosidad", float(perfil.get("rugosidad", 0.8)) * float(v))
					m.set_shader_parameter("rugosidad_canto", float(perfil.get("rugosidad_canto", 0.5)) * float(v))
			"doble_cara":
				pass    # ya avisó arriba: no cambia nada
			"depura":
				if not es_ascua:
					m.set_shader_parameter("depura", int(v))
			"reflejo":
				if not es_ascua and v is Texture2D:
					m.set_shader_parameter("reflejo", v)
					if not variante.has("fuerza_reflejo"):
						m.set_shader_parameter("fuerza_reflejo", 0.6)
			"fuerza_reflejo":
				if not es_ascua:
					m.set_shader_parameter("fuerza_reflejo", maxf(float(v), 0.0))
			"oclusion":
				if not es_ascua and v is Texture2D:
					m.set_shader_parameter("mapa_oclusion", v)
			"oclusion_rect":
				if not es_ascua and v is Rect2:
					var r: Rect2 = v
					m.set_shader_parameter("rect_oclusion", Vector4(r.position.x, r.position.y, r.size.x, r.size.y))
			_:
				_avisar("clave:" + str(k), "BIBLIOTECA: no conozco la variante «%s» (en «%s»). Las que hay: %s" % [
					str(k), nombre, ", ".join(PackedStringArray(CLAVES))])
	return m

## El programa de superficie que toca. Sin depuración ni espejo, el de la mesa
## (el fichero); con ellos, uno armado aquí con su `#define`, que solo se compila
## si se usa.
func _superficie(con_depura: bool, con_reflejo: bool) -> Shader:
	if not con_depura and not con_reflejo:
		return SUPERFICIE
	var defines := ""
	if con_depura:
		defines += "#define DEPURA\n"
	if con_reflejo:
		defines += "#define REFLEJO\n"
	if not _programas.has(defines):
		var s := Shader.new()
		# El mismo modo que `superficie.gdshader`: el especular lo pone la luz
		# copiada a mano que va dentro de la inclusión (`luz_godot.gdshaderinc`).
		s.code = "shader_type spatial;\nrender_mode specular_disabled;\n%s#include \"%s\"\n" % [defines, RUTA_SUPERFICIE]
		_programas[defines] = s
	return _programas[defines]

## El marco de la textura: un giro que pone su eje X a lo largo de «veta». Va
## transpuesto porque el sombreador hace `marco * p` y lo que quiere son las
## coordenadas de p EN el marco, o sea el producto por las filas.
func _marco(veta: Variant) -> Basis:
	var d := Vector3.RIGHT
	if veta is Vector3 and (veta as Vector3).length() > 0.0001:
		d = (veta as Vector3).normalized()
	if d.is_equal_approx(Vector3.RIGHT):
		return Basis.IDENTITY
	# El segundo eje, lo más vertical que se pueda: así lo que chorrea sigue
	# chorreando hacia abajo aunque la veta vaya torcida.
	var arriba := Vector3.UP if absf(d.y) < 0.92 else Vector3.BACK
	var b := (arriba - d * d.dot(arriba)).normalized()
	var c := d.cross(b)
	return Basis(d, b, c).transposed()

func _sillar(v: Variant) -> Vector3:
	if v is Vector3:
		return v
	if v is Vector2:
		return Vector3(v.x, v.y, v.y)
	if v is bool:
		return PIEDRA_SILLAR if v else Vector3.ZERO
	var lado := float(v)
	return Vector3(lado, lado * 0.5, lado * 0.7)

# ----------------------------------------------------------------- los perfiles

## Los números de partida de `superficie.gdshaderinc`. Cada perfil dice solo en
## qué se aparta.
func _base() -> Dictionary:
	return {
		"_sombreador": "superficie", "_emision": "emision",
		"escala": 0.5, "escala_celdas": 1.0, "escala_manchas": 3.3,
		"estirado": 1.0, "estirado_celdas": 1.0, "estirado_manchas": Vector3.ONE,
		"color_emision": Paleta.NARANJA, "translucido": Color(0.0, 0.0, 0.0),
		"tinte": Color(1.0, 1.0, 1.0),
		"variacion": 1.0, "claros": 0.5, "moteado": 0.3, "parches": 1.0,
		"mota_tono": 0.4, "picado": 1.0, "tono_bloque": 0.0,
		"rugosidad": 0.8, "rugosidad_var": 0.08, "rugosidad_canto": 0.5, "rugosidad_suciedad": 0.95,
		"metal": 0.0, "metal_canto": 0.0, "metal_suciedad": 0.0, "especular": 0.5,
		"relieve": 0.5, "relieve_celdas": 0.0, "relieve_testa": 1.0, "grietas": 0.0, "grieta_ancho": 0.18,
		"suciedad": 0.5, "desgaste": 0.5, "roce_blando": 0.0, "roce_ruido": 1.0, "proy_suave": 0.0,
		"mojado": 0.0, "porosidad": 0.5,
		"usa_vertice": 0.0, "curvatura": 1.0,
		"bloque": Vector3.ZERO, "junta": Vector3(0.012, 0.022, 1.0), "pulido": 0.0,
		"anillos": 0.0, "veta": 0.0,
		"emision": 0.0, "emision_grietas": 0.0, "en_local": 0.0, "desfase": Vector3.ZERO,
		"depura": 0,
	}

func _sup(cambios: Dictionary) -> Dictionary:
	var p := _base()
	p.merge(cambios, true)
	return p

func _luz(cambios: Dictionary) -> Dictionary:
	var p := {
		"_sombreador": "ascua", "_emision": "energia",
		"escala": 0.24, "tinte": Color(1.0, 1.0, 1.0), "energia": 3.0,
		"calor": 0.6, "nucleo": 0.4, "costra": 0.5, "grietas": 0.5,
		"latido": 0.1, "ritmo": 0.45, "parpadeo": 0.2, "prisa": 0.3, "relieve": 0.6,
		"usa_vertice": 0.0, "suciedad": 0.5, "en_local": 0.0, "desfase": Vector3.ZERO,
		# La luz propia de la costra (el ascua va sin luz de Godot: ver su cabecera).
		# Hace de la luz que antes le daba el fuego de al lado: cálida, de arriba
		# y un poco de delante.
		"luz_costra": Vector3(1.0, 0.22, 0.08), "fuerza_costra": 8.7,
		"dir_costra": Vector3(0.05, 0.6, 0.8),
		# Y CUÁNTA DE ESA LUZ LLEGA A SU SITIO (ver «LA LUZ DE SU SITIO» en el
		# sombreador). La 8,7 es la del campo, que es donde se igualó; un brasero de
		# pie de la sala con ella salía «una pila roja» (crítica de gira6). Los cortes
		# son los del reparto del fuego (`entorno._peso_zona`: el medio campo y la
		# altura de la sala se leen de allí; el 2,6 y el 7,0 están escritos en esa
		# función). Los pesos se miden contra gira5 con la caja del crítico.
		"sitio_peso": PESO_SITIO,
		"sitio_corte": Vector4(2.0, Entorno.MEDIO_CAMPO, 2.6, 7.0),
		"sitio_y": Entorno.Nucleo.Y_SALA + 0.6,
	}
	p.merge(cambios, true)
	return p

func _definir() -> Dictionary:
	var negro := Paleta.NEGRO
	return {
		# PIEDRA: sillar gastado. Mate de verdad, picada, con el canto mellado más
		# claro, grietas que nacen y mueren, y la humedad chorreando.
		"piedra": _sup({
			"_escala_fija": PIEDRA_GRANO, "_freno_tinte": PIEDRA_FRENO_TINTE,
			"color_a": Paleta.PIEDRA_1, "color_b": Paleta.PIEDRA_2, "color_c": Paleta.PIEDRA_3,
			"color_suciedad": Paleta.PIEDRA_1.lerp(Paleta.TIERRA_1, 0.5).lerp(Paleta.VERDE_1, 0.15).darkened(0.3),
			# El canto apenas aclara: un bisel claro alrededor de cada sillar era el
			# «marco de armario». La arista gastada se nota por la luz, no por pintura.
			"color_canto": Paleta.PIEDRA_2.lerp(Paleta.PIEDRA_3, 0.45), "color_grieta": negro,
			"escala": PIEDRA_GRANO, "escala_celdas": 2.0, "escala_manchas": PIEDRA_MANCHAS / PIEDRA_GRANO,
			"estirado_manchas": Vector3(1.0, 1.6, 1.0),
			"variacion": 0.75, "claros": 0.45, "moteado": 0.2, "mota_tono": 0.14, "picado": 0.35,
			"tono_bloque": 0.28,
			"rugosidad": PIEDRA_RUGOSIDAD, "rugosidad_var": 0.05, "rugosidad_canto": 0.82, "rugosidad_suciedad": 0.97,
			"especular": 0.32, "relieve": 0.34, "grietas": 0.35, "grieta_ancho": 0.15,
			"porosidad": 0.9, "parches": 0.6,
			"relieve_celdas": 0.14,
			"roce_blando": 0.25,
			"junta": Vector3(0.010, 0.016, 1.0),
			# El canto romo de dos facetas de las albardillas: ver «proy_suave».
			"proy_suave": 1.0,
		}),
		# LOSA: el suelo. La MISMA piedra (mismo grano, misma gama), más oscura, en
		# losas grandes con la junta negra, pulida en el centro de cada una por el
		# paso, y MOJADA.
		"losa": _sup({
			"_escala_fija": PIEDRA_GRANO, "_freno_tinte": PIEDRA_FRENO_TINTE,
			"color_a": Paleta.PIEDRA_1.darkened(0.25), "color_b": Paleta.PIEDRA_1, "color_c": Paleta.PIEDRA_2,
			"color_suciedad": negro.lerp(Paleta.TIERRA_1, 0.4),
			"color_canto": Paleta.PIEDRA_1.lerp(Paleta.PIEDRA_2, 0.6), "color_grieta": negro,
			"escala": PIEDRA_GRANO, "escala_celdas": 2.0, "escala_manchas": PIEDRA_MANCHAS / PIEDRA_GRANO,
			"variacion": 0.7, "claros": 0.45, "moteado": 0.12, "mota_tono": 0.14, "picado": 0.35,
			"tono_bloque": 0.22,
			"rugosidad": 0.8, "rugosidad_var": 0.06, "rugosidad_canto": 0.7, "rugosidad_suciedad": 0.95,
			"especular": 0.4, "relieve": 0.25, "grietas": 0.3, "grieta_ancho": 0.14,
			"porosidad": 0.85, "mojado": 0.5, "pulido": 0.3,
			"bloque": Vector3(0.78, 0.0, 0.52), "junta": Vector3(0.008, 0.016, 1.0),
			"relieve_celdas": 0.12,
			"roce_blando": 0.25,
		}),
		# HIERRO FORJADO: negro mate, batido a martillo, con herrumbre en lo hondo
		# y el filo pulido hasta el acero.
		# Antes era casi espejo (metal 0,9, rugosidad 0,5) con un martillado fuerte
		# y menudo: brillaba a pellizcos, como papel de aluminio arrugado. El hierro
		# forjado es negro MATE: el golpe de martillo se ve por la luz rasante, no
		# por chispas, y solo el filo está pulido.
		#
		# FORJA NEGRA MATE (decisión 7 del remate). La segunda crítica lo seguía
		# viendo moteado, «granito o papel de aluminio», en las palas, los
		# engranajes y los aros de los escudos. Eran tres cosas a la vez: el ruido
		# del roce pelaba crestas sueltas en mitad de las caras (lunares de GRIS_4
		# metálico sobre negro), los parches de mugre ponían manchas pardas
		# encima, y el color base se abría de GRIS_1 oscurecido a GRIS_2. Ahora:
		#   - GRIS_1 casi uniforme (la variación a un tercio, sin mota en el tono);
		#   - el martillado a menos de la mitad de amplitud y al doble de tamaño
		#     (celdas ×2), y el grano fino, más bajo y nunca menor de 0,22;
		#   - lo pulido SOLO en el filo: «roce_ruido» bajo, así que sin canal G no
		#     se pela nada, y con G el filo se pule en degradado, apenas mordido;
		#   - el óxido SOLO en lo hondo (canal R): sin parches y casi sin picado.
		"hierro": _sup({
			"_escala_min": 0.22,
			"color_a": Paleta.GRIS_1.darkened(0.12), "color_b": Paleta.GRIS_1, "color_c": Paleta.GRIS_1.lerp(Paleta.GRIS_2, 0.4),
			"color_suciedad": Paleta.COBRE_1.darkened(0.3), "color_canto": Paleta.GRIS_4, "color_grieta": negro,
			"escala": 0.28, "escala_celdas": 2.0,
			"variacion": 0.3, "claros": 0.12, "moteado": 0.05, "parches": 0.0, "mota_tono": 0.04, "picado": 0.15,
			"rugosidad": 0.7, "rugosidad_var": 0.03, "rugosidad_canto": 0.36, "rugosidad_suciedad": 0.92,
			"metal": 0.55, "metal_canto": 1.0, "metal_suciedad": 0.0,
			"relieve": 0.05, "relieve_celdas": 0.085,
			# El roce CASI SIN RUIDO y con la caída ancha (de 0,45 a 0,80): lo pulido
			# sigue al canal G en degradado y nace a media G. El ruido tiene que
			# quedar muy por debajo del ancho de la caída: con ruido 0,3 y caída de
			# 0,15 (probado en el remate), el aro de los escudos y los dientes de los
			# engranajes, que llevan G a medias en toda la cara, volvían a salir a
			# lunares; con ruido 0,4, igual. Sin G (caras), el hierro no se pela.
			"suciedad": 0.38, "desgaste": 0.5, "porosidad": 0.2, "roce_blando": 0.05, "roce_ruido": 0.1,
			"estirado_manchas": Vector3(1.0, 2.4, 1.0),
		}),
		# ÓXIDO: hierro comido. Costra mate y naranja, a ampollas, chorreando
		# hacia abajo, con el hierro asomando donde se roza.
		"oxido": _sup({
			"color_a": Paleta.COBRE_1.lerp(negro, 0.6), "color_b": Paleta.COBRE_1.lerp(Paleta.COBRE_2, 0.35),
			"color_c": Paleta.COBRE_2.lerp(Paleta.NARANJA, 0.2),
			"color_suciedad": Paleta.TIERRA_1, "color_canto": Paleta.GRIS_3, "color_grieta": negro,
			"escala": 0.28, "escala_celdas": 0.8, "estirado_manchas": Vector3(1.0, 2.6, 1.0),
			"variacion": 1.25, "claros": 0.8, "moteado": 0.7,
			"rugosidad": 0.9, "rugosidad_var": 0.05, "rugosidad_canto": 0.45, "rugosidad_suciedad": 0.97,
			"metal": 0.05, "metal_canto": 0.9, "metal_suciedad": 0.0,
			"relieve": 0.5, "relieve_celdas": -0.2, "grietas": 0.55, "grieta_ancho": 0.14,
			"suciedad": 0.45, "desgaste": 0.4, "porosidad": 0.6,
		}),
		# BRONCE: fundido y viejo. Pardo dorado, con pátina oscura en los huecos y
		# el metal vivo solo donde se toca.
		"bronce": _sup({
			"color_a": Paleta.ORO_OSCURO.lerp(Paleta.TIERRA_1, 0.5), "color_b": Paleta.ORO_OSCURO,
			"color_c": Paleta.COBRE_3,
			"color_suciedad": Paleta.TIERRA_1.lerp(Paleta.VERDE_1, 0.4),
			"color_canto": Paleta.COBRE_3.lerp(Paleta.ORO, 0.5), "color_grieta": negro,
			"escala": 0.3, "escala_celdas": 2.0,
			"variacion": 0.6, "claros": 0.4, "moteado": 0.3, "parches": 0.7,
			"rugosidad": 0.42, "rugosidad_var": 0.08, "rugosidad_canto": 0.26, "rugosidad_suciedad": 0.86,
			"metal": 0.95, "metal_canto": 1.0, "metal_suciedad": 0.2,
			"relieve": 0.15, "relieve_celdas": 0.12,
			"suciedad": 0.6, "desgaste": 0.5, "porosidad": 0.15,
		}),
		# LATÓN: lo único que brilla limpio. Raíles e incrustaciones.
		# Ni lunares ni parches: la pátina va SOLO a los huecos (canal R) y el canto
		# es del mismo oro que la cara. Ver «leopardo» en el sombreador.
		"laton": _sup({
			"color_a": Paleta.ORO, "color_b": Paleta.ORO.lerp(Paleta.ORO_CLARO, 0.35),
			"color_c": Paleta.ORO.lerp(Paleta.ORO_CLARO, 0.6),
			"color_suciedad": Paleta.ORO_OSCURO.lerp(Paleta.TIERRA_1, 0.55),
			"color_canto": Paleta.ORO.lerp(Paleta.ORO_CLARO, 0.5),
			"color_grieta": negro,
			"escala": 0.3, "estirado": 1.0,
			"variacion": 0.12, "claros": 0.25, "moteado": 0.0, "parches": 0.0, "mota_tono": 0.1, "picado": 0.0,
			"rugosidad": 0.26, "rugosidad_var": 0.02, "rugosidad_canto": 0.2, "rugosidad_suciedad": 0.55,
			"metal": 0.92, "metal_canto": 1.0, "metal_suciedad": 0.6,
			"relieve": 0.03,
			"suciedad": 0.3, "desgaste": 0.3, "porosidad": 0.05,
			"roce_blando": 0.3, "curvatura": 0.5,
		}),
		# ACERO: pulido y frío. Ejes, la bola, los filos.
		"acero": _sup({
			"color_a": Paleta.GRIS_3, "color_b": Paleta.GRIS_4, "color_c": Paleta.GRIS_5,
			"color_suciedad": Paleta.GRIS_1, "color_canto": Paleta.BLANCO, "color_grieta": negro,
			"escala": 0.3, "estirado": 1.0,
			"variacion": 0.2, "claros": 0.35, "moteado": 0.03, "parches": 0.5,
			"rugosidad": 0.33, "rugosidad_var": 0.04, "rugosidad_canto": 0.2, "rugosidad_suciedad": 0.55,
			"metal": 0.94, "metal_canto": 1.0, "metal_suciedad": 0.6,
			"relieve": 0.05,
			"suciedad": 0.2, "desgaste": 0.4, "porosidad": 0.05,
		}),
		# MADERA: roble viejo. Veta con dirección (anillos de verdad), fibra, y
		# rajas a lo largo.
		# MADERA: roble VIEJO, gris pardo y apagado. Antes la veta iba estirada
		# nueve veces (un cepillo de rayas) y en TIERRA_3/4 bajo el fuego: tarima
		# laminada naranja rosada. Ahora la fibra es más corta, la veta más suave y
		# el tono baja hacia TIERRA_2/3 con un poco de gris.
		#
		# Y SIN MALVA (remate). TIERRA_1 y TIERRA_2 son pardos con más azul que
		# verde (4A3A42): bajo la luna fría la tarima del coro salía rosa malva,
		# violeta fuera del espectro y sin casar con la viga de la campana. La
		# madera sale ahora de TIERRA_3 (el pardo cálido) apagado con la piedra,
		# la mugre y las rajas de PIEDRA_1 y negro, la veta pinta menos y la fibra
		# es algo más corta; cada tablón, su tono (juntas del coro).
		"madera": _sup({
			"color_a": Paleta.TIERRA_3.darkened(0.5).lerp(Paleta.PIEDRA_1, 0.35),
			"color_b": Paleta.TIERRA_3.darkened(0.22).lerp(Paleta.PIEDRA_2, 0.2),
			"color_c": Paleta.TIERRA_3.lerp(Paleta.TIERRA_4, 0.2).lerp(Paleta.PIEDRA_3, 0.25),
			"color_suciedad": Paleta.PIEDRA_1.darkened(0.45).lerp(Paleta.COBRE_1, 0.15),
			"color_canto": Paleta.TIERRA_3.lerp(Paleta.TIERRA_4, 0.4),
			"color_grieta": negro.lerp(Paleta.PIEDRA_1, 0.2),
			"escala": 0.5, "escala_celdas": 0.8, "estirado": 3.0, "estirado_celdas": 2.5,
			"estirado_manchas": Vector3(3.0, 1.0, 1.0), "tono_bloque": 0.6,
			"variacion": 0.5, "claros": 0.3, "moteado": 0.4,
			"rugosidad": 0.82, "rugosidad_var": 0.08, "rugosidad_canto": 0.7, "rugosidad_suciedad": 0.9,
			"especular": 0.35, "relieve": 0.4, "relieve_testa": 0.3, "grietas": 0.38, "grieta_ancho": 0.2,
			"parches": 0.5,
			"anillos": 30.0, "veta": 0.26,
			"suciedad": 0.5, "desgaste": 0.5, "porosidad": 0.8,
			"roce_blando": 0.12,
		}),
		# HUESO: mate y cálido, con el poro fino y las grietas en tierra. No llega al
		# blanco de la paleta: bajo el fuego, un blanco de verdad se quema entero.
		"hueso": _sup({
			"color_a": Paleta.TIERRA_5.lerp(Paleta.TIERRA_4, 0.6).darkened(0.25),
			"color_b": Paleta.TIERRA_5.darkened(0.25), "color_c": Paleta.TIERRA_6.darkened(0.25),
			"color_suciedad": Paleta.TIERRA_3.lerp(Paleta.TIERRA_4, 0.4), "color_canto": Paleta.TIERRA_6.darkened(0.2),
			"color_grieta": Paleta.TIERRA_3.darkened(0.3),
			"escala": 0.22, "escala_celdas": 1.5,
			"variacion": 0.7, "claros": 0.6, "moteado": 0.22,
			"rugosidad": 0.64, "rugosidad_var": 0.05, "rugosidad_canto": 0.5, "rugosidad_suciedad": 0.92,
			"especular": 0.35, "relieve": 0.14, "grietas": 0.7, "grieta_ancho": 0.17,
			"suciedad": 0.35, "desgaste": 0.4, "porosidad": 0.6,
			"translucido": Paleta.TIERRA_4.darkened(0.6),
			"parches": 0.35,
			"roce_blando": 0.15,
		}),
		# GOMA: roja, satinada, sin un solo brillo duro. Polvo en lo hondo.
		# GOMA: ROJO oscuro de la paleta, mate. Antes el tono claro tiraba a
		# ROJO_LUZ y bajo el fuego salía naranja neón, lo más saturado de la mesa.
		# El canto se gasta a polvo (claro y apagado), no a rojo vivo.
		"goma": _sup({
			"color_a": Paleta.ROJO.lerp(negro, 0.55), "color_b": Paleta.ROJO.lerp(negro, 0.3), "color_c": Paleta.ROJO,
			"color_suciedad": Paleta.TIERRA_2.lerp(negro, 0.3),
			"color_canto": Paleta.ROJO.lerp(Paleta.TIERRA_4, 0.45).darkened(0.15),
			"color_grieta": negro,
			"escala": 0.25,
			"variacion": 0.3, "claros": 0.2, "moteado": 0.05, "mota_tono": 0.2, "picado": 0.3,
			"rugosidad": 0.76, "rugosidad_var": 0.06, "rugosidad_canto": 0.88, "rugosidad_suciedad": 0.95,
			"especular": 0.3, "relieve": 0.05,
			"suciedad": 0.35, "desgaste": 0.35, "porosidad": 0.1,
			"parches": 0.5,
			"roce_blando": 0.3, "curvatura": 0.5,
		}),
		# CERA: la de las velas. Lisa, blanda, deja pasar la luz.
		"cera": _sup({
			"color_a": Paleta.TIERRA_5.darkened(0.3), "color_b": Paleta.TIERRA_6.lerp(Paleta.TIERRA_5, 0.5).darkened(0.25),
			"color_c": Paleta.TIERRA_6.darkened(0.2),
			"color_suciedad": Paleta.TIERRA_3, "color_canto": Paleta.TIERRA_6.darkened(0.18), "color_grieta": Paleta.TIERRA_3,
			"color_emision": Paleta.ORO_CLARO.lerp(Paleta.NARANJA, 0.35),
			"escala": 0.3, "escala_celdas": 1.4,
			"variacion": 0.4, "claros": 0.4, "moteado": 0.06,
			"rugosidad": 0.4, "rugosidad_var": 0.04, "rugosidad_canto": 0.34, "rugosidad_suciedad": 0.8,
			"especular": 0.45, "relieve": 0.05, "relieve_celdas": 0.12,
			"suciedad": 0.3, "desgaste": 0.2, "porosidad": 0.05,
			# La luz que atraviesa, PARDA y apagada (remate): con NARANJA la cera de
			# serie salía naranja aunque la vela estuviera apagada. Quien quiera la
			# cera encendida la pide con «emision» (atrezzo la pisa en una copia).
			"translucido": Paleta.TIERRA_4.darkened(0.62),
			"roce_blando": 0.2,
		}),
		# CARBÓN: negro a facetas, con ceniza en los cantos. Con «emision», arde
		# por las grietas.
		"carbon": _sup({
			"_emision": "emision_grietas",
			"color_a": negro.darkened(0.5), "color_b": negro, "color_c": Paleta.GRIS_1.lerp(negro, 0.4),
			"color_suciedad": negro.darkened(0.5), "color_canto": Paleta.GRIS_2.lerp(Paleta.GRIS_1, 0.4), "color_grieta": negro.darkened(0.7),
			"color_emision": Paleta.NARANJA.lerp(Paleta.ORO_CLARO, 0.25),
			"escala": 0.25, "escala_celdas": 0.7,
			"variacion": 0.8, "claros": 0.5, "moteado": 0.6,
			"rugosidad": 0.65, "rugosidad_var": 0.2, "rugosidad_canto": 0.95, "rugosidad_suciedad": 0.97,
			"especular": 0.35, "relieve": 0.6, "relieve_celdas": 0.35, "grietas": 0.95, "grieta_ancho": 0.24,
			"suciedad": 0.4, "desgaste": 0.35, "porosidad": 0.3,
			"roce_blando": 0.1,
		}),
		# ASCUA: núcleo casi blanco, borde rojo. Late y parpadea.
		"ascua": _luz({
			"color_costra": Paleta.TIERRA_1.lerp(negro, 0.5),
			"color_rojo": Paleta.ROJO_LUZ, "color_naranja": Paleta.NARANJA,
			"color_claro": Paleta.ORO_CLARO, "color_nucleo": Paleta.ORO_CLARO.lerp(Paleta.TIERRA_6, 0.6),
			"escala": 0.3, "energia": 2.6,
			"calor": 0.5, "nucleo": 0.5, "costra": 0.4, "grietas": 0.6,
			"latido": 0.1, "ritmo": 0.45, "parpadeo": 0.25, "prisa": 0.3,
		}),
		# ARCANO: el ascua del espectro. Violeta, fría, lenta, y arde por el borde.
		"arcano": _luz({
			"color_costra": Paleta.TIERRA_1.lerp(negro, 0.6),
			"color_rojo": Paleta.ARCANO_1.lerp(negro, 0.35), "color_naranja": Paleta.ARCANO_1,
			"color_claro": Paleta.ARCANO, "color_nucleo": Paleta.ARCANO.lerp(Paleta.BLANCO, 0.6),
			"escala": 0.5, "energia": 2.2,
			"calor": 0.4, "nucleo": -0.45, "costra": 0.25, "grietas": 0.7,
			"latido": 0.12, "ritmo": 0.2, "parpadeo": 0.35, "prisa": 0.1, "relieve": 0.2,
			# Su costra, en la boca de la catacumba, la alumbraban los fuegos de la
			# mesa: cálida y más floja que la del ascua. Con luz violeta (la del
			# muestrario) la boca salía morada y encendida: medido en la mesa, la
			# boca era (34, 13, 10) de media y con violeta daba (41, 16, 43).
			# Con (1,0 · 0,22 · 0,08) × 3,5 el fondo de la boca quedaba algo más rojizo
		# que en gira5 (crítica de gira6: 20/11/10 → 23/10/9 y 21/14/17 → 25/15/17):
		# la luz de fuego de la mesa (`COLOR_FUEGO`, en lineal ~1 · 0,4 · 0,13) tiene
		# más verde, y a la boca le llegaba además el violeta de su propio resplandor.
		# Con esta, la boca derecha de v0_00 da 22/14/17 (gira5: 21/14/16).
		"luz_costra": Vector3(0.9, 0.33, 0.3), "fuerza_costra": 1.4,
		}),
	}
