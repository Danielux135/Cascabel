class_name BolsaReliquias
extends RefCounted

## Las reliquias que llevas y cómo se acumulan sus modificadores.
##
## ESTA CLASE ES LA QUE HACE QUE LAS RELIQUIAS NO SEAN CUARENTA Y CINCO CASOS
## ESPECIALES. `Combate` no sabe qué reliquias existen: pregunta por una clave y
## le sale un número. Una bolsa vacía devuelve el neutro de cada tipo, así que el
## combate sin reliquias se comporta exactamente igual que antes y las medidas
## viejas siguen valiendo.
##
## Reglas de acumulación, decididas por el prefijo de la clave:
##   suma_*    se suman
##   factor_*  se multiplican, partiendo de 1,0
##   bandera_* basta con que una la lleve
##
## Y dos sufijos/campos que evitan escribir código por reliquia:
##
## `_por_victoria` aplica el efecto una vez por combate ganado. Es el eje de
## ESCALADO entero. Ojo a la diferencia: en las sumas el escalado se SUMA a la
## base, y en los factores se suma AL FACTOR (o sea, no compuesto), que es lo que
## impide que una reliquia de escalado se dispare a mitad del run.
##
## `cuando` apaga y enciende la reliquia según el estado del combate. Es el
## gancho de "pasivos condicionales" de `DISEÑO.md` §10, y es lo que permite que
## una reliquia diga algo más interesante que "+X": *mientras vayas bajo de
## vida*, *mientras el reloj esté a punto de sonar*, *mientras no hayas drenado*.
## La condición se evalúa contra un CONTEXTO que publica `Combate`; si el
## contexto no trae el dato, la condición se da por falsa, que es el lado seguro:
## una reliquia apagada se nota; una encendida sin motivo descuadra el balance.

const SUFIJO_VICTORIA := "_por_victoria"

var reliquias: Array[Reliquia] = []
## Combates ganados en el run. Lo lleva `Run`, y es de lo único que depende el
## eje de escalado.
var victorias: int = 0
## Lo que pasa ahora mismo en el combate, para las reliquias condicionales. Lo
## rellena `Combate` y nadie más.
var contexto: Dictionary = {}
## Para lo que tenga azar. Va aquí y no en `Combate` porque el azar es de las
## reliquias: sin reliquias de caos, nadie lo llama.
var rng := RandomNumberGenerator.new()

func _init(semilla: int = 0) -> void:
	rng.seed = semilla if semilla != 0 else 20260812

func tiene(el_id: String) -> bool:
	for r in reliquias:
		if r.id == el_id:
			return true
	return false

func anadir(r: Reliquia) -> bool:
	if r == null or tiene(r.id):
		return false
	reliquias.append(r)
	return true

func vacia() -> bool:
	return reliquias.is_empty()

func nombres() -> Array[String]:
	var lista: Array[String] = []
	for r in reliquias:
		lista.append(r.nombre)
	return lista

# ------------------------------------------------------------- condiciones

## ¿Está encendida esta reliquia ahora mismo?
##
## Las condiciones se resuelven aquí y no en `Combate` a propósito: `Combate`
## publica QUÉ ESTÁ PASANDO y las reliquias deciden si eso les interesa. Al
## revés —que el combate supiera qué reliquia quiere qué— es justo la avería que
## este sistema existe para evitar.
func activa(r: Reliquia) -> bool:
	if r.cuando == "":
		return true
	match r.cuando:
		"vida_baja": return _menor("vida", r.umbral)
		"vida_alta": return _mayor("vida", r.umbral)
		"combo_alto": return _mayor("multiplicador", r.umbral)
		"sin_combo": return _igual("multiplicador", 1.0)
		"reloj_cargado": return _mayor("reloj", r.umbral)
		"reloj_frio": return _menor("reloj", r.umbral)
		"enemigo_tocado": return _menor("enemigo", r.umbral)
		"enemigo_intacto": return _mayor("enemigo", r.umbral)
		"sin_drenar": return _igual("drenajes", 0.0)
	return false

## Las condiciones son la única parte del sistema que puede equivocarse en
## silencio: un `cuando` mal escrito apagaría la reliquia para siempre sin dar
## error. Por eso hay una lista cerrada y una prueba que la comprueba.
const CONDICIONES := ["vida_baja", "vida_alta", "combo_alto", "sin_combo",
	"reloj_cargado", "reloj_frio", "enemigo_tocado", "enemigo_intacto",
	"sin_drenar"]

func _menor(clave: String, umbral: float) -> bool:
	return contexto.has(clave) and float(contexto[clave]) <= umbral

func _mayor(clave: String, umbral: float) -> bool:
	return contexto.has(clave) and float(contexto[clave]) >= umbral

func _igual(clave: String, valor: float) -> bool:
	return contexto.has(clave) and is_equal_approx(float(contexto[clave]), valor)

# ------------------------------------------------------------- acumulación

## Todo lo que suma esta clave, contando el escalado por victorias y saltándose
## las reliquias apagadas.
func suma(clave: String, base: float = 0.0) -> float:
	var total := base
	for r in reliquias:
		if not activa(r):
			continue
		total += float(r.efectos.get(clave, 0.0))
		total += float(r.efectos.get(clave + SUFIJO_VICTORIA, 0.0)) * float(victorias)
	return total

## Todo lo que multiplica esta clave. Neutro 1,0.
func factor(clave: String) -> float:
	var f := 1.0
	var extra := 0.0
	for r in reliquias:
		if not activa(r):
			continue
		f *= float(r.efectos.get(clave, 1.0))
		extra += float(r.efectos.get(clave + SUFIJO_VICTORIA, 0.0)) * float(victorias)
	return maxf(f + extra, 0.0)

func bandera(clave: String) -> bool:
	for r in reliquias:
		if activa(r) and bool(r.efectos.get(clave, false)):
			return true
	return false

## Tira un dado contra una probabilidad acumulada. Con probabilidad 0 no se
## consume azar: sin reliquias de caos la simulación sigue siendo determinista,
## que es lo que permite comparar dos medidas.
func azar(clave: String, base: float = 0.0) -> bool:
	var prob := suma(clave, base)
	if prob <= 0.0:
		return false
	return rng.randf() < prob
