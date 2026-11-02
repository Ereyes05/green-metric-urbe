# La flechita del mapa marca solo las misiones pendientes del nivel actual.
# Correr: $GODOT --headless --path . res://tests/test_indicador_misiones.tscn
extends Node

const INDICADOR := preload("res://scenes/mapa/indicador_misiones.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _punto(mision_id: String, completada := false) -> Node2D:
	var s := GDScript.new()
	s.source_code = "extends Node2D\nvar mision_id := ''\nvar _completada := false\n"
	s.reload()
	var n := Node2D.new()
	n.set_script(s)
	n.mision_id = mision_id
	n._completada = completada
	return n


func _ready() -> void:
	print("test_indicador_misiones")
	var nm = get_node("/root/NivelManager")
	var nivel := 0
	for n in range(1, 7):
		if nm.nivel_desbloqueado(n) and not nm.nivel_completo(n):
			nivel = n
			break
	_check(nivel > 0, "hay un nivel actual (%d)" % nivel)
	var ids : Array = nm.misiones_nivel[nivel].filter(
		func(id): return not nm.mision_completada_q(nivel, id))
	var otro : String = nm.misiones_nivel[6 if nivel != 6 else 1][0]
	var mapa := Node2D.new()
	add_child(mapa)
	var pendiente := _punto(ids[0])
	var hecha := _punto(ids[1], true)
	var de_otro_nivel := _punto(otro)
	var npc := _punto("mision_rector")
	for p in [pendiente, hecha, de_otro_nivel, npc]:
		mapa.add_child(p)
	var ind = INDICADOR.new()
	mapa.add_child(ind)
	ind._buscar()
	_check(ind._objetivos.has(pendiente), "marca la misión pendiente del nivel actual")
	_check(not ind._objetivos.has(hecha), "no marca la misión completada")
	_check(not ind._objetivos.has(de_otro_nivel), "no marca misiones de otro nivel")
	_check(not ind._objetivos.has(npc), "no marca los quiz de NPC")
	_check(ind._objetivos.size() == 1, "una sola flecha")
	print("test_indicador_misiones: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
