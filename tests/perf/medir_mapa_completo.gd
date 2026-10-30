# Costo por cuadro del mapa con los 6 niveles completos (como una cuenta
# EcoLíder) y cuánto dibuja cada parte. No es una prueba: imprime números.
# $GODOT --path . --resolution 1280x720 res://tests/perf/medir_mapa_completo.tscn
extends Node

func _ready() -> void:
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var todo := {}
	for n in range(1, 7):
		var d := {}
		for id in NivelManager.misiones_nivel.get(n, []):
			d[id] = true
		todo[str(n)] = d
	NivelManager._misiones = todo
	var mapa = load("res://scenes/mapa/scene_mapa_mundo.tscn").instantiate()
	add_child(mapa)
	await get_tree().create_timer(4.0).timeout
	var P := Performance
	var base := await _medir()
	var dc0 : int = P.get_monitor(P.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	print("cuadro: %.2f ms  draw calls: %d  primitivas: %d  nodos: %d" % [base, dc0,
		P.get_monitor(P.RENDER_TOTAL_PRIMITIVES_IN_FRAME), P.get_monitor(P.OBJECT_NODE_COUNT)])
	var res := []
	for h in _partes(mapa):
		if not (h is CanvasItem or h is CanvasLayer) or not h.visible:
			continue
		h.visible = false
		var m := await _medir()
		var dc : int = P.get_monitor(P.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		h.visible = true
		res.append([dc0 - dc, base - m, h.name, (h.get_script().resource_path.get_file() if h.get_script() else h.get_class())])
	res.sort_custom(func(a, b): return a[0] > b[0])
	for r in res.slice(0, 8):
		print("  -%3d draw calls  -%.2f ms  %s (%s)" % r)
	# _process y _physics_process por script: se apagan y se mide cuánto baja.
	var grupos := {}
	_procesando(mapa, grupos)
	for n in get_tree().root.get_children():
		if n != self: _procesando(n, grupos)
	var r2 := []
	for k in grupos:
		var b := await _medir()
		for n in grupos[k]:
			n.set_process(false); n.set_physics_process(false)
		var m := await _medir()
		for n in grupos[k]:
			n.set_process(true); n.set_physics_process(true)
		r2.append([b - m, k, grupos[k].size()])
	r2.sort_custom(func(a, b): return a[0] > b[0])
	var clases := {}
	for n in grupos.get("", []) + grupos.get("Timer", []):
		var k : String = n.get_class() + " / padre: " + (n.get_parent().get_script().resource_path.get_file() if n.get_parent() and n.get_parent().get_script() else str(n.get_parent().get_class()))
		clases[k] = clases.get(k, 0) + 1
	for k in grupos.keys():
		if not k.ends_with(".gd"):
			for n in grupos[k]:
				var kk : String = k + " / padre: " + (n.get_parent().get_script().resource_path.get_file() if n.get_parent() and n.get_parent().get_script() else str(n.get_parent().get_class()))
				clases[kk] = clases.get(kk, 0) + 1
	print(clases)
	print("física: ticks/s ", Engine.physics_ticks_per_second, "  max pasos/cuadro ", Engine.max_physics_steps_per_frame)
	for r in r2.slice(0, 15):
		print("  ahorra %.2f ms  %s  (x%d)" % r)
	get_tree().quit()

func _procesando(n: Node, d: Dictionary) -> void:
	if n.is_processing() or n.is_physics_processing():
		var s = n.get_script()
		var k : String = s.resource_path.get_file() if s else n.get_class()
		if not d.has(k): d[k] = []
		d[k].append(n)
	for h in n.get_children():
		_procesando(h, d)

func _partes(mapa: Node) -> Array:
	var out := []
	for h in mapa.get_children():
		out.append(h)
		if h.name in ["Mundo", "Objetos", "Zonas", "NPCs", "Campus"] or h.get_child_count() > 15:
			for n in h.get_children():
				out.append(n)
	return out

func _medir() -> float:
	for i in 8:
		await get_tree().process_frame
	var t0 := Time.get_ticks_usec()
	for i in 120:
		await get_tree().process_frame
	return (Time.get_ticks_usec() - t0) / 60.0 / 1000.0
