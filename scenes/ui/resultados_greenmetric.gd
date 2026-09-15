# ============================================================
# resultados_greenmetric.gd — URBE Rangers: Eco-Quest
# Pantalla final de reporte estilo UI GreenMetric.
# Se muestra al completar todas las misiones o al pulsar Tab.
# ============================================================
extends CanvasLayer

signal cerrar_resultados()

const MODULOS_INFO : Array = [
	{"id": 1, "nombre": "Setting & Infrastructure", "icono": "🌿", "peso": 15,
	 "color": Color(0.18, 0.75, 0.28), "desc": "Áreas verdes, política ambiental, certificaciones"},
	{"id": 2, "nombre": "Energy & Climate Change",  "icono": "⚡", "peso": 21,
	 "color": Color(0.95, 0.60, 0.05), "desc": "Consumo energético, renovables, emisiones CO₂"},
	{"id": 3, "nombre": "Waste",                    "icono": "♻", "peso": 18,
	 "color": Color(0.90, 0.78, 0.05), "desc": "Reciclaje, reducción, política de residuos"},
	{"id": 4, "nombre": "Water",                    "icono": "💧", "peso": 10,
	 "color": Color(0.05, 0.55, 0.92), "desc": "Eficiencia hídrica, tratamiento, monitoreo"},
	{"id": 5, "nombre": "Transportation",           "icono": "🚲", "peso": 18,
	 "color": Color(0.15, 0.35, 0.92), "desc": "Movilidad sostenible, bicicletas, transporte público"},
	{"id": 6, "nombre": "Education & Research",     "icono": "📚", "peso": 18,
	 "color": Color(0.58, 0.05, 0.88), "desc": "Materias ambientales, publicaciones, iniciativas"},
]

const RANKING_SIMULADO : Array = [
	"Wageningen University",
	"UC Davis",
	"Nottingham University",
	"Leiden University",
	"UNIVERSIDAD URBE ← TÚ",
	"UNAM",
	"UCV",
	"USB",
]

var _progreso : Dictionary = {}
var _xp_total : int        = 0

var _panel       : Panel          = null
var _barras      : Array          = []
var _score_lbl   : Label          = null
var _rank_lbl    : Label          = null
var _t_anim      : float          = 0.0
var _animando    : bool           = false
var _anim_idx    : int            = 0


func _ready() -> void:
	layer = 20
	_crear_ui()
	hide()


func mostrar(progreso: Dictionary, xp: int) -> void:
	_progreso = progreso
	_xp_total = xp
	_t_anim   = 0.0
	_animando = true
	_anim_idx = 0
	for b in _barras:
		(b as ColorRect).size.x = 0.0
	_score_lbl.text = "Calculando..."
	_rank_lbl.text  = ""
	_panel.modulate.a = 0.0
	_panel.scale      = Vector2(0.88, 0.88)
	show()
	var tw := create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(_panel, "scale", Vector2(1.0, 1.0), 0.28)
	if AudioManager:
		AudioManager.tocar("resultados")


func _process(delta: float) -> void:
	if not _animando: return
	_t_anim += delta
	if _t_anim < 0.4: return   # pequeña pausa inicial

	var BARRA_W : float = 280.0
	if _anim_idx < MODULOS_INFO.size():
		var info : Dictionary = MODULOS_INFO[_anim_idx]
		var pct  : float = clampf(float(_progreso.get(info["id"], 0.0)), 0.0, 1.0)
		var tw := create_tween().set_ease(Tween.EASE_OUT)
		tw.tween_property(_barras[_anim_idx], "size:x", BARRA_W * pct, 0.45)
		_anim_idx += 1
	elif _anim_idx == MODULOS_INFO.size():
		_anim_idx += 1
		await get_tree().create_timer(0.5).timeout
		if not is_instance_valid(self): return
		_mostrar_score_final()
		_animando = false


func _mostrar_score_final() -> void:
	# El total sale de PuntajeManager (el mismo número que el informe final y
	# el HUD) en vez de recalcularlo aquí con la copia de pesos de
	# MODULOS_INFO: recalcular desde fracciones redondeadas daba diferencias
	# de 0.1 con el informe. Los pesos de arriba quedan solo para la etiqueta
	# "×N" de cada barra.
	var score_100 : float = PuntajeManager.total
	_score_lbl.text = "%.1f / 100" % score_100

	var pos : int = 8
	if score_100 >= 80.0:    pos = 1
	elif score_100 >= 65.0:  pos = 3
	elif score_100 >= 50.0:  pos = 5
	elif score_100 >= 35.0:  pos = 7

	_rank_lbl.text = "Posición estimada: #%d / 1.050 universidades" % pos

	var tw := create_tween()
	tw.tween_property(_score_lbl, "modulate:a", 1.0, 0.35).from(0.0)
	tw.parallel().tween_property(_rank_lbl,  "modulate:a", 1.0, 0.35).from(0.0)


# ════════════════════════════════════════════════════════════
# CONSTRUCCIÓN DE UI
# ════════════════════════════════════════════════════════════
func _crear_ui() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.80)
	add_child(overlay)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(680, 500)
	_panel.offset_left   = -340
	_panel.offset_top    = -250
	_panel.offset_right  =  340
	_panel.offset_bottom =  250
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.07, 0.06, 0.98)
	ps.border_color = Color(0.22, 0.80, 0.28)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(16)
	ps.shadow_color = Color(0.10, 0.60, 0.20, 0.55)
	ps.shadow_size  = 22
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mg.add_theme_constant_override("margin_left",   28)
	mg.add_theme_constant_override("margin_right",  28)
	mg.add_theme_constant_override("margin_top",    20)
	mg.add_theme_constant_override("margin_bottom", 20)
	_panel.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	mg.add_child(vbox)

	# ── Encabezado ───────────────────────────────────────────
	var titulo := Label.new()
	titulo.text = "🏆  UI GreenMetric — Reporte URBE"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 18)
	titulo.add_theme_color_override("font_color", Color(0.28, 1.00, 0.38))
	vbox.add_child(titulo)

	var sep := _hacer_sep()
	vbox.add_child(sep)

	# ── Módulos ──────────────────────────────────────────────
	for i in MODULOS_INFO.size():
		var info : Dictionary = MODULOS_INFO[i]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		vbox.add_child(fila)

		var icono := Label.new()
		icono.text = info["icono"]
		icono.custom_minimum_size = Vector2(24, 0)
		icono.add_theme_font_size_override("font_size", 14)
		fila.add_child(icono)

		var nombre := Label.new()
		nombre.text = info["nombre"]
		nombre.custom_minimum_size = Vector2(220, 0)
		nombre.add_theme_font_size_override("font_size", 11)
		nombre.add_theme_color_override("font_color", Color(0.80, 0.88, 0.82))
		fila.add_child(nombre)

		# Barra
		var barra_bg := ColorRect.new()
		barra_bg.custom_minimum_size = Vector2(280, 14)
		barra_bg.color = Color(0.08, 0.12, 0.16)
		fila.add_child(barra_bg)

		var barra_fill := ColorRect.new()
		barra_fill.size  = Vector2(0, 14)
		barra_fill.color = info["color"]
		barra_bg.add_child(barra_fill)
		_barras.append(barra_fill)

		var peso_lbl := Label.new()
		peso_lbl.text = "×%d" % info["peso"]
		peso_lbl.custom_minimum_size = Vector2(28, 0)
		peso_lbl.add_theme_font_size_override("font_size", 9)
		peso_lbl.add_theme_color_override("font_color", Color(0.45, 0.50, 0.45))
		fila.add_child(peso_lbl)

	vbox.add_child(_hacer_sep())

	# ── Score global ─────────────────────────────────────────
	var fila_score := HBoxContainer.new()
	fila_score.alignment = BoxContainer.ALIGNMENT_CENTER
	fila_score.add_theme_constant_override("separation", 18)
	vbox.add_child(fila_score)

	var score_titulo := Label.new()
	score_titulo.text = "Score GreenMetric:"
	score_titulo.add_theme_font_size_override("font_size", 15)
	score_titulo.add_theme_color_override("font_color", Color(0.70, 0.78, 0.72))
	fila_score.add_child(score_titulo)

	_score_lbl = Label.new()
	_score_lbl.add_theme_font_size_override("font_size", 22)
	_score_lbl.add_theme_color_override("font_color", Color(0.28, 1.00, 0.40))
	_score_lbl.modulate.a = 0.0
	fila_score.add_child(_score_lbl)

	_rank_lbl = Label.new()
	_rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rank_lbl.add_theme_font_size_override("font_size", 12)
	_rank_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.18))
	_rank_lbl.modulate.a = 0.0
	vbox.add_child(_rank_lbl)

	# XP total
	var xp_lbl := Label.new()
	xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_lbl.add_theme_font_size_override("font_size", 11)
	xp_lbl.add_theme_color_override("font_color", Color(0.55, 0.62, 0.58))
	xp_lbl.text = "XP acumulada esta sesión: —"
	xp_lbl.name = "XpLbl"
	vbox.add_child(xp_lbl)

	# ── Botón cerrar ─────────────────────────────────────────
	var btn := Button.new()
	btn.text = "Continuar jugando"
	btn.custom_minimum_size = Vector2(200, 40)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bs := StyleBoxFlat.new()
	bs.bg_color     = Color(0.08, 0.22, 0.10)
	bs.border_color = Color(0.22, 0.80, 0.28)
	bs.set_border_width_all(2)
	bs.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", bs)
	btn.add_theme_color_override("font_color", Color(0.28, 1.00, 0.38))
	btn.add_theme_font_size_override("font_size", 14)
	btn.pressed.connect(func():
		var tw := create_tween()
		tw.tween_property(_panel, "modulate:a", 0.0, 0.20)
		tw.tween_callback(func(): hide(); cerrar_resultados.emit()))
	vbox.add_child(btn)


func _hacer_sep() -> HSeparator:
	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.22, 0.72, 0.22, 0.28)
	sep_s.content_margin_top = 1.0; sep_s.content_margin_bottom = 1.0
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", sep_s)
	return sep


func actualizar_xp(xp: int) -> void:
	_xp_total = xp
	var lbl : Label = _panel.find_child("XpLbl", true, false)
	if lbl:
		lbl.text = "XP acumulada esta sesión: %d XP" % xp
