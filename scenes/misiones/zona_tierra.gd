# ============================================================
# zona_tierra.gd — NIVEL 1 Infraestructura y Entorno
# Zona de tierra en áreas verdes del campus.
# El jugador se acerca y presiona E para iniciar la misión
# de plantación correspondiente.
# ============================================================
extends Area2D

@export var mision_id        : String = "plantar_1"
@export var nombre_zona      : String = "Jardín Norte"
@export var indice_mision    : int    = 0
@export var modo_interaccion : String = "click"   # "click" o "drag"

signal plantar_solicitado(zona: Area2D)
signal riego_realizado(zona: Area2D, xp: int, ec: int)

const RADIO_TIERRA  : float = 34.0   # en espacio del padre (no inner class)
const RADIO_DETEC   : float = 60.0

var _jugador_cerca  : bool  = false
var _completada     : bool  = false
var _t              : float = 0.0

var _prompt_canvas  : CanvasLayer = null
var _prompt_panel   : Panel       = null
var _prompt_lbl     : Label       = null

var _planta_visual  : Node2D  = null
var _info_panel     : Panel   = null

# ── Sistema de riego ─────────────────────────────────────────
const WATERING_INTERVAL : float = 600.0   # 10 min (riego cada 10 min)
var _necesita_riego : bool  = false
var _riego_timer    : float = 0.0
var _agua_node      : Node2D = null        # indicador visual de gota
var _eco_badge      : Node2D = null        # badge flotante de impacto ambiental


# Piezas del hoyo que late, dibujadas una sola vez. TierraVisual las anima
# con scale (el latido) y modulate.a (el brillo del aro).
class HoyoTierra extends Node2D:
	func _draw() -> void:
		draw_circle(Vector2.ZERO, 7.0, Color(0.20, 0.11, 0.04))

class AroTierra extends Node2D:
	func _draw() -> void:
		draw_arc(Vector2.ZERO, 7.5, 0.0, TAU, 16, Color(0.55, 0.88, 0.25, 1.0), 1.5)


class TierraVisual extends Node2D:
	const RADIO_TIERRA = 34.0
	var completada  : bool   = false:
		set(v):
			completada = v
			_actualizar_hoyo()
			queue_redraw()
	var tipo_planta : String = ""
	var _t          : float  = 0.0
	# 0=recién plantado → 1=árbol adulto. Lo anima un tween con
	# tween_property, que pasa por este setter: redibuja solo mientras crece.
	var _growth_t   : float  = 1.0:
		set(v):
			_growth_t = v
			queue_redraw()
	var _riego_t    : float  = -1.0  # ≥0 → animación de agua activa
	var _hoyo       : Node2D = null
	var _aro        : Node2D = null

	# Rendimiento (medido 2026-09-14): antes se redibujaba TODO en cada frame
	# — un polígono de 28 puntos con senos y cosenos, un generador de números
	# aleatorios nuevo para 14 motas que siempre quedan en el mismo lugar, dos
	# arcos — cuando lo único animado era el hoyo que late. Las 6 zonas eran
	# ~26% del tiempo de frame.
	#
	# Ahora el parche se dibuja una vez; el hoyo que late son dos nodos hijos
	# animados con scale/modulate (no redibujan); y el nodo solo se redibuja
	# cuando cambia de estado o mientras dura el crecimiento o el riego.
	func _ready() -> void:
		_hoyo = HoyoTierra.new()
		add_child(_hoyo)
		_aro = AroTierra.new()
		add_child(_aro)
		_actualizar_hoyo()

	func _actualizar_hoyo() -> void:
		if _hoyo: _hoyo.visible = not completada
		if _aro:  _aro.visible  = not completada

	func _process(delta: float) -> void:
		_t += delta
		if not completada and _hoyo:
			var puls := 1.0 + 0.12 * sin(_t * 3.0)
			_hoyo.scale = Vector2(puls, puls)
			_aro.scale  = Vector2(puls, puls)
			_aro.modulate.a = 0.6 + 0.3 * sin(_t * 2.5)
		if _riego_t >= 0.0:
			_riego_t += delta
			if _riego_t > 1.0:
				_riego_t = -1.0
			queue_redraw()   # también el frame en que termina, para borrar los aros

	func _draw() -> void:
		if completada:
			_draw_completada()
		else:
			_draw_tierra()

	func disparar_riego() -> void:
		_riego_t = 0.0

	func _draw_tierra() -> void:
		# Sombra
		draw_arc(Vector2(0, 6), RADIO_TIERRA * 1.1, 0.0, PI, 20,
				 Color(0.0, 0.0, 0.0, 0.18), 8.0)
		# Parche de tierra (elipse marrón)
		var puntos := PackedVector2Array()
		for i in 28:
			var a := float(i) / 28.0 * TAU
			puntos.append(Vector2(cos(a) * RADIO_TIERRA, sin(a) * RADIO_TIERRA * 0.55))
		draw_colored_polygon(puntos, Color(0.38, 0.24, 0.10))
		# Borde grass
		draw_arc(Vector2(0, 0), RADIO_TIERRA, 0.0, TAU, 28,
				 Color(0.22, 0.55, 0.14, 0.7), 4.0)
		# Textura de tierra (motas)
		var rng := RandomNumberGenerator.new()
		rng.seed = 42
		for _i in 14:
			var px := rng.randf_range(-RADIO_TIERRA * 0.7, RADIO_TIERRA * 0.7)
			var py := rng.randf_range(-RADIO_TIERRA * 0.28, RADIO_TIERRA * 0.25)
			draw_circle(Vector2(px, py), rng.randf_range(1.5, 3.5),
						Color(0.28, 0.16, 0.06, 0.55))
		# (El hoyo central que late lo dibujan HoyoTierra/AroTierra, hijos de
		# este nodo, animados sin redibujar.)

	func _draw_completada() -> void:
		var sc := clampf(_growth_t, 0.001, 1.0)
		# Escala desde el suelo: el árbol crece hacia arriba
		draw_set_transform(Vector2(0.0, 8.0 * (1.0 - sc)), 0.0, Vector2(sc, sc))
		_draw_planta_simple()
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# Animación de agua (aros azules expandiéndose)
		if _riego_t >= 0.0:
			for i in 3:
				var d := _riego_t + float(i) * 0.28
				if d > 1.0: continue
				var r := d * 48.0
				draw_arc(Vector2.ZERO, r, 0.0, TAU, 24,
						 Color(0.25, 0.65, 0.95, (1.0 - d) * 0.8), 3.0)

	func _draw_planta_simple() -> void:
		draw_rect(Rect2(-3, -6, 6, 14), Color(0.40, 0.25, 0.10))
		draw_circle(Vector2(0, -18), 16.0, Color(0.15, 0.62, 0.18))
		draw_circle(Vector2(-9, -12), 11.0, Color(0.18, 0.68, 0.20))
		draw_circle(Vector2( 9, -12), 11.0, Color(0.18, 0.68, 0.20))
		draw_circle(Vector2(0, -26), 12.0, Color(0.22, 0.72, 0.22))

class AroAgua extends Node2D:
	func _draw() -> void:
		draw_arc(Vector2(0, -70.0), 16.0, 0.0, TAU, 20, Color(0.22, 0.60, 0.96, 1.0), 2.0)

# Mismo arreglo que TierraVisual: se dibuja una vez y se anima moviendo el
# nodo (balanceo) y la transparencia del aro, en vez de redibujar cada frame.
class AguaIndicador extends Node2D:
	var _t      : float  = 0.0
	var _base_y : float  = 0.0
	var _aro    : Node2D = null
	func _ready() -> void:
		_base_y = position.y
		_aro = AroAgua.new()
		add_child(_aro)
	func _process(delta: float) -> void:
		_t += delta
		position.y = _base_y + sin(_t * 4.5) * 5.0
		_aro.modulate.a = 0.45 + 0.3 * sin(_t * 5.0)
	func _draw() -> void:
		var cy  := -70.0   # el balanceo lo hace position.y
		var pts := PackedVector2Array([
			Vector2(0, cy - 16), Vector2(-8, cy),
			Vector2(0, cy + 9),  Vector2(8, cy)
		])
		draw_colored_polygon(pts, Color(0.22, 0.60, 0.96, 0.92))
		draw_circle(Vector2(-2, cy - 6), 2.5, Color(0.85, 0.93, 1.0, 0.75))
		# (El aro que late lo dibuja AroAgua, hijo de este nodo.)


# ── Jardinero animado (5 fases) ───────────────────────────────
class GardeneroVisual extends Node2D:
	var fase        : int   = 0
	var _t_walk     : float = 0.0
	var _t_fase     : float = 0.0
	var _bend       : float = 0.0
	var _agua_t     : float = 0.0
	const BEND_SPEED : float = 1.8

	func _process(delta: float) -> void:
		_t_walk += delta
		_t_fase += delta
		_agua_t += delta
		match fase:
			1: _bend = minf(_bend + BEND_SPEED * delta, 1.0)
			3: _bend = maxf(_bend - BEND_SPEED * delta, 0.0)
		queue_redraw()

	func _draw() -> void:
		var caminando : bool  = (fase == 0 or fase == 4)
		var leg_swing : float = sin(_t_walk * 9.0) * 6.0 if caminando else 0.0
		var B         : float = _bend * 8.0

		# Sombra
		draw_arc(Vector2(0, 16 + B * 0.3), 12.0, 0.0, PI, 10,
				Color(0.0, 0.0, 0.0, 0.22), 4.0)

		# Piernas (pantalón azul oscuro)
		draw_line(Vector2(-4, 4 + B * 0.3), Vector2(-4 + leg_swing, 16),
				  Color(0.12, 0.22, 0.50), 3.5)
		draw_line(Vector2(4, 4 + B * 0.3), Vector2(4 - leg_swing, 16),
				  Color(0.12, 0.22, 0.50), 3.5)
		draw_circle(Vector2(-4 + leg_swing, 16), 2.5, Color(0.15, 0.15, 0.15))
		draw_circle(Vector2(4 - leg_swing, 16), 2.5, Color(0.15, 0.15, 0.15))

		# Cuerpo (camisa verde jardinero)
		draw_colored_polygon(PackedVector2Array([
			Vector2(-7, -8 + B), Vector2(7, -8 + B),
			Vector2(8, 5 + B * 0.5), Vector2(-8, 5 + B * 0.5)
		]), Color(0.28, 0.68, 0.35))
		# Franja amarilla reflectiva
		draw_rect(Rect2(-7, -1 + B * 0.8, 14, 2.5), Color(0.92, 0.82, 0.08))

		# Brazos + regadera (fases 1 y 2)
		if fase == 1 or fase == 2:
			var arm_ext : float = 8.0 * _bend
			var arm_end := Vector2(9.0 + arm_ext, 2.0 + B * 0.4)
			draw_line(Vector2(7, -4 + B), arm_end, Color(0.28, 0.68, 0.35), 3.0)
			# Regadera: cuerpo trapezoidal
			draw_colored_polygon(PackedVector2Array([
				arm_end + Vector2(0, -5),  arm_end + Vector2(14, -3),
				arm_end + Vector2(12, 5),  arm_end + Vector2(-2, 5)
			]), Color(0.55, 0.72, 0.88))
			# Asa
			draw_arc(arm_end + Vector2(6, -5), 5.0, -PI * 0.5, PI * 0.5, 10,
					 Color(0.40, 0.60, 0.80), 2.0)
			# Pitorrete
			var spout_end := arm_end + Vector2(22, 10)
			draw_line(arm_end + Vector2(12, 4), spout_end, Color(0.40, 0.60, 0.80), 2.0)
			# Brazo izquierdo quieto
			draw_line(Vector2(-7, -5 + B), Vector2(-11, 3 + B * 0.4),
					  Color(0.28, 0.68, 0.35), 3.0)
			# Gotas de agua cayendo (solo fase 2)
			if fase == 2:
				for i in 5:
					var dt   := fmod(_agua_t * 1.6 + float(i) * 0.22, 1.0)
					var drop := spout_end + Vector2(-dt * 10.0, dt * 24.0)
					draw_circle(drop, 2.2, Color(0.30, 0.68, 0.95, 1.0 - dt))
		else:
			# Brazos oscilando al caminar
			var arm_s : float = -sin(_t_walk * 9.0) * 7.0 if caminando else 0.0
			draw_line(Vector2(-7, -5 + B), Vector2(-11, 3.0 + arm_s + B * 0.4),
					  Color(0.28, 0.68, 0.35), 3.0)
			draw_line(Vector2(7, -5 + B), Vector2(11, 3.0 - arm_s + B * 0.4),
					  Color(0.28, 0.68, 0.35), 3.0)

		# Cabeza
		var head_y : float = -14.0 + B * 1.15
		draw_circle(Vector2(0, head_y), 6.5, Color(0.85, 0.68, 0.48))
		# Sombrero de paja
		draw_colored_polygon(PackedVector2Array([
			Vector2(-12, head_y - 1), Vector2(12, head_y - 1),
			Vector2(8, head_y - 8),   Vector2(-8, head_y - 8)
		]), Color(0.80, 0.65, 0.30))
		draw_rect(Rect2(-13, head_y - 3, 26, 3), Color(0.72, 0.56, 0.22))


# ── Badge flotante de impacto ambiental ───────────────────────
# Se redibujaba en cada frame para un balanceo de ±1,5 px, incluso cuando
# estaba invisible (modulate.a = 0 mientras el jugador no está cerca). Ahora
# se dibuja una vez y el balanceo mueve el nodo.
class EcoBadge extends Node2D:
	var _t      : float = 0.0
	var _base_y : float = 0.0
	func _ready() -> void:
		_base_y = position.y   # zona_tierra le asigna (0, -52) antes de agregarlo
	func _process(delta: float) -> void:
		_t += delta
		position.y = _base_y + sin(_t * 1.8) * 1.5
	func _draw() -> void:
		var font := ThemeDB.fallback_font
		if not font: return
		var bob := 0.0   # el balanceo lo hace position.y
		# Fondo pill (2 líneas de texto)
		draw_rect(Rect2(-46, -24 + bob, 94, 30), Color(0.03, 0.10, 0.05, 0.88))
		draw_rect(Rect2(-46, -24 + bob, 94, 30), Color(0.22, 0.88, 0.30, 0.55), false, 1.5)
		# Ícono árbol: tronco + 3 copas
		var tx := -36.0
		var ty  := bob - 10.0
		draw_rect(Rect2(tx - 1.5, ty + 7, 3, 8), Color(0.52, 0.32, 0.12))
		draw_circle(Vector2(tx, ty + 3),      5.5, Color(0.18, 0.70, 0.22))
		draw_circle(Vector2(tx - 4.5, ty + 7), 3.8, Color(0.20, 0.68, 0.24))
		draw_circle(Vector2(tx + 4.5, ty + 7), 3.8, Color(0.20, 0.68, 0.24))
		# Línea 1: CO2 (verde)
		draw_string(font, Vector2(-26, -9 + bob),
					"CO2: -12 kg/ano",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
					Color(0.38, 0.96, 0.42))
		# Línea 2: temperatura (celeste)
		draw_string(font, Vector2(-26, 3 + bob),
					"Temp: -1.5 C",
					HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
					Color(0.55, 0.88, 0.96))


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _ready() -> void:
	add_to_group("zona_tierra")
	_crear_collision()
	_crear_visual()
	_crear_prompt()
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	var nm = _nivel_mgr()
	if nm and nm.mision_completada_q(1, mision_id):
		_marcar_completada(false)   # ya estaba plantada — sin animación


func _crear_collision() -> void:
	var shape := CircleShape2D.new()
	shape.radius = RADIO_DETEC
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)


func _crear_visual() -> void:
	_planta_visual = TierraVisual.new()
	(_planta_visual as TierraVisual).completada = false
	_planta_visual.z_index = 1
	add_child(_planta_visual)


func _crear_prompt() -> void:
	_prompt_canvas = CanvasLayer.new()
	_prompt_canvas.layer = 12
	add_child(_prompt_canvas)

	_prompt_panel = Panel.new()
	_prompt_panel.custom_minimum_size = Vector2(200, 42)
	_prompt_panel.visible = false
	_prompt_canvas.add_child(_prompt_panel)

	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.10, 0.06, 0.93)
	ps.border_color = Color(0.22, 0.88, 0.30)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(10)
	ps.shadow_color = Color(0.10, 0.50, 0.15, 0.40)
	ps.shadow_size  = 8
	_prompt_panel.add_theme_stylebox_override("panel", ps)

	_prompt_lbl = Label.new()
	_prompt_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_prompt_lbl.add_theme_font_size_override("font_size", 13)
	_prompt_lbl.add_theme_color_override("font_color", Color(0.88, 1.0, 0.88))
	_prompt_panel.add_child(_prompt_lbl)

	# ── Panel de información (visible tras completar la misión) ─
	_info_panel = Panel.new()
	_info_panel.custom_minimum_size = Vector2(340, 250)
	_info_panel.set_anchors_preset(Control.PRESET_CENTER)
	_info_panel.offset_left   = -170.0
	_info_panel.offset_top    = -125.0
	_info_panel.offset_right  =  170.0
	_info_panel.offset_bottom =  125.0
	_info_panel.visible   = false
	_info_panel.modulate.a = 0.0
	_prompt_canvas.add_child(_info_panel)

	var ip_st := StyleBoxFlat.new()
	ip_st.bg_color     = Color(0.04, 0.10, 0.06, 0.97)
	ip_st.border_color = Color(0.22, 0.88, 0.30)
	ip_st.set_border_width_all(2)
	ip_st.set_corner_radius_all(12)
	ip_st.shadow_color = Color(0.10, 0.50, 0.15, 0.55)
	ip_st.shadow_size  = 14
	_info_panel.add_theme_stylebox_override("panel", ip_st)

	var ip_vb := VBoxContainer.new()
	ip_vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ip_vb.offset_left   =  14.0
	ip_vb.offset_top    =  12.0
	ip_vb.offset_right  = -14.0
	ip_vb.offset_bottom = -12.0
	ip_vb.add_theme_constant_override("separation", 6)
	_info_panel.add_child(ip_vb)

	var ip_tit := Label.new()
	ip_tit.text = "🌳 Árbol Plantado — Impacto Ambiental"
	ip_tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ip_tit.add_theme_font_size_override("font_size", 15)
	ip_tit.add_theme_color_override("font_color", Color(0.30, 1.00, 0.40))
	ip_vb.add_child(ip_tit)

	var ip_sep := HSeparator.new()
	ip_sep.add_theme_color_override("color", Color(0.22, 0.88, 0.30, 0.5))
	ip_vb.add_child(ip_sep)

	var ip_body := Label.new()
	ip_body.text = (
		"🌿 Absorción de CO₂: ~12 kg / año\n"
		+ "🌡 Reducción térmica: ↓ 1.5 °C en el área\n"
		+ "💧 Mejora el drenaje y retención hídrica\n"
		+ "🐝 Fomenta la biodiversidad local\n"
		+ "☀️ Genera sombra natural para el campus"
	)
	ip_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	ip_body.add_theme_font_size_override("font_size", 12)
	ip_body.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
	ip_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	ip_vb.add_child(ip_body)

	var ip_btn := Button.new()
	ip_btn.text = "Cerrar"
	ip_btn.add_theme_font_size_override("font_size", 13)
	ip_btn.pressed.connect(_cerrar_info_panel)
	ip_vb.add_child(ip_btn)


func _process(delta: float) -> void:
	# ── Timer de riego ────────────────────────────────────────
	if _completada and not _necesita_riego:
		_riego_timer += delta
		if _riego_timer >= WATERING_INTERVAL:
			_activar_necesidad_riego()

	# ── Posición del prompt en pantalla ───────────────────────
	if not _prompt_panel.visible: return
	var cam := get_viewport().get_camera_2d()
	if not cam: return
	var gp := global_position + Vector2(-100, -80)
	var vp_size := get_viewport().get_visible_rect().size
	var cam_zoom := cam.zoom
	var cam_offset := cam.global_position - vp_size * 0.5 / cam_zoom
	var screen_pos := (gp - cam_offset) * cam_zoom
	_prompt_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_prompt_panel.position = screen_pos


func _al_entrar(body: Node) -> void:
	if not body.is_in_group("jugador"): return
	_jugador_cerca = true
	_actualizar_texto_prompt()
	_prompt_panel.modulate.a = 0.0
	_prompt_panel.visible    = true
	var tw := create_tween()
	tw.tween_property(_prompt_panel, "modulate:a", 1.0, 0.20)
	if is_instance_valid(_eco_badge):
		var twb := create_tween()
		twb.tween_property(_eco_badge, "modulate:a", 0.90, 0.20)


func _actualizar_texto_prompt() -> void:
	if _completada:
		if _necesita_riego:
			_prompt_lbl.text = "💧 [E]  Regar la planta — %s" % nombre_zona
		else:
			_prompt_lbl.text = "✅ [E]  Ver árbol plantado — %s" % nombre_zona
	else:
		var icono := "🖐" if modo_interaccion == "drag" else "🌱"
		_prompt_lbl.text = "%s [E]  Plantar en %s" % [icono, nombre_zona]


func _al_salir(body: Node) -> void:
	if not body.is_in_group("jugador"): return
	_jugador_cerca = false
	var tw := create_tween()
	tw.tween_property(_prompt_panel, "modulate:a", 0.0, 0.16)
	tw.tween_callback(func(): _prompt_panel.visible = false)
	if is_instance_valid(_eco_badge):
		var twb := create_tween()
		twb.tween_property(_eco_badge, "modulate:a", 0.0, 0.16)
	if is_instance_valid(_info_panel) and _info_panel.visible:
		var tw2 := create_tween()
		tw2.tween_property(_info_panel, "modulate:a", 0.0, 0.16)
		tw2.tween_callback(func(): _info_panel.visible = false)


func intentar_interactuar() -> void:
	if not _jugador_cerca: return
	if _completada:
		if _necesita_riego:
			_regar_planta()
		else:
			_mostrar_info_completada()
		return
	_prompt_panel.visible = false
	plantar_solicitado.emit(self)


func _mostrar_info_completada() -> void:
	if not is_instance_valid(_info_panel): return
	_info_panel.visible    = true
	_info_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_info_panel, "modulate:a", 1.0, 0.22)


func _cerrar_info_panel() -> void:
	if not is_instance_valid(_info_panel): return
	var tw := create_tween()
	tw.tween_property(_info_panel, "modulate:a", 0.0, 0.16)
	tw.tween_callback(func(): _info_panel.visible = false)


func _marcar_completada(animar : bool = true) -> void:
	_completada = true
	_prompt_panel.visible = false
	if not is_instance_valid(_planta_visual): return
	var tv := _planta_visual as TierraVisual
	tv.completada = true
	if animar:
		tv._growth_t = 0.0
		_riego_timer = randf() * WATERING_INTERVAL * 0.4
		var tw := create_tween()
		tw.tween_property(tv, "_growth_t", 1.0, 3.5)
		tw.tween_callback(_crear_eco_badge)
	else:
		tv._growth_t = 1.0
		_crear_eco_badge()


func _crear_eco_badge() -> void:
	# Solo visible cuando el jugador está cerca — evita que el mapa se
	# llene de badges permanentes al plantar muchos árboles.
	if is_instance_valid(_eco_badge): return
	_eco_badge = EcoBadge.new()
	_eco_badge.position = Vector2(0, -52)
	_eco_badge.z_index  = 3
	_eco_badge.modulate.a = 0.0
	add_child(_eco_badge)
	if _jugador_cerca:
		var tw := create_tween()
		tw.tween_property(_eco_badge, "modulate:a", 0.90, 0.8)


func _activar_necesidad_riego() -> void:
	_necesita_riego = true
	if not is_instance_valid(_agua_node):
		_agua_node = AguaIndicador.new()
		_agua_node.z_index = 2
		add_child(_agua_node)
	if _jugador_cerca:
		_actualizar_texto_prompt()


func _regar_planta() -> void:
	_necesita_riego = false
	_riego_timer    = 0.0
	if is_instance_valid(_agua_node):
		_agua_node.queue_free()
		_agua_node = null
	_iniciar_animacion_riego()
	var em = get_node_or_null("/root/EconomiaManager")
	if em:
		em.ganar_creditos(8)
	riego_realizado.emit(self, 10, 8)
	if _jugador_cerca:
		_actualizar_texto_prompt()


func _iniciar_animacion_riego() -> void:
	var g := GardeneroVisual.new()
	g.position = position + Vector2(-120, 0)
	g.z_index  = 3
	get_parent().add_child(g)

	var tv_ref := _planta_visual

	var tw := get_tree().create_tween()
	# Fase 0 → camina hacia la planta (2.0 s)
	tw.tween_property(g, "position", position + Vector2(-22, 10), 2.0)
	# Fase 1 → se prepara, dobla brazo con regadera (0.5 s)
	tw.tween_callback(func(): g.fase = 1)
	tw.tween_interval(0.5)
	# Fase 2 → riega (2.0 s), dispara aros de agua en la planta
	tw.tween_callback(func():
		g.fase = 2
		if is_instance_valid(tv_ref):
			(tv_ref as TierraVisual).disparar_riego()
	)
	tw.tween_interval(2.0)
	# Fase 3 → se incorpora (0.5 s)
	tw.tween_callback(func(): g.fase = 3)
	tw.tween_interval(0.5)
	# Fase 4 → se retira caminando y se desvanece (2.0 s)
	tw.tween_callback(func(): g.fase = 4)
	tw.tween_property(g, "position", position + Vector2(-140, 0), 2.0)
	tw.tween_property(g, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		if is_instance_valid(g):
			g.queue_free()
	)
