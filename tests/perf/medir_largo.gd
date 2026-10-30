# Caminata larga: ¿algo se acumula? No es una prueba.
extends Node

var _mapa

func _ready() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var todo := {}
	for n in range(1, 7):
		var d := {}
		for id in NivelManager.misiones_nivel.get(n, []): d[id] = true
		todo[str(n)] = d
	NivelManager._misiones = todo
	_mapa = load("res://scenes/mapa/scene_mapa_mundo.tscn").instantiate()
	add_child(mapa_ref())
	await get_tree().create_timer(4.0).timeout
	var P := Performance
	var dirs := ["mover_derecha", "mover_abajo", "mover_izquierda", "mover_arriba"]
	for tramo in 12:
		var acc : String = dirs[tramo % 4]
		Input.action_press(acc)
		var t0 := Time.get_ticks_usec()
		for i in 150: await get_tree().process_frame
		Input.action_release(acc)
		print("tramo %2d  %.2f ms  nodos %d  objetos %d  memoria %.1f MB  tweens? huérfanos %d" % [tramo,
			(Time.get_ticks_usec() - t0) / 150.0 / 1000.0, P.get_monitor(P.OBJECT_NODE_COUNT),
			P.get_monitor(P.OBJECT_COUNT), P.get_monitor(P.MEMORY_STATIC) / 1048576.0,
			P.get_monitor(P.OBJECT_ORPHAN_NODE_COUNT)])
	get_tree().quit()

func mapa_ref(): return _mapa
