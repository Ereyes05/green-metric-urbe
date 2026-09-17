# Prueba del punto genérico del Plan de Movilidad: ubicación por lugar,
# estados, texto del cartel e interacción.
# Correr: $GODOT --headless --path . res://tests/test_punto_movilidad.tscn
extends Node

const PUNTO := preload("res://scenes/misiones/punto_movilidad.gd")
const LUGARES := preload("res://scenes/mapa/lugares_campus.gd")
const TEMA := preload("res://scenes/ui/hud_tema.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _nuevo(tipo: String, lugar: String, nombre: String) -> Area2D:
	var p : Area2D = PUNTO.new()
	p.mision_id = "tr_lote"
	p.tipo = tipo
	p.lugar = lugar
	p.nombre_punto = nombre
	return p


func _ready() -> void:
	print("test_punto_movilidad")
	var p := _nuevo("decision", "lote_este", "El lote poco usado")
	p.desplazamiento = Vector2(4, -6)
	add_child(p)
	_check(p.position == LUGARES.posicion("lote_este", Vector2(4, -6)), "ubicado por lugar + desplazamiento")
	_check(p.is_in_group("punto_movilidad"), "grupo punto_movilidad")
	var forma : CollisionShape2D = null
	for c in p.get_children():
		if c is CollisionShape2D:
			forma = c
	_check(forma != null and is_equal_approx((forma.shape as CircleShape2D).radius, 55.0), "radio 55")

	var n := [0]
	p.interaccion_solicitada.connect(func(_x): n[0] += 1)
	p.set_estado("pendiente")
	_check(p.texto_prompt().contains("Decidir") and p.texto_prompt().contains("El lote poco usado"), "cartel pendiente")
	p.intentar_interactuar()
	_check(n[0] == 0, "lejos no interactúa")
	p._jugador_cerca = true
	p.intentar_interactuar()
	_check(n[0] == 1, "cerca interactúa")
	p.set_estado("bloqueado")
	p.intentar_interactuar()
	_check(n[0] == 1 and p.texto_prompt().begins_with("🔒"), "bloqueado no interactúa y lo explica")
	p.set_estado("resuelto")
	_check(p.texto_prompt().contains("Revisar"), "cartel resuelto")
	_check(p._prompt_lbl.text == p.texto_prompt(), "el cartel muestra el texto del estado")
	var caja := p._prompt.get_theme_stylebox("panel") as StyleBoxFlat
	_check(caja != null and caja.border_color == TEMA.VIOLETA and caja.bg_color == TEMA.PANEL_BG, "cartel con tokens del HUD")

	for caso in [["oficina", "Oficina"], ["consejo", "Consejo"], ["bicicletero", "bicicletero"]]:
		var q := _nuevo(caso[0], "rectorado", "X")
		add_child(q)
		q.set_estado("pendiente")
		_check(q.texto_prompt().contains(caso[1]), "cartel de %s" % caso[0])
		q.queue_free()
	var c := _nuevo("consejo", "rectorado", "Consejo")
	add_child(c)
	c.set_estado("bloqueado")
	_check(c.texto_prompt().contains("8 decisiones"), "Consejo bloqueado explica el requisito")
	await get_tree().process_frame
	await get_tree().process_frame

	print("test_punto_movilidad: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
