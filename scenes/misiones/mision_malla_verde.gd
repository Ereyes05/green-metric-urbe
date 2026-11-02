# ============================================================
# mision_malla_verde.gd — NIVEL 6: Educación e Investigación
# Misión "Malla Verde" (ED1 — % de cursos de sostenibilidad).
# El jugador asigna módulos de sostenibilidad, con costo en
# créditos académicos, a 4 mallas de carrera con presupuesto
# y capacidad limitados: no se puede meter todo, hay que elegir.
# ============================================================
extends CanvasLayer

signal malla_verde_completada(mision_id: String, xp: int, ec: int)

const AJUSTE := preload("res://scenes/ui/ui_ajuste.gd")

const PRESUPUESTO_TOTAL : int = 14
const CAPACIDAD_CARRERA : int = 2
const MIN_MODULOS_CONFIRMAR : int = 3

const MODULOS : Array = [
	{"id": "m_ecologia",       "nombre": "Ecología y Desarrollo Sostenible",     "costo": 3, "icono": "🌱"},
	{"id": "m_circular",       "nombre": "Economía Circular",                    "costo": 3, "icono": "♻️"},
	{"id": "m_bioclim",        "nombre": "Arquitectura Bioclimática",            "costo": 5, "icono": "🏛️"},
	{"id": "m_residuos_ind",   "nombre": "Gestión de Residuos Industriales",     "costo": 4, "icono": "🏭"},
	{"id": "m_rse",            "nombre": "Responsabilidad Social Empresarial",   "costo": 3, "icono": "🤝"},
	{"id": "m_clima_politicas","nombre": "Cambio Climático y Políticas Públicas","costo": 4, "icono": "🌍"},
	{"id": "m_renovables",     "nombre": "Energías Renovables",                  "costo": 5, "icono": "⚡"},
	{"id": "m_urbanismo",      "nombre": "Diseño Urbano Sostenible",             "costo": 4, "icono": "🏙️"},
]

const CARRERAS : Array = [
	{"id": "ingenieria",        "nombre": "Ingeniería",         "icono": "⚙️"},
	{"id": "administracion",    "nombre": "Administración",     "icono": "📊"},
	{"id": "arquitectura",      "nombre": "Arquitectura",       "icono": "📐"},
	{"id": "ciencias_sociales", "nombre": "Ciencias Sociales",  "icono": "🌐"},
]

# ── Estado ───────────────────────────────────────────────────
var _mision_id      : String     = "malla_verde"
var _punto_ref      : Area2D     = null
var _asignaciones   : Dictionary = {}   # modulo_id -> carrera_id
var _seleccionado   : String     = ""   # modulo_id en staging, "" si ninguno

# ── Nodos UI ─────────────────────────────────────────────────
var _panel_root     : Panel           = null
var _presupuesto_lbl: Label           = null
var _modulos_cont    : GridContainer  = null
var _carreras_cont   : HBoxContainer  = null
var _btn_confirmar   : Button         = null
var _modulo_btns     : Dictionary     = {}   # modulo_id -> Button
var _carrera_conts   : Dictionary     = {}   # carrera_id -> VBoxContainer (chips)


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _ready() -> void:
	layer = 20
	_crear_ui()
	hide()


func iniciar(punto_node: Area2D) -> void:
	_punto_ref     = punto_node
	_asignaciones  = {}
	_seleccionado  = ""
	_refrescar_ui()
	show()
	AJUSTE.encajar(_panel_root)
	SupabaseManager.registrar_evento(6, _mision_id, "mision_iniciada")
	var hb = get_tree().get_first_node_in_group("hint_bubble")
	if hb:
		hb.push("primer_malla_verde",
			"📚 Elige qué materias de sostenibilidad entran en la malla. El presupuesto no alcanza para todo — prioriza.")


# ── Presupuesto / capacidad ────────────────────────────────────
func _gastado() -> int:
	var total := 0
	for mid in _asignaciones.keys():
		total += int(_costo_de(mid))
	return total


func _costo_de(modulo_id: String) -> int:
	for m in MODULOS:
		if m["id"] == modulo_id: return int(m["costo"])
	return 0


func _cupo_carrera(carrera_id: String) -> int:
	var n := 0
	for c in _asignaciones.values():
		if c == carrera_id: n += 1
	return n


# ── Interacción ─────────────────────────────────────────────
func _on_click_modulo(modulo_id: String) -> void:
	if _asignaciones.has(modulo_id):
		# Ya asignado: click lo devuelve al pool (desasignar)
		_asignaciones.erase(modulo_id)
		if _seleccionado == modulo_id: _seleccionado = ""
		_refrescar_ui()
		return
	# Toggle selección
	_seleccionado = "" if _seleccionado == modulo_id else modulo_id
	_refrescar_ui()


func _on_click_carrera(carrera_id: String) -> void:
	if _seleccionado == "": return
	var costo := _costo_de(_seleccionado)
	if _gastado() + costo > PRESUPUESTO_TOTAL: return
	if _cupo_carrera(carrera_id) >= CAPACIDAD_CARRERA: return
	_asignaciones[_seleccionado] = carrera_id
	_seleccionado = ""
	_refrescar_ui()


func _completar_mision() -> void:
	var nm = _nivel_mgr()
	if nm:
		nm.completar_mision(6, _mision_id)
		var resumen : Array = []
		for mid in _asignaciones.keys():
			var m := _modulo_por_id(mid)
			var c := _carrera_por_id(_asignaciones[mid])
			resumen.append({"modulo": m.get("nombre",""), "carrera": c.get("nombre","")})
		nm.guardar_detalle(_mision_id, {"asignaciones": resumen, "gastado": _gastado(), "presupuesto": PRESUPUESTO_TOTAL})
		SupabaseManager.registrar_evento(6, _mision_id, "mision_completada",
			{"asignaciones": resumen, "gastado": _gastado(), "presupuesto": PRESUPUESTO_TOTAL})
	if is_instance_valid(_punto_ref) and _punto_ref.has_method("_marcar_completado"):
		_punto_ref._marcar_completado()
	var xp : int = int(nm.XP_POR_MISION.get(6, 70)) if nm else 70
	var ec : int = int(nm.EC_POR_MISION.get(6, 20)) if nm else 20
	malla_verde_completada.emit(_mision_id, xp, ec)
	_mostrar_confirmacion(xp, ec)


func _modulo_por_id(mid: String) -> Dictionary:
	for m in MODULOS:
		if m["id"] == mid: return m
	return {}


func _carrera_por_id(cid: String) -> Dictionary:
	for c in CARRERAS:
		if c["id"] == cid: return c
	return {}


func _on_salir() -> void:
	var tw := create_tween()
	tw.tween_property(_panel_root, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func(): hide(); _panel_root.modulate.a = 1.0)


# ── Refrescar UI ────────────────────────────────────────────
func _refrescar_ui() -> void:
	var gastado := _gastado()
	_presupuesto_lbl.text = "🎓 Presupuesto de créditos académicos:  %d / %d" % [gastado, PRESUPUESTO_TOTAL]
	_presupuesto_lbl.add_theme_color_override("font_color",
		Color(0.95, 0.55, 0.20) if gastado >= PRESUPUESTO_TOTAL else Color(0.80, 0.70, 0.95))

	for m in MODULOS:
		var mid : String = m["id"]
		var btn : Button = _modulo_btns[mid]
		var asignada : bool = _asignaciones.has(mid)
		var puede_pagar : bool = (gastado + int(m["costo"])) <= PRESUPUESTO_TOTAL
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(10)
		sb.set_border_width_all(2)
		sb.content_margin_left = 8; sb.content_margin_right = 8
		sb.content_margin_top = 6; sb.content_margin_bottom = 6
		if asignada:
			sb.bg_color     = Color(0.10, 0.28, 0.14)
			sb.border_color = Color(0.25, 0.85, 0.35)
			btn.modulate.a  = 1.0
		elif mid == _seleccionado:
			sb.bg_color     = Color(0.20, 0.10, 0.32)
			sb.border_color = Color(0.75, 0.35, 0.95)
			btn.modulate.a  = 1.0
		elif not puede_pagar:
			sb.bg_color     = Color(0.10, 0.08, 0.10)
			sb.border_color = Color(0.30, 0.22, 0.28)
			btn.modulate.a  = 0.45
		else:
			sb.bg_color     = Color(0.08, 0.08, 0.12)
			sb.border_color = Color(0.35, 0.30, 0.45)
			btn.modulate.a  = 1.0
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.disabled = asignada and false  # asignados siguen clickeables para desasignar
		var estado := "  ✅ en malla" if asignada else ("  👆 elegido" if mid == _seleccionado else "")
		btn.text = "%s  %s\n💳 %d créditos%s" % [m["icono"], m["nombre"], m["costo"], estado]

	for c in CARRERAS:
		var cid : String = c["id"]
		var cont : VBoxContainer = _carrera_conts[cid]
		for child in cont.get_children():
			child.queue_free()
		var cupo := _cupo_carrera(cid)
		for mid in _asignaciones.keys():
			if _asignaciones[mid] != cid: continue
			var m := _modulo_por_id(mid)
			var chip := Label.new()
			chip.text = "%s %s" % [m.get("icono",""), m.get("nombre","")]
			chip.add_theme_font_size_override("font_size", 10)
			chip.add_theme_color_override("font_color", Color(0.75, 0.95, 0.80))
			chip.autowrap_mode = TextServer.AUTOWRAP_WORD
			cont.add_child(chip)
		for _i in range(CAPACIDAD_CARRERA - cupo):
			var vacio := Label.new()
			vacio.text = "· · · vacío · · ·"
			vacio.add_theme_font_size_override("font_size", 10)
			vacio.add_theme_color_override("font_color", Color(0.40, 0.38, 0.45))
			cont.add_child(vacio)

	var total_asignados : int = _asignaciones.size()
	_btn_confirmar.disabled = total_asignados < MIN_MODULOS_CONFIRMAR
	_btn_confirmar.text = ("  Confirmar malla (%d/%d mín.)  ▶  " % [total_asignados, MIN_MODULOS_CONFIRMAR]) \
		if total_asignados < MIN_MODULOS_CONFIRMAR else "  Confirmar malla curricular  🎓  "


# ── Panel de confirmación final ────────────────────────────────
func _mostrar_confirmacion(xp: int, ec: int) -> void:
	var cel := Panel.new()
	cel.set_anchors_preset(Control.PRESET_CENTER)
	cel.custom_minimum_size = Vector2(480, 260)
	cel.offset_left  = -240.0; cel.offset_top    = -130.0
	cel.offset_right =  240.0; cel.offset_bottom =  130.0
	var cps := StyleBoxFlat.new()
	cps.bg_color     = Color(0.06, 0.03, 0.09, 0.98)
	cps.border_color = Color(0.62, 0.24, 0.90)
	cps.set_border_width_all(3)
	cps.set_corner_radius_all(16)
	cps.shadow_color = Color(0.30, 0.05, 0.50, 0.55)
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
	tit.add_theme_color_override("font_color", Color(0.80, 0.55, 1.0))
	tit.text = "🎓 ¡Malla curricular aprobada!"
	vb.add_child(tit)
	var det := Label.new()
	det.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	det.autowrap_mode = TextServer.AUTOWRAP_WORD
	det.add_theme_font_size_override("font_size", 12)
	det.add_theme_color_override("font_color", Color(0.78, 0.75, 0.85))
	det.text = "%d módulos de sostenibilidad se incorporan al pénsum (%d/%d créditos usados)." \
		% [_asignaciones.size(), _gastado(), PRESUPUESTO_TOTAL]
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
	_panel_root.custom_minimum_size = Vector2(960, 620)
	_panel_root.set_anchors_preset(Control.PRESET_CENTER)
	_panel_root.offset_left   = -480.0
	_panel_root.offset_top    = -310.0
	_panel_root.offset_right  =  480.0
	_panel_root.offset_bottom =  310.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.05, 0.04, 0.08, 0.98)
	ps.border_color = Color(0.62, 0.24, 0.90)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(18)
	ps.shadow_color = Color(0.30, 0.05, 0.50, 0.50)
	ps.shadow_size  = 28
	_panel_root.add_theme_stylebox_override("panel", ps)
	add_child(_panel_root)

	var acento := ColorRect.new()
	acento.set_anchors_preset(Control.PRESET_TOP_WIDE)
	acento.custom_minimum_size = Vector2(0, 4)
	acento.offset_bottom       = 4.0
	acento.color               = Color(0.68, 0.28, 0.95, 0.85)
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
	titulo_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 1.0))
	titulo_lbl.text = "📚  Decanato — Rediseño de Malla Curricular"
	header.add_child(titulo_lbl)

	var badge := Label.new()
	badge.text = "🎓 NIVEL 6 — Educación e Investigación"
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(0.75, 0.45, 0.95))
	header.add_child(badge)
	# El botón Salir está fijo en la esquina (fuera del VBox): se le guarda
	# su lugar para que el letrero del nivel no quede debajo de él.
	var lugar_salir := Control.new()
	lugar_salir.custom_minimum_size = Vector2(84, 0)
	header.add_child(lugar_salir)

	var ctx_lbl := Label.new()
	ctx_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	ctx_lbl.add_theme_font_size_override("font_size", 12)
	ctx_lbl.add_theme_color_override("font_color", Color(0.75, 0.72, 0.80))
	ctx_lbl.text = "UI GreenMetric (ED1) mide qué % de las asignaturas del campus incorpora sostenibilidad. El decanato solo aprueba un número limitado de créditos nuevos por período: elige qué módulos entran en la malla de cada carrera. Clic en un módulo para elegirlo, luego clic en una carrera para asignarlo. Clic sobre un módulo ya asignado lo quita."
	vbox.add_child(ctx_lbl)

	_presupuesto_lbl = Label.new()
	_presupuesto_lbl.add_theme_font_size_override("font_size", 13)
	vbox.add_child(_presupuesto_lbl)

	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.62, 0.24, 0.90, 0.30)
	sep_s.content_margin_top    = 1.0
	sep_s.content_margin_bottom = 1.0
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", sep_s)
	vbox.add_child(sep)

	# ── Grid de módulos ────────────────────────────────────────
	var mod_lbl := Label.new()
	mod_lbl.text = "Módulos propuestos"
	mod_lbl.add_theme_font_size_override("font_size", 12)
	mod_lbl.add_theme_color_override("font_color", Color(0.70, 0.68, 0.78))
	vbox.add_child(mod_lbl)

	var mod_scroll := ScrollContainer.new()
	mod_scroll.custom_minimum_size = Vector2(0, 190)
	vbox.add_child(mod_scroll)

	_modulos_cont = GridContainer.new()
	_modulos_cont.columns = 4
	_modulos_cont.add_theme_constant_override("h_separation", 10)
	_modulos_cont.add_theme_constant_override("v_separation", 10)
	_modulos_cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mod_scroll.add_child(_modulos_cont)

	for m in MODULOS:
		var mid : String = m["id"]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(210, 68)
		btn.clip_text = false
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.add_theme_font_size_override("font_size", 11)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(_on_click_modulo.bind(mid))
		_modulos_cont.add_child(btn)
		_modulo_btns[mid] = btn

	# ── Fila de carreras ───────────────────────────────────────
	var car_lbl := Label.new()
	car_lbl.text = "Mallas de carrera  (capacidad %d cada una)" % CAPACIDAD_CARRERA
	car_lbl.add_theme_font_size_override("font_size", 12)
	car_lbl.add_theme_color_override("font_color", Color(0.70, 0.68, 0.78))
	vbox.add_child(car_lbl)

	_carreras_cont = HBoxContainer.new()
	_carreras_cont.add_theme_constant_override("separation", 10)
	_carreras_cont.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_carreras_cont)

	for c in CARRERAS:
		var cid : String = c["id"]
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(0, 120)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sps := StyleBoxFlat.new()
		sps.bg_color     = Color(0.07, 0.06, 0.11, 0.90)
		sps.border_color = Color(0.45, 0.35, 0.55)
		sps.set_border_width_all(2)
		sps.set_corner_radius_all(10)
		slot.add_theme_stylebox_override("panel", sps)
		_carreras_cont.add_child(slot)

		var slot_mg := MarginContainer.new()
		slot_mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for k in ["margin_left","margin_right","margin_top","margin_bottom"]:
			slot_mg.add_theme_constant_override(k, 8)
		slot.add_child(slot_mg)

		var slot_vb := VBoxContainer.new()
		slot_vb.add_theme_constant_override("separation", 4)
		slot_mg.add_child(slot_vb)

		var slot_titulo := Label.new()
		slot_titulo.text = "%s %s" % [c["icono"], c["nombre"]]
		slot_titulo.add_theme_font_size_override("font_size", 12)
		slot_titulo.add_theme_color_override("font_color", Color(0.90, 0.85, 0.95))
		slot_vb.add_child(slot_titulo)

		var chips_cont := VBoxContainer.new()
		chips_cont.add_theme_constant_override("separation", 3)
		slot_vb.add_child(chips_cont)
		_carrera_conts[cid] = chips_cont

		var slot_btn := Button.new()
		slot_btn.text = "Asignar aquí"
		slot_btn.custom_minimum_size = Vector2(0, 24)
		slot_btn.add_theme_font_size_override("font_size", 10)
		slot_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		slot_btn.pressed.connect(_on_click_carrera.bind(cid))
		slot_vb.add_child(slot_btn)

	# ── Botón confirmar ─────────────────────────────────────────
	_btn_confirmar = Button.new()
	_btn_confirmar.custom_minimum_size = Vector2(0, 46)
	_btn_confirmar.add_theme_font_size_override("font_size", 14)
	var bns := StyleBoxFlat.new()
	bns.bg_color     = Color(0.20, 0.08, 0.28)
	bns.border_color = Color(0.68, 0.28, 0.95)
	bns.set_border_width_all(2)
	bns.set_corner_radius_all(12)
	_btn_confirmar.add_theme_stylebox_override("normal", bns)
	_btn_confirmar.pressed.connect(_completar_mision)
	vbox.add_child(_btn_confirmar)
