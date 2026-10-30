# Mide el costo por cuadro de la pantalla de login (no es una prueba).
# $GODOT --path . --resolution 1280x720 res://tests/perf/medir_login.tscn
extends Node

func _ready() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var login = load("res://scenes/login/scene_login.tscn").instantiate()
	add_child(login)
	await get_tree().create_timer(3.0).timeout
	var P := Performance
	print("draw calls: ", P.get_monitor(P.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"  primitivas: ", P.get_monitor(P.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"  nodos: ", P.get_monitor(P.OBJECT_NODE_COUNT))
	var base := await _medir()
	print("cuadro con todo: %.2f ms" % base)
	for n in _animados(login):
		n.set_process(false)
		n.queue_redraw()
		var m := await _medir()
		print("  sin %s: %.2f ms  (draw calls %d, primitivas %d)" % [n.get_script().resource_path.get_file() if n.get_script() else n.name,
			m, P.get_monitor(P.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), P.get_monitor(P.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
		n.visible = false
		var m2 := await _medir()
		print("  y oculto: %.2f ms  (draw calls %d)" % [m2, P.get_monitor(P.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
		n.visible = true
		n.set_process(true)
	get_tree().quit()

func _animados(n: Node) -> Array:
	var out := []
	if n is CanvasItem and n.is_processing() and n.get_script() and n != get_child(0):
		out.append(n)
	for h in n.get_children():
		out.append_array(_animados(h))
	return out

func _medir() -> float:
	for i in 10:
		await get_tree().process_frame
	var t0 := Time.get_ticks_usec()
	for i in 120:
		await get_tree().process_frame
	return (Time.get_ticks_usec() - t0) / 120.0 / 1000.0
