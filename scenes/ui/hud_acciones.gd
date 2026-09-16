# ============================================================
# hud_acciones.gd — 5 botones abajo a la izquierda (spec 2b §3), con
# atajo de teclado 1–5. Emite `accion(indice)`; quien lo crea decide
# qué abrir.
# ============================================================
extends HBoxContainer

const TEMA := preload("res://scenes/ui/hud_tema.gd")

signal accion(indice: int)

const DEFS : Array = [
	{"emoji": "🌡", "label": "Calor",   "tip": "Mapa de calor energético", "color": TEMA.NARANJA},
	{"emoji": "📊", "label": "Reporte", "tip": "Reporte GreenMetric",      "color": TEMA.CIAN},
	{"emoji": "🏆", "label": "Ranking", "tip": "Tabla de clasificación",   "color": TEMA.DORADO},
	{"emoji": "🔬", "label": "Simular", "tip": "Simulador de decisiones",  "color": TEMA.VIOLETA},
	{"emoji": "🛒", "label": "Tienda",  "tip": "Tienda del Conocimiento",  "color": TEMA.VERDE},
]
const TECLAS : Array = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]

var botones : Array[Button] = []


func _init() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left = 16
	offset_right = 320
	offset_top = -75
	offset_bottom = -16
	add_theme_constant_override("separation", 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in DEFS.size():
		botones.append(_crear_boton(i, DEFS[i]))


func _crear_boton(i: int, d: Dictionary) -> Button:
	var col : Color = d["color"]
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(56, 59)
	btn.tooltip_text = "%s  [%d]" % [d["tip"], i + 1]
	btn.pivot_offset = Vector2(28, 29.5)
	btn.add_theme_stylebox_override("normal", TEMA.caja(TEMA.PANEL_BG, col, 2, 10))
	btn.add_theme_stylebox_override("hover", TEMA.caja(Color(col, 0.18), col, 2, 10))
	btn.add_theme_stylebox_override("pressed", TEMA.caja(Color(col, 0.18), col, 2, 10))
	var foco := TEMA.caja(Color.TRANSPARENT, TEMA.TEXTO, 2, 10)
	foco.draw_center = false
	btn.add_theme_stylebox_override("focus", foco)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.add_theme_constant_override("separation", 3)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for l in [TEMA.label(d["emoji"], 19, TEMA.TEXTO), TEMA.label(d["label"], 9, TEMA.TEXTO, 600), TEMA.label(str(i + 1), 8, TEMA.TEXTO_3)]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(l)
	btn.add_child(vb)

	btn.button_down.connect(func(): _escalar(btn, 0.96))
	btn.button_up.connect(func(): _escalar(btn, 1.0))
	btn.pressed.connect(func(): accion.emit(i))
	add_child(btn)
	return btn


func _escalar(btn: Button, s: float) -> void:
	if btn.is_inside_tree():
		btn.create_tween().tween_property(btn, "scale", Vector2(s, s), 0.08)


func tecla(keycode: int) -> bool:
	var i := TECLAS.find(keycode)
	if i < 0:
		return false
	accion.emit(i)
	return true
