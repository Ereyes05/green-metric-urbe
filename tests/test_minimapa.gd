# Minimapa (pedido del jurado, nov. 2026): un punto por misión pendiente del
# nivel actual, que desaparece al completarla, y los puntos caen dentro del
# dibujo del campus.
# Correr: $GODOT --headless --path . res://tests/test_minimapa.tscn
extends Node

const MINIMAPA := preload("res://scenes/ui/minimapa.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _punto(mision_id: String, pos: Vector2) -> Node2D:
	var s := GDScript.new()
	s.source_code = "extends Node2D\nvar mision_id := ''\nvar _completada := false\n"
	s.reload()
	var n := Node2D.new()
	n.set_script(s)
	n.mision_id = mision_id
	n.position = pos
	return n


func _ready() -> void:
	print("test_minimapa")
	get_window().size = Vector2i(1280, 720)
	var nm = get_node("/root/NivelManager")
	var nivel := 0
	for n in range(1, 7):
		if nm.nivel_desbloqueado(n) and not nm.nivel_completo(n):
			nivel = n
			break
	var ids : Array = nm.misiones_nivel[nivel].filter(
		func(id): return not nm.mision_completada_q(nivel, id))

	var s := GDScript.new()
	s.source_code = "extends Node2D\nfunc borde_mapa() -> Rect2:\n\treturn Rect2(-600, -400, 2400, 1300)\n"
	s.reload()
	var mapa := Node2D.new()
	mapa.set_script(s)
	add_child(mapa)
	var a := _punto(ids[0], Vector2(-500, -300))
	var b := _punto(ids[1], Vector2(1700, 800))
	mapa.add_child(a)
	mapa.add_child(b)

	var mm = MINIMAPA.new()
	mm.mapa = mapa
	add_child(mm)
	await get_tree().process_frame
	_check(not mm.esta_abierto(), "arranca cerrado")
	mm.alternar()
	await get_tree().process_frame
	_check(mm.esta_abierto(), "el botón o la M lo abren")
	_check(mm._puntos.size() == 2, "un punto por misión pendiente del nivel %d" % nivel)
	_check(mm._titulo.text.contains("faltan 2"), "dice cuántas faltan")
	var r := Rect2(Vector2.ZERO, mm._vista.custom_minimum_size)
	_check(r.has_point(mm.a_vista(a.global_position)) and r.has_point(mm.a_vista(b.global_position)),
		"los puntos caen dentro del dibujo del campus")
	_check(mm.a_vista(a.global_position).x < mm.a_vista(b.global_position).x, "respeta izquierda y derecha")

	a._completada = true
	mm._actualizar()
	_check(mm._puntos.size() == 1 and not mm._puntos.has(a), "al completar una misión su punto desaparece")
	var pr : Rect2 = mm._panel.get_global_rect()
	_check(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(pr), "el minimapa entra en la pantalla %s" % pr)
	mm.alternar()
	_check(not mm.esta_abierto(), "se cierra")

	print("test_minimapa: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
