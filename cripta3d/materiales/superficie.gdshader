shader_type spatial;
// Sin el especular de Godot: lo pone `luz_godot.gdshaderinc`, que va dentro.
render_mode specular_disabled;

// CRIPTA 3D — la superficie opaca de la mesa. El código entero vive en
// `superficie.gdshaderinc`; este fichero solo dice cómo se pinta.
//
// ES EL ÚNICO PROGRAMA DE SUPERFICIE QUE COMPILA LA MESA. Había otro igual con
// `cull_disabled` («superficie_doble»): 8,8 s más de compilar en un navegador
// por un modo de render que no pedía ningún módulo, así que ya no existe (ver
// «doble_cara» en `biblioteca.gd`). Pasarlo todo a dos caras tampoco vale: la
// bóveda es de UNA cara a propósito, para que la cámara cenital la atraviese.
// Los programas con DEPURA o REFLEJO los arma la biblioteca al vuelo, sin
// fichero, y solo los compila quien los pide.

#include "res://cripta3d/materiales/superficie.gdshaderinc"
