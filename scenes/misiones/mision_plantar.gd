# ============================================================
# mision_plantar.gd — NIVEL 1: Infraestructura y Entorno
# Minijuego de plantación sostenible.
# El estudiante debe elegir la planta correcta para cada
# zona del campus según criterios de sostenibilidad.
# ============================================================
extends CanvasLayer

signal mision_completada_plantar(mision_id: String, xp: int, ec: int)

# ── Datos de las 3 misiones de plantación ───────────────────
const MISIONES : Array = [
	{
		"id":       "plantar_corredores",
		"zona":     "Corredor Principal URBE",
		"icono":    "🌳",
		"contexto": "Los corredores del campus reciben el sol directo todo el día.\nLos estudiantes necesitan sombra natural y las aceras requieren raíces no invasivas.",
		"criterio": "Necesitamos un árbol nativo que dé sombra amplia sin dañar la infraestructura.",
		"correcta": "araguaney",
		"plantas":  [
			{"id": "araguaney",      "nombre": "Araguaney",          "desc": "Árbol Nacional · Sombra amplia · Raíces no invasivas"},
			{"id": "eucalipto",      "nombre": "Eucalipto",           "desc": "Especie introducida · Raíces invasivas"},
			{"id": "cactus",         "nombre": "Cactus del Desierto", "desc": "Especie desértica · Sin sombra"},
			{"id": "pino_canadiense","nombre": "Pino Canadiense",     "desc": "Especie foránea · Clima frío"},
		],
		"feedback": {
			"araguaney":       "✅ ¡Excelente! El Araguaney es el Árbol Nacional de Venezuela. Su copa amplia proporciona sombra perfecta y sus raíces no dañan las aceras. ¡Elección ideal para corredores universitarios!",
			"eucalipto":       "❌ El eucalipto es una especie invasiva. Sus raíces profundas y agresivas dañan aceras e infraestructura. Además consume grandes cantidades de agua subterránea.",
			"cactus":          "❌ El cactus del desierto no es apto para el clima tropical de Maracaibo. No proporciona sombra y no se adapta a las condiciones de humedad del campus.",
			"pino_canadiense": "❌ El pino canadiense es una especie de clima frío. No tolera las altas temperaturas de Maracaibo y no brinda la sombra adecuada para corredores universitarios.",
		},
	},
	{
		"id":       "plantar_rectorado",
		"zona":     "Jardín del Rectorado",
		"icono":    "🌺",
		"contexto": "El jardín principal del Rectorado es la carta de presentación del campus.\nNecesita plantas ornamentales con bajo consumo de agua y alto impacto visual.",
		"criterio": "Buscamos plantas decorativas adaptadas al trópico, resistentes al calor y sin pesticidas.",
		"correcta": "buganvilia",
		"plantas":  [
			{"id": "buganvilia",  "nombre": "Buganvilia (Veranera)", "desc": "Tropical · Ornamental · Resistente · Poco agua"},
			{"id": "rosa_inglesa","nombre": "Rosa Inglesa",          "desc": "Alto mantenimiento · Necesita pesticidas"},
			{"id": "bambu",       "nombre": "Bambú Gigante",         "desc": "Invasivo · Crece descontrolado"},
			{"id": "cactus",      "nombre": "Cactus",                "desc": "Sin valor ornamental para jardín formal"},
		],
		"feedback": {
			"buganvilia":   "✅ ¡Perfecto! La Buganvilia (Veranera) es ideal: resistente al calor de Maracaibo, consume poca agua, florece abundantemente todo el año y embellece el campus sin requerir pesticidas.",
			"rosa_inglesa": "❌ La rosa inglesa requiere muchos cuidados, pesticidas y condiciones de clima templado. Su mantenimiento intensivo es incompatible con los principios de sostenibilidad de GreenMetric.",
			"bambu":        "❌ El bambú gigante es una especie invasiva. Se propaga de forma descontrolada, puede dañar estructuras y no es adecuado para un jardín formal universitario.",
			"cactus":       "❌ El cactus no tiene valor ornamental para un jardín universitario formal. No produce flores vistosas ni proporciona la imagen verde que necesita el Rectorado.",
		},
	},
	{
		"id":       "plantar_patio",
		"zona":     "Patio Central Estudiantil",
		"icono":    "🌿",
		"contexto": "El patio central es el espacio de descanso de los estudiantes.\nNecesita vegetación que cree un microclima fresco sin obstruir el paso ni crear peligros.",
		"criterio": "Plantas de bajo mantenimiento que reduzcan la temperatura y sean seguras para el tránsito.",
		"correcta": "helecho_tropical",
		"plantas":  [
			{"id": "helecho_tropical","nombre": "Helecho Tropical + Pasto","desc": "Bajo mantenimiento · Fresco · Seguro"},
			{"id": "mango",           "nombre": "Árbol de Mango",          "desc": "Frutos resbalosos · Raíces invasivas"},
			{"id": "bambu",           "nombre": "Bambú",                   "desc": "Invasivo · Obstruye el paso"},
			{"id": "eucalipto",       "nombre": "Eucalipto",               "desc": "Invasivo · Tóxico para otras plantas"},
		],
		"feedback": {
			"helecho_tropical": "✅ ¡Correcto! El helecho tropical con pasto San Agustín crea un manto verde de bajo mantenimiento que reduce la temperatura del suelo, es seguro para el tránsito estudiantil y no requiere podas frecuentes.",
			"mango":            "❌ El árbol de mango presenta riesgos: sus frutos caídos son resbalosos y peligrosos, sus raíces invasivas dañan las aceras y su sombra irregular no es ideal para zonas de tránsito.",
			"bambu":            "❌ El bambú se propaga invasivamente y puede obstruir el paso en el patio. Su rápido crecimiento requiere mantenimiento constante y podría dañar la infraestructura cercana.",
			"eucalipto":        "❌ El eucalipto libera compuestos alelopáticos que inhiben el crecimiento de otras plantas. Además es invasivo y consume grandes cantidades de agua subterránea.",
		},
	},
	{
		"id":       "plantar_norte",
		"zona":     "Camino Norte del Campus",
		"icono":    "🌳",
		"contexto": "El camino norte es la entrada principal al campus. Necesita vegetación que dé bienvenida y sombra a los estudiantes.",
		"criterio": "Árbol de copa amplia, nativo de la región y con valor representativo.",
		"correcta": "araguaney",
		"plantas":  [
			{"id": "araguaney",       "nombre": "Araguaney",         "desc": "Árbol Nacional · Sombra amplia · Raíces no invasivas"},
			{"id": "eucalipto",       "nombre": "Eucalipto",          "desc": "Especie invasiva · Raíces agresivas"},
			{"id": "bambu",           "nombre": "Bambú",              "desc": "Invasivo · No apropiado para entradas"},
			{"id": "pino_canadiense", "nombre": "Pino Canadiense",    "desc": "Especie foránea · Clima frío"},
		],
		"feedback": {
			"araguaney":       "✅ El Araguaney es la elección perfecta. Su floración amarilla representa la identidad venezolana y su copa proporciona sombra ideal para la entrada del campus.",
			"eucalipto":       "❌ El eucalipto es invasivo y consume grandes cantidades de agua subterránea. Sus raíces agresivas dañan aceras e infraestructura.",
			"bambu":           "❌ El bambú crece de forma descontrolada y no proyecta la imagen representativa que necesita la entrada del campus.",
			"pino_canadiense": "❌ El pino canadiense no se adapta al clima tropical de Maracaibo ni representa la flora local.",
		},
	},
	{
		"id":       "plantar_cafetín",
		"zona":     "Zona Norte — Cafetín URBE",
		"icono":    "🌺",
		"contexto": "El área frente al cafetín universitario es frecuentada por estudiantes en horario de comidas.\nNecesita plantas ornamentales que mejoren el ambiente sin obstruir el paso.",
		"criterio": "Plantas tropicales ornamentales de bajo mantenimiento y alta resistencia al sol.",
		"correcta": "buganvilia",
		"plantas":  [
			{"id": "buganvilia",  "nombre": "Buganvilia (Veranera)", "desc": "Tropical · Ornamental · Resistente al sol"},
			{"id": "cactus",      "nombre": "Cactus",                "desc": "Sin valor ornamental · Riesgo por espinas"},
			{"id": "bambu",       "nombre": "Bambú",                 "desc": "Invasivo · Obstruye el paso"},
			{"id": "eucalipto",   "nombre": "Eucalipto",             "desc": "Invasivo · Libera toxinas al suelo"},
		],
		"feedback": {
			"buganvilia": "✅ La Buganvilia resiste el sol directo, florece con colores vivos todo el año y no requiere mucho riego. Perfecta para esta zona de paso frecuente.",
			"cactus":     "❌ El cactus no es apropiado para zonas de tránsito estudiantil. Sus espinas representan un riesgo y su valor ornamental es limitado.",
			"bambu":      "❌ El bambú se propaga invasivamente y puede bloquear el paso frente al cafetín. No es adecuado para esta zona.",
			"eucalipto":  "❌ El eucalipto libera compuestos que inhiben el crecimiento de otras plantas y puede afectar la calidad del aire cerca del cafetín.",
		},
	},
	{
		"id":       "plantar_este",
		"zona":     "Corredor Norte-Este",
		"icono":    "🌿",
		"contexto": "El corredor noreste conecta el Bloque E con los Estudios a Distancia.\nEs una zona de tránsito constante que necesita vegetación fresca y de bajo mantenimiento.",
		"criterio": "Vegetación nativa de bajo mantenimiento que reduzca la temperatura del corredor.",
		"correcta": "helecho_tropical",
		"plantas":  [
			{"id": "helecho_tropical","nombre": "Helecho Tropical + Pasto","desc": "Bajo mantenimiento · Refresca · Nativo"},
			{"id": "rosa_inglesa",    "nombre": "Rosa Inglesa",            "desc": "Alto mantenimiento · Requiere pesticidas"},
			{"id": "cactus",          "nombre": "Cactus",                  "desc": "Desértico · Sin sombra ni frescor"},
			{"id": "bambu",           "nombre": "Bambú Invasivo",          "desc": "Se expande sin control · Daña infraestructura"},
		],
		"feedback": {
			"helecho_tropical": "✅ El helecho tropical con pasto crea un suelo verde fresco de bajo mantenimiento. Ideal para reducir la temperatura en corredores de tránsito intenso.",
			"rosa_inglesa":      "❌ La rosa inglesa requiere pesticidas y riego frecuente. Es incompatible con los principios de sostenibilidad del campus.",
			"cactus":            "❌ El cactus no contribuye a refrescar el corredor ni ofrece sombra. No es adecuado para zonas de tránsito estudiantil.",
			"bambu":             "❌ El bambú invasivo se expande sin control y puede dañar la infraestructura del corredor. Su mantenimiento es costoso y frecuente.",
		},
	},
	{
		"id":       "plantar_sur",
		"zona":     "Zona Sur del Campus",
		"icono":    "🌳",
		"contexto": "La zona sur del campus recibe alta insolación todo el día. Estudiantes y docentes necesitan sombra durante el recorrido entre bloques.",
		"criterio": "Árbol de crecimiento rápido, copa amplia, resistente al calor de Maracaibo.",
		"correcta": "araguaney",
		"plantas":  [
			{"id": "araguaney",       "nombre": "Araguaney",         "desc": "Copa amplia · Resistente al calor · Nativo"},
			{"id": "pino_canadiense", "nombre": "Pino Canadiense",   "desc": "No se adapta al trópico · Clima frío"},
			{"id": "eucalipto",       "nombre": "Eucalipto",          "desc": "Especie invasiva · Perjudicial para otras plantas"},
			{"id": "rosa_inglesa",    "nombre": "Rosa Inglesa",       "desc": "Sin sombra · Alto mantenimiento"},
		],
		"feedback": {
			"araguaney":       "✅ El Araguaney ofrece sombra amplia y resiste el intenso calor maracaibero. Su floración amarilla también mejora la estética del campus.",
			"pino_canadiense": "❌ El pino canadiense no tolera el calor tropical de Maracaibo. Su forma cónica no proporciona suficiente sombra lateral.",
			"eucalipto":       "❌ El eucalipto es invasivo y sus raíces pueden dañar la infraestructura. Su alelopatía afecta a las plantas cercanas.",
			"rosa_inglesa":    "❌ La rosa inglesa no proporciona sombra suficiente y requiere cuidados intensivos que contradicen los principios de sostenibilidad.",
		},
	},
	{
		"id":       "plantar_oeste",
		"zona":     "Corredor Oeste Sur",
		"icono":    "🌺",
		"contexto": "El corredor oeste sur está junto al estacionamiento. Necesita plantas que actúen como barrera verde y mejoren la calidad del aire.",
		"criterio": "Plantas que filtren gases vehiculares y actúen como barrera visual natural.",
		"correcta": "buganvilia",
		"plantas":  [
			{"id": "buganvilia",     "nombre": "Buganvilia (Veranera)", "desc": "Resistente · Filtra el aire · Ornamental"},
			{"id": "eucalipto",      "nombre": "Eucalipto",             "desc": "Invasivo · Consume mucha agua"},
			{"id": "cactus",         "nombre": "Cactus",                "desc": "No filtra gases · Sin barrera visual"},
			{"id": "pino_canadiense","nombre": "Pino Canadiense",       "desc": "No se adapta al clima tropical"},
		],
		"feedback": {
			"buganvilia":     "✅ La Buganvilia forma una barrera verde densa y colorida. Resiste los gases vehiculares y mejora la estética del área junto al estacionamiento.",
			"eucalipto":      "❌ Aunque crece rápido, el eucalipto es invasivo y puede dañar la infraestructura del estacionamiento con sus raíces agresivas.",
			"cactus":         "❌ El cactus no forma una barrera visual efectiva ni filtra gases vehiculares. No es apropiado para esta zona de tránsito.",
			"pino_canadiense":"❌ El pino canadiense no se adapta al clima tropical de Maracaibo y no puede sobrevivir a las altas temperaturas de la región.",
		},
	},
]

# ── Constantes visuales ──────────────────────────────────────
const PANEL_W   : float = 960.0
const PANEL_H   : float = 620.0
const CARTA_W   : float = 195.0
const CARTA_H   : float = 210.0

# ── Constantes de la fase de plantación ──────────────────────
const PASO_CLICKS  : Array[int]    = [6, 1, 8]
const PASO_TITULOS : Array[String] = [
	"Paso 1/3 — 🪓  Abrir el hueco",
	"Paso 2/3 — 🌿  Colocar el árbol",
	"Paso 3/3 — 💧  Regar el árbol",
]
const PASO_DESCS : Array[String] = [
	"Haz clic repetidamente para cavar la tierra",
	"Haz clic para colocar el árbol en el hueco",
	"Haz clic repetidamente para regar y ver crecer el árbol",
]
const PASO_BTNS : Array[String] = [
	"  🪓  ¡Cavar!  ",
	"  🌿  ¡Plantar!  ",
	"  💧  ¡Regar!  ",
]

# ── Constantes modo drag ──────────────────────────────────────
const PASO_DRAG_UMBRAL : Array[float] = [180.0, 1.0, 220.0]
const PASO_TITULOS_DRAG : Array[String] = [
	"Paso 1/3 — 🖐  Rasca para cavar",
	"Paso 2/3 — 🌿  Coloca el árbol",
	"Paso 3/3 — 💧  Frota para regar",
]
const PASO_DESCS_DRAG : Array[String] = [
	"Mantén el clic y frota el mouse sobre la tierra para cavar",
	"Haz clic en el botón para colocar el árbol en el hueco",
	"Mantén el clic y frota para regar — ¡mira cómo crece!",
]
const PASO_BTNS_DRAG : Array[String] = [
	"  🖐  Frota aquí  ",
	"  🌿  ¡Plantar!  ",
	"  💧  Frota aquí  ",
]

# ── Estado ───────────────────────────────────────────────────
var _mision_idx     : int    = 0
var _mision_id      : String = ""
var _seleccion_ok   : bool   = false
var _zona_ref       : Area2D = null
var _planta_elegida : String = ""
var _paso_actual    : int    = 0
var _paso_progreso  : int    = 0
var _modo           : String = "click"   # "click" o "drag"
var _drag_pressed   : bool   = false
var _drag_acum      : float  = 0.0      # distancia acumulada de arrastre

# ── Nodos UI — fase 1 (selección) ────────────────────────────
var _panel_root     : Panel         = null
var _zona_lbl       : Label         = null
var _contexto_lbl   : Label         = null
var _criterio_lbl   : Label         = null
var _suelo_node     : Node2D        = null
var _cartas         : Array         = []
var _feedback_panel : Panel         = null
var _fb_icono       : Label         = null
var _fb_titulo      : Label         = null
var _fb_desc        : Label         = null
var _fb_btn         : Button        = null
var _pct_lbl        : Label         = null
var _nivel_badge    : Label         = null

# ── Nodos UI — fase 2 (plantación interactiva) ────────────────
var _plant_panel      : Panel      = null
var _plant_title_lbl  : Label      = null
var _plant_visual_node: Node2D     = null
var _paso_desc_lbl    : Label      = null
var _prog_bar         : ProgressBar = null
var _plant_btn        : Button     = null
var _drag_area        : Panel      = null   # área de frotado (modo drag)
var _drag_area_lbl    : Label      = null

# ── Inner class: ilustración de planta ───────────────────────
class PlantaVisual extends Node2D:
	var tipo : String = ""
	var _t   : float  = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		match tipo:
			"araguaney":       _araguaney()
			"buganvilia":      _buganvilia()
			"cactus":          _cactus()
			"eucalipto":       _eucalipto()
			"pino_canadiense": _pino()
			"rosa_inglesa":    _rosa()
			"bambu":           _bambu()
			"helecho_tropical":_helecho()
			_:                 _generico()

	func _araguaney() -> void:
		# Tronco marrón
		draw_rect(Rect2(-5, 2, 10, 30), Color(0.42, 0.26, 0.10))
		# Raíces (no invasivas, pequeñas)
		draw_line(Vector2(-5, 28), Vector2(-14, 34), Color(0.35, 0.20, 0.08), 2.0)
		draw_line(Vector2( 5, 28), Vector2( 14, 34), Color(0.35, 0.20, 0.08), 2.0)
		# Copa amarilla (flores de araguaney)
		draw_circle(Vector2( 0, -20), 26.0, Color(0.90, 0.72, 0.05, 0.92))
		draw_circle(Vector2(-14, -10), 18.0, Color(0.92, 0.76, 0.06, 0.85))
		draw_circle(Vector2( 14, -10), 18.0, Color(0.92, 0.76, 0.06, 0.85))
		draw_circle(Vector2(  0, -34), 16.0, Color(0.95, 0.80, 0.10, 0.82))
		# Flores amarillas individuales
		for i in 10:
			var a := float(i) / 10.0 * TAU
			var r := 18.0 + sin(_t * 2.0 + a) * 2.5
			var p := Vector2(cos(a) * r, sin(a) * r * 0.7 - 18)
			draw_circle(p, 3.5, Color(1.0, 0.90, 0.15))
		# Hojas verdes visibles bajo flores
		draw_circle(Vector2(-8, -8), 9.0, Color(0.18, 0.52, 0.14, 0.60))
		draw_circle(Vector2( 8, -8), 9.0, Color(0.18, 0.52, 0.14, 0.60))

	func _buganvilia() -> void:
		# Tallo principal
		draw_line(Vector2(0, 32), Vector2(-16, -4), Color(0.28, 0.48, 0.14), 3.0)
		draw_line(Vector2(0, 32), Vector2( 16, -4), Color(0.28, 0.48, 0.14), 3.0)
		draw_line(Vector2(-16, -4), Vector2(-22, -22), Color(0.28, 0.48, 0.14), 2.5)
		draw_line(Vector2( 16, -4), Vector2( 22, -22), Color(0.28, 0.48, 0.14), 2.5)
		draw_line(Vector2(0, 10), Vector2(0, -28), Color(0.28, 0.48, 0.14), 2.5)
		# Hojas verdes
		var hojas := [Vector2(-10, 8), Vector2(10, 8), Vector2(-6, -2), Vector2(6, -2)]
		for h in hojas:
			draw_circle(h, 7.0, Color(0.22, 0.58, 0.18, 0.75))
		# Brácteas / flores (fucsia/morado)
		var flores := [Vector2(-24, -24), Vector2(24, -24), Vector2(-10, -32),
					   Vector2(10, -32), Vector2(0, -36), Vector2(-18, -16), Vector2(18, -16)]
		for f in flores:
			for j in 5:
				var a := float(j) / 5.0 * TAU + _t * 0.5
				draw_circle(f + Vector2(cos(a), sin(a)) * 6.5, 4.5,
							Color(0.88, 0.20, 0.62, 0.90))
		# Centro amarillo de las flores
		for f in flores:
			draw_circle(f, 2.5, Color(1.0, 0.88, 0.15))

	func _cactus() -> void:
		# Suelo arenoso
		draw_arc(Vector2(0, 34), 22.0, 0.0, PI, 14, Color(0.72, 0.58, 0.30, 0.6), 8.0)
		# Cuerpo principal
		var body := PackedVector2Array([
			Vector2(-10, 32), Vector2(10, 32), Vector2(11, -22), Vector2(-11, -22)
		])
		draw_colored_polygon(body, Color(0.20, 0.52, 0.16))
		draw_arc(Vector2(0, -22), 11.0, PI, TAU, 14, Color(0.20, 0.52, 0.16), 22.0)
		# Brazos
		draw_rect(Rect2(-30, -8, 20, 10), Color(0.20, 0.52, 0.16))
		draw_arc(Vector2(-20, -8), 10.0, PI, TAU, 10, Color(0.20, 0.52, 0.16), 20.0)
		draw_rect(Rect2(10, -2, 20, 10), Color(0.20, 0.52, 0.16))
		draw_arc(Vector2(20, -2), 10.0, PI, TAU, 10, Color(0.20, 0.52, 0.16), 20.0)
		# Espinas
		for i in 12:
			var y_pos := -20.0 + float(i) * 4.5
			draw_line(Vector2(-11, y_pos), Vector2(-17, y_pos - 2), Color(0.85, 0.80, 0.60), 1.2)
			draw_line(Vector2( 11, y_pos), Vector2( 17, y_pos - 2), Color(0.85, 0.80, 0.60), 1.2)
		# Flor en la cima (pequeña)
		draw_circle(Vector2(0, -34), 6.0, Color(0.95, 0.30, 0.20))
		draw_circle(Vector2(0, -34), 3.0, Color(1.0, 0.85, 0.15))

	func _eucalipto() -> void:
		# Tronco delgado alto (árbol muy alto y estrecho)
		draw_rect(Rect2(-3, -32, 6, 64), Color(0.55, 0.48, 0.38))
		# Raíces invasivas (amplias y visibles)
		draw_line(Vector2(-3, 30), Vector2(-30, 36), Color(0.45, 0.35, 0.22), 3.0)
		draw_line(Vector2( 3, 30), Vector2( 30, 36), Color(0.45, 0.35, 0.22), 3.0)
		draw_line(Vector2(-3, 28), Vector2(-22, 40), Color(0.45, 0.35, 0.22), 2.0)
		draw_line(Vector2( 3, 28), Vector2( 22, 40), Color(0.45, 0.35, 0.22), 2.0)
		# Texto "INVASIVO" indicador (raíces)
		# Ramas plateadas (hojas de eucalipto son colgantes)
		for i in 8:
			var y := -28.0 + float(i) * 7.0
			var x_off := 10.0 + sin(float(i) * 0.8 + _t) * 4.0
			draw_line(Vector2(0, y), Vector2(-x_off, y + 8), Color(0.60, 0.72, 0.62), 2.0)
			draw_line(Vector2(0, y), Vector2( x_off, y + 8), Color(0.60, 0.72, 0.62), 2.0)
			# Hojas ovaladas plateadas-verdes
			draw_circle(Vector2(-x_off - 4, y + 10), 5.5, Color(0.58, 0.70, 0.60, 0.85))
			draw_circle(Vector2( x_off + 4, y + 10), 5.5, Color(0.58, 0.70, 0.60, 0.85))
		# Cruz roja de "especie invasiva"
		draw_line(Vector2(-18, -36), Vector2(18, -8), Color(0.88, 0.15, 0.15, 0.70), 3.0)
		draw_line(Vector2(-18, -8), Vector2(18, -36), Color(0.88, 0.15, 0.15, 0.70), 3.0)

	func _pino() -> void:
		# Tronco
		draw_rect(Rect2(-4, 18, 8, 18), Color(0.42, 0.28, 0.14))
		# Capas del pino (triángulos superpuestos)
		var capas := [
			{"y": 18.0, "w": 28.0}, {"y": 4.0,  "w": 22.0},
			{"y": -8.0, "w": 18.0}, {"y": -20.0,"w": 13.0},
		]
		for capa in capas:
			var pts := PackedVector2Array([
				Vector2(-(capa["w"] as float), capa["y"] as float),
				Vector2( (capa["w"] as float), capa["y"] as float),
				Vector2(0.0, (capa["y"] as float) - 18.0)
			])
			draw_colored_polygon(pts, Color(0.10, 0.30, 0.14))
			draw_line(pts[0], pts[2], Color(0.15, 0.40, 0.18), 1.5)
			draw_line(pts[1], pts[2], Color(0.15, 0.40, 0.18), 1.5)
		# Punta de la copa
		var top_pts := PackedVector2Array([
			Vector2(-9, -20), Vector2(9, -20), Vector2(0, -36)
		])
		draw_colored_polygon(top_pts, Color(0.10, 0.28, 0.12))
		# Nieve en punta (clima frío, especie foránea)
		draw_circle(Vector2(0, -34), 6.5, Color(0.92, 0.94, 0.96, 0.90))
		draw_arc(Vector2(-22, 4), 6.0, PI, TAU, 8, Color(0.90, 0.93, 0.96, 0.80), 8.0)
		draw_arc(Vector2( 22, 4), 6.0, PI, TAU, 8, Color(0.90, 0.93, 0.96, 0.80), 8.0)

	func _rosa() -> void:
		# Tallo con espinas
		draw_line(Vector2(0, 34), Vector2(0, -12), Color(0.18, 0.48, 0.14), 3.0)
		for i in 4:
			var y := 28.0 - float(i) * 10.0
			draw_line(Vector2(0, y), Vector2(6 if i%2 == 0 else -6, y - 5),
					  Color(0.18, 0.48, 0.14), 1.5)
		# Hojas
		draw_circle(Vector2(-10, 10), 8.0, Color(0.20, 0.55, 0.16))
		draw_circle(Vector2( 10, 10), 8.0, Color(0.20, 0.55, 0.16))
		# Pétalos rosa/rojo
		for i in 7:
			var a := float(i) / 7.0 * TAU
			draw_circle(Vector2(cos(a) * 10, sin(a) * 10 - 14), 9.0, Color(0.85, 0.12, 0.22, 0.90))
		# Centro de la rosa
		draw_circle(Vector2(0, -14), 7.0, Color(0.70, 0.08, 0.18))
		draw_circle(Vector2(0, -14), 3.5, Color(0.95, 0.50, 0.55))

	func _bambu() -> void:
		# 3 cañas de bambú (altas y apretadas → visualmente obstructivo)
		var canas := [Vector2(-10, 0), Vector2(0, 0), Vector2(10, 0)]
		for c in canas:
			draw_rect(Rect2((c as Vector2).x - 4, -36, 8, 70),
					  Color(0.20 + (c as Vector2).x * 0.005, 0.58, 0.18))
			# Nodos del bambú cada 12px
			for n in 5:
				var ynb := -32.0 + float(n) * 14.0
				draw_rect(Rect2((c as Vector2).x - 5, ynb, 10, 3),
						  Color(0.15, 0.45, 0.12))
		# Hojas en las cimas
		var leaf_positions := [Vector2(-20, -34), Vector2(0, -36), Vector2(20, -34),
							   Vector2(-12, -26), Vector2(12, -26)]
		for lp in leaf_positions:
			draw_circle(lp as Vector2, 7.0, Color(0.18, 0.60, 0.15, 0.85))

	func _helecho() -> void:
		# Pasto San Agustín (fondo verde bajo)
		var pts_grass := PackedVector2Array([
			Vector2(-36, 34), Vector2(36, 34), Vector2(36, 20), Vector2(-36, 20)
		])
		draw_colored_polygon(pts_grass, Color(0.22, 0.58, 0.16))
		# Briznas de pasto
		for i in 12:
			var gx := -32.0 + float(i) * 6.0
			draw_line(Vector2(gx, 20), Vector2(gx + sin(float(i)) * 4, 8),
					  Color(0.25, 0.68, 0.18), 2.0)
		# Helechos (palmas con hojas pinnadas)
		var centros := [Vector2(-14, 10), Vector2(14, 10), Vector2(0, 4)]
		for centro in centros:
			var cp := centro as Vector2
			# Pecíolo principal
			draw_line(cp, cp + Vector2(0, -18), Color(0.18, 0.52, 0.14), 2.5)
			# Pinas (hojillas) alternadas
			for n in 7:
				var y := -4.0 - float(n) * 2.5
				var xl := cp.x - 4.0 - float(n) * 0.8
				var xr := cp.x + 4.0 + float(n) * 0.8
				draw_circle(Vector2(xl, cp.y + y), 3.0, Color(0.20, 0.60, 0.18, 0.88))
				draw_circle(Vector2(xr, cp.y + y), 3.0, Color(0.20, 0.60, 0.18, 0.88))

	func _generico() -> void:
		draw_circle(Vector2(0, -10), 20.0, Color(0.20, 0.60, 0.20))
		draw_rect(Rect2(-4, 5, 8, 28), Color(0.42, 0.26, 0.10))

# ── Inner class: suelo animado ────────────────────────────────
class SueloVisual extends Node2D:
	var _t          : float  = 0.0
	var plantada    : bool   = false
	var tipo_planta : String = ""

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		# Fondo de tierra
		var pts := PackedVector2Array()
		for i in 36:
			var a := float(i) / 36.0 * TAU
			pts.append(Vector2(cos(a) * 64, sin(a) * 28))
		draw_colored_polygon(pts, Color(0.35, 0.22, 0.09))
		# Textura de tierra
		draw_arc(Vector2(0, 0), 60.0, 0.0, TAU, 36, Color(0.25, 0.14, 0.05), 4.0)
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		for _i in 20:
			var px := rng.randf_range(-54.0, 54.0)
			var py := rng.randf_range(-20.0, 20.0)
			draw_circle(Vector2(px, py), rng.randf_range(2.0, 5.0),
						Color(0.25, 0.14, 0.06, 0.55))
		# Hoyo central
		if not plantada:
			var puls := 1.0 + 0.15 * sin(_t * 3.5)
			draw_circle(Vector2(0, 0), 14.0 * puls, Color(0.18, 0.10, 0.03))
			draw_arc(Vector2(0, 0), 15.0 * puls, 0.0, TAU, 20,
					 Color(0.55, 0.88, 0.25, 0.5 + 0.3 * sin(_t * 2.0)), 2.0)
			# Flechas indicadoras de "plantar aquí"
			var arrow_a := _t * 0.8
			for j in 3:
				var a := arrow_a + float(j) / 3.0 * TAU
				var p := Vector2(cos(a) * 22, sin(a) * 22)
				draw_arc(p, 5.0, a + PI * 0.5, a + PI * 1.5, 8,
						 Color(0.45, 0.88, 0.25, 0.55), 2.0)
		else:
			# Planta creciendo
			var scale_y := minf(_t * 0.8, 1.0)
			var ga := 0.12 + 0.08 * sin(_t * 2.0)
			draw_circle(Vector2(0, -20), 30.0, Color(0.20, 0.80, 0.25, ga))

# ── Inner class: mini-juego de plantación ────────────────────
class PlantacionVisual extends Node2D:
	var paso        : int    = 0
	var progreso    : float  = 0.0
	var tipo_planta : String = ""
	var _t          : float  = 0.0

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		_dibujar_suelo()
		match paso:
			0: _cavar()
			1: _plantar()
			2: _regar()

	func _dibujar_suelo() -> void:
		var pts := PackedVector2Array()
		for i in 40:
			var a := float(i) / 40.0 * TAU
			pts.append(Vector2(cos(a) * 120.0, sin(a) * 46.0))
		draw_colored_polygon(pts, Color(0.38, 0.22, 0.08))
		var rng := RandomNumberGenerator.new()
		rng.seed = 88
		for _i in 28:
			var px := rng.randf_range(-108.0, 108.0)
			var py := rng.randf_range(-38.0, 38.0)
			draw_circle(Vector2(px, py), rng.randf_range(2.0, 5.5),
						Color(0.25, 0.13, 0.05, 0.55))
		draw_arc(Vector2.ZERO, 118.0, 0.0, TAU, 40, Color(0.22, 0.55, 0.14, 0.4), 6.0)

	func _cavar() -> void:
		var hole_r := progreso * 34.0
		if hole_r > 2.0:
			draw_circle(Vector2.ZERO, hole_r, Color(0.15, 0.08, 0.02))
			draw_arc(Vector2.ZERO, hole_r, 0.0, TAU, 24,
					 Color(0.50, 0.82, 0.22, 0.55), 2.5)
		for i in int(progreso * 7):
			var ai := float(i) / 7.0 * PI + _t * 1.4 + float(i) * 0.5
			var di := (32.0 + float(i) * 10.0) * progreso
			var p  := Vector2(cos(ai) * di, -44.0 - absf(sin(ai)) * di * 0.5)
			var al := maxf(0.0, 0.85 - progreso * 0.4 - float(i) * 0.06)
			if al > 0.05:
				draw_circle(p, 4.5, Color(0.38, 0.22, 0.08, al))
		var sx := -55.0 + sin(_t * (2.5 + progreso * 2.0)) * 14.0
		var sy := -110.0
		draw_line(Vector2(sx, sy), Vector2(sx + 9.0, sy + 72.0),
				  Color(0.55, 0.38, 0.18), 5.0)
		draw_rect(Rect2(sx + 3.0, sy + 68.0, 14.0, 20.0), Color(0.62, 0.65, 0.68))
		draw_rect(Rect2(sx - 2.0, sy - 8.0,  16.0,  9.0), Color(0.40, 0.25, 0.12))

	func _plantar() -> void:
		draw_circle(Vector2.ZERO, 33.0, Color(0.15, 0.08, 0.02))
		draw_arc(Vector2.ZERO, 33.0, 0.0, TAU, 24,
				 Color(0.50, 0.82, 0.22, 0.55), 2.5)
		var ty := -155.0 + progreso * 120.0
		_arbol(Vector2(0.0, ty), tipo_planta, 1.0)

	func _regar() -> void:
		draw_circle(Vector2.ZERO, 33.0, Color(0.15, 0.08, 0.02))
		var sc := 0.55 + progreso * 0.45
		_arbol(Vector2(0.0, -22.0 * sc), tipo_planta, sc)
		var cx := 140.0
		var cy := -90.0 + sin(_t * 0.9) * 8.0
		var body := PackedVector2Array([
			Vector2(cx - 30.0, cy - 12.0), Vector2(cx + 10.0, cy - 12.0),
			Vector2(cx + 10.0, cy + 16.0), Vector2(cx - 30.0, cy + 16.0)
		])
		draw_colored_polygon(body, Color(0.28, 0.62, 0.85))
		draw_line(Vector2(cx - 30.0, cy + 2.0), Vector2(cx - 56.0, cy + 24.0),
				  Color(0.22, 0.52, 0.78), 6.0)
		draw_arc(Vector2(cx + 10.0, cy + 4.0), 14.0, -PI * 0.5, PI * 0.5,
				 12, Color(0.22, 0.52, 0.78), 5.0)
		for i in 10:
			var dt  := fmod(_t * 1.8 + float(i) * 0.22, 1.0)
			var dxi := cx - 22.0 - float(i % 5) * 10.0
			var dyi := cy + 24.0 + dt * 90.0
			var al2 := (1.0 - dt) * progreso
			if al2 > 0.05:
				draw_circle(Vector2(dxi, dyi), 3.0, Color(0.30, 0.70, 0.95, al2))
		if progreso > 0.72:
			for i in 8:
				var ai := float(i) / 8.0 * TAU + _t * 0.9
				var ri := 72.0 + sin(_t * 2.0 + float(i)) * 10.0
				var pi := Vector2(cos(ai) * ri, sin(ai) * ri * 0.55 - 30.0)
				draw_circle(pi, 5.0, Color(1.0, 0.95, 0.20, (progreso - 0.72) / 0.28))

	func _arbol(pos: Vector2, tipo: String, sc: float) -> void:
		draw_rect(Rect2(pos.x - 4.0*sc, pos.y, 8.0*sc, 28.0*sc),
				  Color(0.40, 0.25, 0.10))
		match tipo:
			"araguaney":
				draw_circle(Vector2(pos.x, pos.y - 20.0*sc), 28.0*sc,
							Color(0.90, 0.72, 0.05))
				draw_circle(Vector2(pos.x - 14.0*sc, pos.y - 10.0*sc), 18.0*sc,
							Color(0.92, 0.76, 0.06))
				draw_circle(Vector2(pos.x + 14.0*sc, pos.y - 10.0*sc), 18.0*sc,
							Color(0.92, 0.76, 0.06))
			"buganvilia":
				draw_circle(Vector2(pos.x, pos.y - 20.0*sc), 24.0*sc,
							Color(0.22, 0.58, 0.18, 0.8))
				for j in 6:
					var a := float(j) / 6.0 * TAU + _t * 0.4
					draw_circle(
						Vector2(pos.x + cos(a)*20.0*sc, pos.y - 20.0*sc + sin(a)*12.0*sc),
						7.0*sc, Color(0.88, 0.20, 0.62))
			"helecho_tropical":
				draw_circle(Vector2(pos.x, pos.y - 16.0*sc), 30.0*sc,
							Color(0.22, 0.62, 0.22, 0.85))
				draw_circle(Vector2(pos.x - 18.0*sc, pos.y - 6.0*sc), 18.0*sc,
							Color(0.25, 0.68, 0.25, 0.80))
				draw_circle(Vector2(pos.x + 18.0*sc, pos.y - 6.0*sc), 18.0*sc,
							Color(0.25, 0.68, 0.25, 0.80))
			_:
				draw_circle(Vector2(pos.x, pos.y - 20.0*sc), 26.0*sc,
							Color(0.18, 0.65, 0.20))
				draw_circle(Vector2(pos.x - 14.0*sc, pos.y - 10.0*sc), 17.0*sc,
							Color(0.20, 0.68, 0.20))
				draw_circle(Vector2(pos.x + 14.0*sc, pos.y - 10.0*sc), 17.0*sc,
							Color(0.20, 0.68, 0.20))


# ── _ready ────────────────────────────────────────────────────
func _ready() -> void:
	layer = 20
	add_to_group("mision_plantar")
	_crear_ui()
	_crear_panel_plantacion()
	hide()


func iniciar(indice: int, zona_node: Area2D, modo: String = "click") -> void:
	_mision_idx     = clampi(indice, 0, MISIONES.size() - 1)
	_zona_ref       = zona_node
	_modo           = modo
	_seleccion_ok   = false
	_planta_elegida = ""
	_paso_actual    = 0
	_paso_progreso  = 0
	_drag_pressed   = false
	_drag_acum      = 0.0
	SupabaseManager.registrar_evento(1, str(MISIONES[_mision_idx].get("id", "")),
		"mision_iniciada", {"modo": modo})
	_feedback_panel.visible = false
	if is_instance_valid(_plant_panel):
		_plant_panel.visible = false
	_panel_root.visible = true
	for c in _cartas:
		_resetear_carta(c)
	_poblar_datos()
	show()
	var hb = get_tree().get_first_node_in_group("hint_bubble")
	if hb:
		var msg := "🌱 Elige la planta correcta para esta zona." if modo == "click" \
			else "🖐 ¡Zona de área verde! Elegirás la planta y luego frotarás el mouse para plantarla."
		hb.push("primer_plantar", msg)


# ── Poblar con datos del mision_idx actual ───────────────────
func _poblar_datos() -> void:
	var m : Dictionary = MISIONES[_mision_idx]
	_mision_id = m["id"]

	_zona_lbl.text      = "%s  %s" % [m["icono"], m["zona"]]
	_contexto_lbl.text  = m["contexto"]
	_criterio_lbl.text  = "📋 " + m["criterio"]

	# Progreso nivel 1
	var nm = _nivel_mgr()
	var pct : float = nm.pct_nivel(1) if nm else 0.0
	_pct_lbl.text = "NIVEL 1  ·  %.0f%% completado" % (pct * 100.0)

	var plantas : Array = m["plantas"].duplicate()
	plantas.shuffle()
	for i in _cartas.size():
		var carta : Panel = _cartas[i]
		if i >= plantas.size(): continue
		var pdata : Dictionary = plantas[i]
		_configurar_carta(carta, pdata["id"], pdata["nombre"], pdata["desc"],
						  pdata["id"] == m["correcta"])


# ── Crear UI ──────────────────────────────────────────────────
func _crear_ui() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color        = Color(0.0, 0.0, 0.0, 0.88)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	_panel_root = Panel.new()
	_panel_root.custom_minimum_size = Vector2(PANEL_W, PANEL_H)
	_panel_root.set_anchors_preset(Control.PRESET_CENTER)
	_panel_root.offset_left   = -PANEL_W * 0.5
	_panel_root.offset_top    = -PANEL_H * 0.5
	_panel_root.offset_right  =  PANEL_W * 0.5
	_panel_root.offset_bottom =  PANEL_H * 0.5
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.08, 0.06, 0.98)
	ps.border_color = Color(0.20, 0.80, 0.25)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(18)
	ps.shadow_color = Color(0.10, 0.55, 0.18, 0.55)
	ps.shadow_size  = 28
	_panel_root.add_theme_stylebox_override("panel", ps)
	add_child(_panel_root)

	# Franja verde superior
	var acento := ColorRect.new()
	acento.set_anchors_preset(Control.PRESET_TOP_WIDE)
	acento.custom_minimum_size = Vector2(0, 4)
	acento.offset_bottom       = 4.0
	acento.color               = Color(0.22, 0.88, 0.30, 0.80)
	acento.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	_panel_root.add_child(acento)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for key in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(key, 22)
	_panel_root.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	mg.add_child(vbox)

	# ── Encabezado ────────────────────────────────────────────
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var btn_salir := Button.new()
	btn_salir.text = "← Salir"
	btn_salir.custom_minimum_size = Vector2(80, 32)
	btn_salir.add_theme_font_size_override("font_size", 12)
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.18, 0.06, 0.06, 0.90)
	bs.border_color = Color(0.65, 0.15, 0.15)
	bs.set_border_width_all(2)
	bs.set_corner_radius_all(8)
	btn_salir.add_theme_stylebox_override("normal", bs)
	btn_salir.add_theme_color_override("font_color", Color(0.95, 0.55, 0.55))
	btn_salir.pressed.connect(_on_salir)
	header.add_child(btn_salir)

	_zona_lbl = Label.new()
	_zona_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_zona_lbl.add_theme_font_size_override("font_size", 19)
	_zona_lbl.add_theme_color_override("font_color", Color(0.88, 1.0, 0.88))
	header.add_child(_zona_lbl)

	_nivel_badge = Label.new()
	_nivel_badge.text = "🌿 NIVEL 1"
	_nivel_badge.add_theme_font_size_override("font_size", 12)
	_nivel_badge.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55))
	header.add_child(_nivel_badge)

	# Separador
	var sep_s := StyleBoxFlat.new()
	sep_s.bg_color = Color(0.22, 0.72, 0.22, 0.35)
	sep_s.content_margin_top    = 1.0
	sep_s.content_margin_bottom = 1.0
	var sep := HSeparator.new()
	sep.add_theme_stylebox_override("separator", sep_s)
	vbox.add_child(sep)

	# ── Fila de contenido ─────────────────────────────────────
	var content_row := HBoxContainer.new()
	content_row.add_theme_constant_override("separation", 18)
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(content_row)

	# Columna izquierda: contexto + suelo
	var col_izq := VBoxContainer.new()
	col_izq.custom_minimum_size   = Vector2(230, 0)
	col_izq.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col_izq.add_theme_constant_override("separation", 10)
	content_row.add_child(col_izq)

	_contexto_lbl = Label.new()
	_contexto_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_contexto_lbl.add_theme_font_size_override("font_size", 12)
	_contexto_lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.75))
	col_izq.add_child(_contexto_lbl)

	_criterio_lbl = Label.new()
	_criterio_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_criterio_lbl.add_theme_font_size_override("font_size", 11)
	_criterio_lbl.add_theme_color_override("font_color", Color(0.55, 0.88, 0.60))
	col_izq.add_child(_criterio_lbl)

	# Contenedor visual del suelo
	var suelo_cont := Control.new()
	suelo_cont.custom_minimum_size   = Vector2(140, 100)
	suelo_cont.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	suelo_cont.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col_izq.add_child(suelo_cont)

	_suelo_node = SueloVisual.new()
	_suelo_node.position = Vector2(70, 50)
	suelo_cont.add_child(_suelo_node)

	_pct_lbl = Label.new()
	_pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pct_lbl.add_theme_font_size_override("font_size", 11)
	_pct_lbl.add_theme_color_override("font_color", Color(0.40, 0.80, 0.45))
	col_izq.add_child(_pct_lbl)

	# Separador vertical
	var vsep := VSeparator.new()
	var vss := StyleBoxFlat.new()
	vss.bg_color = Color(0.22, 0.72, 0.22, 0.30)
	vss.content_margin_left = 1.0
	vsep.add_theme_stylebox_override("separator", vss)
	content_row.add_child(vsep)

	# Columna derecha: cuadrícula de plantas
	var col_der := VBoxContainer.new()
	col_der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_der.add_theme_constant_override("separation", 10)
	content_row.add_child(col_der)

	var instruccion := Label.new()
	instruccion.text = "🔍  Selecciona la planta más adecuada para esta zona:"
	instruccion.add_theme_font_size_override("font_size", 13)
	instruccion.add_theme_color_override("font_color", Color(0.88, 0.92, 0.88))
	col_der.add_child(instruccion)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	col_der.add_child(grid)

	_cartas = []
	for _i in 4:
		var carta := _crear_carta()
		grid.add_child(carta)
		_cartas.append(carta)

	# ── Panel de feedback (oculto) ────────────────────────────
	_crear_panel_feedback()


func _crear_carta() -> Panel:
	var carta := Panel.new()
	carta.custom_minimum_size = Vector2(CARTA_W, CARTA_H)
	var cs := StyleBoxFlat.new()
	cs.bg_color     = Color(0.06, 0.12, 0.08, 0.95)
	cs.border_color = Color(0.20, 0.55, 0.22)
	cs.set_border_width_all(2)
	cs.set_corner_radius_all(12)
	cs.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	cs.shadow_size  = 6
	carta.add_theme_stylebox_override("panel", cs)
	carta.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	carta.gui_input.connect(_on_carta_input.bind(carta))

	# Zona de ilustración de la planta
	var visual_cont := Control.new()
	visual_cont.set_anchors_preset(Control.PRESET_TOP_WIDE)
	visual_cont.custom_minimum_size = Vector2(0, 110)
	visual_cont.offset_bottom = 110.0
	visual_cont.clip_contents = true
	carta.add_child(visual_cont)

	var pv := PlantaVisual.new()
	pv.position = Vector2(CARTA_W * 0.5, 72)
	visual_cont.add_child(pv)
	carta.set_meta("planta_visual", pv)

	# Nombre de la planta
	var nombre_lbl := Label.new()
	nombre_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	nombre_lbl.offset_top    = -70.0
	nombre_lbl.offset_bottom = -44.0
	nombre_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nombre_lbl.add_theme_font_size_override("font_size", 12)
	nombre_lbl.add_theme_color_override("font_color", Color(0.90, 0.96, 0.90))
	carta.add_child(nombre_lbl)
	carta.set_meta("nombre_lbl", nombre_lbl)

	# Descripción
	var desc_lbl := Label.new()
	desc_lbl.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	desc_lbl.offset_top    = -44.0
	desc_lbl.offset_bottom = -6.0
	desc_lbl.offset_left   = 6.0
	desc_lbl.offset_right  = -6.0
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_font_size_override("font_size", 9)
	desc_lbl.add_theme_color_override("font_color", Color(0.60, 0.72, 0.62))
	carta.add_child(desc_lbl)
	carta.set_meta("desc_lbl", desc_lbl)

	carta.set_meta("planta_id",  "")
	carta.set_meta("es_correcta", false)
	return carta


func _configurar_carta(carta: Panel, pid: String, nombre: String,
					   desc: String, es_correcta: bool) -> void:
	carta.set_meta("planta_id",   pid)
	carta.set_meta("es_correcta", es_correcta)
	(carta.get_meta("nombre_lbl") as Label).text = nombre
	(carta.get_meta("desc_lbl") as Label).text   = desc
	(carta.get_meta("planta_visual") as PlantaVisual).tipo = pid


func _resetear_carta(carta: Panel) -> void:
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.06, 0.12, 0.08, 0.95)
	ps.border_color = Color(0.20, 0.55, 0.22)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(12)
	ps.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	ps.shadow_size  = 6
	carta.add_theme_stylebox_override("panel", ps)
	carta.modulate = Color.WHITE


func _on_carta_input(event: InputEvent, carta: Panel) -> void:
	if not (event is InputEventMouseButton): return
	var ev := event as InputEventMouseButton
	if not (ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT): return
	if _seleccion_ok: return
	_procesar_seleccion(carta)


func _procesar_seleccion(carta: Panel) -> void:
	var pid        : String = carta.get_meta("planta_id")
	var es_ok      : bool   = carta.get_meta("es_correcta")
	var m          : Dictionary = MISIONES[_mision_idx]
	var feedback_txt : String = m["feedback"].get(pid, "Respuesta no reconocida.")

	if es_ok:
		_seleccion_ok   = true
		_planta_elegida = pid
		_animar_carta_ok(carta)
		_mostrar_feedback(true, "¡Planta correcta!", feedback_txt)
	else:
		_animar_carta_mal(carta)
		_mostrar_feedback(false, "Planta incorrecta", feedback_txt)


func _animar_carta_ok(carta: Panel) -> void:
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.06, 0.28, 0.10, 0.98)
	ps.border_color = Color(0.22, 0.90, 0.28)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(12)
	carta.add_theme_stylebox_override("panel", ps)
	var tw := carta.create_tween()
	tw.tween_property(carta, "scale", Vector2(1.06, 1.06), 0.10)
	tw.tween_property(carta, "scale", Vector2(1.0,  1.0),  0.10)


func _animar_carta_mal(carta: Panel) -> void:
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.20, 0.04, 0.04, 0.98)
	ps.border_color = Color(0.88, 0.18, 0.18)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(12)
	carta.add_theme_stylebox_override("panel", ps)
	var tw := carta.create_tween()
	tw.tween_property(carta, "position:x", carta.position.x + 6, 0.06)
	tw.tween_property(carta, "position:x", carta.position.x - 6, 0.06)
	tw.tween_property(carta, "position:x", carta.position.x, 0.06)


func _crear_panel_feedback() -> void:
	_feedback_panel = Panel.new()
	_feedback_panel.set_anchors_preset(Control.PRESET_CENTER)
	_feedback_panel.custom_minimum_size = Vector2(560, 220)
	_feedback_panel.offset_left   = -280.0
	_feedback_panel.offset_top    = -110.0
	_feedback_panel.offset_right  =  280.0
	_feedback_panel.offset_bottom =  110.0
	_feedback_panel.visible       = false
	var fps := StyleBoxFlat.new()
	fps.bg_color     = Color(0.04, 0.06, 0.04, 0.98)
	fps.border_color = Color(0.22, 0.82, 0.28)
	fps.set_border_width_all(3)
	fps.set_corner_radius_all(16)
	fps.shadow_color = Color(0.10, 0.55, 0.18, 0.60)
	fps.shadow_size  = 20
	_feedback_panel.add_theme_stylebox_override("panel", fps)
	add_child(_feedback_panel)

	var fmg := MarginContainer.new()
	fmg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in ["margin_left","margin_right","margin_top","margin_bottom"]:
		fmg.add_theme_constant_override(k, 24)
	_feedback_panel.add_child(fmg)

	var fvbox := VBoxContainer.new()
	fvbox.add_theme_constant_override("separation", 12)
	fmg.add_child(fvbox)

	_fb_icono = Label.new()
	_fb_icono.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fb_icono.add_theme_font_size_override("font_size", 36)
	fvbox.add_child(_fb_icono)

	_fb_titulo = Label.new()
	_fb_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fb_titulo.add_theme_font_size_override("font_size", 18)
	_fb_titulo.add_theme_color_override("font_color", Color.WHITE)
	fvbox.add_child(_fb_titulo)

	_fb_desc = Label.new()
	_fb_desc.autowrap_mode       = TextServer.AUTOWRAP_WORD
	_fb_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fb_desc.size_flags_vertical  = Control.SIZE_EXPAND_FILL
	_fb_desc.add_theme_font_size_override("font_size", 13)
	_fb_desc.add_theme_color_override("font_color", Color(0.82, 0.88, 0.82))
	fvbox.add_child(_fb_desc)

	_fb_btn = Button.new()
	_fb_btn.text = "  Continuar  ▶  "
	_fb_btn.custom_minimum_size = Vector2(200, 44)
	_fb_btn.add_theme_font_size_override("font_size", 14)
	var fbs := StyleBoxFlat.new()
	fbs.bg_color     = Color(0.06, 0.34, 0.08)
	fbs.border_color = Color(0.22, 0.84, 0.22)
	fbs.set_border_width_all(2)
	fbs.set_corner_radius_all(12)
	_fb_btn.add_theme_stylebox_override("normal", fbs)
	_fb_btn.pressed.connect(_on_feedback_continuar)
	fvbox.add_child(_fb_btn)


func _crear_panel_plantacion() -> void:
	_plant_panel = Panel.new()
	_plant_panel.custom_minimum_size = Vector2(720, 530)
	_plant_panel.set_anchors_preset(Control.PRESET_CENTER)
	_plant_panel.offset_left   = -360.0
	_plant_panel.offset_top    = -265.0
	_plant_panel.offset_right  =  360.0
	_plant_panel.offset_bottom =  265.0
	_plant_panel.visible = false
	var pp_st := StyleBoxFlat.new()
	pp_st.bg_color     = Color(0.04, 0.08, 0.06, 0.98)
	pp_st.border_color = Color(0.20, 0.80, 0.25)
	pp_st.set_border_width_all(3)
	pp_st.set_corner_radius_all(18)
	pp_st.shadow_color = Color(0.10, 0.55, 0.18, 0.55)
	pp_st.shadow_size  = 28
	_plant_panel.add_theme_stylebox_override("panel", pp_st)
	add_child(_plant_panel)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left   =  22.0
	vb.offset_top    =  18.0
	vb.offset_right  = -22.0
	vb.offset_bottom = -18.0
	vb.add_theme_constant_override("separation", 10)
	_plant_panel.add_child(vb)

	var header2 := HBoxContainer.new()
	header2.add_theme_constant_override("separation", 10)
	vb.add_child(header2)

	var btn_salir2 := Button.new()
	btn_salir2.text = "← Salir"
	btn_salir2.custom_minimum_size = Vector2(80, 32)
	btn_salir2.add_theme_font_size_override("font_size", 12)
	var bs2 := StyleBoxFlat.new()
	bs2.bg_color     = Color(0.18, 0.06, 0.06, 0.90)
	bs2.border_color = Color(0.65, 0.15, 0.15)
	bs2.set_border_width_all(2)
	bs2.set_corner_radius_all(8)
	btn_salir2.add_theme_stylebox_override("normal", bs2)
	btn_salir2.add_theme_color_override("font_color", Color(0.95, 0.55, 0.55))
	btn_salir2.pressed.connect(_on_salir)
	header2.add_child(btn_salir2)

	_plant_title_lbl = Label.new()
	_plant_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_plant_title_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	_plant_title_lbl.add_theme_font_size_override("font_size", 20)
	_plant_title_lbl.add_theme_color_override("font_color", Color(0.30, 1.00, 0.40))
	header2.add_child(_plant_title_lbl)

	var vis_cont := Control.new()
	vis_cont.custom_minimum_size   = Vector2(0, 270)
	vis_cont.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vis_cont.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	vis_cont.clip_contents         = true
	vb.add_child(vis_cont)

	_plant_visual_node = PlantacionVisual.new()
	_plant_visual_node.position = Vector2(338, 200)
	vis_cont.add_child(_plant_visual_node)

	_paso_desc_lbl = Label.new()
	_paso_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_paso_desc_lbl.add_theme_font_size_override("font_size", 14)
	_paso_desc_lbl.add_theme_color_override("font_color", Color(0.80, 0.92, 0.80))
	vb.add_child(_paso_desc_lbl)

	_prog_bar = ProgressBar.new()
	_prog_bar.custom_minimum_size   = Vector2(0, 24)
	_prog_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prog_bar.min_value             = 0.0
	_prog_bar.max_value             = 1.0
	_prog_bar.value                 = 0.0
	_prog_bar.show_percentage       = false
	vb.add_child(_prog_bar)

	_plant_btn = Button.new()
	_plant_btn.custom_minimum_size = Vector2(220, 52)
	_plant_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_plant_btn.add_theme_font_size_override("font_size", 18)
	var pb_st := StyleBoxFlat.new()
	pb_st.bg_color     = Color(0.06, 0.34, 0.08)
	pb_st.border_color = Color(0.22, 0.84, 0.22)
	pb_st.set_border_width_all(2)
	pb_st.set_corner_radius_all(14)
	_plant_btn.add_theme_stylebox_override("normal", pb_st)
	_plant_btn.add_theme_color_override("font_color", Color(0.88, 1.0, 0.88))
	_plant_btn.pressed.connect(_on_plantar_btn)
	vb.add_child(_plant_btn)

	# ── Área de frotado (modo drag) ────────────────────────────
	_drag_area = Panel.new()
	_drag_area.custom_minimum_size   = Vector2(340, 52)
	_drag_area.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_drag_area.mouse_default_cursor_shape = Control.CURSOR_CROSS
	_drag_area.visible = false
	var da_st := StyleBoxFlat.new()
	da_st.bg_color     = Color(0.30, 0.18, 0.06, 0.90)
	da_st.border_color = Color(0.65, 0.42, 0.18)
	da_st.set_border_width_all(2)
	da_st.set_corner_radius_all(12)
	_drag_area.add_theme_stylebox_override("panel", da_st)
	_drag_area.gui_input.connect(_on_drag_area_input)
	vb.add_child(_drag_area)

	_drag_area_lbl = Label.new()
	_drag_area_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_drag_area_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_drag_area_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_drag_area_lbl.add_theme_font_size_override("font_size", 16)
	_drag_area_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.45))
	_drag_area_lbl.text = "  🖐  Frota aquí  "
	_drag_area.add_child(_drag_area_lbl)


func _on_drag_area_input(event: InputEvent) -> void:
	# Guard: _completar_plantacion() no oculta este panel cuando el último
	# paso es de arrastre, así que puede seguir recibiendo input con
	# _paso_actual ya fuera de rango (índice one-past-the-end) — sin esto,
	# PASO_DRAG_UMBRAL[_paso_actual] revienta con "Out of bounds".
	if _paso_actual >= PASO_DRAG_UMBRAL.size(): return
	if event is InputEventMouseButton:
		var ev := event as InputEventMouseButton
		_drag_pressed = ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventMouseMotion and _drag_pressed:
		var ev   := event as InputEventMouseMotion
		var dist : float = ev.relative.length()
		_drag_acum += dist
		var umbral : float = PASO_DRAG_UMBRAL[_paso_actual]
		var pct    : float = clampf(_drag_acum / umbral, 0.0, 1.0)
		if is_instance_valid(_plant_visual_node):
			(_plant_visual_node as PlantacionVisual).progreso = pct
		_prog_bar.value = _drag_acum
		if _drag_acum >= umbral:
			_drag_acum = 0.0
			_drag_pressed = false
			_avanzar_paso()


func _iniciar_plantacion() -> void:
	_paso_actual   = 0
	_paso_progreso = 0
	_drag_pressed  = false
	_drag_acum     = 0.0
	if is_instance_valid(_plant_visual_node):
		var pv := _plant_visual_node as PlantacionVisual
		pv.paso        = 0
		pv.progreso    = 0.0
		pv.tipo_planta = _planta_elegida
	if is_instance_valid(_plant_btn):
		_plant_btn.disabled = false
	_actualizar_paso_ui()
	_panel_root.visible  = false
	_plant_panel.visible = true
	_plant_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_plant_panel, "modulate:a", 1.0, 0.25)


func _actualizar_paso_ui() -> void:
	_drag_pressed = false
	_drag_acum    = 0.0
	if _modo == "drag":
		_plant_title_lbl.text = PASO_TITULOS_DRAG[_paso_actual]
		_paso_desc_lbl.text   = PASO_DESCS_DRAG[_paso_actual]
		_prog_bar.max_value   = PASO_DRAG_UMBRAL[_paso_actual]
		_prog_bar.value       = 0.0
		# Paso 2 siempre usa botón; pasos 1 y 3 usan área drag
		var es_drag_step := (_paso_actual != 1)
		_drag_area.visible = es_drag_step
		_plant_btn.visible = not es_drag_step
		if es_drag_step:
			_drag_area_lbl.text = PASO_BTNS_DRAG[_paso_actual]
			# Color según el paso
			var da_st := StyleBoxFlat.new()
			da_st.set_corner_radius_all(12)
			da_st.set_border_width_all(2)
			if _paso_actual == 0:   # cavar → marrón tierra
				da_st.bg_color     = Color(0.30, 0.18, 0.06, 0.90)
				da_st.border_color = Color(0.65, 0.42, 0.18)
				_drag_area_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.45))
			else:                   # regar → azul agua (paso 2)
				da_st.bg_color     = Color(0.04, 0.18, 0.32, 0.90)
				da_st.border_color = Color(0.22, 0.60, 0.90)
				_drag_area_lbl.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
			_drag_area.add_theme_stylebox_override("panel", da_st)
		else:
			_plant_btn.text = PASO_BTNS[1]
	else:
		_plant_title_lbl.text = PASO_TITULOS[_paso_actual]
		_paso_desc_lbl.text   = PASO_DESCS[_paso_actual]
		_plant_btn.text       = PASO_BTNS[_paso_actual]
		_prog_bar.max_value   = float(PASO_CLICKS[_paso_actual])
		_prog_bar.value       = 0.0
		_drag_area.visible    = false
		_plant_btn.visible    = true


func _on_plantar_btn() -> void:
	_paso_progreso += 1
	if is_instance_valid(_plant_visual_node):
		(_plant_visual_node as PlantacionVisual).progreso = \
			float(_paso_progreso) / float(PASO_CLICKS[_paso_actual])
	_prog_bar.value = float(_paso_progreso)
	if _paso_progreso >= PASO_CLICKS[_paso_actual]:
		_avanzar_paso()


func _avanzar_paso() -> void:
	_paso_actual   += 1
	_paso_progreso  = 0
	if _paso_actual >= PASO_CLICKS.size():
		_completar_plantacion()
		return
	if is_instance_valid(_plant_visual_node):
		var pv := _plant_visual_node as PlantacionVisual
		pv.paso     = _paso_actual
		pv.progreso = 0.0
	_actualizar_paso_ui()


func _completar_plantacion() -> void:
	if is_instance_valid(_plant_visual_node):
		(_plant_visual_node as PlantacionVisual).progreso = 1.0
	if is_instance_valid(_plant_btn):
		_plant_btn.disabled = true
	# Causa de fondo del crash: en modo drag no había un equivalente a
	# "disabled" para el panel de frotar — quedaba visible y receptivo.
	if is_instance_valid(_drag_area):
		_drag_area.visible = false
	_plant_title_lbl.text = "🎉 ¡Árbol plantado con éxito!"
	_paso_desc_lbl.text   = "¡El árbol quedó plantado en el campus URBE!"
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_callback(_mostrar_panel_metricas_planta)


func _mostrar_panel_metricas_planta() -> void:
	var nm   = _nivel_mgr()
	var xp   : int    = int(nm.XP_POR_MISION.get(1, 40)) if nm else 40
	var ec   : int    = int(nm.EC_POR_MISION.get(1, 15)) if nm else 15
	var m    : Dictionary = MISIONES[_mision_idx]
	var zona : String = m["zona"]
	var tipo : String = _planta_elegida

	var detalle : String
	match tipo:
		"araguaney":
			detalle = "🌡  Copa amplia → −2 °C en la zona\n" \
				+ "🐝  Flores amarillas → atrae polinizadores nativos\n" \
				+ "🏛  Árbol Nacional de Venezuela — identidad y cultura"
		"buganvilia":
			detalle = "💨  Barrera verde densa → filtra partículas del aire\n" \
				+ "🌸  Floración continua → fomenta biodiversidad local\n" \
				+ "💧  Bajo consumo hídrico — resistente a sequías"
		"helecho_tropical":
			detalle = "💧  Cobertura del suelo → mejora el drenaje\n" \
				+ "🌬  Evapotranspiración natural → refresca el aire\n" \
				+ "🌿  Hábitat para insectos y microorganismos del suelo"
		_:
			detalle = "🌿  Vegetación nativa adaptada al clima tropical\n" \
				+ "💧  Retención hídrica y mejora del suelo\n" \
				+ "🐝  Fomenta la biodiversidad del campus"

	var met := Panel.new()
	met.set_anchors_preset(Control.PRESET_CENTER)
	met.custom_minimum_size = Vector2(520, 390)
	met.offset_left  = -260.0; met.offset_top    = -195.0
	met.offset_right =  260.0; met.offset_bottom =  195.0
	var mps := StyleBoxFlat.new()
	mps.bg_color     = Color(0.04, 0.08, 0.06, 0.99)
	mps.border_color = Color(0.22, 0.90, 0.28)
	mps.set_border_width_all(3)
	mps.set_corner_radius_all(16)
	mps.shadow_color = Color(0.10, 0.55, 0.18, 0.55)
	mps.shadow_size  = 24
	met.add_theme_stylebox_override("panel", mps)
	add_child(met)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 20; vb.offset_top = 16
	vb.offset_right = -20; vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 9)
	met.add_child(vb)

	var tit := Label.new()
	tit.text = "🌳 ¡Árbol plantado!\n%s — %s" % [m["icono"], zona]
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.add_theme_font_size_override("font_size", 15)
	tit.add_theme_color_override("font_color", Color(0.30, 1.00, 0.40))
	tit.autowrap_mode = TextServer.AUTOWRAP_WORD
	vb.add_child(tit)

	var sep1 := HSeparator.new()
	sep1.add_theme_color_override("color", Color(0.22, 0.88, 0.30, 0.4))
	vb.add_child(sep1)

	var sub := Label.new()
	sub.text = "🏆  Impacto en las métricas GreenMetric URBE"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55))
	vb.add_child(sub)

	var met_lbl := Label.new()
	met_lbl.text = (
		"🏛  Infraestructura y Configuración\n"
		+ "   • Espacio verde activo en el campus\n"
		+ "   • Vegetación nativa adaptada al trópico\n\n"
		+ "⚡  Energía y Cambio Climático\n"
		+ "   • Absorción de CO₂: ~12 kg/año\n"
		+ "   • Reducción térmica: ↓ 1.5 °C en el área\n\n"
		+ "💧  Agua\n"
		+ "   • Mejora el drenaje y la retención hídrica del suelo\n\n"
		+ "🌿  Detalle — %s\n%s" % [tipo.replace("_", " ").capitalize(), detalle]
	)
	met_lbl.autowrap_mode       = TextServer.AUTOWRAP_WORD
	met_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	met_lbl.add_theme_font_size_override("font_size", 11)
	met_lbl.add_theme_color_override("font_color", Color(0.80, 0.92, 0.80))
	vb.add_child(met_lbl)

	var sep2 := HSeparator.new()
	sep2.add_theme_color_override("color", Color(0.22, 0.88, 0.30, 0.3))
	vb.add_child(sep2)

	var recomp := Label.new()
	recomp.text = "+%d XP   ·   +%d EcoCredits" % [xp, ec]
	recomp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recomp.add_theme_font_size_override("font_size", 14)
	recomp.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55))
	vb.add_child(recomp)

	var btn := Button.new()
	btn.text = "  ¡Genial!  ✓  "
	btn.custom_minimum_size   = Vector2(180, 44)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 14)
	var bst := StyleBoxFlat.new()
	bst.bg_color = Color(0.06, 0.30, 0.08); bst.border_color = Color(0.22, 0.84, 0.22)
	bst.set_border_width_all(2); bst.set_corner_radius_all(12)
	btn.add_theme_stylebox_override("normal", bst)
	btn.add_theme_color_override("font_color", Color(0.88, 1.0, 0.88))
	btn.pressed.connect(func():
		met.queue_free()
		_completar_mision()
		_plant_panel.visible = false
		hide()
	)
	vb.add_child(btn)

	met.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(met, "modulate:a", 1.0, 0.25)


func _mostrar_feedback(correcto: bool, titulo: String, desc: String) -> void:
	_fb_icono.text  = "🌱" if correcto else "❌"
	_fb_titulo.text = titulo
	_fb_titulo.add_theme_color_override("font_color",
		Color(0.30, 0.95, 0.35) if correcto else Color(0.95, 0.35, 0.30))
	_fb_desc.text   = desc
	_fb_btn.text    = "  ¡A plantar! 🌱  " if correcto else "  Intentar de nuevo  "

	_feedback_panel.modulate.a = 0.0
	_feedback_panel.visible    = true
	var tw := create_tween()
	tw.tween_property(_feedback_panel, "modulate:a", 1.0, 0.22)
	tw.parallel().tween_property(_feedback_panel, "scale",
		Vector2(1.0, 1.0), 0.22).from(Vector2(0.85, 0.85))


func _on_feedback_continuar() -> void:
	_feedback_panel.visible = false
	if _seleccion_ok:
		_iniciar_plantacion()


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _completar_mision() -> void:
	SupabaseManager.registrar_evento(1, _mision_id, "mision_completada",
		{"planta": _planta_elegida, "modo": _modo})
	var nm = _nivel_mgr()
	if nm:
		nm.completar_mision(1, _mision_id)
	if is_instance_valid(_zona_ref) and _zona_ref.has_method("_marcar_completada"):
		_zona_ref._marcar_completada()
	var xp : int = int(nm.XP_POR_MISION.get(1, 40)) if nm else 40
	var ec : int = int(nm.EC_POR_MISION.get(1, 15)) if nm else 15
	mision_completada_plantar.emit(_mision_id, xp, ec)


func _on_salir() -> void:
	_cerrar()


func _cerrar() -> void:
	if is_instance_valid(_plant_panel) and _plant_panel.visible:
		_plant_panel.visible = false
		hide()
		return
	var tw := create_tween()
	tw.tween_property(_panel_root, "modulate:a", 0.0, 0.18)
	tw.tween_callback(func(): hide(); _panel_root.modulate.a = 1.0)
