
extends RefCounted

## PRUEBA 3D — generadores de malla.
##
## Todo lo que hay en la mesa es una CÁPSULA (`Colisionador`: segmento a→b con un
## radio; con a == b, un círculo). Así que casi toda la geometría 3D sale de una
## sola función, `estadio`, que levanta esa misma cápsula hasta una altura. El
## arte y el colisionador son la misma medida por construcción: no hay modelo que
## pueda quedarse viejo cuando se mueva un dial.
##
## Las coordenadas de entrada son las de la mesa 2D (píxeles, Y hacia abajo). La
## conversión es una sola: `a3`.

## Un píxel de la mesa son 0,01 unidades 3D: la mesa mide 4 × 13.
const E := 0.01

static func a3(v: Vector2, h: float = 0.0) -> Vector3:
	return Vector3(v.x * E, h, v.y * E)

# ------------------------------------------------------------------ triángulos

## Añade un triángulo con la cara vista hacia donde apuntan sus normales. Godot
## toma como cara vista la que va en sentido horario, y decidirlo a mano en cada
## generador es la forma segura de dejar media mesa del revés.
static func _tri(st: SurfaceTool, col: Color,
		p0: Vector3, p1: Vector3, p2: Vector3,
		n0: Vector3, n1: Vector3, n2: Vector3) -> void:
	if (p1 - p0).cross(p2 - p0).dot(n0 + n1 + n2) > 0.0:
		var tp := p1
		p1 = p2
		p2 = tp
		var tn := n1
		n1 = n2
		n2 = tn
	st.set_color(col)
	st.set_normal(n0)
	st.set_uv(Vector2(p0.x, p0.z))
	st.add_vertex(p0)
	st.set_normal(n1)
	st.set_uv(Vector2(p1.x, p1.z))
	st.add_vertex(p1)
	st.set_normal(n2)
	st.set_uv(Vector2(p2.x, p2.z))
	st.add_vertex(p2)

static func _cuadro(st: SurfaceTool, col: Color,
		p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
		n0: Vector3, n1: Vector3, n2: Vector3, n3: Vector3) -> void:
	_tri(st, col, p0, p1, p2, n0, n1, n2)
	_tri(st, col, p0, p2, p3, n0, n2, n3)

# -------------------------------------------------------------------- contorno

## El contorno 2D de una cápsula, con la normal de cada punto. Devuelve
## `[puntos, normales]`.
static func contorno(a: Vector2, b: Vector2, r: float, seg: int) -> Array:
	var pts := PackedVector2Array()
	var nrm := PackedVector2Array()
	var d := b - a
	if d.length_squared() < 1e-6:
		for i in seg * 2:
			var ang := TAU * float(i) / float(seg * 2)
			var n := Vector2(cos(ang), sin(ang))
			pts.append(a + n * r)
			nrm.append(n)
		return [pts, nrm]
	var base := d.angle()
	for i in seg + 1:
		var ang := base - PI * 0.5 + PI * float(i) / float(seg)
		var n := Vector2(cos(ang), sin(ang))
		pts.append(b + n * r)
		nrm.append(n)
	for i in seg + 1:
		var ang := base + PI * 0.5 + PI * float(i) / float(seg)
		var n := Vector2(cos(ang), sin(ang))
		pts.append(a + n * r)
		nrm.append(n)
	return [pts, nrm]

# --------------------------------------------------------------------- estadio

## Una cápsula levantada de `y0` a `y1`, con el canto de arriba biselado.
## `a`, `b` y `r` en píxeles de mesa; las alturas y el bisel, en unidades 3D.
static func estadio(st: SurfaceTool, a: Vector2, b: Vector2, r: float,
		y0: float, y1: float, bisel: float, col_lado: Color, col_tapa: Color,
		seg: int = 5) -> void:
	bisel = minf(bisel, (y1 - y0) * 0.5)
	var r_int := maxf(r - bisel / E, r * 0.35)
	var fuera: Array = contorno(a, b, r, seg)
	var dentro: Array = contorno(a, b, r_int, seg)
	var pe: PackedVector2Array = fuera[0]
	var ne: PackedVector2Array = fuera[1]
	var pi: PackedVector2Array = dentro[0]
	var ym := y1 - bisel
	var arriba := Vector3.UP
	var centro := a3((a + b) * 0.5, y1)
	var n := pe.size()
	for i in n:
		var j := (i + 1) % n
		var ni := Vector3(ne[i].x, 0.0, ne[i].y)
		var nj := Vector3(ne[j].x, 0.0, ne[j].y)
		_cuadro(st, col_lado,
			a3(pe[i], y0), a3(pe[j], y0), a3(pe[j], ym), a3(pe[i], ym),
			ni, nj, nj, ni)
		var bi := (ni + arriba).normalized()
		var bj := (nj + arriba).normalized()
		_cuadro(st, col_tapa.lerp(col_lado, 0.35),
			a3(pe[i], ym), a3(pe[j], ym), a3(pi[j], y1), a3(pi[i], y1),
			bi, bj, bj, bi)
		_tri(st, col_tapa, centro, a3(pi[i], y1), a3(pi[j], y1),
			arriba, arriba, arriba)

# ---------------------------------------------------------------------- prisma

## Un polígono levantado de `y0` a `y1`, con las caras planas. Para losas.
static func prisma(st: SurfaceTool, poligono: PackedVector2Array,
		y0: float, y1: float, col_lado: Color, col_tapa: Color) -> void:
	var centro := Vector2.ZERO
	for pt in poligono:
		centro += pt
	centro /= float(poligono.size())
	var n := poligono.size()
	for i in n:
		var p := poligono[i]
		var q := poligono[(i + 1) % n]
		var d := (q - p).normalized()
		var perp := Vector2(-d.y, d.x)
		if perp.dot((p + q) * 0.5 - centro) < 0.0:
			perp = -perp
		var nn := Vector3(perp.x, 0.0, perp.y)
		_cuadro(st, col_lado,
			a3(p, y0), a3(q, y0), a3(q, y1), a3(p, y1), nn, nn, nn, nn)
	var tri := Geometry2D.triangulate_polygon(poligono)
	for i in range(0, tri.size(), 3):
		_tri(st, col_tapa,
			a3(poligono[tri[i]], y1), a3(poligono[tri[i + 1]], y1),
			a3(poligono[tri[i + 2]], y1),
			Vector3.UP, Vector3.UP, Vector3.UP)

static func caja(st: SurfaceTool, r: Rect2, y0: float, y1: float,
		col_lado: Color, col_tapa: Color) -> void:
	prisma(st, PackedVector2Array([
		r.position, Vector2(r.end.x, r.position.y),
		r.end, Vector2(r.position.x, r.end.y),
	]), y0, y1, col_lado, col_tapa)

# ------------------------------------------------------------------------ tubo

## Un tubo a lo largo de una línea 3D. Para los raíles de las rampas.
static func tubo(st: SurfaceTool, pts: PackedVector3Array, radio: float,
		col: Color, lados: int = 6) -> void:
	var n := pts.size()
	if n < 2:
		return
	var anillos: Array = []
	var normales: Array = []
	for i in n:
		var tg := (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var lateral := tg.cross(Vector3.UP)
		if lateral.length_squared() < 1e-6:
			lateral = Vector3.RIGHT
		lateral = lateral.normalized()
		var alto := lateral.cross(tg).normalized()
		var anillo := PackedVector3Array()
		var nrm := PackedVector3Array()
		for k in lados:
			var ang := TAU * float(k) / float(lados)
			var dir := lateral * cos(ang) + alto * sin(ang)
			anillo.append(pts[i] + dir * radio)
			nrm.append(dir)
		anillos.append(anillo)
		normales.append(nrm)
	for i in n - 1:
		var a0: PackedVector3Array = anillos[i]
		var a1: PackedVector3Array = anillos[i + 1]
		var n0: PackedVector3Array = normales[i]
		var n1: PackedVector3Array = normales[i + 1]
		for k in lados:
			var k2 := (k + 1) % lados
			_cuadro(st, col, a0[k], a0[k2], a1[k2], a1[k],
				n0[k], n0[k2], n1[k2], n1[k])

## Un disco plano mirando arriba. Para bocas de túnel, platillos e insertos.
static func disco(st: SurfaceTool, centro: Vector2, r: float, y: float,
		col: Color, seg: int = 16) -> void:
	var c := a3(centro, y)
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		_tri(st, col, c,
			a3(centro + Vector2(cos(a0), sin(a0)) * r, y),
			a3(centro + Vector2(cos(a1), sin(a1)) * r, y),
			Vector3.UP, Vector3.UP, Vector3.UP)

## Una corona plana mirando arriba. Para los anillos pintados en el tablero.
static func anillo(st: SurfaceTool, centro: Vector2, r_int: float, r_ext: float,
		y: float, col: Color, seg: int = 40) -> void:
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		_cuadro(st, col,
			a3(centro + d0 * r_int, y), a3(centro + d0 * r_ext, y),
			a3(centro + d1 * r_ext, y), a3(centro + d1 * r_int, y),
			Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP)

## Una cinta plana a lo largo de una línea 3D, con UV pensadas para un shader
## que fluye: `UV.x` cruza la cinta de 0 a 1 y `UV.y` es la distancia recorrida,
## en unidades 3D. `ancho` en unidades 3D.
static func cinta(st: SurfaceTool, pts: PackedVector3Array, ancho: float) -> void:
	var n := pts.size()
	if n < 2:
		return
	var izq := PackedVector3Array()
	var der := PackedVector3Array()
	var dist := PackedFloat32Array()
	var d := 0.0
	for i in n:
		if i > 0:
			d += pts[i - 1].distance_to(pts[i])
		var tg := (pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var lateral := tg.cross(Vector3.UP)
		if lateral.length_squared() < 1e-6:
			lateral = Vector3.RIGHT
		lateral = lateral.normalized() * ancho * 0.5
		izq.append(pts[i] - lateral)
		der.append(pts[i] + lateral)
		dist.append(d)
	for i in n - 1:
		var esquinas := [izq[i], der[i], der[i + 1], izq[i], der[i + 1], izq[i + 1]]
		var uvs := [Vector2(0.0, dist[i]), Vector2(1.0, dist[i]),
			Vector2(1.0, dist[i + 1]), Vector2(0.0, dist[i]),
			Vector2(1.0, dist[i + 1]), Vector2(0.0, dist[i + 1])]
		for k in 6:
			st.set_color(Color.WHITE)
			st.set_normal(Vector3.UP)
			st.set_uv(uvs[k])
			st.add_vertex(esquinas[k])
