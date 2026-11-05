# indicador_misiones.gd — flechita "▼" sobre las misiones pendientes.
#
# Señala en el mapa dónde están las misiones del nivel actual que faltan.
# Solo dibuja: no agrega botones, teclas ni pantallas. Una misión deja de
# tener flecha al completarse; con el jugador al lado se esconde (ahí ya
# aparece el aviso [E]).
#
# Los puntos de misión son hijos directos del mapa con la propiedad
# mision_id; el nivel de cada uno sale de NivelManager.misiones_nivel. La
# oficina del Nivel 5 no tiene mision_id: se la reconoce por tipo.
extends Node2D

const ALTO_SOBRE_PUNTO := 34.0
const DIST_OCULTAR := 70.0
const REBOTE := 5.0
const COLOR := Color(1.0, 0.86, 0.20)
const BORDE := Color(0.10, 0.08, 0.02, 0.85)

var _objetivos : Array[Node2D] = []
var _t := 0.0
var _buscar_en := 0.0


func _ready() -> void:
	z_index = 50
	top_level = true


func _process(delta: float) -> void:
	_t += delta
	_buscar_en -= delta
	if _buscar_en <= 0.0:
		_buscar_en = 1.0
		_buscar()
	queue_redraw()


func _buscar() -> void:
	_objetivos = pendientes(get_parent(), get_node_or_null("/root/NivelManager"))


# Puntos del mapa con misiones del nivel actual que faltan. También la usa
# el minimapa (scenes/ui/minimapa.gd) para sus puntos rojos.
static func pendientes(mapa: Node, nm) -> Array[Node2D]:
	var out : Array[Node2D] = []
	if nm == null or mapa == null:
		return out
	var nivel := nivel_actual(nm)
	if nivel == 0:
		return out
	var ids : Array = nm.misiones_nivel.get(nivel, [])
	for n in mapa.get_children():
		if not (n is Node2D) or not n.is_visible_in_tree():
			continue
		var es_oficina : bool = nivel == 5 and str(n.get("tipo")) == "oficina"
		if not es_oficina and not (str(n.get("mision_id")) in ids):
			continue
		if n.get("_completada") == true or n.get("_completado") == true:
			continue
		if n.get("estado") != null and n.get("estado") != "pendiente":
			continue
		if not es_oficina and nm.mision_completada_q(nivel, n.get("mision_id")):
			continue
		out.append(n)
	return out


static func nivel_actual(nm) -> int:
	for n in range(1, 7):
		if nm.nivel_desbloqueado(n) and not nm.nivel_completo(n):
			return n
	return 0


func _draw() -> void:
	var jugador := get_tree().get_first_node_in_group("jugador") as Node2D
	var dy := -absf(sin(_t * 3.0)) * REBOTE
	for o in _objetivos:
		if not is_instance_valid(o):
			continue
		var p := o.global_position
		if jugador and jugador.global_position.distance_to(p) < DIST_OCULTAR:
			continue
		# Anillo que late alrededor del punto: en la prueba de usabilidad una
		# estudiante no encontraba las misiones del Nivel 2 solo con la flecha.
		var latido := 0.5 + 0.5 * sin(_t * 3.0)
		draw_arc(p, 22.0 + 4.0 * latido, 0.0, TAU, 32,
			Color(COLOR, 0.35 + 0.35 * (1.0 - latido)), 2.5, true)
		var punta := p + Vector2(0, -ALTO_SOBRE_PUNTO - 4.0 + dy)
		var tri := PackedVector2Array([punta, punta + Vector2(-12, -16), punta + Vector2(12, -16)])
		draw_colored_polygon(tri, COLOR)
		tri.append(punta)
		draw_polyline(tri, BORDE, 2.0, true)
