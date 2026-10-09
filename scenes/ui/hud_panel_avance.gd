# ============================================================
# hud_panel_avance.gd — botón [1] "Avance" de la barra de acciones.
# Ventana con el avance de misiones por nivel: cuántas lleva de cada uno,
# un cuadrito por misión y si el nivel está completo, en curso o bloqueado.
#
# Reemplaza al "mapa de avance" (colores sobre cada zona), que se dibujaba
# en mapa_campus.gd con las coordenadas del mapa viejo de 1408×768: con la
# imagen nueva del campus quedó tapado y el botón no mostraba nada.
#
# Lee todo de NivelManager cada vez que se abre, así que no hace falta
# avisarle cuando se completa una misión.
# ============================================================
extends CanvasLayer

const TEMA := preload("res://scenes/ui/hud_tema.gd")

const ANCHO : float = 560.0

var _overlay  : ColorRect     = null
var _resumen  : Label         = null
var _barra    : ProgressBar   = null
var _filas_vb : VBoxContainer = null

# Una entrada por nivel, expuesta para test_hud_avance.gd:
# {"nivel", "hechas", "total", "estado", "cuenta": Label, "estado_lbl": Label}
var filas : Array = []


func _ready() -> void:
	layer = 15
	_crear_ui()
	hide()


func mostrar() -> void:
	_poblar()
	show()


func cerrar() -> void:
	hide()


# Devuelve si quedó abierto.
func alternar() -> bool:
	if visible: cerrar()
	else: mostrar()
	return visible


# Esc o la misma tecla 1 lo cierran. Los hijos reciben _input antes que
# SceneMapaMundo, así que Esc no llega a abrir el menú de pausa.
func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode in [KEY_ESCAPE, KEY_1]:
		cerrar()
		get_viewport().set_input_as_handled()


# ── Datos ────────────────────────────────────────────────────
func _poblar() -> void:
	# free() inmediato y no queue_free: si no, las filas viejas siguen en el
	# VBox durante este frame y se suman a las nuevas (mismo caso que el
	# ranking).
	for hijo in _filas_vb.get_children():
		_filas_vb.remove_child(hijo)
		hijo.free()
	filas.clear()

	var hechas_total := 0
	var total := 0
	for n in range(1, 7):
		var ids : Array = NivelManager.misiones_nivel.get(n, [])
		var hechas := 0
		for id in ids:
			if NivelManager.mision_completada_q(n, id): hechas += 1
		hechas_total += hechas
		total += ids.size()

		var estado := "bloqueado"
		if NivelManager.nivel_completo(n): estado = "completo"
		elif NivelManager.nivel_desbloqueado(n): estado = "en_curso"
		_filas_vb.add_child(_fila_nivel(n, ids, hechas, estado))

	_resumen.text = "%d de %d misiones completadas" % [hechas_total, total]
	_barra.value  = 100.0 * hechas_total / maxi(total, 1)


func _fila_nivel(n: int, ids: Array, hechas: int, estado: String) -> Control:
	var cat : Dictionary = TEMA.CATEGORIAS[n]
	var col : Color = cat["color"]

	var caja := PanelContainer.new()
	caja.add_theme_stylebox_override("panel",
		TEMA.caja(Color(col, 0.08), Color(col, 0.35), 1, 8, 12, 8))
	if estado == "bloqueado":
		caja.modulate.a = 0.55

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	caja.add_child(hb)

	var icono := TEMA.label(cat["icono"], 20, TEMA.TEXTO)
	icono.custom_minimum_size = Vector2(28, 0)
	icono.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icono.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(icono)

	var centro := VBoxContainer.new()
	centro.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centro.add_theme_constant_override("separation", 5)
	hb.add_child(centro)
	centro.add_child(TEMA.label("Nivel %d · %s" % [n, NivelManager.NOMBRES_NIVEL[n]],
		13, TEMA.TEXTO, 600))

	# Un cuadrito por misión, lleno si está hecha. Son paneles y no
	# caracteres (●/○) porque la fuente de emojis del HUD es un subconjunto.
	var cuadros := HBoxContainer.new()
	cuadros.add_theme_constant_override("separation", 4)
	centro.add_child(cuadros)
	for id in ids:
		var c := Panel.new()
		c.custom_minimum_size = Vector2(14, 8)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var hecha : bool = NivelManager.mision_completada_q(n, id)
		c.add_theme_stylebox_override("panel",
			TEMA.caja(col if hecha else TEMA.PASO_PENDIENTE, Color.TRANSPARENT, 0, 3))
		cuadros.add_child(c)

	var der := VBoxContainer.new()
	der.alignment = BoxContainer.ALIGNMENT_CENTER
	der.add_theme_constant_override("separation", 2)
	hb.add_child(der)

	var cuenta := TEMA.label("%d/%d" % [hechas, ids.size()], 15, TEMA.TEXTO, 600, false, true)
	cuenta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	der.add_child(cuenta)

	var textos := {"completo": "Completo", "en_curso": "En curso", "bloqueado": "🔒 Bloqueado"}
	var colores := {"completo": TEMA.VERDE, "en_curso": TEMA.DORADO, "bloqueado": TEMA.APAGADO}
	var estado_lbl := TEMA.label(textos[estado], 10, colores[estado], 600)
	estado_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	estado_lbl.custom_minimum_size = Vector2(84, 0)
	der.add_child(estado_lbl)

	filas.append({"nivel": n, "hechas": hechas, "total": ids.size(), "estado": estado,
				  "cuenta": cuenta, "estado_lbl": estado_lbl})
	return caja


# ── UI ───────────────────────────────────────────────────────
func _crear_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	_overlay.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed: cerrar())
	add_child(_overlay)

	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centro)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(ANCHO, 0)
	var estilo := TEMA.panel(TEMA.NARANJA)   # mismo color que el botón Avance
	estilo.content_margin_left   = 20
	estilo.content_margin_right  = 20
	estilo.content_margin_top    = 16
	estilo.content_margin_bottom = 18
	estilo.bg_color = TEMA.POPOVER_BG
	panel.add_theme_stylebox_override("panel", estilo)
	centro.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	var cab := HBoxContainer.new()
	vb.add_child(cab)
	var titulo := TEMA.label("🌡  Tu avance", 18, TEMA.TEXTO, 700)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(titulo)

	var btn_cerrar := Button.new()
	btn_cerrar.text = "✕"
	btn_cerrar.tooltip_text = "Cerrar  [Esc]"
	btn_cerrar.custom_minimum_size = Vector2(30, 30)
	btn_cerrar.focus_mode = Control.FOCUS_NONE
	btn_cerrar.add_theme_stylebox_override("normal", TEMA.caja(TEMA.PANEL_BG, TEMA.VACIO, 1, 6))
	btn_cerrar.add_theme_stylebox_override("hover", TEMA.caja(Color(TEMA.ALERTA, 0.25), TEMA.ALERTA, 1, 6))
	btn_cerrar.add_theme_stylebox_override("pressed", TEMA.caja(Color(TEMA.ALERTA, 0.25), TEMA.ALERTA, 1, 6))
	btn_cerrar.add_theme_color_override("font_color", TEMA.TEXTO_2)
	btn_cerrar.pressed.connect(cerrar)
	cab.add_child(btn_cerrar)

	_resumen = TEMA.label("", 12, TEMA.TEXTO_2)
	vb.add_child(_resumen)

	_barra = ProgressBar.new()
	_barra.custom_minimum_size = Vector2(0, 8)
	_barra.show_percentage = false
	_barra.max_value = 100.0
	_barra.add_theme_stylebox_override("background", TEMA.caja(TEMA.TRACK, Color.TRANSPARENT, 0, 4))
	_barra.add_theme_stylebox_override("fill", TEMA.caja(TEMA.NARANJA, Color.TRANSPARENT, 0, 4))
	vb.add_child(_barra)

	_filas_vb = VBoxContainer.new()
	_filas_vb.add_theme_constant_override("separation", 6)
	vb.add_child(_filas_vb)
