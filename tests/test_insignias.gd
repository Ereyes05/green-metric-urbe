# Prueba del lado cliente de las insignias (EconomiaManager).
# El servidor decide cuáles se ganaron (sql/insignias.sql); acá solo se
# comprueba que el juego muestre lo correcto y, sobre todo, que NO avise por
# las que el estudiante ya tenía al entrar.
# Correr: $GODOT --headless --path . res://tests/test_insignias.tscn
extends Node

var _fallos := 0
var _avisadas : Array[String] = []


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _fila(id: String, nombre: String, icono: String) -> Dictionary:
	return {"insignia_id": id, "nombre": nombre, "icono": icono}


func _ready() -> void:
	print("test_insignias")
	var em : Node = load("res://autoload/EconomiaManager.gd").new()
	add_child(em)
	em.insignia_obtenida.connect(func(id, _n, _i): _avisadas.append(str(id)))

	var verde := _fila("m1_completo", "Guardián Verde", "🌿")
	var solar := _fila("m2_completo", "Ahorrista Solar", "⚡")
	var estrella := _fila("quiz_perfecto", "Puntaje Perfecto", "⭐")

	# 1) Primera respuesta de la sesión: son las que YA tenía. No se avisa.
	em._on_insignias_evaluadas(["m1_completo", "m2_completo"], [verde, solar], [])
	_check(_avisadas.is_empty(), "al entrar no avisa por las insignias viejas: %s" % str(_avisadas))
	_check(em.insignias_obtenidas().size() == 2, "pero sí las registra: %d" % em.insignias_obtenidas().size())
	_check("m1_completo" in em.insignias_obtenidas(), "conoce m1_completo")

	# 2) Segunda respuesta: lo nuevo sí se avisa, y solo lo nuevo.
	em._on_insignias_evaluadas(["quiz_perfecto"], [verde, solar, estrella], [])
	_check(_avisadas == ["quiz_perfecto"], "avisa solo la recién ganada: %s" % str(_avisadas))
	_check(em.insignias_obtenidas().size() == 3, "ahora tiene 3")

	# 3) Una evaluación sin novedades no vuelve a avisar.
	_avisadas.clear()
	em._on_insignias_evaluadas([], [verde, solar, estrella], [])
	_check(_avisadas.is_empty(), "sin insignias nuevas no avisa nada")

	# 4) El nombre y el ícono salen del servidor, no de una copia local.
	# Si el cliente tuviera su propio catálogo, este nombre inventado no
	# llegaría al aviso.
	_avisadas.clear()
	var raro := _fila("crisis_resuelta", "NOMBRE DEL SERVIDOR", "🚨")
	var visto : Array[String] = []
	em.insignia_obtenida.connect(func(_id, n, _i): visto.append(str(n)))
	em._on_insignias_evaluadas(["crisis_resuelta"], [verde, solar, estrella, raro], [])
	_check(visto == ["NOMBRE DEL SERVIDOR"], "el nombre viene del servidor: %s" % str(visto))

	# 5) El cliente ya no tiene catálogo propio de insignias.
	var fuente : String = FileAccess.get_file_as_string("res://autoload/EconomiaManager.gd")
	_check(not fuente.contains("const INSIGNIAS"),
		"EconomiaManager ya no lleva su propio catálogo de insignias")
	_check(not fuente.contains("func otorgar_insignia"),
		"el cliente ya no puede otorgarse una insignia")

	# 6) La consulta del servidor no manda nada: solo pide que evalúe.
	var sup : String = FileAccess.get_file_as_string("res://autoload/SupabaseManager.gd")
	var i := sup.find("func evaluar_insignias")
	_check(i != -1 and sup.substr(i, 320).contains("rpc/evaluar_insignias"),
		"evaluar_insignias() llama a la RPC del servidor")
	_check(i != -1 and sup.substr(i, 320).contains('"{}"'),
		"y no le manda ninguna insignia: el cuerpo va vacío")

	remove_child(em)
	em.free()
	print("test_insignias: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
