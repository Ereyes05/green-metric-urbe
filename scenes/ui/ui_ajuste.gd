# ui_ajuste.gd — que el contenido de un cuadro nunca se salga de él.
#
# Los cuadros de las misiones son Panel de alto fijo (p. ej. 520×390) con
# un VBox adentro. Cuando el texto era más largo de lo previsto, el VBox
# crecía por debajo del Panel y el botón ("¡Genial!", "¡A plantar!")
# quedaba afuera del borde. encajar() mide lo que el contenido necesita y
# estira el Panel hacia arriba y hacia abajo por igual (sigue centrado),
# sin pasar del alto de la pantalla. Lo que aun así no cabe va dentro de un
# scroll (con_scroll()), que es lo único que se achica.
extends RefCounted

const MARGEN_PANTALLA := 16.0


# Envuelve un Label largo en un scroll vertical que toma el espacio libre
# del VBox. El texto sigue cortándose por palabras al ancho del cuadro.
static func con_scroll(contenido: Control) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.set_meta("ajuste", true)
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(contenido)
	return sc


# Estira el panel (anclado al centro) hasta que entre su contenido. Llamar
# después de poner los textos; si el panel se reutiliza, vuelve a su alto
# original antes de medir.
static func encajar(panel: Control) -> void:
	if not panel.has_meta("alto_base"):
		panel.set_meta("alto_base", panel.offset_bottom - panel.offset_top)
	_poner_alto(panel, panel.get_meta("alto_base"))
	# Dos cuadros para que los contenedores (y lo que hay dentro de los
	# scrolls) se acomoden con los textos nuevos.
	await panel.get_tree().process_frame
	await panel.get_tree().process_frame
	if not is_instance_valid(panel):
		return
	var falta := 0.0
	for hijo in panel.get_children():
		if hijo is Container and hijo.visible:
			falta = maxf(falta, _falta(hijo, panel))
	if falta <= 0.0:
		return
	var alto_max := panel.get_viewport_rect().size.y - 2.0 * MARGEN_PANTALLA
	var alto := panel.offset_bottom - panel.offset_top
	_poner_alto(panel, minf(alto + falta, alto_max))


# Cuánto le falta de alto a un contenedor para mostrar todo sin cortes:
# lo que pide su mínimo frente al alto que el panel le deja (un Control
# nunca mide menos que su mínimo, así que su size no sirve para esto), más
# lo que tienen escondido sus scrolls.
static func _falta(cont: Control, panel: Control) -> float:
	var disponible := panel.size.y * (cont.anchor_bottom - cont.anchor_top) \
		+ cont.offset_bottom - cont.offset_top
	# Si sobra espacio, ese sobrante ya lo tienen los scrolls: no se descuenta.
	var falta := maxf(0.0, cont.get_combined_minimum_size().y - disponible)
	for n in cont.find_children("*", "ScrollContainer", true, false):
		var sc := n as ScrollContainer
		if sc.is_visible_in_tree() and sc.get_child_count() > 0:
			var dentro := (sc.get_child(0) as Control).size.y
			falta += maxf(0.0, dentro - sc.size.y)
	return falta


static func _poner_alto(panel: Control, alto: float) -> void:
	var centro := (panel.offset_top + panel.offset_bottom) / 2.0
	panel.custom_minimum_size.y = alto
	panel.offset_top    = centro - alto / 2.0
	panel.offset_bottom = centro + alto / 2.0


# Avisos del mapa ("[E] Regar la planta — Jardín de la Plazoleta"): el cuadro
# tenía ancho fijo y el texto largo se salía. Llamar en vez de asignar
# position: ensancha el cuadro hasta que entre el texto, lo deja centrado
# donde estaba y sin salirse de la pantalla.
static func colocar_aviso(panel: Control, lbl: Label, pos: Vector2) -> void:
	if not panel.has_meta("ancho_base"):
		panel.set_meta("ancho_base", panel.custom_minimum_size.x)
	var base : float = panel.get_meta("ancho_base")
	# En pasos de 24 px: un aviso que cambia solo (los litros de la llave) no
	# salta de lado cada vez que el número gana un dígito.
	var ancho := maxf(base, ceilf((lbl.get_minimum_size().x + 28.0) / 24.0) * 24.0)
	panel.custom_minimum_size.x = ancho
	panel.size.x = ancho
	pos.x -= (ancho - base) * 0.5
	var vp := panel.get_viewport_rect().size
	pos.x = clampf(pos.x, MARGEN_PANTALLA, maxf(MARGEN_PANTALLA, vp.x - ancho - MARGEN_PANTALLA))
	pos.y = clampf(pos.y, MARGEN_PANTALLA, maxf(MARGEN_PANTALLA, vp.y - panel.size.y - MARGEN_PANTALLA))
	panel.position = pos
