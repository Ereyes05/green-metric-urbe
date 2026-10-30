# Prueba de los tests de cierre de nivel (scenes/misiones/tests_nivel.gd):
# de dónde salen las preguntas y qué test toca.
# Correr: $GODOT --headless --path . res://tests/test_tests_nivel.tscn
extends Node

const TESTS := preload("res://scenes/misiones/tests_nivel.gd")
const MAPA  := preload("res://scenes/mapa/SceneMapaMundo.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _hechos(ids: Array) -> Dictionary:
	var d := {}
	for id in ids:
		d[id] = {"aciertos": 1, "total": 3}
	return d


func _ready() -> void:
	print("test_tests_nivel")
	var quiz : Dictionary = MAPA.QUIZ_POR_MISION
	var rng := RandomNumberGenerator.new()
	rng.seed = 7

	# Las preguntas salen solo del banco validado.
	for n in range(1, 7):
		for mision_id in TESTS.QUIZZES_POR_NIVEL[n]:
			_check(quiz.has(mision_id), "nivel %d: %s está en QUIZ_POR_MISION" % [n, mision_id])
		_check(TESTS.banco(n, quiz).size() >= 3, "nivel %d: al menos 3 preguntas" % n)
		var p : Array = TESTS.preguntas(TESTS.id_nivel(n), quiz, rng)
		_check(p.size() == mini(TESTS.PREGUNTAS_TEST, TESTS.banco(n, quiz).size()),
			"nivel %d: %d preguntas" % [n, p.size()])
		var unicas := {}
		for q in p:
			unicas[q["pregunta"]] = true
			_check(TESTS.banco(n, quiz).has(q), "nivel %d: pregunta del nivel" % n)
		_check(unicas.size() == p.size(), "nivel %d: sin repetidas" % n)

	var final : Array = TESTS.preguntas(TESTS.ID_FINAL, quiz, rng)
	_check(final.size() == 12, "final: 2 por nivel = 12")

	# Qué test toca.
	var nada := [false, false, false, false, false, false]
	var uno  := [true, false, false, false, false, false]
	var todos := [true, true, true, true, true, true]
	_check(TESTS.pendiente(nada, {}) == "", "sin niveles, sin test")
	_check(TESTS.pendiente(uno, {}) == "nivel_1", "nivel 1 superado → test 1")
	_check(TESTS.pendiente(uno, _hechos(["nivel_1"])) == "", "test 1 hecho → nada")
	_check(TESTS.pendiente(todos, _hechos(["nivel_1", "nivel_3"])) == "nivel_2", "toca el más bajo")
	var seis := ["nivel_1", "nivel_2", "nivel_3", "nivel_4", "nivel_5", "nivel_6"]
	_check(TESTS.pendiente(todos, _hechos(seis)) == "final", "6 tests → final")
	_check(TESTS.pendiente(todos, _hechos(seis + ["final"])) == "", "final hecho → nada")
	_check(TESTS.titulo("nivel_4") == "Nivel 4" and TESTS.titulo("final") == "Test final", "títulos")

	print("test_tests_nivel: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
