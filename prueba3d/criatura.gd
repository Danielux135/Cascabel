extends RefCounted

## PRUEBA 3D — una criatura de la caza. SOLO ESTADO: quién es, dónde está y qué
## le pasa. No sabe dibujarse ni moverse sola: la mueve `caza_orbita.gd`, que es
## quien ve la mesa, y la dibuja `criatura_3d.gd`, que solo lee esto.
##
## Es un círculo, igual que la bola: se mide con `radio`.

enum Estado {
	FUERA,        ## no está en la mesa: esperando a entrar, partida o ya asegurada
	APARECER,     ## saliendo: aún no se la puede tocar
	CORRER,       ## a lo suyo, de nodo en nodo
	ALERTA,       ## ha visto venir la bola: se agacha un instante antes de huir
	HUIR,         ## corre al nodo más lejano de las bolas
	VOLAR,        ## la han golpeado: va sin control hasta que se frena
	ATURDIDA,     ## en el suelo, viendo estrellas
	ACORRALADA,   ## (LUMI) miedo lleno: se encoge donde está. Tocarla la recoge
	VOLCADA,      ## (TANQUE) panza arriba, pataleando. Tocarlo lo recoge
	ESCONDIDA,    ## (LUMI) dentro del agujero de gusano: ni se la ve ni se la toca
	EN_BOLA,      ## recogida: va dentro de una bola, camino de una pala
}

# ------------------------------------------------------------------- quién es

var indice := 0
## "corredor", "saltarin", "gotita" o "escarabajo".
var especie := "corredor"
var nombre := "CRIATURA"
## En píxeles de mesa. La bola mide 9.
var radio := 12.0
## Respecto a la bola, que pesa 1. Por debajo de 1 la bola la manda lejos y
## sigue su camino; por encima, la bola rebota en ella.
var masa := 0.5
var rebote := 0.5
var v_correr := 90.0
var v_huir := 180.0
## Las que saltan no andan: avanzan a botes. Largo y duración del bote, y lo que
## se quedan posadas entre uno y otro paseando y huyendo.
var salta := false
var bote_largo := 40.0
var bote_tiempo := 0.30
var posada_paseo := 0.25
var posada_huida := 0.10
## Para las mitades de GOTA: el índice de la entera. −1 si no es una mitad.
var madre := -1
## ¿Cuenta en el marcador? Las mitades no: cuenta la entera.
var principal := true
## ¿Está en juego? Se quita y se pone con las teclas de la prueba.
var activa := true

# ------------------------------------------------------------------ qué le pasa

var estado: int = Estado.FUERA
var t_estado := 0.0
var pos := Vector2.ZERO
var vel := Vector2.ZERO
## En qué capa de altura está, con los mismos números que la bola.
var capa: int = Colisionador.CAPA_TABLERO
## Hacia dónde mira el cuerpo. Unitario.
var rumbo := Vector2.DOWN
## El punto de la mesa que está mirando con los ojos (la bola, casi siempre).
var mira := Vector2.ZERO

## De 0 a 1. Solo lo usa LUMI: no tiene vida, tiene miedo.
var miedo := 0.0
var golpes := 0
## Ya está a salvo en una pala. Es el final bueno.
var asegurada := false
## (GOTA) ahora mismo está partida en dos mitades.
var partida := false
var t_partida := 0.0
## (mitades) van al centro a juntarse.
var reuniendose := false
## La bola que la lleva dentro mientras está EN_BOLA.
var portadora: Bola = null

## Navegación: de qué nodo viene y a cuál va. Andando, su sitio es el segmento
## entre donde está y el nodo de destino, que siempre está libre.
var nodo := -1
var destino := -1

## El bote de las que saltan: de 0 a 1 mientras está en el aire, −1 posada.
var bote_u := -1.0
var bote_reloj := 0.0
var bote_resto := 0.0
var bote_total := 1.0
## (TANQUE) el golpe que lleva lo va a dejar panza arriba al aterrizar.
var volcando := false
## La ha apartado una bola lenta: al parar vuelve a lo suyo, sin estrellas.
var empujada := false

# Relojes de quien la mueve. Están aquí porque son de ESTA criatura.
var espera := 0.0
var t_recarga := 0.0
var t_empujon := 0.0
var t_refugio := 0.0
var t_huyendo := 0.0
var t_sin_bola := 0.0
var t_realerta := 0.0
var t_vigia := 0.0
var pos_vigia := Vector2.ZERO
var t_cierre := 0.0
## Por qué boca del túnel entró y por cuál va a salir (índices de boca).
var boca_entrada := -1
var boca_salida := -1
var asoma_avisado := false
## Miedo con el que vuelve si se escapa de la bola.
var miedo_al_volver := 0.0

func cambiar(nuevo: int) -> void:
	estado = nuevo
	t_estado = 0.0

## ¿Está en la mesa y la bola puede tocarla?
func golpeable() -> bool:
	return estado == Estado.CORRER or estado == Estado.ALERTA \
		or estado == Estado.HUIR or estado == Estado.VOLAR \
		or estado == Estado.ATURDIDA or estado == Estado.ACORRALADA \
		or estado == Estado.VOLCADA

## ¿Basta con tocarla, a cualquier velocidad, para recogerla?
func rendida() -> bool:
	if estado == Estado.ACORRALADA or estado == Estado.VOLCADA:
		return true
	return especie == "gotita" and golpeable() and t_recarga <= 0.0

func a_la_vista() -> bool:
	return estado != Estado.FUERA and estado != Estado.ESCONDIDA

func a_pie() -> bool:
	return estado == Estado.CORRER or estado == Estado.HUIR
