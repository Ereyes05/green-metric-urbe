# ============================================================
# minijuego_residuos.gd — URBE Rangers: Eco-Quest
# Minijuego M3: Clasificar residuos en el contenedor correcto.
# 10 residuos, 60 segundos, 5 XP por acierto.
# Emite: minijuego_completado(xp_total)
# ============================================================
extends CanvasLayer

signal minijuego_completado(xp_total: int)

# ── Constantes ───────────────────────────────────────────────
const XP_POR_ACIERTO  : int   = 5
const TOTAL_RESIDUOS  : int   = 10
const TIEMPO_LIMITE   : float = 60.0

# ── Tipos de contenedor ───────────────────────────────────────
enum Tipo { RECICLABLE, ORGANICO, NO_RECICLABLE }

# ── Catálogo de residuos ──────────────────────────────────────
const RESIDUOS : Array = [
	{"emoji": "🍌", "nombre": "Cáscara de banana",   "tipo": Tipo.ORGANICO,       "dato": "Los residuos orgánicos se compostan y generan abono natural."},
	{"emoji": "🍾", "nombre": "Botella de vidrio",    "tipo": Tipo.RECICLABLE,     "dato": "El vidrio puede reciclarse infinitas veces sin perder calidad."},
	{"emoji": "📄", "nombre": "Hoja de papel",        "tipo": Tipo.RECICLABLE,     "dato": "Reciclar 1 tonelada de papel salva 17 árboles."},
	{"emoji": "🍕", "nombre": "Resto de comida",      "tipo": Tipo.ORGANICO,       "dato": "Los restos orgánicos representan el 50% de los residuos del campus."},
	{"emoji": "🔋", "nombre": "Pila usada",           "tipo": Tipo.NO_RECICLABLE,  "dato": "Las pilas contienen metales pesados tóxicos. Van a puntos especiales."},
	{"emoji": "🥤", "nombre": "Vaso plástico",        "tipo": Tipo.RECICLABLE,     "dato": "El plástico tarda 500 años en degradarse en la naturaleza."},
	{"emoji": "🌿", "nombre": "Hojas secas",          "tipo": Tipo.ORGANICO,       "dato": "Las hojas secas son excelente material para compostaje."},
	{"emoji": "💊", "nombre": "Medicamento vencido",  "tipo": Tipo.NO_RECICLABLE,  "dato": "Los medicamentos contaminan el agua. Devuélvelos a la farmacia."},
	{"emoji": "📦", "nombre": "Caja de cartón",       "tipo": Tipo.RECICLABLE,     "dato": "El cartón reciclado reduce la tala de bosques."},
	{"emoji": "🖊️", "nombre": "Bolígrafo sin tinta", "tipo": Tipo.NO_RECICLABLE,  "dato": "Los bolígrafos tienen partes mixtas difíciles de separar para reciclar."},
	{"emoji": "🍊", "nombre": "Cáscara de naranja",   "tipo": Tipo.ORGANICO,       "dato": "Las cáscaras cítricas enriquecen el compost con nutrientes."},
	{"emoji": "🥫", "nombre": "Lata de aluminio",     "tipo": Tipo.RECICLABLE,     "dato": "Reciclar aluminio usa 95% menos energía que producirlo nuevo."},
]

# ── Nodos internos ────────────────────────────────────────────
var _titulo_lbl      : Label     = null
var _tiempo_lbl      : Label     = null
var _progreso_lbl    : Label     = null
var _residuo_emoji   : Label     = null
var _residuo_nombre  : Label     = null
var _dato_lbl        : Label     = null
var _feedback_lbl    : Label     = null
var _btn_reciclable  : Button    = null
var _btn_organico    : Button    = null
var _btn_no_recic    : Button    = null
var _tiempo_bar_fill : ColorRect = null
var _res_overlay     : Panel     = null
var _res_titulo_lbl  : Label     = null
var _res_score_lbl   : Label     = null
var _res_xp_lbl      : Label     = null

# ── Estado ────────────────────────────────────────────────────
var _residuos_mezclados : Array  = []
var _indice             : int    = 0
var _xp_total           : int    = 0
var _aciertos           : int    = 0
var _tiempo_restante    : float  = TIEMPO_LIMITE
var _activo             : bool   = false
var _bloqueado          : bool   = false


func _ready() -> void:
	layer = 14
	add_to_group("ui_minijuego")
	_crear_ui()
	hide()


# ── API pública ───────────────────────────────────────────────
func iniciar() -> void:
	# mision_residuos_minijuego, no mision_residuos: son cosas distintas
	# (ver el comentario de _on_minijuego_completado en SceneMapaMundo.gd).
	SupabaseManager.registrar_evento(3, "mision_residuos_minijuego",
		"mision_iniciada")
	# Mezclar residuos y tomar los primeros TOTAL_RESIDUOS
	_residuos_mezclados = RESIDUOS.duplicate()
	_residuos_mezclados.shuffle()
	if _residuos_mezclados.size() > TOTAL_RESIDUOS:
		_residuos_mezclados = _residuos_mezclados.slice(0, TOTAL_RESIDUOS)

	_indice          = 0
	_xp_total        = 0
	_aciertos        = 0
	_tiempo_restante = TIEMPO_LIMITE
	_activo          = true
	_bloqueado       = false

	_mostrar_residuo()
	show()


# ── Lógica del juego ──────────────────────────────────────────
func _process(delta: float) -> void:
	if not visible or not _activo:
		return

	_tiempo_restante -= delta
	_actualizar_barra_tiempo()

	if _tiempo_restante <= 0:
		_tiempo_restante = 0
		_terminar()


func _mostrar_residuo() -> void:
	if _indice >= _residuos_mezclados.size():
		_terminar()
		return

	var r : Dictionary = _residuos_mezclados[_indice]
	_residuo_emoji.text  = r["emoji"]
	_residuo_nombre.text = r["nombre"]
	_dato_lbl.text       = ""
	_feedback_lbl.text   = ""
	_progreso_lbl.text   = "Residuo %d / %d" % [_indice + 1, _residuos_mezclados.size()]
	_bloqueado           = false

	_btn_normal(_btn_reciclable)
	_btn_normal(_btn_organico)
	_btn_normal(_btn_no_recic)
	_btn_reciclable.disabled = false
	_btn_organico.disabled   = false
	_btn_no_recic.disabled   = false


func _clasificar(tipo_elegido: int) -> void:
	if _bloqueado:
		return
	_bloqueado = true

	var r        : Dictionary = _residuos_mezclados[_indice]
	var correcto : bool       = (tipo_elegido == r["tipo"])

	_btn_reciclable.disabled = true
	_btn_organico.disabled   = true
	_btn_no_recic.disabled   = true

	var btn_elegido : Button = _boton_por_tipo(tipo_elegido)
	var btn_correct : Button = _boton_por_tipo(r["tipo"])

	if correcto:
		_btn_verde(btn_elegido)
		_xp_total += XP_POR_ACIERTO
		_aciertos += 1
		_feedback_lbl.add_theme_color_override("font_color", Color(0.25, 0.88, 0.25))
		_feedback_lbl.text = "✓ ¡Correcto!  +%d XP" % XP_POR_ACIERTO
		_sfx("xp")
	else:
		_btn_rojo(btn_elegido)
		_btn_verde(btn_correct)
		_feedback_lbl.add_theme_color_override("font_color", Color(0.90, 0.28, 0.28))
		_feedback_lbl.text = "✗ Incorrecto — era: %s" % _boton_nombre(r["tipo"])
		_sfx("error")

	_dato_lbl.text = "💡 " + r["dato"]

	await get_tree().create_timer(2.0).timeout
	if not is_instance_valid(self):
		return

	_indice += 1
	_mostrar_residuo()


func _terminar() -> void:
	_activo = false
	# Es la Comprensión de Residuos (catalogo_misiones: tipo quiz, 10 ítems).
	PuntajeManager.registrar_quiz("mision_residuos_minijuego", _aciertos)
	SupabaseManager.registrar_evento(3, "mision_residuos_minijuego",
		"mision_completada",
		{
			"aciertos" : _aciertos,
			"total"    : _residuos_mezclados.size(),
			"xp_total" : _xp_total,
			"por_tiempo": _tiempo_restante <= 0,
		})
	_mostrar_resultado()


func _mostrar_resultado() -> void:
	var razon   : String = "⏱ Tiempo agotado" if _tiempo_restante <= 0 else "✓ ¡Ronda completa!"
	var estrellas : String = "⭐⭐⭐" if _aciertos == _residuos_mezclados.size() \
		else ("⭐⭐" if _aciertos >= _residuos_mezclados.size() * 0.7 else "⭐")
	_res_titulo_lbl.text = razon + "  " + estrellas
	_res_score_lbl.text  = "%d / %d clasificados correctamente" % [_aciertos, _residuos_mezclados.size()]
	_res_xp_lbl.text     = "+%d XP ganados" % _xp_total
	_res_overlay.modulate.a = 0.0
	_res_overlay.visible    = true
	var tw := create_tween()
	tw.tween_property(_res_overlay, "modulate:a", 1.0, 0.3)
	tw.tween_interval(3.0)
	tw.tween_callback(func():
		hide()
		_res_overlay.visible = false
		minijuego_completado.emit(_xp_total))
	_sfx("mision")


func _sfx(nombre: String) -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am: am.tocar(nombre)


func _boton_nombre(tipo: int) -> String:
	match tipo:
		Tipo.RECICLABLE:    return "Reciclable"
		Tipo.ORGANICO:      return "Orgánico"
		Tipo.NO_RECICLABLE: return "No reciclable"
	return ""


func _actualizar_barra_tiempo() -> void:
	if not _tiempo_bar_fill:
		return
	var pct : float = clampf(_tiempo_restante / TIEMPO_LIMITE, 0.0, 1.0)
	_tiempo_bar_fill.size.x = 560.0 * pct
	if pct > 0.5:
		_tiempo_bar_fill.color = Color(0.18, 0.78, 0.28)
	elif pct > 0.25:
		_tiempo_bar_fill.color = Color(0.88, 0.65, 0.08)
	else:
		_tiempo_bar_fill.color = Color(0.88, 0.18, 0.18)

	var seg : int = int(_tiempo_restante)
	_tiempo_lbl.text = "⏱ %d s" % seg


func _boton_por_tipo(tipo: int) -> Button:
	match tipo:
		Tipo.RECICLABLE:    return _btn_reciclable
		Tipo.ORGANICO:      return _btn_organico
		Tipo.NO_RECICLABLE: return _btn_no_recic
	return _btn_reciclable


# ── Estilos de botón ──────────────────────────────────────────
func _btn_normal(btn: Button) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color     = Color(0.12, 0.17, 0.27)
	s.border_color = Color(0.26, 0.36, 0.56)
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal",   s)
	btn.add_theme_stylebox_override("hover",    s)
	btn.add_theme_stylebox_override("disabled", s)

func _btn_verde(btn: Button) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color     = Color(0.09, 0.42, 0.09)
	s.border_color = Color(0.22, 0.88, 0.22)
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal",   s)
	btn.add_theme_stylebox_override("disabled", s)

func _btn_rojo(btn: Button) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color     = Color(0.42, 0.09, 0.09)
	s.border_color = Color(0.88, 0.22, 0.22)
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal",   s)
	btn.add_theme_stylebox_override("disabled", s)


# ── Construcción de UI ────────────────────────────────────────
func _crear_ui() -> void:
	# Overlay
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.75)
	add_child(overlay)

	# Panel central
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(660, 480)
	panel.offset_left   = -330.0
	panel.offset_top    = -240.0
	panel.offset_right  =  330.0
	panel.offset_bottom =  240.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.05, 0.08, 0.12, 0.98)
	ps.border_color = Color(0.20, 0.68, 0.20)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mg.add_theme_constant_override("margin_left",   28)
	mg.add_theme_constant_override("margin_right",  28)
	mg.add_theme_constant_override("margin_top",    18)
	mg.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	mg.add_child(vbox)

	# ── Cabecera ──────────────────────────────────────────────
	var header := HBoxContainer.new()
	vbox.add_child(header)

	_titulo_lbl = Label.new()
	_titulo_lbl.text = "♻  CLASIFICACIÓN DE RESIDUOS — M3"
	_titulo_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_titulo_lbl.add_theme_font_size_override("font_size", 15)
	_titulo_lbl.add_theme_color_override("font_color", Color(0.30, 0.90, 0.30))
	header.add_child(_titulo_lbl)

	_tiempo_lbl = Label.new()
	_tiempo_lbl.text = "⏱ 60 s"
	_tiempo_lbl.add_theme_font_size_override("font_size", 14)
	_tiempo_lbl.add_theme_color_override("font_color", Color(0.90, 0.80, 0.20))
	header.add_child(_tiempo_lbl)

	# Barra de tiempo
	var tiempo_bg := ColorRect.new()
	tiempo_bg.custom_minimum_size = Vector2(560, 8)
	tiempo_bg.color = Color(0.10, 0.14, 0.20)
	vbox.add_child(tiempo_bg)

	_tiempo_bar_fill = ColorRect.new()
	_tiempo_bar_fill.position = Vector2(0, 0)
	_tiempo_bar_fill.size     = Vector2(560, 8)
	_tiempo_bar_fill.color    = Color(0.18, 0.78, 0.28)
	tiempo_bg.add_child(_tiempo_bar_fill)

	# Progreso
	_progreso_lbl = Label.new()
	_progreso_lbl.add_theme_font_size_override("font_size", 12)
	_progreso_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	_progreso_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_progreso_lbl)

	# Separador
	vbox.add_child(HSeparator.new())

	# ── Residuo actual ────────────────────────────────────────
	var residuo_box := VBoxContainer.new()
	residuo_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	residuo_box.alignment = BoxContainer.ALIGNMENT_CENTER
	residuo_box.add_theme_constant_override("separation", 6)
	vbox.add_child(residuo_box)

	_residuo_emoji = Label.new()
	_residuo_emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_residuo_emoji.add_theme_font_size_override("font_size", 56)
	residuo_box.add_child(_residuo_emoji)

	_residuo_nombre = Label.new()
	_residuo_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_residuo_nombre.add_theme_font_size_override("font_size", 18)
	_residuo_nombre.add_theme_color_override("font_color", Color.WHITE)
	residuo_box.add_child(_residuo_nombre)

	_dato_lbl = Label.new()
	_dato_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dato_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
	_dato_lbl.add_theme_font_size_override("font_size", 12)
	_dato_lbl.add_theme_color_override("font_color", Color(0.65, 0.85, 1.00))
	_dato_lbl.custom_minimum_size = Vector2(0, 36)
	residuo_box.add_child(_dato_lbl)

	# ── Botones de contenedor ─────────────────────────────────
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	_btn_reciclable = _crear_boton("🟦\nReciclable",   Color(0.08, 0.28, 0.58), Color(0.20, 0.55, 0.90))
	_btn_reciclable.pressed.connect(func(): _clasificar(Tipo.RECICLABLE))
	btn_row.add_child(_btn_reciclable)

	_btn_organico = _crear_boton("🟫\nOrgánico",       Color(0.28, 0.18, 0.08), Color(0.65, 0.42, 0.12))
	_btn_organico.pressed.connect(func(): _clasificar(Tipo.ORGANICO))
	btn_row.add_child(_btn_organico)

	_btn_no_recic = _crear_boton("⬛\nNo reciclable",  Color(0.18, 0.08, 0.08), Color(0.55, 0.22, 0.22))
	_btn_no_recic.pressed.connect(func(): _clasificar(Tipo.NO_RECICLABLE))
	btn_row.add_child(_btn_no_recic)

	# ── Feedback ──────────────────────────────────────────────
	_feedback_lbl = Label.new()
	_feedback_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_lbl.add_theme_font_size_override("font_size", 15)
	_feedback_lbl.custom_minimum_size = Vector2(0, 24)
	vbox.add_child(_feedback_lbl)

	# ── Overlay de resultados (aparece al terminar) ────────────
	_res_overlay = Panel.new()
	_res_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var rs := StyleBoxFlat.new()
	rs.bg_color = Color(0.04, 0.10, 0.06, 0.96)
	rs.set_corner_radius_all(14)
	_res_overlay.add_theme_stylebox_override("panel", rs)
	_res_overlay.visible = false
	panel.add_child(_res_overlay)

	var res_vbox := VBoxContainer.new()
	res_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	res_vbox.add_theme_constant_override("separation", 18)
	res_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_res_overlay.add_child(res_vbox)

	_res_titulo_lbl = Label.new()
	_res_titulo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_res_titulo_lbl.add_theme_font_size_override("font_size", 26)
	_res_titulo_lbl.add_theme_color_override("font_color", Color(0.30, 1.00, 0.42))
	res_vbox.add_child(_res_titulo_lbl)

	_res_score_lbl = Label.new()
	_res_score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_res_score_lbl.add_theme_font_size_override("font_size", 18)
	_res_score_lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	res_vbox.add_child(_res_score_lbl)

	_res_xp_lbl = Label.new()
	_res_xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_res_xp_lbl.add_theme_font_size_override("font_size", 22)
	_res_xp_lbl.add_theme_color_override("font_color", Color(1.00, 0.85, 0.18))
	res_vbox.add_child(_res_xp_lbl)


func _crear_boton(texto: String, bg: Color, borde: Color) -> Button:
	var btn := Button.new()
	btn.text = texto
	btn.custom_minimum_size = Vector2(160, 80)
	btn.add_theme_font_size_override("font_size", 14)
	var s := StyleBoxFlat.new()
	s.bg_color     = bg
	s.border_color = borde
	s.set_border_width_all(2)
	s.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", s)
	var sh := s.duplicate()
	sh.bg_color = bg.lightened(0.15)
	btn.add_theme_stylebox_override("hover", sh)
	var sd := s.duplicate()
	sd.bg_color = bg.darkened(0.2)
	btn.add_theme_stylebox_override("disabled", sd)
	return btn
