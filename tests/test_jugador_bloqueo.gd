# Con la Bitácora (o el ranking, el avance, la pausa…) abierta, las flechas
# no mueven al personaje: jugador.gd le pregunta al mapa ui_bloquea_jugador().
# Correr: $GODOT --headless --path . res://tests/test_jugador_bloqueo.tscn
extends Node

const JUGADOR := preload("res://scenes/mapa/jugador.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_jugador_bloqueo")
	var s := GDScript.new()
	s.source_code = "extends Node2D\nvar bloquea := false\nfunc ui_bloquea_jugador() -> bool:\n\treturn bloquea\n"
	s.reload()
	var mapa := Node2D.new()
	mapa.set_script(s)
	add_child(mapa)
	var j := CharacterBody2D.new()
	j.set_script(JUGADOR)
	var spr := AnimatedSprite2D.new()
	spr.name = "AnimatedSprite2D"
	spr.sprite_frames = SpriteFrames.new()
	for dir in ["abajo", "arriba", "derecha", "izquierda"]:
		spr.sprite_frames.add_animation("idle_" + dir)
		spr.sprite_frames.add_animation("walk_" + dir)
	j.add_child(spr)
	mapa.add_child(j)
	await get_tree().physics_frame

	Input.action_press("mover_derecha")
	mapa.bloquea = true
	var x0 := j.global_position.x
	for _i in 10:
		await get_tree().physics_frame
	_check(is_equal_approx(j.global_position.x, x0), "con un panel abierto la flecha no mueve al personaje")

	mapa.bloquea = false
	for _i in 10:
		await get_tree().physics_frame
	_check(j.global_position.x > x0, "sin panel abierto la flecha sí lo mueve")
	Input.action_release("mover_derecha")

	print("test_jugador_bloqueo: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
