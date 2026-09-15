# Prueba de NivelManager: misiones válidas por nivel y desbloqueo por legado.
# Correr: $GODOT --headless --path . res://tests/test_niveles.tscn
extends Node

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _nm_con(misiones: Dictionary) -> Node:
	var nm : Node = load("res://autoload/NivelManager.gd").new()
	nm._misiones = misiones
	return nm


func _ready() -> void:
	print("test_niveles")
	var nm : Node = _nm_con({})

	# Espejo: TOTAL_MISIONES coincide con las listas.
	for n in range(1, 7):
		_check(nm.TOTAL_MISIONES[n] == nm.MISIONES_NIVEL[n].size(),
			"TOTAL_MISIONES[%d] == MISIONES_NIVEL[%d].size()" % [n, n])

	# IDs que no pertenecen al nivel no cuentan.
	var basura := {}
	for i in 10:
		basura["no_es_del_nivel_%d" % i] = true
	# Cada NivelManager se crea con .new() fuera del árbol: nadie lo libera
	# solo, así que se libera antes de reemplazarlo (si no, ObjectDB leaks).
	nm.free()
	nm = _nm_con({"1": basura})
	_check(not nm.nivel_completo(1), "IDs ajenos no completan el nivel 1")
	_check(is_equal_approx(nm.pct_nivel(1), 0.0), "IDs ajenos dan 0% en nivel 1")

	# Nivel completo con sus IDs válidos.
	var n1 := {}
	for id in nm.MISIONES_NIVEL[1]:
		n1[id] = true
	nm.free()
	nm = _nm_con({"1": n1})
	_check(nm.nivel_completo(1), "nivel 1 completo con sus 6 IDs")
	_check(nm.nivel_desbloqueado(2), "nivel 2 desbloqueado")

	# Legado: el nivel cambió (IDs nuevos) pero ya se había superado.
	nm.free()
	nm = _nm_con({"5": {"viejo_a": true, "viejo_b": true}})
	nm.misiones_nivel[5] = ["nuevo_a", "nuevo_b", "nuevo_c"]
	nm.misiones_legado[5] = ["viejo_a", "viejo_b"]
	for n in range(1, 5):
		var d := {}
		for id in nm.MISIONES_NIVEL[n]:
			d[id] = true
		nm._misiones[str(n)] = d
	_check(not nm.nivel_completo(5), "nivel 5 reabierto: no está completo")
	_check(nm.nivel_superado(5), "nivel 5 superado por legado")
	_check(nm.nivel_desbloqueado(6), "nivel 6 sigue desbloqueado por legado")
	_check(is_equal_approx(nm.pct_nivel(5), 0.0), "avance del nivel 5 nuevo en 0%")

	# Legado incompleto no desbloquea.
	nm._misiones["5"] = {"viejo_a": true}
	_check(not nm.nivel_superado(5), "legado incompleto no supera el nivel")
	_check(not nm.nivel_desbloqueado(6), "legado incompleto no desbloquea el 6")

	nm.free()
	print("test_niveles: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
