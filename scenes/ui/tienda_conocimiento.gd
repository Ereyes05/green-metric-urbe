# ============================================================
# tienda_conocimiento.gd — URBE Rangers: Eco-Quest
# HU-012 "Gestionar EcoCredits en la tienda" (Cap. 4 de la tesis).
#
# Solo muestra y pide: el catálogo, el saldo y las compras viven en el
# servidor (sql/tienda_ecocredits.sql) y los maneja EconomiaManager. Una
# compra se refleja recién cuando el servidor la confirma, porque los
# criterios de aceptación (saldo, precio fijo, no recompra) los valida él.
# ============================================================
extends CanvasLayer

const COLOR_BORDE     := Color(0.20, 0.80, 0.95)
const COLOR_OK        := Color(0.30, 0.95, 0.45)
const COLOR_ERROR     := Color(1.0, 0.40, 0.40)
const COLOR_AVISO     := Color(1.0, 0.80, 0.25)
const NOMBRE_TIPO_MISION := {
	"solar": "las misiones de paneles solares (Nivel 2)",
	"captacion": "las misiones de captación de lluvia (Nivel 4)",
	"bicicletero": "las misiones de bicicleteros (Nivel 5)",
}

var _panel       : Panel         = null
var _saldo_lbl   : Label         = null
var _filas_vbox  : VBoxContainer = null
var _scroll      : ScrollContainer = null
var _mensaje_lbl : Label         = null
var _comprando   : bool          = false
# Ítem opcional que el estudiante ya intentó comprar una vez y recibió el
# aviso de que se quedaría sin EC para una herramienta obligatoria.
var _confirmando : String        = ""
var _resaltado   : String        = ""


func _ready() -> void:
	layer = 25
	add_to_group("ui_tienda")   # jugador.gd deja de moverse mientras está visible
	_crear_ui()
	hide()
	EconomiaManager.ecocredits_cambiados.connect(func(_t): _actualizar_saldo())
	EconomiaManager.inventario_cambiado.connect(_reconstruir)
	EconomiaManager.catalogo_listo.connect(_reconstruir)
	EconomiaManager.compra_terminada.connect(_on_compra_terminada)


# item_resaltado: se usa al llegar desde una misión bloqueada, para señalar
# qué herramienta hace falta.
func abrir(item_resaltado: String = "") -> void:
	_resaltado   = item_resaltado
	_confirmando = ""
	_mensaje("", Color.WHITE)
	if EconomiaManager.catalogo.is_empty() and not SupabaseManager.jwt_token.is_empty():
		SupabaseManager.cargar_catalogo()
	_reconstruir()
	_actualizar_saldo()
	show()


func cerrar() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cerrar()


# ── Construcción ──────────────────────────────────────────────
func _crear_ui() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	overlay.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed: cerrar())
	add_child(overlay)

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left   = -350.0
	_panel.offset_top    = -300.0
	_panel.offset_right  =  350.0
	_panel.offset_bottom =  300.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.06, 0.10, 0.99)
	ps.border_color = COLOR_BORDE
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(16)
	ps.shadow_color = Color(0.10, 0.55, 0.70, 0.45)
	ps.shadow_size  = 24
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		mg.add_theme_constant_override(m, 22)
	_panel.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	mg.add_child(vbox)

	# Encabezado: título, saldo y cerrar
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var titulo := Label.new()
	titulo.text = "🛒  Tienda del Conocimiento"
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.add_theme_font_size_override("font_size", 20)
	titulo.add_theme_color_override("font_color", COLOR_BORDE)
	header.add_child(titulo)

	_saldo_lbl = Label.new()
	_saldo_lbl.add_theme_font_size_override("font_size", 18)
	_saldo_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.30))
	header.add_child(_saldo_lbl)

	var sep := Control.new()
	sep.custom_minimum_size = Vector2(12, 0)
	header.add_child(sep)

	var btn_cerrar := Button.new()
	btn_cerrar.text = "✕"
	btn_cerrar.custom_minimum_size = Vector2(34, 34)
	btn_cerrar.pressed.connect(cerrar)
	header.add_child(btn_cerrar)

	var sub := Label.new()
	sub.text = "Invertí los EcoCredits que ganás cuidando el campus."
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.65, 0.75, 0.80))
	vbox.add_child(sub)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(_scroll)

	_filas_vbox = VBoxContainer.new()
	_filas_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filas_vbox.add_theme_constant_override("separation", 8)
	_scroll.add_child(_filas_vbox)

	_mensaje_lbl = Label.new()
	_mensaje_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mensaje_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	_mensaje_lbl.custom_minimum_size = Vector2(0, 38)
	_mensaje_lbl.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_mensaje_lbl)


func _reconstruir() -> void:
	if _filas_vbox == null: return
	for h in _filas_vbox.get_children():
		h.queue_free()

	if SupabaseManager.jwt_token.is_empty():
		_agregar_texto("Iniciá sesión para usar la tienda.", Color(0.8, 0.8, 0.8))
		return
	if EconomiaManager.catalogo.is_empty():
		_agregar_texto("Cargando catálogo...", Color(0.8, 0.8, 0.8))
		return

	var secciones := [
		["herramienta",  "🔧  Herramientas — necesarias para algunas misiones"],
		["bonificacion", "✨  Bonificaciones"],
		["avatar",       "🎨  Tu Eco-Ranger"],
	]
	var fila_resaltada : Control = null
	for sec in secciones:
		var items := EconomiaManager.catalogo.filter(func(it): return str(it.get("tipo", "")) == sec[0])
		if items.is_empty(): continue
		_agregar_texto(sec[1], COLOR_BORDE, 15)
		for it in items:
			var fila := _crear_fila(it)
			_filas_vbox.add_child(fila)
			if str(it.get("item_id", "")) == _resaltado:
				fila_resaltada = fila
	if fila_resaltada:
		_scroll.ensure_control_visible.call_deferred(fila_resaltada)


func _agregar_texto(texto: String, color: Color, tam: int = 14) -> void:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	_filas_vbox.add_child(l)


func _crear_fila(it: Dictionary) -> Control:
	var item_id  := str(it.get("item_id", ""))
	var precio   := int(it.get("precio", 0))
	var comprado := EconomiaManager.tiene_item(item_id)

	var caja := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.10, 0.14, 0.95)
	sb.border_color = COLOR_AVISO if item_id == _resaltado else Color(0.18, 0.28, 0.34)
	sb.set_border_width_all(2 if item_id == _resaltado else 1)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12; sb.content_margin_right = 12
	sb.content_margin_top = 8;   sb.content_margin_bottom = 8
	caja.add_theme_stylebox_override("panel", sb)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	caja.add_child(hb)

	var icono := Label.new()
	icono.text = str(it.get("icono", "•"))
	icono.custom_minimum_size = Vector2(40, 0)
	icono.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icono.add_theme_font_size_override("font_size", 28)
	hb.add_child(icono)

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(textos)
	var nombre := Label.new()
	nombre.text = str(it.get("nombre", item_id))
	nombre.add_theme_font_size_override("font_size", 15)
	nombre.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	textos.add_child(nombre)
	var desc := Label.new()
	desc.text = str(it.get("descripcion", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.68, 0.76, 0.82))
	textos.add_child(desc)
	var requerido := str(it.get("requerido_para", ""))
	if requerido != "" and requerido != "<null>":
		var req := Label.new()
		req.text = "Necesaria para " + str(NOMBRE_TIPO_MISION.get(requerido, requerido))
		req.add_theme_font_size_override("font_size", 11)
		req.add_theme_color_override("font_color", COLOR_AVISO)
		textos.add_child(req)

	var der := VBoxContainer.new()
	der.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(der)
	var precio_lbl := Label.new()
	precio_lbl.text = "💰 %d EC" % precio
	precio_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	precio_lbl.add_theme_font_size_override("font_size", 14)
	precio_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.30))
	der.add_child(precio_lbl)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(120, 32)
	btn.add_theme_font_size_override("font_size", 14)
	# Botón de contorno verde, mismo lenguaje visual que el LOGIN; gris cuando
	# ya está comprado. Sin estilo propio parecía texto plano, no un botón.
	var mk := func(borde: Color, fondo: Color) -> StyleBoxFlat:
		var s := StyleBoxFlat.new()
		s.bg_color = fondo
		s.border_color = borde
		s.set_border_width_all(2)
		s.set_corner_radius_all(8)
		return s
	var verde := Color(0.30, 0.90, 0.45)
	btn.add_theme_stylebox_override("normal",   mk.call(verde, Color(0.06, 0.12, 0.08)))
	btn.add_theme_stylebox_override("hover",    mk.call(verde.lightened(0.3), Color(0.10, 0.22, 0.13)))
	btn.add_theme_stylebox_override("pressed",  mk.call(verde, Color(0.04, 0.08, 0.05)))
	btn.add_theme_stylebox_override("disabled", mk.call(Color(0.35, 0.40, 0.42), Color(0.07, 0.09, 0.10)))
	btn.add_theme_color_override("font_color", verde.lightened(0.15))
	btn.add_theme_color_override("font_hover_color", Color(0.85, 1.0, 0.88))
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.62, 0.65))
	if comprado:
		btn.text = "✓ Comprado"
		btn.disabled = true
	elif item_id == _confirmando:
		btn.text = "Comprar igual"
	else:
		btn.text = "Comprar"
	btn.disabled = btn.disabled or _comprando
	btn.pressed.connect(_on_comprar.bind(item_id))
	der.add_child(btn)
	return caja


# ── Compra ────────────────────────────────────────────────────
func _on_comprar(item_id: String) -> void:
	if _comprando: return
	var it     := EconomiaManager.item_catalogo(item_id)
	var precio := int(it.get("precio", 0))

	# Aviso (no bloqueo): si comprar algo opcional deja al estudiante sin EC
	# para una herramienta obligatoria que todavía necesita, se lo advierte
	# antes. Un segundo clic confirma.
	if str(it.get("tipo", "")) != "herramienta" and _confirmando != item_id:
		var pendiente := _herramienta_pendiente()
		if not pendiente.is_empty() and EconomiaManager.ecocredits - precio < int(pendiente.get("precio", 0)):
			_confirmando = item_id
			_mensaje("Ojo: te quedarías sin EcoCredits para el %s (%d EC), que vas a necesitar. Tocá \"Comprar igual\" si querés seguir." \
				% [pendiente.get("nombre", ""), int(pendiente.get("precio", 0))], COLOR_AVISO)
			_reconstruir()
			return

	_confirmando = ""
	_comprando   = true
	_mensaje("Comprando...", Color(0.8, 0.8, 0.8))
	_reconstruir()
	EconomiaManager.comprar(item_id)


func _on_compra_terminada(ok: bool, item_id: String, mensaje: String) -> void:
	_comprando = false
	if ok and item_id == _resaltado:
		_resaltado = ""
		mensaje += " Ya podés hacer la misión."
	_mensaje(mensaje, COLOR_OK if ok else COLOR_ERROR)
	_reconstruir()


# Primera herramienta obligatoria que el estudiante no tiene y cuyo nivel
# todavía no completó (la que va a necesitar), o {}.
func _herramienta_pendiente() -> Dictionary:
	var nm = get_node_or_null("/root/NivelManager")
	for it in EconomiaManager.catalogo:
		if str(it.get("tipo", "")) != "herramienta": continue
		if EconomiaManager.tiene_item(str(it.get("item_id", ""))): continue
		var modulo_v = it.get("modulo_id")   # null en los ítems opcionales
		var modulo : int = int(modulo_v) if modulo_v != null else 0
		if nm and modulo > 0 and nm.nivel_completo(modulo): continue
		return it
	return {}


func _actualizar_saldo() -> void:
	if _saldo_lbl:
		_saldo_lbl.text = "💰 %d EC" % EconomiaManager.ecocredits


func _mensaje(texto: String, color: Color) -> void:
	if _mensaje_lbl:
		_mensaje_lbl.text = texto
		_mensaje_lbl.add_theme_color_override("font_color", color)
