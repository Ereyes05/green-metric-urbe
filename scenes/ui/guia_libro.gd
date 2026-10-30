# ============================================================
# guia_libro.gd — guía rápida dentro del juego, con forma de libro.
# Botón "?" en la esquina inferior derecha (o tecla H, ver
# SceneMapaMundo._input). Es un resumen del manual de usuarios
# (docs/manual_usuarios.md): si cambia una regla del juego, cambiar las dos.
#
# Solo usa emoji que están en NotoColorEmoji-subset.ttf (test_emojis.gd).
# ============================================================
extends CanvasLayer

const TEMA := preload("res://scenes/ui/hud_tema.gd")

const LIBRO  := Vector2(860, 500)
const PAPEL  := Color("#F4ECDA")
const PAPEL_2 := Color("#EADFC6")
const TINTA  := Color("#2A2620")
const TINTA_2 := Color("#5B5246")

# [icono, título, subtítulo, [párrafos]]
const PAGINAS : Array = [
	["📖", "Guía del Eco-Ranger", "Lo esencial para jugar", [
		"Este juego te enseña los seis criterios con los que el ranking UI GreenMetric evalúa qué tan sostenible es una universidad.",
		"Recorres el campus de la URBE, hablas con los responsables de cada área, haces misiones y ves cómo tus decisiones mueven el puntaje del campus.",
		"Pasa las páginas con ‹ › o con las flechas del teclado. Cierra con Esc o con la tecla H.",
	]],
	["🕹", "Controles", "Teclado y ratón", [
		"W A S D o las flechas: mover al Eco-Ranger.",
		"E: hablar con un personaje, entrar a un edificio o empezar una misión. Si hay dos cosas cerca, gana la más cercana.",
		"1 a 5: abrir Avance, Reporte, Ranking, Simular y Tienda.",
		"H: abrir esta guía.   Esc: menú de pausa.",
	]],
	["📊", "Tu pantalla", "Qué muestra cada parte", [
		"Arriba a la izquierda: tu nivel, tu rango y tus EcoCredits.",
		"Arriba a la derecha: el puntaje GreenMetric del campus, de 0 a 100, y una barra por cada criterio. Pasa el cursor por una fila para ver el desglose.",
		"Abajo: los cinco botones de acción. Avance te dice cuántas misiones llevas en cada nivel.",
	]],
	["💬", "Los personajes", "Aprender de cada área", [
		"Cada personaje explica un criterio de GreenMetric y después te hace un cuestionario: 15 segundos por pregunta.",
		"Atienden desde su nivel. Los que se ven apagados todavía no: al pulsar E te dicen desde qué nivel están disponibles.",
		"Cada cuestionario se responde una sola vez. Después puedes volver a escuchar la explicación para repasar.",
	]],
	["🔧", "Misiones", "Actuar en el campus", [
		"Las misiones de campo están en los puntos marcados del mapa: plantar, cambiar a LED, reciclar, cerrar llaves, montar bicicleteros.",
		"Algunas necesitan una herramienta de la tienda. Si te falta, el juego te lo dice.",
		"En las decisiones eliges entre opciones con costo distinto. En las crisis tienes 10 segundos para responder.",
	]],
	["📋", "Test de cierre y correo", "Al terminar cada nivel", [
		"Cuando completas un nivel aparece un test corto, de hasta cinco preguntas, para que compruebes qué te quedó. No da puntos: solo se guarda tu primer intento.",
		"Con los seis tests hechos aparece el test final, con dos preguntas de cada nivel.",
		"Después de cada test te llega un correo con tu avance. Si no lo ves, revisa spam y promociones.",
	]],
	["🏆", "El puntaje GreenMetric", "Cómo se suma", [
		"Cada criterio vale de 0 a 100: misiones 80, cuestionario 10, decisiones 5 y sinergias 5. Actuar es lo que más pesa.",
		"Las sinergias aparecen cuando una acción de un criterio también mejora otro, como los paneles solares, que además bajan la huella de carbono.",
		"El botón Reporte (tecla 2) muestra el detalle.",
	]],
	["🛒", "EcoCredits y tienda", "La moneda del juego", [
		"Ganas EcoCredits al registrarte y con cada misión. No caducan y no se compran con dinero.",
		"Herramientas obligatorias: kit solar (100), kit pluvial (60) y kit de bicicletero (60). Cómpralas antes que lo opcional.",
		"Si una compra opcional te dejaría sin saldo para una herramienta, la tienda te avisa antes de cobrar.",
	]],
	["⭐", "Rangos e insignias", "Tu reconocimiento", [
		"Tu rango sube con cada nivel completado: Semilla, Brote, Árbol, Estratega, Investigador y EcoLíder.",
		"Las insignias se ganan solas al cumplir un logro: completar un nivel, un cuestionario perfecto, resolver una crisis.",
		"La lista de las que tienes llega en el correo de avance.",
	]],
	["💡", "Si algo no funciona", "Antes de pedir ayuda", [
		"La E no hace nada: acércate más.",
		"Un personaje no habla: está apagado porque es de un nivel posterior.",
		"Una misión no arranca: te falta la herramienta de la tienda.",
		"Tu progreso se guarda solo en cada acción. Si se cierra el juego, no pierdes nada.",
	]],
]

var pagina : int = 0

var _boton    : Button  = null
var _overlay  : ColorRect = null
var _libro    : Control = null
var _hoja_izq : VBoxContainer = null
var _hoja_der : VBoxContainer = null
var _num_lbl  : Label   = null
var _btn_ant  : Button  = null
var _btn_sig  : Button  = null


func _ready() -> void:
	layer = 15
	_crear_boton()
	_crear_libro()
	_libro.hide()
	_overlay.hide()


func esta_abierta() -> bool:
	return _libro.visible


func abrir() -> void:
	_mostrar_pagina(pagina, 0)
	_overlay.show()
	_libro.show()
	_libro.modulate.a = 0.0
	create_tween().tween_property(_libro, "modulate:a", 1.0, 0.15)


func cerrar() -> void:
	_libro.hide()
	_overlay.hide()


func alternar() -> void:
	if esta_abierta(): cerrar()
	else: abrir()


func pasar(delta: int) -> void:
	var nueva := clampi(pagina + delta, 0, PAGINAS.size() - 1)
	if nueva != pagina:
		_mostrar_pagina(nueva, delta)


# Los hijos reciben _input antes que SceneMapaMundo: con el libro abierto,
# Esc no abre la pausa ni las flechas mueven al personaje.
func _input(event: InputEvent) -> void:
	if not esta_abierta():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE, KEY_H: cerrar()
			KEY_LEFT, KEY_A: pasar(-1)
			KEY_RIGHT, KEY_D: pasar(1)
			_: pass
		get_viewport().set_input_as_handled()


# ── Construcción ─────────────────────────────────────────────
func _crear_boton() -> void:
	_boton = Button.new()
	_boton.text = "?"
	_boton.tooltip_text = "Guía del juego (H)"
	_boton.focus_mode = Control.FOCUS_NONE
	_boton.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_boton.offset_left = -58; _boton.offset_top = -58
	_boton.offset_right = -18; _boton.offset_bottom = -18
	_boton.add_theme_font_override("font", TEMA.rubik(700))
	_boton.add_theme_font_size_override("font_size", 20)
	_boton.add_theme_color_override("font_color", TEMA.DORADO)
	_boton.add_theme_stylebox_override("normal", TEMA.caja(TEMA.PANEL_BG, Color(TEMA.DORADO, 0.7), 2, 20))
	_boton.add_theme_stylebox_override("hover", TEMA.caja(Color(TEMA.DORADO, 0.25), TEMA.DORADO, 2, 20))
	_boton.add_theme_stylebox_override("pressed", TEMA.caja(Color(TEMA.DORADO, 0.35), TEMA.DORADO, 2, 20))
	_boton.pressed.connect(alternar)
	add_child(_boton)


func _crear_libro() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0.55)
	_overlay.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: cerrar())
	add_child(_overlay)

	_libro = Control.new()
	_libro.set_anchors_preset(Control.PRESET_CENTER)
	_libro.offset_left = -LIBRO.x / 2; _libro.offset_right = LIBRO.x / 2
	_libro.offset_top = -LIBRO.y / 2; _libro.offset_bottom = LIBRO.y / 2
	add_child(_libro)

	# Tapa: un borde de cuero alrededor de las dos hojas.
	var tapa := Panel.new()
	tapa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var st := TEMA.caja(Color("#3B2A1E"), Color("#1E140D"), 2, 14)
	st.shadow_color = Color(0, 0, 0, 0.5); st.shadow_size = 18
	tapa.add_theme_stylebox_override("panel", st)
	_libro.add_child(tapa)

	var ancho_hoja := (LIBRO.x - 36) / 2
	_hoja_izq = _hoja(Vector2(14, 14), Vector2(ancho_hoja, LIBRO.y - 74), true)
	_hoja_der = _hoja(Vector2(22 + ancho_hoja, 14), Vector2(ancho_hoja, LIBRO.y - 74), false)

	# Lomo
	var lomo := ColorRect.new()
	lomo.color = Color(0, 0, 0, 0.18)
	lomo.position = Vector2(14 + ancho_hoja - 2, 14)
	lomo.size = Vector2(12, LIBRO.y - 74)
	lomo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_libro.add_child(lomo)

	# Pie: anterior · página · siguiente, y cerrar.
	var pie := HBoxContainer.new()
	pie.position = Vector2(14, LIBRO.y - 52)
	pie.size = Vector2(LIBRO.x - 28, 40)
	pie.alignment = BoxContainer.ALIGNMENT_CENTER
	pie.add_theme_constant_override("separation", 18)
	_libro.add_child(pie)
	_btn_ant = _boton_pie("‹ Anterior", func(): pasar(-1))
	pie.add_child(_btn_ant)
	_num_lbl = TEMA.label("", 13, Color("#E9DCC0"), 500)
	_num_lbl.custom_minimum_size = Vector2(110, 0)
	_num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pie.add_child(_num_lbl)
	_btn_sig = _boton_pie("Siguiente ›", func(): pasar(1))
	pie.add_child(_btn_sig)

	var x := _boton_pie("Cerrar", cerrar)
	x.position = Vector2(LIBRO.x - 98, LIBRO.y - 48)
	_libro.add_child(x)


func _hoja(pos: Vector2, tam: Vector2, izquierda: bool) -> VBoxContainer:
	var hoja := Panel.new()
	hoja.position = pos
	hoja.size = tam
	var s := TEMA.caja(PAPEL if izquierda else PAPEL_2.lerp(PAPEL, 0.5), Color(0, 0, 0, 0), 0, 6)
	hoja.add_theme_stylebox_override("panel", s)
	_libro.add_child(hoja)
	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		mg.add_theme_constant_override("margin_" + lado, 26)
	hoja.add_child(mg)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	if izquierda:
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
	mg.add_child(vb)
	return vb


func _boton_pie(texto: String, accion: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(110, 32)
	b.add_theme_font_override("font", TEMA.rubik(600))
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", Color("#F4ECDA"))
	b.add_theme_color_override("font_disabled_color", Color("#F4ECDA", 0.3))
	b.add_theme_stylebox_override("normal", TEMA.caja(Color("#5A4030"), Color("#8A6A4A"), 1, 8))
	b.add_theme_stylebox_override("hover", TEMA.caja(Color("#6E4F3A"), Color("#C9A46E"), 1, 8))
	b.add_theme_stylebox_override("pressed", TEMA.caja(Color("#4A3426"), Color("#C9A46E"), 1, 8))
	b.add_theme_stylebox_override("disabled", TEMA.caja(Color("#4A3426", 0.5), Color("#8A6A4A", 0.3), 1, 8))
	b.pressed.connect(accion)
	return b


# ── Contenido ────────────────────────────────────────────────
func _mostrar_pagina(n: int, direccion: int) -> void:
	pagina = n
	var p : Array = PAGINAS[n]
	for vb in [_hoja_izq, _hoja_der]:
		for c in vb.get_children():
			vb.remove_child(c)
			c.free()

	var icono := TEMA.label(p[0], 54, TINTA)
	icono.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hoja_izq.add_child(icono)
	var titulo := _texto(p[1], 24, TINTA, 700)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hoja_izq.add_child(titulo)
	var sub := _texto(p[2], 14, TINTA_2, 400)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hoja_izq.add_child(sub)

	for parrafo in p[3]:
		_hoja_der.add_child(_texto(parrafo, 14, TINTA, 400))

	_num_lbl.text = "Página %d de %d" % [n + 1, PAGINAS.size()]
	_btn_ant.disabled = n == 0
	_btn_sig.disabled = n == PAGINAS.size() - 1

	# Pasar la hoja: el texto entra desde el lado hacia el que se avanza.
	if direccion != 0:
		for vb in [_hoja_izq, _hoja_der]:
			vb.modulate.a = 0.0
			vb.position.x = 18.0 * signf(direccion)
			var tw := create_tween().set_parallel()
			tw.tween_property(vb, "modulate:a", 1.0, 0.18)
			tw.tween_property(vb, "position:x", 0.0, 0.18).set_ease(Tween.EASE_OUT)


func _texto(t: String, tam: int, color: Color, peso: int) -> Label:
	var l := TEMA.label(t, tam, color, peso)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2((LIBRO.x - 36) / 2 - 52, 0)
	return l


# Para las pruebas: el texto de la página actual entra en sus hojas.
func pagina_cabe() -> bool:
	for vb in [_hoja_izq, _hoja_der]:
		var hoja : Control = vb.get_parent().get_parent()
		if vb.get_combined_minimum_size().y > hoja.size.y - 52 + 0.5:
			return false
	return true
