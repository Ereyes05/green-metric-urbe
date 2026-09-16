# ============================================================
# hud_aviso.gd — aviso central arriba (spec 2b §5). Un aviso a la vez:
# entra 0,15 s, se ve 2 s, sale 0,2 s. Hasta 2 pendientes; si llega un
# tercero se descarta el pendiente más viejo (antes cada aviso pisaba al
# anterior y los de sinergia se perdían).
# ============================================================
extends PanelContainer

const TEMA := preload("res://scenes/ui/hud_tema.gd")
const MAX_COLA := 2
const TOP := 20.0

var texto_lbl : Label
var cola      : Array = []
var mostrando : bool = false
var _deltas   : HBoxContainer


func _init() -> void:
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	offset_top = TOP
	custom_minimum_size = Vector2(0, 40)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	visible = false
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texto_lbl = TEMA.label("", 13, TEMA.TEXTO, 600)
	texto_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(texto_lbl)
	_deltas = HBoxContainer.new()
	_deltas.add_theme_constant_override("separation", 8)
	_deltas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(_deltas)
	add_child(hb)


func avisar(texto: String, bloqueo: bool = false, deltas: Array = []) -> void:
	var item := {"texto": texto, "bloqueo": bloqueo, "deltas": deltas}
	if not mostrando:
		_mostrar(item)
		return
	if cola.size() >= MAX_COLA:
		cola.pop_front()
	cola.append(item)


func _mostrar(item: Dictionary) -> void:
	mostrando = true
	texto_lbl.text = item["texto"]
	for c in _deltas.get_children():
		_deltas.remove_child(c)
		c.free()
	for d in item["deltas"]:
		_deltas.add_child(TEMA.label(str(d.get("texto", "")), 13, d.get("color", TEMA.TEXTO), 600))
	add_theme_stylebox_override("panel",
		TEMA.caja(TEMA.PANEL_BG, TEMA.VIDAS if item["bloqueo"] else TEMA.DORADO, 2, 10, 14, 8))
	visible = true
	offset_left = 0
	offset_right = 0
	reset_size()
	if not is_inside_tree():
		return
	modulate.a = 0.0
	offset_top = TOP + 4
	var tw := create_tween()
	tw.set_parallel()
	tw.tween_property(self, "modulate:a", 1.0, 0.15)
	tw.tween_property(self, "offset_top", TOP, 0.15)
	tw.chain().tween_interval(2.0)
	tw.chain().tween_property(self, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(_siguiente)


func _siguiente() -> void:
	mostrando = false
	visible = false
	if not cola.is_empty():
		_mostrar(cola.pop_front())
