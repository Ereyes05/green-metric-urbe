# ============================================================
# guia_libro.gd — guía rápida dentro del juego: la bitácora de campo del
# Eco-Ranger. Botón "?" en la esquina inferior derecha (o tecla H, ver
# SceneMapaMundo._input). Es un resumen del manual de usuarios
# (docs/manual_usuarios.md): si cambia una regla del juego, cambiar las dos.
#
# Libreta de tapa de cuero con hojas cuadriculadas. Cada capítulo lleva el
# color de su tema (los del HUD) y una pestaña en el borde para saltar a él.
# Pasar de página voltea la hoja sobre el lomo.
#
# Solo usa emoji que están en NotoColorEmoji-subset.ttf (test_emojis.gd).
# ============================================================
extends CanvasLayer

const TEMA := preload("res://scenes/ui/hud_tema.gd")

const LIBRO   := Vector2(880, 520)
const MARGEN  := 18.0     # tapa alrededor de las hojas
const LOMO    := 10.0     # separación entre hojas
const PIE     := 56.0     # botones debajo de las hojas
const PAD     := 34.0     # margen interior de cada hoja
const TAPA    := Color("#2E4A36")
const TAPA_OSC := Color("#1B2D21")
const COSTURA := Color("#C9B98A")
const PAPEL   := Color("#EFE8D3")
const CUADRO  := Color("#DCD3B8")
const TINTA   := Color("#2B2A24")
const TINTA_2 := Color("#6A6253")
const VUELTA  := 0.16     # segundos de cada mitad del giro de la hoja

# [icono, título, subtítulo, color del capítulo, [párrafos]]
const PAGINAS : Array = [
	["📖", "Bitácora del Eco-Ranger", "Lo esencial para jugar", TEMA.VERDE, [
		"Este juego te enseña los seis criterios con los que el ranking UI GreenMetric evalúa qué tan sostenible es una universidad.",
		"Recorres el campus de la URBE, hablas con los responsables de cada área, haces misiones y ves cómo tus decisiones mueven el puntaje del campus.",
		"Pasa las hojas con las flechas del teclado o con las pestañas del borde. Cierra con Esc o con la tecla H.",
	]],
	["🕹", "Controles", "Teclado y ratón", TEMA.CIAN, [
		"W A S D o las flechas: mover al Eco-Ranger.",
		"E: hablar con un personaje, entrar a un edificio o empezar una misión. Si hay dos cosas cerca, gana la más cercana.",
		"1 a 5: abrir Avance, Reporte, Ranking, Simular y Tienda.",
		"H: abrir esta bitácora.   Esc: menú de pausa.",
	]],
	["📊", "Tu pantalla", "Qué muestra cada parte", TEMA.CIAN, [
		"Arriba a la izquierda: tu nivel, tu rango y tus EcoCredits.",
		"Arriba a la derecha: el puntaje GreenMetric del campus, de 0 a 100, y una barra por cada criterio. Pasa el cursor por una fila para ver el desglose.",
		"Abajo: los cinco botones de acción. Avance te dice cuántas misiones llevas en cada nivel.",
	]],
	["💬", "Los personajes", "Aprender de cada área", TEMA.VIOLETA, [
		"Cada personaje explica un criterio de GreenMetric y después te hace un cuestionario: 15 segundos por pregunta.",
		"Atienden desde su nivel. Los que se ven apagados todavía no: al pulsar E te dicen desde qué nivel están disponibles.",
		"Cada cuestionario se responde una sola vez. Después puedes volver a escuchar la explicación para repasar.",
	]],
	["🔧", "Misiones", "Actuar en el campus", TEMA.NARANJA, [
		"Las misiones de campo están en los puntos marcados del mapa: plantar, cambiar a LED, reciclar, cerrar llaves, montar bicicleteros.",
		"Algunas necesitan una herramienta de la tienda. Si te falta, el juego te lo dice.",
		"En las decisiones eliges entre opciones con costo distinto. En las crisis tienes 10 segundos para responder.",
	]],
	["📋", "Test de cierre y correo", "Al terminar cada nivel", TEMA.TEAL, [
		"Cuando completas un nivel aparece un test corto, de hasta cinco preguntas, para que compruebes qué te quedó. No da puntos: solo se guarda tu primer intento.",
		"Con los seis tests hechos aparece el test final, con dos preguntas de cada nivel.",
		"Después de cada test te llega un correo con tu avance. Si no lo ves, revisa spam y promociones.",
	]],
	["🏆", "El puntaje GreenMetric", "Cómo se suma", TEMA.DORADO, [
		"Cada criterio vale de 0 a 100: misiones 80, cuestionario 10, decisiones 5 y sinergias 5. Actuar es lo que más pesa.",
		"Las sinergias aparecen cuando una acción de un criterio también mejora otro, como los paneles solares, que además bajan la huella de carbono.",
		"El botón Reporte (tecla 2) muestra el detalle.",
	]],
	["🛒", "EcoCredits y tienda", "La moneda del juego", TEMA.DORADO, [
		"Ganas EcoCredits al registrarte y con cada misión. No caducan y no se compran con dinero.",
		"Herramientas obligatorias: kit solar (100), kit pluvial (60) y kit de bicicletero (60). Cómpralas antes que lo opcional.",
		"Si una compra opcional te dejaría sin saldo para una herramienta, la tienda te avisa antes de cobrar.",
	]],
	["⭐", "Rangos e insignias", "Tu reconocimiento", TEMA.VERDE, [
		"Tu rango sube con cada nivel completado: Semilla, Brote, Árbol, Estratega, Investigador y EcoLíder.",
		"Las insignias se ganan solas al cumplir un logro: completar un nivel, un cuestionario perfecto, resolver una crisis.",
		"La lista de las que tienes llega en el correo de avance.",
	]],
	["💡", "Si algo no funciona", "Antes de pedir ayuda", TEMA.ALERTA, [
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
var _pestanas : Array   = []
var _animando : bool    = false


# Hoja cuadriculada, como una libreta de campo.
class Papel extends Panel:
	func _draw() -> void:
		var paso := 22.0
		var y := paso
		while y < size.y:
			draw_line(Vector2(0, y), Vector2(size.x, y), CUADRO, 1.0)
			y += paso
		var x := paso
		while x < size.x:
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(CUADRO, 0.45), 1.0)
			x += paso


# Tapa de cuero con costura.
class Tapa extends Panel:
	func _draw() -> void:
		var r := Rect2(Vector2(7, 7), size - Vector2(14, 14))
		var tramo := 9.0
		var p := r.position.x
		while p < r.end.x:
			draw_line(Vector2(p, r.position.y), Vector2(minf(p + 5, r.end.x), r.position.y), COSTURA, 1.5)
			draw_line(Vector2(p, r.end.y), Vector2(minf(p + 5, r.end.x), r.end.y), COSTURA, 1.5)
			p += tramo
		p = r.position.y
		while p < r.end.y:
			draw_line(Vector2(r.position.x, p), Vector2(r.position.x, minf(p + 5, r.end.y)), COSTURA, 1.5)
			draw_line(Vector2(r.end.x, p), Vector2(r.end.x, minf(p + 5, r.end.y)), COSTURA, 1.5)
			p += tramo


func _ready() -> void:
	layer = 15
	_crear_boton()
	_crear_libro()
	_libro.hide()
	_overlay.hide()


func esta_abierta() -> bool:
	return _libro.visible


func abrir() -> void:
	_llenar(_hoja_izq, pagina, true)
	_llenar(_hoja_der, pagina, false)
	_actualizar_pie()
	_overlay.show()
	_libro.show()
	_libro.modulate.a = 0.0
	_libro.scale = Vector2(0.96, 0.96)
	var tw := create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(_libro, "modulate:a", 1.0, 0.18)
	tw.tween_property(_libro, "scale", Vector2.ONE, 0.22)


func cerrar() -> void:
	_libro.hide()
	_overlay.hide()


func alternar() -> void:
	if esta_abierta(): cerrar()
	else: abrir()


func pasar(delta: int) -> void:
	ir_a(clampi(pagina + delta, 0, PAGINAS.size() - 1))


func ir_a(n: int) -> void:
	if n == pagina or _animando:
		return
	_mostrar_pagina(n, signi(n - pagina))


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
	_boton.tooltip_text = "Bitácora del Eco-Ranger (H)"
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


func _ancho_hoja() -> float:
	return (LIBRO.x - 2 * MARGEN - LOMO) / 2.0


func _alto_hoja() -> float:
	return LIBRO.y - 2 * MARGEN - PIE


func _crear_libro() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0.6)
	_overlay.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed: cerrar())
	add_child(_overlay)

	_libro = Control.new()
	_libro.set_anchors_preset(Control.PRESET_CENTER)
	_libro.offset_left = -LIBRO.x / 2; _libro.offset_right = LIBRO.x / 2
	_libro.offset_top = -LIBRO.y / 2; _libro.offset_bottom = LIBRO.y / 2
	_libro.pivot_offset = LIBRO / 2
	add_child(_libro)

	# Pestañas primero: quedan detrás de la tapa y asoman por el borde.
	for i in PAGINAS.size():
		_pestanas.append(_crear_pestana(i))

	var tapa := Tapa.new()
	tapa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var st := TEMA.caja(TAPA, TAPA_OSC, 3, 16)
	st.shadow_color = Color(0, 0, 0, 0.55); st.shadow_size = 22; st.shadow_offset = Vector2(0, 6)
	tapa.add_theme_stylebox_override("panel", st)
	_libro.add_child(tapa)

	var ancho := _ancho_hoja()
	_hoja_izq = _hoja(Vector2(MARGEN, MARGEN), true)
	_hoja_der = _hoja(Vector2(MARGEN + ancho + LOMO, MARGEN), false)

	# Lomo: sombra del pliegue entre las dos hojas.
	var lomo := ColorRect.new()
	lomo.color = Color(0, 0, 0, 0.28)
	lomo.position = Vector2(MARGEN + ancho - 3, MARGEN)
	lomo.size = Vector2(LOMO + 6, _alto_hoja())
	lomo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_libro.add_child(lomo)

	# Pie: anterior · página · siguiente, y cerrar.
	var pie := HBoxContainer.new()
	pie.position = Vector2(MARGEN, LIBRO.y - PIE + 4)
	pie.size = Vector2(LIBRO.x - 2 * MARGEN, PIE - 18)
	pie.alignment = BoxContainer.ALIGNMENT_CENTER
	pie.add_theme_constant_override("separation", 20)
	_libro.add_child(pie)
	_btn_ant = _boton_pie("‹ Anterior", func(): pasar(-1))
	pie.add_child(_btn_ant)
	_num_lbl = TEMA.label("", 13, COSTURA, 500)
	_num_lbl.custom_minimum_size = Vector2(120, 0)
	_num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pie.add_child(_num_lbl)
	_btn_sig = _boton_pie("Siguiente ›", func(): pasar(1))
	pie.add_child(_btn_sig)

	var x := _boton_pie("Cerrar", cerrar)
	x.position = Vector2(LIBRO.x - MARGEN - 104, LIBRO.y - PIE + 6)
	_libro.add_child(x)


func _crear_pestana(i: int) -> Button:
	var col : Color = PAGINAS[i][3]
	var b := Button.new()
	b.text = PAGINAS[i][0]
	b.tooltip_text = PAGINAS[i][1]
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", TEMA.rubik(400))
	b.add_theme_font_size_override("font_size", 15)
	var alto := (_alto_hoja() - 8) / PAGINAS.size()
	# Asoma 34 px por fuera de la tapa; el ícono va en esa parte visible.
	b.size = Vector2(52, alto - 4)
	b.position = Vector2(LIBRO.x - 18, MARGEN + 4 + i * alto)
	var s := TEMA.caja(col.darkened(0.15), col.darkened(0.45), 1, 6)
	s.corner_radius_top_left = 0; s.corner_radius_bottom_left = 0
	s.content_margin_left = 20
	b.add_theme_stylebox_override("normal", s)
	b.add_theme_stylebox_override("hover", s)
	b.add_theme_stylebox_override("pressed", s)
	b.pressed.connect(func(): ir_a(i))
	_libro.add_child(b)
	return b


func _hoja(pos: Vector2, izquierda: bool) -> VBoxContainer:
	var hoja := _papel(pos, izquierda)
	_libro.add_child(hoja)
	return hoja.get_child(0).get_child(0)


# Hoja con su margen y su VBox. También se usa para la hoja que se voltea.
func _papel(pos: Vector2, izquierda: bool) -> Panel:
	var hoja := Papel.new()
	hoja.position = pos
	hoja.size = Vector2(_ancho_hoja(), _alto_hoja())
	hoja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := TEMA.caja(PAPEL, Color(0, 0, 0, 0), 0, 4)
	if izquierda:
		s.corner_radius_top_right = 0; s.corner_radius_bottom_right = 0
	else:
		s.corner_radius_top_left = 0; s.corner_radius_bottom_left = 0
	hoja.add_theme_stylebox_override("panel", s)
	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for lado in ["left", "right", "top", "bottom"]:
		mg.add_theme_constant_override("margin_" + lado, int(PAD))
	hoja.add_child(mg)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER if izquierda else BoxContainer.ALIGNMENT_BEGIN
	mg.add_child(vb)
	return hoja


func _boton_pie(texto: String, accion: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(112, 34)
	b.add_theme_font_override("font", TEMA.rubik(600))
	b.add_theme_font_size_override("font_size", 13)
	b.add_theme_color_override("font_color", PAPEL)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(PAPEL, 0.3))
	b.add_theme_stylebox_override("normal", TEMA.caja(TAPA_OSC, Color(COSTURA, 0.5), 1, 8))
	b.add_theme_stylebox_override("hover", TEMA.caja(TAPA.darkened(0.2), COSTURA, 1, 8))
	b.add_theme_stylebox_override("pressed", TEMA.caja(TAPA_OSC.darkened(0.3), COSTURA, 1, 8))
	b.add_theme_stylebox_override("disabled", TEMA.caja(Color(TAPA_OSC, 0.5), Color(COSTURA, 0.15), 1, 8))
	b.pressed.connect(accion)
	return b


# ── Contenido ────────────────────────────────────────────────
func _llenar(vb: VBoxContainer, n: int, izquierda: bool) -> void:
	for c in vb.get_children():
		vb.remove_child(c)
		c.free()
	var p : Array = PAGINAS[n]
	var col : Color = p[3]
	if izquierda:
		var cap := TEMA.label("Capítulo %d" % (n + 1), 10, col.darkened(0.35), 400, true)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(cap)
		vb.add_child(_sello(p[0], col))
		var titulo := _texto(p[1], 26, TINTA, 700)
		titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(titulo)
		var raya := ColorRect.new()
		raya.color = col
		raya.custom_minimum_size = Vector2(56, 3)
		raya.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vb.add_child(raya)
		var sub := _texto(p[2], 15, TINTA_2, 400)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(sub)
	else:
		for parrafo in p[4]:
			vb.add_child(_texto(parrafo, 15, TINTA, 400))


# Ícono del capítulo dentro de un sello circular de su color.
func _sello(icono: String, col: Color) -> Control:
	var c := CenterContainer.new()
	var circulo := Panel.new()
	circulo.custom_minimum_size = Vector2(96, 96)
	var s := TEMA.caja(Color(col, 0.16), col.darkened(0.2), 3, 48)
	circulo.add_theme_stylebox_override("panel", s)
	c.add_child(circulo)
	var l := TEMA.label(icono, 44, TINTA)
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	circulo.add_child(l)
	return c


func _texto(t: String, tam: int, color: Color, peso: int) -> Label:
	var l := TEMA.label(t, tam, color, peso)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(_ancho_hoja() - 2 * PAD, 0)
	l.add_theme_constant_override("line_spacing", 4)
	return l


func _actualizar_pie() -> void:
	_num_lbl.text = "Página %d de %d" % [pagina + 1, PAGINAS.size()]
	_btn_ant.disabled = pagina == 0
	_btn_sig.disabled = pagina == PAGINAS.size() - 1
	for i in _pestanas.size():
		var b : Button = _pestanas[i]
		var activa := i == pagina
		b.position.x = LIBRO.x - (8.0 if activa else 18.0)
		b.modulate = Color.WHITE if activa else Color(0.8, 0.8, 0.8)


# Voltear la hoja sobre el lomo. Hacia adelante: la hoja derecha se dobla
# hacia el lomo (debajo ya está la página nueva) y su reverso se abre sobre
# la izquierda con el capítulo nuevo. Hacia atrás, al revés.
func _mostrar_pagina(n: int, direccion: int) -> void:
	var vieja := pagina
	pagina = n
	_actualizar_pie()
	if direccion == 0 or not esta_abierta():
		_llenar(_hoja_izq, n, true)
		_llenar(_hoja_der, n, false)
		return
	_animando = true
	var ancho := _ancho_hoja()
	var x_izq := MARGEN
	var x_der := MARGEN + ancho + LOMO
	var adelante := direccion > 0

	# Primera mitad: la hoja que se va se pliega hacia el lomo.
	var va := _papel(Vector2(x_der if adelante else x_izq, MARGEN), not adelante)
	_llenar(va.get_child(0).get_child(0), vieja, not adelante)
	va.pivot_offset = Vector2(0.0 if adelante else ancho, 0.0)
	_libro.add_child(va)
	# Debajo ya se ve la página nueva de ese lado.
	if adelante: _llenar(_hoja_der, n, false)
	else: _llenar(_hoja_izq, n, true)

	var tw := create_tween()
	tw.tween_property(va, "scale:x", 0.0, VUELTA).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(va, "modulate", Color(0.7, 0.7, 0.7), VUELTA)
	tw.tween_callback(func():
		va.queue_free()
		# Segunda mitad: el reverso se abre del otro lado con la página nueva.
		var viene := _papel(Vector2(x_izq if adelante else x_der, MARGEN), adelante)
		_llenar(viene.get_child(0).get_child(0), n, adelante)
		viene.pivot_offset = Vector2(ancho if adelante else 0.0, 0.0)
		viene.scale.x = 0.0
		viene.modulate = Color(0.7, 0.7, 0.7)
		_libro.add_child(viene)
		var tw2 := create_tween()
		tw2.tween_property(viene, "scale:x", 1.0, VUELTA).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
		tw2.parallel().tween_property(viene, "modulate", Color.WHITE, VUELTA)
		tw2.tween_callback(func():
			if adelante: _llenar(_hoja_izq, n, true)
			else: _llenar(_hoja_der, n, false)
			viene.queue_free()
			_animando = false))


# Para las pruebas: el texto de la página actual entra en sus hojas.
func pagina_cabe() -> bool:
	for vb in [_hoja_izq, _hoja_der]:
		if vb.get_combined_minimum_size().y > _alto_hoja() - 2 * PAD + 0.5:
			return false
	return true
