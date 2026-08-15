class_name Estados
extends RefCounted

## LO QUE DURA EN EL TIEMPO: veneno, escarcha, brasa, marca, frenesí.
##
## POR QUÉ EXISTE, que es lo importante. Los cascabeles se montaron como bolsa de
## modificadores —reutilizando el sistema de reliquias, que encajaba limpio— y
## salieron medidos y equilibrados y **completamente invisibles**: un ×1,19 al
## daño no se ve mientras juegas. La causa no era el número, era la forma: **una
## bolsa de modificadores solo sabe producir porcentajes.** Para que PASEN COSAS
## hacen falta eventos, y esto es la capa de eventos.
##
## NADIE ESCRIBE UN `if` POR ESTADO, igual que nadie escribe uno por misión.
## `Combate._apuntar(tiro)` ya sabe qué tiro acaba de pasar, y ahí le pregunta a
## la bolsa por `aplica_<estado>_<tiro>`. Un estado nuevo es una fila más en
## `data/estados.json`; una build nueva es una clave más en una reliquia.
##
## LOS EFECTOS SON DATOS, NO CASOS. Una definición puede traer cualquier
## combinación de: daño por tic, freno del reloj, daño al expirar, crítico
## garantizado y suma de probabilidad de crítico. El bucle de abajo los aplica
## todos sin saber cuál es cuál, así que "hielo" y "veneno" son el mismo código
## con otros números.

const RUTA := "res://data/estados.json"

class Definicion extends RefCounted:
	var id: String = ""
	var nombre: String = ""
	var simbolo: String = ""
	var color: String = ""
	var sobre: String = "enemigo"
	var texto: String = ""
	var duracion: float = 5.0
	var refresca: bool = true
	var periodo: float = 0.0
	var dano_tick: float = 0.0
	var dano_al_expirar: float = 0.0
	var factor_reloj_por_acumulacion: float = 0.0
	var factor_reloj_suelo: float = 0.25
	var critico_garantizado: bool = false
	var suma_critico_por_acumulacion: float = 0.0
	var max_acumulaciones: int = 20

	func _init(d: Dictionary) -> void:
		id = str(d.get("id", ""))
		nombre = str(d.get("nombre", id))
		simbolo = str(d.get("simbolo", id.to_upper().substr(0, 3)))
		color = str(d.get("color", "verde"))
		sobre = str(d.get("sobre", "enemigo"))
		texto = str(d.get("texto", ""))
		duracion = float(d.get("duracion", 5.0))
		refresca = bool(d.get("refresca", true))
		periodo = float(d.get("periodo", 0.0))
		dano_tick = float(d.get("dano_tick", 0.0))
		dano_al_expirar = float(d.get("dano_al_expirar", 0.0))
		factor_reloj_por_acumulacion = float(d.get("factor_reloj_por_acumulacion", 0.0))
		factor_reloj_suelo = float(d.get("factor_reloj_suelo", 0.25))
		critico_garantizado = bool(d.get("critico_garantizado", false))
		suma_critico_por_acumulacion = float(d.get("suma_critico_por_acumulacion", 0.0))
		max_acumulaciones = int(d.get("max_acumulaciones", 20))

class Activo extends RefCounted:
	var def: Definicion
	var acumulaciones: int = 0
	var restante: float = 0.0
	var _hasta_tic: float = 0.0

	func _init(d: Definicion) -> void:
		def = d
		_hasta_tic = d.periodo

static var _defs: Array = []

static func definiciones() -> Array:
	if not _defs.is_empty():
		return _defs
	var f := FileAccess.open(RUTA, FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir %s" % RUTA)
		return []
	var crudo: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(crudo) != TYPE_DICTIONARY or not (crudo as Dictionary).has("estados"):
		push_error("%s no tiene la forma esperada" % RUTA)
		return []
	var lista: Array = []
	for d in (crudo as Dictionary)["estados"]:
		lista.append(Definicion.new(d as Dictionary))
	_defs = lista
	return _defs

static func definicion(el_id: String) -> Definicion:
	for d in definiciones():
		if (d as Definicion).id == el_id:
			return d
	return null

## Los ids, para el bucle que pregunta a la bolsa. Se calcula una vez: se llama
## en cada tiro y recorrer el JSON entero por golpe es tirar el fotograma.
static var _ids: PackedStringArray = PackedStringArray()

static func ids() -> PackedStringArray:
	if _ids.is_empty():
		for d in definiciones():
			_ids.append((d as Definicion).id)
	return _ids

# ------------------------------------------------------------------- estado

var activos: Dictionary = {}

func limpiar() -> void:
	activos.clear()

func acumulaciones(el_id: String) -> int:
	if not activos.has(el_id):
		return 0
	return (activos[el_id] as Activo).acumulaciones

func tiene(el_id: String) -> bool:
	return acumulaciones(el_id) > 0

## Los que están encendidos, ordenados como el JSON. Para el HUD: un estado que
## el jugador no ve no existe, y se diagnostica como que no funciona — es la
## avería del platillo, que ya costó un run entero de confusión.
func lista() -> Array:
	var salida: Array = []
	for d in definiciones():
		var el_id := (d as Definicion).id
		if activos.has(el_id) and (activos[el_id] as Activo).acumulaciones > 0:
			salida.append(activos[el_id])
	return salida

## Aplica `n` acumulaciones. Devuelve cuántas ha metido de verdad, que puede ser
## menos por el tope: quien llama lo necesita para no anunciar un efecto que no
## ha entrado.
func aplicar(el_id: String, n: int) -> int:
	if n <= 0:
		return 0
	var d := definicion(el_id)
	if d == null:
		return 0
	if not activos.has(el_id):
		activos[el_id] = Activo.new(d)
	var a := activos[el_id] as Activo
	var antes := a.acumulaciones
	a.acumulaciones = mini(a.acumulaciones + n, d.max_acumulaciones)
	# LA BRASA NO REFRESCA, y es la decisión que hace que exista. Si refrescara,
	# seguirías echándole brasas y no estallaría nunca: el estado más vistoso del
	# juego no se vería jamás. Sin refresco, la cuenta atrás arranca con la
	# primera y lo que decides es cuántas metes antes de que reviente.
	if d.refresca or a.restante <= 0.0:
		a.restante = d.duracion
	return a.acumulaciones - antes

## Un tic de reloj. Devuelve lo que ha pasado, y NO toca al enemigo: quien
## reparte daño es `Combate`, que es el único que sabe de multiplicadores,
## señales y muertes. Un sistema que se pusiera a hacer daño por su cuenta se
## saltaría el crítico, la misión y el contador de la bola.
##
##   { "dano": int, "estallidos": [ids que acaban de reventar] }
func avanzar(dt: float) -> Dictionary:
	var dano := 0.0
	var estallidos: Array = []
	var muertos: Array = []
	for el_id in activos:
		var a := activos[el_id] as Activo
		if a.acumulaciones <= 0:
			continue
		# El daño por tic. Va en periodos fijos y no proporcional a `dt` para que
		# el veneno haga lo mismo a 60 que a 120 fotogramas, y para que se pueda
		# oír: un goteo continuo no suena, un tic sí.
		if a.def.periodo > 0.0 and a.def.dano_tick > 0.0:
			a._hasta_tic -= dt
			while a._hasta_tic <= 0.0:
				a._hasta_tic += a.def.periodo
				dano += a.def.dano_tick * float(a.acumulaciones)
		a.restante -= dt
		if a.restante <= 0.0:
			if a.def.dano_al_expirar > 0.0:
				dano += a.def.dano_al_expirar * float(a.acumulaciones)
				estallidos.append(el_id)
			muertos.append(el_id)
	for el_id in muertos:
		activos.erase(el_id)
	return {"dano": int(round(dano)), "estallidos": estallidos}

# --------------------------------------------------------------- consultas

## Cuánto frena el reloj del enemigo. Neutro 1,0, con suelo para que la escarcha
## no pueda pararlo del todo: un reloj parado quita la única presión continua que
## tiene el juego.
func factor_reloj() -> float:
	var f := 1.0
	for el_id in activos:
		var a := activos[el_id] as Activo
		if a.acumulaciones <= 0 or is_zero_approx(a.def.factor_reloj_por_acumulacion):
			continue
		f += a.def.factor_reloj_por_acumulacion * float(a.acumulaciones)
		f = maxf(f, a.def.factor_reloj_suelo)
	return maxf(f, 0.05)

## Lo que suman al crítico los estados del jugador.
func suma_critico() -> float:
	var s := 0.0
	for el_id in activos:
		var a := activos[el_id] as Activo
		if a.acumulaciones > 0:
			s += a.def.suma_critico_por_acumulacion * float(a.acumulaciones)
	return s

## Gasta una marca si la hay. Devuelve si este golpe es crítico seguro.
func consumir_critico() -> bool:
	for el_id in activos:
		var a := activos[el_id] as Activo
		if a.def.critico_garantizado and a.acumulaciones > 0:
			a.acumulaciones -= 1
			if a.acumulaciones <= 0:
				activos.erase(el_id)
			return true
	return false
