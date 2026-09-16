# ============================================================
# hud_banner_zona.gd — banner de zona abajo al centro (spec 2b §4).
# Queda visible mientras el jugador está en la zona (la pista
# «E · interactuar» tiene que verse); entra en 0,18 s y sale en 0,25 s.
# ============================================================
extends PanelContainer

const TEMA := preload("res://scenes/ui/hud_tema.gd")

const TOP := -67.0
const BOTTOM := -16.0

var titulo_lbl    : Label
var subtitulo_lbl : Label
var activo        : bool = false
var _icono_lbl    : Label
var _tween        : Tween = null


func _init() -> void:
	set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	offset_left = -210
	offset_right = 210
	offset_top = TOP
	offset_bottom = BOTTOM
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	add_theme_stylebox_override("panel", TEMA.caja(TEMA.PANEL_BG, TEMA.VERDE, 2, 12, 12, 6))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icono_lbl = TEMA.label("🌍", 20, TEMA.TEXTO)
	hb.add_child(_icono_lbl)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	titulo_lbl = TEMA.label("", 11, TEMA.TEXTO, 400, true)
	titulo_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	titulo_lbl.clip_text = true
	vb.add_child(titulo_lbl)
	subtitulo_lbl = TEMA.label("", 11, TEMA.VERDE)
	vb.add_child(subtitulo_lbl)
	hb.add_child(vb)
	var hint := TEMA.label("E · interactuar", 10, TEMA.APAGADO)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(hint)
	add_child(hb)


func mostrar(icono: String, titulo: String, subtitulo: String, color: Color) -> void:
	activo = true
	_icono_lbl.text = icono
	titulo_lbl.text = titulo
	subtitulo_lbl.text = subtitulo
	subtitulo_lbl.add_theme_color_override("font_color", color)
	add_theme_stylebox_override("panel", TEMA.caja(TEMA.PANEL_BG, color, 2, 12, 12, 6))
	visible = true
	_matar_tween()
	if not is_inside_tree():
		return
	modulate.a = 0.0
	offset_top = TOP + 12
	offset_bottom = BOTTOM + 12
	_tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, 0.18)
	_tween.tween_property(self, "offset_top", TOP, 0.18)
	_tween.tween_property(self, "offset_bottom", BOTTOM, 0.18)


func ocultar() -> void:
	activo = false
	_matar_tween()
	if not is_inside_tree():
		visible = false
		return
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	_tween.tween_callback(func(): if not activo: visible = false)


func _matar_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	offset_top = TOP
	offset_bottom = BOTTOM
	modulate.a = 1.0
