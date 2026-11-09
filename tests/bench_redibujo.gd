# Mide el costo de redibujar los íconos animados del mapa en cada cuadro
# (Redibujo.CADA = 0, como antes del 2026-11-09) contra ~12 Hz.
# Rondas intercaladas A/B para no confundir calentamiento con mejora.
# NO headless (tiene que dibujar):
#   $GODOT --path . res://tests/bench_redibujo.tscn
extends Node

const Redibujo := preload("res://scenes/mapa/redibujo.gd")
const RONDAS  := 4
const SEG     := 3.0


func _medir(cada: float) -> float:
	Redibujo.CADA = cada
	for i in 10: await get_tree().process_frame
	var cuadros := 0
	var t0 := Time.get_ticks_usec()
	while Time.get_ticks_usec() - t0 < int(SEG * 1e6):
		await get_tree().process_frame
		cuadros += 1
	return (Time.get_ticks_usec() - t0) / 1000.0 / cuadros


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	get_window().size = Vector2i(1898, 982)
	NivelManager._misiones = {}
	for n in range(1, 7):
		var h := {}
		for m in NivelManager.MISIONES_NIVEL[n]: h[m] = true
		NivelManager._misiones[str(n)] = h
	NivelManager.nivel_actual = 6
	var mapa = load("res://scenes/mapa/scene_mapa_mundo.tscn").instantiate()
	add_child(mapa)
	await get_tree().create_timer(4.0).timeout
	for h in mapa.get_children():
		if h is CanvasLayer and h.layer > 1:
			h.visible = false   # tutorial/paneles encima del mapa
	var antes := 0.0
	var despues := 0.0
	for r in RONDAS:
		var a : float = await _medir(0.0)
		var b : float = await _medir(1.0 / 12.0)
		print("  ronda %d: cada cuadro %.2f ms | 12 Hz %.2f ms" % [r + 1, a, b])
		antes += a
		despues += b
	var vivos := 0
	for n in mapa._animados:
		if is_instance_valid(n) and n.is_processing(): vivos += 1
	print("bench_redibujo: cada cuadro %.2f ms, 12 Hz %.2f ms (%d visuales animándose en cámara)" % [
		antes / RONDAS, despues / RONDAS, vivos])
	get_tree().quit()
