extends SceneTree

## CRIPTA 3D — genera las texturas de ruido de la biblioteca de materiales.
##
##     python cripta3d/herramientas/godot3d.py guion res://cripta3d/materiales/generar_texturas.gd --lineas 20
##     python cripta3d/herramientas/godot3d.py importar --lineas 5
##
## Tarda cosa de un minuto. Deja tres PNG de 512 en `cripta3d/texturas/`, cada
## uno con su ficha de importación (mipmaps, sin compresión con pérdida y sin
## «arreglo» del borde alfa, que aquí el alfa es un dato y no una transparencia).
##
## POR QUÉ SON PNG Y NO `NoiseTexture2D`: una textura de ruido de Godot se
## calcula al arrancar, en un hilo. En web no hay hilos, así que el juego se
## quedaría parado medio minuto generando ruido antes de enseñar nada. Esto se
## calcula UNA vez, aquí, y lo que viaja es una imagen.
##
## POR QUÉ TRES Y NO UNA POR MATERIAL: la mesa entera va con un solo sombreador
## (`superficie.gdshaderinc`) y este lee nueve veces por píxel: tres texturas,
## cada una en triplanar. Cada lectura trae cuatro canales con cuatro cosas
## distintas, así que por esas nueve lecturas salen doce ruidos:
##
##   ruido_grano.png    R  relieve fino (lomas, aristas y hoyos)
##                      G  su pendiente en u   } el relieve ya DERIVADO: la normal
##                      B  su pendiente en v   } sale de una lectura, no de tres
##                      A  moteado (ecualizado)
##   ruido_celdas.png   R  martillado: cuencos de Voronoi con el canto suave
##                      G  su pendiente en u
##                      B  su pendiente en v
##                      A  distancia a la grieta (raíz, para afinar cerca de 0)
##   ruido_manchas.png  R  variación grande (ecualizada)
##                      G  mugre, más rota (ecualizada)
##                      B  venas: crestas finas (ecualizada)
##                      A  hondonadas: lo que se encharca (ecualizada)
##
## «Ecualizado» quiere decir que el canal reparte sus valores por igual entre 0
## y 1. Así un umbral ES una cobertura: cortar en 0,7 deja el 30 % de la
## superficie, en cualquier material y a cualquier escala, y los mandos de
## «suciedad», «desgaste» y «mojado» se pueden leer como porcentajes.
##
## SIN COSTURAS, Y CÓMO: FastNoiseLite no sabe hacer ruido periódico. Lo que se
## hace es leer el ruido en cuatro sitios —el píxel y sus tres copias una tesela
## más allá— y mezclarlos con pesos que valen 0 justo en el borde. La mezcla
## normal aplana el centro (ahí se promedian cuatro ruidos y la variación cae a
## la mitad): se ve una cruz lisa en cada tesela. Dividir por la raíz de la suma
## de los pesos al cuadrado devuelve el contraste a su sitio. Y por eso todo lo
## que NO es lineal (crestas, hoyos, ecualizar) se hace DESPUÉS de mezclar:
## cuatro crestas promediadas son cuatro fantasmas, no una cresta.

const TAM := 512
const CARPETA := "res://cripta3d/texturas/"

var _pesos := PackedFloat32Array()

func _init() -> void:
	var t0 := Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CARPETA))
	_pesos.resize(TAM)
	for i in TAM:
		var u := float(i) / float(TAM)
		_pesos[i] = u * u * (3.0 - 2.0 * u)
	_grano()
	print("TEXTURAS: grano a los %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	_celdas()
	print("TEXTURAS: celdas a los %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	_manchas()
	print("TEXTURAS: manchas a los %.1f s. Ahora: godot3d.py importar" % (
		(Time.get_ticks_msec() - t0) / 1000.0))
	quit()

# ------------------------------------------------------------------ las piezas

func _ruido(semilla: int, ciclos: float, octavas: int = 1, ganancia: float = 0.5) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.seed = semilla
	n.frequency = ciclos / float(TAM)
	if octavas > 1:
		n.fractal_type = FastNoiseLite.FRACTAL_FBM
		n.fractal_octaves = octavas
		n.fractal_gain = ganancia
		n.fractal_lacunarity = 2.0
	else:
		n.fractal_type = FastNoiseLite.FRACTAL_NONE
	return n

## Una capa de ruido sin costuras, centrada en 0 (ver la cabecera).
func _capa(n: FastNoiseLite) -> PackedFloat32Array:
	var t := float(TAM)
	# La media se quita antes de mezclar: si no, dividir por la raíz de los pesos
	# la amplifica en el centro y vuelve a salir la cruz, ahora de brillo.
	var media := 0.0
	for j in 40:
		for i in 40:
			media += n.get_noise_2d((float(i) + 0.37) * t / 20.0 - t, (float(j) + 0.61) * t / 20.0 - t)
	media /= 1600.0
	var d := PackedFloat32Array()
	d.resize(TAM * TAM)
	var k := 0
	for y in TAM:
		var fy := float(y)
		var b := _pesos[y]
		var b1 := 1.0 - b
		for x in TAM:
			var fx := float(x)
			var a := _pesos[x]
			var a1 := 1.0 - a
			var w00 := a1 * b1
			var w10 := a * b1
			var w01 := a1 * b
			var w11 := a * b
			var v := n.get_noise_2d(fx, fy) * w00 + n.get_noise_2d(fx - t, fy) * w10 \
				+ n.get_noise_2d(fx, fy - t) * w01 + n.get_noise_2d(fx - t, fy - t) * w11
			d[k] = (v - media) / sqrt(w00 * w00 + w10 * w10 + w01 * w01 + w11 * w11)
			k += 1
	return d

## Octavas sueltas, cada una al doble de frecuencia que la anterior: para poder
## doblarlas (crestas) una a una después de mezclar.
func _octavas(semilla: int, ciclos: float, cuantas: int) -> Array[PackedFloat32Array]:
	var lista: Array[PackedFloat32Array] = []
	for o in cuantas:
		lista.append(_capa(_ruido(semilla + o * 101, ciclos * pow(2.0, float(o)))))
	return lista

## Estira a 0..1 recortando las colas: un pico suelto no se come el rango.
func _normalizar(d: PackedFloat32Array, recorte: float = 0.002) -> void:
	var orden := d.duplicate()
	orden.sort()
	var n := orden.size()
	var lo := orden[int(recorte * float(n))]
	var hi := orden[n - 1 - int(recorte * float(n))]
	var ancho := maxf(hi - lo, 0.000001)
	for k in n:
		d[k] = clampf((d[k] - lo) / ancho, 0.0, 1.0)

## Reparte los valores por igual entre 0 y 1: cada uno pasa a ser su puesto en
## la lista ordenada. Es lo que convierte un umbral en una cobertura.
func _ecualizar(d: PackedFloat32Array) -> void:
	var orden := d.duplicate()
	orden.sort()
	var n := float(orden.size())
	for k in d.size():
		d[k] = float(orden.bsearch(d[k])) / n

## La pendiente de un relieve, con vuelta en los bordes, ya escalada para que
## llene el rango −1..1: el percentil «recorte» del módulo vale 1 y lo que pasa
## de ahí se recorta. Con hoyos, el tope lo ponen sus paredes y el resto del
## relieve se queda en cuatro grises: por eso el grano recorta antes.
func _pendiente(h: PackedFloat32Array, recorte: float = 0.998) -> Array[PackedFloat32Array]:
	var gx := PackedFloat32Array()
	var gy := PackedFloat32Array()
	gx.resize(TAM * TAM)
	gy.resize(TAM * TAM)
	var modulos := PackedFloat32Array()
	modulos.resize(TAM * TAM)
	for y in TAM:
		var y0 := y * TAM
		var ya := ((y + TAM - 1) % TAM) * TAM
		var yb := ((y + 1) % TAM) * TAM
		for x in TAM:
			var xa := (x + TAM - 1) % TAM
			var xb := (x + 1) % TAM
			# Sobel: la diferencia central, repartida con las dos filas vecinas. A
			# pelo, la pendiente sale con el grano del píxel y la normal chispea.
			var dx := (h[y0 + xb] - h[y0 + xa]) * 0.5 + (h[ya + xb] - h[ya + xa]) * 0.25 \
				+ (h[yb + xb] - h[yb + xa]) * 0.25
			var dy := (h[yb + x] - h[ya + x]) * 0.5 + (h[yb + xa] - h[ya + xa]) * 0.25 \
				+ (h[yb + xb] - h[ya + xb]) * 0.25
			gx[y0 + x] = dx
			gy[y0 + x] = dy
			modulos[y0 + x] = maxf(absf(dx), absf(dy))
	modulos.sort()
	var tope := maxf(modulos[int(recorte * float(TAM * TAM))], 0.000001)
	for k in TAM * TAM:
		gx[k] = clampf(gx[k] / tope, -1.0, 1.0) * 0.5 + 0.5
		gy[k] = clampf(gy[k] / tope, -1.0, 1.0) * 0.5 + 0.5
	print("    pendiente: tope %.4f por píxel (%.1f por tesela)" % [tope, tope * float(TAM)])
	return [gx, gy]

func _guardar(nombre: String, r: PackedFloat32Array, g: PackedFloat32Array,
		b: PackedFloat32Array, a: PackedFloat32Array) -> void:
	var bytes := PackedByteArray()
	bytes.resize(TAM * TAM * 4)
	for k in TAM * TAM:
		bytes[k * 4] = int(clampf(r[k], 0.0, 1.0) * 255.0 + 0.5)
		bytes[k * 4 + 1] = int(clampf(g[k], 0.0, 1.0) * 255.0 + 0.5)
		bytes[k * 4 + 2] = int(clampf(b[k], 0.0, 1.0) * 255.0 + 0.5)
		# NUNCA un alfa de 0: un compresor sin pérdida puede tirar el color de un
		# píxel del todo transparente, y aquí ese «color» son tres ruidos.
		bytes[k * 4 + 3] = maxi(int(clampf(a[k], 0.0, 1.0) * 255.0 + 0.5), 1)
	var img := Image.create_from_data(TAM, TAM, false, Image.FORMAT_RGBA8, bytes)
	var ruta := CARPETA + nombre + ".png"
	var err := img.save_png(ProjectSettings.globalize_path(ruta))
	print("  %s: %s" % [ruta, "guardada" if err == OK else "ERROR %d" % err])
	_ficha(ruta)

## La ficha de importación, si no existe. Godot respeta los parámetros que
## encuentra y rellena el resto. Los cuatro que importan:
##   - sin pérdida: S3TC/ETC2 hacen bloques de 4×4 y una pendiente en bloques es
##     una normal a escalones;
##   - con mipmaps: sin ellos el relieve chispea en cuanto se aleja la cámara;
##   - sin «arreglar» el borde alfa: ese arreglo repinta el color de los píxeles
##     con alfa bajo, y aquí serían tres canales de ruido machacados;
##   - sin detección 3D: el editor, al ver la textura en una malla, la
##     recomprime él solo a VRAM y deshace lo primero.
func _ficha(ruta: String) -> void:
	var ficha := ProjectSettings.globalize_path(ruta + ".import")
	if FileAccess.file_exists(ficha):
		return
	var f := FileAccess.open(ficha, FileAccess.WRITE)
	if f == null:
		print("  no puedo escribir ", ficha)
		return
	f.store_string("[remap]\n\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\n\n[params]\n\n"
		+ "compress/mode=0\nmipmaps/generate=true\nprocess/fix_alpha_border=false\n"
		+ "process/premult_alpha=false\ndetect_3d/compress_to=0\n")
	f.close()

# ------------------------------------------------------------------- el grano

## El relieve fino. Seis octavas, cada una mitad loma y mitad cresta —así hay
## bulto y hay arista a la vez—, y encima hoyos: pocos, hondos y en racimos, que
## es lo que distingue una piedra picada de un ruido.
func _grano() -> void:
	# Las octavas gordas, casi apagadas: el grano es GRANO. Enteras, de lejos
	# —cuando el mipmap ya se ha comido lo fino— lo único que queda de la normal
	# son bultos del tamaño de la pieza, y una esfera con bultos y el contorno
	# redondo canta a falso (y todos los materiales parecen el mismo barro). El
	# bulto, cuando hace falta, sale de las celdas, que tienen su propio mando.
	const PESO_OCTAVA: Array[float] = [0.15, 0.35, 0.7, 1.0, 1.0, 1.0]
	var oct := _octavas(1101, 5.0, 6)
	var hoyos := _capa(_ruido(2203, 54.0))
	var racimo := _capa(_ruido(2311, 3.0, 3, 0.5))
	var h := PackedFloat32Array()
	h.resize(TAM * TAM)
	for k in TAM * TAM:
		var v := 0.0
		var amp := 1.0
		for o in oct.size():
			var l := oct[o][k]
			v += amp * PESO_OCTAVA[o] * (l * 0.6 + (0.25 - absf(l)) * 0.4)
			amp *= 0.6
		var hoyo := smoothstep(0.50, 0.86, hoyos[k]) * smoothstep(0.0, 0.5, racimo[k])
		h[k] = v - hoyo * 0.55
	_normalizar(h)
	var g := _pendiente(h, 0.985)
	var mota := _capa(_ruido(3307, 9.0, 5, 0.55))
	_ecualizar(mota)
	_guardar("ruido_grano", h, g[0], g[1], mota)

# ------------------------------------------------------------------ las celdas

## Voronoi periódico, hecho a mano: aquí sí hace falta que sea exacto, porque
## una grieta mezclada con otra son dos grietas fantasma.
##   - El martillado es el mínimo SUAVE de unos cuencos (uno por punto, cada uno
##     con su tamaño y su fondo): cuencos que se pisan y dejan un caballón romo
##     entre dos, que es como queda el hierro batido.
##   - La grieta es la distancia de verdad al borde de la celda (el método de
##     Íñigo Quílez), no F2−F1, que engorda en las esquinas.
##   - El dominio va deformado por un ruido periódico: sin eso los bordes son
##     rectas y se lee «panal», no «roto».
func _celdas() -> void:
	const N := 11
	const M := N + 4
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var bx := PackedFloat32Array()
	var by := PackedFloat32Array()
	var bp := PackedFloat32Array()
	var bf := PackedFloat32Array()
	bx.resize(N * N)
	by.resize(N * N)
	bp.resize(N * N)
	bf.resize(N * N)
	for j in N:
		for i in N:
			bx[j * N + i] = float(i) + 0.5 + (rng.randf() - 0.5) * 0.86
			by[j * N + i] = float(j) + 0.5 + (rng.randf() - 0.5) * 0.86
			bp[j * N + i] = rng.randf_range(0.75, 1.4)
			bf[j * N + i] = rng.randf_range(0.0, 0.10)
	# La misma tabla con dos celdas de borde por cada lado, ya desplazadas: así el
	# bucle de dentro no hace módulos.
	var px := PackedFloat32Array()
	var py := PackedFloat32Array()
	var pp := PackedFloat32Array()
	var pf := PackedFloat32Array()
	px.resize(M * M)
	py.resize(M * M)
	pp.resize(M * M)
	pf.resize(M * M)
	for j in M:
		for i in M:
			var ii := posmod(i - 2, N)
			var jj := posmod(j - 2, N)
			px[j * M + i] = bx[jj * N + ii] + float(i - 2 - ii)
			py[j * M + i] = by[jj * N + ii] + float(j - 2 - jj)
			pp[j * M + i] = bp[jj * N + ii]
			pf[j * M + i] = bf[jj * N + ii]
	var dx_ := _capa(_ruido(5101, 5.0, 3, 0.5))
	var dy_ := _capa(_ruido(5207, 5.0, 3, 0.5))
	var h := PackedFloat32Array()
	var grieta := PackedFloat32Array()
	h.resize(TAM * TAM)
	grieta.resize(TAM * TAM)
	var rx := PackedFloat32Array()
	var ry := PackedFloat32Array()
	rx.resize(25)
	ry.resize(25)
	const DUREZA := 9.0
	var k := 0
	for y in TAM:
		for x in TAM:
			var u := fposmod((float(x) + 0.5) / float(TAM) * float(N) + dx_[k] * 0.42, float(N))
			var v := fposmod((float(y) + 0.5) / float(TAM) * float(N) + dy_[k] * 0.42, float(N))
			var ci := int(u)
			var cj := int(v)
			var mejor := 1.0e9
			var cual := 0
			var suma := 0.0
			var c := 0
			for dj in 5:
				var fila := (cj + dj) * M + ci
				for di in 5:
					var idx := fila + di
					var ex := px[idx] - u
					var ey := py[idx] - v
					rx[c] = ex
					ry[c] = ey
					var d2 := ex * ex + ey * ey
					if d2 < mejor:
						mejor = d2
						cual = c
					suma += exp(-DUREZA * (d2 * pp[idx] + pf[idx]))
					c += 1
			# El tope blando: donde tres celdas dejan un claro grande, el mínimo
			# sube sin freno y salía un pico suelto que se comía el rango entero.
			h[k] = 0.5 * (1.0 - exp(log(maxf(suma, 1.0e-30)) / DUREZA / 0.5))
			var mx := rx[cual]
			var my := ry[cual]
			var borde := 1.0e9
			for c2 in 25:
				if c2 == cual:
					continue
				var qx := rx[c2] - mx
				var qy := ry[c2] - my
				var largo := sqrt(qx * qx + qy * qy)
				if largo < 0.0001:
					continue
				var d := ((mx + rx[c2]) * qx + (my + ry[c2]) * qy) * 0.5 / largo
				if d < borde:
					borde = d
			# La raíz reparte los 8 bits donde hacen falta: una grieta vive entre 0
			# y 0,1 de celda, y sin esto serían veinte escalones.
			grieta[k] = sqrt(clampf(borde / 0.6, 0.0, 1.0))
			k += 1
	_normalizar(h, 0.001)
	var g := _pendiente(h)
	_guardar("ruido_celdas", h, g[0], g[1], grieta)

# ----------------------------------------------------------------- las manchas

func _manchas() -> void:
	var grande := _capa(_ruido(7001, 2.5, 4, 0.5))
	_ecualizar(grande)
	var mugre := _capa(_ruido(7103, 4.0, 5, 0.62))
	_ecualizar(mugre)
	var oct := _octavas(7211, 3.0, 4)
	var venas := PackedFloat32Array()
	venas.resize(TAM * TAM)
	for k in TAM * TAM:
		var v := 0.0
		var amp := 1.0
		for o in oct.size():
			v += amp * (0.3 - absf(oct[o][k]))
			amp *= 0.5
		venas[k] = v
	_ecualizar(venas)
	var hondo := _capa(_ruido(7309, 1.7, 3, 0.45))
	_ecualizar(hondo)
	_guardar("ruido_manchas", grande, mugre, venas, hondo)
