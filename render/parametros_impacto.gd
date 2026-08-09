class_name ParametrosImpacto
extends RefCounted

## Los tres efectos de impacto: onda expansiva, polvo y chispas. Todo por
## código, sin sprites.
##
## Se dibujan en píxeles enteros, como el resto: son formas geométricas encima
## de pixelart, y a medio píxel se ven sucias justo en el fotograma en el que
## más se miran.
##
## Los números están para tocarlos. La regla al ajustar: el polvo es lento y
## apagado, las chispas son rápidas y brillantes, y la onda dura menos que las
## dos. Si la onda dura más, tapa el golpe en vez de marcarlo.

# --- Onda expansiva ---
## Un anillo que sale disparado y se afina. Marca DÓNDE ha sido el golpe.
var onda_duracion: float = 0.22
var onda_radio_inicial: float = 6.0
var onda_radio_final: float = 34.0
var onda_grosor_inicial: float = 3.0
var onda_grosor_final: float = 1.0
var onda_alfa: float = 0.75

# --- Polvo ---
## Cuadraditos lentos que se posan. Da peso al golpe; sin él todo suena a
## metal. Casi no cae: es polvo, no grava.
var polvo_cantidad: int = 7
var polvo_duracion: float = 0.55
var polvo_velocidad: float = 90.0
var polvo_dispersion: float = 0.9      # radianes a cada lado de la dirección
var polvo_frenado: float = 3.4         # v *= exp(-frenado * dt)
var polvo_gravedad: float = 120.0
var polvo_tamano: int = 3              # lado en px, entero
var polvo_crecimiento: int = 2         # cuánto engorda antes de irse
var polvo_alfa: float = 0.50

# --- Chispas ---
## Rápidas, brillantes y con estela. Son las que hacen que el golpe se sienta
## metálico. La estela se dibuja del sitio anterior al actual: sin ella, a 340
## px/s son puntos parpadeando.
var chispa_cantidad: int = 9
var chispa_duracion: float = 0.30
var chispa_velocidad: float = 340.0
var chispa_variacion: float = 0.5      # 0..1 de variación sobre la velocidad
var chispa_dispersion: float = 1.1
var chispa_frenado: float = 5.0
var chispa_gravedad: float = 900.0     # estas sí caen, y rápido
var chispa_grosor: float = 1.0

## Tope de partículas vivas. Con un racimo de bumpers se acumulan rápido, y
## más allá de esto ya no se distingue nada: solo cuesta.
var maximo_particulas: int = 260
