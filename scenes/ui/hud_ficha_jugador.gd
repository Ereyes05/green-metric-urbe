# ============================================================
# hud_ficha_jugador.gd — ficha arriba a la izquierda (spec 2b §1):
# nombre y vidas, nivel de misiones con 6 pasos, rango + EcoCredits y
# barra hacia el siguiente rango. Solo muestra lo que le pasan; no lee
# autoloads.
#
# Los "índices del campus" (Verde/Agua/Educación) vivían acá desde antes
# del panel GreenMetric. Repetían tres de sus seis filas con el mismo
# número — PuntajeManager.fraccion(cat) es valor(cat)/100 — y encima le
# decían "Verde" a la categoría que el panel llama "Entorno". El panel es
# la única vista de categorías; la ficha muestra solo lo suyo.
# ============================================================
extends PanelContainer

const TEMA   := preload("res://scenes/ui/hud_tema.gd")
const BARRA  := preload("res://scenes/ui/hud_barra.gd")
const RANGOS := preload("res://autoload/rangos.gd")

var corazones    : Array[Label] = []
var pasos        : Array[Panel] = []
var nivel_lbl    : Label
var rango_lbl    : Label
var creditos_lbl : Label
var hacia_lbl    : Label
var xp_lbl       : Label
var barra_xp


func _init() -> void:
	position = Vector2(16, 16)
	custom_minimum_size = Vector2(268, 0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", TEMA.panel(TEMA.VERDE))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vb)

	# Fila 1: nombre + vidas
	var f1 := _hbox(6)
	f1.add_child(TEMA.label("🌿", 14, TEMA.TEXTO))
	var nom := TEMA.label("Eco-Ranger", 11, TEMA.TEXTO, 400, true)
	nom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f1.add_child(nom)
	var vidas := _hbox(2)
	for i in 3:
		var c := TEMA.label("♥", 12, TEMA.VIDAS)
		corazones.append(c)
		vidas.add_child(c)
	f1.add_child(vidas)
	vb.add_child(f1)

	# Fila 2: nivel de misiones
	var caja := PanelContainer.new()
	caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caja.add_theme_stylebox_override("panel", TEMA.caja(Color(TEMA.TEAL, 0.12), Color(TEMA.TEAL, 0.45), 1, 8, 8, 5))
	var f2 := _hbox(8)
	var textos := VBoxContainer.new()
	textos.add_theme_constant_override("separation", 0)
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	textos.add_child(TEMA.label("NIVEL DE MISIONES", 9, TEMA.APAGADO))
	nivel_lbl = TEMA.label("Nivel 1/6 · Entorno", 12, TEMA.TEXTO, 600)
	textos.add_child(nivel_lbl)
	f2.add_child(textos)
	var hp := _hbox(2)
	hp.alignment = BoxContainer.ALIGNMENT_END
	hp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in 6:
		var p := Panel.new()
		p.custom_minimum_size = Vector2(4, 12)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_theme_stylebox_override("panel", TEMA.caja(TEMA.PASO_PENDIENTE, Color.TRANSPARENT, 0, 1))
		pasos.append(p)
		hp.add_child(p)
	f2.add_child(hp)
	caja.add_child(f2)
	vb.add_child(caja)

	# Fila 3: rango + EcoCredits
	var f3 := _hbox(4)
	f3.add_child(TEMA.label("⭐", 12, TEMA.DORADO))
	f3.add_child(TEMA.label("RANGO", 9, TEMA.APAGADO))
	rango_lbl = TEMA.label("Semilla", 12, TEMA.DORADO, 600)
	rango_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	f3.add_child(rango_lbl)
	creditos_lbl = TEMA.label("💰 0 EC", 13, TEMA.DORADO, 600, false, true)
	f3.add_child(creditos_lbl)
	vb.add_child(f3)

	# Barra hacia el siguiente rango
	var bloque_xp := VBoxContainer.new()
	bloque_xp.add_theme_constant_override("separation", 4)
	bloque_xp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	barra_xp = BARRA.new()
	barra_xp.configurar(TEMA.CIAN, 10)
	bloque_xp.add_child(barra_xp)
	var fx := _hbox(4)
	hacia_lbl = TEMA.label("Hacia Brote", 10, TEMA.TEXTO_3)
	hacia_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fx.add_child(hacia_lbl)
	xp_lbl = TEMA.label("0 XP", 10, TEMA.TEXTO_3, 400, false, true)
	fx.add_child(xp_lbl)
	bloque_xp.add_child(fx)
	vb.add_child(bloque_xp)


func _hbox(sep: int) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


func set_energia(actual: int, maximo: int) -> void:
	for i in corazones.size():
		corazones[i].visible = i < maximo
		corazones[i].add_theme_color_override("font_color", TEMA.VIDAS if i < actual else TEMA.VACIO)


func set_nivel_misiones(nivel: int, hechos: Array) -> void:
	var n := clampi(nivel, 1, 6)
	nivel_lbl.text = "Nivel %d/6 · %s" % [n, TEMA.CATEGORIAS[n]["nombre"]]
	for i in pasos.size():
		var hecho : bool = i < hechos.size() and bool(hechos[i])
		pasos[i].add_theme_stylebox_override("panel",
			TEMA.caja(TEMA.TEAL if hecho else TEMA.PASO_PENDIENTE, Color.TRANSPARENT, 0, 1))


func set_rango(niveles_completos: int, fraccion: float, xp: int) -> void:
	rango_lbl.text = RANGOS.nombre(niveles_completos)
	var sig := RANGOS.siguiente(niveles_completos)
	hacia_lbl.text = "Rango máximo" if sig == "" else "Hacia " + sig
	barra_xp.set_fraccion(1.0 if sig == "" else fraccion)
	xp_lbl.text = "%d XP" % xp


func set_creditos(ec: int) -> void:
	creditos_lbl.text = "💰 %d EC" % ec
