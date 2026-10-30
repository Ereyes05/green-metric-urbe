# ============================================================
# dialogo_npc.gd - URBE Rangers: Eco-Quest
# Panel inferior mejorado: retrato de color, nombre del NPC,
# efecto typewriter letra a letra. Al terminar emite señal
# para lanzar el quiz del módulo.
# ============================================================
extends CanvasLayer

signal dialogo_terminado(mision_id: String)

# — Caja centrada con el sprite del NPC como retrato. Si un NPC no tiene
# sprite se usa el panel clásico con el retrato procedural.
const ANCHO_CAJA  : float = 860.0
const ALTO_CAJA   : float = 170.0
const MARGEN_INF  : float = 22.0
const LADO_RECORTE: int   = 44     # px del sprite (cabeza y torso)
const ZOOM_RETRATO: int   = 3      # entero: los píxeles quedan parejos
const VERDE_BORDE := Color(0.22, 0.72, 0.22)
const VERDE_HINT  := Color(0.38, 0.90, 0.38)

# — Nodos (creados en _crear_ui) ————————————————————————————
var _retrato_nodo : RetratoNPC = null
var _nombre_lbl   : Label      = null
# Labels activos: apuntan a los del panel clásico o a los de la caja nueva.
var _texto_lbl  : Label     = null
var _hint_lbl   : Label     = null

var _panel_clasico : Panel       = null
var _texto_clasico : Label       = null
var _hint_clasico  : Label       = null
var _velo          : ColorRect   = null
var _caja          : Panel       = null
var _pestana       : Panel       = null
var _pestana_lbl   : Label       = null
var _marco_retrato : Panel       = null
var _retrato_tex   : TextureRect = null
var _texto_nuevo   : Label       = null
var _hint_nuevo    : Label       = null
var _contador_lbl  : Label       = null
var _flecha        : FlechaContinuar = null
var _diseno_nuevo  : bool        = false
var _tween_caja    : Tween       = null

# — Estado del diálogo ————————————————————————————————————
var _dialogos  : PackedStringArray = []
var _indice    : int    = 0
var _mision_id : String = ""

# — Typewriter ————————————————————————————————————————————
var _texto_completo : String = ""
var _chars_vis      : int    = 0
var _timer          : float  = 0.0
var _escribiendo    : bool   = false
const CHARS_SEG     : float  = 38.0


# ════════════════════════════════════════════════════════════
# INNER CLASS — Retrato animado del NPC (90 × 116 px)
# Se dibuja proceduralmente con el color único de cada NPC.
# ════════════════════════════════════════════════════════════
class RetratoNPC extends Node2D:
	var col : Color = Color(0.5, 0.5, 0.5)
	var _t  : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var puls := 1.0 + 0.04 * sin(_t * 2.2)
		var bob  := sin(_t * 1.5) * 1.5

		# — Glow de fondo ─────────────────────────────────────
		var ga := 0.09 + 0.05 * sin(_t * 1.8)
		draw_circle(Vector2(45, 58), 50.0, Color(col.r, col.g, col.b, ga))

		# — Cuerpo ────────────────────────────────────────────
		var body_pts := PackedVector2Array([
			Vector2(22, 90), Vector2(68, 90),
			Vector2(72, 116), Vector2(18, 116)
		])
		draw_colored_polygon(body_pts, col.darkened(0.28))
		for i in body_pts.size():
			draw_line(body_pts[i], body_pts[(i + 1) % body_pts.size()],
					  col.lightened(0.22), 1.5)
		# Brillo en hombro
		draw_arc(Vector2(22, 92), 6.0, PI, PI * 1.6, 8, col.lightened(0.55), 2.0)

		# — Cuello ────────────────────────────────────────────
		draw_rect(Rect2(40, 82, 10, 10), col.darkened(0.10))

		# — Cabeza ────────────────────────────────────────────
		var hp := Vector2(45, bob + 62)
		draw_circle(hp, 22.0 * puls, col.lightened(0.08))
		draw_arc(hp, 22.0 * puls, 0.0, TAU, 32, col.lightened(0.35), 2.0)

		# — Ojos ──────────────────────────────────────────────
		var el := hp + Vector2(-7.5, -3.0)
		var er := hp + Vector2( 7.5, -3.0)
		draw_circle(el, 4.5, Color(1.0, 1.0, 1.0, 0.93))
		draw_circle(er, 4.5, Color(1.0, 1.0, 1.0, 0.93))
		draw_circle(el + Vector2( 0.5,  0.5), 2.5, Color(0.08, 0.04, 0.18))
		draw_circle(er + Vector2( 0.5,  0.5), 2.5, Color(0.08, 0.04, 0.18))
		draw_circle(el + Vector2( 2.0, -1.5), 1.0, Color(1.0, 1.0, 1.0, 0.88))
		draw_circle(er + Vector2( 2.0, -1.5), 1.0, Color(1.0, 1.0, 1.0, 0.88))

		# — Boca (sonrisa) ────────────────────────────────────
		draw_arc(hp + Vector2(0, 8.0), 7.5, 0.30, PI - 0.30, 10,
				 col.lightened(0.60), 2.0)

		# — Collar ────────────────────────────────────────────
		draw_arc(hp + Vector2(0, 17.0), 9.0, 0.40, PI - 0.40, 10,
				 col.lightened(0.45), 2.0)

		# — Marco circular decorativo ─────────────────────────
		draw_arc(Vector2(45, 58), 44.0, 0.0, TAU, 32,
				 Color(col.r, col.g, col.b, 0.38), 1.5)


# Flechita ▼ que rebota cuando la línea terminó de escribirse.
class FlechaContinuar extends Control:
	var _t : float = 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(10, 12)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER

	func _process(delta: float) -> void:
		if not is_visible_in_tree(): return
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var dy := absf(sin(_t * 4.0)) * 3.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, dy), Vector2(10, dy), Vector2(5, 7 + dy)]), VERDE_HINT)


func _ready() -> void:
	layer = 10
	add_to_group("ui_dialogo")
	_crear_ui()
	hide()


func _crear_ui() -> void:
	# ── Panel principal (ancho completo, pegado abajo) ────────
	var panel := Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top    = -185.0
	panel.offset_bottom =    0.0

	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.055, 0.07, 0.11, 0.96)
	ps.border_color = Color(0.22, 0.72, 0.22)
	ps.set_border_width_all(2)
	ps.corner_radius_top_left  = 10
	ps.corner_radius_top_right = 10
	panel.add_theme_stylebox_override("panel", ps)
	add_child(panel)
	_panel_clasico = panel

	# Franja de acento verde en el borde superior del panel
	var acento := ColorRect.new()
	acento.set_anchors_preset(Control.PRESET_TOP_WIDE)
	acento.custom_minimum_size = Vector2(0, 3)
	acento.offset_bottom       = 3.0
	acento.color               = Color(0.22, 0.80, 0.28, 0.65)
	acento.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	panel.add_child(acento)

	# ── Margen interior ──────────────────────────────────────
	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mg.add_theme_constant_override("margin_left",   16)
	mg.add_theme_constant_override("margin_right",  16)
	mg.add_theme_constant_override("margin_top",    10)
	mg.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(mg)

	# ── HBox: izquierda (retrato+nombre) | derecha (texto+hint)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	mg.add_child(hbox)

	# ── Columna izquierda ────────────────────────────────────
	var col_izq := VBoxContainer.new()
	col_izq.custom_minimum_size   = Vector2(102, 0)
	col_izq.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col_izq.alignment             = BoxContainer.ALIGNMENT_CENTER
	col_izq.add_theme_constant_override("separation", 5)
	hbox.add_child(col_izq)

	var retrato_cont := Control.new()
	retrato_cont.custom_minimum_size = Vector2(90, 116)
	retrato_cont.clip_contents       = true
	col_izq.add_child(retrato_cont)

	_retrato_nodo = RetratoNPC.new()
	retrato_cont.add_child(_retrato_nodo)

	_nombre_lbl = Label.new()
	_nombre_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nombre_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD
	_nombre_lbl.add_theme_font_size_override("font_size", 12)
	_nombre_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.45))
	col_izq.add_child(_nombre_lbl)

	# ── Separador vertical ───────────────────────────────────
	var vsep := VSeparator.new()
	var vs := StyleBoxFlat.new()
	vs.bg_color = Color(0.22, 0.72, 0.22, 0.40)
	vs.content_margin_left = 1.0
	vsep.add_theme_stylebox_override("separator", vs)
	hbox.add_child(vsep)

	# ── Columna derecha ──────────────────────────────────────
	var col_der := VBoxContainer.new()
	col_der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_der.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	hbox.add_child(col_der)

	_texto_lbl = Label.new()
	_texto_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_texto_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_texto_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	_texto_lbl.add_theme_font_size_override("font_size", 16)
	_texto_lbl.add_theme_color_override("font_color", Color.WHITE)
	col_der.add_child(_texto_lbl)

	_hint_lbl = Label.new()
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_lbl.add_theme_font_size_override("font_size", 11)
	_hint_lbl.add_theme_color_override("font_color", VERDE_HINT)
	col_der.add_child(_hint_lbl)

	_texto_clasico = _texto_lbl
	_hint_clasico  = _hint_lbl
	_crear_caja_nueva()


# Misma caja que el panel clásico (fondo, borde verde, franja de acento),
# pero centrada y flotando sobre el borde inferior, con el nombre en una
# pestaña y el sprite del NPC como retrato.
func _crear_caja_nueva() -> void:
	# Oscurece el mapa y el HUD de atrás mientras se habla.
	_velo = ColorRect.new()
	_velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_velo.color        = Color(0, 0, 0, 0.30)
	_velo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_velo.visible      = false
	add_child(_velo)

	_caja = Panel.new()
	_caja.name          = "CajaNueva"
	_caja.anchor_left   = 0.5
	_caja.anchor_right  = 0.5
	_caja.anchor_top    = 1.0
	_caja.anchor_bottom = 1.0
	_caja.offset_left   = -ANCHO_CAJA * 0.5
	_caja.offset_right  =  ANCHO_CAJA * 0.5
	_caja.offset_top    = -MARGEN_INF - ALTO_CAJA
	_caja.offset_bottom = -MARGEN_INF
	_caja.visible       = false
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.055, 0.07, 0.11, 0.96)
	ps.border_color = VERDE_BORDE
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	_caja.add_theme_stylebox_override("panel", ps)
	add_child(_caja)

	var acento := ColorRect.new()
	acento.set_anchors_preset(Control.PRESET_TOP_WIDE)
	acento.offset_left   = 10.0
	acento.offset_right  = -10.0
	acento.offset_top    = 2.0
	acento.offset_bottom = 5.0
	acento.color         = Color(0.22, 0.80, 0.28, 0.65)
	acento.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	_caja.add_child(acento)

	# ── Pestaña con el nombre, pegada al borde superior ──────
	# Su fondo tapa el tramo del borde de la caja que queda debajo, así
	# pestaña y caja se ven como una sola pieza.
	_pestana = Panel.new()
	_pestana.position = Vector2(24, -28)
	_pestana.size     = Vector2(160, 30)
	_caja.add_child(_pestana)

	_pestana_lbl = Label.new()
	_pestana_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pestana_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pestana_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_pestana_lbl.add_theme_font_size_override("font_size", 14)
	_pestana.add_child(_pestana_lbl)

	# ── Contenido: retrato | texto ───────────────────────────
	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mg.add_theme_constant_override("margin_left",   16)
	mg.add_theme_constant_override("margin_right",  20)
	mg.add_theme_constant_override("margin_top",    15)
	mg.add_theme_constant_override("margin_bottom", 15)
	_caja.add_child(mg)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	mg.add_child(hbox)

	_marco_retrato = Panel.new()
	_marco_retrato.custom_minimum_size = Vector2.ONE * (LADO_RECORTE * ZOOM_RETRATO + 4)
	_marco_retrato.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_marco_retrato.clip_contents       = true
	hbox.add_child(_marco_retrato)

	_retrato_tex = TextureRect.new()
	_retrato_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_retrato_tex.offset_left   = 2.0
	_retrato_tex.offset_top    = 2.0
	_retrato_tex.offset_right  = -2.0
	_retrato_tex.offset_bottom = -2.0
	_retrato_tex.expand_mode    = TextureRect.EXPAND_IGNORE_SIZE
	_retrato_tex.stretch_mode   = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato_tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_marco_retrato.add_child(_retrato_tex)

	var col_der := VBoxContainer.new()
	col_der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_der.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	hbox.add_child(col_der)

	_texto_nuevo = Label.new()
	_texto_nuevo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_texto_nuevo.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_texto_nuevo.vertical_alignment  = VERTICAL_ALIGNMENT_TOP
	_texto_nuevo.add_theme_font_size_override("font_size", 18)
	_texto_nuevo.add_theme_color_override("font_color", Color(0.96, 0.96, 0.92))
	_texto_nuevo.add_theme_constant_override("line_spacing", 4)
	col_der.add_child(_texto_nuevo)

	# ── Fila inferior: contador · [E] Continuar ▼ ─────────────
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	col_der.add_child(fila)

	var relleno := Control.new()
	relleno.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(relleno)

	_contador_lbl = Label.new()
	_contador_lbl.add_theme_font_size_override("font_size", 12)
	_contador_lbl.add_theme_color_override("font_color", Color(0.55, 0.62, 0.68))
	fila.add_child(_contador_lbl)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(10, 0)
	fila.add_child(sep)

	var tecla := Panel.new()
	tecla.custom_minimum_size = Vector2(22, 22)
	tecla.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ts := StyleBoxFlat.new()
	ts.bg_color     = Color(0.09, 0.14, 0.12)
	ts.border_color = VERDE_BORDE
	ts.set_border_width_all(1)
	ts.border_width_bottom = 3
	ts.set_corner_radius_all(4)
	tecla.add_theme_stylebox_override("panel", ts)
	fila.add_child(tecla)

	var tecla_lbl := Label.new()
	tecla_lbl.text = "E"
	tecla_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tecla_lbl.offset_bottom        = -2.0
	tecla_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tecla_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	tecla_lbl.add_theme_font_size_override("font_size", 12)
	tecla_lbl.add_theme_color_override("font_color", VERDE_HINT)
	tecla.add_child(tecla_lbl)

	_hint_nuevo = Label.new()
	_hint_nuevo.add_theme_font_size_override("font_size", 13)
	_hint_nuevo.add_theme_color_override("font_color", VERDE_HINT)
	fila.add_child(_hint_nuevo)

	_flecha = FlechaContinuar.new()
	fila.add_child(_flecha)


# Cabeza y torso del sprite: un cuadrado desde 2 px sobre la cabeza,
# centrado en el cuerpo. Se muestra ×ZOOM_RETRATO con filtro NEAREST.
func _recorte_retrato(tex: Texture2D) -> Texture2D:
	var img : Image = tex.get_image()
	var usado : Rect2i = img.get_used_rect() if img else Rect2i(Vector2i(0, 5), Vector2i(tex.get_size()))
	var cx : float = roundf(usado.position.x + usado.size.x * 0.5)
	var at := AtlasTexture.new()
	at.atlas  = tex
	at.region = Rect2(cx - LADO_RECORTE * 0.5, usado.position.y - 2, LADO_RECORTE, LADO_RECORTE)
	return at


func _preparar_caja(nombre: String, color: Color, retrato: Texture2D) -> void:
	_pestana_lbl.text = nombre
	_pestana_lbl.add_theme_color_override("font_color", color.lightened(0.35))
	_pestana.size.x = maxf(_pestana_lbl.get_minimum_size().x + 32.0, 110.0)
	var tab := StyleBoxFlat.new()
	tab.bg_color     = Color(0.055, 0.07, 0.11, 1.0)
	tab.border_color = VERDE_BORDE
	tab.set_border_width_all(2)
	tab.border_width_bottom    = 0
	tab.corner_radius_top_left  = 8
	tab.corner_radius_top_right = 8
	_pestana.add_theme_stylebox_override("panel", tab)

	var ms := StyleBoxFlat.new()
	ms.bg_color     = color.darkened(0.70)
	ms.border_color = color.lightened(0.10)
	ms.set_border_width_all(2)
	ms.set_corner_radius_all(8)
	_marco_retrato.add_theme_stylebox_override("panel", ms)
	_retrato_tex.texture = _recorte_retrato(retrato)

	# Entrada: sube 14 px con fundido.
	if _tween_caja: _tween_caja.kill()
	_caja.modulate.a    = 0.0
	_velo.modulate.a    = 0.0
	_caja.offset_top    = -MARGEN_INF - ALTO_CAJA + 14.0
	_caja.offset_bottom = -MARGEN_INF + 14.0
	_tween_caja = create_tween().set_parallel()
	_tween_caja.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween_caja.tween_property(_velo, "modulate:a", 1.0, 0.15)
	_tween_caja.tween_property(_caja, "modulate:a", 1.0, 0.15)
	_tween_caja.tween_property(_caja, "offset_top", -MARGEN_INF - ALTO_CAJA, 0.15)
	_tween_caja.tween_property(_caja, "offset_bottom", -MARGEN_INF, 0.15)


# ── API pública ───────────────────────────────────────────────
func iniciar(nombre: String, textos: PackedStringArray,
			 mision_id: String = "", color: Color = Color.GRAY,
			 retrato: Texture2D = null) -> void:
	_dialogos  = textos
	_indice    = 0
	_mision_id = mision_id
	if _retrato_nodo:
		_retrato_nodo.col = color
	_nombre_lbl.text = nombre

	_diseno_nuevo = retrato != null
	_panel_clasico.visible = not _diseno_nuevo
	_velo.visible          = _diseno_nuevo
	_caja.visible          = _diseno_nuevo
	_texto_lbl = _texto_nuevo if _diseno_nuevo else _texto_clasico
	_hint_lbl  = _hint_nuevo  if _diseno_nuevo else _hint_clasico
	if _diseno_nuevo:
		_preparar_caja(nombre, color, retrato)

	_mostrar_linea()
	show()
	# Pista contextual: primera vez que se abre un diálogo
	var hb = get_tree().get_first_node_in_group("hint_bubble")
	if hb:
		hb.push("primer_dialogo",
			"📖 Lee el mensaje del NPC y presiona [E] para continuar.")


# ── Internos ─────────────────────────────────────────────────
func _mostrar_linea() -> void:
	_texto_completo = _dialogos[_indice]
	_chars_vis      = 0
	_timer          = 0.0
	_escribiendo    = true
	_texto_lbl.text = ""
	var es_ultimo   := (_indice >= _dialogos.size() - 1)
	# En la caja nueva la tecla va dibujada aparte, sin "[E]" en el texto.
	var tecla := "" if _diseno_nuevo else "[E] "
	if es_ultimo and _mision_id != "":
		_hint_lbl.text = tecla + "Continuar misión"
	elif es_ultimo:
		_hint_lbl.text = tecla + "Cerrar"
	else:
		_hint_lbl.text = tecla + "Continuar"
	_contador_lbl.text = "%d / %d" % [_indice + 1, _dialogos.size()]
	_contador_lbl.visible = _dialogos.size() > 1
	_flecha.visible = false


func _process(delta: float) -> void:
	if not visible or not _escribiendo:
		return
	_timer += delta
	var meta := int(_timer * CHARS_SEG)
	if meta > _chars_vis:
		_chars_vis      = mini(meta, _texto_completo.length())
		_texto_lbl.text = _texto_completo.substr(0, _chars_vis)
		if _chars_vis >= _texto_completo.length():
			_escribiendo = false
			_flecha.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not event.is_action_pressed("interactuar"):
		return
	get_viewport().set_input_as_handled()

	if _escribiendo:
		# Saltar typewriter: mostrar texto completo al instante
		_chars_vis      = _texto_completo.length()
		_texto_lbl.text = _texto_completo
		_escribiendo    = false
		_flecha.visible = true
		return

	_indice += 1
	if _indice >= _dialogos.size():
		hide()
		_indice = 0
		dialogo_terminado.emit(_mision_id)
	else:
		_mostrar_linea()
