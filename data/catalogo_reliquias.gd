class_name CatalogoReliquias
extends RefCounted

## Carga data/reliquias.json. Igual que `CatalogoEnemigos`: la lectura de
## fichero vive aquí y no en `sim/`, para que `sim/` siga sin tocar nada del
## sistema de archivos y se pueda medir sin motor de recursos.

const RUTA := "res://data/reliquias.json"

## Devuelve `Array[Reliquia]`. Vacío si el fichero no está o no tiene la forma
## esperada: un run sin reliquias sigue jugándose, solo que sin ellas.
static func cargar() -> Array[Reliquia]:
	var lista: Array[Reliquia] = []
	var f := FileAccess.open(RUTA, FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir %s" % RUTA)
		return lista
	var crudo: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(crudo) != TYPE_DICTIONARY or not (crudo as Dictionary).has("reliquias"):
		push_error("%s no tiene la forma esperada" % RUTA)
		return lista
	for datos in (crudo as Dictionary)["reliquias"]:
		var d: Dictionary = (datos as Dictionary).duplicate()
		# El eje se escribe con palabras en el JSON y se guarda como enum: en el
		# fichero tiene que poder leerse, en el código tiene que poder compararse.
		d["eje"] = Reliquia.eje_desde(str(d.get("eje", "combo")))
		# La rareza comparte enum con las misiones: una misión de rareza N
		# paga una reliquia de rareza N.
		d["rareza"] = Mision.rareza_desde(str(d.get("rareza", "comun")))
		lista.append(Reliquia.new(d))
	return lista

static func por_rareza(rareza: int) -> Array[Reliquia]:
	var lista: Array[Reliquia] = []
	for r in cargar():
		if r.rareza == rareza:
			lista.append(r)
	return lista

static func por_id(el_id: String) -> Reliquia:
	for r in cargar():
		if r.id == el_id:
			return r
	return null
