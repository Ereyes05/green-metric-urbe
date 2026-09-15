# ============================================================
# quiz_npc.gd — URBE Rangers: Eco-Quest
# Quiz interactivo: temporizador, rachas, bonus velocidad,
# hover en respuestas, flash de feedback, dots de progreso.
# ============================================================
extends CanvasLayer

signal quiz_completado(xp_total: int)

const XP_POR_PREGUNTA    : int   = 10
const XP_BONUS_VELOCIDAD : int   = 5
const XP_BONUS_RACHA     : int   = 5
const TIEMPO_PREGUNTA    : float = 15.0

# — Nodos ————————————————————————————————————————————————
var _titulo_lbl   : Label          = null
var _pregunta_lbl : Label          = null
var _botones      : Array          = []
var _feedback_lbl : Label          = null
var _xp_lbl       : Label          = null
var _racha_lbl    : Label          = null
var _timer_fill   : ColorRect      = null
var _timer_lbl    : Label          = null
var _dots_row     : HBoxContainer  = null
var _dots         : Array          = []
var _flash        : ColorRect      = null
var _panel        : Panel          = null
var _btn_salir    : Button         = null
var _dlg_overlay  : ColorRect      = null

# — Estado ────────────────────────────────────────────────
var _preguntas         : Array = []
var _indice            : int   = 0
var _xp_total          : int   = 0
var _racha             : int   = 0
var _aciertos          : int   = 0
# 1 = primer intento (cuenta para la Comprensión), 2 = repetición.
var _intento           : int   = 1
var _bloqueado         : bool  = false
var _tiempo_restante   : float = TIEMPO_PREGUNTA
var _tiempo_inicio_preg: float = 0.0
var _cronometro_activo : bool  = false
var _xp_offset         : int   = 0   # offset vertical para labels flotantes

# Contexto para la telemetría (eventos_aprendizaje). Lo pasa quien llama a
# iniciar(): el quiz por sí solo no sabe a qué nivel/misión pertenece.
# Con nivel 0 los eventos igual se registran, pero sin poder atribuirse a
# un indicador GreenMetric — por eso conviene siempre pasarlo.
var _nivel     : int    = 0
var _mision_id : String = ""


func _ready() -> void:
	layer = 15
	add_to_group("ui_quiz")
	_crear_ui()
	hide()


func _process(delta: float) -> void:
	if not visible or _bloqueado or not _cronometro_activo:
		return
	_tiempo_restante -= delta
	_actualizar_timer()
	if _tiempo_restante <= 0.0:
		_cronometro_activo = false
		_tiempo_se_acabo()


# ════════════════════════════════════════════════════════
# CONSTRUCCIÓN DE UI
# ════════════════════════════════════════════════════════
func _crear_ui() -> void:
	# Overlay oscuro
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.68)
	add_child(overlay)

	# Flash de feedback
	_flash = ColorRect.new()
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.color   = Color(0, 0, 0, 0)
	_flash.visible = false
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	# Panel principal
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(700, 470)
	_panel.offset_left   = -350.0
	_panel.offset_top    = -235.0
	_panel.offset_right  =  350.0
	_panel.offset_bottom =  235.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.07, 0.11, 0.98)
	ps.border_color = Color(0.22, 0.72, 0.22)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(14)
	ps.shadow_color = Color(0.10, 0.55, 0.18, 0.55)
	ps.shadow_size  = 18
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	# Barra de tiempo (ENCIMA del panel, borde superior)
	var timer_bg := ColorRect.new()
	timer_bg.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	timer_bg.position = Vector2(-350, -235)
	timer_bg.size     = Vector2(700, 8)
	timer_bg.color    = Color(0.08, 0.12, 0.18)
	_panel.add_child(timer_bg)

	_timer_fill = ColorRect.new()
	_timer_fill.position = Vector2(0, 0)
	_timer_fill.size     = Vector2(700, 8)
	_timer_fill.color    = Color(0.18, 0.80, 0.28)
	timer_bg.add_child(_timer_fill)

	# Contenido del panel
	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mg.add_theme_constant_override("margin_left",   28)
	mg.add_theme_constant_override("margin_right",  28)
	mg.add_theme_constant_override("margin_top",    18)
	mg.add_theme_constant_override("margin_bottom", 18)
	_panel.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	mg.add_child(vbox)

	# ── Cabecera: título + racha + timer ─────────────────
	var header := HBoxContainer.new()
	vbox.add_child(header)

	_titulo_lbl = Label.new()
	_titulo_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_titulo_lbl.add_theme_font_size_override("font_size", 16)
	_titulo_lbl.add_theme_color_override("font_color", Color(0.30, 0.90, 0.30))
	header.add_child(_titulo_lbl)

	_racha_lbl = Label.new()
	_racha_lbl.add_theme_font_size_override("font_size", 14)
	_racha_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.10))
	_racha_lbl.visible = false
	header.add_child(_racha_lbl)

	_timer_lbl = Label.new()
	_timer_lbl.custom_minimum_size = Vector2(34, 0)
	_timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_timer_lbl.add_theme_font_size_override("font_size", 16)
	_timer_lbl.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	header.add_child(_timer_lbl)

	# Botón Salir
	_btn_salir = Button.new()
	_btn_salir.text = "✕ Salir"
	_btn_salir.custom_minimum_size = Vector2(80, 28)
	_btn_salir.add_theme_font_size_override("font_size", 12)
	var s_sal := StyleBoxFlat.new()
	s_sal.bg_color     = Color(0.18, 0.06, 0.06)
	s_sal.border_color = Color(0.65, 0.18, 0.18)
	s_sal.set_border_width_all(1)
	s_sal.set_corner_radius_all(6)
	_btn_salir.add_theme_stylebox_override("normal", s_sal)
	var s_sal_h := s_sal.duplicate()
	(s_sal_h as StyleBoxFlat).bg_color = Color(0.30, 0.08, 0.08)
	_btn_salir.add_theme_stylebox_override("hover", s_sal_h)
	_btn_salir.add_theme_color_override("font_color", Color(0.90, 0.36, 0.36))
	_btn_salir.pressed.connect(_on_btn_salir_pressed)
	header.add_child(_btn_salir)

	# ── Puntos de progreso ───────────────────────────────
	_dots_row = HBoxContainer.new()
	_dots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots_row.add_theme_constant_override("separation", 8)
	vbox.add_child(_dots_row)

	# ── Separador ────────────────────────────────────────
	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.22, 0.72, 0.22, 0.35)
	sep_s.content_margin_top = 1.0; sep_s.content_margin_bottom = 1.0
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", sep_s)
	vbox.add_child(sep)

	# ── Pregunta ─────────────────────────────────────────
	_pregunta_lbl = Label.new()
	_pregunta_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_pregunta_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pregunta_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	_pregunta_lbl.add_theme_font_size_override("font_size", 17)
	_pregunta_lbl.add_theme_color_override("font_color", Color.WHITE)
	_pregunta_lbl.custom_minimum_size = Vector2(0, 64)
	vbox.add_child(_pregunta_lbl)

	# ── Opciones ─────────────────────────────────────────
	var ops_box := VBoxContainer.new()
	ops_box.add_theme_constant_override("separation", 9)
	vbox.add_child(ops_box)

	var letras := ["A", "B", "C"]
	for i in range(3):
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size   = Vector2(0, 48)
		btn.add_theme_font_size_override("font_size", 14)
		btn.text = ""
		var idx := i
		btn.pressed.connect(func(): _responder(idx))
		btn.mouse_entered.connect(func():
			if not btn.disabled and not _bloqueado: _btn_hover(btn, letras[idx]))
		btn.mouse_exited.connect(func():
			if not btn.disabled and not _bloqueado: _btn_normal(btn, letras[idx]))
		ops_box.add_child(btn)
		_botones.append(btn)
		_btn_normal(btn, letras[idx])

	# ── Feedback ─────────────────────────────────────────
	_feedback_lbl = Label.new()
	_feedback_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_lbl.add_theme_font_size_override("font_size", 15)
	_feedback_lbl.custom_minimum_size = Vector2(0, 28)
	vbox.add_child(_feedback_lbl)

	# ── Fila inferior: XP ────────────────────────────────
	var pie := HBoxContainer.new()
	vbox.add_child(pie)

	_xp_lbl = Label.new()
	_xp_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_xp_lbl.add_theme_font_size_override("font_size", 13)
	_xp_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.18))
	pie.add_child(_xp_lbl)

	var hint := Label.new()
	hint.text = "Clic para responder"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.40, 0.40, 0.40))
	pie.add_child(hint)

	# ── Diálogo de confirmación de salida (oculto por defecto) ─
	_crear_dialogo_salida()


func _crear_dialogo_salida() -> void:
	_dlg_overlay = ColorRect.new()
	_dlg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dlg_overlay.color = Color(0.0, 0.0, 0.0, 0.70)
	_dlg_overlay.visible = false
	_dlg_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dlg_overlay)

	var dlg := Panel.new()
	dlg.set_anchors_preset(Control.PRESET_CENTER)
	dlg.custom_minimum_size = Vector2(380, 180)
	dlg.offset_left   = -190.0
	dlg.offset_top    = -90.0
	dlg.offset_right  =  190.0
	dlg.offset_bottom =  90.0
	var ds := StyleBoxFlat.new()
	ds.bg_color     = Color(0.08, 0.06, 0.06, 0.98)
	ds.border_color = Color(0.75, 0.22, 0.22)
	ds.set_border_width_all(2)
	ds.set_corner_radius_all(14)
	ds.shadow_color = Color(0.6, 0.1, 0.1, 0.40)
	ds.shadow_size  = 18
	dlg.add_theme_stylebox_override("panel", ds)
	_dlg_overlay.add_child(dlg)

	var vmg := MarginContainer.new()
	vmg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left","margin_right","margin_top","margin_bottom"]:
		vmg.add_theme_constant_override(m, 24)
	dlg.add_child(vmg)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vmg.add_child(vb)

	var ico := Label.new()
	ico.text = "⚠️"
	ico.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ico.add_theme_font_size_override("font_size", 28)
	vb.add_child(ico)

	var msg := Label.new()
	msg.text = "¿Salir del quiz?\nNo se guardará el XP de esta sesión."
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg.add_theme_font_size_override("font_size", 14)
	msg.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88))
	vb.add_child(msg)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 18)
	vb.add_child(btn_row)

	var btn_si := Button.new()
	btn_si.text = "Sí, salir"
	btn_si.custom_minimum_size = Vector2(120, 38)
	btn_si.add_theme_font_size_override("font_size", 13)
	var ss := StyleBoxFlat.new()
	ss.bg_color     = Color(0.28, 0.06, 0.06)
	ss.border_color = Color(0.80, 0.22, 0.22)
	ss.set_border_width_all(2)
	ss.set_corner_radius_all(10)
	btn_si.add_theme_stylebox_override("normal", ss)
	btn_si.add_theme_color_override("font_color", Color(1.0, 0.55, 0.55))
	btn_si.pressed.connect(_on_confirmar_salida)
	btn_row.add_child(btn_si)

	var btn_no := Button.new()
	btn_no.text = "No, continuar"
	btn_no.custom_minimum_size = Vector2(140, 38)
	btn_no.add_theme_font_size_override("font_size", 13)
	var sn := StyleBoxFlat.new()
	sn.bg_color     = Color(0.06, 0.22, 0.08)
	sn.border_color = Color(0.22, 0.78, 0.25)
	sn.set_border_width_all(2)
	sn.set_corner_radius_all(10)
	btn_no.add_theme_stylebox_override("normal", sn)
	btn_no.add_theme_color_override("font_color", Color(0.40, 1.0, 0.48))
	btn_no.pressed.connect(_on_cancelar_salida)
	btn_row.add_child(btn_no)


func _on_btn_salir_pressed() -> void:
	_cronometro_activo = false
	_dlg_overlay.visible = true


func _on_confirmar_salida() -> void:
	_dlg_overlay.visible = false
	_cronometro_activo   = false
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func(): hide())


func _on_cancelar_salida() -> void:
	_dlg_overlay.visible = false
	if not _bloqueado:
		_cronometro_activo = true


# ════════════════════════════════════════════════════════
# API PÚBLICA
# ════════════════════════════════════════════════════════
func iniciar(preguntas: Array, nombre_npc: String,
			 nivel: int = 0, mision_id: String = "") -> void:
	_preguntas = preguntas
	_indice    = 0
	_xp_total  = 0
	_racha     = 0
	_aciertos  = 0
	_intento   = 2 if PuntajeManager.quiz_hecho(mision_id) else 1
	_xp_offset = 0
	_nivel     = nivel
	_mision_id = mision_id if mision_id != "" else "quiz_%s" % nombre_npc.to_lower()
	SupabaseManager.registrar_evento(_nivel, _mision_id, "mision_iniciada",
		{"npc": nombre_npc, "preguntas": preguntas.size()})
	_titulo_lbl.text = "QUIZ  ─  " + nombre_npc
	_xp_lbl.text     = "XP ganada: 0"
	_racha_lbl.visible = false
	_dlg_overlay.visible = false
	_crear_dots()
	_mostrar_pregunta()
	_panel.modulate.a = 0.0
	show()
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, 0.20)
	# Pista contextual (solo la primera vez)
	var hb = get_tree().get_first_node_in_group("hint_bubble")
	if hb:
		hb.push("primer_quiz",
			"⏱ Tienes 15 seg por pregunta. ¡Responde rápido para ganar XP extra!")


# ════════════════════════════════════════════════════════
# LÓGICA INTERNA
# ════════════════════════════════════════════════════════
func _crear_dots() -> void:
	for d in _dots_row.get_children(): d.queue_free()
	_dots.clear()
	for _i in _preguntas.size():
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(14, 14)
		var s := StyleBoxFlat.new()
		s.bg_color     = Color(0.22, 0.32, 0.45)
		s.border_color = Color(0.35, 0.50, 0.70)
		s.set_border_width_all(2)
		s.set_corner_radius_all(7)
		dot.add_theme_stylebox_override("panel", s)
		_dots_row.add_child(dot)
		_dots.append(dot)


func _mostrar_pregunta() -> void:
	var q : Dictionary = _preguntas[_indice]
	_pregunta_lbl.text = q["pregunta"]
	_feedback_lbl.text = ""
	_bloqueado         = false
	_tiempo_restante   = TIEMPO_PREGUNTA
	_tiempo_inicio_preg = Time.get_ticks_msec() / 1000.0
	_cronometro_activo = true

	var letras := ["A", "B", "C"]
	var ops : Array = q["opciones"]
	for i in range(_botones.size()):
		var btn : Button = _botones[i]
		# El texto debe estar prefijado ANTES de llamar _btn_normal
		# para que su substr(3) recorte el prefijo y no el contenido.
		btn.text     = letras[i] + "  " + (ops[i] if i < ops.size() else "")
		btn.disabled = false
		_btn_normal(btn, letras[i])

	# Animación de entrada de la pregunta
	_pregunta_lbl.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_pregunta_lbl, "modulate:a", 1.0, 0.18)

	_actualizar_timer()
	_actualizar_dots(-1)


func _responder(idx: int) -> void:
	if _bloqueado: return
	_bloqueado         = true
	_cronometro_activo = false

	var q        : Dictionary = _preguntas[_indice]
	var correcta : int        = q["correcta"]
	var acerto   : bool       = (idx == correcta)
	var letras                := ["A", "B", "C"]

	# Desactivar botones
	for btn in _botones: btn.disabled = true

	# Calcular XP
	var xp_ganado : int = 0
	if acerto:
		_aciertos += 1
		xp_ganado += XP_POR_PREGUNTA
		var tiempo_usado : float = Time.get_ticks_msec() / 1000.0 - _tiempo_inicio_preg
		if tiempo_usado < 6.0:
			xp_ganado += XP_BONUS_VELOCIDAD
		_racha += 1
		if _racha >= 3:
			xp_ganado += XP_BONUS_RACHA
	else:
		_racha = 0

	# Colorear respuestas
	for i in range(_botones.size()):
		if i == correcta:
			_btn_color(_botones[i], letras[i], Color(0.07, 0.38, 0.07), Color(0.22, 0.90, 0.22))
		elif i == idx and not acerto:
			_btn_color(_botones[i], letras[i], Color(0.38, 0.07, 0.07), Color(0.90, 0.22, 0.22))

	_actualizar_dots(idx if acerto else -2)

	# Telemetría: es el evento más valioso del juego para la tesis — registra
	# el proceso (qué eligió, cuánto tardó, si venía en racha), no solo el
	# resultado final.
	SupabaseManager.registrar_evento(_nivel, _mision_id, "respuesta_quiz",
		{
			"pregunta"      : str(q.get("pregunta", "")),
			"opcion_elegida": str(q["opciones"][idx]) if idx < q["opciones"].size() else "",
			"opcion_correcta": str(q["opciones"][correcta]),
			"segundos"      : snappedf(Time.get_ticks_msec() / 1000.0 - _tiempo_inicio_preg, 0.01),
			"racha"         : _racha,
			"xp_ganado"     : xp_ganado,
			"intento_quiz"  : _intento,
		},
		acerto, _indice + 1)

	# Feedback visual
	if acerto:
		_xp_total += xp_ganado
		_xp_lbl.text = "XP ganada: %d" % _xp_total
		var msg := "✓  Correcto!  +%d XP" % xp_ganado
		if _racha >= 3:
			msg = "🔥 RACHA x%d!  +%d XP" % [_racha, xp_ganado]
			_racha_lbl.text    = "🔥 RACHA x%d" % _racha
			_racha_lbl.visible = true
		elif _racha >= 2:
			msg = "⚡ Racha x%d!  +%d XP" % [_racha, xp_ganado]
			_racha_lbl.text    = "⚡ x%d" % _racha
			_racha_lbl.visible = true
		else:
			_racha_lbl.visible = false
		_feedback_txt(_feedback_lbl, msg, Color(0.25, 0.95, 0.30))
		_disparar_flash(Color(0.18, 0.82, 0.28, 0.14))
		_flotar_xp_panel("+%d XP" % xp_ganado, Color(0.28, 1.0, 0.42))
	else:
		_racha_lbl.visible = false
		var correcta_txt : String = str(q["opciones"][correcta])
		_feedback_txt(_feedback_lbl,
			"✗  Incorrecto — Resp. correcta: %s" % correcta_txt,
			Color(0.95, 0.28, 0.28))
		_disparar_flash(Color(0.78, 0.12, 0.12, 0.14))

	await get_tree().create_timer(1.6).timeout
	if not is_instance_valid(self): return

	_indice += 1
	if _indice >= _preguntas.size():
		_finalizar()
	else:
		_mostrar_pregunta()


func _tiempo_se_acabo() -> void:
	_bloqueado = true
	var letras := ["A", "B", "C"]
	var q : Dictionary = _preguntas[_indice]
	var correcta : int = q["correcta"]
	for btn in _botones: btn.disabled = true
	_btn_color(_botones[correcta], letras[correcta],
			   Color(0.07, 0.38, 0.07), Color(0.22, 0.90, 0.22))
	_racha = 0
	_racha_lbl.visible = false
	_feedback_txt(_feedback_lbl, "⏱ ¡Tiempo agotado!", Color(0.95, 0.65, 0.10))
	_disparar_flash(Color(0.80, 0.52, 0.04, 0.16))
	_actualizar_dots(-2)

	# Se registra aparte de respuesta_quiz: "no contestó a tiempo" no es lo
	# mismo que "contestó mal", y para el análisis pedagógico conviene poder
	# distinguirlos.
	SupabaseManager.registrar_evento(_nivel, _mision_id, "tiempo_agotado",
		{"pregunta": str(q.get("pregunta", "")), "intento_quiz": _intento}, false, _indice + 1)
	await get_tree().create_timer(1.8).timeout
	if not is_instance_valid(self): return
	_indice += 1
	if _indice >= _preguntas.size(): _finalizar()
	else: _mostrar_pregunta()


func _finalizar() -> void:
	# El servidor guarda solo el primer intento (registrar_quiz); repetir el
	# quiz se juega igual pero no cambia la Comprensión.
	PuntajeManager.registrar_quiz(_mision_id, _aciertos)
	SupabaseManager.registrar_evento(_nivel, _mision_id, "mision_completada",
		{"xp_total": _xp_total, "preguntas": _preguntas.size()})
	var hb = get_tree().get_first_node_in_group("hint_bubble")
	if hb:
		hb.push("primer_quiz_done",
			"🏆 ¡Quiz completado! Busca más NPCs en el campus para seguir explorando.")
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func():
		hide()
		quiz_completado.emit(_xp_total))


# ════════════════════════════════════════════════════════
# VISUALES
# ════════════════════════════════════════════════════════
func _actualizar_timer() -> void:
	var pct : float = clampf(_tiempo_restante / TIEMPO_PREGUNTA, 0.0, 1.0)
	_timer_fill.size.x = 700.0 * pct
	_timer_lbl.text = "%d" % ceili(_tiempo_restante)
	if pct > 0.55:
		_timer_fill.color = Color(0.18, 0.80, 0.28)
		_timer_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70))
	elif pct > 0.25:
		_timer_fill.color = Color(0.90, 0.65, 0.08)
		_timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.10))
	else:
		_timer_fill.color = Color(0.88, 0.16, 0.16)
		_timer_lbl.add_theme_color_override("font_color", Color(1.0, 0.36, 0.36))


func _actualizar_dots(idx_respondido: int) -> void:
	for i in _dots.size():
		var dot  : Panel = _dots[i]
		var bg   : Color
		var brd  : Color
		if i < _indice:
			bg  = Color(0.22, 0.72, 0.22)
			brd = Color(0.30, 0.92, 0.30)
		elif i == _indice and idx_respondido == -2:
			bg  = Color(0.80, 0.20, 0.20)
			brd = Color(1.00, 0.35, 0.35)
		elif i == _indice:
			bg  = Color(0.82, 0.82, 0.82)
			brd = Color(1.00, 1.00, 1.00)
		else:
			bg  = Color(0.22, 0.32, 0.45)
			brd = Color(0.35, 0.50, 0.70)
		var s := StyleBoxFlat.new()
		s.bg_color     = bg
		s.border_color = brd
		s.set_border_width_all(2)
		s.set_corner_radius_all(7)
		dot.add_theme_stylebox_override("panel", s)
		# "Pop" visual en el dot activo
		if i == _indice:
			var tw := dot.create_tween().set_ease(Tween.EASE_OUT)
			tw.tween_property(dot, "scale", Vector2(1.0, 1.0), 0.12).from(Vector2(1.4, 1.4))


func _disparar_flash(color: Color) -> void:
	_flash.color   = color
	_flash.visible = true
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, 0.30)
	tw.tween_callback(func():
		_flash.visible = false
		_flash.color.a = color.a)


func _flotar_xp_panel(texto: String, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = texto
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", color)
	lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lbl.offset_left  = -160.0
	lbl.offset_top   = 60.0 + float(_xp_offset) * 26.0
	lbl.offset_right = -10.0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(lbl)
	_xp_offset = (_xp_offset + 1) % 4
	var tw := create_tween()
	tw.tween_property(lbl, "offset_top", lbl.offset_top - 40.0, 0.9).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.9).set_ease(Tween.EASE_IN)
	tw.tween_callback(lbl.queue_free)


func _feedback_txt(lbl: Label, texto: String, color: Color) -> void:
	lbl.text = texto
	lbl.add_theme_color_override("font_color", color)
	lbl.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(lbl, "modulate:a", 1.0, 0.15)


# ── Estilos de botón ─────────────────────────────────────
func _btn_normal(btn: Button, letra: String) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color     = Color(0.10, 0.15, 0.24)
	s.border_color = Color(0.24, 0.34, 0.54)
	s.set_border_width_all(1)
	s.set_corner_radius_all(8)
	s.content_margin_left = 14; s.content_margin_right = 14
	s.content_margin_top  = 8;  s.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal",   s)
	btn.add_theme_stylebox_override("disabled", s)
	btn.text = letra + "  " + btn.text.substr(3) if btn.text.length() > 3 else btn.text
	btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.90))


func _btn_hover(btn: Button, _letra: String) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color     = Color(0.14, 0.22, 0.38)
	s.border_color = Color(0.35, 0.55, 0.90)
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	s.shadow_color = Color(0.25, 0.45, 0.85, 0.30)
	s.shadow_size  = 5
	s.content_margin_left = 14; s.content_margin_right = 14
	s.content_margin_top  = 8;  s.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", s)
	btn.add_theme_stylebox_override("hover",  s)
	btn.add_theme_color_override("font_color", Color.WHITE)
	var tw := create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(1.02, 1.02), 0.08)


func _btn_color(btn: Button, _letra: String, bg: Color, borde: Color) -> void:
	if not is_instance_valid(btn): return
	var tw := create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.08)
	var s := StyleBoxFlat.new()
	s.bg_color     = bg
	s.border_color = borde
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	s.shadow_color = Color(borde.r, borde.g, borde.b, 0.40)
	s.shadow_size  = 7
	s.content_margin_left = 14; s.content_margin_right = 14
	s.content_margin_top  = 8;  s.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal",   s)
	btn.add_theme_stylebox_override("disabled", s)
	btn.add_theme_color_override("font_color", Color.WHITE)
