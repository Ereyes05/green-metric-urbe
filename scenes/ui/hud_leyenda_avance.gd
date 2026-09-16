# ============================================================
# hud_leyenda_avance.gd — leyenda del "Mapa de avance" (botón [1] de la
# barra de acciones), anclada abajo a la izquierda justo encima de esa
# barra. Oculta por defecto; SceneMapaMundo la muestra/oculta según el
# estado que devuelve mapa_campus.toggle_mapa_avance().
# ============================================================
extends PanelContainer

const TEMA        := preload("res://scenes/ui/hud_tema.gd")
const MAPA_CAMPUS := preload("res://scenes/mapa/mapa_campus.gd")

# {"texto": String, "pct": float de referencia para el color del chip}
const NIVELES : Array = [
	{"texto": "Bajo  < 40%",    "pct": 0.0},
	{"texto": "Medio  40–74%",  "pct": 0.5},
	{"texto": "Alto  ≥ 75%",    "pct": 1.0},
]

const ANCHO : float = 200.0
const ALTO  : float = 132.0

# Filas de nivel expuestas para la prueba (test_hud_controles.gd).
var filas_nivel : Array = []


func _init() -> void:
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	offset_left   = 16
	offset_right  = 16 + ANCHO
	offset_bottom = -83.0   # justo encima de hud_acciones (botones: y 645–704)
	offset_top    = offset_bottom - ALTO
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	add_theme_stylebox_override("panel", TEMA.panel(TEMA.LEYENDA))

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vb)

	vb.add_child(TEMA.label("MAPA DE AVANCE", 11, TEMA.TEXTO, 600))

	var filas := VBoxContainer.new()
	filas.add_theme_constant_override("separation", 5)
	filas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(filas)
	for n in NIVELES:
		filas.add_child(_fila_nivel(n))

	var muted := TEMA.label("Avance GreenMetric de cada zona", 9, TEMA.APAGADO)
	muted.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(muted)


func _fila_nivel(n: Dictionary) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var chip := Panel.new()
	chip.custom_minimum_size = Vector2(12, 12)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col : Color = MAPA_CAMPUS.color_nivel(n["pct"])
	chip.add_theme_stylebox_override("panel", TEMA.caja(col, Color.TRANSPARENT, 0, 3))
	fila.add_child(chip)

	fila.add_child(TEMA.label(n["texto"], 10, TEMA.TEXTO_2))

	filas_nivel.append(fila)
	return fila


func set_activo(activo: bool) -> void:
	visible = activo
