# ============================================================
# SceneLogin.gd — GreenMetric URBE
# Tres paneles: Login | Registro | Recuperar contraseña
# Diseño: fondo animado, glassmorphism, tweens, spinner
# ============================================================
extends Control

# ── Nodos del .tscn ──────────────────────────────────────────
@onready var _email_in  : LineEdit        = %EmailInput
@onready var _pass_in   : LineEdit        = %PasswordInput
@onready var _btn_login : Button          = %BotonLogin
@onready var _btn_reg   : Button          = %BotonRegistro
@onready var _msg_login : Label           = %MensajeLabel
@onready var _center    : CenterContainer = $CenterContainer
@onready var _bg_rect   : ColorRect       = $ColorRect

# ── Panel Registro ────────────────────────────────────────────
var _panel_reg   : Control  = null
var _reg_nombre  : LineEdit = null
var _reg_cedula  : LineEdit = null
var _reg_email   : LineEdit = null
var _reg_carrera : OptionButton = null
var _reg_trimestre: OptionButton = null
var _reg_pass    : LineEdit = null
var _reg_confirm : LineEdit = null
var _btn_crear   : Button   = null
var _msg_reg     : Label    = null

# ── Panel Recuperar (3 pasos: código → verificar → nueva clave) ──
var _panel_rec        : Control  = null
var _rec_paso1         : Control  = null
var _rec_paso2         : Control  = null
var _rec_paso3         : Control  = null
var _rec_email         : LineEdit = null
var _btn_enviar        : Button   = null
var _rec_codigo        : LineEdit = null
var _btn_verificar     : Button   = null
var _rec_pass_nueva     : LineEdit = null
var _rec_pass_confirmar : LineEdit = null
var _btn_cambiar       : Button   = null
var _msg_rec           : Label    = null

# ── Validación de correo (idéntica a la del servidor) ─────────
# La base rechaza dominios no permitidos, pero Supabase enmascara ese
# error con un mensaje genérico e inútil — así que el formulario valida
# lo mismo ANTES de llamar a /auth/v1/signup, para dar un mensaje claro.
const FONDO_ILUSTRADO_PATH : String = "res://assets/sprites/login_fondo.png"
const EMAIL_REGEX          : String = "^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$"
const DOMINIOS_PERMITIDOS  : Array  = ["urbe.edu", "gmail.com", "outlook.com",
										"hotmail.com", "yahoo.com", "icloud.com"]
var _re_email : RegEx = null

# ── Estado ───────────────────────────────────────────────────
# true mientras la sesión de SupabaseManager.login() en curso viene de un
# registro sin sesión (signup 200 sin access_token), no de que el usuario
# tocó "Iniciar sesión" — cambia cómo se interpreta login_fallido.
var _login_es_post_registro : bool = false
var _cargando       : bool  = false
var _tween_panel    : Tween = null
var _spinner_label  : Label = null
var _spinner_chars  : Array = ["◐","◓","◑","◒"]
var _spinner_idx    : int   = 0
var _spinner_timer  : float = 0.0



# ════════════════════════════════════════════════════════════
# INNER CLASS — Fondo animado con partículas flotantes
# Todos los valores de Dictionary se castean a float explícitamente
# para evitar el error "Cannot infer type from Variant".
# ════════════════════════════════════════════════════════════
class BackgroundNode extends Node2D:
	var _t    : float          = 0.0
	var _orbs : Array          = []
	var _hex  : Array[Vector2] = []   # tipado → p.x / p.y son float

	func _ready() -> void:
		# Usa el tamaño real del viewport para cubrir cualquier resolución
		var sz := get_viewport_rect().size
		if sz == Vector2.ZERO:
			sz = Vector2(1280.0, 720.0)
		for _i in 50:
			_orbs.append(_rand_orb(sz, true))
		# Grid hexagonal con margen extra para no dejar bordes vacíos al escalar
		var cols : int = int(sz.x / 48.0) + 3
		var rows : int = int(sz.y / 40.0) + 3
		for gy in rows:
			for gx in cols:
				_hex.append(Vector2(gx * 48.0 + (gy % 2) * 24.0, gy * 40.0))

	func _rand_orb(sz: Vector2, init: bool = false) -> Dictionary:
		return {
			"x"   : randf_range(0.0, sz.x),
			"y"   : randf_range(0.0, sz.y) if init else sz.y + 16.0,
			"vy"  : randf_range(-28.0, -10.0),
			"vx"  : randf_range(-4.0, 4.0),
			"r"   : randf_range(2.0, 8.5),
			"ph"  : randf_range(0.0, TAU),
			"sp"  : randf_range(0.5, 1.7),
			"leaf": (randi() % 4 != 0),
		}

	func _process(delta: float) -> void:
		_t += delta
		var sz := get_viewport_rect().size
		for i in _orbs.size():
			var o : Dictionary = _orbs[i]
			o["y"] = float(o["y"]) + float(o["vy"]) * delta
			o["x"] = float(o["x"]) + float(o["vx"]) * delta \
					 + sin(_t * float(o["sp"]) + float(o["ph"])) * 0.25
			if float(o["y"]) < -20.0:
				_orbs[i] = _rand_orb(sz)
		queue_redraw()

	func _draw() -> void:
		# Puntos de cuadrícula — _hex es Array[Vector2], p.x/p.y son float
		for p : Vector2 in _hex:
			var a : float = 0.04 + 0.02 * sin(_t * 0.4 + p.x * 0.01 + p.y * 0.02)
			draw_circle(p, 1.2, Color(0.20, 0.72, 0.32, a))

		# Partículas flotantes — cast explícito de valores Variant
		for o in _orbs:
			var sp  : float = float(o["sp"])
			var ph  : float = float(o["ph"])
			var ox  : float = float(o["x"])
			var oy  : float = float(o["y"])
			var r   : float = float(o["r"])
			var a   : float = 0.06 + 0.04 * sin(_t * sp + ph)
			var col := Color(0.22, 0.82, 0.36, a)
			var pos := Vector2(ox, oy)
			if bool(o["leaf"]):
				var ang : float = _t * sp * 0.28 + ph
				var d   := Vector2(cos(ang), sin(ang)) * r * 0.5
				draw_arc(pos + d, r * 0.85, ang, ang + PI,  10, col, 1.3)
				draw_arc(pos - d, r * 0.85, ang + PI, ang + TAU, 10, col, 1.3)
			else:
				draw_circle(pos, r, col)
				draw_arc(pos, r, 0.0, TAU, 12, col.lightened(0.3), 0.8)


# ════════════════════════════════════════════════════════════
# INNER CLASS — Logo animado con hoja giratoria
# ════════════════════════════════════════════════════════════
class LogoNode extends Node2D:
	var _t : float = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var puls : float = 1.0 + 0.06 * sin(_t * 2.2)
		var ga   : float = 0.12 + 0.06 * sin(_t * 1.8)
		var glow := Color(0.20, 0.78, 0.30, ga)
		# Halo exterior — valores float literales, sin loop sobre Variant
		draw_circle(Vector2.ZERO, 22.0 * puls, glow)
		draw_circle(Vector2.ZERO, 18.0 * puls, glow)
		draw_circle(Vector2.ZERO, 14.0 * puls, glow)
		# Hoja principal
		var ang : float = _t * 0.6
		var d1  := Vector2(cos(ang) * 5.0, sin(ang) * 5.0)
		draw_arc( d1, 10.0 * puls, ang, ang + PI * 1.1, 16, Color(0.22, 0.88, 0.35, 0.90), 2.2)
		draw_arc(-d1, 10.0 * puls, ang, ang + PI * 1.1, 16, Color(0.22, 0.88, 0.35, 0.90), 2.2)
		# Centro
		draw_circle(Vector2.ZERO, 4.5 * puls, Color(0.38, 1.0, 0.50, 0.95))
		draw_circle(Vector2.ZERO, 2.5,        Color(0.12, 0.44, 0.18, 1.0))


# ════════════════════════════════════════════════════════════
# READY
# ════════════════════════════════════════════════════════════
func _ready() -> void:
	_re_email = RegEx.new()
	_re_email.compile(EMAIL_REGEX)

	# Fondo oscuro y partículas
	_bg_rect.color = Color(0.030, 0.065, 0.033, 1.0)

	# Fondo ilustrado (opcional) — hueco listo para cuando exista el arte.
	# Sin textura asignada acá no se ve nada, y queda debajo del ColorRect
	# de partículas: asignar FONDO_ILUSTRADO_PATH y listo, no hace falta
	# tocar más código.
	if FONDO_ILUSTRADO_PATH != "" and ResourceLoader.exists(FONDO_ILUSTRADO_PATH):
		var fondo_tex := TextureRect.new()
		fondo_tex.texture = load(FONDO_ILUSTRADO_PATH)
		fondo_tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		fondo_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		fondo_tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(fondo_tex)
		move_child(fondo_tex, 1)   # justo encima del ColorRect

	var bg := BackgroundNode.new()
	add_child(bg)
	move_child(bg, 2)   # entre el fondo ilustrado (si existe) y CenterContainer

	# Señales Supabase
	SupabaseManager.login_exitoso.connect(_en_login_exitoso)
	SupabaseManager.login_fallido.connect(_en_login_fallido)
	SupabaseManager.registro_exitoso.connect(_en_registro_exitoso)
	SupabaseManager.registro_sin_sesion.connect(_en_registro_sin_sesion)
	SupabaseManager.registro_fallido.connect(_en_registro_fallido)
	SupabaseManager.recuperacion_enviada.connect(_en_recuperacion_enviada)
	SupabaseManager.recuperacion_fallida.connect(_en_recuperacion_fallida)
	SupabaseManager.codigo_verificado.connect(_en_codigo_verificado)
	SupabaseManager.codigo_fallido.connect(_en_codigo_fallido)
	SupabaseManager.contrasena_actualizada.connect(_en_contrasena_actualizada)
	SupabaseManager.actualizar_contrasena_fallido.connect(_en_actualizar_contrasena_fallido)
	SupabaseManager.error_red.connect(_en_error_red)

	_pass_in.secret = true
	_msg_login.text = ""

	# Estilizar panel login (nodos del .tscn)
	_aplicar_estilo_panel_tscn()

	# Botón "¿Olvidaste tu contraseña?"
	var btn_olvide := _btn_link("¿Olvidaste tu contraseña?",
								Color(0.40, 0.72, 1.0))
	var vlogin := _btn_reg.get_parent() as VBoxContainer
	vlogin.add_child(btn_olvide)
	vlogin.move_child(btn_olvide, _btn_reg.get_index() + 1)

	# Spinner de carga
	_spinner_label = Label.new()
	_spinner_label.text = ""
	_spinner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spinner_label.add_theme_font_size_override("font_size", 22)
	_spinner_label.add_theme_color_override("font_color", Color(0.35, 0.92, 0.46))
	_spinner_label.visible = false
	vlogin.add_child(_spinner_label)

	# Conexiones botones login
	_btn_login.pressed.connect(_on_login_pressed)
	_btn_reg.pressed.connect(func(): _cambiar_panel("registro"))
	btn_olvide.pressed.connect(func():
		_resetear_panel_recuperacion()
		_cambiar_panel("recuperar"))

	# Hover en botón principal
	_btn_login.mouse_entered.connect(func():
		if not _cargando: _escalar_btn(_btn_login, 1.04))
	_btn_login.mouse_exited.connect(func():
		_escalar_btn(_btn_login, 1.0))

	_crear_panel_registro()
	_crear_panel_recuperacion()
	_cambiar_panel("login")


func _process(delta: float) -> void:
	if not _cargando: return
	_spinner_timer += delta
	if _spinner_timer >= 0.17:
		_spinner_timer = 0.0
		_spinner_idx = (_spinner_idx + 1) % _spinner_chars.size()
		if is_instance_valid(_spinner_label):
			_spinner_label.text = _spinner_chars[_spinner_idx]


# ════════════════════════════════════════════════════════════
# ESTILOS VISUALES
# ════════════════════════════════════════════════════════════
func _aplicar_estilo_panel_tscn() -> void:
	# Panel container del .tscn
	var pc := _center.get_child(0) as PanelContainer
	if pc: pc.add_theme_stylebox_override("panel", _style_panel())

	# Logo con animación — insertarlo en el vbox del .tscn
	var vlogin := _btn_login.get_parent() as VBoxContainer
	var logo_ctrl := _crear_logo_widget()
	vlogin.add_child(logo_ctrl)
	vlogin.move_child(logo_ctrl, 0)

	# Título original del .tscn (index 1 ahora, porque logo va al 0)
	var titulo := vlogin.get_child(1) as Label
	if titulo:
		# El emoji 🌿 no existe en la fuente pixel-art (Press Start 2P no
		# trae glifos de emoji, se vería como un cuadrado vacío) — de
		# todos modos ya sobra, el logo animado de arriba (LogoNode) es
		# la misma hoja pero dibujada, así que el emoji del texto es
		# redundante.
		titulo.text = "GreenMetric URBE"
		var fuente_pixel := _fuente_pixel()
		if fuente_pixel:
			titulo.add_theme_font_override("font", fuente_pixel)
		titulo.add_theme_font_size_override("font_size", 16)
		titulo.add_theme_color_override("font_color", Color(0.35, 0.95, 0.50))

	# Subtítulo "Inicia sesión..." (index 3)
	var sub := vlogin.get_child(3) as Label
	if sub:
		sub.add_theme_color_override("font_color", Color(0.52, 0.68, 0.55))
		sub.add_theme_font_size_override("font_size", 11)

	_estilizar_input(_email_in)
	_estilizar_input(_pass_in)
	_estilizar_btn_primario(_btn_login)
	_estilizar_btn_secundario(_btn_reg)

	_msg_login.add_theme_font_size_override("font_size", 12)
	_msg_login.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _crear_logo_widget() -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(60, 60)

	var logo := LogoNode.new()
	logo.position = Vector2(c.custom_minimum_size.x * 0.5, c.custom_minimum_size.y * 0.5)
	c.add_child(logo)

	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return c


func _fuente_pixel() -> Font:
	const RUTA : String = "res://assets/fonts/PressStart2P-Regular.ttf"
	if not ResourceLoader.exists(RUTA):
		return null
	return load(RUTA) as Font


func _style_panel() -> StyleBoxFlat:
	# Azul-pizarra oscuro con borde cian — pedido explícito del usuario
	# (referencia: panel de login con look de terminal azul/cian, en vez
	# del verde que tenía el panel antes). El verde se conserva como
	# color de marca en el botón LOGIN, ver _estilizar_btn_primario.
	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.075, 0.095, 0.125, 0.92)
	sb.border_color = Color(0.30, 0.65, 0.85, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.shadow_color  = Color(0.20, 0.55, 0.78, 0.35)
	sb.shadow_size   = 12
	sb.shadow_offset = Vector2(0, 5)
	sb.content_margin_left   = 26
	sb.content_margin_right  = 26
	sb.content_margin_top    = 22
	sb.content_margin_bottom = 22
	return sb


func _estilizar_input(le: LineEdit) -> void:
	le.custom_minimum_size = Vector2(290, 40)

	var sb_n := StyleBoxFlat.new()
	sb_n.bg_color     = Color(0.055, 0.075, 0.100, 0.96)
	sb_n.border_color = Color(0.24, 0.34, 0.44, 0.70)
	sb_n.set_border_width_all(1)
	sb_n.set_corner_radius_all(8)
	sb_n.content_margin_left   = 12
	sb_n.content_margin_right  = 12
	sb_n.content_margin_top    = 8
	sb_n.content_margin_bottom = 8
	le.add_theme_stylebox_override("normal", sb_n)

	var sb_f := sb_n.duplicate() as StyleBoxFlat
	sb_f.border_color = Color(0.35, 0.75, 0.95, 1.0)
	sb_f.set_border_width_all(2)
	sb_f.shadow_color = Color(0.25, 0.65, 0.90, 0.30)
	sb_f.shadow_size  = 7
	le.add_theme_stylebox_override("focus", sb_f)

	le.add_theme_color_override("font_color",             Color(0.90, 0.95, 0.98))
	le.add_theme_color_override("font_placeholder_color", Color(0.42, 0.52, 0.62))
	le.add_theme_color_override("caret_color",            Color(0.45, 0.85, 0.98))
	le.add_theme_font_size_override("font_size", 13)


func _estilizar_btn_primario(btn: Button) -> void:
	# Botón de contorno (fondo oscuro + borde brillante), no relleno
	# sólido — pedido explícito del usuario mostrando una referencia con
	# ese estilo. Verde: es el botón principal (LOGIN), mantiene el color
	# de marca de GreenMetric.
	_estilizar_btn_contorno(btn, Color(0.30, 0.90, 0.45))
	btn.add_theme_font_size_override("font_size", 14)


func _estilizar_btn_secundario(btn: Button) -> void:
	# Mismo tratamiento de contorno que el primario, pero en cian — el
	# botón secundario (ej. "Crear cuenta") de la referencia del usuario.
	_estilizar_btn_contorno(btn, Color(0.35, 0.80, 0.95))
	btn.add_theme_font_size_override("font_size", 13)


func _estilizar_btn_contorno(btn: Button, col: Color) -> void:
	btn.custom_minimum_size = Vector2(290, 44)
	btn.pivot_offset = btn.size * 0.5
	btn.flat = false

	var mk := func(bg_a: float, border_a: float) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color     = Color(0.06, 0.09, 0.10, bg_a)
		s.border_color = Color(col.r, col.g, col.b, border_a)
		s.set_border_width_all(2)
		s.set_corner_radius_all(11)
		s.shadow_color  = Color(col.r, col.g, col.b, 0.30)
		s.shadow_size   = 6
		s.content_margin_top    = 10
		s.content_margin_bottom = 10
		return s

	btn.add_theme_stylebox_override("normal",  mk.call(0.55, 0.75))
	btn.add_theme_stylebox_override("hover",   mk.call(0.75, 1.0))
	btn.add_theme_stylebox_override("pressed", mk.call(0.85, 0.55))
	btn.add_theme_color_override("font_color",       col.lightened(0.15))
	btn.add_theme_color_override("font_hover_color", col.lightened(0.35))


func _estilizar_option(ob: OptionButton) -> void:
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ob.add_theme_color_override("font_color", Color(0.85, 0.95, 0.87))
	ob.add_theme_font_size_override("font_size", 12)


func _escalar_btn(btn: Button, escala: float) -> void:
	var tw := create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "scale", Vector2(escala, escala), 0.12)


func _btn_link(texto: String, col: Color) -> Button:
	var b := Button.new()
	b.text = texto
	b.flat = true
	b.add_theme_color_override("font_color", col)
	b.add_theme_font_size_override("font_size", 11)
	return b


# ════════════════════════════════════════════════════════════
# PANEL REGISTRO
# ════════════════════════════════════════════════════════════
func _crear_panel_registro() -> void:
	var vbox := _nuevo_panel()

	_titulo(vbox, "Crear Cuenta")
	_lbl_sec(vbox, "Datos personales")

	_reg_nombre = _campo(vbox, "Nombre completo *")
	_reg_cedula = _campo(vbox, "Cédula (ej. V-12345678) *")

	_lbl_sec(vbox, "Información académica")
	_lbl(vbox, "Carrera:")
	_reg_carrera = OptionButton.new()
	for c in ["Ingeniería en Computación", "Ingeniería Industrial",
			  "Ingeniería Eléctrica", "Ingeniería de Telecomunicaciones",
			  "Arquitectura", "Administración de Empresas",
			  "Contaduría Pública", "Comunicación Social",
			  "Derecho", "Educación", "Psicología", "Medicina", "Otra"]:
		_reg_carrera.add_item(c)
	_estilizar_option(_reg_carrera)
	vbox.add_child(_reg_carrera)

	_lbl(vbox, "Trimestre:")
	_reg_trimestre = OptionButton.new()
	for i in range(1, 13):
		_reg_trimestre.add_item("Trimestre %d" % i)
	_estilizar_option(_reg_trimestre)
	vbox.add_child(_reg_trimestre)

	_lbl_sec(vbox, "Acceso")
	_reg_email   = _campo(vbox, "Correo electrónico *")
	_reg_pass    = _campo(vbox, "Contraseña (mín. 6 caracteres) *", true)
	_reg_confirm = _campo(vbox, "Confirmar contraseña *", true)

	vbox.add_child(HSeparator.new())

	_btn_crear = Button.new()
	_btn_crear.text = "Crear cuenta"
	_estilizar_btn_primario(_btn_crear)
	_btn_crear.mouse_entered.connect(func(): _escalar_btn(_btn_crear, 1.04))
	_btn_crear.mouse_exited.connect(func(): _escalar_btn(_btn_crear, 1.0))
	vbox.add_child(_btn_crear)
	_btn_crear.pressed.connect(_on_registro_pressed)

	var btn_volver_reg := _btn_link("← Volver al login", Color(0.40, 0.72, 1.0))
	vbox.add_child(btn_volver_reg)
	btn_volver_reg.pressed.connect(func(): _cambiar_panel("login"))

	vbox.add_child(HSeparator.new())
	_msg_reg = _make_msg(); vbox.add_child(_msg_reg)

	add_child(_panel_reg)


# ════════════════════════════════════════════════════════════
# PANEL RECUPERAR CONTRASEÑA
# ════════════════════════════════════════════════════════════
func _crear_panel_recuperacion() -> void:
	var vbox := _nuevo_panel()

	_titulo(vbox, "Recuperar Contraseña")
	vbox.add_child(HSeparator.new())

	# ── Paso 1: pedir el código por correo ──────────────────────
	_rec_paso1 = VBoxContainer.new()
	_rec_paso1.add_theme_constant_override("separation", 10)
	vbox.add_child(_rec_paso1)

	var desc1 := Label.new()
	desc1.text = "Ingresa tu correo registrado y te enviaremos\nun código de 6 dígitos para restablecer tu contraseña."
	desc1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc1.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc1.add_theme_color_override("font_color", Color(0.58, 0.75, 0.62))
	desc1.add_theme_font_size_override("font_size", 12)
	_rec_paso1.add_child(desc1)

	_rec_email = _campo(_rec_paso1, "Correo electrónico registrado")

	_btn_enviar = Button.new()
	_btn_enviar.text = "Enviar código"
	_estilizar_btn_primario(_btn_enviar)
	_btn_enviar.mouse_entered.connect(func(): _escalar_btn(_btn_enviar, 1.04))
	_btn_enviar.mouse_exited.connect(func(): _escalar_btn(_btn_enviar, 1.0))
	_rec_paso1.add_child(_btn_enviar)
	_btn_enviar.pressed.connect(_on_recuperar_pressed)

	# ── Paso 2: canjear el código ────────────────────────────────
	_rec_paso2 = VBoxContainer.new()
	_rec_paso2.add_theme_constant_override("separation", 10)
	_rec_paso2.visible = false
	vbox.add_child(_rec_paso2)

	var desc2 := Label.new()
	desc2.text = "Ingresa el código de 6 dígitos que te enviamos por correo."
	desc2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc2.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc2.add_theme_color_override("font_color", Color(0.58, 0.75, 0.62))
	desc2.add_theme_font_size_override("font_size", 12)
	_rec_paso2.add_child(desc2)

	_rec_codigo = _campo(_rec_paso2, "Código de 6 dígitos")

	_btn_verificar = Button.new()
	_btn_verificar.text = "Verificar código"
	_estilizar_btn_primario(_btn_verificar)
	_btn_verificar.mouse_entered.connect(func(): _escalar_btn(_btn_verificar, 1.04))
	_btn_verificar.mouse_exited.connect(func(): _escalar_btn(_btn_verificar, 1.0))
	_rec_paso2.add_child(_btn_verificar)
	_btn_verificar.pressed.connect(_on_verificar_codigo_pressed)

	var btn_reenviar := _btn_link("← Pedir otro código", Color(0.40, 0.72, 1.0))
	_rec_paso2.add_child(btn_reenviar)
	btn_reenviar.pressed.connect(func():
		_rec_paso1.visible = true
		_rec_paso2.visible = false
		_msg(_msg_rec, "", Color.WHITE))

	# ── Paso 3: contraseña nueva ─────────────────────────────────
	_rec_paso3 = VBoxContainer.new()
	_rec_paso3.add_theme_constant_override("separation", 10)
	_rec_paso3.visible = false
	vbox.add_child(_rec_paso3)

	var desc3 := Label.new()
	desc3.text = "Código verificado. Escribe tu contraseña nueva."
	desc3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc3.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc3.add_theme_color_override("font_color", Color(0.58, 0.75, 0.62))
	desc3.add_theme_font_size_override("font_size", 12)
	_rec_paso3.add_child(desc3)

	_rec_pass_nueva     = _campo(_rec_paso3, "Contraseña nueva (mín. 6 caracteres)", true)
	_rec_pass_confirmar = _campo(_rec_paso3, "Confirmar contraseña nueva", true)

	_btn_cambiar = Button.new()
	_btn_cambiar.text = "Cambiar contraseña"
	_estilizar_btn_primario(_btn_cambiar)
	_btn_cambiar.mouse_entered.connect(func(): _escalar_btn(_btn_cambiar, 1.04))
	_btn_cambiar.mouse_exited.connect(func(): _escalar_btn(_btn_cambiar, 1.0))
	_rec_paso3.add_child(_btn_cambiar)
	_btn_cambiar.pressed.connect(_on_cambiar_pass_pressed)

	var btn_volver_rec := _btn_link("← Volver al login", Color(0.40, 0.72, 1.0))
	vbox.add_child(btn_volver_rec)
	btn_volver_rec.pressed.connect(func(): _cambiar_panel("login"))

	vbox.add_child(HSeparator.new())
	_msg_rec = _make_msg(); vbox.add_child(_msg_rec)

	add_child(_panel_rec)


func _resetear_panel_recuperacion() -> void:
	if is_instance_valid(_rec_paso1): _rec_paso1.visible = true
	if is_instance_valid(_rec_paso2): _rec_paso2.visible = false
	if is_instance_valid(_rec_paso3): _rec_paso3.visible = false
	if is_instance_valid(_rec_codigo): _rec_codigo.text = ""
	if is_instance_valid(_rec_pass_nueva): _rec_pass_nueva.text = ""
	if is_instance_valid(_rec_pass_confirmar): _rec_pass_confirmar.text = ""


# ════════════════════════════════════════════════════════════
# CONSTRUCTOR INTERNO DE PANELES
# ════════════════════════════════════════════════════════════
func _nuevo_panel() -> VBoxContainer:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)

	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _style_panel())
	cc.add_child(pc)

	var sc := ScrollContainer.new()
	sc.custom_minimum_size        = Vector2(330, 390)
	sc.horizontal_scroll_mode     = ScrollContainer.SCROLL_MODE_DISABLED
	pc.add_child(sc)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(vbox)

	if _panel_reg == null:
		_panel_reg = root
	else:
		_panel_rec = root

	return vbox


# ════════════════════════════════════════════════════════════
# CAMBIO DE PANEL CON TRANSICIÓN
# ════════════════════════════════════════════════════════════
func _cambiar_panel(cual: String) -> void:
	var prev : Control = null
	if _center.visible:
		prev = _center
	elif is_instance_valid(_panel_reg) and _panel_reg.visible:
		prev = _panel_reg
	elif is_instance_valid(_panel_rec) and _panel_rec.visible:
		prev = _panel_rec

	var next : Control = null
	match cual:
		"login":     next = _center
		"registro":  next = _panel_reg
		"recuperar": next = _panel_rec

	_msg_login.text = ""
	if is_instance_valid(_msg_reg): _msg_reg.text = ""
	if is_instance_valid(_msg_rec): _msg_rec.text = ""
	_set_cargando(false)

	if prev != null and next != null and prev != next:
		if _tween_panel: _tween_panel.kill()
		_tween_panel = create_tween()
		_tween_panel.tween_property(prev, "modulate:a", 0.0, 0.13)
		_tween_panel.tween_callback(func():
			_center.visible    = (cual == "login")
			if is_instance_valid(_panel_reg): _panel_reg.visible = (cual == "registro")
			if is_instance_valid(_panel_rec): _panel_rec.visible = (cual == "recuperar")
			if is_instance_valid(next): next.modulate.a = 0.0
		)
		_tween_panel.tween_property(next, "modulate:a", 1.0, 0.20)
	else:
		_center.visible = (cual == "login")
		if is_instance_valid(_panel_reg): _panel_reg.visible = (cual == "registro")
		if is_instance_valid(_panel_rec): _panel_rec.visible = (cual == "recuperar")


# ════════════════════════════════════════════════════════════
# ACCIONES
# ════════════════════════════════════════════════════════════
func _on_login_pressed() -> void:
	_login_es_post_registro = false
	var email := _email_in.text.strip_edges()
	var pass_ := _pass_in.text
	if email.is_empty() or pass_.is_empty():
		_msg(_msg_login, "Completa todos los campos.", Color(0.98, 0.82, 0.12))
		_shake(_center)
		return
	if not email.contains("@"):
		_msg(_msg_login, "El correo no es válido.", Color(0.98, 0.82, 0.12))
		_shake(_center)
		return
	_set_cargando(true)
	_msg(_msg_login, "Conectando...", Color(0.65, 0.90, 0.70))
	SupabaseManager.login(email, pass_)


func _on_registro_pressed() -> void:
	var nombre   := _reg_nombre.text.strip_edges()
	var cedula   := _reg_cedula.text.strip_edges()
	var email    := _reg_email.text.strip_edges().to_lower().replace(" ", "")
	var pass_    := _reg_pass.text
	var confirm_ := _reg_confirm.text
	var carrera   := _reg_carrera.get_item_text(_reg_carrera.selected)
	var trimestre := _reg_trimestre.selected + 1

	if nombre.is_empty() or cedula.is_empty() or email.is_empty() or pass_.is_empty():
		_msg(_msg_reg, "Completa todos los campos obligatorios (*).", Color(0.98, 0.82, 0.12))
		_shake(_panel_reg); return
	var error_email := _validar_email(email)
	if not error_email.is_empty():
		_msg(_msg_reg, error_email, Color(0.98, 0.82, 0.12))
		_shake(_panel_reg); return
	if pass_.length() < 6:
		_msg(_msg_reg, "La contraseña debe tener al menos 6 caracteres.", Color(0.98, 0.82, 0.12))
		_shake(_panel_reg); return
	if pass_ != confirm_:
		_msg(_msg_reg, "Las contraseñas no coinciden.", Color(0.98, 0.82, 0.12))
		_shake(_panel_reg); return

	_set_cargando(true)
	_msg(_msg_reg, "Creando cuenta...", Color(0.65, 0.90, 0.70))
	SupabaseManager.registrar(email, pass_, {
		"nombre"  : nombre,
		"cedula"  : cedula,
		"carrera"   : carrera,
		"trimestre" : trimestre
	})


func _on_recuperar_pressed() -> void:
	var email := _rec_email.text.strip_edges()
	if email.is_empty():
		_msg(_msg_rec, "Ingresa tu correo.", Color(0.98, 0.82, 0.12))
		_shake(_panel_rec); return
	if not email.contains("@"):
		_msg(_msg_rec, "Correo no válido.", Color(0.98, 0.82, 0.12))
		_shake(_panel_rec); return
	_set_cargando(true)
	_msg(_msg_rec, "Enviando código...", Color(0.65, 0.90, 0.70))
	SupabaseManager.recuperar_contrasena(email)


func _on_verificar_codigo_pressed() -> void:
	var codigo := _rec_codigo.text.strip_edges()
	if codigo.length() != 6:
		_msg(_msg_rec, "El código tiene 6 dígitos.", Color(0.98, 0.82, 0.12))
		_shake(_panel_rec); return
	_set_cargando(true)
	_msg(_msg_rec, "Verificando...", Color(0.65, 0.90, 0.70))
	SupabaseManager.verificar_codigo_recuperacion(_rec_email.text.strip_edges(), codigo)


func _on_cambiar_pass_pressed() -> void:
	var nueva     := _rec_pass_nueva.text
	var confirmar := _rec_pass_confirmar.text
	if nueva.length() < 6:
		_msg(_msg_rec, "La contraseña debe tener al menos 6 caracteres.", Color(0.98, 0.82, 0.12))
		_shake(_panel_rec); return
	if nueva != confirmar:
		_msg(_msg_rec, "Las contraseñas no coinciden.", Color(0.98, 0.82, 0.12))
		_shake(_panel_rec); return
	_set_cargando(true)
	_msg(_msg_rec, "Actualizando contraseña...", Color(0.65, 0.90, 0.70))
	SupabaseManager.establecer_nueva_contrasena(nueva)


# ════════════════════════════════════════════════════════════
# CALLBACKS SUPABASE
# ════════════════════════════════════════════════════════════
func _en_login_exitoso(_datos: Dictionary) -> void:
	_set_cargando(false)
	_login_es_post_registro = false
	_msg(_msg_login, "¡Bienvenido al campus!", Color(0.28, 0.95, 0.45))
	await _preparar_progreso_y_entrar(_msg_login)


func _en_login_fallido(error: String, error_code: String) -> void:
	_set_cargando(false)
	if _login_es_post_registro:
		_login_es_post_registro = false
		_resolver_login_post_registro_fallido(error, error_code)
		return
	_msg(_msg_login, error, Color(0.95, 0.30, 0.30))
	_shake(_center)


# El registro sí guardó sesión (signup devolvió access_token) — entrar
# directo, sin ningún mensaje de error de por medio.
func _en_registro_exitoso(_usuario: Dictionary) -> void:
	_set_cargando(false)
	_msg(_msg_reg, "¡Cuenta creada! Entrando al campus...", Color(0.28, 0.95, 0.45))
	await get_tree().create_timer(1.0).timeout
	await _preparar_progreso_y_entrar(_msg_reg)


# Ata el guardado local de NivelManager a la cuenta que acaba de iniciar
# sesión — antes era un único archivo global sin distinguir cuenta, así
# que una cuenta nueva en una máquina con progreso previo arrancaba
# viendo el campus como si todo estuviera completado. Después reconstruye
# el estado real desde misiones_estudiante (la fuente de verdad del
# servidor), necesario cuando el estudiante juega desde una máquina sin
# save local. Con timeout y fail-open: si no hay red, entra igual con lo
# que haya en el archivo local en vez de trabar al estudiante acá.
func _preparar_progreso_y_entrar(msg_lbl: Label) -> void:
	# Estas trazas son permanentes a propósito: en el export web no hay
	# panel de Salida del editor al que recurrir, y cuando el progreso no
	# aparece esto es lo único que distingue "el servidor no contestó" de
	# "contestó vacío" de "ni siquiera hay sesión". Salen en la consola del
	# navegador (F12).
	print("SceneLogin: user_id='%s' jwt=%s" % [
		SupabaseManager.user_id,
		"si" if not SupabaseManager.jwt_token.is_empty() else "NO",
	])
	NivelManager.iniciar_sesion(SupabaseManager.user_id)
	_msg(msg_lbl, "Cargando tu progreso...", Color(0.65, 0.90, 0.70))
	var lista = await _cargar_misiones_con_timeout()
	if lista is Array:
		print("SceneLogin: el servidor devolvió %d misiones completadas" % lista.size())
		NivelManager.repoblar_desde_servidor(lista)
	else:
		push_warning("SceneLogin: no se pudo recuperar el progreso del servidor "
			+ "(sin red o tardó más de 8 s). Se entra con el guardado local.")

	# EcoCredits, inventario de la tienda y mejoras de zona (HU-012). Se
	# espera, con límite, para que el mapa arranque con el saldo real y las
	# zonas ya mejoradas; si no llega, el mapa se actualiza solo cuando llegue.
	EconomiaManager.iniciar_sesion()
	var billetera_ok : bool = await _esperar_billetera_con_timeout()
	print("SceneLogin: billetera %s (saldo=%d, items=%d)" % [
		"cargada" if billetera_ok else "NO cargada a tiempo",
		EconomiaManager.ecocredits, EconomiaManager.inventario.size()])

	# Detalles (decisiones con criterio propio) y puntaje GreenMetric. Los
	# detalles se esperan con límite: el informe final los necesita y antes
	# vivían solo en esta computadora. El puntaje no se espera: el HUD se
	# actualiza solo cuando llega (PuntajeManager.puntaje_actualizado).
	var detalles = await _esperar_detalles_con_timeout()
	if detalles is Dictionary:
		PuntajeManager.restaurar_detalles(detalles)
	print("SceneLogin: detalles %s" % (
		"%d del servidor" % detalles.size() if detalles is Dictionary else "NO cargados a tiempo"))
	PuntajeManager.iniciar_sesion()

	var tw := create_tween()
	tw.tween_property(_center, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/mapa/scene_mapa_mundo.tscn"))


# Pide misiones_estudiante y espera su respuesta (o error_red, o 8s de
# timeout) sin usar `await` directo sobre una señal — necesitamos poder
# "ganar" con la que llegue primero entre dos señales distintas más un
# límite de tiempo, y GDScript no tiene un await-de-varias-señales nativo.
# Devuelve el Array de filas, o null si falló/no hubo respuesta a tiempo.
func _esperar_billetera_con_timeout() -> bool:
	var limite := Time.get_ticks_msec() + 6000
	while not EconomiaManager.billetera_cargada and Time.get_ticks_msec() < limite:
		await get_tree().process_frame
	return EconomiaManager.billetera_cargada


# Devuelve {clave: detalle} o null si no llegó en 6 s. Mismo patrón de
# Dictionary por referencia que _cargar_misiones_con_timeout: las lambdas
# capturan variables simples por valor, así que el estado se guarda en un
# Dictionary (tipo por referencia) para que el bucle de abajo lo vea.
func _esperar_detalles_con_timeout() -> Variant:
	var estado := {"resuelto": false, "resultado": null}
	var on_ok := func(d: Dictionary):
		estado["resuelto"]  = true
		estado["resultado"] = d
	SupabaseManager.detalles_recibidos.connect(on_ok, CONNECT_ONE_SHOT)
	SupabaseManager.obtener_detalles()
	var limite := Time.get_ticks_msec() + 6000
	while not estado["resuelto"] and Time.get_ticks_msec() < limite:
		await get_tree().process_frame
	if SupabaseManager.detalles_recibidos.is_connected(on_ok):
		SupabaseManager.detalles_recibidos.disconnect(on_ok)
	return estado["resultado"]


func _cargar_misiones_con_timeout() -> Variant:
	SupabaseManager.cargar_misiones_estudiante()

	# Dictionary, no bool/Variant sueltos: las lambdas de GDScript capturan
	# variables locales simples POR VALOR, no por referencia — escribir
	# "resuelto = true" dentro de la lambda no se reflejaba afuera, así que
	# el bucle de abajo nunca veía el cambio y siempre esperaba el timeout
	# completo devolviendo null, aunque la respuesta ya hubiera llegado
	# bien. Un Dictionary es un tipo por referencia: mutar sus claves desde
	# la lambda sí es visible aquí afuera.
	var estado := {"resuelto": false, "resultado": null}
	var on_ok := func(lista: Array):
		estado["resuelto"]  = true
		estado["resultado"] = lista
	var on_err := func(_msg: String):
		estado["resuelto"]  = true
		estado["resultado"] = null

	SupabaseManager.misiones_estudiante_cargadas.connect(on_ok, CONNECT_ONE_SHOT)
	SupabaseManager.error_red.connect(on_err, CONNECT_ONE_SHOT)

	var limite := Time.get_ticks_msec() + 8000
	while not estado["resuelto"] and Time.get_ticks_msec() < limite:
		await get_tree().process_frame

	if SupabaseManager.misiones_estudiante_cargadas.is_connected(on_ok):
		SupabaseManager.misiones_estudiante_cargadas.disconnect(on_ok)
	if SupabaseManager.error_red.is_connected(on_err):
		SupabaseManager.error_red.disconnect(on_err)

	return estado["resultado"]


# El signup respondió 200 pero sin sesión (con "user" legible o con el
# cuerpo ilegible — a esta altura da igual cuál). En vez de adivinar el
# estado de la cuenta, probamos loguearnos con las credenciales que ya
# están en los campos del formulario y actuamos según ESA respuesta.
func _en_registro_sin_sesion() -> void:
	_msg(_msg_reg, "Verificando tu cuenta...", Color(0.65, 0.90, 0.70))
	_login_es_post_registro = true
	var email := _reg_email.text.strip_edges().to_lower().replace(" ", "")
	SupabaseManager.login(email, _reg_pass.text)


func _en_registro_fallido(error: String) -> void:
	_set_cargando(false)
	_msg(_msg_reg, error, Color(0.95, 0.30, 0.30))
	_shake(_panel_reg)


# Falló el login automático post-registro. La cuenta se creó igual (el
# signup devolvió 200) — nunca mostramos esto como error, y precargamos
# el correo en el panel de login para que solo falte la contraseña.
func _resolver_login_post_registro_fallido(error: String, error_code: String) -> void:
	var email := _reg_email.text.strip_edges().to_lower().replace(" ", "")
	var msg   : String
	var color : Color
	if _es_error_correo_no_confirmado(error, error_code):
		msg   = "Cuenta creada. Te enviamos un correo para confirmarla. Confirmala y volvé a iniciar sesión acá."
		color = Color(0.28, 0.95, 0.45)   # mismo verde de éxito que ya usa el formulario
	else:
		msg   = "Tu cuenta se creó. Iniciá sesión para entrar."
		color = Color(0.65, 0.90, 0.70)   # mismo neutro que "Conectando..." / "Creando cuenta..."
	_cambiar_panel("login")
	_email_in.text = email
	_msg(_msg_login, msg, color)


# Verificado en la documentación oficial de Supabase: el error de
# /auth/v1/token?grant_type=password trae "error_code": "email_not_confirmed"
# cuando la cuenta existe pero el correo no está confirmado — ese código
# es la condición principal, tal como recomienda la doc (branchear por
# código, no por mensaje, porque el texto cambia entre versiones).
# El matching de texto queda solo como respaldo secundario, por si el
# servidor no manda error_code (respuesta vieja o malformada).
func _es_error_correo_no_confirmado(error: String, error_code: String) -> bool:
	if error_code == "email_not_confirmed":
		return true
	var e := error.to_lower()
	return e.contains("not confirmed") or e.contains("not_confirmed") or e.contains("confirm")


func _en_recuperacion_enviada() -> void:
	_set_cargando(false)
	_msg(_msg_rec,
		"¡Código enviado!\nRevisa tu bandeja y la carpeta de spam.",
		Color(0.28, 0.95, 0.45))
	_rec_paso1.visible = false
	_rec_paso2.visible = true


func _en_recuperacion_fallida(error: String) -> void:
	_set_cargando(false)
	_msg(_msg_rec, error, Color(0.95, 0.30, 0.30))


func _en_codigo_verificado() -> void:
	_set_cargando(false)
	_msg(_msg_rec, "", Color.WHITE)
	_rec_paso2.visible = false
	_rec_paso3.visible = true


func _en_codigo_fallido(error: String) -> void:
	_set_cargando(false)
	_msg(_msg_rec, error, Color(0.95, 0.30, 0.30))
	_shake(_panel_rec)


func _en_contrasena_actualizada() -> void:
	_set_cargando(false)
	_msg(_msg_rec, "¡Contraseña actualizada! Ya puedes iniciar sesión.", Color(0.28, 0.95, 0.45))
	await get_tree().create_timer(2.5).timeout
	_resetear_panel_recuperacion()
	_cambiar_panel("login")


func _en_actualizar_contrasena_fallido(error: String) -> void:
	_set_cargando(false)
	_msg(_msg_rec, error, Color(0.95, 0.30, 0.30))
	_shake(_panel_rec)


func _en_error_red(mensaje: String) -> void:
	_set_cargando(false)
	# Se muestra el mensaje completo, no un "Sin conexión." pelado: el código
	# que trae adentro es lo único que distingue un problema de red real de
	# un 401/403 del servidor, y sin él no hay forma de diagnosticar nada en
	# el export web.
	push_error("SceneLogin: error de red -> " + mensaje)
	_msg(_msg_login, mensaje, Color(0.95, 0.30, 0.30))
	if is_instance_valid(_msg_reg): _msg_reg.text = "Sin conexión: " + mensaje
	if is_instance_valid(_msg_rec): _msg_rec.text = "Sin conexión."


# ════════════════════════════════════════════════════════════
# HELPERS UI
# ════════════════════════════════════════════════════════════
func _set_cargando(estado: bool) -> void:
	_cargando           = estado
	_btn_login.disabled = estado
	if is_instance_valid(_btn_crear):  _btn_crear.disabled  = estado
	if is_instance_valid(_btn_enviar): _btn_enviar.disabled = estado
	if is_instance_valid(_spinner_label):
		_spinner_label.visible = estado
	if estado:
		_spinner_idx   = 0
		_spinner_timer = 0.0


# Devuelve "" si el correo es válido, o el mensaje de error a mostrar.
# Recibe el correo ya normalizado (minúsculas, sin espacios) — normalizar
# es responsabilidad de quien llama, para no normalizar dos veces.
func _validar_email(email: String) -> String:
	if not _re_email.search(email):
		return "Ese correo no parece válido. Revisá que tenga @ y un dominio."
	var dominio := email.split("@")[-1]
	if not (dominio in DOMINIOS_PERMITIDOS):
		return "Usá tu correo @urbe.edu, o uno de Gmail, Outlook, Hotmail, Yahoo o iCloud."
	return ""


func _msg(label: Label, texto: String, color: Color) -> void:
	if not is_instance_valid(label): return
	label.text     = texto
	label.modulate = Color.WHITE
	label.add_theme_color_override("font_color", color)
	var tw := create_tween()
	tw.tween_property(label, "scale", Vector2(1.05, 1.05), 0.08)
	tw.tween_property(label, "scale", Vector2(1.0, 1.0),   0.10)


func _shake(node: Control) -> void:
	if not is_instance_valid(node): return
	var tw := create_tween()
	tw.tween_property(node, "modulate", Color(1.0, 0.55, 0.55, 1.0), 0.07)
	tw.tween_property(node, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.28)


func _titulo(vbox: VBoxContainer, texto: String) -> void:
	var l := Label.new()
	l.text = "🌿  " + texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(0.35, 0.95, 0.50))
	vbox.add_child(l)


func _lbl(vbox: VBoxContainer, texto: String) -> void:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(0.62, 0.78, 0.65))
	vbox.add_child(l)


func _lbl_sec(vbox: VBoxContainer, texto: String) -> void:
	var l := Label.new()
	l.text = "▸ " + texto
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color(0.30, 0.78, 0.42))
	vbox.add_child(l)


func _campo(vbox: VBoxContainer, placeholder: String,
			secreto: bool = false) -> LineEdit:
	var le := LineEdit.new()
	le.placeholder_text      = placeholder
	le.secret                = secreto
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_estilizar_input(le)
	vbox.add_child(le)
	return le


func _make_msg() -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode        = TextServer.AUTOWRAP_WORD
	l.add_theme_font_size_override("font_size", 12)
	return l
