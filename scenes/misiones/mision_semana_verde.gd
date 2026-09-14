# ============================================================
# mision_semana_verde.gd — NIVEL 6: Educación e Investigación
# Misión "Semana Verde URBE" (ED4 — eventos de sostenibilidad).
# Elige exactamente 3 de 7 actividades, pagadas con EcoCredits
# REALES del jugador (EconomiaManager) — el primer gasto temático
# de la economía del juego, no un sink de recuperación.
# ============================================================
extends CanvasLayer

signal semana_verde_completada(mision_id: String, xp: int, ec: int)

const MISION_ID  : String = "semana_verde"
const CUPO_ELEGIR : int   = 3

const ACTIVIDADES : Array = [
	{"id": "feria_reciclaje", "nombre": "Feria de Reciclaje Creativo",              "costo": 45, "alcance": 150, "icono": "♻️"},
	{"id": "charla_clima",    "nombre": "Charla: Cambio Climático y Políticas",     "costo": 25, "alcance": 80,  "icono": "🎤"},
	{"id": "maraton_siembra", "nombre": "Maratón de Siembra Comunitaria",           "costo": 60, "alcance": 200, "icono": "🌱"},
	{"id": "cine_foro",       "nombre": "Cine Foro Ambiental",                      "costo": 18, "alcance": 60,  "icono": "🎬"},
	{"id": "taller_movilidad","nombre": "Taller de Movilidad Sostenible",           "costo": 32, "alcance": 90,  "icono": "🚲"},
	{"id": "concurso_verde",  "nombre": "Concurso de Innovación Verde",             "costo": 70, "alcance": 120, "icono": "🏆"},
	{"id": "caminata_eco",    "nombre": "Caminata Ecológica por el Campus",         "costo": 14, "alcance": 70,  "icono": "🚶"},
]

# ── Estado ───────────────────────────────────────────────────
var _punto_ref   : Area2D = null
var _elegidas    : Array  = []   # Array[String] ids


func _economia():
	return get_node_or_null("/root/EconomiaManager")


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


# ── Nodos UI ─────────────────────────────────────────────────
var _panel_root    : Panel   = null
var _saldo_lbl     : Label   = null
var _actividades_cont : VBoxContainer = null
var _act_btns      : Dictionary = {}
var _btn_confirmar : Button  = null
var _aviso_lbl     : Label   = null


func _ready() -> void:
	layer = 20
	_crear_ui()
	hide()


func iniciar(punto_node: Area2D) -> void:
	_punto_ref = punto_node
	_elegidas  = []
	_refrescar_ui()
	show()
	SupabaseManager.registrar_evento(6, MISION_ID, "mision_iniciada")
	var hb = get_tree().get_first_node_in_group("hint_bubble")
	if hb:
		hb.push("primer_semana_verde",
			"🎪 El auditorio solo alcanza para 3 actividades. Elige bien: cada una tiene un alcance distinto y cuesta EcoCredits reales.")


func _costo_de(aid: String) -> int:
	for a in ACTIVIDADES:
		if a["id"] == aid: return int(a["costo"])
	return 0


func _costo_total() -> int:
	var t := 0
	for aid in _elegidas: t += _costo_de(aid)
	return t


func _alcance_total() -> int:
	var t := 0
	for aid in _elegidas:
		for a in ACTIVIDADES:
			if a["id"] == aid: t += int(a["alcance"])
	return t


func _saldo_actual() -> int:
	var eco = _economia()
	return int(eco.ecocredits) if eco else 0


func _on_click_actividad(aid: String) -> void:
	if aid in _elegidas:
		_elegidas.erase(aid)
		SupabaseManager.registrar_evento(6, MISION_ID, "opcion_quitada", {"actividad": aid})
		_refrescar_ui()
		return
	if _elegidas.size() >= CUPO_ELEGIR:
		_aviso_lbl.text = "Ya elegiste %d actividades — quita una para elegir otra." % CUPO_ELEGIR
		return
	if _costo_total() + _costo_de(aid) > _saldo_actual():
		_aviso_lbl.text = "No te alcanzan los EcoCredits para agregar esta actividad."
		return
	_elegidas.append(aid)
	# Exploración libre — probar combinaciones antes de confirmar es en sí
	# mismo una señal de decisión autónoma, no solo el resultado final.
	SupabaseManager.registrar_evento(6, MISION_ID, "opcion_elegida", {"actividad": aid})
	_refrescar_ui()


func _completar_mision() -> void:
	var eco = _economia()
	var costo := _costo_total()
	if eco and not eco.gastar_creditos(costo, "semana_verde", "evento"):
		_aviso_lbl.text = "No se pudo cobrar el evento — verifica tus EcoCredits."
		return
	var nm = _nivel_mgr()
	var elegidas_nombres : Array = []
	for aid in _elegidas:
		for a in ACTIVIDADES:
			if a["id"] == aid: elegidas_nombres.append(a["nombre"])
	if nm:
		nm.completar_mision(6, MISION_ID)
		nm.guardar_detalle(MISION_ID, {
			"actividades": elegidas_nombres,
			"costo_total": costo,
			"alcance_total": _alcance_total(),
		})
		SupabaseManager.registrar_evento(6, MISION_ID, "mision_completada",
			{"actividades": elegidas_nombres, "costo_total": costo, "alcance_total": _alcance_total()})
	if is_instance_valid(_punto_ref) and _punto_ref.has_method("_marcar_completado"):
		_punto_ref._marcar_completado()
	var xp : int = int(nm.XP_POR_MISION.get(6, 70)) if nm else 70
	var ec_ganado : int = int(nm.EC_POR_MISION.get(6, 20)) if nm else 20
	semana_verde_completada.emit(MISION_ID, xp, ec_ganado)
	_mostrar_confirmacion(xp, ec_ganado, costo)


func _on_salir() -> void:
	var tw := create_tween()
	tw.tween_property(_panel_root, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func(): hide(); _panel_root.modulate.a = 1.0)


# ── Refrescar UI ────────────────────────────────────────────
func _refrescar_ui() -> void:
	_aviso_lbl.text = ""
	var saldo := _saldo_actual()
	var costo := _costo_total()
	_saldo_lbl.text = "💳 Tus EcoCredits: %d   ·   Costo del evento: %d   ·   Alcance estimado: %d estudiantes" \
		% [saldo, costo, _alcance_total()]
	_saldo_lbl.add_theme_color_override("font_color",
		Color(0.95, 0.55, 0.20) if costo > saldo else Color(1.0, 0.80, 0.90))

	for a in ACTIVIDADES:
		var aid : String = a["id"]
		var btn : Button = _act_btns[aid]
		var elegida : bool = aid in _elegidas
		var puede : bool = elegida or (_elegidas.size() < CUPO_ELEGIR and (costo + int(a["costo"])) <= saldo)
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(10)
		sb.set_border_width_all(2)
		sb.content_margin_left = 8; sb.content_margin_right = 8
		sb.content_margin_top = 6; sb.content_margin_bottom = 6
		if elegida:
			sb.bg_color     = Color(0.30, 0.08, 0.18)
			sb.border_color = Color(0.95, 0.30, 0.55)
			btn.modulate.a  = 1.0
		elif not puede:
			sb.bg_color     = Color(0.10, 0.08, 0.09)
			sb.border_color = Color(0.32, 0.24, 0.27)
			btn.modulate.a  = 0.45
		else:
			sb.bg_color     = Color(0.09, 0.08, 0.10)
			sb.border_color = Color(0.42, 0.32, 0.38)
			btn.modulate.a  = 1.0
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		var estado := "  ✅ en el programa" if elegida else ""
		btn.text = "%s  %s\n💳 %d EC   ·   👥 alcance %d%s" % [a["icono"], a["nombre"], a["costo"], a["alcance"], estado]

	_btn_confirmar.disabled = _elegidas.size() != CUPO_ELEGIR
	_btn_confirmar.text = ("  Confirmar evento (%d/%d elegidas)  ▶  " % [_elegidas.size(), CUPO_ELEGIR]) \
		if _elegidas.size() != CUPO_ELEGIR else "  Confirmar Semana Verde URBE  🎪  "


# ── Panel de confirmación final ────────────────────────────────
func _mostrar_confirmacion(xp: int, ec: int, costo: int) -> void:
	var cel := Panel.new()
	cel.set_anchors_preset(Control.PRESET_CENTER)
	cel.custom_minimum_size = Vector2(500, 260)
	cel.offset_left  = -250.0; cel.offset_top    = -130.0
	cel.offset_right =  250.0; cel.offset_bottom =  130.0
	var cps := StyleBoxFlat.new()
	cps.bg_color     = Color(0.10, 0.03, 0.06, 0.98)
	cps.border_color = Color(0.90, 0.28, 0.55)
	cps.set_border_width_all(3)
	cps.set_corner_radius_all(16)
	cps.shadow_color = Color(0.45, 0.08, 0.25, 0.55)
	cps.shadow_size  = 24
	cel.add_theme_stylebox_override("panel", cps)
	add_child(cel)
	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(k, 20)
	cel.add_child(mg)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 8)
	mg.add_child(vb)
	var tit := Label.new()
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.add_theme_font_size_override("font_size", 19)
	tit.add_theme_color_override("font_color", Color(1.0, 0.55, 0.75))
	tit.text = "🎪 ¡Semana Verde URBE lista!"
	vb.add_child(tit)
	var det := Label.new()
	det.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	det.autowrap_mode = TextServer.AUTOWRAP_WORD
	det.add_theme_font_size_override("font_size", 12)
	det.add_theme_color_override("font_color", Color(0.90, 0.80, 0.85))
	det.text = "Costó %d EcoCredits reales y alcanzará a ~%d estudiantes del campus." % [costo, _alcance_total()]
	vb.add_child(det)
	var xp_lbl := Label.new()
	xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_lbl.add_theme_font_size_override("font_size", 16)
	xp_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.18))
	xp_lbl.text = "+%d XP  ·  +%d EcoCredits" % [xp, ec]
	vb.add_child(xp_lbl)
	cel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(cel, "modulate:a", 1.0, 0.25)
	tw.tween_interval(3.2)
	tw.tween_property(cel, "modulate:a", 0.0, 0.30)
	tw.tween_callback(func():
		cel.queue_free()
		_on_salir())


# ── Crear UI ──────────────────────────────────────────────────
func _crear_ui() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color        = Color(0.0, 0.0, 0.0, 0.88)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	_panel_root = Panel.new()
	_panel_root.custom_minimum_size = Vector2(880, 600)
	_panel_root.set_anchors_preset(Control.PRESET_CENTER)
	_panel_root.offset_left   = -440.0
	_panel_root.offset_top    = -300.0
	_panel_root.offset_right  =  440.0
	_panel_root.offset_bottom =  300.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.08, 0.03, 0.05, 0.98)
	ps.border_color = Color(0.90, 0.28, 0.55)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(18)
	ps.shadow_color = Color(0.45, 0.08, 0.25, 0.50)
	ps.shadow_size  = 28
	_panel_root.add_theme_stylebox_override("panel", ps)
	add_child(_panel_root)

	var acento := ColorRect.new()
	acento.set_anchors_preset(Control.PRESET_TOP_WIDE)
	acento.custom_minimum_size = Vector2(0, 4)
	acento.offset_bottom       = 4.0
	acento.color               = Color(0.95, 0.30, 0.58, 0.85)
	acento.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	_panel_root.add_child(acento)

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
	vbox.add_theme_constant_override("separation", 10)
	mg.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var titulo_lbl := Label.new()
	titulo_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo_lbl.add_theme_font_size_override("font_size", 19)
	titulo_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.94))
	titulo_lbl.text = "🎪  Auditorio — Semana Verde URBE"
	header.add_child(titulo_lbl)

	var badge := Label.new()
	badge.text = "🎓 NIVEL 6 — Educación e Investigación"
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(0.95, 0.55, 0.72))
	header.add_child(badge)

	var ctx_lbl := Label.new()
	ctx_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	ctx_lbl.add_theme_font_size_override("font_size", 12)
	ctx_lbl.add_theme_color_override("font_color", Color(0.78, 0.72, 0.75))
	ctx_lbl.text = "UI GreenMetric (ED4) mide cuántos eventos de sostenibilidad organiza el campus. El auditorio solo da para %d actividades — se pagan con tus EcoCredits reales, no un presupuesto aparte. Elige las que den más alcance por lo que cuestan." % CUPO_ELEGIR
	vbox.add_child(ctx_lbl)

	_saldo_lbl = Label.new()
	_saldo_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_saldo_lbl)

	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.90, 0.28, 0.55, 0.30)
	sep_s.content_margin_top    = 1.0
	sep_s.content_margin_bottom = 1.0
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", sep_s)
	vbox.add_child(sep)

	var act_scroll := ScrollContainer.new()
	act_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(act_scroll)

	_actividades_cont = VBoxContainer.new()
	_actividades_cont.add_theme_constant_override("separation", 8)
	_actividades_cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	act_scroll.add_child(_actividades_cont)

	for a in ACTIVIDADES:
		var aid : String = a["id"]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 52)
		btn.clip_text = false
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.add_theme_font_size_override("font_size", 12)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(_on_click_actividad.bind(aid))
		_actividades_cont.add_child(btn)
		_act_btns[aid] = btn

	_aviso_lbl = Label.new()
	_aviso_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_aviso_lbl.add_theme_font_size_override("font_size", 11)
	_aviso_lbl.add_theme_color_override("font_color", Color(0.95, 0.60, 0.30))
	_aviso_lbl.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(_aviso_lbl)

	_btn_confirmar = Button.new()
	_btn_confirmar.custom_minimum_size = Vector2(0, 46)
	_btn_confirmar.add_theme_font_size_override("font_size", 14)
	var bns := StyleBoxFlat.new()
	bns.bg_color     = Color(0.28, 0.08, 0.18)
	bns.border_color = Color(0.95, 0.30, 0.55)
	bns.set_border_width_all(2)
	bns.set_corner_radius_all(12)
	_btn_confirmar.add_theme_stylebox_override("normal", bns)
	_btn_confirmar.pressed.connect(_completar_mision)
	vbox.add_child(_btn_confirmar)
