# ============================================================
# mision_reciclar.gd — NIVEL 3: Manejo de Residuos
# Panel interactivo de clasificación por arrastre (drag-and-drop).
# El jugador arrastra objetos donados a su contenedor correcto.
# ============================================================
extends CanvasLayer

signal mision_reciclaje_completada(mision_id: String, xp: int, ec: int)

# ── Categorías de reciclaje ───────────────────────────────────
const CATEGORIAS : Array = [
	{"id": "electronico", "icono": "🖥️", "nombre": "Electrónicos",  "color": Color(0.20, 0.45, 0.80)},
	{"id": "plastico",    "icono": "🧴",  "nombre": "Plásticos",     "color": Color(0.15, 0.68, 0.85)},
	{"id": "tapa",        "icono": "🔴",  "nombre": "Tapas",         "color": Color(0.85, 0.55, 0.10)},
	{"id": "papel",       "icono": "📄",  "nombre": "Papel/Cartón",  "color": Color(0.80, 0.72, 0.18)},
	{"id": "vidrio",      "icono": "🍾",  "nombre": "Vidrio",        "color": Color(0.22, 0.75, 0.55)},
	{"id": "metal",       "icono": "🥫",  "nombre": "Metal",         "color": Color(0.60, 0.62, 0.65)},
	{"id": "organico",    "icono": "🌿",  "nombre": "Orgánico",      "color": Color(0.28, 0.62, 0.18)},
]

# ── Pool de objetos reciclables ───────────────────────────────
const ITEMS_POOL : Array = [
	# Electrónicos
	{"emoji": "💾", "nombre": "Módulo RAM",          "cat": "electronico"},
	{"emoji": "⚙️", "nombre": "Procesador CPU",      "cat": "electronico"},
	{"emoji": "🔌", "nombre": "Cable USB",            "cat": "electronico"},
	{"emoji": "🖱️","nombre": "Mouse viejo",          "cat": "electronico"},
	{"emoji": "⌨️","nombre": "Teclado viejo",         "cat": "electronico"},
	{"emoji": "💿", "nombre": "Disco duro HDD",       "cat": "electronico"},
	{"emoji": "📟", "nombre": "Tarjeta de red",       "cat": "electronico"},
	# Plásticos
	{"emoji": "🧴", "nombre": "Botella PET",          "cat": "plastico"},
	{"emoji": "🥛", "nombre": "Envase de yogur",      "cat": "plastico"},
	{"emoji": "🛍️","nombre": "Bolsa plástica",       "cat": "plastico"},
	{"emoji": "🥤", "nombre": "Vaso plástico",        "cat": "plastico"},
	{"emoji": "📦", "nombre": "Recipiente PET",       "cat": "plastico"},
	# Tapas de botella
	{"emoji": "🔴", "nombre": "Tapa roja",            "cat": "tapa"},
	{"emoji": "🔵", "nombre": "Tapa azul",            "cat": "tapa"},
	{"emoji": "🟠", "nombre": "Tapa de caja de jugo", "cat": "tapa"},
	{"emoji": "🟡", "nombre": "Tapa de frasco",       "cat": "tapa"},
	{"emoji": "⚪", "nombre": "Tapa blanca PET",      "cat": "tapa"},
	# Papel
	{"emoji": "📄", "nombre": "Hoja de papel",        "cat": "papel"},
	{"emoji": "📰", "nombre": "Periódico",            "cat": "papel"},
	{"emoji": "📦", "nombre": "Caja de cartón",       "cat": "papel"},
	{"emoji": "📓", "nombre": "Cuaderno viejo",       "cat": "papel"},
	{"emoji": "📖", "nombre": "Revista",              "cat": "papel"},
	# Vidrio
	{"emoji": "🍾", "nombre": "Botella de vidrio",    "cat": "vidrio"},
	{"emoji": "🫙", "nombre": "Frasco de vidrio",     "cat": "vidrio"},
	{"emoji": "🥃", "nombre": "Vaso de vidrio",       "cat": "vidrio"},
	# Metal
	{"emoji": "🥫", "nombre": "Lata de refresco",     "cat": "metal"},
	{"emoji": "🪣", "nombre": "Lata de atún",         "cat": "metal"},
	{"emoji": "🔩", "nombre": "Tornillos y grapas",   "cat": "metal"},
	{"emoji": "📎", "nombre": "Clips de metal",       "cat": "metal"},
	# Orgánico
	{"emoji": "🍊", "nombre": "Cáscara de naranja",   "cat": "organico"},
	{"emoji": "🍕", "nombre": "Restos de comida",     "cat": "organico"},
	{"emoji": "🍂", "nombre": "Hojas secas",          "cat": "organico"},
	{"emoji": "🍵", "nombre": "Bolsita de té",        "cat": "organico"},
	{"emoji": "🌽", "nombre": "Residuo de verduras",  "cat": "organico"},
]

const ITEMS_POR_MISION : int = 8
const COLS              : int = 4
const ITEM_W            : float = 112.0
const ITEM_H            : float = 92.0
const ITEM_GAP          : float = 10.0
const BIN_H             : float = 128.0

# ── Estado ────────────────────────────────────────────────────
var _mision_id    : String = ""
var _zona_nombre  : String = ""
var _zona_ref     : Node2D = null

var _items_mision : Array = []
var _items_estado : Array = []   # "pendiente" | "correcto"
var _items_nodes  : Array = []   # Array[Panel]
var _items_origin : Array = []   # Array[Vector2] in _panel coords

var _correctos        : int     = 0
var _drag_idx         : int     = -1
var _drag_offset      : Vector2 = Vector2.ZERO
var _bins_highlighted : Array   = []  # Array[bool]

var _panel        : Panel   = null
var _items_area   : Control = null
var _bins_nodes   : Array   = []
var _progress_lbl : Label   = null
var _title_lbl    : Label   = null


func _ready() -> void:
	layer = 20
	add_to_group("mision_reciclaje")
	_crear_ui()
	hide()


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


# ── API pública ───────────────────────────────────────────────
func iniciar(mision_id: String, zona_nombre: String, zona_ref: Node2D) -> void:
	_mision_id   = mision_id
	_zona_nombre = zona_nombre
	_zona_ref    = zona_ref
	_drag_idx    = -1
	_correctos   = 0
	SupabaseManager.registrar_evento(3, _mision_id, "mision_iniciada",
		{"zona": zona_nombre})

	_title_lbl.text = "♻  Punto de Donación — %s" % zona_nombre

	# Seleccionar items aleatorios garantizando variedad de categorías
	var pool : Array = ITEMS_POOL.duplicate()
	pool.shuffle()
	_items_mision = pool.slice(0, ITEMS_POR_MISION)

	_items_estado.clear()
	for _i in _items_mision.size():
		_items_estado.append("pendiente")

	_bins_highlighted.clear()
	for _i in CATEGORIAS.size():
		_bins_highlighted.append(false)

	_actualizar_progress()

	show()
	_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, 0.25)

	call_deferred("_posicionar_items")


# ── Construcción de items (diferida para esperar layout) ──────
func _posicionar_items() -> void:
	for node in _items_nodes:
		if is_instance_valid(node): node.queue_free()
	_items_nodes.clear()
	_items_origin.clear()

	# Obtener posición del items_area en espacio del panel
	var ia_global     := _items_area.global_position
	var panel_global  := _panel.global_position
	var ia_in_panel   := ia_global - panel_global

	var items_row_w   := COLS * ITEM_W + (COLS - 1) * ITEM_GAP
	var area_w        := _panel.size.x - 32.0   # panel width minus margins
	var x_start       := ia_in_panel.x + (area_w - items_row_w) * 0.5
	var y_start       := ia_in_panel.y

	for i in _items_mision.size():
		var col := i % COLS
		var row := i / COLS
		var pos := Vector2(
			x_start + col * (ITEM_W + ITEM_GAP),
			y_start + row * (ITEM_H + ITEM_GAP)
		)
		var card := _crear_item_card(i)
		_panel.add_child(card)
		card.position = pos
		card.z_index  = 5
		_items_nodes.append(card)
		_items_origin.append(pos)

	_actualizar_progress()


func _crear_item_card(idx: int) -> Panel:
	var item : Dictionary = _items_mision[idx]
	var cat_color := _color_for_cat(item["cat"])

	var card := Panel.new()
	card.custom_minimum_size = Vector2(ITEM_W, ITEM_H)
	card.size                = Vector2(ITEM_W, ITEM_H)
	card.mouse_filter        = Control.MOUSE_FILTER_STOP
	card.set_meta("item_idx", idx)

	var st := StyleBoxFlat.new()
	st.bg_color     = Color(0.07, 0.10, 0.18)
	st.border_color = cat_color.darkened(0.35)
	st.set_border_width_all(2)
	st.set_corner_radius_all(10)
	card.add_theme_stylebox_override("panel", st)

	# Barra de color de categoría (top)
	var bar := ColorRect.new()
	bar.color = cat_color
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 5.0
	bar.mouse_filter  = Control.MOUSE_FILTER_PASS
	card.add_child(bar)

	# Emoji
	var emo := Label.new()
	emo.text = item["emoji"]
	emo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emo.add_theme_font_size_override("font_size", 34)
	emo.set_anchors_preset(Control.PRESET_TOP_WIDE)
	emo.offset_top    = 8
	emo.offset_bottom = 55
	emo.mouse_filter  = Control.MOUSE_FILTER_PASS
	card.add_child(emo)

	# Nombre
	var nom := Label.new()
	nom.text = item["nombre"]
	nom.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nom.add_theme_font_size_override("font_size", 10)
	nom.add_theme_color_override("font_color", Color(0.88, 0.92, 0.95))
	nom.autowrap_mode = TextServer.AUTOWRAP_WORD
	nom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nom.offset_top    = -34
	nom.offset_bottom = -4
	nom.mouse_filter  = Control.MOUSE_FILTER_PASS
	card.add_child(nom)

	card.gui_input.connect(func(ev: InputEvent): _on_card_input(ev, idx))
	return card


# ── Drag ─────────────────────────────────────────────────────
func _on_card_input(event: InputEvent, idx: int) -> void:
	if not (event is InputEventMouseButton): return
	var ev := event as InputEventMouseButton
	if ev.button_index != MOUSE_BUTTON_LEFT or not ev.pressed: return
	if _items_estado[idx] != "pendiente": return
	if _drag_idx >= 0: return

	_drag_idx    = idx
	_drag_offset = ev.position

	var card := _items_nodes[idx] as Panel
	card.z_index = 200

	var tw := create_tween()
	tw.tween_property(card, "scale", Vector2(1.10, 1.10), 0.10)
	tw.tween_property(card, "scale", Vector2(1.04, 1.04), 0.08)

	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not visible or _drag_idx < 0: return

	var card  := _items_nodes[_drag_idx] as Panel
	var mouse := get_viewport().get_mouse_position()
	card.global_position = mouse - _drag_offset

	# Resaltar contenedor bajo el cursor
	var card_center := card.global_position + card.size * 0.5
	for i in _bins_nodes.size():
		var over := (_bins_nodes[i] as Panel).get_global_rect().has_point(card_center)
		if over != _bins_highlighted[i]:
			_bins_highlighted[i] = over
			_set_bin_highlight(i, over)


func _input(event: InputEvent) -> void:
	if not visible or _drag_idx < 0: return
	if not (event is InputEventMouseButton): return
	var ev := event as InputEventMouseButton
	if ev.button_index != MOUSE_BUTTON_LEFT or ev.pressed: return

	# Soltar
	var card        := _items_nodes[_drag_idx] as Panel
	var card_center := card.global_position + card.size * 0.5
	var dropped_bin := -1
	for i in _bins_nodes.size():
		if (_bins_nodes[i] as Panel).get_global_rect().has_point(card_center):
			dropped_bin = i
			break

	# Reset highlights
	for i in _bins_nodes.size():
		if _bins_highlighted[i]:
			_bins_highlighted[i] = false
			_set_bin_highlight(i, false)

	var saved_idx := _drag_idx
	_drag_idx = -1

	if dropped_bin < 0:
		_regresar_al_origen(saved_idx)
	else:
		var item_cat : String = (_items_mision[saved_idx] as Dictionary)["cat"]
		var bin_cat  : String = (CATEGORIAS[dropped_bin] as Dictionary)["id"]
		if item_cat == bin_cat:
			_clasificar_correcto(saved_idx, dropped_bin)
		else:
			_clasificar_incorrecto(saved_idx)

	get_viewport().set_input_as_handled()


# ── Resolución del drop ───────────────────────────────────────
func _regresar_al_origen(idx: int) -> void:
	var card         := _items_nodes[idx] as Panel
	var origin_global : Vector2 = _panel.global_position + (_items_origin[idx] as Vector2)
	card.z_index = 5
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(card, "global_position", origin_global, 0.28)
	tw.parallel().tween_property(card, "scale", Vector2(1.0, 1.0), 0.28)


func _clasificar_correcto(idx: int, bin_idx: int) -> void:
	_items_estado[idx] = "correcto"
	_correctos += 1

	var card := _items_nodes[idx] as Panel
	card.z_index = 5

	# Estilo verde
	var st := StyleBoxFlat.new()
	st.bg_color     = Color(0.06, 0.28, 0.09)
	st.border_color = Color(0.22, 0.92, 0.28)
	st.set_border_width_all(3)
	st.set_corner_radius_all(10)
	card.add_theme_stylebox_override("panel", st)

	# Animar hacia el bin y desvanecer
	var bin        := _bins_nodes[bin_idx] as Panel
	var bin_center := bin.global_position + bin.size * 0.5
	var tw := create_tween().set_ease(Tween.EASE_IN)
	tw.tween_property(card, "global_position", bin_center - card.size * 0.5, 0.22)
	tw.parallel().tween_property(card, "scale", Vector2(0.25, 0.25), 0.22)
	tw.parallel().tween_property(card, "modulate:a", 0.0, 0.22)
	tw.tween_callback(func(): card.visible = false)

	_flash_bin_exito(bin_idx)
	_actualizar_progress()
	_sfx("xp")

	if _correctos >= _items_mision.size():
		var tw2 := create_tween()
		tw2.tween_interval(0.7)
		tw2.tween_callback(_completar_mision)


func _clasificar_incorrecto(idx: int) -> void:
	_sfx("error")
	var card          := _items_nodes[idx] as Panel
	var origin_global : Vector2 = _panel.global_position + (_items_origin[idx] as Vector2)
	card.z_index = 5

	# Estilo rojo momentáneo
	var st := StyleBoxFlat.new()
	st.bg_color     = Color(0.28, 0.05, 0.05)
	st.border_color = Color(0.88, 0.18, 0.18)
	st.set_border_width_all(3)
	st.set_corner_radius_all(10)
	card.add_theme_stylebox_override("panel", st)

	# Regresar y sacudir
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(card, "global_position", origin_global, 0.25)
	tw.parallel().tween_property(card, "scale", Vector2(1.0, 1.0), 0.25)
	tw.tween_callback(func(): _sacudir_card(card, idx))


func _sacudir_card(card: Panel, idx: int) -> void:
	var base_x : float = (_items_origin[idx] as Vector2).x
	var tw := create_tween()
	for _i in 3:
		tw.tween_property(card, "position:x", base_x + 7, 0.045)
		tw.tween_property(card, "position:x", base_x - 7, 0.045)
	tw.tween_property(card, "position:x", base_x, 0.05)
	tw.tween_callback(func(): _reset_card_style(card, (_items_mision[idx] as Dictionary)["cat"]))


func _reset_card_style(card: Panel, cat_id: String) -> void:
	var col := _color_for_cat(cat_id)
	var st := StyleBoxFlat.new()
	st.bg_color     = Color(0.07, 0.10, 0.18)
	st.border_color = col.darkened(0.35)
	st.set_border_width_all(2)
	st.set_corner_radius_all(10)
	card.add_theme_stylebox_override("panel", st)


func _flash_bin_exito(bin_idx: int) -> void:
	var bin := _bins_nodes[bin_idx] as Panel
	var tw := create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(bin, "scale", Vector2(1.15, 1.15), 0.12)
	tw.tween_property(bin, "scale", Vector2(1.0,  1.0),  0.14)


func _set_bin_highlight(i: int, on: bool) -> void:
	var cat := CATEGORIAS[i] as Dictionary
	var col := cat["color"] as Color
	var st  := StyleBoxFlat.new()
	if on:
		st.bg_color     = col.darkened(0.4)
		st.border_color = col
		st.set_border_width_all(4)
		st.shadow_color = Color(col.r, col.g, col.b, 0.55)
		st.shadow_size  = 10
	else:
		st.bg_color     = col.darkened(0.72)
		st.border_color = col.darkened(0.25)
		st.set_border_width_all(2)
	st.set_corner_radius_all(12)
	(_bins_nodes[i] as Panel).add_theme_stylebox_override("panel", st)


func _actualizar_progress() -> void:
	_progress_lbl.text = "%d / %d  ✓" % [_correctos, _items_mision.size()]


# ── Completar misión ──────────────────────────────────────────
func _completar_mision() -> void:
	SupabaseManager.registrar_evento(3, _mision_id, "mision_completada",
		{"correctos": _correctos})
	var nm = _nivel_mgr()
	if nm:
		nm.completar_mision(3, _mision_id)
	if is_instance_valid(_zona_ref) and _zona_ref.has_method("_marcar_completado"):
		_zona_ref._marcar_completado()
	var xp : int = int(nm.XP_POR_MISION.get(3, 35)) if nm else 35
	var ec : int = int(nm.EC_POR_MISION.get(3, 12)) if nm else 12
	mision_reciclaje_completada.emit(_mision_id, xp, ec)
	_mostrar_metricas(xp, ec)


func _mostrar_metricas(xp: int, ec: int) -> void:
	var met := Panel.new()
	met.set_anchors_preset(Control.PRESET_FULL_RECT)
	var mst := StyleBoxFlat.new()
	mst.bg_color     = Color(0.04, 0.08, 0.06, 0.98)
	mst.border_color = Color(0.22, 0.90, 0.28)
	mst.set_border_width_all(3)
	mst.set_corner_radius_all(16)
	met.add_theme_stylebox_override("panel", mst)
	met.modulate.a = 0.0
	_panel.add_child(met)

	var tw := create_tween()
	tw.tween_property(met, "modulate:a", 1.0, 0.30)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left   = 28; vb.offset_top    = 20
	vb.offset_right  = -28; vb.offset_bottom = -20
	vb.add_theme_constant_override("separation", 10)
	met.add_child(vb)

	var tit := Label.new()
	tit.text = "♻ ¡Clasificación Completada!\n%s" % _zona_nombre
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.add_theme_font_size_override("font_size", 17)
	tit.add_theme_color_override("font_color", Color(0.30, 1.00, 0.40))
	tit.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(tit)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.22, 0.88, 0.30, 0.45))
	vb.add_child(sep)

	var sub := Label.new()
	sub.text = "🏆  Impacto en Gestión de Residuos — GreenMetric Módulo 3"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.88, 0.80, 0.22))
	vb.add_child(sub)

	var body := Label.new()
	body.text = (
		"♻  Tasa de clasificación correcta en el campus: ↑ 12%\n"
		+ "🌍  Residuos desviados del vertedero: −340 kg / semestre\n"
		+ "⚡  Ahorro energético por reciclaje: −18% vs disposición final\n"
		+ "🖥️  Piezas electrónicas recuperadas para reutilización: +8 equipos\n"
		+ "🌱  CO₂ evitado por reciclaje y compostaje: ~45 kg / semestre\n"
		+ "🏛  Puntaje GreenMetric M3 Residuos: ↑ 15 puntos"
	)
	body.autowrap_mode  = TextServer.AUTOWRAP_WORD
	body.add_theme_font_size_override("font_size", 12)
	body.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(body)

	var xp_lbl := Label.new()
	xp_lbl.text = "+%d XP  ·  +%d EcoCredits" % [xp, ec]
	xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_lbl.add_theme_font_size_override("font_size", 15)
	xp_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.18))
	vb.add_child(xp_lbl)

	var btn := Button.new()
	btn.text = "  ¡Genial!  ✓  "
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(func():
		met.queue_free()
		_cerrar()
	)
	vb.add_child(btn)


func _cerrar() -> void:
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 0.0, 0.22)
	tw.tween_callback(func(): hide(); _panel.modulate.a = 1.0)


func _sfx(nombre: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("tocar"): am.tocar(nombre)


func _color_for_cat(cat_id: String) -> Color:
	for c in CATEGORIAS:
		if (c as Dictionary)["id"] == cat_id:
			return (c as Dictionary)["color"] as Color
	return Color(0.5, 0.5, 0.5)


# ── Construcción de UI ────────────────────────────────────────
func _crear_ui() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color        = Color(0.0, 0.0, 0.0, 0.72)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(900, 520)
	_panel.offset_left   = -450.0
	_panel.offset_top    = -260.0
	_panel.offset_right  =  450.0
	_panel.offset_bottom =  260.0
	_panel.clip_contents = false
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.07, 0.11, 0.99)
	ps.border_color = Color(0.22, 0.80, 0.28)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(18)
	ps.shadow_color = Color(0.10, 0.50, 0.15, 0.55)
	ps.shadow_size  = 28
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(k, 16)
	_panel.add_child(mg)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	mg.add_child(vb)

	# ── Header ────────────────────────────────────────────────
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	vb.add_child(hdr)

	var salir_btn := Button.new()
	salir_btn.text = "← Salir"
	salir_btn.add_theme_font_size_override("font_size", 12)
	salir_btn.custom_minimum_size = Vector2(80, 32)
	salir_btn.pressed.connect(_cerrar)
	hdr.add_child(salir_btn)

	_title_lbl = Label.new()
	_title_lbl.text = "♻  Punto de Donación"
	_title_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_lbl.add_theme_font_size_override("font_size", 16)
	_title_lbl.add_theme_color_override("font_color", Color(0.30, 1.0, 0.40))
	hdr.add_child(_title_lbl)

	_progress_lbl = Label.new()
	_progress_lbl.text = "0 / 0  ✓"
	_progress_lbl.add_theme_font_size_override("font_size", 15)
	_progress_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.18))
	_progress_lbl.custom_minimum_size   = Vector2(90, 0)
	_progress_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
	hdr.add_child(_progress_lbl)

	vb.add_child(HSeparator.new())

	# ── Zona de items (placeholder de altura fija) ────────────
	_items_area = Control.new()
	_items_area.custom_minimum_size   = Vector2(0, ITEM_H * 2 + ITEM_GAP + 8)
	_items_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_area.mouse_filter          = Control.MOUSE_FILTER_PASS
	vb.add_child(_items_area)

	vb.add_child(HSeparator.new())

	# ── Instrucción ───────────────────────────────────────────
	var instr := Label.new()
	instr.text = "↓  Arrastra cada objeto al contenedor correcto  ↓"
	instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instr.add_theme_font_size_override("font_size", 12)
	instr.add_theme_color_override("font_color", Color(0.60, 0.78, 0.62))
	vb.add_child(instr)

	# ── Contenedores (bins) ───────────────────────────────────
	var bins_hb := HBoxContainer.new()
	bins_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	bins_hb.add_theme_constant_override("separation", 5)
	vb.add_child(bins_hb)

	_bins_nodes.clear()
	for i in CATEGORIAS.size():
		var bin := _crear_bin(CATEGORIAS[i] as Dictionary)
		bins_hb.add_child(bin)
		_bins_nodes.append(bin)


func _crear_bin(cat: Dictionary) -> Panel:
	var col := cat["color"] as Color
	var bin := Panel.new()
	bin.custom_minimum_size = Vector2(114, BIN_H)
	bin.mouse_filter        = Control.MOUSE_FILTER_PASS

	var st := StyleBoxFlat.new()
	st.bg_color     = col.darkened(0.72)
	st.border_color = col.darkened(0.25)
	st.set_border_width_all(2)
	st.set_corner_radius_all(12)
	bin.add_theme_stylebox_override("panel", st)

	var vb2 := VBoxContainer.new()
	vb2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb2.offset_left   = 4;  vb2.offset_top    = 8
	vb2.offset_right  = -4; vb2.offset_bottom = -6
	vb2.alignment     = BoxContainer.ALIGNMENT_CENTER
	vb2.add_theme_constant_override("separation", 4)
	vb2.mouse_filter  = Control.MOUSE_FILTER_PASS
	bin.add_child(vb2)

	var icono := Label.new()
	icono.text = cat["icono"]
	icono.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icono.add_theme_font_size_override("font_size", 30)
	icono.mouse_filter = Control.MOUSE_FILTER_PASS
	vb2.add_child(icono)

	var nombre := Label.new()
	nombre.text = cat["nombre"]
	nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre.add_theme_font_size_override("font_size", 10)
	nombre.add_theme_color_override("font_color", Color(0.85, 0.90, 0.88))
	nombre.autowrap_mode = TextServer.AUTOWRAP_WORD
	nombre.mouse_filter  = Control.MOUSE_FILTER_PASS
	vb2.add_child(nombre)

	var hint := Label.new()
	hint.text = "[ soltar aquí ]"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 9)
	hint.add_theme_color_override("font_color", col.lightened(0.25))
	hint.modulate.a  = 0.55
	hint.mouse_filter = Control.MOUSE_FILTER_PASS
	vb2.add_child(hint)

	return bin
