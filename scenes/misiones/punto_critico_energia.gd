# ============================================================
# punto_critico_energia.gd — NIVEL 2: Energía y Cambio Climático
# Punto interactivo en el mapa para misiones de energía.
# tipo "led"   → abre interior_bloque.gd (navegación WASD interior)
# tipo "solar" → abre mision_solar.gd (instalación de paneles)
# ============================================================
extends Area2D

# Los íconos se redibujan a ~12 Hz, no en cada cuadro (ver redibujo.gd).
const Redibujo := preload("res://scenes/mapa/redibujo.gd")

@export var mision_id     : String = "led_bloque_a"
@export var nombre_punto  : String = "Bloque A"
@export var tipo          : String = "led"    # "led" o "solar"
@export var num_spots     : int    = 3        # bombillos/paneles a instalar
@export var indice_bloque : int    = 0        # índice en BLOQUES (misiones LED)
@export var indice_mision : int    = 0        # índice en MISIONES_SOLAR (misiones solar)

signal energia_solicitada(punto: Area2D)

const AJUSTE := preload("res://scenes/ui/ui_ajuste.gd")
const RADIO_DETEC : float = 55.0

var _jugador_cerca : bool  = false
var _completado    : bool  = false
var _t             : float = 0.0

var _prompt_canvas : CanvasLayer = null
var _prompt_panel  : Panel       = null
var _prompt_lbl    : Label       = null
var _info_panel    : Panel       = null


# ── Inner class: icono visual en el mapa ─────────────────────
class EnergyIcon extends Node2D:
	var tipo        : String = "led"
	var completado  : bool   = false
	var _t          : float  = 0.0

	var _redibujo : float = randf() * Redibujo.CADA   # fase al azar: no todos en el mismo cuadro

	func _process(delta: float) -> void:
		_t += delta
		_redibujo -= delta
		if _redibujo <= 0.0:
			_redibujo = Redibujo.CADA
			queue_redraw()

	func _draw() -> void:
		if completado:
			_draw_completado()
			return
		if tipo == "led":
			_draw_led()
		else:
			_draw_solar()

	func _draw_led() -> void:
		# Halo pulsante naranja/amarillo
		var glow_a := 0.12 + 0.10 * sin(_t * 3.5)
		draw_circle(Vector2(0, 0), 28.0, Color(0.95, 0.55, 0.05, glow_a))
		draw_arc(Vector2(0, 0), 30.0, 0.0, TAU, 32,
				 Color(0.95, 0.55, 0.05, glow_a * 0.6), 2.0)
		# Sombra
		draw_arc(Vector2(0, 8), 14.0, 0.0, PI, 16, Color(0.0, 0.0, 0.0, 0.25), 10.0)
		# Bombillo incandescente (viejo, naranja oscuro)
		_draw_bulb(Color(0.80, 0.40, 0.05), Color(0.95, 0.55, 0.10))
		# Cruz indicando que hay que reemplazarlo
		var cr := 6.0
		draw_line(Vector2(-cr, -cr) + Vector2(0, 18), Vector2(cr, cr) + Vector2(0, 18),
				  Color(0.90, 0.20, 0.20, 0.80), 2.5)
		draw_line(Vector2( cr, -cr) + Vector2(0, 18), Vector2(-cr, cr) + Vector2(0, 18),
				  Color(0.90, 0.20, 0.20, 0.80), 2.5)
		# Texto "LED" pulsante
		var pulse := 0.6 + 0.4 * sin(_t * 2.5)
		draw_arc(Vector2(0, -20), 12.0 * pulse, 0.0, TAU, 20,
				 Color(0.95, 0.80, 0.10, 0.40 * pulse), 2.0)

	func _draw_solar() -> void:
		# Halo pulsante dorado/solar
		var glow_a := 0.10 + 0.10 * sin(_t * 2.8)
		draw_circle(Vector2(0, 0), 30.0, Color(0.98, 0.78, 0.05, glow_a))
		# Sombra
		draw_arc(Vector2(0, 10), 16.0, 0.0, PI, 16, Color(0.0, 0.0, 0.0, 0.22), 10.0)
		# Panel solar (rectángulo con grid)
		draw_rect(Rect2(-18, -20, 36, 22), Color(0.06, 0.10, 0.30))
		draw_rect(Rect2(-18, -20, 36, 22), Color(0.15, 0.40, 0.65), false, 2.0)
		# Grid del panel
		for xi in 3:
			draw_line(Vector2(-18 + xi * 12, -20), Vector2(-18 + xi * 12, 2),
					  Color(0.20, 0.50, 0.75, 0.55), 1.0)
		for yi in 2:
			draw_line(Vector2(-18, -20 + yi * 11), Vector2(18, -20 + yi * 11),
					  Color(0.20, 0.50, 0.75, 0.55), 1.0)
		# Brillo de luz solar
		var sa := _t * 1.5
		for i in 6:
			var a := sa + float(i) / 6.0 * TAU
			draw_line(Vector2(cos(a) * 22, sin(a) * 22 - 8),
					  Vector2(cos(a) * 30, sin(a) * 30 - 8),
					  Color(0.98, 0.85, 0.15, 0.55), 1.5)
		# Soporte
		draw_rect(Rect2(-3, 2, 6, 12), Color(0.45, 0.45, 0.45))
		draw_rect(Rect2(-12, 12, 24, 4), Color(0.40, 0.40, 0.40))

	func _draw_completado() -> void:
		# Sombra base
		draw_arc(Vector2(0, 8), 14.0, 0.0, PI, 16, Color(0.0, 0.0, 0.0, 0.22), 10.0)
		if tipo == "led":
			# Halo suave azul-blanco (LED encendido)
			var ga := 0.06 + 0.04 * sin(_t * 1.8)
			draw_circle(Vector2(0, 0), 26.0, Color(0.60, 0.85, 1.0, ga))
			# Bombillo LED instalado (blanco-azulado, sin filamento ni cruz)
			draw_circle(Vector2(0, -8), 12.0, Color(0.88, 0.95, 1.0))
			draw_arc(Vector2(0, -8), 12.0, 0.0, TAU, 20,
					 Color(0.70, 0.90, 1.0), 1.5)
			draw_rect(Rect2(-6, 4, 12, 8), Color(0.65, 0.75, 0.88))
			draw_rect(Rect2(-6, 12, 12, 3), Color(0.55, 0.50, 0.45))
			draw_circle(Vector2(-3, -12), 3.5, Color(1.0, 1.0, 1.0, 0.70))
			# Destellos giratorios de luz LED
			var sa := _t * 2.0
			for i in 4:
				var a := sa + float(i) / 4.0 * TAU
				draw_line(Vector2(cos(a) * 16, sin(a) * 16 - 8),
						  Vector2(cos(a) * 22, sin(a) * 22 - 8),
						  Color(0.80, 0.95, 1.0, 0.70), 1.5)
		else:
			# Halo suave dorado (panel solar funcionando)
			var ga := 0.06 + 0.04 * sin(_t * 1.5)
			draw_circle(Vector2(0, 0), 30.0, Color(0.98, 0.78, 0.05, ga))
			# Panel solar instalado
			draw_rect(Rect2(-18, -20, 36, 22), Color(0.06, 0.10, 0.30))
			draw_rect(Rect2(-18, -20, 36, 22), Color(0.15, 0.40, 0.65), false, 2.0)
			for xi in 3:
				draw_line(Vector2(-18 + xi * 12, -20), Vector2(-18 + xi * 12, 2),
						  Color(0.20, 0.50, 0.75, 0.55), 1.0)
			for yi in 2:
				draw_line(Vector2(-18, -20 + yi * 11), Vector2(18, -20 + yi * 11),
						  Color(0.20, 0.50, 0.75, 0.55), 1.0)
			draw_rect(Rect2(-3, 2, 6, 12), Color(0.45, 0.45, 0.45))
			draw_rect(Rect2(-12, 12, 24, 4), Color(0.40, 0.40, 0.40))
			# Rayos solares (giro lento)
			var sa := _t * 0.5
			for i in 6:
				var a := sa + float(i) / 6.0 * TAU
				draw_line(Vector2(cos(a) * 22, sin(a) * 22 - 8),
						  Vector2(cos(a) * 28, sin(a) * 28 - 8),
						  Color(0.98, 0.85, 0.15, 0.55), 1.5)

	func _draw_bulb(color_base: Color, color_glow: Color) -> void:
		# Bombillo: parte redonda
		draw_circle(Vector2(0, -8), 12.0, color_base)
		draw_arc(Vector2(0, -8), 12.0, 0.0, TAU, 20,
				 color_glow.lightened(0.2), 1.5)
		# Parte inferior del bombillo (casquillo)
		draw_rect(Rect2(-6, 4, 12, 8), color_base.darkened(0.3))
		draw_rect(Rect2(-6, 12, 12, 3), Color(0.55, 0.50, 0.45))
		# Brillo del bombillo
		draw_circle(Vector2(-3, -12), 3.5, Color(1.0, 0.95, 0.70, 0.50))
		# Filamento (solo en el incandescente)
		if color_base.r > 0.5:
			draw_arc(Vector2(0, -8), 4.0, PI * 0.3, PI * 2.7, 10,
					 Color(0.95, 0.80, 0.30, 0.80), 1.2)


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _ready() -> void:
	add_to_group("punto_energia")
	_crear_collision()
	_crear_visual()
	_crear_prompt()
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	var nm = _nivel_mgr()
	if nm and nm.mision_completada_q(2, mision_id):
		_marcar_completado()


func _crear_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = RADIO_DETEC
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _crear_visual() -> void:
	var icon := EnergyIcon.new()
	icon.tipo  = tipo
	icon.z_index = 1
	add_child(icon)
	set_meta("energy_icon", icon)


func _crear_prompt() -> void:
	_prompt_canvas = CanvasLayer.new()
	_prompt_canvas.layer = 12
	add_child(_prompt_canvas)

	_prompt_panel = Panel.new()
	_prompt_panel.custom_minimum_size = Vector2(280, 42)
	_prompt_panel.visible = false
	_prompt_canvas.add_child(_prompt_panel)

	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.06, 0.06, 0.14, 0.93)
	ps.border_color = Color(0.95, 0.65, 0.10)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	ps.shadow_color = Color(0.50, 0.30, 0.05, 0.40)
	ps.shadow_size  = 8
	_prompt_panel.add_theme_stylebox_override("panel", ps)

	_prompt_lbl = Label.new()
	_prompt_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_prompt_lbl.add_theme_font_size_override("font_size", 13)
	_prompt_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.70))
	_prompt_panel.add_child(_prompt_lbl)

	# ── Panel de información (post-instalación) ──────────────
	_info_panel = Panel.new()
	_info_panel.custom_minimum_size = Vector2(370, 295)
	_info_panel.set_anchors_preset(Control.PRESET_CENTER)
	_info_panel.offset_left   = -185.0
	_info_panel.offset_top    = -148.0
	_info_panel.offset_right  =  185.0
	_info_panel.offset_bottom =  148.0
	_info_panel.visible = false
	var ip_col := Color(0.95, 0.62, 0.10) if tipo == "led" else Color(0.95, 0.78, 0.05)
	var ips := StyleBoxFlat.new()
	ips.bg_color     = Color(0.04, 0.07, 0.14, 0.98)
	ips.border_color = ip_col
	ips.set_border_width_all(3)
	ips.set_corner_radius_all(16)
	ips.shadow_color = Color(ip_col.r * 0.5, ip_col.g * 0.3, 0.05, 0.55)
	ips.shadow_size  = 22
	_info_panel.add_theme_stylebox_override("panel", ips)
	_prompt_canvas.add_child(_info_panel)

	var img := MarginContainer.new()
	img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		img.add_theme_constant_override(k, 18)
	_info_panel.add_child(img)

	var ivbox := VBoxContainer.new()
	ivbox.add_theme_constant_override("separation", 9)
	img.add_child(ivbox)

	# Título
	var tit_lbl := Label.new()
	var tit_str := ("💡 LED Instalado — %s" % nombre_punto) if tipo == "led" \
				 else ("☀️ Panel Solar Instalado — %s" % nombre_punto)
	tit_lbl.text = tit_str
	tit_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit_lbl.add_theme_font_size_override("font_size", 15)
	tit_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.50))
	ivbox.add_child(tit_lbl)

	var sep := HSeparator.new()
	ivbox.add_child(sep)

	# Beneficios
	var ben_lbl := Label.new()
	ben_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	ben_lbl.add_theme_font_size_override("font_size", 13)
	ben_lbl.add_theme_color_override("font_color", Color(0.82, 0.88, 0.84))
	if tipo == "led":
		ben_lbl.text = (
			"⚡ Ahorro energético: ~88% del consumo anterior\n" +
			"🌍 CO₂ reducido: ~0.8 t/año por bloque\n" +
			"📊 Vida útil: 50,000 h  vs  1,000 h incandescente\n" +
			"🔁 Sensor de movimiento: apagado automático\n" +
			"💰 Ahorro estimado: ~$95 USD/año por bloque"
		)
	else:
		ben_lbl.text = (
			"⚡ Generación estimada: 450 kWh/año\n" +
			"🌍 CO₂ evitado: ~0.3 t/año\n" +
			"📊 Vida útil garantizada: 25 años\n" +
			"💰 Ahorro: ~$180 USD anuales en electricidad\n" +
			"☀️ Producción pico: 1.2 kW en horas solares"
		)
	ivbox.add_child(ben_lbl)

	# GreenMetric
	var gm_lbl := Label.new()
	gm_lbl.text = "📈 Contribuye al módulo M2: Energía y Cambio Climático"
	gm_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	gm_lbl.add_theme_font_size_override("font_size", 12)
	gm_lbl.add_theme_color_override("font_color", ip_col)
	ivbox.add_child(gm_lbl)

	# Botón cerrar
	var btn_ok := Button.new()
	btn_ok.text = "  Cerrar  ✕  "
	btn_ok.custom_minimum_size = Vector2(130, 38)
	btn_ok.add_theme_font_size_override("font_size", 13)
	var bks := StyleBoxFlat.new()
	bks.bg_color     = Color(0.08, 0.16, 0.26)
	bks.border_color = Color(0.38, 0.55, 0.75)
	bks.set_border_width_all(2)
	bks.set_corner_radius_all(9)
	btn_ok.add_theme_stylebox_override("normal", bks)
	btn_ok.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_ok.pressed.connect(func(): _info_panel.visible = false)
	ivbox.add_child(btn_ok)


func _process(_delta: float) -> void:
	if not _prompt_panel.visible: return
	var cam := get_viewport().get_camera_2d()
	if not cam: return
	var vp_size   := get_viewport().get_visible_rect().size
	var cam_zoom  := cam.zoom
	var cam_offset := cam.global_position - vp_size * 0.5 / cam_zoom
	var screen_pos := (global_position + Vector2(-105, -80) - cam_offset) * cam_zoom
	_prompt_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	AJUSTE.colocar_aviso(_prompt_panel, _prompt_lbl, screen_pos)


func _al_entrar(body: Node) -> void:
	if not body.is_in_group("jugador"): return
	_jugador_cerca = true
	var texto : String
	if _completado:
		texto = "✅ [E]  Ver instalación — %s" % nombre_punto
	elif tipo == "led":
		texto = "⚡ [E]  Misión LED — %s" % nombre_punto
	else:
		texto = "☀️ [E]  Instalar Paneles — %s" % nombre_punto
	_prompt_lbl.text         = texto
	_prompt_panel.modulate.a = 0.0
	_prompt_panel.visible    = true
	var tw := create_tween()
	tw.tween_property(_prompt_panel, "modulate:a", 1.0, 0.20)


func _al_salir(body: Node) -> void:
	if not body.is_in_group("jugador"): return
	_jugador_cerca = false
	if is_instance_valid(_info_panel):
		_info_panel.visible = false
	var tw := create_tween()
	tw.tween_property(_prompt_panel, "modulate:a", 0.0, 0.16)
	tw.tween_callback(func(): _prompt_panel.visible = false)


func intentar_interactuar() -> void:
	if not _jugador_cerca: return
	_prompt_panel.visible = false
	if _completado:
		_mostrar_info_completada()
		return
	energia_solicitada.emit(self)


func _mostrar_info_completada() -> void:
	if not is_instance_valid(_info_panel): return
	_info_panel.modulate.a = 0.0
	_info_panel.visible    = true
	var tw := create_tween()
	tw.tween_property(_info_panel, "modulate:a", 1.0, 0.22)


func _marcar_completado() -> void:
	_completado = true
	if has_meta("energy_icon"):
		var icon := get_meta("energy_icon") as EnergyIcon
		icon.completado = true
		icon.modulate.a = 0.5   # atenuado: ya no compite visualmente con lo pendiente
	_prompt_panel.visible = false
