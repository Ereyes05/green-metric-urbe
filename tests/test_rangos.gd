# Prueba de rangos: uno por nivel completado.
# Correr: $GODOT --headless --path . res://tests/test_rangos.tscn
extends Node

const RANGOS := preload("res://autoload/rangos.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


# NivelManager real con los niveles 1..hasta completos y `parcial` misiones
# hechas del nivel siguiente.
func _nm_con(hasta: int, parcial: int = 0) -> Node:
	var nm : Node = load("res://autoload/NivelManager.gd").new()
	var mis : Dictionary = {}
	for n in range(1, hasta + 1):
		var d := {}
		for id in nm.MISIONES_NIVEL[n]:
			d[id] = true
		mis[str(n)] = d
	if hasta < 6 and parcial > 0:
		var d2 := {}
		var ids : Array = nm.MISIONES_NIVEL[hasta + 1]
		for i in mini(parcial, ids.size()):
			d2[ids[i]] = true
		mis[str(hasta + 1)] = d2
	nm._misiones = mis
	return nm


func _ready() -> void:
	print("test_rangos")
	var esperados := ["Semilla", "Brote", "Árbol", "Estratega", "Investigador", "Investigador", "EcoLíder"]
	for c in range(0, 7):
		_check(RANGOS.nombre(c) == esperados[c], "%d niveles -> %s" % [c, esperados[c]])
	_check(RANGOS.indice(-3) == 0, "negativo se trata como 0")
	_check(RANGOS.indice(9) == 5, "más de 6 es EcoLíder")
	_check(RANGOS.siguiente(0) == "Brote", "desde Semilla sigue Brote")
	_check(RANGOS.siguiente(4) == "EcoLíder", "desde Investigador (4) sigue EcoLíder")
	_check(RANGOS.siguiente(5) == "EcoLíder", "desde Investigador (5) sigue EcoLíder")
	_check(RANGOS.siguiente(6) == "", "EcoLíder no tiene siguiente")

	var nm := _nm_con(0)
	_check(RANGOS.niveles_superados(nm) == 0, "sin misiones: 0 niveles")
	_check(is_equal_approx(RANGOS.fraccion_siguiente(nm), 0.0), "sin misiones: 0 hacia Brote")
	nm.free()

	nm = _nm_con(2)
	_check(RANGOS.niveles_superados(nm) == 2, "niveles 1-2 completos: 2")
	_check(RANGOS.nombre(RANGOS.niveles_superados(nm)) == "Árbol", "niveles 1-2 -> Árbol")
	nm.free()

	var total3 : int = load("res://autoload/NivelManager.gd").MISIONES_NIVEL[3].size()
	nm = _nm_con(2, 3)
	_check(is_equal_approx(RANGOS.fraccion_siguiente(nm), 3.0 / total3), "hacia Estratega = avance del nivel 3")
	nm.free()

	# Con 4 completos, EcoLíder pide el 5 y el 6: mitad del camino si el 5 está completo.
	nm = _nm_con(5)
	_check(RANGOS.niveles_superados(nm) == 5, "niveles 1-5 completos: 5")
	_check(is_equal_approx(RANGOS.fraccion_siguiente(nm), 0.5), "5 completos: 50% hacia EcoLíder")
	nm.free()

	nm = _nm_con(6)
	_check(RANGOS.niveles_superados(nm) == 6, "todo completo: 6")
	_check(is_equal_approx(RANGOS.fraccion_siguiente(nm), 1.0), "EcoLíder: barra llena")
	nm.free()

	print("test_rangos: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
