extends SceneTree

## CRIPTA 3D — sonda de la biblioteca de materiales. No dibuja: comprueba el
## contrato que el núcleo y los módulos dan por hecho, y lo dice.
##
##     python cripta3d/herramientas/godot3d.py guion res://cripta3d/materiales/sonda_biblioteca.gd --lineas 40
##
## LO QUE MIRA, y por qué cada cosa:
##   - que estén los catorce nombres acordados;
##   - que sin variante salga SIEMPRE la misma instancia, y con variante una por
##     combinación (da igual el orden de las claves, o si el número es entero);
##   - que cada clave de un perfil sea un mando de verdad de su sombreador. Un
##     mando mal escrito no da error: `set_shader_parameter` se lo traga y el
##     material sale sin él, que es la avería de la reliquia con la clave mal
##     puesta. Se comprueba LEYENDO el sombreador, no con una lista a mano;
##   - que cada clave de variante cambie algo: una variante que no hace nada se
##     diagnostica como «el material no responde»;
##   - que una clave o un nombre que no existen avisen y no rompan;
##   - y que las tres texturas estén y midan lo que tienen que medir.

const Biblioteca := preload("res://cripta3d/materiales/biblioteca.gd")
const OBLIGADOS: Array[String] = ["piedra", "losa", "hierro", "oxido", "bronce", "laton", "acero",
	"madera", "hueso", "goma", "cera", "carbon", "ascua", "arcano"]

var _hechas := 0
var _fallos := 0

func _init() -> void:
	var mat := Biblioteca.new()
	var hay: PackedStringArray = mat.nombres()
	for n in OBLIGADOS:
		_comprobar("existe «%s»" % n, mat.hay(n) and hay.has(n))
	_comprobar("no hay un material que se llame como ninguno", not mat.hay("purpurina"))

	_comprobar("sin variante, siempre la misma instancia", mat.dame("hierro") == mat.dame("hierro"))
	_comprobar("una variante vacía es no dar variante", mat.dame("hierro", {}) == mat.dame("hierro"))
	var a: Material = mat.dame("hierro", {"vertice": true, "escala": 0.3})
	var b: Material = mat.dame("hierro", {"escala": 0.3, "vertice": true})
	_comprobar("la misma variante en otro orden es la misma instancia", a == b)
	_comprobar("y no es la de sin variante", a != mat.dame("hierro"))
	_comprobar("un entero y un decimal son la misma variante",
		mat.dame("piedra", {"escala": 1}) == mat.dame("piedra", {"escala": 1.0}))
	_comprobar("dos materiales distintos no comparten instancia", mat.dame("hierro") != mat.dame("acero"))

	# Los mandos de cada sombreador, leídos de su fuente.
	var de_superficie := _mandos("res://cripta3d/materiales/superficie.gdshaderinc")
	var de_ascua := _mandos("res://cripta3d/materiales/ascua.gdshader")
	_comprobar("el sombreador de superficie tiene mandos", de_superficie.size() > 20, str(de_superficie.size()))
	_comprobar("el del ascua también", de_ascua.size() > 10, str(de_ascua.size()))
	var perfiles: Dictionary = mat.get("_perfiles")
	for n: String in perfiles:
		var perfil: Dictionary = perfiles[n]
		var mandos: Dictionary = de_ascua if perfil["_sombreador"] == "ascua" else de_superficie
		var sobran: Array[String] = []
		for clave: String in perfil:
			if not clave.begins_with("_") and not mandos.has(clave):
				sobran.append(clave)
		_comprobar("«%s»: todas sus claves son mandos del sombreador" % n, sobran.is_empty(), str(sobran))
		var m := mat.dame(n) as ShaderMaterial
		_comprobar("«%s» es un ShaderMaterial con su sombreador" % n, m != null and m.shader != null)

	# Cada clave de variante tiene que cambiar algún mando.
	var pruebas := {
		"tinte": Color(0.5, 0.6, 0.7), "escala": 0.123, "vertice": true, "emision": 2.5, "mojado": 0.7,
		"desgaste": 0.9, "suciedad": 0.9, "semilla": 4.0, "local": true, "veta": Vector3(0.0, 1.0, 0.0),
		"juntas": Vector3(0.5, 0.25, 0.4), "relieve": 2.0, "rugosidad": 0.5, "depura": 2,
		"fuerza_reflejo": 0.5, "oclusion_rect": Rect2(0.0, 5.7, 4.0, 7.3),
	}
	var liso := mat.dame("piedra") as ShaderMaterial
	for clave: String in pruebas:
		var v := mat.dame("piedra", {clave: pruebas[clave]}) as ShaderMaterial
		var cambia := false
		for mando: String in de_superficie:
			if v.get_shader_parameter(mando) != liso.get_shader_parameter(mando):
				cambia = true
				break
		_comprobar("la variante «%s» cambia algo en la piedra" % clave, cambia)
	# UN SOLO PROGRAMA DE SUPERFICIE (ver la cabecera de `superficie.gdshaderinc`):
	# «doble_cara» era otro programa entero, 8,8 s de compilar en un navegador.
	_comprobar("«doble_cara» NO cambia de sombreador: la mesa compila un solo programa de superficie",
		(mat.dame("hierro", {"doble_cara": true}) as ShaderMaterial).shader == (mat.dame("hierro") as ShaderMaterial).shader)
	var brasa := mat.dame("ascua") as ShaderMaterial
	var brasa_fuerte := mat.dame("ascua", {"emision": 7.0}) as ShaderMaterial
	_comprobar("«emision» es la energía del ascua",
		is_equal_approx(float(brasa_fuerte.get_shader_parameter("energia")), 7.0)
		and not is_equal_approx(float(brasa.get_shader_parameter("energia")), 7.0))
	var carbon := mat.dame("carbon", {"emision": 3.0}) as ShaderMaterial
	_comprobar("y en el carbón, el fuego de las grietas",
		is_equal_approx(float(carbon.get_shader_parameter("emision_grietas")), 3.0))

	# Lo que no existe avisa y no rompe.
	var raro: Material = mat.dame("purpurina")
	_comprobar("un nombre que no existe da piedra, no un nulo", raro == mat.dame("piedra"))
	var con_errata: Material = mat.dame("hierro", {"mogado": 1.0})
	_comprobar("una clave que no existe se ignora, no rompe", con_errata != null)

	# Las texturas.
	for nombre: String in ["ruido_grano", "ruido_celdas", "ruido_manchas"]:
		var ruta := "res://cripta3d/texturas/%s.png" % nombre
		var img := Image.load_from_file(ProjectSettings.globalize_path(ruta))
		_comprobar("%s está y es cuadrada de 512" % nombre,
			img != null and img.get_width() == 512 and img.get_height() == 512)
		var ficha := FileAccess.get_file_as_string(ruta + ".import")
		_comprobar("%s se importa con mipmaps y sin tocarle el alfa" % nombre,
			ficha.contains("mipmaps/generate=true") and ficha.contains("process/fix_alpha_border=false")
			and ficha.contains("compress/mode=0"))

	if _fallos == 0:
		print("OK  %d/%d comprobaciones de la biblioteca" % [_hechas, _hechas])
	else:
		print("FALLO  %d de %d comprobaciones de la biblioteca" % [_fallos, _hechas])
	quit()

func _comprobar(que: String, bien: bool, detalle: String = "") -> void:
	_hechas += 1
	if bien:
		return
	_fallos += 1
	print("  FALLO: %s %s" % [que, detalle])

## Los nombres de los `uniform` de un sombreador, leídos de su texto.
func _mandos(ruta: String) -> Dictionary:
	var texto := FileAccess.get_file_as_string(ruta)
	var re := RegEx.new()
	re.compile("(?m)^uniform\\s+\\w+\\s+(\\w+)")
	var mandos := {}
	for m in re.search_all(texto):
		mandos[m.get_string(1)] = true
	return mandos
