# ============================================================
# hud_ficha_jugador.gd — ficha arriba a la izquierda (spec 2b §1):
# nombre y vidas, nivel de misiones con 6 pasos, rango + EcoCredits,
# barra hacia el siguiente rango e índices del campus DENTRO del panel.
# Solo muestra lo que le pasan; no lee autoloads.
# ============================================================
extends PanelContainer

const TEMA   := preload("res://scenes/ui/hud_tema.gd")
const BARRA  := preload("res://scenes/ui/hud_barra.gd")
const RANGOS := preload("res://autoload/rangos.gd")

const INDICES : Array = [
	{"cat": 1, "icono": "🌿", "nombre": "Verde"},
	{"cat": 4, "icono": "💧", "nombre": "Agua"},
	{"cat": 6, "icono": "📚", "nombre": "Educación"},
]

var corazones    : Array[Label] = []
var pasos        : Array[Panel] = []
var nivel_lbl    : Label
var rango_lbl    : Label
var creditos_lbl : Label
var hacia_lbl    : Label
var xp_lbl       : Label
var barra_xp
var indices      : Dictionary = {}


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

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = TEMA.SEPARADOR
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(sep)

	# Índices del campus
	var bloque_ind := VBoxContainer.new()
	bloque_ind.add_theme_constant_override("separation", 6)
	bloque_ind.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bloque_ind.add_child(TEMA.label("ÍNDICES DEL CAMPUS", 10, TEMA.APAGADO))
	for d in INDICES:
		var cat : int = d["cat"]
		var fila := _hbox(6)
		fila.custom_minimum_size.y = 14
		var ic := TEMA.label(d["icono"], 14, TEMA.TEXTO)
		ic.custom_minimum_size.x = 18
		fila.add_child(ic)
		var nl := TEMA.label(d["nombre"], 11, TEMA.TEXTO_2)
		nl.custom_minimum_size.x = 64
		fila.add_child(nl)
		var b = BARRA.new()
		b.configurar(TEMA.CATEGORIAS[cat]["color"], 6)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(b)
		var pct := TEMA.label("0%", 11, TEMA.TEXTO, 600, false, true)
		pct.custom_minimum_size.x = 32
		pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		fila.add_child(pct)
		bloque_ind.add_child(fila)
		indices[cat] = {"barra": b, "pct": pct}
	vb.add_child(bloque_ind)


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


func set_indices(fracciones: Dictionary) -> void:
	for cat in indices.keys():
		var f := clampf(float(fracciones.get(cat, 0.0)), 0.0, 1.0)
		indices[cat]["barra"].set_fraccion(f)
		indices[cat]["pct"].text = "%d%%" % roundi(f * 100.0)
