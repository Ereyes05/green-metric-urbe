# Prueba del tema del HUD: fuentes, emoji y estilos.
# Correr: $GODOT --headless --path . res://tests/test_hud_tema.tscn
extends Node

const TEMA  := preload("res://scenes/ui/hud_tema.gd")
const BARRA := preload("res://scenes/ui/hud_barra.gd")

var _fallos := 0


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok    ", msg)
	else:
		_fallos += 1
		printerr("  FALLA ", msg)


func _ready() -> void:
	print("test_hud_tema")
	_check(TEMA.PANEL_BG.is_equal_approx(Color(16 / 255.0, 28 / 255.0, 38 / 255.0, 0.86)), "fondo panel #101C26 al 86%")
	_check(TEMA.VERDE.to_html(false) == "62d06a", "verde #62D06A")
	_check(TEMA.CATEGORIAS.size() == 7, "6 categorías + índice 0 vacío")
	_check(TEMA.CATEGORIAS[5]["color"].to_html(false) == "9b77df", "Transporte violeta")

	var p : StyleBoxFlat = TEMA.panel(TEMA.CIAN)
	_check(p.border_width_left == 2 and p.corner_radius_top_left == 12, "panel: borde 2, radio 12")
	_check(is_equal_approx(p.content_margin_left, 12.0) and is_equal_approx(p.content_margin_top, 10.0), "panel: padding 10/12")

	var r : Font = TEMA.rubik(600)
	_check(r != null, "Rubik carga")
	_check(r.has_char("Á".unicode_at(0)) and r.has_char("í".unicode_at(0)), "Rubik tiene acentos")
	_check(TEMA.rubik(600) == r, "Rubik por peso se cachea")
	_check(TEMA.pixel() != null, "Press Start 2P carga")

	# Cada emoji del HUD tiene que existir en alguna fuente de la cadena
	# (si no, en la web sale un cuadradito).
	for e in TEMA.EMOJIS_HUD:
		var cp : int = e.unicode_at(0)
		var ok := r.has_char(cp)
		for fb in r.fallbacks:
			ok = ok or fb.has_char(cp)
		_check(ok, "emoji %s (U+%X) disponible" % [e, cp])

	var l : Label = TEMA.label("Hola", 11, TEMA.TEXTO, 600)
	_check(l.get_theme_font_size("font_size") == 11, "label tamaño 11")
	_check(l.mouse_filter == Control.MOUSE_FILTER_IGNORE, "label no bloquea el mouse")

	var b = BARRA.new()
	b.configurar(TEMA.CIAN, 10)
	b.set_fraccion(1.7, false)
	_check(is_equal_approx(b.fraccion, 1.0), "barra recorta a 1.0")
	b.set_fraccion(0.45, false)
	_check(is_equal_approx(b.get_child(0).anchor_right, 0.45), "barra: anchor_right = fracción")
	b.free()
	l.free()

	print("test_hud_tema: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)
