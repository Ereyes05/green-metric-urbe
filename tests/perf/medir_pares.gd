# Qué Area2D/cuerpos generan los pares de colisión. No es una prueba.
extends Node

func _ready() -> void:
	var mapa = load("res://scenes/mapa/scene_mapa_mundo.tscn").instantiate()
	add_child(mapa)
	await get_tree().create_timer(3.0).timeout
	var cuenta := {}
	_ver(mapa, cuenta)
	for k in cuenta: print("  %4d  %s" % [cuenta[k], k])
	print("jugador capa ", mapa.jugador.collision_layer, " máscara ", mapa.jugador.collision_mask)
	print("pares: ", Performance.get_monitor(Performance.PHYSICS_2D_COLLISION_PAIRS))
	get_tree().quit()

func _ver(n: Node, c: Dictionary) -> void:
	if n is CollisionObject2D:
		var k := "%s capa=%d máscara=%d%s%s" % [n.get_class(), n.collision_layer, n.collision_mask,
			("  monitoring" if n is Area2D and n.monitoring else ""),
			("  monitorable" if n is Area2D and n.monitorable else "")]
		c[k] = c.get(k, 0) + 1
	for h in n.get_children(): _ver(h, c)
