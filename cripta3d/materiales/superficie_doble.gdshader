shader_type spatial;
render_mode cull_disabled;

// CRIPTA 3D — la misma superficie, a dos caras: para chapas, cadenas planas y
// cualquier malla abierta a la que se le ve el revés. Se pide con la variante
// «doble_cara». Es un programa aparte, así que solo donde haga falta.

#include "res://cripta3d/materiales/superficie.gdshaderinc"
