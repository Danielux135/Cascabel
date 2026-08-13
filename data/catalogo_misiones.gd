class_name CatalogoMisiones
extends RefCounted

## Carga data/misiones.json. Igual que los otros catálogos: la lectura de
## fichero vive aquí y no en `sim/`.

const RUTA := "res://data/misiones.json"

static func cargar() -> Array[Mision]:
	var lista: Array[Mision] = []
	var f := FileAccess.open(RUTA, FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir %s" % RUTA)
		return lista
	var crudo: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(crudo) != TYPE_DICTIONARY or not (crudo as Dictionary).has("misiones"):
		push_error("%s no tiene la forma esperada" % RUTA)
		return lista
	for datos in (crudo as Dictionary)["misiones"]:
		var d: Dictionary = (datos as Dictionary).duplicate(true)
		d["rareza"] = Mision.rareza_desde(str(d.get("rareza", "comun")))
		lista.append(Mision.new(d))
	return lista

static func por_rareza(rareza: int) -> Array[Mision]:
	var lista: Array[Mision] = []
	for m in cargar():
		if m.rareza == rareza:
			lista.append(m)
	return lista
