# ============================================================
# mision_comite_ambiental.gd — NIVEL 6: Educación e Investigación
# Misión "Recluta tu comité" (ED5 — actividades de organizaciones
# estudiantiles). Cinco estudiantes, cada uno con una objeción;
# solo un argumento por estudiante funciona, y es siempre uno que
# cita algo concreto que el jugador ya logró en Niveles 1-5 —
# la lección: los datos convencen, las apelaciones genéricas no.
# ============================================================
extends CanvasLayer

signal comite_completada(mision_id: String, xp: int, ec: int)

const ESTUDIANTES : Array = [
	{
		"id": "camila", "nombre": "Camila", "icono": "🌱", "nivel_ref": 1,
		"objecion": "\"Sembrar unas matas no va a cambiar el cambio climático, eso es puro simbolismo.\"",
		"opciones": [
			{"texto": "En este campus ya hay 6 zonas de siembra activas — cada árbol adulto captura hasta 22 kg de CO₂ al año, y ya se está midiendo.", "correcta": true},
			{"texto": "Tienes razón, es más que todo simbólico, pero ayuda a la imagen de la universidad.", "correcta": false},
			{"texto": "Es una obligación ambiental que toda universidad debería cumplir.", "correcta": false},
		],
		"feedback_ok": "Camila se une al comité — le convenció el dato concreto, no la consigna.",
	},
	{
		"id": "diego", "nombre": "Diego", "icono": "⚡", "nivel_ref": 2,
		"objecion": "\"Apagar unas luces no ahorra nada comparado con lo que gasta toda la universidad.\"",
		"opciones": [
			{"texto": "Todos deberíamos hacer un esfuerzo, así sea pequeño.", "correcta": false},
			{"texto": "Los paneles solares del Rectorado y el estacionamiento ya generan ~14.400 kWh al año entre los dos — es energía real, no gesto.", "correcta": true},
			{"texto": "La universidad ya paga la electricidad, no es nuestro problema.", "correcta": false},
		],
		"feedback_ok": "Diego se une al comité — los kWh medibles pesan más que el gesto simbólico.",
	},
	{
		"id": "valentina", "nombre": "Valentina", "icono": "♻", "nivel_ref": 3,
		"objecion": "\"Yo he visto que todo el reciclaje termina en el mismo camión de basura.\"",
		"opciones": [
			{"texto": "No hay que preocuparse, la universidad se encarga de eso.", "correcta": false},
			{"texto": "Puede que antes fuera así, pero seguro que ahora ya cambió.", "correcta": false},
			{"texto": "El campus ya tiene puntos de reciclaje separados por tipo en 6 ubicaciones con servicio real de retiro — lo puedes verificar tú misma.", "correcta": true},
		],
		"feedback_ok": "Valentina se une al comité — verificar de primera mano vale más que la sospecha.",
	},
	{
		"id": "andres", "nombre": "Andrés", "icono": "💧", "nivel_ref": 4,
		"objecion": "\"El agua no se acaba, siempre va a haber en el grifo.\"",
		"opciones": [
			{"texto": "Deberíamos ser más conscientes con el planeta.", "correcta": false},
			{"texto": "Eso no depende de nosotros, es problema del gobierno.", "correcta": false},
			{"texto": "El campus ya cerró fugas activas en 6 puntos y capta agua de lluvia en 2 techos — cada gota ahorrada reduce un costo real y medible.", "correcta": true},
		],
		"feedback_ok": "Andrés se une al comité — el ahorro medible convence más que la conciencia abstracta.",
	},
	{
		"id": "sofia", "nombre": "Sofía", "icono": "🚲", "nivel_ref": 5,
		"objecion": "\"El carro es mucho más cómodo, a nadie le importa la bicicleta.\"",
		"opciones": [
			{"texto": "Cómodo sí, pero ya hay bicicleteros nuevos y hasta un día sin carros en el campus — cada vehículo que se deja en casa reduce emisiones que ya se están midiendo.", "correcta": true},
			{"texto": "Deberíamos pensar más en el planeta que en la comodidad.", "correcta": false},
			{"texto": "Eso es decisión personal de cada quien.", "correcta": false},
		],
		"feedback_ok": "Sofía se une al comité — la evidencia concreta gana, no el llamado a la culpa.",
	},
]

const MISION_ID : String = "comite_ambiental"

# ── Estado ───────────────────────────────────────────────────
var _punto_ref     : Area2D = null
var _convencidos   : Array  = []   # Array[String] ids de estudiantes ya ganados
var _idx_actual    : int    = 0
var _opcion_sel    : int    = -1
var _intentos      : int    = 0   # intentos en el estudiante actual (para medir aprendizaje por repetición)

# ── Nodos UI ─────────────────────────────────────────────────
var _panel_root    : Panel   = null
var _contador_lbl  : Label   = null
var _nombre_lbl    : Label   = null
var _objecion_lbl  : Label   = null
var _feedback_lbl  : Label   = null
var _opciones_cont : VBoxContainer = null
var _opcion_btns   : Array   = []


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _ready() -> void:
	layer = 20
	_crear_ui()
	hide()


func iniciar(punto_node: Area2D) -> void:
	_punto_ref = punto_node
	var nm = _nivel_mgr()
	_convencidos = []
	if nm:
		var det : Dictionary = nm.obtener_detalle(MISION_ID)
		_convencidos = det.get("convencidos", []).duplicate()
	_idx_actual = _proximo_pendiente()
	if _idx_actual == -1:
		return  # ya están todos convencidos (no debería pasar, el punto se marca completado)
	_opcion_sel = -1
	_mostrar_estudiante()
	show()
	SupabaseManager.registrar_evento(6, MISION_ID, "mision_iniciada")
	var hb = get_tree().get_first_node_in_group("hint_bubble")
	if hb:
		hb.push("primer_comite",
			"🗣 Cada estudiante solo se convence con un argumento: el que cita algo real que ya lograste en el campus.")


func _proximo_pendiente() -> int:
	for i in ESTUDIANTES.size():
		var e : Dictionary = ESTUDIANTES[i]
		if not (e["id"] in _convencidos):
			return i
	return -1


func _mostrar_estudiante() -> void:
	var e : Dictionary = ESTUDIANTES[_idx_actual]
	_contador_lbl.text = "Comité Ambiental — %d/%d estudiantes" % [_convencidos.size(), ESTUDIANTES.size()]
	_nombre_lbl.text   = "%s  %s" % [e["icono"], e["nombre"]]
	_objecion_lbl.text = e["objecion"]
	_feedback_lbl.text = ""
	_opcion_sel = -1
	_intentos   = 0
	for child in _opciones_cont.get_children():
		child.queue_free()
	_opcion_btns = []
	var opciones : Array = (e["opciones"] as Array).duplicate()
	opciones.shuffle()
	for op : Dictionary in opciones:
		var btn := Button.new()
		btn.text = op["texto"]
		btn.custom_minimum_size = Vector2(0, 54)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD
		btn.add_theme_font_size_override("font_size", 12)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var sb := StyleBoxFlat.new()
		sb.bg_color     = Color(0.08, 0.08, 0.10)
		sb.border_color = Color(0.40, 0.35, 0.30)
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 10; sb.content_margin_right = 10
		sb.content_margin_top = 6; sb.content_margin_bottom = 6
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.pressed.connect(_on_elegir_opcion.bind(bool(op["correcta"]), op["texto"]))
		_opciones_cont.add_child(btn)
		_opcion_btns.append(btn)


func _on_elegir_opcion(correcta: bool, texto: String) -> void:
	for btn in _opcion_btns:
		(btn as Button).disabled = true
	_intentos += 1
	var estudiante_id : String = ESTUDIANTES[_idx_actual]["id"]
	SupabaseManager.registrar_evento(6, MISION_ID, "opcion_elegida",
		{"estudiante": estudiante_id, "texto": texto}, correcta, _intentos)
	if correcta:
		var e : Dictionary = ESTUDIANTES[_idx_actual]
		_feedback_lbl.text = "✅ " + String(e["feedback_ok"])
		_feedback_lbl.add_theme_color_override("font_color", Color(0.40, 0.90, 0.45))
		_convencidos.append(e["id"])
		var nm = _nivel_mgr()
		if nm:
			nm.guardar_detalle(MISION_ID, {"convencidos": _convencidos})
		if is_instance_valid(_punto_ref) and _punto_ref.has_method("_actualizar_contador"):
			_punto_ref.call("_actualizar_contador", _convencidos.size())
		await get_tree().create_timer(1.6).timeout
		var sig := _proximo_pendiente()
		if sig == -1:
			_completar_mision()
		else:
			_idx_actual = sig
			_mostrar_estudiante()
	else:
		_feedback_lbl.text = "❌ No lo convence — le suena a discurso genérico. Prueba con algo concreto que ya hicieron en el campus."
		_feedback_lbl.add_theme_color_override("font_color", Color(0.95, 0.45, 0.35))
		await get_tree().create_timer(1.4).timeout
		for btn in _opcion_btns:
			(btn as Button).disabled = false
		_feedback_lbl.text = ""


func _completar_mision() -> void:
	var nm = _nivel_mgr()
	var nombres : Array = []
	for e in ESTUDIANTES:
		nombres.append(e["nombre"])
	if nm:
		nm.completar_mision(6, MISION_ID)
		nm.guardar_detalle(MISION_ID, {"convencidos": _convencidos, "miembros": nombres})
	if is_instance_valid(_punto_ref) and _punto_ref.has_method("_marcar_completado"):
		_punto_ref._marcar_completado()
	var xp : int = int(nm.XP_POR_MISION.get(6, 70)) if nm else 70
	var ec : int = int(nm.EC_POR_MISION.get(6, 20)) if nm else 20
	SupabaseManager.registrar_evento(6, MISION_ID, "mision_completada", {"miembros": nombres})
	comite_completada.emit(MISION_ID, xp, ec)
	_mostrar_confirmacion(xp, ec)


func _on_salir() -> void:
	var tw := create_tween()
	tw.tween_property(_panel_root, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func(): hide(); _panel_root.modulate.a = 1.0)


func _mostrar_confirmacion(xp: int, ec: int) -> void:
	var cel := Panel.new()
	cel.set_anchors_preset(Control.PRESET_CENTER)
	cel.custom_minimum_size = Vector2(480, 240)
	cel.offset_left  = -240.0; cel.offset_top    = -120.0
	cel.offset_right =  240.0; cel.offset_bottom =  120.0
	var cps := StyleBoxFlat.new()
	cps.bg_color     = Color(0.09, 0.06, 0.02, 0.98)
	cps.border_color = Color(0.90, 0.62, 0.15)
	cps.set_border_width_all(3)
	cps.set_corner_radius_all(16)
	cps.shadow_color = Color(0.45, 0.28, 0.05, 0.55)
	cps.shadow_size  = 24
	cel.add_theme_stylebox_override("panel", cps)
	add_child(cel)
	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(k, 20)
	cel.add_child(mg)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 8)
	mg.add_child(vb)
	var tit := Label.new()
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.add_theme_font_size_override("font_size", 19)
	tit.add_theme_color_override("font_color", Color(0.98, 0.75, 0.20))
	tit.text = "🗣 ¡Comité Ambiental formado!"
	vb.add_child(tit)
	var det := Label.new()
	det.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	det.autowrap_mode = TextServer.AUTOWRAP_WORD
	det.add_theme_font_size_override("font_size", 12)
	det.add_theme_color_override("font_color", Color(0.85, 0.80, 0.70))
	det.text = "Camila, Diego, Valentina, Andrés y Sofía se unieron — convencidos con datos reales del campus, no con discursos."
	vb.add_child(det)
	var xp_lbl := Label.new()
	xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	xp_lbl.add_theme_font_size_override("font_size", 16)
	xp_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.18))
	xp_lbl.text = "+%d XP  ·  +%d EcoCredits" % [xp, ec]
	vb.add_child(xp_lbl)
	cel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(cel, "modulate:a", 1.0, 0.25)
	tw.tween_interval(3.2)
	tw.tween_property(cel, "modulate:a", 0.0, 0.30)
	tw.tween_callback(func():
		cel.queue_free()
		_on_salir())


# ── Crear UI ──────────────────────────────────────────────────
func _crear_ui() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color        = Color(0.0, 0.0, 0.0, 0.88)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	_panel_root = Panel.new()
	_panel_root.custom_minimum_size = Vector2(760, 560)
	_panel_root.set_anchors_preset(Control.PRESET_CENTER)
	_panel_root.offset_left   = -380.0
	_panel_root.offset_top    = -280.0
	_panel_root.offset_right  =  380.0
	_panel_root.offset_bottom =  280.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.07, 0.06, 0.04, 0.98)
	ps.border_color = Color(0.90, 0.62, 0.15)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(18)
	ps.shadow_color = Color(0.45, 0.28, 0.05, 0.50)
	ps.shadow_size  = 28
	_panel_root.add_theme_stylebox_override("panel", ps)
	add_child(_panel_root)

	var acento := ColorRect.new()
	acento.set_anchors_preset(Control.PRESET_TOP_WIDE)
	acento.custom_minimum_size = Vector2(0, 4)
	acento.offset_bottom       = 4.0
	acento.color               = Color(0.95, 0.65, 0.15, 0.85)
	acento.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	_panel_root.add_child(acento)

	var btn_salir := Button.new()
	btn_salir.text = "✕ Salir"
	btn_salir.custom_minimum_size = Vector2(80, 30)
	btn_salir.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_salir.offset_left   = -92.0
	btn_salir.offset_top    =  8.0
	btn_salir.offset_right  = -8.0
	btn_salir.offset_bottom =  38.0
	btn_salir.add_theme_font_size_override("font_size", 11)
	var bss := StyleBoxFlat.new()
	bss.bg_color = Color(0.18, 0.06, 0.06, 0.90)
	bss.border_color = Color(0.65, 0.15, 0.15)
	bss.set_border_width_all(2)
	bss.set_corner_radius_all(8)
	btn_salir.add_theme_stylebox_override("normal", bss)
	btn_salir.add_theme_color_override("font_color", Color(0.92, 0.50, 0.50))
	btn_salir.pressed.connect(_on_salir)
	_panel_root.add_child(btn_salir)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(k, 18)
	_panel_root.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	mg.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var titulo_fijo := Label.new()
	titulo_fijo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo_fijo.add_theme_font_size_override("font_size", 17)
	titulo_fijo.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	titulo_fijo.text = "🗣  Mesa del Comité Ambiental"
	header.add_child(titulo_fijo)

	var badge := Label.new()
	badge.text = "🎓 NIVEL 6 — Educación e Investigación"
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color", Color(0.90, 0.68, 0.25))
	header.add_child(badge)
	# El botón Salir está fijo en la esquina (fuera del VBox): se le guarda
	# su lugar para que el letrero del nivel no quede debajo de él.
	var lugar_salir := Control.new()
	lugar_salir.custom_minimum_size = Vector2(84, 0)
	header.add_child(lugar_salir)

	_contador_lbl = Label.new()
	_contador_lbl.add_theme_font_size_override("font_size", 12)
	_contador_lbl.add_theme_color_override("font_color", Color(0.75, 0.70, 0.60))
	vbox.add_child(_contador_lbl)

	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.90, 0.62, 0.15, 0.30)
	sep_s.content_margin_top    = 1.0
	sep_s.content_margin_bottom = 1.0
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", sep_s)
	vbox.add_child(sep)

	_nombre_lbl = Label.new()
	_nombre_lbl.add_theme_font_size_override("font_size", 18)
	_nombre_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.60))
	vbox.add_child(_nombre_lbl)

	_objecion_lbl = Label.new()
	_objecion_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_objecion_lbl.add_theme_font_size_override("font_size", 14)
	_objecion_lbl.add_theme_color_override("font_color", Color(0.80, 0.78, 0.72))
	vbox.add_child(_objecion_lbl)

	var op_titulo := Label.new()
	op_titulo.text = "¿Con qué le respondes?"
	op_titulo.add_theme_font_size_override("font_size", 11)
	op_titulo.add_theme_color_override("font_color", Color(0.60, 0.58, 0.52))
	vbox.add_child(op_titulo)

	_opciones_cont = VBoxContainer.new()
	_opciones_cont.add_theme_constant_override("separation", 8)
	vbox.add_child(_opciones_cont)

	_feedback_lbl = Label.new()
	_feedback_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_feedback_lbl.add_theme_font_size_override("font_size", 12)
	_feedback_lbl.custom_minimum_size = Vector2(0, 36)
	vbox.add_child(_feedback_lbl)
