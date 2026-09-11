# ============================================================
# mision_captacion.gd — NIVEL 4: Uso del Agua (Captación de lluvia)
# Misión de instalación de sistemas de captación de agua de
# lluvia en techos del campus. Estructura calcada de
# mision_solar.gd (mismo flujo paso a paso + grid clicable).
# ============================================================
extends CanvasLayer

signal mision_captacion_completada(mision_id: String, xp: int, ec: int)

const MISIONES_CAPTACION : Array = [
	{
		"id":       "captacion_biblioteca",
		"nombre":   "Techo de la Biblioteca",
		"icono":    "📚",
		"contexto": "El techo de la Biblioteca tiene una gran superficie de captación. Canalizando el agua de lluvia hacia tanques de almacenamiento se puede reutilizar para riego y limpieza, reduciendo el consumo de agua potable del acueducto.",
		"capacidad": "12 tanques · 4,800 L de almacenamiento",
		"cols": 4, "rows": 3,
	},
	{
		"id":       "captacion_bloque_c",
		"nombre":   "Techo del Bloque C",
		"icono":    "🏫",
		"contexto": "El Bloque C puede equiparse con un sistema de canaletas y cisternas para captar el agua de lluvia y usarla en los sanitarios y jardines cercanos.",
		"capacidad": "6 tanques · 2,400 L de almacenamiento",
		"cols": 3, "rows": 2,
	},
]

const BENEFICIOS_CAPTACION : Array = [
	"💧 Agua captada: ~18,000 L/año (temporada de lluvias)\n🌱 Reduce el uso de agua potable para riego y limpieza\n♻ Vida útil del sistema: ~15 años",
	"💧 Agua captada: ~9,000 L/año (temporada de lluvias)\n🌱 Abastece sanitarios y jardines cercanos\n♻ Vida útil del sistema: ~15 años",
]

const PASOS_CAPTACION : Array = [
	{
		"titulo": "Paso 1 — Evaluación de superficie",
		"desc":   "Se mide el área de techo disponible y la pendiente de drenaje. A mayor superficie e inclinación, más agua se puede captar por cada milímetro de lluvia.",
		"icono":  "🔍", "color": Color(0.28, 0.72, 0.95),
	},
	{
		"titulo": "Paso 2 — Instalación de canaletas",
		"desc":   "Se instalan canaletas selladas a lo largo de los bordes del techo, dirigiendo el agua hacia un punto central de recolección.",
		"icono":  "🔧", "color": Color(0.55, 0.62, 0.70),
	},
	{
		"titulo": "Paso 3 — Colocación de tanques de almacenamiento",
		"desc":   "Cada cisterna se conecta a la bajante de agua. Haz clic en cada celda para colocar un tanque de almacenamiento.",
		"icono":  "🛢️", "color": Color(0.15, 0.55, 0.90),
	},
	{
		"titulo": "Paso 4 — Sistema de filtrado",
		"desc":   "Un desviador de primeras lluvias descarta el agua inicial (más sucia) y un filtro retiene hojas y sedimentos antes de almacenar el agua limpia.",
		"icono":  "🧪", "color": Color(0.20, 0.80, 0.75),
	},
	{
		"titulo": "Paso 5 — Sistema operativo",
		"desc":   "¡Sistema activo! El agua captada se usa para riego, limpieza y sanitarios, reduciendo el consumo de agua tratada del campus.",
		"icono":  "✅", "color": Color(0.22, 0.90, 0.30),
	},
]

# ── Estado ───────────────────────────────────────────────────
var _mision_idx    : int    = 0
var _paso_actual   : int    = 0
var _mision_id     : String = ""
var _punto_ref     : Area2D = null
var _tanques_col   : Array  = []  # Array[bool] — grid de tanques colocados
var _todos_puestos : bool   = false

# ── Nodos UI ─────────────────────────────────────────────────
var _panel_root  : Panel  = null
var _titulo_lbl  : Label  = null
var _paso_lbl    : Label  = null
var _desc_lbl    : Label  = null
var _btn_cont    : Button = null
var _vis_node    : Node2D = null
var _grid_cont   : Control = null
var _cap_lbl     : Label   = null
var _ctx_lbl     : Label   = null


# ── Inner class: visual del techo + tanques ────────────────────
class RoofVisual extends Node2D:
	var paso        : int   = 0
	var cols        : int   = 4
	var rows        : int   = 3
	var tanques     : Array = []  # Array[bool]
	var _t          : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		match paso:
			0: _draw_evaluacion()
			1: _draw_canaletas()
			2: _draw_tanques()
			3: _draw_filtrado()
			4: _draw_activo()
			_: _draw_tanques()

	func _draw_evaluacion() -> void:
		# Vista de techo desde arriba
		draw_rect(Rect2(-80, -55, 160, 110), Color(0.30, 0.28, 0.30))
		draw_rect(Rect2(-80, -55, 160, 110), Color(0.45, 0.42, 0.46), false, 2.0)
		for row in 6:
			for col in 5:
				var rx := -75.0 + float(col) * 32.0
				var ry := -50.0 + float(row) * 18.0
				draw_rect(Rect2(rx, ry, 30, 16), Color(0.35, 0.33, 0.36))
				draw_rect(Rect2(rx, ry, 30, 16), Color(0.42, 0.40, 0.44), false, 1.0)
		# Nube de lluvia animada
		var by := -30.0 + sin(_t * 0.8) * 4.0
		draw_circle(Vector2(-14, by), 14.0, Color(0.60, 0.66, 0.72))
		draw_circle(Vector2(6, by - 4), 17.0, Color(0.66, 0.72, 0.78))
		draw_circle(Vector2(22, by), 13.0, Color(0.60, 0.66, 0.72))
		# Gotas cayendo
		for i in 5:
			var ciclo : float = fmod(_t * 1.4 + float(i) * 0.2, 1.0)
			var gx := -22.0 + float(i) * 11.0
			var gy := by + 16.0 + ciclo * 22.0
			draw_circle(Vector2(gx, gy), 1.6, Color(0.35, 0.70, 0.98, 1.0 - ciclo))
		# Flechas de medición
		draw_line(Vector2(-80, 60), Vector2(80, 60), Color(0.28, 0.72, 0.95, 0.7), 2.0)
		draw_line(Vector2(-80, 57), Vector2(-80, 63), Color(0.28, 0.72, 0.95, 0.7), 2.0)
		draw_line(Vector2(80, 57), Vector2(80, 63), Color(0.28, 0.72, 0.95, 0.7), 2.0)

	func _draw_canaletas() -> void:
		draw_rect(Rect2(-80, -55, 160, 110), Color(0.28, 0.26, 0.28))
		draw_rect(Rect2(-80, -55, 160, 110), Color(0.40, 0.38, 0.42), false, 1.5)
		# Canaletas en los 4 bordes
		draw_rect(Rect2(-82, -57, 164, 5), Color(0.62, 0.66, 0.70))
		draw_rect(Rect2(-82, 52, 164, 5), Color(0.62, 0.66, 0.70))
		draw_rect(Rect2(-82, -57, 5, 114), Color(0.62, 0.66, 0.70))
		draw_rect(Rect2(77, -57, 5, 114), Color(0.62, 0.66, 0.70))
		# Bajante hacia el punto de recolección
		draw_rect(Rect2(76, 40, 5, 30), Color(0.55, 0.60, 0.65))
		draw_circle(Vector2(78, 70), 4.0, Color(0.30, 0.65, 0.95))

	func _draw_tanques() -> void:
		draw_rect(Rect2(-80, -55, 160, 110), Color(0.26, 0.24, 0.27))
		draw_rect(Rect2(-82, -57, 164, 5), Color(0.55, 0.60, 0.65, 0.6))
		var cell_w := 152.0 / float(cols)
		var cell_h := 88.0  / float(rows)
		for r in rows:
			for c in cols:
				var idx := r * cols + c
				var px := -76.0 + float(c) * cell_w
				var py := -44.0 + float(r) * cell_h
				var es_puesto : bool = idx < tanques.size() and bool(tanques[idx])
				if es_puesto:
					draw_rect(Rect2(px + 1, py + 1, cell_w - 2, cell_h - 2),
							  Color(0.06, 0.20, 0.32))
					var ga := 0.10 + 0.06 * sin(_t * 2.0 + float(idx))
					draw_rect(Rect2(px + 1, py + 1, cell_w - 2, cell_h - 2),
							  Color(0.18, 0.55, 0.85, ga))
					draw_rect(Rect2(px + 1, py + 1, cell_w - 2, cell_h - 2),
							  Color(0.25, 0.62, 0.90), false, 1.5)
					# Ícono de gota en el centro del tanque
					draw_circle(Vector2(px + cell_w * 0.5, py + cell_h * 0.55), 3.0,
							  Color(0.55, 0.85, 1.0, 0.85))
				else:
					draw_rect(Rect2(px + 1, py + 1, cell_w - 2, cell_h - 2),
							  Color(0.18, 0.16, 0.18))
					draw_rect(Rect2(px + 1, py + 1, cell_w - 2, cell_h - 2),
							  Color(0.32, 0.28, 0.32), false, 1.5)
					if paso == 2:
						draw_line(Vector2(px + 4, py + 4),
								  Vector2(px + cell_w - 4, py + cell_h - 4),
								  Color(0.42, 0.38, 0.42), 1.0)
						draw_line(Vector2(px + cell_w - 4, py + 4),
								  Vector2(px + 4, py + cell_h - 4),
								  Color(0.42, 0.38, 0.42), 1.0)

	func _draw_filtrado() -> void:
		_draw_tanques()
		# Tubería hacia el filtro
		draw_line(Vector2(76, 0), Vector2(110, 0), Color(0.35, 0.68, 0.90), 3.0)
		draw_line(Vector2(110, 0), Vector2(110, 50), Color(0.35, 0.68, 0.90), 3.0)
		# Desviador de primeras lluvias
		draw_rect(Rect2(90, 50, 40, 30), Color(0.14, 0.30, 0.40))
		draw_rect(Rect2(90, 50, 40, 30), Color(0.25, 0.62, 0.80), false, 2.0)
		var pulse := 0.5 + 0.5 * sin(_t * 4.0)
		draw_circle(Vector2(110, 65), 4.0, Color(0.30, 0.85, 0.80, pulse))
		# Agua filtrada saliendo
		var wave_pts := PackedVector2Array()
		for wi in 20:
			var wt := float(wi) / 20.0
			wave_pts.append(Vector2(90 + wt * 40, 85 + sin(wt * TAU * 2 + _t * 4) * 6))
		if wave_pts.size() > 1:
			for wi in wave_pts.size() - 1:
				draw_line(wave_pts[wi], wave_pts[wi+1], Color(0.30, 0.75, 0.98, 0.80), 2.0)

	func _draw_activo() -> void:
		_draw_tanques()
		var flow_t := fmod(_t * 2.0, 1.0)
		var flow_pts := [
			Vector2(76, 0), Vector2(110, 0), Vector2(110, 50),
			Vector2(130, 65), Vector2(140, 65),
		]
		for i in flow_pts.size() - 1:
			draw_line(flow_pts[i], flow_pts[i+1], Color(0.30, 0.75, 0.98, 0.55), 2.5)
		var seg_total := float(flow_pts.size() - 1)
		var seg_idx   := int(flow_t * seg_total)
		seg_idx = clampi(seg_idx, 0, flow_pts.size() - 2)
		var seg_t   := fmod(flow_t * seg_total, 1.0)
		var flow_p  := (flow_pts[seg_idx] as Vector2).lerp(flow_pts[seg_idx + 1], seg_t)
		draw_circle(flow_p, 5.0, Color(0.40, 0.85, 1.0))
		draw_circle(flow_p, 3.0, Color(0.75, 0.95, 1.0))
		var la := 0.8 + 0.2 * sin(_t * 2.0)
		draw_circle(Vector2(140, 65), 18.0, Color(0.22, 0.88, 0.30, 0.20 * la))
		draw_arc(Vector2(140, 65), 18.0, 0.0, TAU, 24,
				 Color(0.25, 0.92, 0.32, 0.60 * la), 2.5)


# ── _ready ────────────────────────────────────────────────────
func _ready() -> void:
	layer = 20
	add_to_group("mision_captacion")
	_crear_ui()
	hide()


func _mostrar_paso() -> void:
	var p : Dictionary = PASOS_CAPTACION[_paso_actual]
	_paso_lbl.text  = "%s  %s" % [p["icono"], p["titulo"]]
	_paso_lbl.add_theme_color_override("font_color", p["color"])
	_desc_lbl.text  = p["desc"]
	(_vis_node as RoofVisual).paso = _paso_actual
	var es_ultimo := (_paso_actual == PASOS_CAPTACION.size() - 1)
	_btn_cont.text = "  ¡Sistema Activo!  🎉  " if es_ultimo else "  Continuar  ▶  "
	_btn_cont.visible = not (_paso_actual == 2)  # En paso 3 se oculta hasta poner todos los tanques
	_grid_cont.visible = (_paso_actual == 2)


func _on_continuar() -> void:
	_paso_actual += 1
	if _paso_actual >= PASOS_CAPTACION.size():
		_completar_mision()
	else:
		_mostrar_paso()


func _on_grid_click(event: InputEvent, cell_idx: int) -> void:
	if not (event is InputEventMouseButton): return
	var ev := event as InputEventMouseButton
	if not (ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT): return
	if _tanques_col[cell_idx]: return
	_tanques_col[cell_idx] = true
	(_vis_node as RoofVisual).tanques = _tanques_col
	var todos := true
	for t in _tanques_col:
		if not t: todos = false; break
	if todos:
		_todos_puestos = true
		_btn_cont.visible = true
		_btn_cont.text = "  ¡Tanques instalados!  ▶  "


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _completar_mision() -> void:
	SupabaseManager.registrar_evento(4, _mision_id, "mision_completada")
	var nm = _nivel_mgr()
	if nm:
		nm.completar_mision(4, _mision_id)
	if is_instance_valid(_punto_ref) and _punto_ref.has_method("_marcar_completado"):
		_punto_ref._marcar_completado()
	var xp : int = int(nm.XP_POR_MISION.get(4, 35)) if nm else 35
	var ec : int = int(nm.EC_POR_MISION.get(4, 12)) if nm else 12
	mision_captacion_completada.emit(_mision_id, xp, ec)
	# Panel de éxito
	var cel := Panel.new()
	cel.set_anchors_preset(Control.PRESET_CENTER)
	cel.custom_minimum_size = Vector2(500, 280)
	cel.offset_left  = -250.0; cel.offset_top    = -140.0
	cel.offset_right =  250.0; cel.offset_bottom =  140.0
	var cps := StyleBoxFlat.new()
	cps.bg_color     = Color(0.03, 0.07, 0.10, 0.98)
	cps.border_color = Color(0.20, 0.85, 0.90)
	cps.set_border_width_all(3)
	cps.set_corner_radius_all(16)
	cps.shadow_color = Color(0.05, 0.35, 0.50, 0.55)
	cps.shadow_size  = 24
	cel.add_theme_stylebox_override("panel", cps)
	add_child(cel)
	var cel_mg := MarginContainer.new()
	cel_mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for mk in ["margin_left","margin_right","margin_top","margin_bottom"]:
		cel_mg.add_theme_constant_override(mk, 20)
	cel.add_child(cel_mg)
	var cel_vb := VBoxContainer.new()
	cel_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	cel_vb.add_theme_constant_override("separation", 8)
	cel_mg.add_child(cel_vb)
	var m : Dictionary = MISIONES_CAPTACION[_mision_idx]
	var titulo_lbl := Label.new()
	titulo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_lbl.add_theme_font_size_override("font_size", 20)
	titulo_lbl.add_theme_color_override("font_color", Color(0.30, 0.85, 0.95))
	titulo_lbl.text = "🌧 ¡Sistema de captación activo!\n%s" % m["nombre"]
	cel_vb.add_child(titulo_lbl)
	var cap_lbl := Label.new()
	cap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap_lbl.add_theme_font_size_override("font_size", 13)
	cap_lbl.add_theme_color_override("font_color", Color(0.60, 0.80, 0.95))
	cap_lbl.text = "📐  " + m["capacidad"]
	cel_vb.add_child(cap_lbl)
	var sep_cel := HSeparator.new()
	cel_vb.add_child(sep_cel)
	var ben_lbl := Label.new()
	ben_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ben_lbl.add_theme_font_size_override("font_size", 13)
	ben_lbl.add_theme_color_override("font_color", Color(0.65, 0.85, 0.92))
	ben_lbl.text = BENEFICIOS_CAPTACION[_mision_idx] if _mision_idx < BENEFICIOS_CAPTACION.size() else ""
	ben_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	cel_vb.add_child(ben_lbl)
	var xp_lbl := Label.new()
	xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_lbl.add_theme_font_size_override("font_size", 16)
	xp_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.18))
	xp_lbl.text = "+%d XP  ·  +%d EcoCredits" % [xp, ec]
	cel_vb.add_child(xp_lbl)
	cel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(cel, "modulate:a", 1.0, 0.25)
	tw.tween_interval(5.0)
	tw.tween_property(cel, "modulate:a", 0.0, 0.30)
	tw.tween_callback(func():
		cel.queue_free()
		_on_salir())


func _on_salir() -> void:
	var tw := create_tween()
	tw.tween_property(_panel_root, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func(): hide(); _panel_root.modulate.a = 1.0)


# ── Crear UI ──────────────────────────────────────────────────
func _crear_ui() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color        = Color(0.0, 0.0, 0.0, 0.88)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	_panel_root = Panel.new()
	_panel_root.custom_minimum_size = Vector2(920, 580)
	_panel_root.set_anchors_preset(Control.PRESET_CENTER)
	_panel_root.offset_left   = -460.0
	_panel_root.offset_top    = -290.0
	_panel_root.offset_right  =  460.0
	_panel_root.offset_bottom =  290.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.05, 0.07, 0.10, 0.98)
	ps.border_color = Color(0.20, 0.75, 0.92)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(18)
	ps.shadow_color = Color(0.05, 0.35, 0.50, 0.50)
	ps.shadow_size  = 28
	_panel_root.add_theme_stylebox_override("panel", ps)
	add_child(_panel_root)

	# Franja celeste
	var acento := ColorRect.new()
	acento.set_anchors_preset(Control.PRESET_TOP_WIDE)
	acento.custom_minimum_size = Vector2(0, 4)
	acento.offset_bottom       = 4.0
	acento.color               = Color(0.20, 0.75, 0.92, 0.85)
	acento.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	_panel_root.add_child(acento)

	# Botón salir
	var btn_salir := Button.new()
	btn_salir.text = "✕ Salir"
	btn_salir.custom_minimum_size = Vector2(80, 30)
	btn_salir.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_salir.offset_left   = -92.0
	btn_salir.offset_top    =  8.0
	btn_salir.offset_right  = -8.0
	btn_salir.offset_bottom =  38.0
	btn_salir.add_theme_font_size_override("font_size", 11)
	var bss := StyleBoxFlat.new()
	bss.bg_color = Color(0.18, 0.06, 0.06, 0.90)
	bss.border_color = Color(0.65, 0.15, 0.15)
	bss.set_border_width_all(2)
	bss.set_corner_radius_all(8)
	btn_salir.add_theme_stylebox_override("normal", bss)
	btn_salir.add_theme_color_override("font_color", Color(0.92, 0.50, 0.50))
	btn_salir.pressed.connect(_on_salir)
	_panel_root.add_child(btn_salir)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(k, 18)
	_panel_root.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	mg.add_child(vbox)

	# Encabezado
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	_titulo_lbl = Label.new()
	_titulo_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_titulo_lbl.add_theme_font_size_override("font_size", 19)
	_titulo_lbl.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0))
	header.add_child(_titulo_lbl)

	var badge := Label.new()
	badge.text = "💧 NIVEL 4 — Uso del Agua"
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(0.30, 0.80, 0.95))
	header.add_child(badge)

	# Contexto y capacidad
	_ctx_lbl = Label.new()
	_ctx_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_ctx_lbl.add_theme_font_size_override("font_size", 12)
	_ctx_lbl.add_theme_color_override("font_color", Color(0.72, 0.78, 0.80))
	vbox.add_child(_ctx_lbl)

	_cap_lbl = Label.new()
	_cap_lbl.add_theme_font_size_override("font_size", 11)
	_cap_lbl.add_theme_color_override("font_color", Color(0.55, 0.80, 0.90))
	vbox.add_child(_cap_lbl)

	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.20, 0.75, 0.92, 0.30)
	sep_s.content_margin_top    = 1.0
	sep_s.content_margin_bottom = 1.0
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", sep_s)
	vbox.add_child(sep)

	# Fila central: visual + texto del paso
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(row)

	var vis_cont := Control.new()
	vis_cont.custom_minimum_size   = Vector2(460, 320)
	vis_cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vis_cont.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	vis_cont.clip_contents         = true
	row.add_child(vis_cont)

	_vis_node = RoofVisual.new()
	_vis_node.position = Vector2(230, 160)
	_vis_node.scale    = Vector2(1.6, 1.6)
	vis_cont.add_child(_vis_node)

	_grid_cont = Control.new()
	_grid_cont.custom_minimum_size = Vector2(244, 142)
	_grid_cont.position            = Vector2(230 - 76 * 1.6, 160 - 44 * 1.6)
	_grid_cont.visible             = false
	vis_cont.add_child(_grid_cont)

	var col_der := VBoxContainer.new()
	col_der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_der.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	col_der.add_theme_constant_override("separation", 14)
	row.add_child(col_der)

	_paso_lbl = Label.new()
	_paso_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_paso_lbl.add_theme_font_size_override("font_size", 16)
	col_der.add_child(_paso_lbl)

	_desc_lbl = Label.new()
	_desc_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desc_lbl.add_theme_font_size_override("font_size", 13)
	_desc_lbl.add_theme_color_override("font_color", Color(0.78, 0.85, 0.88))
	col_der.add_child(_desc_lbl)

	var steps_row := HBoxContainer.new()
	steps_row.alignment = BoxContainer.ALIGNMENT_CENTER
	steps_row.add_theme_constant_override("separation", 8)
	for i in PASOS_CAPTACION.size():
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(10, 10)
		dot.name = "dot_%d" % i
		var ds := StyleBoxFlat.new()
		ds.set_corner_radius_all(5)
		ds.bg_color     = Color(0.06, 0.18, 0.25)
		ds.border_color = Color(0.15, 0.45, 0.55)
		ds.set_border_width_all(2)
		dot.add_theme_stylebox_override("panel", ds)
		steps_row.add_child(dot)
	col_der.add_child(steps_row)

	_btn_cont = Button.new()
	_btn_cont.custom_minimum_size = Vector2(220, 46)
	_btn_cont.add_theme_font_size_override("font_size", 14)
	var bns := StyleBoxFlat.new()
	bns.bg_color     = Color(0.05, 0.20, 0.28)
	bns.border_color = Color(0.20, 0.75, 0.85)
	bns.set_border_width_all(2)
	bns.set_corner_radius_all(12)
	_btn_cont.add_theme_stylebox_override("normal", bns)
	_btn_cont.pressed.connect(_on_continuar)
	col_der.add_child(_btn_cont)


func iniciar(mision_idx: int, punto_node: Area2D) -> void:
	_mision_idx  = clampi(mision_idx, 0, MISIONES_CAPTACION.size() - 1)
	_punto_ref   = punto_node
	_paso_actual = 0
	_todos_puestos = false
	var m : Dictionary = MISIONES_CAPTACION[_mision_idx]
	_mision_id   = m["id"]
	SupabaseManager.registrar_evento(4, _mision_id, "mision_iniciada")
	_tanques_col = []
	var num_tanques := int(m["cols"]) * int(m["rows"])
	for _i in num_tanques:
		_tanques_col.append(false)
	var vis := _vis_node as RoofVisual
	vis.cols    = int(m["cols"])
	vis.rows    = int(m["rows"])
	vis.tanques = _tanques_col
	vis.paso    = 0
	_titulo_lbl.text = "%s  %s" % [m["icono"], m["nombre"]]
	_ctx_lbl.text    = m["contexto"]
	_cap_lbl.text    = "📐  " + m["capacidad"]
	_crear_grid_dinamico(int(m["cols"]), int(m["rows"]))
	_mostrar_paso()
	show()
	var hb = get_tree().get_first_node_in_group("hint_bubble")
	if hb:
		hb.push("primer_captacion",
			"🌧 Sigue los pasos para instalar un sistema de captación de agua de lluvia.")


func _crear_grid_dinamico(cols: int, rows: int) -> void:
	for child in _grid_cont.get_children():
		child.queue_free()
	const SCALE_F : float = 1.6
	var cell_w := 152.0 * SCALE_F / float(cols)
	var cell_h := 88.0  * SCALE_F / float(rows)
	_grid_cont.position = Vector2(230 - 76 * SCALE_F, 160 - 44 * SCALE_F)
	_grid_cont.custom_minimum_size = Vector2(152 * SCALE_F, 88 * SCALE_F)
	for r in rows:
		for c in cols:
			var idx := r * cols + c
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(cell_w - 2, cell_h - 2)
			btn.position = Vector2(float(c) * cell_w + 1, float(r) * cell_h + 1)
			var bss := StyleBoxFlat.new()
			bss.bg_color = Color(0.0, 0.0, 0.0, 0.0)
			btn.add_theme_stylebox_override("normal", bss)
			btn.add_theme_stylebox_override("hover", bss)
			btn.add_theme_stylebox_override("pressed", bss)
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			btn.gui_input.connect(_on_grid_click.bind(idx))
			_grid_cont.add_child(btn)
