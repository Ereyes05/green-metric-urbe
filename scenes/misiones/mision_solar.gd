# ============================================================
# mision_solar.gd — NIVEL 2: Energía (Paneles Fotovoltaicos)
# Misión de instalación de paneles solares en techos del campus.
# Proceso paso a paso con visualización interactiva.
# ============================================================
extends CanvasLayer

signal mision_solar_completada(mision_id: String, xp: int, ec: int)

const MISIONES_SOLAR : Array = [
	{
		"id":       "solar_rectorado",
		"nombre":   "Techo del Rectorado",
		"icono":    "🏛️",
		"contexto": "El Rectorado tiene 200 m² de techo disponible orientado al sur.\nInstalando 16 paneles fotovoltaicos de 400W cada uno, se generarían 6.4 kW de energía limpia.",
		"capacidad": "16 paneles · 6.4 kW · ~9,600 kWh/año",
		"cols": 4, "rows": 4,
	},
	{
		"id":       "solar_estacionamiento",
		"nombre":   "Pérgola Solar Estacionamiento",
		"icono":    "🚗",
		"contexto": "El estacionamiento puede convertirse en una pérgola solar que sombrea los vehículos mientras genera energía para el campus.",
		"capacidad": "8 paneles · 3.2 kW · ~4,800 kWh/año",
		"cols": 4, "rows": 2,
	},
]

const BENEFICIOS_SOLAR : Array = [
	"🌍 CO₂ evitado: ~4.2 t/año\n♻ Energía limpia: 9,600 kWh/año\n💰 Ahorro estimado: ~$1,440/año  ·  Vida útil: 25 años",
	"🌍 CO₂ evitado: ~2.5 t/año\n♻ Energía limpia: 4,800 kWh/año\n💰 Carga ~20 vehículos eléctricos/año  ·  Vida útil: 25 años",
]

const PASOS_SOLAR : Array = [
	{
		"titulo": "Paso 1 — Evaluación de superficie",
		"desc":   "Se verifica la orientación, inclinación y resistencia estructural del techo. El techo sur es ideal: máxima exposición solar en el hemisferio norte.",
		"icono":  "🔍", "color": Color(0.28, 0.88, 0.95),
	},
	{
		"titulo": "Paso 2 — Instalación de estructura soporte",
		"desc":   "Se instalan los rieles de aluminio anclados al techo con sellos impermeables. La estructura soporta hasta 150 km/h de viento.",
		"icono":  "🔧", "color": Color(0.95, 0.75, 0.15),
	},
	{
		"titulo": "Paso 3 — Colocación de paneles",
		"desc":   "Cada panel monocristalino de 400W se fija a la estructura. Haz clic en cada celda para colocar un panel fotovoltaico.",
		"icono":  "☀️", "color": Color(0.98, 0.82, 0.08),
	},
	{
		"titulo": "Paso 4 — Conexión al inversor",
		"desc":   "Los paneles se conectan en serie al inversor que convierte la corriente continua (DC) en alterna (AC) para el campus.\nEficiencia del sistema: 97%.",
		"icono":  "⚡", "color": Color(0.95, 0.58, 0.10),
	},
	{
		"titulo": "Paso 5 — Sistema operativo",
		"desc":   "¡Sistema activo! El medidor bidireccional registra la generación. El excedente se inyecta a la red.\nCarbono evitado estimado: 4.2 t CO₂/año.",
		"icono":  "✅", "color": Color(0.22, 0.90, 0.30),
	},
]

# ── Estado ───────────────────────────────────────────────────
var _mision_idx    : int    = 0
var _paso_actual   : int    = 0
var _mision_id     : String = ""
var _zona_ref      : Area2D = null
var _paneles_col   : Array  = []  # Array[bool] — grid de paneles colocados
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


# ── Inner class: visual del techo + paneles ───────────────────
class TechoVisual extends Node2D:
	var paso        : int   = 0
	var cols        : int   = 4
	var rows        : int   = 4
	var paneles     : Array = []  # Array[bool]
	var _t          : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		match paso:
			0: _draw_evaluacion()
			1: _draw_estructura()
			2: _draw_paneles()
			3: _draw_conexion()
			4: _draw_activo()
			_: _draw_paneles()

	func _draw_evaluacion() -> void:
		# Vista de techo desde arriba
		draw_rect(Rect2(-80, -55, 160, 110), Color(0.35, 0.30, 0.25))
		draw_rect(Rect2(-80, -55, 160, 110), Color(0.50, 0.44, 0.38), false, 2.0)
		# Patrón de tejas
		for row in 6:
			for col in 5:
				var rx := -75.0 + float(col) * 32.0
				var ry := -50.0 + float(row) * 18.0
				draw_rect(Rect2(rx, ry, 30, 16), Color(0.40, 0.34, 0.28))
				draw_rect(Rect2(rx, ry, 30, 16), Color(0.48, 0.42, 0.35), false, 1.0)
		# Sol animado
		var sa := _t * 0.8
		for i in 8:
			var a := sa + float(i) / 8.0 * TAU
			draw_line(Vector2(cos(a) * 55, sin(a) * 55 - 30),
					  Vector2(cos(a) * 70, sin(a) * 70 - 30),
					  Color(0.98, 0.85, 0.15, 0.55), 2.0)
		draw_circle(Vector2(0, -30), 18.0, Color(0.98, 0.85, 0.15))
		draw_circle(Vector2(0, -30), 14.0, Color(1.0, 0.92, 0.40))
		# Flechas de medición
		draw_line(Vector2(-80, 60), Vector2(80, 60), Color(0.28, 0.88, 0.95, 0.7), 2.0)
		draw_line(Vector2(-80, 57), Vector2(-80, 63), Color(0.28, 0.88, 0.95, 0.7), 2.0)
		draw_line(Vector2(80, 57), Vector2(80, 63), Color(0.28, 0.88, 0.95, 0.7), 2.0)

	func _draw_estructura() -> void:
		# Techo base
		draw_rect(Rect2(-80, -55, 160, 110), Color(0.30, 0.26, 0.22))
		draw_rect(Rect2(-80, -55, 160, 110), Color(0.45, 0.40, 0.34), false, 1.5)
		# Rieles de aluminio
		for i in 5:
			var y := -44.0 + float(i) * 22.0
			draw_rect(Rect2(-76, y, 152, 4), Color(0.70, 0.72, 0.75))
			draw_rect(Rect2(-76, y, 152, 4), Color(0.82, 0.84, 0.86, 0.6), false, 1.0)
		for i in 5:
			var x := -76.0 + float(i) * 38.0
			draw_rect(Rect2(x, -44, 4, 88), Color(0.68, 0.70, 0.72))
		# Tornillos de anclaje
		for i in 10:
			var ax := -68.0 + float(i) * 15.2
			draw_circle(Vector2(ax, -44), 2.5, Color(0.55, 0.55, 0.60))
			draw_circle(Vector2(ax,  44), 2.5, Color(0.55, 0.55, 0.60))

	func _draw_paneles() -> void:
		# Fondo de techo
		draw_rect(Rect2(-80, -55, 160, 110), Color(0.28, 0.24, 0.20))
		# Rieles (fondo)
		for i in 5:
			var y := -44.0 + float(i) * 22.0
			draw_rect(Rect2(-76, y, 152, 4), Color(0.60, 0.62, 0.65, 0.6))
		# Grid de paneles
		var cell_w := 152.0 / float(cols)
		var cell_h := 88.0  / float(rows)
		for r in rows:
			for c in cols:
				var idx := r * cols + c
				var px := -76.0 + float(c) * cell_w
				var py := -44.0 + float(r) * cell_h
				var es_puesto : bool = idx < paneles.size() and bool(paneles[idx])
				if es_puesto:
					# Panel colocado: azul oscuro con celdas
					draw_rect(Rect2(px + 1, py + 1, cell_w - 2, cell_h - 2),
							  Color(0.06, 0.10, 0.28))
					# Celdas interiores del panel
					var sc_w := (cell_w - 6) / 3.0
					var sc_h := (cell_h - 6) / 3.0
					for si in 3:
						for sj in 3:
							draw_rect(Rect2(px + 3 + float(si) * sc_w,
										   py + 3 + float(sj) * sc_h,
										   sc_w - 1, sc_h - 1),
									  Color(0.08, 0.14, 0.35))
					# Brillo del panel
					var ga := 0.10 + 0.06 * sin(_t * 2.0 + float(idx))
					draw_rect(Rect2(px + 1, py + 1, cell_w - 2, cell_h - 2),
							  Color(0.22, 0.55, 0.88, ga))
					draw_rect(Rect2(px + 1, py + 1, cell_w - 2, cell_h - 2),
							  Color(0.30, 0.60, 0.90), false, 1.5)
				else:
					# Celda vacía
					draw_rect(Rect2(px + 1, py + 1, cell_w - 2, cell_h - 2),
							  Color(0.18, 0.16, 0.14))
					draw_rect(Rect2(px + 1, py + 1, cell_w - 2, cell_h - 2),
							  Color(0.32, 0.28, 0.24), false, 1.5)
					# Cruz indicando espacio libre
					if paso == 2:
						draw_line(Vector2(px + 4, py + 4),
								  Vector2(px + cell_w - 4, py + cell_h - 4),
								  Color(0.45, 0.40, 0.35), 1.0)
						draw_line(Vector2(px + cell_w - 4, py + 4),
								  Vector2(px + 4, py + cell_h - 4),
								  Color(0.45, 0.40, 0.35), 1.0)

	func _draw_conexion() -> void:
		_draw_paneles()
		# Cables al inversor
		draw_line(Vector2(76, 0), Vector2(110, 0), Color(0.80, 0.55, 0.15), 3.0)
		draw_line(Vector2(110, 0), Vector2(110, 50), Color(0.80, 0.55, 0.15), 3.0)
		draw_line(Vector2(76, 20), Vector2(110, 20), Color(0.22, 0.22, 0.22), 3.0)
		draw_line(Vector2(110, 20), Vector2(110, 50), Color(0.22, 0.22, 0.22), 3.0)
		# Inversor
		draw_rect(Rect2(90, 50, 40, 30), Color(0.22, 0.26, 0.35))
		draw_rect(Rect2(90, 50, 40, 30), Color(0.40, 0.50, 0.70), false, 2.0)
		# LED del inversor pulsando
		var pulse := 0.5 + 0.5 * sin(_t * 4.0)
		draw_circle(Vector2(110, 65), 4.0, Color(0.20, 0.90, 0.30, pulse))
		# AC output
		var wave_pts := PackedVector2Array()
		for wi in 20:
			var wt := float(wi) / 20.0
			wave_pts.append(Vector2(90 + wt * 40, 85 + sin(wt * TAU * 2 + _t * 4) * 8))
		if wave_pts.size() > 1:
			for wi in wave_pts.size() - 1:
				draw_line(wave_pts[wi], wave_pts[wi+1], Color(0.95, 0.60, 0.10, 0.80), 2.0)

	func _draw_activo() -> void:
		_draw_paneles()
		# Animación de energía fluyendo
		var flow_t := fmod(_t * 2.0, 1.0)
		var flow_pts := [
			Vector2(76, 0), Vector2(110, 0), Vector2(110, 50),
			Vector2(130, 65), Vector2(140, 65),
		]
		for i in flow_pts.size() - 1:
			draw_line(flow_pts[i], flow_pts[i+1], Color(0.95, 0.80, 0.15, 0.55), 2.5)
		# Partícula de energía viajando
		var seg_total := float(flow_pts.size() - 1)
		var seg_idx   := int(flow_t * seg_total)
		seg_idx = clampi(seg_idx, 0, flow_pts.size() - 2)
		var seg_t   := fmod(flow_t * seg_total, 1.0)
		var flow_p  := (flow_pts[seg_idx] as Vector2).lerp(flow_pts[seg_idx + 1], seg_t)
		draw_circle(flow_p, 5.0, Color(1.0, 0.90, 0.20))
		draw_circle(flow_p, 3.0, Color(1.0, 1.0, 0.55))
		# Kw generados (pulsante)
		var kw_a := 0.8 + 0.2 * sin(_t * 2.0)
		draw_circle(Vector2(140, 65), 18.0, Color(0.22, 0.88, 0.30, 0.20 * kw_a))
		draw_arc(Vector2(140, 65), 18.0, 0.0, TAU, 24,
				 Color(0.25, 0.92, 0.32, 0.60 * kw_a), 2.5)


# ── _ready ────────────────────────────────────────────────────
func _ready() -> void:
	layer = 20
	add_to_group("mision_solar")
	_crear_ui()
	hide()


func _mostrar_paso() -> void:
	var p : Dictionary = PASOS_SOLAR[_paso_actual]
	_paso_lbl.text  = "%s  %s" % [p["icono"], p["titulo"]]
	_paso_lbl.add_theme_color_override("font_color", p["color"])
	_desc_lbl.text  = p["desc"]
	(_vis_node as TechoVisual).paso = _paso_actual
	var es_ultimo := (_paso_actual == PASOS_SOLAR.size() - 1)
	_btn_cont.text = "  ¡Sistema Activo!  🎉  " if es_ultimo else "  Continuar  ▶  "
	_btn_cont.visible = not (_paso_actual == 2)  # En paso 3 se oculta hasta poner todos los paneles
	_grid_cont.visible = (_paso_actual == 2)


func _on_continuar() -> void:
	_paso_actual += 1
	if _paso_actual >= PASOS_SOLAR.size():
		_completar_mision()
	else:
		_mostrar_paso()


func _on_grid_click(event: InputEvent, cell_idx: int) -> void:
	if not (event is InputEventMouseButton): return
	var ev := event as InputEventMouseButton
	if not (ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT): return
	if _paneles_col[cell_idx]: return
	_paneles_col[cell_idx] = true
	(_vis_node as TechoVisual).paneles = _paneles_col
	_actualizar_grid_visual()
	# Verificar si todos colocados
	var todos := true
	for p in _paneles_col:
		if not p: todos = false; break
	if todos:
		_todos_puestos = true
		_btn_cont.visible = true
		_btn_cont.text = "  ¡Paneles instalados!  ▶  "


func _actualizar_grid_visual() -> void:
	# Los botones del grid se actualizan por señal (la visual TechoVisual hace queue_redraw)
	pass


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _completar_mision() -> void:
	SupabaseManager.registrar_evento(2, _mision_id, "mision_completada")
	var nm = _nivel_mgr()
	if nm:
		nm.completar_mision(2, _mision_id)
	if is_instance_valid(_zona_ref) and _zona_ref.has_method("_marcar_completado"):
		_zona_ref._marcar_completado()
	var xp : int = int(nm.XP_POR_MISION.get(2, 50)) if nm else 50
	var ec : int = int(nm.EC_POR_MISION.get(2, 20)) if nm else 20
	mision_solar_completada.emit(_mision_id, xp, ec)
	# Panel de éxito
	var cel := Panel.new()
	cel.set_anchors_preset(Control.PRESET_CENTER)
	cel.custom_minimum_size = Vector2(500, 280)
	cel.offset_left  = -250.0; cel.offset_top    = -140.0
	cel.offset_right =  250.0; cel.offset_bottom =  140.0
	var cps := StyleBoxFlat.new()
	cps.bg_color     = Color(0.04, 0.08, 0.04, 0.98)
	cps.border_color = Color(0.22, 0.90, 0.28)
	cps.set_border_width_all(3)
	cps.set_corner_radius_all(16)
	cps.shadow_color = Color(0.10, 0.55, 0.18, 0.55)
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
	var m : Dictionary = MISIONES_SOLAR[_mision_idx]
	var titulo_lbl := Label.new()
	titulo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_lbl.add_theme_font_size_override("font_size", 20)
	titulo_lbl.add_theme_color_override("font_color", Color(0.30, 0.95, 0.35))
	titulo_lbl.text = "☀️ ¡Sistema solar activo!\n%s" % m["nombre"]
	cel_vb.add_child(titulo_lbl)
	var cap_lbl := Label.new()
	cap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap_lbl.add_theme_font_size_override("font_size", 13)
	cap_lbl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.50))
	cap_lbl.text = "📐  " + m["capacidad"]
	cel_vb.add_child(cap_lbl)
	var sep_cel := HSeparator.new()
	cel_vb.add_child(sep_cel)
	var ben_lbl := Label.new()
	ben_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ben_lbl.add_theme_font_size_override("font_size", 13)
	ben_lbl.add_theme_color_override("font_color", Color(0.70, 0.92, 0.72))
	ben_lbl.text = BENEFICIOS_SOLAR[_mision_idx] if _mision_idx < BENEFICIOS_SOLAR.size() else ""
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
	ps.bg_color     = Color(0.06, 0.06, 0.10, 0.98)
	ps.border_color = Color(0.98, 0.78, 0.08)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(18)
	ps.shadow_color = Color(0.55, 0.40, 0.05, 0.50)
	ps.shadow_size  = 28
	_panel_root.add_theme_stylebox_override("panel", ps)
	add_child(_panel_root)

	# Franja solar dorada
	var acento := ColorRect.new()
	acento.set_anchors_preset(Control.PRESET_TOP_WIDE)
	acento.custom_minimum_size = Vector2(0, 4)
	acento.offset_bottom       = 4.0
	acento.color               = Color(0.98, 0.80, 0.08, 0.85)
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
	_titulo_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.70))
	header.add_child(_titulo_lbl)

	var badge := Label.new()
	badge.text = "☀️ NIVEL 2 — Energía"
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(0.98, 0.80, 0.20))
	header.add_child(badge)

	# Contexto y capacidad
	_ctx_lbl = Label.new()
	_ctx_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_ctx_lbl.add_theme_font_size_override("font_size", 12)
	_ctx_lbl.add_theme_color_override("font_color", Color(0.75, 0.80, 0.75))
	vbox.add_child(_ctx_lbl)

	_cap_lbl = Label.new()
	_cap_lbl.add_theme_font_size_override("font_size", 11)
	_cap_lbl.add_theme_color_override("font_color", Color(0.55, 0.88, 0.60))
	vbox.add_child(_cap_lbl)

	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.98, 0.78, 0.08, 0.30)
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

	# Panel visual del techo (izquierda) — más grande y centrado
	var vis_cont := Control.new()
	vis_cont.custom_minimum_size   = Vector2(460, 320)
	vis_cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vis_cont.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	vis_cont.clip_contents         = true
	row.add_child(vis_cont)

	_vis_node = TechoVisual.new()
	_vis_node.position = Vector2(230, 160)
	_vis_node.scale    = Vector2(1.6, 1.6)
	vis_cont.add_child(_vis_node)

	# Grid de paneles — reescalado para coincidir con TechoVisual x1.6
	_grid_cont = Control.new()
	_grid_cont.custom_minimum_size = Vector2(244, 142)
	_grid_cont.position            = Vector2(230 - 76 * 1.6, 160 - 44 * 1.6)
	_grid_cont.visible             = false
	vis_cont.add_child(_grid_cont)
	# Columna derecha: pasos
	var col_der := VBoxContainer.new()
	col_der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_der.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	col_der.add_theme_constant_override("separation", 14)
	row.add_child(col_der)

	# Paso actual
	_paso_lbl = Label.new()
	_paso_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_paso_lbl.add_theme_font_size_override("font_size", 16)
	col_der.add_child(_paso_lbl)

	# Descripción
	_desc_lbl = Label.new()
	_desc_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_desc_lbl.add_theme_font_size_override("font_size", 13)
	_desc_lbl.add_theme_color_override("font_color", Color(0.80, 0.85, 0.80))
	col_der.add_child(_desc_lbl)

	# Indicador de pasos
	var steps_row := HBoxContainer.new()
	steps_row.alignment = BoxContainer.ALIGNMENT_CENTER
	steps_row.add_theme_constant_override("separation", 8)
	for i in PASOS_SOLAR.size():
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(10, 10)
		dot.name = "dot_%d" % i
		var ds := StyleBoxFlat.new()
		ds.set_corner_radius_all(5)
		ds.bg_color     = Color(0.25, 0.20, 0.06)
		ds.border_color = Color(0.50, 0.40, 0.12)
		ds.set_border_width_all(2)
		dot.add_theme_stylebox_override("panel", ds)
		steps_row.add_child(dot)
	col_der.add_child(steps_row)

	# Botón continuar
	_btn_cont = Button.new()
	_btn_cont.custom_minimum_size = Vector2(220, 46)
	_btn_cont.add_theme_font_size_override("font_size", 14)
	var bns := StyleBoxFlat.new()
	bns.bg_color     = Color(0.10, 0.28, 0.06)
	bns.border_color = Color(0.22, 0.85, 0.22)
	bns.set_border_width_all(2)
	bns.set_corner_radius_all(12)
	_btn_cont.add_theme_stylebox_override("normal", bns)
	_btn_cont.pressed.connect(_on_continuar)
	col_der.add_child(_btn_cont)


func iniciar(mision_idx: int, zona_node: Area2D) -> void:
	_mision_idx  = clampi(mision_idx, 0, MISIONES_SOLAR.size() - 1)
	_zona_ref    = zona_node
	_paso_actual = 0
	_todos_puestos = false
	var m : Dictionary = MISIONES_SOLAR[_mision_idx]
	_mision_id   = m["id"]
	SupabaseManager.registrar_evento(2, _mision_id, "mision_iniciada")
	_paneles_col = []
	var num_paneles := int(m["cols"]) * int(m["rows"])
	for _i in num_paneles:
		_paneles_col.append(false)
	var vis := _vis_node as TechoVisual
	vis.cols    = int(m["cols"])
	vis.rows    = int(m["rows"])
	vis.paneles = _paneles_col
	vis.paso    = 0
	_titulo_lbl.text = "%s  %s" % [m["icono"], m["nombre"]]
	_ctx_lbl.text    = m["contexto"]
	_cap_lbl.text    = "📐  " + m["capacidad"]
	# Crear grid de botones clickeables dinámicamente
	_crear_grid_dinamico(int(m["cols"]), int(m["rows"]))
	_mostrar_paso()
	show()
	var hb = get_tree().get_first_node_in_group("hint_bubble")
	if hb:
		hb.push("primer_solar",
			"☀️ Sigue los pasos para instalar paneles fotovoltaicos en el campus.")


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
