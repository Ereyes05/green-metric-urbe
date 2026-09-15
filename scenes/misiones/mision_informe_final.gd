# ============================================================
# mision_informe_final.gd — NIVEL 6: Educación e Investigación
# Misión "Publica el informe" (ED7 — informe de sostenibilidad).
# Cierre narrativo del juego: compone un documento con las
# decisiones REALES que tomó el jugador en Malla Verde, Comité
# y Semana Verde (no solo un score agregado), más el puntaje
# GreenMetric ponderado y una posición estimada en el ranking.
# ============================================================
extends CanvasLayer

signal informe_completada(mision_id: String, xp: int, ec: int)

const MISION_ID : String = "informe_final"

# El puntaje sale de PuntajeManager (servidor), el mismo número que muestran
# el HUD y la pantalla de resultados.

var _punto_ref : Area2D = null

var _panel_root  : Panel = null
var _texto_cont  : VBoxContainer = null
var _score_lbl   : Label = null
var _rank_lbl    : Label = null
var _btn_publicar: Button = null


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _ready() -> void:
	layer = 20
	_crear_ui()
	hide()


func iniciar(punto_node: Area2D) -> void:
	_punto_ref = punto_node
	_construir_informe()
	show()
	var hb = get_tree().get_first_node_in_group("hint_bubble")
	if hb:
		hb.push("primer_informe", "📄 Este informe recoge lo que realmente hiciste, no un número inventado.")


func _parrafo(texto: String, color: Color = Color(0.82, 0.80, 0.86)) -> void:
	var lbl := Label.new()
	lbl.text = texto
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", color)
	_texto_cont.add_child(lbl)


func _subtitulo(texto: String) -> void:
	var lbl := Label.new()
	lbl.text = texto
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.30))
	_texto_cont.add_child(lbl)


func _construir_informe() -> void:
	for c in _texto_cont.get_children():
		c.queue_free()
	var nm = _nivel_mgr()

	_parrafo("Informe compilado a partir de las decisiones tomadas en el campus — no es un resumen genérico, cita lo que el jugador eligió realmente.", Color(0.65, 0.62, 0.58))

	# ── Currículo (Malla Verde) ─────────────────────────────
	_subtitulo("🎓 Currículo — Malla Verde")
	var det_malla : Dictionary = nm.obtener_detalle("malla_verde") if nm else {}
	var asign : Array = det_malla.get("asignaciones", [])
	if asign.is_empty():
		_parrafo("Sin datos de currículo todavía.")
	else:
		var por_carrera : Dictionary = {}
		for a in asign:
			var c : String = a.get("carrera", "")
			if not por_carrera.has(c): por_carrera[c] = []
			(por_carrera[c] as Array).append(a.get("modulo", ""))
		var partes : Array = []
		for c in por_carrera.keys():
			partes.append("%s incorporó %s" % [c, ", ".join(por_carrera[c])])
		_parrafo("El decanato aprobó %d módulos de sostenibilidad (%d/%d créditos usados): %s." \
			% [asign.size(), int(det_malla.get("gastado", 0)), int(det_malla.get("presupuesto", 0)), "; ".join(partes) + "."])

	# ── Comunidad (Comité Ambiental) ────────────────────────
	_subtitulo("🗣 Comunidad — Comité Ambiental")
	var det_comite : Dictionary = nm.obtener_detalle("comite_ambiental") if nm else {}
	var miembros : Array = det_comite.get("miembros", [])
	if miembros.is_empty():
		_parrafo("Sin datos de comunidad todavía.")
	else:
		_parrafo("El Comité Ambiental estudiantil quedó formado por %s — cada uno se sumó al escuchar un argumento respaldado por algo que realmente ocurrió en el campus, no un discurso genérico." \
			% ", ".join(miembros))

	# ── Extensión (Semana Verde) ────────────────────────────
	_subtitulo("🎪 Extensión — Semana Verde URBE")
	var det_semana : Dictionary = nm.obtener_detalle("semana_verde") if nm else {}
	var acts : Array = det_semana.get("actividades", [])
	if acts.is_empty():
		_parrafo("Sin datos de extensión todavía.")
	else:
		_parrafo("La Semana Verde URBE incluirá %s — una inversión de %d EcoCredits reales, con un alcance estimado de %d estudiantes." \
			% [", ".join(acts), int(det_semana.get("costo_total", 0)), int(det_semana.get("alcance_total", 0))])

	_subtitulo("📊 Puntaje GreenMetric del campus")
	var score : float = PuntajeManager.total
	_score_lbl.text = "%.1f / 100" % score
	var pos := 8
	if score >= 80.0:    pos = 1
	elif score >= 65.0:  pos = 3
	elif score >= 50.0:  pos = 5
	elif score >= 35.0:  pos = 7
	_rank_lbl.text = "Posición estimada: #%d / 1.050 universidades" % pos


func _completar_mision() -> void:
	var nm = _nivel_mgr()
	if nm:
		nm.completar_mision(6, MISION_ID)
	if is_instance_valid(_punto_ref) and _punto_ref.has_method("_marcar_completado"):
		_punto_ref._marcar_completado()
	var xp : int = int(nm.XP_POR_MISION.get(6, 70)) if nm else 70
	var ec : int = int(nm.EC_POR_MISION.get(6, 20)) if nm else 20
	informe_completada.emit(MISION_ID, xp, ec)
	_mostrar_confirmacion(xp, ec)


func _on_salir() -> void:
	var tw := create_tween()
	tw.tween_property(_panel_root, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func(): hide(); _panel_root.modulate.a = 1.0)


func _mostrar_confirmacion(xp: int, ec: int) -> void:
	var cel := Panel.new()
	cel.set_anchors_preset(Control.PRESET_CENTER)
	cel.custom_minimum_size = Vector2(500, 260)
	cel.offset_left  = -250.0; cel.offset_top    = -130.0
	cel.offset_right =  250.0; cel.offset_bottom =  130.0
	var cps := StyleBoxFlat.new()
	cps.bg_color     = Color(0.09, 0.08, 0.03, 0.98)
	cps.border_color = Color(0.95, 0.80, 0.20)
	cps.set_border_width_all(3)
	cps.set_corner_radius_all(16)
	cps.shadow_color = Color(0.45, 0.38, 0.05, 0.55)
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
	tit.add_theme_color_override("font_color", Color(1.0, 0.85, 0.30))
	tit.text = "📄 ¡Informe de Sostenibilidad publicado!"
	vb.add_child(tit)
	var det := Label.new()
	det.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	det.autowrap_mode = TextServer.AUTOWRAP_WORD
	det.add_theme_font_size_override("font_size", 12)
	det.add_theme_color_override("font_color", Color(0.85, 0.82, 0.70))
	det.text = "Nivel 6 completado — Educación e Investigación."
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
	tw.tween_interval(3.5)
	tw.tween_property(cel, "modulate:a", 0.0, 0.30)
	tw.tween_callback(func():
		cel.queue_free()
		_on_salir())


# ── Crear UI ──────────────────────────────────────────────────
func _crear_ui() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color        = Color(0.0, 0.0, 0.0, 0.90)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	_panel_root = Panel.new()
	_panel_root.custom_minimum_size = Vector2(820, 640)
	_panel_root.set_anchors_preset(Control.PRESET_CENTER)
	_panel_root.offset_left   = -410.0
	_panel_root.offset_top    = -320.0
	_panel_root.offset_right  =  410.0
	_panel_root.offset_bottom =  320.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.06, 0.05, 0.03, 0.98)
	ps.border_color = Color(0.95, 0.80, 0.20)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(18)
	ps.shadow_color = Color(0.45, 0.38, 0.05, 0.50)
	ps.shadow_size  = 28
	_panel_root.add_theme_stylebox_override("panel", ps)
	add_child(_panel_root)

	var acento := ColorRect.new()
	acento.set_anchors_preset(Control.PRESET_TOP_WIDE)
	acento.custom_minimum_size = Vector2(0, 4)
	acento.offset_bottom       = 4.0
	acento.color               = Color(0.98, 0.82, 0.15, 0.85)
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
	titulo_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.80))
	titulo_lbl.text = "📄  Informe de Sostenibilidad — Campus URBE"
	header.add_child(titulo_lbl)

	var badge := Label.new()
	badge.text = "🎓 NIVEL 6 — Educación e Investigación"
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(0.90, 0.78, 0.30))
	header.add_child(badge)

	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.95, 0.80, 0.20, 0.30)
	sep_s.content_margin_top    = 1.0
	sep_s.content_margin_bottom = 1.0
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", sep_s)
	vbox.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_texto_cont = VBoxContainer.new()
	_texto_cont.add_theme_constant_override("separation", 6)
	_texto_cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_texto_cont)

	vbox.add_child(_hacer_sep())

	var fila_score := HBoxContainer.new()
	fila_score.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_score.add_theme_constant_override("separation", 18)
	vbox.add_child(fila_score)

	var score_titulo := Label.new()
	score_titulo.text = "Score GreenMetric:"
	score_titulo.add_theme_font_size_override("font_size", 14)
	score_titulo.add_theme_color_override("font_color", Color(0.75, 0.72, 0.62))
	fila_score.add_child(score_titulo)

	_score_lbl = Label.new()
	_score_lbl.add_theme_font_size_override("font_size", 20)
	_score_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.20))
	fila_score.add_child(_score_lbl)

	_rank_lbl = Label.new()
	_rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rank_lbl.add_theme_font_size_override("font_size", 12)
	_rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.18))
	vbox.add_child(_rank_lbl)

	_btn_publicar = Button.new()
	_btn_publicar.custom_minimum_size = Vector2(0, 46)
	_btn_publicar.text = "  Publicar informe  📄  "
	_btn_publicar.add_theme_font_size_override("font_size", 14)
	var bns := StyleBoxFlat.new()
	bns.bg_color     = Color(0.24, 0.20, 0.06)
	bns.border_color = Color(0.95, 0.80, 0.20)
	bns.set_border_width_all(2)
	bns.set_corner_radius_all(12)
	_btn_publicar.add_theme_stylebox_override("normal", bns)
	_btn_publicar.pressed.connect(_completar_mision)
	vbox.add_child(_btn_publicar)


func _hacer_sep() -> HSeparator:
	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.95, 0.80, 0.20, 0.22)
	sep_s.content_margin_top    = 1.0
	sep_s.content_margin_bottom = 1.0
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", sep_s)
	return sep
