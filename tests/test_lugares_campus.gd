# Prueba del registro de lugares con nombre y chequeo de solapamientos
# contra los puntos que ya existen en el mapa. Volver a correrla cada vez
# que cambie una coordenada (mapa nuevo).
# Correr: $GODOT --headless --path . res://tests/test_lugares_campus.tscn
extends Node

const LUGARES := preload("res://scenes/mapa/lugares_campus.gd")
const MINIMO := 55.0
# Constantes DATOS_* de SceneMapaMundo que no son puntos instanciados en el
# mapa. Las del Nivel 5 viejo ya no existen: este registro las reemplazó, y
# DATOS_ZONAS_VERDES / DATOS_CONTENEDORES se borraron con sus subsistemas
# (2026-09-20). La lista queda porque el chequeo la sigue consultando: si
# aparece otra constante DATOS_* que no sea un punto real del mapa, va acá.
const IGNORADAS : Array[String] = []

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


# Colisiones reales del mapa nuevo (hijas de Sprite2D/StaticBody2D en la
# escena), en coordenadas LOCALES al nodo raíz — las mismas que LUGARES.
# El "Borde" es el anillo de bosque que rodea el campus: el punto NO debe
# caer dentro de ese polígono.
func _colisiones() -> Dictionary:
	var escena : Node = (load("res://scenes/mapa/scene_mapa_mundo.tscn") as PackedScene).instantiate()
	var spr : Node2D = escena.get_node("Sprite2D")
	var out := {"rects": [], "polis": [], "borde": PackedVector2Array()}
	for h in escena.get_node("Sprite2D/StaticBody2D").get_children():
		if h.get("disabled") and h.name != "Laguna":
			continue
		if h is CollisionShape2D and h.shape is RectangleShape2D:
			var s : Vector2 = (h.shape as RectangleShape2D).size
			out["rects"].append(Rect2(spr.position + h.position - s / 2.0, s))
		elif h is CollisionPolygon2D:
			var pts := PackedVector2Array()
			for q in (h as CollisionPolygon2D).polygon:
				pts.append(spr.position + h.position + q)
			if h.name == "Borde":
				out["borde"] = pts
			else:
				out["polis"].append(pts)
	escena.free()
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
	_check(LUGARES.posicion("rectorado") == Vector2(684, 262), "posición del Rectorado")
	_check(LUGARES.posicion("rectorado", Vector2(10, -5)) == Vector2(694, 257), "desplazamiento se suma")
	# Mapa nuevo (urbe_removed (1).png), coordenadas locales al nodo raíz.
	_check(LUGARES.posicion("oficina_movilidad") == Vector2(-166, 870), "oficina frente a la caseta")
	_check(LUGARES.posicion("bicicletero_bloque_e") == Vector2(1584, -45), "bicicletero Bloque E")
	_check(LUGARES.posicion("bicicletero_cafetin") == Vector2(1764, 672), "bicicletero del picnic")

	var existentes := _puntos_existentes()
	_check(existentes.size() >= 40, "se leyeron los puntos existentes (%d)" % existentes.size())
	var col := _colisiones()
	# Límites del mapa nuevo en coordenadas locales: imagen 2814x1536 − (816, 412)
	var mundo := Rect2(-816, -412, 2814, 1536)
	var nombres : Array = LUGARES.LUGARES.keys()
	for i in nombres.size():
		var nombre : String = nombres[i]
		var p : Vector2 = LUGARES.LUGARES[nombre]
		_check(mundo.has_point(p), "%s dentro del mapa" % nombre)
		_check(not Geometry2D.is_point_in_polygon(p, col["borde"]), "%s fuera del bosque del borde" % nombre)
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
		for r in col["rects"]:
			if (r as Rect2).has_point(p):
				dentro = true
		for pl in col["polis"]:
			if Geometry2D.is_point_in_polygon(p, pl):
				dentro = true
		_check(not dentro, "%s fuera de edificios" % nombre)

	print("test_lugares_campus: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
