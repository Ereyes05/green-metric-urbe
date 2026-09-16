# Prueba de la ficha del jugador y del panel GreenMetric con datos fijos.
# Correr: $GODOT --headless --path . res://tests/test_hud_paneles.tscn
extends Node

const FICHA := preload("res://scenes/ui/hud_ficha_jugador.gd")
const PANEL_GM := preload("res://scenes/ui/hud_panel_greenmetric.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_hud_paneles")
	var f = FICHA.new()
	add_child(f)
	f.set_energia(2, 3)
	_check(f.corazones.size() == 3, "3 corazones")
	_check(f.corazones[2].get_theme_color("font_color").is_equal_approx(Color("#3A4550")), "corazón vacío gris")
	f.set_nivel_misiones(6, [true, true, true, true, false, false])
	_check(f.nivel_lbl.text == "Nivel 6/6 · Educación", "nivel de misiones: %s" % f.nivel_lbl.text)
	_check(f.pasos.size() == 6, "6 pasos")
	f.set_rango(2, 0.45, 1578)
	_check(f.rango_lbl.text == "Árbol", "rango Árbol con 2 niveles")
	_check(f.hacia_lbl.text == "Hacia Estratega", "texto hacia: %s" % f.hacia_lbl.text)
	_check(f.xp_lbl.text == "1578 XP", "xp: %s" % f.xp_lbl.text)
	f.set_rango(6, 1.0, 2800)
	_check(f.hacia_lbl.text == "Rango máximo", "EcoLíder: rango máximo")
	f.set_creditos(319)
	_check(f.creditos_lbl.text == "💰 319 EC", "créditos")
	f.set_indices({1: 0.62, 4: 0.3, 6: 1.0})
	_check(f.indices[1]["pct"].text == "62%", "índice verde 62%")
	_check(f.indices[6]["pct"].text == "100%", "índice educación 100%")

	var gm = PANEL_GM.new()
	add_child(gm)
	var cats := {}
	for c in range(1, 7):
		cats[c] = {"avance": 0.0, "comprension": 0.0, "decisiones": 0.0, "sinergias": 0.0, "total": 0.0}
	cats[1] = {"avance": 40.0, "comprension": 10.0, "decisiones": 5.0, "sinergias": 0.0, "total": 55.0}
	gm.actualizar(cats, 66.4)
	_check(gm.total_lbl.text == "66", "total campus redondeado: %s" % gm.total_lbl.text)
	_check(gm.filas[1]["pct"].text == "55%", "Entorno 55%")
	var tramos : Array = gm.filas[1]["tramos"]
	_check(tramos.size() == 4, "4 tramos")
	_check(is_equal_approx(tramos[0].size_flags_stretch_ratio, 80.0) and is_equal_approx(tramos[3].size_flags_stretch_ratio, 5.0), "stretch 80/10/5/5")
	_check(is_equal_approx(tramos[0].get_child(0).anchor_right, 0.5), "tramo misiones a 50%")
	_check(is_equal_approx(tramos[1].get_child(0).anchor_right, 1.0), "tramo quiz lleno")
	_check(gm.texto_falta(cats[1]) == "Falta: completar las misiones del nivel", "falta: %s" % gm.texto_falta(cats[1]))
	_check(gm.texto_falta({"avance": 80.0, "comprension": 10.0, "decisiones": 5.0, "sinergias": 5.0}) == "¡Categoría completa!", "completa")
	gm.mostrar_popover(1)
	_check(gm.popover.visible, "popover visible al pasar el mouse")
	gm.ocultar_popover()
	_check(not gm.popover.visible, "popover se oculta")

	print("test_hud_paneles: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
