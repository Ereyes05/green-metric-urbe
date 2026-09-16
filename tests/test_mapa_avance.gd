# Prueba del "Mapa de avance" (antes "mapa de calor"): color_nivel() y los
# datos de ZONAS_AVANCE. mapa_campus.gd no tiene @onready hacia nodos de la
# escena real, así que se puede tocar directo desde el script cargado
# (sin instanciar el Node2D ni sus hijos de ambiente).
# Correr: $GODOT --headless --path . res://tests/test_mapa_avance.tscn
extends Node

const MAPA_CAMPUS := preload("res://scenes/mapa/mapa_campus.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_mapa_avance")

	_check(MAPA_CAMPUS.color_nivel(0.39) == Color(0.90, 0.18, 0.18), "0.39 -> rojo (bajo)")
	_check(MAPA_CAMPUS.color_nivel(0.40) == Color(0.92, 0.72, 0.08), "0.40 -> amarillo (medio)")
	_check(MAPA_CAMPUS.color_nivel(0.74) == Color(0.92, 0.72, 0.08), "0.74 -> amarillo (medio)")
	_check(MAPA_CAMPUS.color_nivel(0.75) == Color(0.18, 0.85, 0.18), "0.75 -> verde (alto)")

	var zonas : Array = MAPA_CAMPUS.ZONAS_AVANCE
	_check(zonas.size() > 0, "hay zonas de avance definidas")
	for z : Dictionary in zonas:
		var mod : int = int(z.get("mod", -1))
		_check(mod >= 1 and mod <= 6, "zona '%s' con mod válido (1..6): %d" % [z.get("lugar", "?"), mod])
		_check(String(z.get("lugar", "")) != "", "zona con 'lugar' no vacío")
		_check(z.get("rect") is Rect2, "zona '%s' con rect" % z.get("lugar", "?"))

	print("test_mapa_avance: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
