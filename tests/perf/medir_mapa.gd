# Mide el costo por cuadro del mapa (no es una prueba: imprime números).
# $GODOT --path . --resolution 1280x720 res://tests/perf/medir_mapa.tscn
extends Node

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var mapa = load("res://scenes/mapa/scene_mapa_mundo.tscn").instantiate()
	add_child(mapa)
	await get_tree().create_timer(4.0).timeout
	var P := Performance
	var muestras := []
	for i in 5:
		await get_tree().create_timer(1.0).timeout
		muestras.append(P.get_monitor(P.TIME_FPS))
	print("FPS (sin vsync): ", muestras)
	print("process ms: %.2f  physics ms: %.2f" % [P.get_monitor(P.TIME_PROCESS) * 1000, P.get_monitor(P.TIME_PHYSICS_PROCESS) * 1000])
	print("nodos: ", P.get_monitor(P.OBJECT_NODE_COUNT))
	print("draw calls: ", P.get_monitor(P.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), "  objetos dibujados: ", P.get_monitor(P.RENDER_TOTAL_OBJECTS_IN_FRAME))
	print("física 2D activos: ", P.get_monitor(P.PHYSICS_2D_ACTIVE_OBJECTS), "  pares: ", P.get_monitor(P.PHYSICS_2D_COLLISION_PAIRS), "  islas: ", P.get_monitor(P.PHYSICS_2D_ISLAND_COUNT))
	print("memoria video MB: %.1f" % (P.get_monitor(P.RENDER_VIDEO_MEM_USED) / 1048576.0))
	var cuenta := {}
	_contar(mapa, cuenta)
	var top := cuenta.keys()
	top.sort_custom(func(a, b): return cuenta[a] > cuenta[b])
	for k in top.slice(0, 10):
		print("  %5d  %s" % [cuenta[k], k])
	# Costo de _process por script: se apaga cada grupo y se mide cuánto baja.
	var por_script := {}
	_procesando(mapa, por_script)
	var base := await _medir()
	print("cuadro base ms: %.2f" % base)
	var res := []
	for k in por_script:
		for n in por_script[k]: n.set_process(false)
		var m := await _medir()
		for n in por_script[k]: n.set_process(true)
		var b2 := await _medir()
		res.append([b2 - m, k, por_script[k].size()])
	res.sort_custom(func(a, b): return a[0] > b[0])
	for r in res.slice(0, 10):
		print("  ahorra %.2f ms  %s  (x%d)" % r)
	get_tree().quit()

func _medir() -> float:
	for i in 10:
		await get_tree().process_frame
	var t0 := Time.get_ticks_usec()
	for i in 120:
		await get_tree().process_frame
	return (Time.get_ticks_usec() - t0) / 120.0 / 1000.0

func _procesando(n: Node, d: Dictionary) -> void:
	if n.is_processing():
		var s = n.get_script()
		var k : String = s.resource_path.get_file() if s else n.get_class()
		if not d.has(k): d[k] = []
		d[k].append(n)
	for h in n.get_children():
		_procesando(h, d)

func _contar(n: Node, c: Dictionary) -> void:
	var k := n.get_class()
	var s = n.get_script()
	if s: k += " (" + s.resource_path.get_file() + ")"
	c[k] = c.get(k, 0) + 1
	for h in n.get_children():
		_contar(h, c)
