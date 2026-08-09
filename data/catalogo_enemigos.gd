class_name CatalogoEnemigos
extends RefCounted

## Carga data/enemigos.json. La lectura de fichero vive aquí y no en sim/, para
## que sim/ siga sin tocar nada del sistema de archivos.

const RUTA := "res://data/enemigos.json"

static func cargar() -> Array:
	var f := FileAccess.open(RUTA, FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir %s" % RUTA)
		return []
	var crudo: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(crudo) != TYPE_DICTIONARY or not (crudo as Dictionary).has("enemigos"):
		push_error("%s no tiene la forma esperada" % RUTA)
		return []
	return (crudo as Dictionary)["enemigos"]

static func por_id(id: String) -> Dictionary:
	for datos in cargar():
		if str((datos as Dictionary).get("id", "")) == id:
			return datos
	return {}
