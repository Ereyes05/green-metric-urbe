# ============================================================
# hud_panel_greenmetric.gd — panel arriba a la derecha (spec 2b §2):
# puntaje del campus (0–100), una fila por categoría con barra partida
# 80/10/5/5 (misiones · quiz · decisiones · sinergias) y un popover con
# el desglose al pasar el mouse.
# ============================================================
extends PanelContainer

const TEMA  := preload("res://scenes/ui/hud_tema.gd")
const BARRA := preload("res://scenes/ui/hud_barra.gd")

const COMPONENTES : Array = [
	{"clave": "avance",      "nombre": "Misiones",   "tope": 80.0, "alpha": 1.00, "corto": "Misión 80"},
	{"clave": "comprension", "nombre": "Quiz",       "tope": 10.0, "alpha": 0.78, "corto": "Quiz 10"},
	{"clave": "decisiones",  "nombre": "Decisiones", "tope": 5.0,  "alpha": 0.58, "corto": "Decis. 5"},
	{"clave": "sinergias",   "nombre": "Sinergias",  "tope": 5.0,  "alpha": 0.40, "corto": "Sinerg. 5"},
]
const FALTA : Dictionary = {
	"avance":      "completar las misiones del nivel",
	"comprension": "responder el quiz al primer intento",
	"decisiones":  "tomar buenas decisiones del nivel",
	"sinergias":   "acciones de otros niveles que suman acá",
}

var total_lbl  : Label
var barra_total
var filas      : Dictionary = {}
var popover    : PanelContainer
var _pop_vb    : VBoxContainer
var _datos     : Dictionary = {}


func _init() -> void:
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	offset_left = -284
	offset_right = -16
	offset_top = 16
	custom_minimum_size = Vector2(268, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", TEMA.panel(TEMA.CIAN))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vb)

	var tit := _hbox(6)
	var t := TEMA.label("GreenMetric", 10, TEMA.CIAN, 400, true)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tit.add_child(t)
	tit.add_child(TEMA.label("0–100", 10, TEMA.APAGADO))
	vb.add_child(tit)

	var caja := PanelContainer.new()
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_theme_stylebox_override("panel", TEMA.caja(Color(TEMA.CIAN, 0.12), Color(TEMA.CIAN, 0.45), 1, 8, 9, 7))
	var hc := _hbox(10)
	total_lbl = TEMA.label("0", 16, TEMA.TEXTO, 400, true)
	total_lbl.custom_minimum_size.x = 52
	hc.add_child(total_lbl)
	barra_total = BARRA.new()
	barra_total.configurar(TEMA.CIAN, 8)
	barra_total.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra_total.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hc.add_child(barra_total)
	caja.add_child(hc)
	vb.add_child(caja)

	var lista := VBoxContainer.new()
	lista.add_theme_constant_override("separation", 0)
	lista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for cat in range(1, 7):
		lista.add_child(_crear_fila(cat))
	vb.add_child(lista)

	var ley := VBoxContainer.new()
	ley.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ley.add_theme_constant_override("separation", 7)
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = TEMA.SEPARADOR
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ley.add_child(sep)
	var chips := _hbox(8)
	for comp in COMPONENTES:
		var h := _hbox(3)
		var chip := Panel.new()
		chip.custom_minimum_size = Vector2(7, 7)
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_theme_stylebox_override("panel", TEMA.caja(Color(TEMA.LEYENDA, comp["alpha"]), Color.TRANSPARENT, 0, 2))
		h.add_child(chip)
		h.add_child(TEMA.label(comp["corto"], 9, TEMA.TEXTO_3))
		chips.add_child(h)
	ley.add_child(chips)
	vb.add_child(ley)

	popover = PanelContainer.new()
	popover.top_level = true
	popover.visible = false
	popover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popover.custom_minimum_size = Vector2(186, 0)
	var ps := TEMA.caja(TEMA.POPOVER_BG, TEMA.CIAN, 2, 10, 10, 9)
	popover.add_theme_stylebox_override("panel", ps)
	_pop_vb = VBoxContainer.new()
	_pop_vb.add_theme_constant_override("separation", 4)
	_pop_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popover.add_child(_pop_vb)
	add_child(popover)


func _hbox(sep: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


func _crear_fila(cat: int) -> Control:
	var info : Dictionary = TEMA.CATEGORIAS[cat]
	var col : Color = info["color"]
	var fila := VBoxContainer.new()
	fila.custom_minimum_size.y = 34
	fila.add_theme_constant_override("separation", 3)
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.mouse_filter = Control.MOUSE_FILTER_STOP
	fila.mouse_entered.connect(mostrar_popover.bind(cat))
	fila.mouse_exited.connect(ocultar_popover)

	var lab := _hbox(6)
	lab.custom_minimum_size.y = 17
	var ic := TEMA.label(info["icono"], 14, TEMA.TEXTO)
	ic.custom_minimum_size.x = 14
	lab.add_child(ic)
	var nom := TEMA.label(info["nombre"], 12, TEMA.TEXTO)
	nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lab.add_child(nom)
	var pct := TEMA.label("0%", 11, TEMA.TEXTO_2, 600, false, true)
	lab.add_child(pct)
	fila.add_child(lab)

	var mg := MarginContainer.new()
	mg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mg.add_theme_constant_override("margin_left", 20)
	var hb := _hbox(2)
	hb.custom_minimum_size.y = 7
	var tramos : Array[Panel] = []
	for i in COMPONENTES.size():
		var comp : Dictionary = COMPONENTES[i]
		var tramo := Panel.new()
		tramo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tramo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tramo.size_flags_stretch_ratio = comp["tope"]
		var st := TEMA.caja(TEMA.TRACK, Color.TRANSPARENT, 0, 0)
		var sf := TEMA.caja(Color(col, comp["alpha"]), Color.TRANSPARENT, 0, 0)
		if i == 0:
			for s in [st, sf]:
				s.corner_radius_top_left = 3
				s.corner_radius_bottom_left = 3
		if i == COMPONENTES.size() - 1:
			for s in [st, sf]:
				s.corner_radius_top_right = 3
				s.corner_radius_bottom_right = 3
		tramo.add_theme_stylebox_override("panel", st)
		var fill := Panel.new()
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fill.add_theme_stylebox_override("panel", sf)
		fill.anchor_bottom = 1.0
		fill.anchor_right = 0.0
		tramo.add_child(fill)
		tramos.append(tramo)
		hb.add_child(tramo)
	mg.add_child(hb)
	fila.add_child(mg)
	filas[cat] = {"pct": pct, "tramos": tramos, "nodo": fila}
	return fila


func actualizar(categorias: Dictionary, total: float) -> void:
	_datos = categorias
	total_lbl.text = str(roundi(total))
	barra_total.set_fraccion(total / 100.0)
	for cat in filas.keys():
		var d : Dictionary = categorias.get(cat, {})
		filas[cat]["pct"].text = "%d%%" % roundi(float(d.get("total", 0.0)))
		var tramos : Array = filas[cat]["tramos"]
		for i in COMPONENTES.size():
			var comp : Dictionary = COMPONENTES[i]
			var f := clampf(float(d.get(comp["clave"], 0.0)) / comp["tope"], 0.0, 1.0)
			tramos[i].get_child(0).anchor_right = f


func texto_falta(datos: Dictionary) -> String:
	var peor := ""
	var hueco := 0.0
	for comp in COMPONENTES:
		var h : float = comp["tope"] - float(datos.get(comp["clave"], 0.0))
		if h > hueco + 0.001:
			hueco = h
			peor = comp["clave"]
	return "¡Categoría completa!" if peor == "" else "Falta: " + FALTA[peor]


func mostrar_popover(cat: int) -> void:
	for c in _pop_vb.get_children():
		c.queue_free()
	var info : Dictionary = TEMA.CATEGORIAS[cat]
	var d : Dictionary = _datos.get(cat, {})
	_pop_vb.add_child(TEMA.label("%s %s · %d/100" % [info["icono"], info["nombre"], roundi(float(d.get("total", 0.0)))], 11, TEMA.TEXTO, 600))
	for comp in COMPONENTES:
		var h := _hbox(6)
		var chip := Panel.new()
		chip.custom_minimum_size = Vector2(8, 8)
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_theme_stylebox_override("panel", TEMA.caja(Color(info["color"], comp["alpha"]), Color.TRANSPARENT, 0, 2))
		h.add_child(chip)
		var n := TEMA.label(comp["nombre"], 10, TEMA.TEXTO_2)
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(n)
		h.add_child(TEMA.label("%d/%d" % [roundi(float(d.get(comp["clave"], 0.0))), int(comp["tope"])], 10, TEMA.TEXTO, 400, false, true))
		_pop_vb.add_child(h)
	var falta := TEMA.label(texto_falta(d), 10, TEMA.DORADO)
	falta.autowrap_mode = TextServer.AUTOWRAP_WORD
	falta.custom_minimum_size.x = 164
	_pop_vb.add_child(falta)
	popover.reset_size()
	var fila : Control = filas[cat]["nodo"]
	if is_inside_tree():
		popover.global_position = Vector2(global_position.x - 186 - 10, fila.global_position.y - 6)
	popover.visible = true


func ocultar_popover() -> void:
	popover.visible = false
