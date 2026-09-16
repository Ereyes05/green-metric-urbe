# ============================================================
# leaderboard.gd — URBE Rangers: Eco-Quest
# Consulta la RPC ranking_publico vía SupabaseManager. Muestra top-50 por
# XP con puesto, nombre, rango y XP.
# ============================================================
extends CanvasLayer

const RANGOS := preload("res://autoload/rangos.gd")

var _overlay     : ColorRect    = null
var _panel       : Panel        = null
var _rows_vbox   : VBoxContainer = null
var _estado_lbl  : Label        = null
var _cargando    : bool         = false


func _ready() -> void:
	layer = 15
	_crear_ui()
	hide()
	# Conexiones permanentes: con CONNECT_ONE_SHOT, un fallo dejaba la
	# conexión colgada y el siguiente intento fallaba al reconectar.
	SupabaseManager.ranking_cargado.connect(_on_ranking_cargado)
	SupabaseManager.ranking_fallido.connect(_on_ranking_fallido)


func mostrar() -> void:
	show()
	_cargar_ranking()


func _cerrar() -> void:
	hide()


func _cargar_ranking() -> void:
	if _cargando: return
	_cargando = true
	_estado_lbl.text    = "Cargando ranking..."
	_estado_lbl.visible = true
	_rows_vbox.visible  = false
	SupabaseManager.cargar_ranking()


func _on_ranking_cargado(lista: Array) -> void:
	_cargando = false
	if lista.is_empty():
		_estado_lbl.text = "Todavía no hay jugadores en el ranking."
		return
	_poblar_filas(lista)


func _on_ranking_fallido() -> void:
	_cargando = false
	_estado_lbl.text    = "No se pudo cargar el ranking. Probá con ↻ Actualizar."
	_estado_lbl.visible = true


func _poblar_filas(data: Array) -> void:
	_estado_lbl.visible = false
	_rows_vbox.visible  = true

	# free() inmediato: con queue_free las filas viejas seguían en la lista
	# durante ese frame y se sumaban a las nuevas.
	for child in _rows_vbox.get_children():
		_rows_vbox.remove_child(child)
		child.free()

	for i in data.size():
		var entrada : Dictionary = data[i] if data[i] is Dictionary else {}
		var xp      : int        = int(entrada.get("xp_total", 0))
		var nombre  : String     = str(entrada.get("nombre", "Eco-Ranger"))
		var nivel   : String     = RANGOS.nombre(int(entrada.get("niveles_completos", 0)))
		var es_yo   : bool       = bool(entrada.get("es_yo", false))

		# PanelContainer (no Panel): toma la altura de su contenido. Con Panel
		# cada fila medía 0 px dentro del VBox y todas se dibujaban encimadas.
		var bg := PanelContainer.new()
		bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var ps := StyleBoxFlat.new()
		ps.bg_color = Color(0.25, 0.55, 0.10, 0.35) if es_yo else Color(0.05, 0.08, 0.12, 0.80)
		if not es_yo:
			if i == 0:   ps.bg_color = Color(0.45, 0.38, 0.00, 0.55)
			elif i == 1: ps.bg_color = Color(0.30, 0.30, 0.30, 0.45)
			elif i == 2: ps.bg_color = Color(0.35, 0.18, 0.05, 0.45)
		ps.set_corner_radius_all(8)
		bg.add_theme_stylebox_override("panel", ps)
		var row_mg := MarginContainer.new()
		for m in ["margin_left","margin_right","margin_top","margin_bottom"]:
			row_mg.add_theme_constant_override(m, 6)
		bg.add_child(row_mg)
		var row_hb := HBoxContainer.new()
		row_hb.add_theme_constant_override("separation", 10)
		row_mg.add_child(row_hb)
		_rows_vbox.add_child(bg)

		var medalla : String = ["🥇","🥈","🥉"][i] if i < 3 else "#%d" % (i + 1)
		var rank_lbl := Label.new()
		rank_lbl.text                   = medalla
		rank_lbl.custom_minimum_size     = Vector2(36, 0)
		rank_lbl.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
		rank_lbl.add_theme_font_size_override("font_size", 15)
		row_hb.add_child(rank_lbl)

		var nom_lbl := Label.new()
		var titulo_v = entrada.get("titulo")
		var titulo : String = "" if titulo_v == null else str(titulo_v)
		nom_lbl.text                   = nombre + (" (Tú)" if es_yo else "") \
			+ ("  🏆 " + titulo if titulo != "" else "")
		nom_lbl.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
		nom_lbl.add_theme_font_size_override("font_size", 13)
		nom_lbl.add_theme_color_override("font_color",
			Color(0.40, 1.0, 0.45) if es_yo else Color(0.88, 0.88, 0.88))
		row_hb.add_child(nom_lbl)

		var niv_lbl := Label.new()
		niv_lbl.text = nivel
		niv_lbl.custom_minimum_size = Vector2(100, 0)
		niv_lbl.add_theme_font_size_override("font_size", 11)
		niv_lbl.add_theme_color_override("font_color", Color(0.92, 0.80, 0.22))
		row_hb.add_child(niv_lbl)

		var xp_lbl := Label.new()
		xp_lbl.text = "%d XP" % xp
		xp_lbl.custom_minimum_size = Vector2(80, 0)
		xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		xp_lbl.add_theme_font_size_override("font_size", 13)
		xp_lbl.add_theme_color_override("font_color", Color(0.40, 0.88, 1.0))
		row_hb.add_child(xp_lbl)


# ── UI ─────────────────────────────────────────────────────────
func _crear_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.75)
	_overlay.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed: _cerrar())
	add_child(_overlay)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(640, 520)
	_panel.offset_left   = -320.0
	_panel.offset_top    = -260.0
	_panel.offset_right  =  320.0
	_panel.offset_bottom =  260.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.06, 0.10, 0.99)
	ps.border_color = Color(0.25, 0.72, 0.25)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(16)
	ps.shadow_color = Color(0.15, 0.65, 0.20, 0.45)
	ps.shadow_size  = 24
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(m, 24)
	_panel.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	mg.add_child(vbox)

	# Encabezado
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(header)

	var titulo := Label.new()
	titulo.text = "🏆  Ranking Global — URBE Rangers"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.88, 0.22))
	header.add_child(titulo)

	var btn_cerrar := Button.new()
	btn_cerrar.text = "✕"
	btn_cerrar.custom_minimum_size = Vector2(32, 32)
	btn_cerrar.add_theme_font_size_override("font_size", 16)
	var s_c := StyleBoxFlat.new()
	s_c.bg_color = Color(0.18, 0.08, 0.08)
	s_c.border_color = Color(0.60, 0.20, 0.20); s_c.set_border_width_all(1); s_c.set_corner_radius_all(6)
	btn_cerrar.add_theme_stylebox_override("normal", s_c)
	btn_cerrar.pressed.connect(_cerrar)
	header.add_child(btn_cerrar)

	# Encabezado de columnas
	var col_header := HBoxContainer.new()
	col_header.add_theme_constant_override("separation", 10)
	vbox.add_child(col_header)
	for par in [["#", 36, HORIZONTAL_ALIGNMENT_CENTER], ["Jugador", 0, HORIZONTAL_ALIGNMENT_LEFT],
				["Rango", 100, HORIZONTAL_ALIGNMENT_LEFT], ["XP Total", 80, HORIZONTAL_ALIGNMENT_RIGHT]]:
		var lbl := Label.new()
		lbl.text = par[0]
		if par[1] > 0: lbl.custom_minimum_size = Vector2(par[1], 0)
		else: lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.horizontal_alignment = par[2]
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.45, 0.65, 0.45))
		col_header.add_child(lbl)

	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.22, 0.50, 0.22, 0.30)
	sep_s.content_margin_top = 1.0; sep_s.content_margin_bottom = 1.0
	var sep := HSeparator.new(); sep.add_theme_stylebox_override("separator", sep_s)
	vbox.add_child(sep)

	# Estado / cargando
	_estado_lbl = Label.new()
	_estado_lbl.text = "Cargando..."
	_estado_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_estado_lbl.add_theme_font_size_override("font_size", 14)
	_estado_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	vbox.add_child(_estado_lbl)

	# Filas de ranking
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_rows_vbox = VBoxContainer.new()
	_rows_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(_rows_vbox)

	# Botón actualizar
	var btn_refresh := Button.new()
	btn_refresh.text = "↻  Actualizar"
	btn_refresh.custom_minimum_size = Vector2(0, 40)
	btn_refresh.add_theme_font_size_override("font_size", 13)
	var s_r := StyleBoxFlat.new()
	s_r.bg_color     = Color(0.06, 0.16, 0.06)
	s_r.border_color = Color(0.22, 0.72, 0.22)
	s_r.set_border_width_all(2); s_r.set_corner_radius_all(10)
	btn_refresh.add_theme_stylebox_override("normal", s_r)
	btn_refresh.pressed.connect(_cargar_ranking)
	vbox.add_child(btn_refresh)
