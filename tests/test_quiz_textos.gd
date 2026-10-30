# Todas las preguntas del juego entran en el quiz: ninguna opción se sale de
# su botón ni el contenido del panel. Cubre los quizzes de NPC, los tests de
# nivel y el test final (salen todos de QUIZ_POR_MISION).
# Correr: $GODOT --headless --path . res://tests/test_quiz_textos.tscn
extends Node

const QUIZ := preload("res://scenes/ui/quiz_npc.tscn")
const MAPA := preload("res://scenes/mapa/SceneMapaMundo.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_quiz_textos")
	get_window().size = Vector2i(1280, 720)
	var quiz = QUIZ.instantiate()
	add_child(quiz)
	var n := 0
	for mision_id in MAPA.QUIZ_POR_MISION:
		for q in MAPA.QUIZ_POR_MISION[mision_id]:
			quiz.iniciar([q], "Prueba", 0, "prueba_textos", true)
			for _i in 4:
				await get_tree().process_frame
			_check(quiz.contenido_cabe(), "%s: %s %s" % [mision_id, str(q["pregunta"]).left(50), str(quiz._panel.get_global_rect())])
			n += 1
	_check(n >= 39, "%d preguntas revisadas" % n)
	print("test_quiz_textos: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
