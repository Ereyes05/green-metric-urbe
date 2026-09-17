# ============================================================
# panel_oficina_movilidad.gd — NIVEL 5: Oficina de Movilidad.
# Primera visita: el encargo (Plan de Movilidad para el Consejo, 100 de
# presupuesto). Después: tablero con presupuesto y estado de cada decisión.
# No modifica el plan: avisa con señales y el controlador guarda.
# ============================================================
extends CanvasLayer

const DATOS := preload("res://scenes/misiones/plan_movilidad_datos.gd")
const UI := preload("res://scenes/misiones/ui_movilidad.gd")
const TEMA := preload("res://scenes/ui/hud_tema.gd")

signal encargo_aceptado()
signal cerrado()

var plan = null
var _vb : VBoxContainer = null


func _ready() -> void:
	layer = 20
	_vb = UI.panel_modal(self, 620)
	visible = false


func abrir(p) -> void:
	plan = p
	_reconstruir()
	visible = true


func cerrar() -> void:
	visible = false
	cerrado.emit()


func _on_aceptar() -> void:
	encargo_aceptado.emit()


func _reconstruir() -> void:
	UI.limpiar(_vb)
	_vb.add_child(UI.texto("🚲 Oficina de Movilidad Sostenible", 11, TEMA.VIOLETA, 600))
	if not plan.encargo_aceptado:
		_vb.add_child(UI.texto("El encargo", 17, TEMA.TEXTO, 700))
		_vb.add_child(UI.texto(DATOS.ENCARGO, 13, TEMA.TEXTO_2))
		var aceptar := UI.boton("Aceptar el encargo", TEMA.VERDE, 42)
		aceptar.alignment = HORIZONTAL_ALIGNMENT_CENTER
		aceptar.pressed.connect(_on_aceptar)
		_vb.add_child(aceptar)
	else:
		_vb.add_child(UI.texto("Tu Plan de Movilidad", 17, TEMA.TEXTO, 700))
		var comprometido : int = plan.costo_comprometido()
		_vb.add_child(UI.texto("Presupuesto: %d de %d comprometido · quedan %d" % [
			comprometido, DATOS.PRESUPUESTO, DATOS.PRESUPUESTO - comprometido], 13, TEMA.DORADO, 600))
		_vb.add_child(UI.barra(float(comprometido) / float(DATOS.PRESUPUESTO)))
		_vb.add_child(UI.separador())
		for d in DATOS.DECISIONES:
			_vb.add_child(_fila(d))
		_vb.add_child(UI.separador())
		_vb.add_child(_fila_consejo())
	var cerrar_btn := UI.boton("Cerrar", TEMA.VACIO, 34)
	cerrar_btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	cerrar_btn.pressed.connect(cerrar)
	_vb.add_child(cerrar_btn)


func _fila(d: Dictionary) -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	var nombre := TEMA.label(d["titulo"], 12, TEMA.TEXTO, 600)
	nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(nombre)
	var op : String = plan.opcion_actual(d["id"])
	var estado : Label
	if op == "":
		estado = TEMA.label("Pendiente · %s" % DATOS.NOMBRE_LUGAR.get(d["lugar"], ""), 12, TEMA.TEXTO_3)
	else:
		var o := DATOS.opcion(d["id"], op)
		estado = TEMA.label("%s · costo %d" % [o["corto"], int(o["costo"])], 12, TEMA.VERDE)
	fila.add_child(estado)
	return fila


func _fila_consejo() -> Control:
	var texto := ""
	var color := TEMA.TEXTO_3
	if plan.presentado():
		texto = "Consejo Universitario: %s" % DATOS.calificacion(int(plan.consejo.get("aciertos", 0)))["nombre"]
		color = TEMA.VERDE
	elif plan.todas_resueltas():
		texto = "Plan completo: preséntalo en el Rectorado"
		color = TEMA.DORADO
	else:
		var faltan := 0
		for id in DATOS.ids_decisiones():
			if not plan.resuelta(id):
				faltan += 1
		texto = ("Consejo Universitario: falta 1 decisión" if faltan == 1
			else "Consejo Universitario: faltan %d decisiones" % faltan)
	return UI.texto(texto, 12, color, 600)
