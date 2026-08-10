class_name Paleta
extends RefCounted

## La paleta cerrada de CONTEXTO.md, en un solo sitio.
##
## Antes cada archivo que dibujaba se copiaba su propio bloque de constantes:
## `vista_mesa`, `nodo_hud`, `nodo_suelo` y `nodo_escritorio` repetían los
## mismos hex, así que cambiar un color obligaba a acordarse de los cuatro.
##
## REGLA: ningún `Color("...")` suelto fuera de este archivo. Si hace falta un
## color que no está aquí, no se inventa: o se usa el más cercano, o se añade a
## la paleta de CONTEXTO.md a propósito y luego aquí. Hay una prueba que lo
## comprueba (`_prueba_paleta`).
##
## Los nombres de tramo son los de CONTEXTO.md. Debajo van los alias por USO,
## que son los que se escriben al dibujar: así se ve para qué sirve un color
## sin tener que acordarse del hex.

# --- Neutros ---
const NEGRO      := Color("14121A")
const GRIS_1     := Color("2A2A33")
const GRIS_2     := Color("43434F")
const GRIS_3     := Color("62636F")
const GRIS_4     := Color("8C8D99")
const GRIS_5     := Color("B9BAC4")
const BLANCO     := Color("E4E6EC")

# --- Piedra ---
const PIEDRA_1   := Color("3A3832")
const PIEDRA_2   := Color("55524A")
const PIEDRA_3   := Color("7A7669")
const PIEDRA_4   := Color("A09B8A")

# --- Tierra ---
const TIERRA_1   := Color("2B2028")
const TIERRA_2   := Color("4A3A42")
const TIERRA_3   := Color("755F52")
const TIERRA_4   := Color("A88968")
const TIERRA_5   := Color("D9BF95")
const TIERRA_6   := Color("F5E9CE")

# --- Rojos ---
const ROJO       := Color("8C2E2E")
const ROJO_LUZ   := Color("C74A3C")
const NARANJA    := Color("E8814A")

# --- Oro ---
const ORO_OSCURO := Color("8A6524")
const ORO        := Color("E0A63C")
const ORO_CLARO  := Color("F7D86B")

# --- Cobre ---
const COBRE_1    := Color("6B3A22")
const COBRE_2    := Color("A0603A")
const COBRE_3    := Color("C98A4B")

# --- Verdes ---
const VERDE_1    := Color("2F5A38")
const VERDE_2    := Color("4E7C3A")
const VERDE      := Color("7BA84A")

# --- Azules ---
const AZUL       := Color("274A63")
const AZUL_LUZ   := Color("4478A0")

# --- Arcano: el único color mágico. Con cuentagotas. ---
const ARCANO_1   := Color("6B3F9E")
const ARCANO     := Color("A97BD9")

## Los 33 de la paleta, para que la prueba pueda comprobar pertenencia.
const TODOS: Array[Color] = [
	NEGRO, GRIS_1, GRIS_2, GRIS_3, GRIS_4, GRIS_5, BLANCO,
	PIEDRA_1, PIEDRA_2, PIEDRA_3, PIEDRA_4,
	TIERRA_1, TIERRA_2, TIERRA_3, TIERRA_4, TIERRA_5, TIERRA_6,
	ROJO, ROJO_LUZ, NARANJA,
	ORO_OSCURO, ORO, ORO_CLARO,
	COBRE_1, COBRE_2, COBRE_3,
	VERDE_1, VERDE_2, VERDE,
	AZUL, AZUL_LUZ,
	ARCANO_1, ARCANO,
]

# ---------------------------------------------------------------- alias por uso
# Lo que se escribe al dibujar. Cambiar aquí repinta todo el juego.

const CABINA      := NEGRO       # el mueble, y el fondo de todo
const MESA        := GRIS_1      # el tablero
const MESA_BAJA   := GRIS_2      # zona baja, un punto más clara
## Los boquetes del tablero. Estaba en 1C1A22, que NO es de la paleta: era un
## intermedio inventado entre el negro y el gris del tablero. Se va al negro,
## que además es lo que se ve de verdad por un agujero: el mueble.
const HUECO       := NEGRO
const PARED       := GRIS_4
const PARED_LUZ   := GRIS_5
const CARRIL      := AZUL
const GOMA        := ROJO        # slingshots y gomas
const GOMA_LUZ    := ROJO_LUZ
const DRENAJE     := TIERRA_2
const PIEDRA      := PIEDRA_3
const FUEGO       := NARANJA

const FLIPPER       := GRIS_1
const FLIPPER_BORDE := NEGRO
const FLIPPER_LINEA := BLANCO
const METAL         := GRIS_4
const METAL_LUZ     := BLANCO

const TEXTO       := GRIS_5
const TEXTO_TENUE := GRIS_3
const DESTELLO    := BLANCO      # el blanco de la paleta, NO el blanco puro
