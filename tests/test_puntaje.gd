# Prueba de puntaje_formula.gd (espejo local del cálculo del servidor).
# Correr: $GODOT --headless --path . res://tests/test_puntaje.tscn
extends Node

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_puntaje")
	var F = load("res://autoload/puntaje_formula.gd")

	var datos := {"categorias": {
		"1": {"avance": 80, "comprension": 6.67, "decisiones": 0, "sinergias": 1, "total": 87.67},
		"2": {"avance": 80, "comprension": 10, "decisiones": 0, "sinergias": 0, "total": 90},
		"3": {"avance": 80, "comprension": 0, "decisiones": 0, "sinergias": 0, "total": 80},
		"4": {"avance": 80, "comprension": 0, "decisiones": 0, "sinergias": 0, "total": 80},
		"5": {"avance": 80, "comprension": 0, "decisiones": 0, "sinergias": 0, "total": 80},
		"6": {"avance": 0, "comprension": 0, "decisiones": 0, "sinergias": 0, "total": 0},
	}, "total": 69.35}
	var cats : Dictionary = F.normalizar(datos)
	_check(cats.has(1) and not cats.has("1"), "normalizar usa claves int")
	_check(cats[1]["total"] is float, "normalizar convierte a float")
	_check(cats.size() == 6, "normalizar devuelve las 6 categorías")
	var esperado := (87.67 * 15 + 90 * 21 + 80 * 18 + 80 * 10 + 80 * 18 + 0 * 18) / 100.0
	_check(is_equal_approx(F.total_ponderado(cats), esperado), "total ponderado con pesos de la guía")

	var vacio : Dictionary = F.normalizar({})
	_check(vacio.size() == 6 and is_equal_approx(vacio[3]["total"], 0.0), "sin datos: 6 categorías en 0")

	var con : Dictionary = F.con_avance(cats[6], 0.5)
	_check(is_equal_approx(con["avance"], 40.0), "con_avance: 50% de misiones = 40")
	_check(is_equal_approx(con["total"], 40.0), "con_avance recalcula el total")
	var tope : Dictionary = F.con_avance({"avance": 0, "comprension": 12, "decisiones": 9, "sinergias": -1}, 1.5)
	_check(is_equal_approx(tope["total"], 80.0 + 10.0 + 5.0 + 0.0), "con_avance respeta topes")

	print("test_puntaje: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
