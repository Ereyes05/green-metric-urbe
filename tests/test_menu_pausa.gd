# "Reiniciar Misiones" del menú de pausa es una herramienta de desarrollo:
# solo borra el guardado local (la XP, el puntaje y el ranking siguen en el
# servidor). En la versión web (release) no debe aparecer.
# Correr: $GODOT --headless --path . res://tests/test_menu_pausa.tscn
extends Node

const MAPA := preload("res://scenes/mapa/scene_mapa_mundo.tscn")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _tiene_reinicio(mapa: Node) -> bool:
	for b in mapa._menu_pausa_canvas.find_children("*", "Button", true, false):
		if "Reiniciar" in (b as Button).text:
			return true
	return false


func _abrir(permitir: bool) -> Node:
	var m = MAPA.instantiate()
	m.permitir_reinicio = permitir
	add_child(m)
	await get_tree().process_frame
	return m


func _ready() -> void:
	print("test_menu_pausa")
	var publicado = await _abrir(false)
	_check(not _tiene_reinicio(publicado), "versión publicada: el menú de pausa no ofrece Reiniciar Misiones")
	_check(publicado._menu_pausa_canvas.find_children("*", "Button", true, false).size() > 0,
		"el menú de pausa sigue teniendo sus otros botones")
	publicado.free()
	var editor = await _abrir(true)
	_check(_tiene_reinicio(editor), "desde el editor sigue disponible para desarrollo")
	editor.free()
	print("test_menu_pausa: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
