# ============================================================
# ui_movilidad.gd — piezas de interfaz del Nivel 5 (Plan de Movilidad),
# construidas SOLO con los tokens de hud_tema.gd: panel centrado, textos,
# botones, barra y formato de números. Los tres paneles del nivel las usan
# para verse como el HUD plano; cambiar de estilo = cambiar hud_tema.gd.
# ============================================================
extends RefCounted

const TEMA := preload("res://scenes/ui/hud_tema.gd")

const ACENTO := TEMA.VIOLETA   # color de Transporte en el HUD


# Fondo oscuro + panel centrado que se ajusta a su contenido. Devuelve el
# VBoxContainer donde va el contenido.
static func panel_modal(capa: CanvasLayer, ancho: float) -> VBoxContainer:
	var fondo := ColorRect.new()
	fondo.name = "Fondo"
	fondo.color = Color(TEMA.POPOVER_BG, 0.6)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa.add_child(fondo)
	var centro := CenterContainer.new()
	centro.name = "Centro"
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa.add_child(centro)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.add_theme_stylebox_override("panel", TEMA.panel(ACENTO))
	centro.add_child(panel)
	var vb := VBoxContainer.new()
	vb.name = "Contenido"
	vb.custom_minimum_size = Vector2(ancho, 0)
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)
	return vb


static func texto(t: String, tam: int = 13, color: Color = TEMA.TEXTO, peso: int = 400) -> Label:
	var l := TEMA.label(t, tam, color, peso)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func boton(t: String, color: Color = ACENTO, alto: int = 40) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(0, alto)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", TEMA.rubik(600))
	b.add_theme_font_size_override("font_size", 13)
	pintar_boton(b, color, false)
	return b


# resaltado = elegido (fondo teñido y borde del color); normal = caja oscura.
static func pintar_boton(b: Button, color: Color, resaltado: bool) -> void:
	var fondo := Color(color, 0.28) if resaltado else TEMA.POPOVER_BG
	var borde := color if resaltado else TEMA.VACIO
	b.add_theme_stylebox_override("normal", TEMA.caja(fondo, borde, 2, 10, 12, 8))
	var hover := TEMA.caja(Color(color, 0.18), color, 2, 10, 12, 8)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled",
		TEMA.caja(fondo, color if resaltado else TEMA.PASO_PENDIENTE, 2, 10, 12, 8))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for clave in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(clave, TEMA.TEXTO)
	b.add_theme_color_override("font_disabled_color", TEMA.TEXTO if resaltado else TEMA.APAGADO)


static func separador() -> HSeparator:
	var s := HSeparator.new()
	var linea := StyleBoxLine.new()
	linea.color = TEMA.SEPARADOR
	linea.thickness = 1
	s.add_theme_stylebox_override("separator", linea)
	return s


static func barra(fraccion: float) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.min_value = 0.0
	pb.max_value = 100.0
	pb.value = clampf(fraccion, 0.0, 1.0) * 100.0
	pb.show_percentage = false
	pb.custom_minimum_size = Vector2(0, 10)
	pb.add_theme_stylebox_override("background", TEMA.caja(TEMA.TRACK, TEMA.TRACK, 0, 5))
	pb.add_theme_stylebox_override("fill", TEMA.caja(TEMA.DORADO, TEMA.DORADO, 0, 5))
	return pb


static func limpiar(contenedor: Node) -> void:
	for c in contenedor.get_children():
		contenedor.remove_child(c)
		c.queue_free()


static func puntos(p: float) -> String:
	return ("%+.2f" % p).replace(".", ",")


static func decimal(p: float) -> String:
	return ("%.2f" % p).replace(".", ",")
