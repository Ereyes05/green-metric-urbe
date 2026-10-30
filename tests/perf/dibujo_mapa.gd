# Cuenta llamadas de dibujo del mapa por parte (no es una prueba: imprime).
# Estado como el de una cuenta con los 6 niveles completos.
# $GODOT --path . --resolution 1280x720 res://tests/perf/dibujo_mapa.tscn
extends Node

func _ready() -> void:
	get_window().size = Vector2i(1280, 720)
	NivelManager._misiones = {}
	for n in range(1, 7):
		var h := {}
		for m in NivelManager.MISIONES_NIVEL[n]: h[m] = true
		NivelManager._misiones[str(n)] = h
	NivelManager.nivel_actual = 6
	var mapa = load("res://scenes/mapa/scene_mapa_mundo.tscn").instantiate()
	add_child(mapa)
	await get_tree().create_timer(4.0).timeout
	var base := await _dc()
	print("draw calls total: ", base, "   nodos: ", Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var res := []
	for h in mapa.get_children():
		if not (h is CanvasItem or h is CanvasLayer): continue
		if not h.visible: continue
		h.visible = false
		var d := await _dc()
		h.visible = true
		var s = h.get_script()
		res.append([base - d, h.name, s.resource_path.get_file() if s else h.get_class()])
	res.sort_custom(func(a, b): return a[0] > b[0])
	for r in res.slice(0, 15):
		print("  %4d  %s  (%s)" % r)
	# Desglose de la capa de interfaz más cara.
	var capa = null
	for r in res:
		if r[2] == "CanvasLayer": capa = mapa.get_node(NodePath(str(r[1]))); break
	if capa:
		var base2 := await _dc()
		var sub := []
		for h in capa.get_children():
			if not (h is CanvasItem) or not h.visible: continue
			h.visible = false
			var d := await _dc()
			h.visible = true
			var s = h.get_script()
			sub.append([base2 - d, h.name, s.resource_path.get_file() if s else h.get_class()])
		sub.sort_custom(func(a, b): return a[0] > b[0])
		print("capa ", capa.name, ":")
		for r in sub.slice(0, 10): print("     %4d  %s  (%s)" % r)
	get_tree().quit()

func _dc() -> int:
	for i in 3: await get_tree().process_frame
	return int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
