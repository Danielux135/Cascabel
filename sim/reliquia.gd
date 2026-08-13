class_name Reliquia
extends RefCounted

## Una reliquia: lo que llevas encima durante un run. `DISEÑO.md` §10.
##
## LO QUE UNA RELIQUIA NO ES: código. Aquí no hay cuarenta y cinco casos
## especiales repartidos por `Combate`. Una reliquia es una BOLSA DE MODIFICADORES con
## nombre, y el combate pregunta por esos modificadores en los sitios donde ya
## tomaba decisiones. Si una reliquia nueva necesita un `if` nuevo en `Combate`,
## es que el gancho no existía todavía: se añade el gancho, no el caso.
##
## Los modificadores llevan el prefijo escrito en el nombre y eso decide cómo se
## acumulan (ver `bolsa_reliquias.gd`):
##
##   suma_*    se suman entre todas las reliquias que lo lleven
##   factor_*  se multiplican entre sí, partiendo de 1,0
##   bandera_* basta que una lo lleve
##
## Y cualquier clave que acabe en `_por_victoria` es la misma clave aplicada una
## vez por cada combate ganado en el run: ahí vive el eje de ESCALADO sin
## necesitar código aparte.

## `DISEÑO.md` §8. El eje no hace nada mecánicamente: sirve para poder mirar la
## lista entera y ver que no son cuarenta y cinco "+2 de daño", y para pintar
## de qué va una reliquia antes de leerla.
enum Eje { COMBO, GOLPE_UNICO, SUPERVIVENCIA, ESCALADO, CAOS }

const NOMBRE_EJE := {
	Eje.COMBO: "combo",
	Eje.GOLPE_UNICO: "golpe unico",
	Eje.SUPERVIVENCIA: "supervivencia",
	Eje.ESCALADO: "escalado",
	Eje.CAOS: "caos",
}

var id: String
var nombre: String
## Qué hace, en una línea y en lenguaje de jugador. Es lo que se lee al
## elegirla, así que no lleva nombres de parámetros.
var texto: String
var eje: int
## En qué momento actúa, con las palabras de `DISEÑO.md` §10. Solo para
## enseñarlo: quien decide cuándo se aplica es la clave del efecto.
var gancho: String
var efectos: Dictionary
## Condición para que la reliquia esté encendida. Vacío = siempre. Las palabras
## válidas están en `BolsaReliquias.CONDICIONES`, y hay una prueba que lo
## comprueba: un `cuando` mal escrito apagaría la reliquia para siempre sin dar
## error, que es la avería más cara de este sistema.
var cuando: String
## El número contra el que se compara la condición. Qué significa depende de la
## condición: fracción de vida, de reloj, o multiplicador.
var umbral: float
## Icono de 64. Vacío mientras no exista el arte: la tarjeta se dibuja igual.
var icono: String
## Común, rara o arcana. Comparte enum con `Mision` a propósito: una misión de
## rareza N paga una reliquia de rareza N, y tenerlo en dos escalas distintas
## sería la manera más rápida de que dejaran de cuadrar.
##
## LA RAREZA NO ES CUÁNTO SUBE UN NÚMERO, ES CUÁNTO CAMBIA LA PARTIDA. Una que
## da +12 de daño a los targets es común aunque sume mucho; una que hace que el
## racimo cobre del multiplicador es arcana aunque el número sea pequeño, porque
## te cambia a qué tiro vas, que es el pilar (`DISEÑO.md` §1).
var rareza: int

func _init(datos: Dictionary) -> void:
	id = str(datos.get("id", ""))
	nombre = str(datos.get("nombre", "?"))
	texto = str(datos.get("texto", ""))
	eje = int(datos.get("eje", Eje.COMBO))
	gancho = str(datos.get("gancho", ""))
	efectos = (datos.get("efectos", {}) as Dictionary).duplicate()
	cuando = str(datos.get("cuando", ""))
	umbral = float(datos.get("umbral", 0.0))
	icono = str(datos.get("icono", ""))
	rareza = int(datos.get("rareza", Mision.Rareza.COMUN))

## Ruta del icono al tamaño que se pida, o "" si esta reliquia aún no tiene arte.
func ruta_icono(lado: int = 64) -> String:
	if icono == "":
		return ""
	return "res://assets/reliquias%s/%s.png" % ["_32" if lado == 32 else "", icono]

func nombre_eje() -> String:
	return str(NOMBRE_EJE.get(eje, "?"))

static func eje_desde(texto_eje: String) -> int:
	for clave in NOMBRE_EJE:
		if str(NOMBRE_EJE[clave]) == texto_eje:
			return int(clave)
	return Eje.COMBO
