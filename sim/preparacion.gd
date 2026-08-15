class_name Preparacion
extends RefCounted

## LO QUE ELIGES ANTES DEL RUN: cascabel, criatura y palas. `DISEÑO.md` §5.
##
## Elegir antes del run NO es desbloquear entre runs, así que esta capa no toca
## el invariante de §13: está todo abierto desde el primer día. Lo que se
## desbloquea son criaturas, que son skin, y eso lo lleva `Guardado`.
##
## LAS DOS MITADES NO SE PARECEN EN NADA, y conviene saber por qué:
##
## - **El cascabel es una bolsa de modificadores**, exactamente igual que una
##   reliquia, y usa los ganchos que `Combate` ya lee. Ni un `if` nuevo. Entra en
##   el combate por `BolsaReliquias.base`, que es como la bolsa de un run vacío,
##   y por eso una partida sin elegir nada se comporta EXACTAMENTE igual que
##   antes: `casc_acero` no tiene efectos y la bolsa base sale neutra. Eso es lo
##   que hace que todas las medidas viejas sigan valiendo.
## - **Las palas tocan la física**, que es justo lo que `DISEÑO.md` §5 quiere de
##   ellas: son "tus manos". Y por eso hay que construir la mesa CON ellas
##   puestas: `Mesa.new()` copia los parámetros dentro de cada colisionador, así
##   que cambiarlas después no hace nada. Es una trampa de `CLAUDE.md` y un
##   barrido escrito al revés mide seis veces lo mismo.

const RUTA := "res://data/preparacion.json"

var cascabel: String = "casc_acero"
var criatura: String = "cr_rata"
var palas: String = "pala_fabrica"

static var _datos: Dictionary = {}

static func _cargar() -> Dictionary:
	if not _datos.is_empty():
		return _datos
	var f := FileAccess.open(RUTA, FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir %s" % RUTA)
		return {}
	var crudo: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(crudo) != TYPE_DICTIONARY:
		push_error("%s no tiene la forma esperada" % RUTA)
		return {}
	_datos = crudo as Dictionary
	return _datos

static func cascabeles() -> Array:
	return _cargar().get("cascabeles", []) as Array

static func palas_disponibles() -> Array:
	return _cargar().get("palas", []) as Array

static func ficha_cascabel(el_id: String) -> Dictionary:
	for c in cascabeles():
		if str((c as Dictionary).get("id", "")) == el_id:
			return c as Dictionary
	return {}

static func ficha_palas(el_id: String) -> Dictionary:
	for p in palas_disponibles():
		if str((p as Dictionary).get("id", "")) == el_id:
			return p as Dictionary
	return {}

# ------------------------------------------------------------- el cascabel

## El cascabel como `Reliquia`, para que entre en la bolsa sin código nuevo.
##
## Es reutilizar el sistema entero —acumulación por prefijo, condiciones con
## `cuando`, escalado por victorias— en vez de escribir un segundo sistema de
## modificadores que hiciera lo mismo con otro nombre. Un cascabel sin efectos
## devuelve una reliquia vacía, que es EXACTAMENTE neutra: si no lo fuera, todo
## el balance medido dejaría de valer sin avisar.
func como_reliquia() -> Reliquia:
	var ficha := ficha_cascabel(cascabel)
	if ficha.is_empty():
		return null
	var d := {
		"id": str(ficha.get("id", "")),
		"nombre": nombre_cascabel(),
		"texto": str(ficha.get("resumen", "")),
		"efectos": ficha.get("efectos", {}),
		"cuando": str(ficha.get("cuando", "")),
		"umbral": float(ficha.get("umbral", 0.0)),
		"eje": Reliquia.Eje.COMBO,
		"rareza": Mision.Rareza.COMUN,
	}
	return Reliquia.new(d)

## El nombre sale del catálogo de recuperables y NO se copia aquí. Dos listas de
## nombres mantenidas a mano se desincronizan siempre, y el día que pasara la
## pantalla de preparación diría una cosa y la carpeta `RECUPERADO` otra.
func nombre_cascabel() -> String:
	var p := CatalogoRecuperable.por_id(cascabel)
	return p.nombre if p != null else cascabel

func nombre_criatura() -> String:
	var p := CatalogoRecuperable.por_id(criatura)
	return p.nombre if p != null else criatura

func nombre_palas() -> String:
	return str(ficha_palas(palas).get("nombre", palas))

# ---------------------------------------------------------------- las palas

## Los parámetros de mesa con las palas elegidas puestas. **Se le pasa a
## `Mesa.new()`**, nunca se toca después.
##
## Solo se sobrescribe lo que la ficha traiga escrito: así, el día que se ajuste
## un dial de `parametros_mesa.gd`, las palas que no lo tocan lo heredan en vez
## de quedarse con una copia vieja.
func parametros_mesa() -> ParametrosMesa:
	var pm := ParametrosMesa.new()
	# LAS DOS MITADES DE LA FÍSICA: las palas son tus manos y el cascabel es la
	# bola. No se pisan —las palas tocan `flipper_*` y el cascabel gravedad,
	# rebote y rodadura—, pero si algún día se pisaran, manda el cascabel: es la
	# elección más específica de las dos.
	_aplicar_mesa(pm, ficha_palas(palas))
	_aplicar_mesa(pm, ficha_cascabel(cascabel))
	return pm

## EL RADIO NO SE TOCA, y esto no es una comprobación de más. El invariante de
## `CLAUDE.md` se abrió a rebote, gravedad y rodadura porque ninguno de los tres
## cambia el hueco entre palas; `radio_bola` sí, y ese hueco es la dificultad
## entera de un pinball. Un radio en el JSON no daría ningún error: dejaría una
## mesa distinta con la misma geometría dibujada.
const PROHIBIDAS := ["radio_bola", "flipper_eje_izq", "flipper_eje_der", "y_drenaje"]

func _aplicar_mesa(pm: ParametrosMesa, ficha: Dictionary) -> void:
	var cambios: Dictionary = ficha.get("mesa", {}) as Dictionary
	for clave in cambios:
		var nombre := str(clave)
		# Una clave mal escrita en el JSON no da error: dejaría unas palas o un
		# cascabel que no se diferencian en nada del de fábrica, y eso se
		# diagnosticaría como "no se notan". Hay una prueba que lo comprueba.
		if not (nombre in pm):
			push_error("preparacion.json: `%s` no existe en ParametrosMesa" % nombre)
			continue
		if PROHIBIDAS.has(nombre):
			push_error("preparacion.json: `%s` no se puede tocar desde aquí" % nombre)
			continue
		pm.set(nombre, cambios[clave])

## Las criaturas que se pueden elegir: las recuperadas y nada más. Es lo único
## de esta pantalla que depende del guardado, porque es lo único que se gana.
static func criaturas_de(g: Guardado) -> Array:
	var lista: Array = []
	for p in CatalogoRecuperable.por_tipo("criatura"):
		if g == null or g.tiene((p as CatalogoRecuperable.Pieza).id):
			lista.append(p)
	return lista

## Deja la elección en algo que exista. Un guardado viejo puede traer una
## criatura que ya no está en el catálogo, y una elección que apunta a la nada
## no da error: deja la bola sin dibujo.
func sanear(g: Guardado) -> void:
	if ficha_cascabel(cascabel).is_empty():
		cascabel = "casc_acero"
	if ficha_palas(palas).is_empty():
		palas = "pala_fabrica"
	var validas := criaturas_de(g)
	if validas.is_empty():
		return
	for c in validas:
		if (c as CatalogoRecuperable.Pieza).id == criatura:
			return
	criatura = (validas[0] as CatalogoRecuperable.Pieza).id
