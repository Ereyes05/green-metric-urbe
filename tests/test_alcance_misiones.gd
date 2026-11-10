# Se llega caminando a todas las misiones y NPCs desde el spawn.
#
# El 2026-11-09 el commit "limites completados" (91f1372) agregó 51
# colisiones de árboles y objetos; tres árboles del pasillo entre los
# Bloques E y F dejaban 18 px de paso — justo la altura del jugador — y el
# punto LED del Bloque E (obligatorio para el Nivel 2) quedó encerrado sin
# que ninguna prueba lo notara. Esta prueba recorre el mapa en una grilla de
# 5 px con la forma real del jugador y avisa qué punto no se alcanza.
# Correr: $GODOT --headless --path . res://tests/test_alcance_misiones.tscn
extends Node

const GRUPOS := ["zona_tierra", "punto_energia", "zona_reciclaje", "llave_agua",
	"punto_captacion", "punto_movilidad", "punto_malla_verde", "punto_comite_ambiental",
	"punto_semana_verde", "punto_informe_final", "npcs_mapa"]
const PASO    := 5.0     # grilla del recorrido
const ALCANCE := 55.0    # RADIO_DETEC de los puntos (el más chico)

var _fallos := 0
var _jug_rid : RID


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _libre(space: PhysicsDirectSpaceState2D, cs: CollisionShape2D, mask: int, p: Vector2) -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = cs.shape
	q.transform = Transform2D(0.0, p + cs.position)
	q.collision_mask = mask
	q.collide_with_areas = false
	q.exclude = [_jug_rid]
	return space.intersect_shape(q, 1).is_empty()


func _ready() -> void:
	print("test_alcance_misiones")
	NivelManager._misiones = {}
	for nv in range(1, 7):
		var h := {}
		for m in NivelManager.MISIONES_NIVEL[nv]: h[m] = true
		NivelManager._misiones[str(nv)] = h
	NivelManager.nivel_actual = 6
	var mapa = load("res://scenes/mapa/scene_mapa_mundo.tscn").instantiate()
	add_child(mapa)
	await get_tree().create_timer(3.0).timeout
	for i in 3: await get_tree().physics_frame

	var jug : CharacterBody2D = mapa.get_node("Jugador")
	var cs : CollisionShape2D = jug.get_node("CollisionShape2D")
	_jug_rid = jug.get_rid()
	var space := jug.get_world_2d().direct_space_state
	# Siempre desde el spawn por defecto, no desde una posición guardada.
	var origen : Vector2 = mapa.to_global(Vector2(mapa.SPAWN_X, mapa.SPAWN_Y))
	_check(_libre(space, cs, jug.collision_mask, origen), "el spawn por defecto está libre")

	var visit := {Vector2i.ZERO: true}
	var cola : Array[Vector2i] = [Vector2i.ZERO]
	while not cola.is_empty():
		var c : Vector2i = cola.pop_back()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nc : Vector2i = c + d
			if visit.has(nc) or absi(nc.x) > 640 or absi(nc.y) > 400: continue
			if _libre(space, cs, jug.collision_mask, origen + Vector2(nc) * PASO):
				visit[nc] = true
				cola.append(nc)

	var total := 0
	var r := int(ceil(ALCANCE / PASO))
	for g in GRUPOS:
		for n in get_tree().get_nodes_in_group(g):
			total += 1
			var base := Vector2i(((n.global_position - origen) / PASO).round())
			var llega := false
			for dx in range(-r, r + 1):
				for dy in range(-r, r + 1):
					var celda := base + Vector2i(dx, dy)
					if visit.has(celda) and (origen + Vector2(celda) * PASO).distance_to(n.global_position) <= ALCANCE:
						llega = true
			if not llega:
				var nombre : String = str(n.get("mision_id")) if n.get("mision_id") != null else str(n.name)
				_check(false, "se llega caminando a %s (%s) en %s" % [nombre, g, n.global_position - mapa.global_position])
	_check(total >= 50, "se revisaron %d puntos de misión y NPCs" % total)

	print("test_alcance_misiones: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
