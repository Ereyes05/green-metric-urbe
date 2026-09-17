# Prueba del registro de lugares con nombre y chequeo de solapamientos
# contra los puntos que ya existen en el mapa. Volver a correrla cada vez
# que cambie una coordenada (mapa nuevo).
# Correr: $GODOT --headless --path . res://tests/test_lugares_campus.tscn
extends Node

const LUGARES := preload("res://scenes/mapa/lugares_campus.gd")
const MINIMO := 55.0
# Constantes DATOS_* de SceneMapaMundo que no son puntos instanciados en el
# mapa. Las del Nivel 5 viejo ya no existen: este registro las reemplazó.
const IGNORADAS := ["DATOS_ZONAS_VERDES", "DATOS_CONTENEDORES"]

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _puntos_existentes() -> Array:
	var out := []
	var script : Script = load("res://scenes/mapa/SceneMapaMundo.gd")
	var consts : Dictionary = script.get_script_constant_map()
	for nombre in consts.keys():
		var n := str(nombre)
		if not n.begins_with("DATOS_") or n in IGNORADAS:
			continue
		var arr = consts[nombre]
		if not (arr is Array):
			continue
		for d in arr:
			if d is Dictionary and d.has("pos"):
				out.append({"id": str(d.get("id", d.get("nombre", n))), "pos": d["pos"]})
	var mapa : Node = script.new()
	for d in mapa.DATOS_NPCS:
		out.append({"id": "npc:" + str(d.get("nombre", "")), "pos": d["pos"]})
	mapa.free()
	return out


func _edificios() -> Array:
	var out := []
	var col : Script = load("res://scenes/mapa/colision_tilemap.gd")
	for e in col.get_script_constant_map()["EDIFICIOS"]:
		out.append(Rect2(float(e[0]) - float(e[2]) * 0.5, float(e[1]) - float(e[3]) * 0.5,
			float(e[2]), float(e[3])))
	return out


func _ready() -> void:
	print("test_lugares_campus")
	var claves := ["oficina_movilidad", "bicicletero_bloque_e", "bicicletero_cafetin",
		"garita_m5", "estacionamiento_m5", "lote_este", "parada_rectorado",
		"porton_vehicular", "zona_mantenimiento", "rectorado"]
	for c in claves:
		_check(LUGARES.existe(c), "existe %s" % c)
	_check(LUGARES.LUGARES.size() == claves.size(), "10 lugares")
	_check(not LUGARES.existe("no_existe"), "lugar desconocido no existe")
	_check(LUGARES.posicion("rectorado") == Vector2(720, 560), "posición del Rectorado")
	_check(LUGARES.posicion("rectorado", Vector2(10, -5)) == Vector2(730, 555), "desplazamiento se suma")
	# Heredadas del Nivel 5 viejo (mismas coordenadas que hoy).
	_check(LUGARES.posicion("oficina_movilidad") == Vector2(600, 100), "oficina en su lugar actual")
	_check(LUGARES.posicion("bicicletero_bloque_e") == Vector2(1020, 460), "bicicletero Bloque E actual")
	_check(LUGARES.posicion("bicicletero_cafetin") == Vector2(200, 360), "bicicletero Cafetín actual")

	var existentes := _puntos_existentes()
	_check(existentes.size() >= 40, "se leyeron los puntos existentes (%d)" % existentes.size())
	var edificios := _edificios()
	var nombres : Array = LUGARES.LUGARES.keys()
	for i in nombres.size():
		var nombre : String = nombres[i]
		var p : Vector2 = LUGARES.LUGARES[nombre]
		_check(p.x >= 0 and p.x <= 1408 and p.y >= 0 and p.y <= 768, "%s dentro del mapa" % nombre)
		var peor := INF
		var cual := ""
		for e in existentes:
			var d := p.distance_to(e["pos"])
			if d < peor:
				peor = d
				cual = e["id"]
		_check(peor >= MINIMO, "%s a %.0f px de %s (mínimo %.0f)" % [nombre, peor, cual, MINIMO])
		for j in range(i + 1, nombres.size()):
			var d2 := p.distance_to(LUGARES.LUGARES[nombres[j]])
			_check(d2 >= MINIMO, "%s a %.0f px de %s" % [nombre, d2, nombres[j]])
		var dentro := false
		for r in edificios:
			if (r as Rect2).has_point(p):
				dentro = true
		_check(not dentro, "%s fuera de edificios" % nombre)

	print("test_lugares_campus: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
