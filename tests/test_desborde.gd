# Ningún texto ni botón de las misiones se sale de su cuadro ni de la
# pantalla (1280×720, la resolución base del proyecto). Abre cada cuadro con
# sus textos reales —todas las misiones y todas las respuestas— y revisa que
# cada Label/Button visible quede dentro de su Panel más cercano.
# Lo que vive dentro de un ScrollContainer se mide contra el scroll, que es
# lo que se ve.
# Correr: $GODOT --headless --path . res://tests/test_desborde.tscn
extends Node

const PLANTAR  := preload("res://scenes/misiones/mision_plantar.gd")
const INTERIOR := preload("res://scenes/misiones/interior_bloque.gd")
const RECICLAR := preload("res://scenes/misiones/mision_reciclar.gd")
const SOLAR    := preload("res://scenes/misiones/mision_solar.gd")
const CAPTACION:= preload("res://scenes/misiones/mision_captacion.gd")
const MALLA    := preload("res://scenes/misiones/mision_malla_verde.gd")
const COMITE   := preload("res://scenes/misiones/mision_comite_ambiental.gd")
const SEMANA   := preload("res://scenes/misiones/mision_semana_verde.gd")
const INFORME  := preload("res://scenes/misiones/mision_informe_final.gd")
const MAPA     := preload("res://scenes/mapa/SceneMapaMundo.gd")
const QUIZ     := preload("res://scenes/ui/quiz_npc.tscn")
const DIALOGO  := preload("res://scenes/ui/dialogo_npc.tscn")
const INICIO   := preload("res://scenes/ui/mision_inicio.gd")
const TIENDA   := preload("res://scenes/ui/tienda_conocimiento.gd")
const RESIDUOS := preload("res://scenes/ui/minijuego_residuos.gd")
const DATOS_MOV:= preload("res://scenes/misiones/plan_movilidad_datos.gd")
const PLAN_MOV := preload("res://scenes/misiones/plan_movilidad.gd")
const DECISION := preload("res://scenes/misiones/panel_decision_movilidad.gd")
const OFICINA  := preload("res://scenes/misiones/panel_oficina_movilidad.gd")
const CONSEJO  := preload("res://scenes/misiones/panel_consejo_movilidad.gd")

const TOLERANCIA := 2.0

var _fallos := 0
var _revisados := 0


func _ready() -> void:
	print("test_desborde")
	get_window().size = Vector2i(1280, 720)
	# Sin NivelManager las misiones no completan nada de verdad (todas
	# preguntan por get_node_or_null("/root/NivelManager")): la prueba no
	# toca el progreso guardado.
	var nm := get_node_or_null("/root/NivelManager")
	if nm:
		nm.name = "NivelManagerApagado"
	await _plantar()
	await _interior()
	await _solar()
	await _reciclar()
	await _captacion()
	await _nivel6()
	await _quiz()
	await _plantar_pasos()
	await _dialogos()
	await _inicio_mision()
	await _tienda()
	await _minijuego_residuos()
	await _movilidad()
	await _avisos_mapa()
	if nm:
		nm.name = "NivelManager"
	print("  %d cuadros revisados" % _revisados)
	print("test_desborde: %d fallos" % _fallos)
	get_tree().quit(1 if _fallos > 0 else 0)


# Lo bastante para que terminen las animaciones de entrada (escala 0.85→1).
func _esperar() -> void:
	await get_tree().create_timer(0.4).timeout


func _contenedor(c: Control) -> Control:
	var p := c.get_parent()
	while p:
		if p is ScrollContainer or p is Panel or p is PanelContainer:
			return p
		p = p.get_parent()
	return null


func revisar(raiz: Node, que: String) -> void:
	_revisados += 1
	var fallos_antes := _fallos
	var pantalla := Rect2(Vector2.ZERO, Vector2(1280, 720)).grow(TOLERANCIA)
	# Scroll solo como último recurso: si el texto no cabe, el cuadro tiene
	# que haber crecido antes hasta casi el alto de la pantalla.
	for n in raiz.find_children("*", "ScrollContainer", true, false):
		var sc := n as ScrollContainer
		# Solo los que agrega ui_ajuste; las listas con scroll son a propósito.
		if not sc.has_meta("ajuste") or not sc.is_visible_in_tree() or sc.get_child_count() == 0:
			continue
		var dentro := (sc.get_child(0) as Control).size.y
		var cuadro := _contenedor(sc)
		if dentro > sc.size.y + TOLERANCIA and cuadro and cuadro.size.y < 720 - 40:
			_fallos += 1
			printerr("  FALLA %s: scroll con %.0f px escondidos y el cuadro mide %.0f de alto"
				% [que, dentro - sc.size.y, cuadro.size.y])
	var vistos : Array[Control] = []
	for n in raiz.find_children("*", "Control", true, false):
		var c := n as Control
		if not (c is Label or c is Button) or not c.is_visible_in_tree():
			continue
		if c.text.strip_edges() == "":
			continue
		if c.modulate.a < 0.05 or c.get_global_transform().get_scale().x < 0.5:
			continue
		var r := c.get_global_rect()
		var rt := _rect_texto(c)
		for otro in vistos:
			if _contenedor(otro) != _contenedor(c):
				continue   # un cuadro encima de otro tapa a propósito
			var choque := rt.intersection(_rect_texto(otro))
			if choque.get_area() > 30.0 and not _contenedor(c) is ScrollContainer:
				_fallos += 1
				printerr("  FALLA %s: «%s» se encima con «%s» (%s)"
					% [que, c.text.strip_edges().left(30), otro.text.strip_edges().left(30), choque.size])
		vistos.append(c)
		var texto : String = c.text.strip_edges().split("\n")[0].left(40)
		if not pantalla.encloses(r):
			_fallos += 1
			printerr("  FALLA %s: «%s» se sale de la pantalla %s" % [que, texto, r])
			continue
		var cont := _contenedor(c)
		if cont is ScrollContainer:
			continue   # se llega a él con la rueda del mouse
		if cont and not cont.get_global_rect().grow(TOLERANCIA).encloses(r):
			_fallos += 1
			printerr("  FALLA %s: «%s» se sale de su cuadro (%s fuera de %s)"
				% [que, texto, r, cont.get_global_rect()])

	if vistos.is_empty():
		_fallos += 1
		printerr("  FALLA %s: no se ve ningún texto (¿se abrió la pantalla?)" % que)
	if _fallos == fallos_antes:
		print("  ok    ", que)

# Lo que de verdad ocupa el texto de un Label de una línea (la caja suele
# ser más ancha que el texto); el resto, su caja.
func _rect_texto(c: Control) -> Rect2:
	var r := c.get_global_rect()
	if not (c is Label) or (c as Label).autowrap_mode != TextServer.AUTOWRAP_OFF:
		return r
	var l := c as Label
	var ancho := 0.0
	var fuente := l.get_theme_font("font")
	var tam := l.get_theme_font_size("font_size")
	for linea in l.text.split("\n"):
		ancho = maxf(ancho, fuente.get_string_size(linea, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x)
	ancho = minf(ancho, r.size.x)
	var alto := minf(r.size.y, l.get_line_height() * l.get_line_count())
	# Un emoji solo: la fuente de emoji trae mucho interlineado, el dibujo
	# mide más o menos el tamaño de la letra.
	if l.text.strip_edges().unicode_at(0) >= 0x2000 and l.text.strip_edges().length() <= 3:
		alto = minf(alto, tam * 1.1)
	match l.vertical_alignment:
		VERTICAL_ALIGNMENT_CENTER:
			r.position.y += (r.size.y - alto) / 2.0
		VERTICAL_ALIGNMENT_BOTTOM:
			r.position.y += r.size.y - alto
	r.size.y = alto
	match l.horizontal_alignment:
		HORIZONTAL_ALIGNMENT_CENTER:
			r.position.x += (r.size.x - ancho) / 2.0
		HORIZONTAL_ALIGNMENT_RIGHT:
			r.position.x += r.size.x - ancho
	r.size.x = ancho
	return r


# ── Avisos del mapa ("[E] Regar la planta — …") ──────────────────
# El Label ocupa todo el cuadro, así que revisar() no ve el texto que se
# pasa del borde: acá se mide el texto contra el ancho del cuadro.
const AVISOS := [
	["res://scenes/misiones/zona_tierra.gd", "nombre_zona"],
	["res://scenes/misiones/zona_reciclaje.gd", "nombre_zona"],
	["res://scenes/misiones/llave_agua.gd", "nombre_llave"],
	["res://scenes/misiones/punto_captacion.gd", "nombre_punto"],
	["res://scenes/misiones/punto_comite_ambiental.gd", "nombre_punto"],
	["res://scenes/misiones/punto_critico_energia.gd", "nombre_punto"],
	["res://scenes/misiones/punto_informe_final.gd", "nombre_punto"],
	["res://scenes/misiones/punto_malla_verde.gd", "nombre_punto"],
	["res://scenes/misiones/punto_semana_verde.gd", "nombre_punto"],
]


func _avisos_mapa() -> void:
	var cam := Camera2D.new()
	add_child(cam)
	cam.make_current()
	var jug := Node2D.new()
	jug.add_to_group("jugador")
	add_child(jug)
	for a in AVISOS:
		var p = load(a[0]).new()
		p.set(a[1], "Jardín del Estacionamiento")
		add_child(p)
		await get_tree().process_frame
		p._al_entrar(jug)
		await _revisar_aviso(p, a[0].get_file())
		if a[0].ends_with("zona_tierra.gd"):
			p._completada = true
			p._necesita_riego = true
			p._actualizar_texto_prompt()
			await _revisar_aviso(p, "zona_tierra regar")
		elif a[0].ends_with("zona_reciclaje.gd"):
			p._completada = true
			p.nivel_llenado = 0.9
			p._actualizar_prompt_texto()
			await _revisar_aviso(p, "zona_reciclaje llamar al servicio")
		p.queue_free()
	cam.queue_free()
	jug.queue_free()


func _revisar_aviso(p: Node, que: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_revisados += 1
	var panel : Control = p._prompt_panel
	var lbl : Label = p._prompt_lbl
	var fuente := lbl.get_theme_font("font")
	var ancho := fuente.get_string_size(lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		lbl.get_theme_font_size("font_size")).x
	var r := panel.get_global_rect()
	var pantalla := Rect2(Vector2.ZERO, Vector2(1280, 720)).grow(TOLERANCIA)
	if ancho > r.size.x - 8.0:
		_fallos += 1
		printerr("  FALLA aviso %s: «%s» mide %.0f px y el cuadro %.0f" % [que, lbl.text, ancho, r.size.x])
	elif r.position.x < pantalla.position.x or r.end.x > pantalla.end.x:
		_fallos += 1
		printerr("  FALLA aviso %s: el cuadro se sale de la pantalla %s" % [que, r])
	else:
		print("  ok    aviso ", que, " (", lbl.text, ")")


# ── Nivel 1: elegir planta, respuesta y métricas ─────────────────
func _plantar() -> void:
	var ui = PLANTAR.new()
	add_child(ui)
	await _esperar()
	for i in PLANTAR.MISIONES.size():
		var m : Dictionary = PLANTAR.MISIONES[i]
		ui.iniciar(i, null)
		await _esperar()
		revisar(ui._panel_root, "plantar %s" % m["id"])
		for carta in ui._cartas:
			ui._seleccionar_carta(carta)
			await _esperar()
			revisar(ui._panel_root, "plantar %s ficha %s" % [m["id"], carta.get_meta("planta_id")])
		for pid in m["feedback"]:
			ui._mostrar_feedback(pid == m["correcta"], "Opción válida", m["feedback"][pid])
			await _esperar()
			revisar(ui._feedback_panel, "plantar %s respuesta %s" % [m["id"], pid])
		ui._feedback_panel.visible = false
		for pid in [m["correcta"], m.get("valida", "")]:
			if pid == "":
				continue
			ui._planta_elegida = pid
			ui._calidad = "mejor" if pid == m["correcta"] else "valida"
			ui._mostrar_panel_metricas_planta()
			await _esperar()
			var met : Control = ui.get_child(ui.get_child_count() - 1)
			revisar(met, "plantar %s métricas %s" % [m["id"], pid])
			met.free()
	ui.queue_free()


# ── Nivel 2: luminarias LED y paneles solares ────────────────────
func _interior() -> void:
	var ui = INTERIOR.new()
	add_child(ui)
	for i in INTERIOR.BLOQUES.size():
		ui.iniciar(i, null)
		await _esperar()
		revisar(ui, "LED %s" % INTERIOR.BLOQUES[i]["id"])
		ui._iniciar_interactivo(0)
		await _esperar()
		revisar(ui._sub_panel, "LED %s luminaria" % INTERIOR.BLOQUES[i]["id"])
		ui._sub_panel.visible = false
		ui._mostrar_panel_metricas_led(50, 20)
		await _esperar()
		var met : Control = ui.get_child(ui.get_child_count() - 1)
		revisar(met, "LED %s métricas" % INTERIOR.BLOQUES[i]["id"])
		met.free()
	ui.queue_free()


func _solar() -> void:
	for i in SOLAR.MISIONES_SOLAR.size():
		var ui = SOLAR.new()
		add_child(ui)
		ui.iniciar(i, null)
		for paso in SOLAR.PASOS_SOLAR.size():
			ui._paso_actual = paso
			ui._mostrar_paso()
			await _esperar()
			revisar(ui, "solar %d paso %d" % [i, paso])
		ui._completar_mision()
		await _esperar()
		revisar(ui, "solar %d fin" % i)
		ui.free()


# ── Nivel 3: clasificar residuos ─────────────────────────────────
func _reciclar() -> void:
	var ui = RECICLAR.new()
	add_child(ui)
	for zona in ["Entrada del Picnic", "Camino de las Canchas"]:
		ui.iniciar("prueba", zona, null)
		await _esperar()
		revisar(ui, "residuos %s" % zona)
	ui._mostrar_metricas(60, 25)
	await _esperar()
	revisar(ui.get_child(ui.get_child_count() - 1), "residuos métricas")
	ui.queue_free()


# ── Nivel 4: captación de agua ───────────────────────────────────
func _captacion() -> void:
	for i in CAPTACION.MISIONES_CAPTACION.size():
		var ui = CAPTACION.new()
		add_child(ui)
		ui.iniciar(i, null)
		for paso in CAPTACION.PASOS_CAPTACION.size():
			ui._paso_actual = paso
			ui._mostrar_paso()
			await _esperar()
			revisar(ui, "agua %d paso %d" % [i, paso])
		ui._completar_mision()
		await _esperar()
		revisar(ui, "agua %d fin" % i)
		ui.free()


# ── Nivel 6: educación ───────────────────────────────────────────
func _nivel6() -> void:
	for par in [[MALLA, "malla verde"], [COMITE, "comité"], [SEMANA, "semana verde"],
			[INFORME, "informe final"]]:
		var ui = par[0].new()
		add_child(ui)
		ui.iniciar(null)
		await _esperar()
		revisar(ui, par[1])
		if par[0] == SEMANA:
			ui._mostrar_confirmacion(80, 30, 40)
		else:
			ui._mostrar_confirmacion(80, 30)
		await _esperar()
		revisar(ui, par[1] + " fin")
		ui.queue_free()


# ── Quiz y tests: todas las preguntas validadas ──────────────────
func _quiz() -> void:
	for mision in MAPA.QUIZ_POR_MISION:
		var pregs : Array = MAPA.QUIZ_POR_MISION[mision]
		for i in pregs.size():
			var ui = QUIZ.instantiate()
			add_child(ui)
			ui.iniciar(pregs, "Profesora", 1, "prueba_" + mision, true)
			ui._indice = i
			ui._mostrar_pregunta()
			await _esperar()
			revisar(ui, "quiz %s pregunta %d" % [mision, i + 1])
			ui._responder((int(pregs[i]["correcta"]) + 1) % 3)
			await _esperar()
			revisar(ui, "quiz %s respuesta %d" % [mision, i + 1])
			ui.free()


# ── Nivel 1: los pasos de plantar (cavar, plantar, regar) ────────
func _plantar_pasos() -> void:
	var ui = PLANTAR.new()
	add_child(ui)
	ui.iniciar(0, null, "drag")
	ui._planta_elegida = PLANTAR.MISIONES[0]["correcta"]
	ui._iniciar_plantacion()
	for paso in PLANTAR.PASO_TITULOS.size():
		ui._paso_actual = paso
		ui._actualizar_paso_ui()
		await _esperar()
		revisar(ui._plant_panel, "plantar paso %d" % paso)
	ui.free()


# ── Diálogos de todos los NPC, línea por línea ───────────────────
func _dialogos() -> void:
	var mapa = MAPA.new()
	var npcs : Array = mapa.DATOS_NPCS.duplicate(true)
	mapa.free()
	for d in npcs:
		var ui = DIALOGO.instantiate()
		add_child(ui)
		ui.iniciar(d["nombre"], d["dialogos"], d.get("mision_id", ""), d.get("color", Color.GRAY))
		for i in (d["dialogos"] as PackedStringArray).size():
			ui._indice = i
			ui._mostrar_linea()
			ui._texto_lbl.text = ui._texto_completo
			ui._escribiendo = false
			await _esperar()
			revisar(ui, "diálogo %s línea %d" % [d["nombre"], i + 1])
		ui.free()


# ── Ficha de inicio de misión, un módulo por nivel ───────────────
func _inicio_mision() -> void:
	for modulo in INICIO.MODULOS_INFO:
		var ui = INICIO.new()
		add_child(ui)
		ui.mostrar(modulo, "Corredor Norte-Este del Campus", "Profesora Ramírez", "prueba")
		await _esperar()
		revisar(ui, "inicio de misión nivel %d" % modulo)
		ui.free()


func _tienda() -> void:
	var ui = TIENDA.new()
	add_child(ui)
	ui.abrir()
	await _esperar()
	revisar(ui, "tienda")
	# Llegando desde una misión bloqueada: explica qué falta.
	var antes : Array = EconomiaManager.catalogo
	EconomiaManager.catalogo = [{"item_id": "prueba", "tipo": "herramienta", "precio": 120,
		"nombre": "Medidor inteligente de consumo eléctrico con registro"}]
	ui.abrir("prueba")
	await _esperar()
	revisar(ui, "tienda desde misión bloqueada")
	EconomiaManager.catalogo = antes
	ui.free()


func _minijuego_residuos() -> void:
	var ui = RESIDUOS.new()
	add_child(ui)
	ui.iniciar()
	await _esperar()
	revisar(ui, "minijuego residuos")
	ui._terminar()
	await _esperar()
	revisar(ui, "minijuego residuos resultado")
	ui.free()


# ── Nivel 5: oficina, cada decisión y el consejo ─────────────────
func _movilidad() -> void:
	var plan = PLAN_MOV.new()
	var ofi = OFICINA.new()
	add_child(ofi)
	ofi.abrir(plan)
	await _esperar()
	revisar(ofi, "movilidad oficina")
	ofi.free()
	for id in DATOS_MOV.ids_decisiones():
		var dec = DECISION.new()
		dec.plan = plan
		add_child(dec)
		dec.abrir(id)
		await _esperar()
		revisar(dec, "movilidad decisión %s" % id)
		# Al marcar cada opción aparece su detalle (qué implica, a quién beneficia).
		for i in 3:
			dec._on_opcion(i)
			await _esperar()
			revisar(dec, "movilidad decisión %s opción %d marcada" % [id, i + 1])
		dec.free()
	# Presupuesto agotado (el caso de la prueba de usabilidad): las tres
	# opciones de la buseta muestran "No alcanza… Libéralo cambiando…".
	var gastado = PLAN_MOV.new()
	gastado.encargo_aceptado = true
	for par in [["tr_permisos", "lectoras_de_placas"], ["tr_lote", "ciclovia_arborizada"],
			["tr_carpool", "app_carpool"], ["tr_dia_sin_carros", "cierre_semanal"]]:
		gastado.aplicar_valida(par[0], par[1])
	var sin = DECISION.new()
	sin.plan = gastado
	add_child(sin)
	sin.abrir("tr_shuttle")
	await _esperar()
	revisar(sin, "movilidad decisión sin presupuesto")
	var aviso := false
	for l in sin.find_children("*", "Label", true, false):
		if "Libéralo cambiando" in (l as Label).text:
			aviso = true
	if not aviso:
		_fallos += 1
		printerr("  FALLA sin presupuesto: no aparece cómo liberarlo")
	sin.free()
	var con = CONSEJO.new()
	add_child(con)
	con.abrir(plan)
	await _esperar()
	revisar(con, "movilidad consejo")
	con.free()
