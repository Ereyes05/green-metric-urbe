# Quieto contra caminando, con los 6 niveles completos. No es una prueba.
# $GODOT --path . --resolution 1280x720 res://tests/perf/medir_caminar.tscn
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
	add_child(_mapa)
	await get_tree().create_timer(4.0).timeout
	for vuelta in 2:
		await _tramo("quieto", "")
		await _tramo("caminando →", "mover_derecha")
		await _tramo("caminando ←", "mover_izquierda")
	get_tree().quit()

func _tramo(nombre: String, accion: String) -> void:
	if accion != "": Input.action_press(accion)
	for i in 10: await get_tree().process_frame
	var P := Performance
	var t0 := Time.get_ticks_usec()
	var proc := 0.0
	var fis := 0.0
	for i in 90:
		await get_tree().process_frame
		proc += P.get_monitor(P.TIME_PROCESS)
		fis += P.get_monitor(P.TIME_PHYSICS_PROCESS)
	var ms := (Time.get_ticks_usec() - t0) / 90.0 / 1000.0
	if accion != "": Input.action_release(accion)
	var pos : Vector2 = _mapa.jugador.global_position
	print("%-12s cuadro %.2f ms  process %.2f ms  física %.2f ms  pares %d  draw %d  jugador %s" % [nombre, ms,
		proc / 90.0 * 1000.0, fis / 90.0 * 1000.0, P.get_monitor(P.PHYSICS_2D_COLLISION_PAIRS),
		P.get_monitor(P.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), str(pos.round())])
