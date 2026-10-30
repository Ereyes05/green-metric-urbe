# Guía tipo libro (scenes/ui/guia_libro.gd): todas las páginas entran en sus
# hojas, se navega sin pasarse de los extremos y Esc/H la cierran.
# Correr: $GODOT --headless --path . res://tests/test_guia.tscn
extends Node

const GUIA := preload("res://scenes/ui/guia_libro.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _tecla(g: Node, k: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.pressed = true
	g._input(e)


func _ready() -> void:
	print("test_guia")
	get_window().size = Vector2i(1280, 720)
	var g = GUIA.new()
	add_child(g)
	await get_tree().process_frame
	_check(not g.esta_abierta(), "arranca cerrada")
	g.abrir()
	for n in GUIA.PAGINAS.size():
		g._mostrar_pagina(n, 0)
		for _i in 3:
			await get_tree().process_frame
		_check(g.pagina_cabe(), "página %d (%s) entra" % [n + 1, GUIA.PAGINAS[n][1]])

	g._mostrar_pagina(0, 0)
	g.pasar(-1)
	_check(g.pagina == 0 and g._btn_ant.disabled, "no retrocede antes de la primera")
	_tecla(g, KEY_RIGHT)
	_check(g.pagina == 1, "flecha derecha avanza")
	_tecla(g, KEY_LEFT)
	_check(g.pagina == 0, "flecha izquierda retrocede")
	for _i in GUIA.PAGINAS.size() + 3:
		g.pasar(1)
	_check(g.pagina == GUIA.PAGINAS.size() - 1 and g._btn_sig.disabled, "no avanza después de la última")
	_tecla(g, KEY_ESCAPE)
	_check(not g.esta_abierta(), "Esc cierra")
	g.abrir()
	_tecla(g, KEY_H)
	_check(not g.esta_abierta(), "H cierra")

	print("test_guia: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
