# ============================================================
# SceneMapaMundo.gd — URBE Rangers: Eco-Quest
# Controlador principal del mapa.
# Una zona → una misión única → un NPC propio.
# ============================================================
extends Node2D

const MAPA_ANCHO : float = 1408.0
const MAPA_ALTO  : float =  768.0
const SPAWN_X    : float =  590.0
const SPAWN_Y    : float =  360.0   # Patio Central — plaza abierta del campus

const NPC_ESCENA                := preload("res://scenes/mapa/npc_base.tscn")
const QUIZ_ESCENA               := preload("res://scenes/ui/quiz_npc.tscn")
const DIALOGO_ESCENA            := preload("res://scenes/ui/dialogo_npc.tscn")
const MISION_INICIO_ESCENA      := preload("res://scenes/ui/mision_inicio.gd")
const MINIJUEGO_RESIDUOS_ESCENA := preload("res://scenes/ui/minijuego_residuos.gd")
const TUTORIAL_ESCENA           := preload("res://scenes/ui/tutorial_onboarding.gd")
const TOUCH_ESCENA              := preload("res://scenes/ui/touch_controls.gd")
const CRISIS_ESCENA             := preload("res://scenes/ui/crisis_evento.gd")
const LEADERBOARD_ESCENA        := preload("res://scenes/ui/leaderboard.gd")
const SIMULADOR_ESCENA          := preload("res://scenes/ui/simulador_decision.gd")
const RESULTADOS_ESCENA         := preload("res://scenes/ui/resultados_greenmetric.gd")
const ZONA_VERDE_ESCENA         := preload("res://scenes/mapa/zona_verde.gd")
const CONTENEDOR_ESCENA         := preload("res://scenes/mapa/contenedor_basura.gd")
const EDIFICIO_ESCENA           := preload("res://scenes/edificios/escena_edificio.gd")
const ZONA_TIERRA_ESCENA        := preload("res://scenes/misiones/zona_tierra.gd")
const PUNTO_ENERGIA_ESCENA      := preload("res://scenes/misiones/punto_critico_energia.gd")
const MISION_PLANTAR_ESCENA     := preload("res://scenes/misiones/mision_plantar.gd")
const INTERIOR_BLOQUE_ESCENA    := preload("res://scenes/misiones/interior_bloque.gd")
const MISION_SOLAR_ESCENA       := preload("res://scenes/misiones/mision_solar.gd")
const ZONA_RECICLAJE_ESCENA     := preload("res://scenes/misiones/zona_reciclaje.gd")
const MISION_RECICLAR_ESCENA    := preload("res://scenes/misiones/mision_reciclar.gd")
const LLAVE_AGUA_ESCENA         := preload("res://scenes/misiones/llave_agua.gd")
const PUNTO_CAPTACION_ESCENA    := preload("res://scenes/misiones/punto_captacion.gd")
const MISION_CAPTACION_ESCENA   := preload("res://scenes/misiones/mision_captacion.gd")
const OFICINA_MOVILIDAD_ESCENA  := preload("res://scenes/misiones/oficina_movilidad.gd")
const MISION_MOVILIDAD_ESCENA   := preload("res://scenes/misiones/mision_movilidad.gd")
const PUNTO_BICICLETERO_ESCENA  := preload("res://scenes/misiones/punto_bicicletero.gd")
const MISION_BICICLETERO_ESCENA := preload("res://scenes/misiones/mision_bicicletero.gd")
const PUNTO_MALLA_VERDE_ESCENA  := preload("res://scenes/misiones/punto_malla_verde.gd")
const MISION_MALLA_VERDE_ESCENA := preload("res://scenes/misiones/mision_malla_verde.gd")
const PUNTO_COMITE_ESCENA       := preload("res://scenes/misiones/punto_comite_ambiental.gd")
const MISION_COMITE_ESCENA      := preload("res://scenes/misiones/mision_comite_ambiental.gd")
const PUNTO_SEMANA_VERDE_ESCENA := preload("res://scenes/misiones/punto_semana_verde.gd")
const MISION_SEMANA_VERDE_ESCENA:= preload("res://scenes/misiones/mision_semana_verde.gd")
const PUNTO_INFORME_ESCENA      := preload("res://scenes/misiones/punto_informe_final.gd")
const MISION_INFORME_ESCENA     := preload("res://scenes/misiones/mision_informe_final.gd")

# ── Sistema de niveles ───────────────────────────────────────
const NIVELES : Array = [
	{"nombre": "Semilla",      "xp_min": 0,     "xp_max": 500},
	{"nombre": "Brote",        "xp_min": 500,   "xp_max": 1500},
	{"nombre": "Árbol",        "xp_min": 1500,  "xp_max": 3500},
	{"nombre": "Estratega",    "xp_min": 3500,  "xp_max": 7000},
	{"nombre": "Investigador", "xp_min": 7000,  "xp_max": 12000},
	{"nombre": "EcoLíder",     "xp_min": 12000, "xp_max": 12000},
]

# ── Datos de los NPCs (uno por zona) — posiciones en nuevo mapa URBE ─
var DATOS_NPCS : Array = [
	# ── M6 Educación ────────────────────────────────────────
	{
		"nombre":    "Rector Morales",
		"mision_id": "mision_rector",
		"tipo":      "rector",
		"pos":       Vector2(778, 464),   # plaza norte del Rectorado, fuera del edificio
		"color":     Color(0.5, 0.1, 0.9),
		"dialogos":  PackedStringArray([
			"Bienvenido, Eco-Ranger. Soy el Rector de URBE.",
			"Nuestro campus participa en el ranking UI GreenMetric, que evalua sostenibilidad universitaria.",
			"Necesito que hables con los coordinadores del campus y recopiles el reporte de cada modulo.",
			"El ranking evalua 6 modulos: Entorno, Energia, Residuos, Agua, Transporte y Educacion."
		])
	},
	{
		"nombre":    "Dra. Luna",
		"mision_id": "mision_educacion",
		"tipo":      "prof_m",
		"pos":       Vector2(1100, 400),   # corredor este (BloqueE↔EstDistancia x=1080..1120)
		"color":     Color(0.35, 0.0, 0.65),
		"dialogos":  PackedStringArray([
			"Por fin llegas! Soy la Dra. Luna, coordinadora de Educacion e Investigacion.",
			"Este modulo evalua materias de sostenibilidad, publicaciones cientificas e iniciativas del campus.",
			"URBE tiene 3 asignaturas ambientales, pero necesitamos mas investigacion publicada en revistas.",
			"Responde este cuestionario final sobre el modulo de Educacion e Investigacion."
		])
	},
	# ── M2 Energía ──────────────────────────────────────────
	{
		"nombre":    "Prof. González",
		"mision_id": "mision_bloque_a",
		"tipo":      "prof_h",
		"pos":       Vector2(440, 660),   # pasillo BloqueC/B↔BloqueA
		"color":     Color(0.9, 0.45, 0.0),
		"dialogos":  PackedStringArray([
			"Hola! Soy el Prof. Gonzalez, docente del Bloque A.",
			"Este bloque concentra aulas con alto consumo de electricidad por aire acondicionado.",
			"Segun GreenMetric, debemos apagar los equipos al salir y optar por iluminacion LED.",
			"Responde este cuestionario sobre eficiencia energetica en aulas universitarias."
		])
	},
	{
		"nombre":    "Dr. Pérez",
		"mision_id": "mision_bloque_b",
		"tipo":      "prof_h",
		"pos":       Vector2(570, 660),   # corredor sur BloqueB
		"color":     Color(0.85, 0.35, 0.0),
		"dialogos":  PackedStringArray([
			"Doctor Perez, coordinador de Energia y Cambio Climatico.",
			"El Bloque B aloja laboratorios con equipos de alto consumo electrico.",
			"GreenMetric penaliza el uso de energias no renovables y las altas emisiones de CO2.",
			"Responde estas preguntas sobre energia y cambio climatico en el campus."
		])
	},
	{
		"nombre":    "Ing. Herrera",
		"mision_id": "mision_bloque_c",
		"tipo":      "prof_m",
		"pos":       Vector2(440, 500),   # pasillo BloqueD↔BloqueC
		"color":     Color(0.95, 0.55, 0.0),
		"dialogos":  PackedStringArray([
			"Buenas! Soy la Ing. Herrera, tecnica del Bloque C.",
			"El Bloque C tiene problemas de iluminacion: muchas luces incandescentes sin control de horario.",
			"Cambiar a LED y usar sensores de movimiento reduciria el consumo un 40%.",
			"Pon a prueba lo que sabes sobre gestion energetica en edificios universitarios."
		])
	},
	{
		"nombre":    "Técn. Ruiz",
		"mision_id": "mision_bloque_d",
		"tipo":      "prof_h",
		"pos":       Vector2(440, 300),   # pasillo Cafetín↔BloqueD
		"color":     Color(0.80, 0.40, 0.0),
		"dialogos":  PackedStringArray([
			"Hola! Soy el Tecn. Ruiz, responsable de instalaciones del Bloque D.",
			"Hemos instalado paneles solares en el techo del Bloque D este semestre.",
			"Segun GreenMetric, el uso de energias renovables mejora significativamente el puntaje.",
			"Demuestra tus conocimientos sobre energias renovables y sostenibilidad campus."
		])
	},
	{
		"nombre":    "Coord. Salinas",
		"mision_id": "mision_bloque_e",
		"tipo":      "prof_m",
		"pos":       Vector2(600, 170),   # patio central, norte (frente a BloqueE)
		"color":     Color(0.90, 0.50, 0.05),
		"dialogos":  PackedStringArray([
			"Soy la Coord. Salinas, encargada del Bloque E norte del campus.",
			"El Bloque E tiene laboratorios de computo con alto consumo energetico.",
			"Necesitamos medir el consumo exacto de cada equipo para el reporte GreenMetric.",
			"Responde sobre el modulo de Energia y Cambio Climatico del campus."
		])
	},
	# ── M1 Entorno e Infraestructura ────────────────────────
	{
		"nombre":    "Ing. Ramírez",
		"mision_id": "mision_bloque_f",
		"tipo":      "prof_m",
		"pos":       Vector2(1100, 250),   # corredor este, zona norte
		"color":     Color(0.2, 0.7, 0.2),
		"dialogos":  PackedStringArray([
			"Hola! Soy la Ing. Ramirez, coordinadora de Entorno e Infraestructura.",
			"El edificio de Estudios a Distancia es el mas grande del campus por el este.",
			"GreenMetric exige que al menos el 25% del campus sea area verde con politica ambiental.",
			"Responde este cuestionario sobre el modulo de Entorno e Infraestructura."
		])
	},
	{
		"nombre":    "Sr. Blanco",
		"mision_id": "mision_fotocopiado",
		"tipo":      "prof_h",
		"pos":       Vector2(90, 558),   # pasillo Estac↔Fotocopiado (y=540..580, x=0..180)
		"color":     Color(0.3, 0.65, 0.3),
		"dialogos":  PackedStringArray([
			"Buenas! Soy el Sr. Blanco, del Centro de Fotocopiado.",
			"Imprimimos miles de hojas diarias, generando residuos de papel que afectan el puntaje.",
			"GreenMetric evalua las politicas de reduccion de papel y consumo responsable de recursos.",
			"Responde sobre el manejo del papel y recursos en el campus universitario."
		])
	},
	# ── M4 Agua ─────────────────────────────────────────────
	{
		"nombre":    "Lic. Torres",
		"mision_id": "mision_agua",
		"tipo":      "prof_m",
		"pos":       Vector2(560, 430),   # patio central sur (fuente, zona de agua)
		"color":     Color(0.0, 0.55, 0.75),
		"dialogos":  PackedStringArray([
			"Buenas, soy la Lic. Torres, responsable del modulo de Agua.",
			"GreenMetric evalua si el campus tiene programas de conservacion hidrica y medidores de consumo.",
			"El Patio Central tiene fuentes ornamentales pero carece de sistemas de riego eficiente.",
			"Responde este cuestionario sobre gestion del agua en el campus universitario."
		])
	},
	# ── M5 Transporte ───────────────────────────────────────
	{
		"nombre":    "Carlos",
		"mision_id": "mision_transporte",
		"tipo":      "est_h",
		"pos":       Vector2(250, 330),   # corredor oeste, junto al Estacionamiento
		"color":     Color(0.1, 0.3, 0.8),
		"dialogos":  PackedStringArray([
			"Hola! Soy Carlos, coordinador de Transporte Sostenible.",
			"GreenMetric mide cuantos estudiantes usan transporte publico, bicicleta o caminan al campus.",
			"Actualmente el 78% llega en vehiculo privado. Tenemos el Estacionamiento M5 siempre lleno.",
			"Responde sobre movilidad sostenible y el modulo de Transporte del campus."
		])
	},
	# ── M3 Residuos ─────────────────────────────────────────
	{
		"nombre":    "Yulimar",
		"mision_id": "mision_residuos",
		"tipo":      "est_m",
		"pos":       Vector2(340, 100),   # camino norte, frente al Cafetín
		"color":     Color(0.85, 0.75, 0.0),
		"dialogos":  PackedStringArray([
			"Eco-Ranger! Soy Yulimar, del comite estudiantil de reciclaje.",
			"El campus genera residuos diariamente, pero solo el 30% se clasifica correctamente.",
			"GreenMetric penaliza la falta de contenedores diferenciados y programas de compostaje.",
			"Ahora pon a prueba tus conocimientos clasificando los residuos del campus."
		])
	},
]

# ── Zona → misión (lookup directo por zona_key, sin ambigüedad) ─
# Mapa actualizado: layout real URBE (foto aérea)
var ZONA_A_MISION : Dictionary = {
	"ZonaRectorado":       {"mision_id": "mision_rector",      "modulo_id": 6, "npc": "Rector Morales", "progreso": 0.55, "nombre": "Rectorado"},
	"ZonaAreaServicios":   {"mision_id": "mision_educacion",   "modulo_id": 6, "npc": "Dra. Luna",      "progreso": 0.55, "nombre": "SERVIEDUCA"},
	"ZonaBloqueA":         {"mision_id": "mision_bloque_a",    "modulo_id": 2, "npc": "Prof. González", "progreso": 0.38, "nombre": "Bloque A"},
	"ZonaBloqueB":         {"mision_id": "mision_bloque_b",    "modulo_id": 2, "npc": "Dr. Pérez",      "progreso": 0.42, "nombre": "Bloque B"},
	"ZonaBloqueC":         {"mision_id": "mision_bloque_c",    "modulo_id": 2, "npc": "Ing. Herrera",   "progreso": 0.35, "nombre": "Bloque C"},
	"ZonaBloqueD":         {"mision_id": "mision_bloque_d",    "modulo_id": 2, "npc": "Técn. Ruiz",     "progreso": 0.45, "nombre": "Bloque D"},
	"ZonaBloqueE":         {"mision_id": "mision_bloque_e",    "modulo_id": 2, "npc": "Coord. Salinas", "progreso": 0.40, "nombre": "Bloque E"},
	"ZonaBloqueF":         {"mision_id": "mision_bloque_f",    "modulo_id": 1, "npc": "Ing. Ramírez",   "progreso": 0.35, "nombre": "Est. a Distancia"},
	"ZonaFotocopiado":     {"mision_id": "mision_fotocopiado", "modulo_id": 1, "npc": "Sr. Blanco",     "progreso": 0.25, "nombre": "Fotocopiado"},
	"ZonaPatio":           {"mision_id": "mision_agua",        "modulo_id": 4, "npc": "Lic. Torres",    "progreso": 0.45, "nombre": "Patio Central"},
	"ZonaEstacionamiento": {"mision_id": "mision_transporte",  "modulo_id": 5, "npc": "Carlos",         "progreso": 0.22, "nombre": "Estacionamiento"},
	"ZonaCafetin":         {"mision_id": "mision_residuos",    "modulo_id": 3, "npc": "Yulimar",        "progreso": 0.30, "nombre": "Cafetín"},
}

# ── Quiz por misión ──────────────────────────────────────────
const QUIZ_POR_MISION : Dictionary = {
	# M6 - Educación
	"mision_rector": [
		{"pregunta": "¿Cuántos módulos evalúa el ranking UI GreenMetric?",
		 "opciones": ["3 módulos", "6 módulos", "10 módulos"], "correcta": 1},
		{"pregunta": "¿Qué evalúa principalmente el ranking UI GreenMetric?",
		 "opciones": ["La calidad académica", "Los deportes universitarios", "La sostenibilidad universitaria"], "correcta": 2},
		{"pregunta": "¿Qué institución participa en GreenMetric en este juego?",
		 "opciones": ["UCV", "URBE", "UCAB"], "correcta": 1}
	],
	"mision_educacion": [
		{"pregunta": "¿Qué evalúa GreenMetric en el módulo de Educación?",
		 "opciones": ["Deportes universitarios", "Idiomas impartidos", "Asignaturas de sostenibilidad e investigación"], "correcta": 2},
		{"pregunta": "¿Cuántas asignaturas ambientales tiene URBE actualmente?",
		 "opciones": ["3 asignaturas", "10 asignaturas", "0 asignaturas"], "correcta": 0},
		{"pregunta": "¿Qué necesita URBE para mejorar en el módulo de Educación?",
		 "opciones": ["Más estacionamientos", "Nuevas canchas deportivas", "Más investigación publicada en revistas"], "correcta": 2}
	],
	# M2 - Energía (preguntas únicas por bloque)
	"mision_bloque_a": [
		{"pregunta": "¿Qué equipo en las aulas consume más electricidad en el campus?",
		 "opciones": ["Computadoras", "Aire acondicionado", "Iluminación LED"], "correcta": 1},
		{"pregunta": "¿Qué hábito reduce el consumo eléctrico en aulas universitarias?",
		 "opciones": ["Dejar equipos en espera", "Apagar luces y equipos al salir", "Aumentar la ventilación"], "correcta": 1},
		{"pregunta": "¿Qué tipo de iluminación recomienda GreenMetric para edificios?",
		 "opciones": ["Incandescente", "Fluorescente", "LED de bajo consumo"], "correcta": 2}
	],
	"mision_bloque_b": [
		{"pregunta": "¿Por qué los laboratorios consumen más energía que las aulas normales?",
		 "opciones": ["Tienen más ventanas", "Usan equipos especializados de alto consumo", "Tienen más estudiantes"], "correcta": 1},
		{"pregunta": "¿Qué gas de efecto invernadero se reduce al usar energías renovables?",
		 "opciones": ["Oxígeno", "CO₂", "Nitrógeno"], "correcta": 1},
		{"pregunta": "¿Qué tipo de energía favorece GreenMetric para campus universitarios?",
		 "opciones": ["Combustibles fósiles", "Energías renovables como solar y eólica", "Energía nuclear"], "correcta": 1}
	],
	"mision_bloque_c": [
		{"pregunta": "¿Cuántos bloques de aulas principales tiene el campus URBE?",
		 "opciones": ["3 bloques", "5 bloques (A, B, C, D y E)", "7 bloques"], "correcta": 1},
		{"pregunta": "¿Qué impacto tiene el aire acondicionado sin mantenimiento?",
		 "opciones": ["Ahorra energía", "Aumenta el consumo hasta un 30% más", "No tiene impacto"], "correcta": 1},
		{"pregunta": "¿Qué sensor reduce el consumo de iluminación en pasillos vacíos?",
		 "opciones": ["Sensor de movimiento", "Sensor de temperatura", "Sensor de humedad"], "correcta": 0}
	],
	"mision_bloque_d": [
		{"pregunta": "¿Qué tecnología permite al Bloque D generar energía limpia?",
		 "opciones": ["Turbinas de viento", "Paneles solares fotovoltaicos", "Generadores diésel"], "correcta": 1},
		{"pregunta": "¿Qué evalúa GreenMetric en el módulo de Energía y Cambio Climático?",
		 "opciones": ["Consumo eléctrico, renovables y emisiones de CO₂", "Número de estudiantes", "Velocidad del internet"], "correcta": 0},
		{"pregunta": "¿Cuánto puede reducir el consumo un edificio con energía solar?",
		 "opciones": ["Nada", "Hasta un 40% del consumo total", "Exactamente un 100%"], "correcta": 1}
	],
	"mision_bloque_e": [
		{"pregunta": "¿Qué tipo de equipos tiene el Bloque E que aumentan el consumo?",
		 "opciones": ["Equipos de jardinería", "Laboratorios de cómputo", "Gimnasio universitario"], "correcta": 1},
		{"pregunta": "¿Qué herramienta mide el consumo exacto de energía por equipo?",
		 "opciones": ["Termómetro", "Vatímetro (medidor de vatios)", "Barómetro"], "correcta": 1},
		{"pregunta": "¿Qué evalúa GreenMetric sobre el Cambio Climático en universidades?",
		 "opciones": ["Las emisiones de CO₂ del campus", "La temperatura del salón", "La lluvia anual"], "correcta": 0}
	],
	# M1 - Entorno e Infraestructura
	"mision_bloque_f": [
		{"pregunta": "¿Qué evalúa GreenMetric en Entorno e Infraestructura?",
		 "opciones": ["Espacios verdes y políticas ambientales", "Número de laboratorios", "Tamaño de las aulas"], "correcta": 0},
		{"pregunta": "¿Cuál es el edificio principal al este del campus URBE?",
		 "opciones": ["Biblioteca", "Bloque F", "Estacionamiento M5"], "correcta": 1},
		{"pregunta": "¿Qué mejora la puntuación en infraestructura según GreenMetric?",
		 "opciones": ["Más cafeterías", "Certificaciones ambientales", "Más plazas de parqueo"], "correcta": 1}
	],
	"mision_bloque_g": [
		{"pregunta": "¿Qué beneficio ambiental aportan los jardines internos de un edificio?",
		 "opciones": ["Aumentan la temperatura", "Reducen CO₂ y mejoran la biodiversidad", "Solo decoración"], "correcta": 1},
		{"pregunta": "¿Cuánta área verde mínima requiere GreenMetric en un campus sostenible?",
		 "opciones": ["Al menos el 5%", "Al menos el 25%", "Al menos el 60%"], "correcta": 1},
		{"pregunta": "¿Qué certifica una política ambiental institucional?",
		 "opciones": ["El número de edificios", "El compromiso formal con la sostenibilidad", "El tamaño del campus"], "correcta": 1}
	],
	"mision_fotocopiado": [
		{"pregunta": "¿Cuántos árboles se necesitan para producir 1 tonelada de papel?",
		 "opciones": ["2 árboles", "17 árboles", "50 árboles"], "correcta": 1},
		{"pregunta": "¿Qué práctica reduce el impacto ambiental del papel en la universidad?",
		 "opciones": ["Imprimir más en papel reciclado", "Usar documentos digitales y reducir impresiones", "Usar papel de mayor gramaje"], "correcta": 1},
		{"pregunta": "¿Qué evalúa GreenMetric sobre el consumo de papel en el campus?",
		 "opciones": ["Solo la cantidad de impresoras", "Las políticas de reducción y uso eficiente de recursos", "El precio del papel"], "correcta": 1}
	],
	# M4 - Agua
	"mision_agua": [
		{"pregunta": "¿Qué evalúa GreenMetric en el módulo de Agua?",
		 "opciones": ["Tamaño de la piscina", "Programas de conservación hídrica y medidores", "Número de bebederos"], "correcta": 1},
		{"pregunta": "¿Qué instrumento mide el consumo de agua en un edificio?",
		 "opciones": ["Termómetro", "Barómetro", "Hidrómetro"], "correcta": 2},
		{"pregunta": "¿Cuál es el problema del agua en la Biblioteca?",
		 "opciones": ["No tiene agua potable", "Tiene la piscina cerrada", "Consume mucha agua sin hidrómetros"], "correcta": 2}
	],
	# M5 - Transporte
	"mision_transporte": [
		{"pregunta": "¿Qué porcentaje de estudiantes llega al campus en vehículo privado?",
		 "opciones": ["50%", "78%", "30%"], "correcta": 1},
		{"pregunta": "¿Qué tipo de transporte favorece GreenMetric?",
		 "opciones": ["Solo automóviles privados", "Motocicletas particulares", "Transporte público y bicicleta"], "correcta": 2},
		{"pregunta": "¿Qué propone Carlos para mejorar la movilidad sostenible?",
		 "opciones": ["Ampliar el estacionamiento M5", "Crear ciclovías en el campus", "Prohibir el transporte público"], "correcta": 1}
	],
	# M3 - Residuos → usa minijuego, pero quiz se define por si acaso
	"mision_residuos": [
		{"pregunta": "¿Cuál de estos es un residuo reciclable?",
		 "opciones": ["Cáscara de banana", "Botella de plástico PET", "Papel mojado con aceite"], "correcta": 1},
		{"pregunta": "¿Qué color de contenedor corresponde a residuos orgánicos?",
		 "opciones": ["Azul", "Rojo", "Marrón/Verde"], "correcta": 2},
		{"pregunta": "¿Qué porcentaje de residuos se clasifica correctamente en el campus?",
		 "opciones": ["30%", "75%", "90%"], "correcta": 0}
	],
}

# ── Referencias a nodos ──────────────────────────────────────
@onready var jugador      : CharacterBody2D = $Jugador
@onready var camara       : Camera2D        = $Jugador/Camera2D
@onready var zonas_campus : Node2D          = $ZonasCampus
@onready var mapa_campus  : Node2D          = $FondoCampus

# ── Estado ───────────────────────────────────────────────────
var _xp_total           : int         = 0
var _nivel_actual       : int         = 0
var _modulo_activo      : int         = -1
var _nombre_activo      : String      = ""
var _zona_activa        : String      = ""
var _mision_activa      : String      = ""
var _quiz_ui            : CanvasLayer = null
var _mision_ui          : CanvasLayer = null
var _dialogo_ui         : CanvasLayer = null
var _minijuego_residuos : CanvasLayer = null

# ── HUD principal ────────────────────────────────────────────
var _hud_canvas      : CanvasLayer = null
var _hud_nombre_lbl  : Label       = null
var _hud_nivel_lbl   : Label       = null
var _hud_barra_bg    : ColorRect   = null
var _hud_barra_fill  : ColorRect   = null
var _hud_xp_lbl      : Label       = null
var _zona_panel      : Panel       = null
var _zona_icono_lbl  : Label       = null
var _zona_nombre_lbl : Label       = null
var _zona_hint_lbl   : Label       = null
var _celebracion_lbl : Label       = null
var _hud_verde_fill  : ColorRect   = null
var _hud_verde_lbl   : Label       = null
var _hud_agua_fill   : ColorRect   = null
var _hud_agua_lbl    : Label       = null
var _hud_edu_fill    : ColorRect   = null
var _hud_edu_lbl     : Label       = null

# ── Sidebar de módulos ────────────────────────────────────────
var _sidebar_fills  : Array = []   # Array[ColorRect]
var _sidebar_pcts   : Array = []   # Array[Label]

# ── Notificación de zona ──────────────────────────────────────
var _notif_zona_lbl : Label = null

# ── Panel de misión completada ────────────────────────────────
var _complete_panel  : Panel  = null
var _complete_titulo : Label  = null
var _complete_xp     : Label  = null
var _complete_barra  : ColorRect = null

# ── Contador de XP flotante ───────────────────────────────────
var _xp_float_offset : int = 0

# ── Sistemas EVA ─────────────────────────────────────────────
var _tutorial_ui      : CanvasLayer = null
var _crisis_ui        : CanvasLayer = null
var _leaderboard_ui   : CanvasLayer = null
var _sim_decision_ui  : CanvasLayer = null
var _resultados_ui    : CanvasLayer = null
var _edificio_ui      : CanvasLayer = null
# ── UIs de misiones por nivel ─────────────────────────────────
var _plantar_ui       : CanvasLayer = null
var _interior_ui      : CanvasLayer = null
var _solar_ui         : CanvasLayer = null
var _reciclar_ui      : CanvasLayer = null
var _captacion_ui     : CanvasLayer = null
var _movilidad_ui     : CanvasLayer = null
var _bicicletero_ui   : CanvasLayer = null
var _malla_verde_ui   : CanvasLayer = null
var _comite_ui        : CanvasLayer = null
var _semana_verde_ui  : CanvasLayer = null
var _informe_ui       : CanvasLayer = null
var _zonas_verdes        : Array       = []   # Array[Node2D]
var _panel_zona_mejora   : Panel       = null
var _pzm_titulo_lbl      : Label       = null
var _pzm_nivel_lbl       : Label       = null
var _pzm_xp_lbl          : Label       = null
var _pzm_costo_lbl       : Label       = null
var _pzm_btn_mejorar     : Button      = null
var _zona_en_panel       : Node2D      = null

# ── Contenedores de basura ────────────────────────────────────
var _contenedores        : Array    = []
var _panel_contenedor    : Panel    = null
var _pc_titulo_lbl       : Label    = null
var _pc_barra_bg         : ColorRect = null
var _pc_barra_fill       : ColorRect = null
var _pc_estado_lbl       : Label    = null
var _pc_btn_servicio     : Button   = null
var _contenedor_en_panel : Node2D   = null
var _timer_crisis         : float   = 0.0
var _crises_desbloqueadas : bool    = false
var _menu_pausa_canvas    : CanvasLayer = null
const _CRISIS_MIN         : float   = 90.0
const _CRISIS_MAX         : float   = 180.0
var _hud_creditos_lbl : Label       = null
var _hud_energia_lbl  : Label       = null
var _insignia_lbl     : Label       = null

# ── Progreso de módulos (copia local para sidebar) ────────────
# Arranca en 0 para todos — antes tenía valores inventados (0.35, 0.40...)
# que hacían que un jugador nuevo, sin hacer nada, ya mostrara 22-55% de
# progreso, y que la barra RETROCEDIERA al completar la primera misión
# real de un nivel (porque el handler de esa misión sobreescribe este
# valor con NivelManager.pct_nivel(), que sí arranca en 0). También
# desincronizaba esta barra/el reporte de resultados de los indicadores
# HUD (💧🌿📚) y del informe final de Nivel 6, que ya usaban pct_nivel()
# directo. Ahora las tres fuentes arrancan iguales y solo suben con
# logros verificables.
var _progreso_modulos : Dictionary = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0, 6: 0.0}

const SIDEBAR_MODULOS : Array = [
	{"id": 1, "icono": "🌿", "nombre": "Entorno",    "color": Color(0.18, 0.55, 0.20)},
	{"id": 2, "icono": "⚡", "nombre": "Energía",    "color": Color(0.90, 0.50, 0.00)},
	{"id": 3, "icono": "♻", "nombre": "Residuos",   "color": Color(0.80, 0.65, 0.00)},
	{"id": 4, "icono": "💧", "nombre": "Agua",       "color": Color(0.00, 0.45, 0.75)},
	{"id": 5, "icono": "🚲", "nombre": "Transporte", "color": Color(0.10, 0.30, 0.80)},
	{"id": 6, "icono": "📚", "nombre": "Educación",  "color": Color(0.40, 0.00, 0.70)},
]


func _ready() -> void:
	jugador.global_position = Vector2(SPAWN_X, SPAWN_Y)
	jugador.z_index = 2

	camara.limit_left   = 0
	camara.limit_top    = 0
	camara.limit_right  = int(MAPA_ANCHO)
	camara.limit_bottom = int(MAPA_ALTO)
	camara.zoom         = Vector2(1.5, 1.5)

	# _progreso_modulos (sidebar) y los índices del HUD (💧🌿📚) solo se
	# actualizaban de forma reactiva, al completar una misión EN ESA
	# sesión — nunca se sembraban desde NivelManager al entrar. Un jugador
	# que vuelve a loguearse sin completar nada nuevo en esa sesión veía
	# 0% en todos lados aunque NivelManager (ya repoblado desde el
	# servidor en SceneLogin, ver iniciar_sesion()/repoblar_desde_servidor)
	# tuviera el progreso real. Hay que sembrar ANTES de _construir_sidebar(),
	# que pinta con lo que haya en _progreso_modulos en ese momento.
	var nm_inicial = _nivel_mgr()
	if nm_inicial:
		for mod_id in _progreso_modulos.keys():
			_progreso_modulos[mod_id] = nm_inicial.pct_nivel(mod_id)

	_construir_hud()
	_construir_sidebar()
	_construir_notificacion_zona()
	_construir_panel_completado()
	_construir_panel_zona_mejora()
	_construir_panel_contenedor()
	_actualizar_hud()
	# Mismo motivo que el sembrado de _progreso_modulos de arriba: estos
	# tres solo se actualizaban al completar una misión en vivo.
	_actualizar_indicador_verde()
	_actualizar_indicador_agua()
	_actualizar_indicador_edu()

	# Escena de interior de edificio (overlay sobre el campus)
	_edificio_ui = EDIFICIO_ESCENA.new()
	add_child(_edificio_ui)
	_edificio_ui.hablar_npc_solicitado.connect(_on_hablar_npc_edificio)
	_edificio_ui.salida_solicitada.connect(_on_salida_edificio)

	# Conectar señal de interacción del jugador para efecto de cámara
	jugador.interaccion_iniciada.connect(_on_interaccion_iniciada)

	if $ZonasCampus:
		zonas_campus.zona_activada.connect(_on_zona_activada)
		zonas_campus.zona_salida.connect(_on_zona_salida)

	_spawn_npcs()

	_mision_ui = MISION_INICIO_ESCENA.new()
	add_child(_mision_ui)
	_mision_ui.mision_aceptada.connect(_on_mision_aceptada)
	_mision_ui.mision_cancelada.connect(_on_mision_cancelada)

	# Reusar el nodo DialogoNPC que ya está en la escena para que tanto el
	# flujo de zona (→ edificio → "Hablar") como el flujo directo de NPC
	# compartan la misma instancia y la señal dialogo_terminado esté conectada.
	_dialogo_ui = $DialogoNPC
	_dialogo_ui.dialogo_terminado.connect(_on_dialogo_terminado)

	_quiz_ui = QUIZ_ESCENA.instantiate()
	add_child(_quiz_ui)
	_quiz_ui.quiz_completado.connect(_on_quiz_completado)

	_minijuego_residuos = MINIJUEGO_RESIDUOS_ESCENA.new()
	add_child(_minijuego_residuos)
	_minijuego_residuos.minijuego_completado.connect(_on_minijuego_completado)

	if has_node("CanvasLayer"):
		$CanvasLayer.visible = false

	SupabaseManager.modulos_cargados.connect(_on_modulos_cargados)
	SupabaseManager.progreso_cargado.connect(_on_progreso_cargado)
	SupabaseManager.progreso_guardado.connect(_on_progreso_guardado)
	SupabaseManager.progreso_guardado_fallido.connect(_on_progreso_guardado_fallido)
	SupabaseManager.cargar_modulos()
	# cargar_progreso se llama desde _on_modulos_cargados para no saturar el HTTPRequest

	_init_sistemas_eva()
	_construir_menu_pausa()


# ── HUD ──────────────────────────────────────────────────────
func _construir_hud() -> void:
	_hud_canvas = CanvasLayer.new()
	_hud_canvas.layer = 5
	add_child(_hud_canvas)

	var panel_top := Panel.new()
	panel_top.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel_top.offset_right  = 310.0
	panel_top.offset_bottom = 96.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.07, 0.10, 0.92)
	ps.border_color = Color(0.20, 0.68, 0.20)
	ps.set_border_width_all(2)
	ps.corner_radius_bottom_left  = 10
	ps.corner_radius_bottom_right = 10
	panel_top.add_theme_stylebox_override("panel", ps)
	_hud_canvas.add_child(panel_top)

	_hud_nombre_lbl = Label.new()
	_hud_nombre_lbl.position = Vector2(10, 6)
	_hud_nombre_lbl.add_theme_font_size_override("font_size", 13)
	_hud_nombre_lbl.add_theme_color_override("font_color", Color(0.25, 0.90, 0.25))
	_hud_canvas.add_child(_hud_nombre_lbl)

	_hud_nivel_lbl = Label.new()
	_hud_nivel_lbl.position = Vector2(130, 6)
	_hud_nivel_lbl.add_theme_font_size_override("font_size", 11)
	_hud_nivel_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.20))
	_hud_canvas.add_child(_hud_nivel_lbl)

	_hud_barra_bg = ColorRect.new()
	_hud_barra_bg.position = Vector2(10, 32)
	_hud_barra_bg.size     = Vector2(240, 12)
	_hud_barra_bg.color    = Color(0.10, 0.14, 0.20)
	_hud_canvas.add_child(_hud_barra_bg)

	_hud_barra_fill = ColorRect.new()
	_hud_barra_fill.position = Vector2(10, 32)
	_hud_barra_fill.size     = Vector2(0, 12)
	_hud_barra_fill.color    = Color(0.18, 0.78, 0.28)
	_hud_canvas.add_child(_hud_barra_fill)

	_hud_xp_lbl = Label.new()
	_hud_xp_lbl.position = Vector2(256, 30)
	_hud_xp_lbl.add_theme_font_size_override("font_size", 10)
	_hud_xp_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70))
	_hud_canvas.add_child(_hud_xp_lbl)

	# Panel de zona (centro inferior)
	_zona_panel = Panel.new()
	_zona_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_zona_panel.offset_top    = -72.0
	_zona_panel.offset_bottom =   0.0
	_zona_panel.offset_left   = 200.0
	_zona_panel.offset_right  = -200.0
	var zps := StyleBoxFlat.new()
	zps.bg_color     = Color(0.04, 0.07, 0.10, 0.90)
	zps.border_color = Color(0.20, 0.68, 0.20)
	zps.set_border_width_all(2)
	zps.corner_radius_top_left  = 10
	zps.corner_radius_top_right = 10
	_zona_panel.add_theme_stylebox_override("panel", zps)
	_zona_panel.visible = false
	_hud_canvas.add_child(_zona_panel)

	_zona_icono_lbl = Label.new()
	_zona_icono_lbl.position = Vector2(14, 8)
	_zona_icono_lbl.add_theme_font_size_override("font_size", 22)
	_zona_panel.add_child(_zona_icono_lbl)

	_zona_nombre_lbl = Label.new()
	_zona_nombre_lbl.position = Vector2(48, 8)
	_zona_nombre_lbl.add_theme_font_size_override("font_size", 13)
	_zona_nombre_lbl.add_theme_color_override("font_color", Color(0.25, 0.90, 0.25))
	_zona_panel.add_child(_zona_nombre_lbl)

	_zona_hint_lbl = Label.new()
	_zona_hint_lbl.position = Vector2(48, 36)
	_zona_hint_lbl.add_theme_font_size_override("font_size", 11)
	_zona_hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.90, 0.55))
	_zona_hint_lbl.text = "🌿 N1 Plantar  ·  ⚡ N2 Energía"
	_zona_panel.add_child(_zona_hint_lbl)

	_celebracion_lbl = Label.new()
	_celebracion_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_celebracion_lbl.offset_left   = -220
	_celebracion_lbl.offset_top    =  70
	_celebracion_lbl.offset_right  =  220
	_celebracion_lbl.offset_bottom =  130
	_celebracion_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_celebracion_lbl.add_theme_font_size_override("font_size", 24)
	_celebracion_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.10))
	_celebracion_lbl.visible = false
	_hud_canvas.add_child(_celebracion_lbl)

	# ── Índice Verde (barra de progreso nivel 1) ─────────────
	var verde_bg := ColorRect.new()
	verde_bg.position = Vector2(10, 80)
	verde_bg.size     = Vector2(236, 12)
	verde_bg.color    = Color(0.06, 0.14, 0.08)
	_hud_canvas.add_child(verde_bg)

	_hud_verde_fill = ColorRect.new()
	_hud_verde_fill.position = Vector2(10, 80)
	_hud_verde_fill.size     = Vector2(0, 12)
	_hud_verde_fill.color    = Color(0.22, 0.82, 0.28)
	_hud_canvas.add_child(_hud_verde_fill)

	_hud_verde_lbl = Label.new()
	_hud_verde_lbl.position = Vector2(10, 92)
	_hud_verde_lbl.add_theme_font_size_override("font_size", 9)
	_hud_verde_lbl.add_theme_color_override("font_color", Color(0.55, 0.95, 0.55))
	_hud_verde_lbl.text = "🌿 Índice Verde: 0%"
	_hud_canvas.add_child(_hud_verde_lbl)

	# ── Índice Agua (barra de progreso nivel 4) ──────────────
	var agua_bg := ColorRect.new()
	agua_bg.position = Vector2(10, 108)
	agua_bg.size     = Vector2(236, 12)
	agua_bg.color    = Color(0.05, 0.10, 0.14)
	_hud_canvas.add_child(agua_bg)

	_hud_agua_fill = ColorRect.new()
	_hud_agua_fill.position = Vector2(10, 108)
	_hud_agua_fill.size     = Vector2(0, 12)
	_hud_agua_fill.color    = Color(0.18, 0.62, 0.90)
	_hud_canvas.add_child(_hud_agua_fill)

	_hud_agua_lbl = Label.new()
	_hud_agua_lbl.position = Vector2(10, 120)
	_hud_agua_lbl.add_theme_font_size_override("font_size", 9)
	_hud_agua_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 0.98))
	_hud_agua_lbl.text = "💧 Índice Agua: 0%"
	_hud_canvas.add_child(_hud_agua_lbl)

	# ── Índice Educación (barra de progreso nivel 6) ─────────
	var edu_bg := ColorRect.new()
	edu_bg.position = Vector2(10, 136)
	edu_bg.size     = Vector2(236, 12)
	edu_bg.color    = Color(0.09, 0.05, 0.14)
	_hud_canvas.add_child(edu_bg)

	_hud_edu_fill = ColorRect.new()
	_hud_edu_fill.position = Vector2(10, 136)
	_hud_edu_fill.size     = Vector2(0, 12)
	_hud_edu_fill.color    = Color(0.62, 0.24, 0.90)
	_hud_canvas.add_child(_hud_edu_fill)

	_hud_edu_lbl = Label.new()
	_hud_edu_lbl.position = Vector2(10, 148)
	_hud_edu_lbl.add_theme_font_size_override("font_size", 9)
	_hud_edu_lbl.add_theme_color_override("font_color", Color(0.82, 0.65, 0.98))
	_hud_edu_lbl.text = "📚 Índice Educación: 0%"
	_hud_canvas.add_child(_hud_edu_lbl)


func _spawn_npcs() -> void:
	for datos in DATOS_NPCS:
		var npc : Area2D = NPC_ESCENA.instantiate()
		npc.nombre_npc = datos["nombre"]
		npc.mision_id  = datos["mision_id"]
		npc.dialogos   = datos["dialogos"]
		npc.color      = datos["color"]
		npc.tipo_npc   = datos.get("tipo", "prof_h")
		npc.position   = datos["pos"]
		npc.z_index    = 1
		var vis_node = npc.get_node_or_null("Visual")
		if vis_node:
			vis_node.modulate = datos["color"]
		add_child(npc)
	print("✅ %d NPCs instanciados" % DATOS_NPCS.size())


# ── Supabase ─────────────────────────────────────────────────
func _on_modulos_cargados(lista: Array) -> void:
	print("📦 Módulos cargados: %d" % lista.size())
	# Ahora que el HTTPRequest está libre, pedimos el progreso
	SupabaseManager.cargar_progreso()

func _on_progreso_cargado(lista: Array) -> void:
	for entrada in lista:
		_xp_total += entrada.get("xp_ganada", 0)
	_actualizar_hud()


# ── Zonas ────────────────────────────────────────────────────
const ZONA_ICONOS : Dictionary = {1: "🌿", 2: "⚡", 3: "♻", 4: "💧", 5: "🚲", 6: "📚"}

func _on_zona_activada(zona_key: String, modulo_id: int, nombre_modulo: String, _color: Color) -> void:
	_zona_activa   = zona_key
	_modulo_activo = modulo_id
	_nombre_activo = nombre_modulo
	_zona_icono_lbl.text  = ZONA_ICONOS.get(modulo_id, "🌍")
	_zona_nombre_lbl.text = nombre_modulo
	_zona_panel.visible   = true
	# Notificación de zona en pantalla
	var icono_txt : String = ZONA_ICONOS.get(modulo_id, "🌍")
	var col : Color = _color
	for info : Dictionary in SIDEBAR_MODULOS:
		if int(info["id"]) == modulo_id:
			col = info["color"]
			break
	_mostrar_notificacion_zona(icono_txt, nombre_modulo, col)
	# Pista contextual: primera zona visitada
	var hb = get_tree().get_first_node_in_group("hint_bubble")
	if hb:
		hb.push("primer_zona",
			"📍 Presiona [E] para aceptar la misión de esta zona del campus.")

func _on_zona_salida() -> void:
	_zona_panel.visible = false
	_zona_activa        = ""
	_modulo_activo      = -1
	_nombre_activo      = ""


# ── Menú de pausa (ESC) ──────────────────────────────────────
func _construir_menu_pausa() -> void:
	_menu_pausa_canvas = CanvasLayer.new()
	_menu_pausa_canvas.layer = 30
	_menu_pausa_canvas.visible = false
	add_child(_menu_pausa_canvas)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu_pausa_canvas.add_child(bg)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(360, 290)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -180.0
	panel.offset_top    = -145.0
	panel.offset_right  =  180.0
	panel.offset_bottom =  145.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.05, 0.08, 0.13, 0.97)
	ps.border_color = Color(0.22, 0.68, 0.90)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(14)
	ps.shadow_color = Color(0.10, 0.40, 0.70, 0.50)
	ps.shadow_size  = 16
	panel.add_theme_stylebox_override("panel", ps)
	_menu_pausa_canvas.add_child(panel)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left   =  20.0
	vb.offset_top    =  16.0
	vb.offset_right  = -20.0
	vb.offset_bottom = -16.0
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	var tit := Label.new()
	tit.text = "⏸  Menú de Pausa"
	tit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit.add_theme_font_size_override("font_size", 20)
	tit.add_theme_color_override("font_color", Color(0.80, 0.95, 1.00))
	vb.add_child(tit)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(0.22, 0.68, 0.90, 0.5))
	vb.add_child(sep)

	var btn_login := Button.new()
	btn_login.text = "🚪  Salir al Login"
	btn_login.add_theme_font_size_override("font_size", 16)
	btn_login.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/login/scene_login.tscn"))
	vb.add_child(btn_login)

	var btn_reset := Button.new()
	btn_reset.text = "🔄  Reiniciar Misiones"
	btn_reset.add_theme_font_size_override("font_size", 16)
	btn_reset.pressed.connect(func():
		var nm = _nivel_mgr()
		if nm:
			nm.reset_progreso()
		get_tree().reload_current_scene())
	vb.add_child(btn_reset)

	var btn_cont := Button.new()
	btn_cont.text = "▶  Continuar"
	btn_cont.add_theme_font_size_override("font_size", 16)
	btn_cont.pressed.connect(_toggle_menu_pausa)
	vb.add_child(btn_cont)


func _toggle_menu_pausa() -> void:
	if not is_instance_valid(_menu_pausa_canvas): return
	_menu_pausa_canvas.visible = not _menu_pausa_canvas.visible


# ── Input ────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	# ── ESC: abrir / cerrar menú de pausa ────────────────────────
	if event.keycode == KEY_ESCAPE:
		_toggle_menu_pausa()
		get_viewport().set_input_as_handled()
		return

	if event.keycode != KEY_E:
		return

	# Si el menú de pausa está abierto no procesar E
	if is_instance_valid(_menu_pausa_canvas) and _menu_pausa_canvas.visible:
		return

	# Si alguna UI de misión/diálogo/quiz ya está activa, no interferir
	if (_dialogo_ui and _dialogo_ui.visible) or (_quiz_ui and _quiz_ui.visible):
		return
	if _mision_ui and _mision_ui.visible:
		return
	if _minijuego_residuos and _minijuego_residuos.visible:
		return

	# Si hay un interior de bloque activo, no capturar el E (lo maneja interior_bloque)
	var interior_bloque_ui := get_tree().get_first_node_in_group("interior_bloque")
	if interior_bloque_ui and interior_bloque_ui.visible:
		return

	# Si hay una misión de reciclaje activa, no capturar el E
	var reciclar_ui_node := get_tree().get_first_node_in_group("mision_reciclaje")
	if reciclar_ui_node and reciclar_ui_node.visible:
		return

	# E cierra la escena de edificio (funciona como "Salir")
	if _edificio_ui and _edificio_ui.visible:
		_on_salida_edificio()
		get_viewport().set_input_as_handled()
		return
	if _panel_contenedor and _panel_contenedor.visible:
		_cerrar_panel_contenedor()
		get_viewport().set_input_as_handled()
		return
	# ── Misiones de todos los niveles: elige la MÁS CERCANA, no la
	# de mayor prioridad de grupo. Antes, si dos misiones de distinto
	# nivel quedaban cerca una de otra, siempre ganaba la del grupo
	# revisado primero (Nivel 1 > 2 > 3 > 4 > 5) sin importar cuál
	# tenías más cerca — eso dejaba misiones inalcanzables cuando
	# coincidían en el mapa. Ahora se compara distancia real. ─────
	const GRUPOS_MISION : Array[String] = [
		"zona_tierra", "punto_energia", "zona_reciclaje",
		"llave_agua", "punto_captacion", "oficina_movilidad", "punto_bicicletero",
		"punto_malla_verde", "punto_comite_ambiental", "punto_semana_verde",
		"punto_informe_final",
	]
	var candidato      : Node  = null
	var candidato_dist : float = INF
	for grupo in GRUPOS_MISION:
		for nodo in get_tree().get_nodes_in_group(grupo):
			if not nodo.get("_jugador_cerca"): continue
			var d : float = jugador.global_position.distance_to((nodo as Node2D).global_position)
			if d < candidato_dist:
				candidato_dist = d
				candidato = nodo
	if candidato:
		candidato.call("intentar_interactuar")
		get_viewport().set_input_as_handled()
		return
	# ── Sin misión de nivel: contenedores y zonas verdes ─────────
	_verificar_contenedor_cercano()
	_verificar_zona_verde_cercana()


# ── Pantalla de misión — muestra interior del edificio primero ─
func _mostrar_pantalla_mision() -> void:
	if not ZONA_A_MISION.has(_zona_activa):
		return
	var info : Dictionary = ZONA_A_MISION[_zona_activa]
	if is_instance_valid(_edificio_ui):
		_edificio_ui.mostrar(_zona_activa, info, info["npc"])
	else:
		_mision_ui.mostrar(info["modulo_id"], _nombre_activo, info["npc"], info["mision_id"], info["progreso"])


func _on_hablar_npc_edificio() -> void:
	if not ZONA_A_MISION.has(_zona_activa): return
	var info : Dictionary = ZONA_A_MISION[_zona_activa]
	_mision_ui.mostrar(info["modulo_id"], _nombre_activo, info["npc"], info["mision_id"], info["progreso"])


func _on_salida_edificio() -> void:
	if is_instance_valid(_edificio_ui):
		_edificio_ui.ocultar()


func _on_mision_aceptada(mision_id: String) -> void:
	if is_instance_valid(_edificio_ui) and _edificio_ui.visible:
		_edificio_ui.ocultar()
	_mision_activa = mision_id
	for datos in DATOS_NPCS:
		if datos["mision_id"] == mision_id:
			if _dialogo_ui:
				_dialogo_ui.iniciar(datos["nombre"], datos["dialogos"], mision_id, datos["color"])
			return

func _on_mision_cancelada() -> void:
	pass


# ── Diálogo → lanza quiz o minijuego según misión ────────────
func _on_dialogo_terminado(mision_id: String) -> void:
	if mision_id == "":
		return

	# M3 Residuos → minijuego de clasificación
	if mision_id == "mision_residuos":
		if _minijuego_residuos:
			_minijuego_residuos.iniciar()
		return

	# Resto de misiones → quiz
	if not is_instance_valid(_quiz_ui):
		return
	if not QUIZ_POR_MISION.has(mision_id):
		return
	var nombre : String = "NPC"
	for d in DATOS_NPCS:
		if d["mision_id"] == mision_id:
			nombre = d["nombre"]
			break
	_quiz_ui.iniciar(QUIZ_POR_MISION[mision_id], nombre)


# ── Callbacks de completado ───────────────────────────────────
func _on_quiz_completado(xp: int) -> void:
	_aplicar_xp(xp, _mision_activa)
	EconomiaManager.on_modulo_completado(_modulo_activo, xp, 30)

func _on_minijuego_completado(xp: int) -> void:
	# "mision_residuos_minijuego", NO "mision_residuos": ese id ya lo usa
	# la zona del NPC Yulimar (ZONA_A_MISION, quiz real de reciclaje).
	# Compartirlo era inofensivo antes (guardar_progreso() no distinguía
	# duplicados); con la RPC idempotente (misiones_estudiante, PK
	# user_id+mision_id) colisiona: quien complete segundo — el minijuego
	# bonus o el quiz de Yulimar — no volvería a recibir XP nunca. Además
	# reusar "mision_residuos" acá disparaba sin querer la rama legacy de
	# _aplicar_xp() (el loop de ZONA_A_MISION), que ya manda su propio
	# guardar_progreso() — duplicaba la llamada de red en cada partida.
	_aplicar_xp(xp, "mision_residuos_minijuego")
	EconomiaManager.ganar_creditos(xp / 5)
	# Actualizar progreso M3 en sidebar (10 aciertos = 50 XP máx → 100%)
	var pct  : float = clampf(float(xp) / 50.0, 0.0, 1.0)
	var prev : float = float(_progreso_modulos.get(3, 0.0))
	_progreso_modulos[3] = clampf(prev + pct * 0.5, 0.0, 1.0)
	_actualizar_sidebar()
	# El minijuego es un bonus aparte, no una de las 6 misiones de reciclaje
	# que cuenta NivelManager — así que su % de acierto propio (pct) y su
	# xp>=40 propio NO representan el estado real del módulo 3. Antes se
	# mandaban tal cual a progreso_estudiante, lo que podía marcar
	# completado=true con una sola buena partida del minijuego aunque no
	# se hubiera hecho ninguna misión real de reciclaje — grave ahora que
	# completado va a ser irreversible. Se manda el % y el completado
	# reales del módulo, igual que el resto de los callbacks.
	var nm3 = _nivel_mgr()
	SupabaseManager.guardar_progreso(3, "mision_residuos_minijuego",
		int((nm3.pct_nivel(3) if nm3 else 0.0) * 100), xp,
		nm3.nivel_completo(3) if nm3 else false)
	_mostrar_mision_completada("mision_residuos", xp)

func _aplicar_xp(xp: int, mision_id: String) -> void:
	var nivel_antes := _nivel_actual
	_xp_total += xp
	_actualizar_hud()
	if xp > 0:
		_flotar_xp(xp)
		_sfx("xp_bonus" if xp >= 20 else "xp")

	print("✅ XP ganada: %d  |  Total: %d  |  Misión: %s" % [xp, _xp_total, mision_id])

	if _nivel_actual > nivel_antes:
		_mostrar_celebracion(NIVELES[_nivel_actual]["nombre"])
		_sfx("nivel")

	# Actualiza progreso de la zona/misión completada y refresca mapa
	for zona_key in ZONA_A_MISION.keys():
		var info : Dictionary = ZONA_A_MISION[zona_key]
		if info["mision_id"] == mision_id:
			var nuevo : float = clampf(float(info["progreso"]) + 0.20, 0.0, 1.0)
			ZONA_A_MISION[zona_key]["progreso"] = nuevo
			var mod_id : int = int(info["modulo_id"])
			if mapa_campus and mapa_campus.has_method("actualizar_modulo"):
				mapa_campus.actualizar_modulo(mod_id, nuevo)
			# Actualiza dict de progreso para sidebar y persiste
			_progreso_modulos[mod_id] = nuevo
			_actualizar_sidebar()
			_mostrar_mision_completada(mision_id, xp)
			# Persistir en Supabase — usa el % y el completado REALES de
			# NivelManager, no `nuevo` (el contador propio y desconectado
			# de este sistema viejo de NPCs/quiz: +0.20 por diálogo,
			# nada que ver con las misiones de mapa que sí cuenta
			# NivelManager). Mismo motivo que el fix del minijuego de
			# residuos — evita marcar completado=true de un módulo sin
			# haber hecho sus misiones reales, ahora que es irreversible.
			if SupabaseManager and SupabaseManager.has_method("guardar_progreso"):
				var nm_legacy = _nivel_mgr()
				SupabaseManager.guardar_progreso(mod_id, mision_id,
					int((nm_legacy.pct_nivel(mod_id) if nm_legacy else 0.0) * 100), xp,
					nm_legacy.nivel_completo(mod_id) if nm_legacy else false)
			_sfx("mision")
			_verificar_misiones_completadas()
			break


# ── Reconciliación de XP con el servidor ────────────────────
# _aplicar_xp() suma el xp local de forma optimista ANTES de que
# guardar_progreso() reciba respuesta (para que el HUD reaccione al
# instante). Estas dos señales corrigen esa suma con lo que la RPC
# idempotente realmente otorgó — así el HUD termina reflejando siempre
# lo que el servidor contó, no el valor local, incluso si un clic
# duplicado disparó _completar_mision() más de una vez para la misma
# misión (ver interior_bloque.gd / mision_solar.gd).
func _on_progreso_guardado(mision_id: String, xp_otorgada: int, ya_registrada: bool, correccion_xp: int) -> void:
	if ya_registrada:
		print("SupabaseManager: guardado duplicado de '%s' — no se otorgó XP de nuevo (otorgada: %d)" % [mision_id, xp_otorgada])
	if correccion_xp != 0:
		_xp_total = max(0, _xp_total + correccion_xp)
		_actualizar_hud()


func _on_progreso_guardado_fallido(mision_id: String, xp_local: int) -> void:
	if xp_local != 0:
		push_warning("SupabaseManager: no se pudo confirmar el guardado de '%s' — revirtiendo %d XP local." % [mision_id, xp_local])
		_xp_total = max(0, _xp_total - xp_local)
		_actualizar_hud()


# ── Celebración ──────────────────────────────────────────────
func _mostrar_celebracion(nombre_nivel: String) -> void:
	if not _celebracion_lbl:
		return
	_celebracion_lbl.text     = "⭐ ¡NIVEL SUBIDO!\n%s" % nombre_nivel.to_upper()
	_celebracion_lbl.modulate = Color(1, 1, 0.2, 0.0)
	_celebracion_lbl.scale    = Vector2(0.5, 0.5)
	_celebracion_lbl.visible  = true

	var tw := create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(_celebracion_lbl, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(_celebracion_lbl, "scale", Vector2(1.15, 1.15), 0.22)
	tw.tween_property(_celebracion_lbl, "scale", Vector2(1.0, 1.0), 0.12)
	tw.tween_interval(2.0)
	tw.tween_property(_celebracion_lbl, "modulate", Color(1, 0.85, 0.0, 0.0), 0.55)
	tw.tween_callback(func(): _celebracion_lbl.visible = false; _celebracion_lbl.scale = Vector2(1, 1))

	# Estrellas flotantes extra para el nivel up
	for i in 4:
		_flotar_estrella(i)


# ── Actualizar HUD ───────────────────────────────────────────
func _actualizar_hud() -> void:
	var nivel_idx : int = 0
	for i in range(NIVELES.size()):
		if _xp_total >= NIVELES[i]["xp_min"]:
			nivel_idx = i
	_nivel_actual = nivel_idx

	var nivel_data : Dictionary = NIVELES[nivel_idx]
	var es_max     : bool       = (nivel_idx == NIVELES.size() - 1)

	if _hud_nombre_lbl:
		_hud_nombre_lbl.text = "🌿 Eco-Ranger"
	if _hud_nivel_lbl:
		_hud_nivel_lbl.text = "Nv.%d  %s" % [nivel_idx + 1, nivel_data["nombre"]]

	if _hud_barra_fill and _hud_xp_lbl:
		var xp_en_nivel : int
		var xp_para_sig : int
		if es_max:
			xp_en_nivel = 1
			xp_para_sig = 1
			_hud_xp_lbl.text = "MAX ✓"
		else:
			var sig : Dictionary = NIVELES[nivel_idx + 1]
			xp_en_nivel = _xp_total - nivel_data["xp_min"]
			xp_para_sig = sig["xp_min"] - nivel_data["xp_min"]
			_hud_xp_lbl.text = "%d / %d XP" % [_xp_total, sig["xp_min"]]

		var pct : float = clampf(float(xp_en_nivel) / float(xp_para_sig), 0.0, 1.0)
		_hud_barra_fill.size = Vector2(240.0 * pct, 12)

		var colores_barra : Array = [
			Color(0.18, 0.78, 0.28),
			Color(0.28, 0.88, 0.38),
			Color(0.20, 0.60, 0.88),
			Color(0.88, 0.65, 0.08),
			Color(0.78, 0.28, 0.88),
			Color(0.98, 0.78, 0.08),
		]
		_hud_barra_fill.color = colores_barra[nivel_idx]


# ════════════════════════════════════════════════════════════
# SIDEBAR DE MÓDULOS (lado derecho, siempre visible)
# ════════════════════════════════════════════════════════════
func _construir_sidebar() -> void:
	var ANCHO : float = 175.0
	var ALTO  : float = float(SIDEBAR_MODULOS.size()) * 34.0 + 30.0

	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left   = -ANCHO
	panel.offset_top    = 0.0
	panel.offset_right  = 0.0
	panel.offset_bottom = ALTO
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.07, 0.10, 0.97)
	ps.border_color = Color(0.20, 0.62, 0.20)
	ps.set_border_width_all(2)
	ps.corner_radius_bottom_left  = 10
	ps.corner_radius_top_left     = 0
	panel.add_theme_stylebox_override("panel", ps)
	_hud_canvas.add_child(panel)

	var titulo := Label.new()
	titulo.text = "GreenMetric"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.position = Vector2(0, 6)
	titulo.size     = Vector2(ANCHO, 18)
	titulo.add_theme_font_size_override("font_size", 10)
	titulo.add_theme_color_override("font_color", Color(0.40, 0.85, 0.42))
	panel.add_child(titulo)

	var sep := ColorRect.new()
	sep.position = Vector2(8, 22)
	sep.size     = Vector2(ANCHO - 16, 1)
	sep.color    = Color(0.20, 0.62, 0.20, 0.50)
	panel.add_child(sep)

	for i in SIDEBAR_MODULOS.size():
		var info : Dictionary = SIDEBAR_MODULOS[i]
		var ry : float = 28.0 + i * 34.0
		var col : Color = info["color"]

		# Icono + nombre
		var icono_lbl := Label.new()
		icono_lbl.text = info["icono"]
		icono_lbl.position = Vector2(6, ry)
		icono_lbl.add_theme_font_size_override("font_size", 12)
		panel.add_child(icono_lbl)

		var nombre_lbl := Label.new()
		nombre_lbl.text = info["nombre"]
		nombre_lbl.position = Vector2(24, ry)
		nombre_lbl.size = Vector2(ANCHO - 30, 14)
		nombre_lbl.add_theme_font_size_override("font_size", 9)
		nombre_lbl.add_theme_color_override("font_color", Color(0.78, 0.88, 0.80))
		panel.add_child(nombre_lbl)

		# Barra de progreso
		var barra_bg := ColorRect.new()
		barra_bg.position = Vector2(6, ry + 15)
		barra_bg.size     = Vector2(ANCHO - 20, 8)
		barra_bg.color    = Color(0.10, 0.14, 0.20)
		panel.add_child(barra_bg)

		var barra_fill := ColorRect.new()
		barra_fill.position = Vector2(0, 0)
		barra_fill.size     = Vector2(0, 8)
		barra_fill.color    = col
		barra_bg.add_child(barra_fill)
		_sidebar_fills.append(barra_fill)

		# Porcentaje
		var pct_lbl := Label.new()
		pct_lbl.position = Vector2(ANCHO - 28, ry + 14)
		pct_lbl.size     = Vector2(22, 12)
		pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		pct_lbl.add_theme_font_size_override("font_size", 9)
		pct_lbl.add_theme_color_override("font_color", Color(0.60, 0.68, 0.62))
		panel.add_child(pct_lbl)
		_sidebar_pcts.append(pct_lbl)

	_actualizar_sidebar()


func _actualizar_sidebar() -> void:
	for i in SIDEBAR_MODULOS.size():
		var modulo_id : int   = SIDEBAR_MODULOS[i]["id"]
		var pct       : float = clampf(float(_progreso_modulos.get(modulo_id, 0.0)), 0.0, 1.0)
		var BAR_W     : float = 135.0   # ancho fijo de la barra bg
		if i < _sidebar_fills.size():
			var fill : ColorRect = _sidebar_fills[i]
			var tw := create_tween().set_ease(Tween.EASE_OUT)
			tw.tween_property(fill, "size:x", BAR_W * pct, 0.35)
		if i < _sidebar_pcts.size():
			var lbl : Label = _sidebar_pcts[i]
			lbl.text = "%d%%" % int(pct * 100)


# ════════════════════════════════════════════════════════════
# NOTIFICACIÓN DE ZONA (centro pantalla, aparece y desaparece)
# ════════════════════════════════════════════════════════════
func _construir_notificacion_zona() -> void:
	_notif_zona_lbl = Label.new()
	_notif_zona_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_notif_zona_lbl.offset_left   = -250
	_notif_zona_lbl.offset_top    = 40
	_notif_zona_lbl.offset_right  =  250
	_notif_zona_lbl.offset_bottom =  90
	_notif_zona_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notif_zona_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_notif_zona_lbl.add_theme_font_size_override("font_size", 16)
	_notif_zona_lbl.add_theme_color_override("font_color", Color.WHITE)
	_notif_zona_lbl.modulate.a = 0.0
	_notif_zona_lbl.visible    = true
	_hud_canvas.add_child(_notif_zona_lbl)


# ════════════════════════════════════════════════════════════
# AVISO DE ESTADO DE CARGA (save corrupto/recuperado)
# ════════════════════════════════════════════════════════════
# Antes, si nivel_progreso.json se corrompía (cierre abrupto a mitad de
# escritura, disco lleno), NivelManager._cargar() fallaba en silencio y
# el jugador volvía a Nivel 1 sin ninguna explicación — indistinguible
# de "el juego está roto". Ahora se avisa explícitamente, con un panel
# que el jugador debe cerrar a propósito (no un toast que se pierde solo).
func _avisar_estado_carga() -> void:
	var nm = _nivel_mgr()
	if not nm: return
	var estado : String = nm.obtener_estado_carga()
	if estado == "ok": return

	var titulo  : String
	var mensaje : String
	var col_borde : Color
	if estado == "recuperado":
		titulo  = "⚠️ Progreso recuperado"
		mensaje = "El archivo de guardado no se pudo leer (probablemente el juego se cerró de golpe la última vez). Se recuperó tu progreso desde la copia de respaldo automática — puede faltar lo último que hiciste justo antes del cierre."
		col_borde = Color(0.95, 0.70, 0.15)
	else:
		titulo  = "🚨 No se pudo recuperar el progreso"
		mensaje = "Tanto el archivo de guardado como su respaldo están dañados y no se pudieron leer. Se reinició el progreso desde Nivel 1. Lo lamento — a partir de ahora cada guardado mantiene una copia de respaldo para que esto no vuelva a pasar sin aviso."
		col_borde = Color(0.92, 0.30, 0.28)

	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.75)
	_hud_canvas.add_child(overlay)

	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(460, 220)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -230.0; panel.offset_top    = -110.0
	panel.offset_right  =  230.0; panel.offset_bottom =  110.0
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.08, 0.06, 0.04, 0.98)
	ps.border_color = col_borde
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(16)
	ps.shadow_color = Color(col_borde.r, col_borde.g, col_borde.b, 0.45)
	ps.shadow_size  = 22
	panel.add_theme_stylebox_override("panel", ps)
	overlay.add_child(panel)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(k, 18)
	panel.add_child(mg)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	mg.add_child(vb)

	var tit_lbl := Label.new()
	tit_lbl.text = titulo
	tit_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tit_lbl.add_theme_font_size_override("font_size", 17)
	tit_lbl.add_theme_color_override("font_color", col_borde)
	vb.add_child(tit_lbl)

	var msg_lbl := Label.new()
	msg_lbl.text = mensaje
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg_lbl.add_theme_font_size_override("font_size", 13)
	msg_lbl.add_theme_color_override("font_color", Color(0.85, 0.82, 0.78))
	vb.add_child(msg_lbl)

	var btn := Button.new()
	btn.text = "Entendido"
	btn.custom_minimum_size = Vector2(0, 40)
	btn.add_theme_font_size_override("font_size", 13)
	var bs := StyleBoxFlat.new()
	bs.bg_color     = Color(0.20, 0.16, 0.05)
	bs.border_color = col_borde
	bs.set_border_width_all(2)
	bs.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", bs)
	btn.pressed.connect(func(): overlay.queue_free())
	vb.add_child(btn)


func _mostrar_notificacion_zona(icono: String, nombre: String, col: Color) -> void:
	if not is_instance_valid(_notif_zona_lbl): return
	_notif_zona_lbl.text = "%s  %s" % [icono, nombre]
	_notif_zona_lbl.add_theme_color_override("font_color", col)
	var tw := create_tween()
	tw.tween_property(_notif_zona_lbl, "modulate:a", 1.0, 0.22)
	tw.tween_interval(1.4)
	tw.tween_property(_notif_zona_lbl, "modulate:a", 0.0, 0.35)


# ════════════════════════════════════════════════════════════
# PANEL DE MISIÓN COMPLETADA
# ════════════════════════════════════════════════════════════
func _construir_panel_completado() -> void:
	_complete_panel = Panel.new()
	_complete_panel.set_anchors_preset(Control.PRESET_CENTER)
	_complete_panel.custom_minimum_size = Vector2(420, 180)
	_complete_panel.offset_left   = -210
	_complete_panel.offset_top    = -90
	_complete_panel.offset_right  =  210
	_complete_panel.offset_bottom =  90
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.08, 0.05, 0.97)
	ps.border_color = Color(0.28, 0.88, 0.32)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(16)
	ps.shadow_color = Color(0.18, 0.72, 0.22, 0.55)
	ps.shadow_size  = 20
	_complete_panel.add_theme_stylebox_override("panel", ps)
	_complete_panel.visible = false
	_hud_canvas.add_child(_complete_panel)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mg.add_theme_constant_override("margin_left",   24)
	mg.add_theme_constant_override("margin_right",  24)
	mg.add_theme_constant_override("margin_top",    18)
	mg.add_theme_constant_override("margin_bottom", 18)
	_complete_panel.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	mg.add_child(vbox)

	_complete_titulo = Label.new()
	_complete_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_complete_titulo.add_theme_font_size_override("font_size", 22)
	_complete_titulo.add_theme_color_override("font_color", Color(0.30, 1.00, 0.42))
	vbox.add_child(_complete_titulo)

	_complete_xp = Label.new()
	_complete_xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_complete_xp.add_theme_font_size_override("font_size", 15)
	_complete_xp.add_theme_color_override("font_color", Color(1.0, 0.85, 0.18))
	vbox.add_child(_complete_xp)

	var barra_bg := ColorRect.new()
	barra_bg.custom_minimum_size = Vector2(360, 12)
	barra_bg.color = Color(0.10, 0.16, 0.12)
	barra_bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(barra_bg)

	_complete_barra = ColorRect.new()
	_complete_barra.size = Vector2(0, 12)
	_complete_barra.color = Color(0.28, 0.90, 0.35)
	barra_bg.add_child(_complete_barra)


# ════════════════════════════════════════════════════════════
# PANEL DE MEJORA DE ZONA VERDE
# ════════════════════════════════════════════════════════════
func _construir_panel_zona_mejora() -> void:
	_panel_zona_mejora = Panel.new()
	_panel_zona_mejora.set_anchors_preset(Control.PRESET_CENTER)
	_panel_zona_mejora.custom_minimum_size = Vector2(320, 220)
	_panel_zona_mejora.offset_left   = -160
	_panel_zona_mejora.offset_top    = -110
	_panel_zona_mejora.offset_right  =  160
	_panel_zona_mejora.offset_bottom =  110
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.04, 0.09, 0.06, 0.97)
	ps.border_color = Color(0.28, 0.85, 0.32)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(14)
	ps.shadow_color = Color(0.18, 0.72, 0.22, 0.50)
	ps.shadow_size  = 18
	_panel_zona_mejora.add_theme_stylebox_override("panel", ps)
	_panel_zona_mejora.visible = false
	_hud_canvas.add_child(_panel_zona_mejora)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left","margin_right","margin_top","margin_bottom"]:
		mg.add_theme_constant_override(m, 20)
	_panel_zona_mejora.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	mg.add_child(vbox)

	_pzm_titulo_lbl = Label.new()
	_pzm_titulo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pzm_titulo_lbl.add_theme_font_size_override("font_size", 15)
	_pzm_titulo_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.45))
	vbox.add_child(_pzm_titulo_lbl)

	_pzm_nivel_lbl = Label.new()
	_pzm_nivel_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pzm_nivel_lbl.add_theme_font_size_override("font_size", 13)
	_pzm_nivel_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.22))
	vbox.add_child(_pzm_nivel_lbl)

	_pzm_xp_lbl = Label.new()
	_pzm_xp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pzm_xp_lbl.add_theme_font_size_override("font_size", 11)
	_pzm_xp_lbl.add_theme_color_override("font_color", Color(0.65, 0.85, 0.65))
	vbox.add_child(_pzm_xp_lbl)

	_pzm_costo_lbl = Label.new()
	_pzm_costo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pzm_costo_lbl.add_theme_font_size_override("font_size", 11)
	_pzm_costo_lbl.add_theme_color_override("font_color", Color(0.85, 0.75, 0.20))
	vbox.add_child(_pzm_costo_lbl)

	_pzm_btn_mejorar = Button.new()
	_pzm_btn_mejorar.custom_minimum_size = Vector2(0, 40)
	_pzm_btn_mejorar.add_theme_font_size_override("font_size", 13)
	var s_m := StyleBoxFlat.new()
	s_m.bg_color     = Color(0.10, 0.28, 0.12)
	s_m.border_color = Color(0.28, 0.80, 0.32)
	s_m.set_border_width_all(2)
	s_m.set_corner_radius_all(8)
	_pzm_btn_mejorar.add_theme_stylebox_override("normal", s_m)
	_pzm_btn_mejorar.pressed.connect(_on_btn_mejorar_zona)
	vbox.add_child(_pzm_btn_mejorar)

	var btn_cerrar := Button.new()
	btn_cerrar.text = "Cerrar"
	btn_cerrar.custom_minimum_size = Vector2(0, 34)
	btn_cerrar.add_theme_font_size_override("font_size", 11)
	var s_c := StyleBoxFlat.new()
	s_c.bg_color     = Color(0.12, 0.06, 0.06)
	s_c.border_color = Color(0.55, 0.20, 0.20)
	s_c.set_border_width_all(1)
	s_c.set_corner_radius_all(6)
	btn_cerrar.add_theme_stylebox_override("normal", s_c)
	btn_cerrar.pressed.connect(_cerrar_panel_zona)
	vbox.add_child(btn_cerrar)


func _mostrar_panel_zona(zona: Node2D) -> void:
	_zona_en_panel = zona
	var nombre  : String = zona.nombre_zona
	var lvl     : int    = zona.nivel
	var xp_p    : int    = zona.xp_pasiva_actual()
	var n_lvl   : String = zona.nombre_nivel_actual()
	var iconos  : Array  = ["🌱", "🌿", "🌳"]

	_pzm_titulo_lbl.text = "%s  %s" % [iconos[lvl - 1], nombre]
	_pzm_nivel_lbl.text  = "Nivel %d — %s" % [lvl, n_lvl]
	_pzm_xp_lbl.text     = "+%d XP / minuto   |   Módulo: %d" % [xp_p, zona.modulo_id]

	if zona.puede_mejorar():
		var costo : int    = zona.costo_siguiente()
		var sig   : String = iconos[lvl]   # siguiente nivel
		_pzm_costo_lbl.text      = "Costo: %d EC  →  %s Nivel %d" % [costo, sig, lvl + 1]
		_pzm_btn_mejorar.text    = "⬆ Mejorar zona  (%d EC)" % costo
		_pzm_btn_mejorar.visible = true
	else:
		_pzm_costo_lbl.text      = "Nivel máximo alcanzado"
		_pzm_btn_mejorar.visible = false

	_panel_zona_mejora.modulate.a = 0.0
	_panel_zona_mejora.visible    = true
	var tw := create_tween()
	tw.tween_property(_panel_zona_mejora, "modulate:a", 1.0, 0.18)


func _cerrar_panel_zona() -> void:
	if not is_instance_valid(_panel_zona_mejora): return
	var tw := create_tween()
	tw.tween_property(_panel_zona_mejora, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func(): _panel_zona_mejora.visible = false)
	_zona_en_panel = null


func _on_btn_mejorar_zona() -> void:
	if not is_instance_valid(_zona_en_panel): return
	var zona  : Node2D = _zona_en_panel
	var costo : int    = zona.costo_siguiente()
	if EconomiaManager.ecocredits < costo:
		_mostrar_notificacion_zona("✗", "Faltan %d EC" % (costo - EconomiaManager.ecocredits),
				Color(1.0, 0.35, 0.35))
		return
	EconomiaManager.gastar_creditos(costo)
	var lvl_antes : int = zona.nivel
	zona.aplicar_mejora()
	# Recompensas inmediatas
	var xp_bonus : int   = zona.XP_MEJORA_INM[lvl_antes - 1]
	var prog_bon : float = zona.PROG_MEJORA[lvl_antes - 1]
	_aplicar_xp(xp_bonus, "mejora_zona_%s" % zona.nombre_zona.to_lower().replace(" ","_"))
	var mod_id  : int   = zona.modulo_id
	var nuevo   : float = clampf(float(_progreso_modulos.get(mod_id, 0.0)) + prog_bon, 0.0, 1.0)
	_progreso_modulos[mod_id] = nuevo
	_actualizar_sidebar()
	_sfx("xp_bonus")
	_mostrar_notificacion_zona("🌳", "%s → Nivel %d  (+%d XP)" % [zona.nombre_zona, zona.nivel, xp_bonus],
			Color(0.30, 1.0, 0.42))
	_mostrar_panel_zona(zona)   # refresca el panel con el nuevo nivel


func _mostrar_mision_completada(mision_id: String, xp_ganado: int) -> void:
	if not is_instance_valid(_complete_panel): return
	var nombre_mision : String = mision_id.replace("_", " ").capitalize()
	_complete_titulo.text = "✓ MISIÓN COMPLETADA\n" + nombre_mision
	_complete_xp.text     = "+%d XP   (Total: %d XP)" % [xp_ganado, _xp_total]

	_complete_panel.modulate.a = 0.0
	_complete_panel.scale      = Vector2(0.7, 0.7)
	_complete_panel.visible    = true
	_complete_barra.size.x     = 0.0

	var pct : float = clampf(float(_xp_total) / 12000.0, 0.0, 1.0)
	var tw := create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(_complete_panel, "modulate:a", 1.0, 0.22)
	tw.parallel().tween_property(_complete_panel, "scale", Vector2(1.0, 1.0), 0.28)
	tw.tween_property(_complete_barra, "size:x", 360.0 * pct, 0.55)
	tw.tween_interval(2.0)
	tw.tween_property(_complete_panel, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func(): _complete_panel.visible = false)


# ════════════════════════════════════════════════════════════
# XP FLOTANTE
# ════════════════════════════════════════════════════════════
func _flotar_xp(cantidad: int) -> void:
	var lbl := Label.new()
	lbl.text = "+%d XP" % cantidad
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.28, 1.0, 0.42))
	lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var base_y : float = 34.0 + float(_xp_float_offset) * 24.0
	lbl.position = Vector2(258.0, base_y)
	_hud_canvas.add_child(lbl)
	_xp_float_offset = (_xp_float_offset + 1) % 4

	var tw := create_tween()
	tw.tween_property(lbl, "position:y", base_y - 36.0, 0.85).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.85).set_ease(Tween.EASE_IN)
	tw.tween_callback(lbl.queue_free)


func _flotar_estrella(idx: int) -> void:
	var lbl := Label.new()
	lbl.text = "⭐"
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	var spread_x : float = float(idx - 2) * 55.0
	lbl.offset_left   = spread_x - 12
	lbl.offset_top    = 0
	lbl.offset_right  = spread_x + 12
	lbl.offset_bottom = 30
	lbl.modulate.a    = 1.0
	_hud_canvas.add_child(lbl)

	var tw := create_tween()
	tw.tween_property(lbl, "offset_top",    -80.0, 1.0).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "offset_bottom", -50.0, 1.0).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	tw.tween_callback(lbl.queue_free)


# ════════════════════════════════════════════════════════════
# EFECTO DE CÁMARA
# ════════════════════════════════════════════════════════════
func _on_interaccion_iniciada() -> void:
	var tw := create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(camara, "zoom", Vector2(1.7, 1.7), 0.22)
	tw.tween_interval(0.3)
	tw.tween_property(camara, "zoom", Vector2(1.5, 1.5), 0.40)


# ════════════════════════════════════════════════════════════
# SISTEMAS EVA — Tutorial, Crisis, Economía, Leaderboard
# ════════════════════════════════════════════════════════════
const HINT_ESCENA := preload("res://scenes/ui/hint_bubble.gd")

func _init_sistemas_eva() -> void:
	# Controles táctiles (solo activos en móvil/touch)
	var touch_ui := TOUCH_ESCENA.new()
	add_child(touch_ui)

	# Sistema de pistas contextuales (toast notifications)
	var hint_ui := HINT_ESCENA.new()
	add_child(hint_ui)

	_tutorial_ui = TUTORIAL_ESCENA.new()
	add_child(_tutorial_ui)
	_tutorial_ui.tutorial_completado.connect(_on_tutorial_completado)

	_crisis_ui = CRISIS_ESCENA.new()
	add_child(_crisis_ui)
	_crisis_ui.crisis_resulta.connect(_on_crisis_resulta)

	_leaderboard_ui = LEADERBOARD_ESCENA.new()
	add_child(_leaderboard_ui)

	_sim_decision_ui = SIMULADOR_ESCENA.new()
	add_child(_sim_decision_ui)
	_sim_decision_ui.decision_tomada.connect(_on_decision_tomada)

	# Pantalla de resultados GreenMetric
	_resultados_ui = RESULTADOS_ESCENA.new()
	add_child(_resultados_ui)
	_resultados_ui.cerrar_resultados.connect(func(): pass)

	# Zonas verdes adoptables
	_spawn_zonas_verdes()

	# Contenedores de basura
	_spawn_contenedores()

	# Sistema de misiones por nivel (Nivel 1 y 2)
	_init_misiones_nivel()
	_avisar_estado_carga()

	# EcoCredits label (esquina superior derecha)
	_hud_creditos_lbl = Label.new()
	_hud_creditos_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hud_creditos_lbl.offset_left   =  10
	_hud_creditos_lbl.offset_top    =  58
	_hud_creditos_lbl.offset_right  = 190
	_hud_creditos_lbl.offset_bottom =  76
	_hud_creditos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_hud_creditos_lbl.add_theme_font_size_override("font_size", 11)
	_hud_creditos_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
	_hud_canvas.add_child(_hud_creditos_lbl)

	# Energía/Vidas label
	_hud_energia_lbl = Label.new()
	_hud_energia_lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_hud_energia_lbl.offset_left   = 190
	_hud_energia_lbl.offset_top    =  58
	_hud_energia_lbl.offset_right  = 308
	_hud_energia_lbl.offset_bottom =  76
	_hud_energia_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud_energia_lbl.add_theme_font_size_override("font_size", 11)
	_hud_energia_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	_hud_canvas.add_child(_hud_energia_lbl)

	# Insignia flotante (abajo centro)
	_insignia_lbl = Label.new()
	_insignia_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_insignia_lbl.offset_left   = -220
	_insignia_lbl.offset_top    = -130
	_insignia_lbl.offset_right  =  220
	_insignia_lbl.offset_bottom = -76
	_insignia_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_insignia_lbl.add_theme_font_size_override("font_size", 15)
	_insignia_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.20))
	_insignia_lbl.visible = false
	_hud_canvas.add_child(_insignia_lbl)

	_crear_btn_mapa_calor()

	# Señales EconomiaManager
	EconomiaManager.ecocredits_cambiados.connect(_on_creditos_cambiados)
	EconomiaManager.energia_cambiada.connect(_on_energia_cambiada)
	EconomiaManager.insignia_obtenida.connect(_on_insignia_obtenida)

	_actualizar_hud_economia()

	# Tutorial la primera vez que ESTA CUENTA entra al juego. La ruta va
	# por cuenta (no por máquina) a propósito: con un archivo global, en
	# una sala de computación compartida solo el primer estudiante vería
	# el tutorial — ver NivelManager.ruta_usuario().
	var _TUTORIAL_FLAG := NivelManager.ruta_usuario("tutorial_visto")
	if not FileAccess.file_exists(_TUTORIAL_FLAG):
		var _tf := FileAccess.open(_TUTORIAL_FLAG, FileAccess.WRITE)
		if _tf: _tf.store_string("1"); _tf.close()
		await get_tree().create_timer(0.6).timeout
		_tutorial_ui.iniciar()


func _process(delta: float) -> void:
	if not _crises_desbloqueadas: return
	if _tutorial_ui and _tutorial_ui.visible: return
	if _crisis_ui and _crisis_ui.visible: return
	_timer_crisis -= delta
	if _timer_crisis <= 0.0 and _crisis_ui:
		_timer_crisis = randf_range(_CRISIS_MIN, _CRISIS_MAX)
		_crisis_ui.iniciar_aleatoria()


func _actualizar_hud_economia() -> void:
	if _hud_creditos_lbl:
		_hud_creditos_lbl.text = "💰 %d EC" % EconomiaManager.ecocredits
	if _hud_energia_lbl:
		var a : int = EconomiaManager.energia_actual
		var sv : String = ""
		for i in EconomiaManager.MAX_ENERGIA:
			sv += "♥" if i < a else "♡"
		_hud_energia_lbl.text = sv


func _on_creditos_cambiados(total: int) -> void:
	if _hud_creditos_lbl:
		_hud_creditos_lbl.text = "💰 %d EC" % total


func _on_energia_cambiada(actual: int, _maximo: int) -> void:
	if _hud_energia_lbl:
		var sv : String = ""
		for i in EconomiaManager.MAX_ENERGIA:
			sv += "♥" if i < actual else "♡"
		_hud_energia_lbl.text = sv


func _on_tutorial_completado() -> void:
	pass  # crises solo se desbloquean al completar el juego


func _on_crisis_resulta(modulo_id: int, exito: bool) -> void:
	var delta : float = 0.08 if exito else -0.06
	var nuevo : float = EconomiaManager.actualizar_impacto(modulo_id, delta)
	_progreso_modulos[modulo_id] = nuevo
	_actualizar_sidebar()
	if mapa_campus and mapa_campus.has_method("actualizar_modulo"):
		mapa_campus.actualizar_modulo(modulo_id, nuevo)
	if exito:
		_aplicar_xp(25, "crisis_%d" % modulo_id)
		EconomiaManager.otorgar_insignia("crisis_resuelta")
	_timer_crisis = randf_range(_CRISIS_MIN, _CRISIS_MAX)


func _on_decision_tomada(modulo_id: int, delta: float) -> void:
	var nuevo : float = EconomiaManager.actualizar_impacto(modulo_id, delta)
	_progreso_modulos[modulo_id] = nuevo
	_actualizar_sidebar()
	if mapa_campus and mapa_campus.has_method("actualizar_modulo"):
		mapa_campus.actualizar_modulo(modulo_id, nuevo)
	if delta > 0.0:
		EconomiaManager.ganar_creditos(15)


# ════════════════════════════════════════════════════════════
# HELPER AUDIO (compatible antes de que el IDE rescane project.godot)
# ════════════════════════════════════════════════════════════
func _sfx(nombre: String) -> void:
	var am := get_node_or_null("/root/AudioManager")
	if am:
		am.tocar(nombre)


# ════════════════════════════════════════════════════════════
# ZONAS VERDES ADOPTABLES
# ════════════════════════════════════════════════════════════
const DATOS_ZONAS_VERDES : Array = [
	# Patio Central (x=480..700, y=120..480) — fuente y arboleda
	{"nombre": "Patio Central",   "pos": Vector2(590, 350), "mod": 4, "radio": 36.0},
	# Corredor oeste norte (junto a Estacionamiento)
	{"nombre": "Corredor Oeste",  "pos": Vector2(250, 200), "mod": 1, "radio": 18.0},
	# Camino norte frente a Bloque E
	{"nombre": "Jardín Norte",    "pos": Vector2(890, 100), "mod": 3, "radio": 18.0},
	# Sur del Rectorado (área abierta y=660..740, x=740..1060)
	{"nombre": "Zona Cultural",   "pos": Vector2(870, 700), "mod": 6, "radio": 28.0},
	# Avenida principal frente a Bloque A
	{"nombre": "Avenida URBE",    "pos": Vector2(490, 752), "mod": 5, "radio": 28.0},
]

func _spawn_zonas_verdes() -> void:
	pass  # zonas mejorables con ecocredits eliminadas del mapa


func _on_zona_verde_adoptada(nombre_zona: String, modulo_id: int) -> void:
	var delta : float = 0.06
	var nuevo : float = clampf(float(_progreso_modulos.get(modulo_id, 0.0)) + delta, 0.0, 1.0)
	_progreso_modulos[modulo_id] = nuevo
	_actualizar_sidebar()
	if mapa_campus and mapa_campus.has_method("actualizar_modulo"):
		mapa_campus.actualizar_modulo(modulo_id, nuevo)
	_aplicar_xp(15, "adopcion_%s" % nombre_zona.to_lower().replace(" ", "_"))
	_mostrar_notificacion_zona("♥", "Adoptaste: " + nombre_zona, Color(0.28, 0.90, 0.40))
	_sfx("adoptar")
	EconomiaManager.ganar_creditos(10)


func _verificar_zona_verde_cercana() -> void:
	var radio_interaccion : float = 55.0
	var nombre_j : String = SupabaseManager.nombre_usuario
	if nombre_j.is_empty(): nombre_j = "Eco-Ranger"
	for zona in _zonas_verdes:
		var z : Node2D = zona as Node2D
		if not is_instance_valid(z): continue
		if jugador.global_position.distance_to(z.global_position) > radio_interaccion:
			continue
		if not z.esta_adoptada():
			z.intentar_adoptar(nombre_j)
		elif z.es_mia(nombre_j):
			_mostrar_panel_zona(z)
		else:
			_mostrar_notificacion_zona("🔒", "Ya adoptada por " + z.adoptado_por, Color(0.80, 0.55, 0.20))
		return


# ════════════════════════════════════════════════════════════
# RESULTADOS GREENMETRIC
# ════════════════════════════════════════════════════════════
func _abrir_resultados() -> void:
	if not is_instance_valid(_resultados_ui): return
	_resultados_ui.actualizar_xp(_xp_total)
	_resultados_ui.mostrar(_progreso_modulos, _xp_total)


func _abrir_simulador() -> void:
	if not is_instance_valid(_sim_decision_ui): return
	if _sim_decision_ui.visible: return
	_sim_decision_ui.mostrar(0)
	_sfx("zona")


func _verificar_misiones_completadas() -> void:
	var total_completadas : int = 0
	for mod_id in _progreso_modulos.keys():
		if float(_progreso_modulos[mod_id]) >= 0.80:
			total_completadas += 1
	if total_completadas >= 6:
		if not _crises_desbloqueadas:
			_crises_desbloqueadas = true
			_timer_crisis = _CRISIS_MIN
		await get_tree().create_timer(1.5).timeout
		_abrir_resultados()


# ════════════════════════════════════════════════════════════
# BOTÓN MAPA DE CALOR (HUD)
# ════════════════════════════════════════════════════════════
func _crear_btn_mapa_calor() -> void:
	# ── Barra de herramientas: 3 botones en esquina inferior izquierda ──
	var s_base := StyleBoxFlat.new()
	s_base.bg_color = Color(0.04, 0.08, 0.06, 0.92)
	s_base.set_border_width_all(2)
	s_base.set_corner_radius_all(8)

	var DEFS : Array = [
		{"emoji": "🌡", "tip": "Mapa de calor energético",  "borde": Color(0.85, 0.38, 0.08),
		 "accion": func():
			if mapa_campus and mapa_campus.has_method("toggle_mapa_calor"):
				mapa_campus.toggle_mapa_calor()
			_sfx("zona")},
		{"emoji": "📊", "tip": "Reporte GreenMetric",        "borde": Color(0.22, 0.80, 0.28),
		 "accion": func(): _abrir_resultados()},
		{"emoji": "🏆", "tip": "Tabla de clasificación",     "borde": Color(0.90, 0.72, 0.08),
		 "accion": func(): _leaderboard_ui.mostrar()},
		{"emoji": "🔬", "tip": "Simulador de decisiones",    "borde": Color(0.55, 0.22, 0.90),
		 "accion": func(): _abrir_simulador()},
	]

	for i in DEFS.size():
		var d  : Dictionary = DEFS[i]
		var sx : float      = 8.0 + i * 48.0
		var s  := s_base.duplicate() as StyleBoxFlat
		s.border_color = d["borde"]
		var btn := Button.new()
		btn.text                = d["emoji"]
		btn.tooltip_text        = d["tip"]
		btn.custom_minimum_size = Vector2(42, 42)
		btn.add_theme_font_size_override("font_size", 20)
		btn.add_theme_stylebox_override("normal", s)
		btn.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		btn.offset_left   = sx
		btn.offset_top    = -50
		btn.offset_right  = sx + 42
		btn.offset_bottom = -8
		btn.pressed.connect(d["accion"])
		_hud_canvas.add_child(btn)


# ════════════════════════════════════════════════════════════
# CONTENEDORES DE BASURA
# ════════════════════════════════════════════════════════════
const DATOS_CONTENEDORES : Array = [
	# Camino norte frente al Cafetín (y=82..120, x=280..480)
	{"nombre": "Cafetín",        "pos": Vector2(430, 100)},
	# Patio central (x=480..700, y=120..480) — zona alta
	{"nombre": "Patio Central",  "pos": Vector2(640, 170)},
	# Corredor oeste (x=220..280), nivel medio
	{"nombre": "Corredor Oeste", "pos": Vector2(250, 500)},
	# Sur del Rectorado (y=660..740, x=740..1060)
	{"nombre": "Sur Rectorado",  "pos": Vector2(870, 705)},
	# Avenida frente al Bloque A
	{"nombre": "Avenida URBE",   "pos": Vector2(490, 752)},
]

func _spawn_contenedores() -> void:
	# Sistema de contenedores grandes retirado para mantener únicamente las papeleras de colores de reciclaje
	return


func _construir_panel_contenedor() -> void:
	_panel_contenedor = Panel.new()
	_panel_contenedor.set_anchors_preset(Control.PRESET_CENTER)
	_panel_contenedor.custom_minimum_size = Vector2(340, 210)
	_panel_contenedor.offset_left   = -170
	_panel_contenedor.offset_top    = -105
	_panel_contenedor.offset_right  =  170
	_panel_contenedor.offset_bottom =  105
	var ps := StyleBoxFlat.new()
	ps.bg_color     = Color(0.06, 0.06, 0.08, 0.97)
	ps.border_color = Color(0.55, 0.42, 0.12)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(14)
	ps.shadow_color = Color(0.40, 0.30, 0.05, 0.50)
	ps.shadow_size  = 16
	_panel_contenedor.add_theme_stylebox_override("panel", ps)
	_panel_contenedor.visible = false
	_hud_canvas.add_child(_panel_contenedor)

	var mg := MarginContainer.new()
	mg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		mg.add_theme_constant_override(m, 20)
	_panel_contenedor.add_child(mg)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	mg.add_child(vbox)

	# Título
	_pc_titulo_lbl = Label.new()
	_pc_titulo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pc_titulo_lbl.add_theme_font_size_override("font_size", 15)
	_pc_titulo_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.30))
	vbox.add_child(_pc_titulo_lbl)

	# Barra de llenado
	_pc_barra_bg = ColorRect.new()
	_pc_barra_bg.custom_minimum_size = Vector2(280, 16)
	_pc_barra_bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_pc_barra_bg.color = Color(0.12, 0.10, 0.06)
	vbox.add_child(_pc_barra_bg)

	_pc_barra_fill = ColorRect.new()
	_pc_barra_fill.size = Vector2(0, 16)
	_pc_barra_fill.color = Color(0.28, 0.72, 0.22)
	_pc_barra_bg.add_child(_pc_barra_fill)

	# Estado / porcentaje
	_pc_estado_lbl = Label.new()
	_pc_estado_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pc_estado_lbl.add_theme_font_size_override("font_size", 12)
	_pc_estado_lbl.add_theme_color_override("font_color", Color(0.80, 0.80, 0.80))
	vbox.add_child(_pc_estado_lbl)

	# Botón llamar servicio
	_pc_btn_servicio = Button.new()
	_pc_btn_servicio.custom_minimum_size = Vector2(0, 40)
	_pc_btn_servicio.add_theme_font_size_override("font_size", 13)
	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(0.12, 0.22, 0.10)
	sb.border_color = Color(0.35, 0.78, 0.28)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	_pc_btn_servicio.add_theme_stylebox_override("normal", sb)
	_pc_btn_servicio.pressed.connect(_on_btn_servicio_contenedor)
	vbox.add_child(_pc_btn_servicio)

	# Botón cerrar
	var btn_c := Button.new()
	btn_c.text = "Cerrar"
	btn_c.custom_minimum_size = Vector2(0, 32)
	btn_c.add_theme_font_size_override("font_size", 11)
	var sc := StyleBoxFlat.new()
	sc.bg_color     = Color(0.12, 0.06, 0.06)
	sc.border_color = Color(0.55, 0.20, 0.20)
	sc.set_border_width_all(1)
	sc.set_corner_radius_all(6)
	btn_c.add_theme_stylebox_override("normal", sc)
	btn_c.pressed.connect(_cerrar_panel_contenedor)
	vbox.add_child(btn_c)


func _verificar_contenedor_cercano() -> bool:
	var radio : float = 52.0
	for nodo in _contenedores:
		var c : Node2D = nodo as Node2D
		if not is_instance_valid(c): continue
		if jugador.global_position.distance_to(c.global_position) > radio: continue
		_mostrar_panel_contenedor(c)
		return true
	return false


func _mostrar_panel_contenedor(c: Node2D) -> void:
	_contenedor_en_panel = c
	var pct  : int    = c.porcentaje()
	var lleno : bool  = c.esta_lleno()
	var serv  : bool  = c.en_servicio

	_pc_titulo_lbl.text = "🗑 Contenedor — %s" % c.nombre_bin

	# Barra de llenado
	var bar_w : float = 280.0
	var col : Color
	if pct >= 80:
		col = Color(0.88, 0.12, 0.12)
	elif pct >= 50:
		col = Color(0.88, 0.72, 0.08)
	else:
		col = Color(0.28, 0.72, 0.22)
	_pc_barra_fill.color  = col
	_pc_barra_fill.size.x = bar_w * clampf(pct / 100.0, 0.0, 1.0)

	# Texto de estado
	if serv:
		_pc_estado_lbl.text = "🧹 Limpiando... el servicio está en camino"
		_pc_btn_servicio.text    = "En servicio..."
		_pc_btn_servicio.disabled = true
	else:
		var estado_txt : String
		if pct >= 90:
			estado_txt = "⚠ URGENTE — %d%% lleno   (+20 XP si lo vacías ahora)" % pct
		elif pct >= 70:
			estado_txt = "Bastante lleno — %d%%   (+15 XP)" % pct
		elif pct >= 50:
			estado_txt = "Medio lleno — %d%%   (+10 XP)" % pct
		else:
			estado_txt = "Poco lleno — %d%%   (+5~7 XP)" % pct
		_pc_estado_lbl.text       = estado_txt
		_pc_btn_servicio.text     = "📞 Llamar servicio de limpieza"
		_pc_btn_servicio.disabled = false

	_panel_contenedor.modulate.a = 0.0
	_panel_contenedor.visible    = true
	var tw := create_tween()
	tw.tween_property(_panel_contenedor, "modulate:a", 1.0, 0.18)


func _cerrar_panel_contenedor() -> void:
	if not is_instance_valid(_panel_contenedor): return
	var tw := create_tween()
	tw.tween_property(_panel_contenedor, "modulate:a", 0.0, 0.14)
	tw.tween_callback(func(): _panel_contenedor.visible = false)
	_contenedor_en_panel = null


func _on_btn_servicio_contenedor() -> void:
	if not is_instance_valid(_contenedor_en_panel): return
	var c : Node2D = _contenedor_en_panel
	if c.en_servicio: return
	c.solicitar_servicio()
	_sfx("zona")
	_cerrar_panel_contenedor()
	_mostrar_notificacion_zona("📞", "Servicio en camino a: %s" % c.nombre_bin,
			Color(0.55, 0.85, 1.0))


func _on_contenedor_vaciado(xp: int, c: Node2D) -> void:
	_aplicar_xp(xp, "contenedor_%s" % c.nombre_bin.to_lower().replace(" ", "_"))
	EconomiaManager.ganar_creditos(xp / 4)
	# Contribuye al progreso M3 (Residuos)
	var delta : float = 0.02 + float(xp) / 1000.0
	var prev  : float = float(_progreso_modulos.get(3, 0.0))
	_progreso_modulos[3] = clampf(prev + delta, 0.0, 1.0)
	_actualizar_sidebar()
	var msg : String
	if xp >= 20:
		msg = "🗑 ¡Contenedor vacío! Servicio excelente  +%d XP" % xp
	else:
		msg = "🗑 Contenedor vaciado  +%d XP" % xp
	_mostrar_notificacion_zona("✓", msg, Color(0.30, 0.90, 0.42))
	_sfx("xp_bonus" if xp >= 15 else "xp")


func _on_insignia_obtenida(_id: String, nombre: String, icono: String) -> void:
	if not _insignia_lbl: return
	_insignia_lbl.text    = "%s  ¡Insignia desbloqueada: %s!" % [icono, nombre]
	_insignia_lbl.modulate = Color(1, 1, 1, 0.0)
	_insignia_lbl.scale    = Vector2(0.75, 0.75)
	_insignia_lbl.visible  = true
	var tw := create_tween().set_ease(Tween.EASE_OUT)
	tw.tween_property(_insignia_lbl, "modulate:a", 1.0, 0.20)
	tw.parallel().tween_property(_insignia_lbl, "scale", Vector2(1.0, 1.0), 0.25)
	tw.tween_interval(2.8)
	tw.tween_property(_insignia_lbl, "modulate:a", 0.0, 0.40)
	tw.tween_callback(func():
		_insignia_lbl.visible = false
		_insignia_lbl.scale   = Vector2(1, 1))


# ════════════════════════════════════════════════════════════
# SISTEMA DE MISIONES POR NIVEL — GreenMetric
# Nivel 1: Infraestructura y Entorno  (plantación sostenible)
# Nivel 2: Energía y Cambio Climático (LED + paneles solares)
# ════════════════════════════════════════════════════════════

const DATOS_ZONAS_TIERRA : Array = [
	# ── Plaza central (interacción clic) ──────────────────────
	{"id": "plantar_rectorado",  "nombre": "Jardín del Rectorado", "indice": 1, "modo": "click",
	 "pos": Vector2(680, 410)},
	{"id": "plantar_patio",      "nombre": "Patio Central",        "indice": 2, "modo": "click",
	 "pos": Vector2(640, 260)},
	{"id": "plantar_este",       "nombre": "Corredor Central",     "indice": 5, "modo": "click",
	 "pos": Vector2(530, 370)},
	# ── Áreas verdes (interacción frotando) ───────────────────
	{"id": "plantar_corredores", "nombre": "Corredor Principal",   "indice": 0, "modo": "drag",
	 "pos": Vector2(250, 200)},
	{"id": "plantar_norte",      "nombre": "Camino Norte",         "indice": 3, "modo": "drag",
	 "pos": Vector2(160, 110)},
	{"id": "plantar_oeste",      "nombre": "Corredor Oeste Sur",   "indice": 7, "modo": "drag",
	 "pos": Vector2(250, 640)},
]

const DATOS_PUNTOS_ENERGIA : Array = [
	# Misiones LED (entradas de los bloques en pasillos transitables, separadas >100px de los NPCs)
	{"id": "led_bloque_a", "nombre": "Bloque A", "tipo": "led", "indice_bloque": 0,
	 "pos": Vector2(310, 660)},
	{"id": "led_bloque_b", "nombre": "Bloque B", "tipo": "led", "indice_bloque": 1,
	 "pos": Vector2(680, 660)},
	{"id": "led_bloque_c", "nombre": "Bloque C", "tipo": "led", "indice_bloque": 2,
	 "pos": Vector2(310, 500)},
	{"id": "led_bloque_d", "nombre": "Bloque D", "tipo": "led", "indice_bloque": 3,
	 "pos": Vector2(310, 300)},
	{"id": "led_bloque_e", "nombre": "Bloque E", "tipo": "led", "indice_bloque": 4,
	 "pos": Vector2(685, 270)},
	{"id": "led_bloque_f", "nombre": "Bloque F", "tipo": "led", "indice_bloque": 5,
	 "pos": Vector2(1100, 330)},
	# Misiones de paneles solares
	{"id": "solar_rectorado",       "nombre": "Rectorado",      "tipo": "solar", "indice_mision": 0,
	 "pos": Vector2(900, 450)},
	{"id": "solar_estacionamiento", "nombre": "Estacionamiento","tipo": "solar", "indice_mision": 1,
	 "pos": Vector2(250, 670)},
]


const DATOS_ZONAS_RECICLAJE : Array = [
	{"id": "reciclar_corredor_n", "nombre": "Corredor Norte",      "pos": Vector2(440, 95)},
	{"id": "reciclar_patio_e",    "nombre": "Patio Este",          "pos": Vector2(660, 450)},
	{"id": "reciclar_bloque_e",   "nombre": "Frente al Bloque E",  "pos": Vector2(685, 170)},
	{"id": "reciclar_oeste",      "nombre": "Corredor Oeste",      "pos": Vector2(250, 480)},
	{"id": "reciclar_sur",        "nombre": "Zona Sur Campus",     "pos": Vector2(750, 700)},
	{"id": "reciclar_este",       "nombre": "Est. a Distancia",    "pos": Vector2(1100, 520)},
]


# NOTA sobre posiciones — 2ª revisión: la primera verificación (Nivel 4)
# solo comprobaba contra los rectángulos de EDIFICIOS, no contra los otros
# ~30 puntos de misión ya existentes en el mapa. Jugando se detectaron
# solapamientos reales (radios de detección que se cruzan) entre puntos
# de niveles distintos, lo que dejaba una misión inalcanzable si el
# jugador quedaba parado en la zona compartida. Se recalcularon las 9
# posiciones de Nivel 4/5 con un chequeo contra los 30 puntos existentes
# a la vez (script aparte, no a ojo) — cero solapamientos nuevos excepto
# uno residual de 10px entre bicicletero_bloque_e y reciclar_este, ya
# mitigado por el cambio en _input() que elige el punto más cercano en
# vez de por prioridad fija de nivel.
const DATOS_LLAVES_AGUA : Array = [
	{"id": "llave_bloque_c",   "nombre": "Baños cerca Bloque C",   "pos": Vector2(490, 510)},
	{"id": "llave_bloque_a",   "nombre": "Baños cerca Bloque A",   "pos": Vector2(150, 550)},
	{"id": "llave_corredor_n", "nombre": "Bebedero Corredor Norte", "pos": Vector2(300, 100)},
	{"id": "llave_patio_e",    "nombre": "Bebedero Corredor Sur",  "pos": Vector2(495, 630)},
	{"id": "llave_este",       "nombre": "Baños Est. a Distancia", "pos": Vector2(1090, 640)},
	{"id": "llave_bloque_b",   "nombre": "Bebedero Plaza Este",    "pos": Vector2(990, 690)},
]

const DATOS_PUNTOS_CAPTACION : Array = [
	{"id": "captacion_biblioteca", "nombre": "Techo de la Biblioteca", "indice_mision": 0,
	 "pos": Vector2(520, 210)},
	{"id": "captacion_bloque_c",   "nombre": "Techo del Bloque C",     "indice_mision": 1,
	 "pos": Vector2(420, 300)},
]

const DATOS_OFICINA_MOVILIDAD : Array = [
	{"id": "oficina_movilidad", "nombre": "Oficina de Movilidad Sostenible", "pos": Vector2(600, 100)},
]

const DATOS_PUNTOS_BICICLETERO : Array = [
	{"id": "bicicletero_bloque_e", "nombre": "Bicicletero — Bloque E", "indice_mision": 0,
	 "pos": Vector2(1020, 460)},
	{"id": "bicicletero_cafetin",   "nombre": "Bicicletero — Cafetín",   "indice_mision": 1,
	 "pos": Vector2(200, 360)},
]

# Posiciones de Nivel 6 verificadas con el mismo chequeo (script aparte)
# contra los ~34 puntos de misión existentes — cero solapamientos, cero
# colisiones con edificios.
const DATOS_PUNTO_MALLA_VERDE : Array = [
	{"id": "malla_verde", "nombre": "Decanato — Rediseño Curricular", "pos": Vector2(795, 99)},
]

const DATOS_PUNTO_COMITE : Array = [
	{"id": "comite_ambiental", "nombre": "Mesa del Comité Ambiental", "pos": Vector2(870, 700)},
]

const DATOS_PUNTO_SEMANA_VERDE : Array = [
	{"id": "semana_verde", "nombre": "Auditorio — Semana Verde URBE", "pos": Vector2(100, 438)},
]

const DATOS_PUNTO_INFORME : Array = [
	{"id": "informe_final", "nombre": "Decanato — Informe de Sostenibilidad", "pos": Vector2(920, 98)},
]


func _nivel_mgr():
	return get_node_or_null("/root/NivelManager")


func _init_misiones_nivel() -> void:
	# ── UIs de misiones ──────────────────────────────────────
	_plantar_ui = MISION_PLANTAR_ESCENA.new()
	add_child(_plantar_ui)
	_plantar_ui.mision_completada_plantar.connect(_on_mision_plantar_completada)

	_interior_ui = INTERIOR_BLOQUE_ESCENA.new()
	add_child(_interior_ui)
	_interior_ui.mision_interior_completada.connect(_on_interior_completado)

	_solar_ui = MISION_SOLAR_ESCENA.new()
	add_child(_solar_ui)
	_solar_ui.mision_solar_completada.connect(_on_solar_completado)

	_reciclar_ui = MISION_RECICLAR_ESCENA.new()
	add_child(_reciclar_ui)
	_reciclar_ui.mision_reciclaje_completada.connect(_on_reciclaje_completado)

	_captacion_ui = MISION_CAPTACION_ESCENA.new()
	add_child(_captacion_ui)
	_captacion_ui.mision_captacion_completada.connect(_on_captacion_completado)

	_movilidad_ui = MISION_MOVILIDAD_ESCENA.new()
	add_child(_movilidad_ui)
	_movilidad_ui.mision_movilidad_completada.connect(_on_movilidad_completado)

	_bicicletero_ui = MISION_BICICLETERO_ESCENA.new()
	add_child(_bicicletero_ui)
	_bicicletero_ui.mision_bicicletero_completada.connect(_on_bicicletero_completado)

	_malla_verde_ui = MISION_MALLA_VERDE_ESCENA.new()
	add_child(_malla_verde_ui)
	_malla_verde_ui.malla_verde_completada.connect(_on_malla_verde_completado)

	_comite_ui = MISION_COMITE_ESCENA.new()
	add_child(_comite_ui)
	_comite_ui.comite_completada.connect(_on_comite_completado)

	_semana_verde_ui = MISION_SEMANA_VERDE_ESCENA.new()
	add_child(_semana_verde_ui)
	_semana_verde_ui.semana_verde_completada.connect(_on_semana_verde_completado)

	_informe_ui = MISION_INFORME_ESCENA.new()
	add_child(_informe_ui)
	_informe_ui.informe_completada.connect(_on_informe_completado)

	# ── Spawns en mapa ───────────────────────────────────────
	_spawn_zonas_tierra()
	_spawn_puntos_energia()
	_spawn_zonas_reciclaje()
	_spawn_llaves_agua()
	_spawn_puntos_captacion()
	_spawn_oficina_movilidad()
	_spawn_puntos_bicicletero()
	_spawn_punto_malla_verde()
	_spawn_punto_comite()
	_spawn_punto_semana_verde()
	_spawn_punto_informe()

	# ── Señales de NivelManager ──────────────────────────────
	var nm = _nivel_mgr()
	if nm:
		nm.nivel_completado.connect(_on_nivel_greenmetric_completado)


func _spawn_zonas_tierra() -> void:
	var nm = _nivel_mgr()
	if not nm or not nm.nivel_desbloqueado(1):
		return
	for dato : Dictionary in DATOS_ZONAS_TIERRA:
		var zt := ZONA_TIERRA_ESCENA.new()
		zt.set("mision_id",        dato["id"])
		zt.set("nombre_zona",      dato["nombre"])
		zt.set("indice_mision",    dato["indice"])
		zt.set("modo_interaccion", dato.get("modo", "click"))
		zt.position = dato["pos"]
		zt.z_index  = 1
		add_child(zt)
		zt.plantar_solicitado.connect(_on_plantar_solicitado)
		if zt.has_signal("riego_realizado"):
			zt.riego_realizado.connect(_on_riego_realizado)


func _spawn_puntos_energia() -> void:
	var nm = _nivel_mgr()
	if not nm or not nm.nivel_desbloqueado(2):
		return
	for dato : Dictionary in DATOS_PUNTOS_ENERGIA:
		var existe := false
		for child in get_children():
			if child.get("mision_id") == dato["id"]:
				existe = true
				break
		if existe: continue
		var pe := PUNTO_ENERGIA_ESCENA.new()
		pe.set("mision_id",    dato["id"])
		pe.set("nombre_punto", dato["nombre"])
		pe.set("tipo",         dato["tipo"])
		if dato.has("indice_bloque"):
			pe.set("indice_bloque", dato["indice_bloque"])
		if dato.has("indice_mision"):
			pe.set("indice_mision", dato["indice_mision"])
		pe.position = dato["pos"]
		pe.z_index  = 1
		add_child(pe)
		pe.energia_solicitada.connect(_on_energia_solicitada)


func _spawn_zonas_reciclaje() -> void:
	var nm = _nivel_mgr()
	if not nm or not nm.nivel_desbloqueado(3):
		return
	for dato : Dictionary in DATOS_ZONAS_RECICLAJE:
		var existe := false
		for child in get_children():
			if child.get("mision_id") == dato["id"]:
				existe = true
				break
		if existe: continue
		var zr := ZONA_RECICLAJE_ESCENA.new()
		zr.set("mision_id",   dato["id"])
		zr.set("nombre_zona", dato["nombre"])
		zr.position = dato["pos"]
		zr.z_index  = 1
		add_child(zr)
		zr.reciclar_solicitado.connect(_on_reciclar_solicitado)
		if zr.has_signal("vaciado_servicio"):
			zr.vaciado_servicio.connect(_on_papelera_vaciada.bind(zr))


func _spawn_llaves_agua() -> void:
	var nm = _nivel_mgr()
	if not nm or not nm.nivel_desbloqueado(4):
		return
	for dato : Dictionary in DATOS_LLAVES_AGUA:
		var existe := false
		for child in get_children():
			if child.get("mision_id") == dato["id"]:
				existe = true
				break
		if existe: continue
		var la := LLAVE_AGUA_ESCENA.new()
		la.set("mision_id",    dato["id"])
		la.set("nombre_llave", dato["nombre"])
		la.position = dato["pos"]
		la.z_index  = 1
		add_child(la)
		la.llave_cerrada.connect(_on_llave_cerrada)


func _spawn_puntos_captacion() -> void:
	var nm = _nivel_mgr()
	if not nm or not nm.nivel_desbloqueado(4):
		return
	for dato : Dictionary in DATOS_PUNTOS_CAPTACION:
		var existe := false
		for child in get_children():
			if child.get("mision_id") == dato["id"]:
				existe = true
				break
		if existe: continue
		var pc := PUNTO_CAPTACION_ESCENA.new()
		pc.set("mision_id",     dato["id"])
		pc.set("nombre_punto",  dato["nombre"])
		pc.set("indice_mision", dato["indice_mision"])
		pc.position = dato["pos"]
		pc.z_index  = 1
		add_child(pc)
		pc.captacion_solicitada.connect(_on_captacion_solicitada)


func _spawn_oficina_movilidad() -> void:
	var nm = _nivel_mgr()
	if not nm or not nm.nivel_desbloqueado(5):
		return
	if not get_tree().get_nodes_in_group("oficina_movilidad").is_empty():
		return
	for dato : Dictionary in DATOS_OFICINA_MOVILIDAD:
		var om := OFICINA_MOVILIDAD_ESCENA.new()
		om.set("nombre_punto", dato["nombre"])
		om.position = dato["pos"]
		om.z_index  = 1
		add_child(om)
		om.movilidad_solicitada.connect(_on_movilidad_solicitada)


func _spawn_puntos_bicicletero() -> void:
	var nm = _nivel_mgr()
	if not nm or not nm.nivel_desbloqueado(5):
		return
	for dato : Dictionary in DATOS_PUNTOS_BICICLETERO:
		var existe := false
		for child in get_children():
			if child.get("mision_id") == dato["id"]:
				existe = true
				break
		if existe: continue
		var pb := PUNTO_BICICLETERO_ESCENA.new()
		pb.set("mision_id",     dato["id"])
		pb.set("nombre_punto",  dato["nombre"])
		pb.set("indice_mision", dato["indice_mision"])
		pb.position = dato["pos"]
		pb.z_index  = 1
		add_child(pb)
		pb.bicicletero_solicitado.connect(_on_bicicletero_solicitado)


func _spawn_punto_malla_verde() -> void:
	var nm = _nivel_mgr()
	if not nm or not nm.nivel_desbloqueado(6):
		return
	for dato : Dictionary in DATOS_PUNTO_MALLA_VERDE:
		var existe := false
		for child in get_children():
			if child.get("mision_id") == dato["id"]:
				existe = true
				break
		if existe: continue
		var pmv := PUNTO_MALLA_VERDE_ESCENA.new()
		pmv.set("mision_id",    dato["id"])
		pmv.set("nombre_punto", dato["nombre"])
		pmv.position = dato["pos"]
		pmv.z_index  = 1
		add_child(pmv)
		pmv.malla_verde_solicitada.connect(_on_malla_verde_solicitada)


func _spawn_punto_comite() -> void:
	var nm = _nivel_mgr()
	if not nm or not nm.nivel_desbloqueado(6):
		return
	for dato : Dictionary in DATOS_PUNTO_COMITE:
		var existe := false
		for child in get_children():
			if child.get("mision_id") == dato["id"]:
				existe = true
				break
		if existe: continue
		var pc := PUNTO_COMITE_ESCENA.new()
		pc.set("mision_id",    dato["id"])
		pc.set("nombre_punto", dato["nombre"])
		pc.position = dato["pos"]
		pc.z_index  = 1
		add_child(pc)
		pc.comite_solicitado.connect(_on_comite_solicitado)


func _spawn_punto_semana_verde() -> void:
	var nm = _nivel_mgr()
	if not nm or not nm.nivel_desbloqueado(6):
		return
	for dato : Dictionary in DATOS_PUNTO_SEMANA_VERDE:
		var existe := false
		for child in get_children():
			if child.get("mision_id") == dato["id"]:
				existe = true
				break
		if existe: continue
		var psv := PUNTO_SEMANA_VERDE_ESCENA.new()
		psv.set("mision_id",    dato["id"])
		psv.set("nombre_punto", dato["nombre"])
		psv.position = dato["pos"]
		psv.z_index  = 1
		add_child(psv)
		psv.semana_verde_solicitada.connect(_on_semana_verde_solicitada)


func _spawn_punto_informe() -> void:
	var nm = _nivel_mgr()
	if not nm or not nm.nivel_desbloqueado(6):
		return
	for dato : Dictionary in DATOS_PUNTO_INFORME:
		var existe := false
		for child in get_children():
			if child.get("mision_id") == dato["id"]:
				existe = true
				break
		if existe: continue
		var pi := PUNTO_INFORME_ESCENA.new()
		pi.set("mision_id",    dato["id"])
		pi.set("nombre_punto", dato["nombre"])
		pi.position = dato["pos"]
		pi.z_index  = 1
		add_child(pi)
		pi.informe_solicitado.connect(_on_informe_solicitado)


func _on_papelera_vaciada(xp: int, ec: int, zr: Node2D) -> void:
	var m_id : String = zr.get("mision_id") if zr.get("mision_id") != null else "papelera"
	_aplicar_xp(xp, "servicio_%s" % m_id)
	EconomiaManager.ganar_creditos(ec)
	_mostrar_notificacion_zona("🧹", "¡Papelera vaciada por el servicio! +%d XP +%d EC" % [xp, ec], Color(0.22, 0.90, 0.28))
	_sfx("mision")


func _on_riego_realizado(zona: Area2D, xp: int, ec: int) -> void:
	var m_id : String = zona.get("mision_id") if zona.get("mision_id") != null else "planta"
	_aplicar_xp(xp, "riego_%s" % m_id)
	_mostrar_notificacion_zona("💧", "¡Planta regada! +%d XP  +%d EC" % [xp, ec], Color(0.28, 0.68, 0.95))
	_sfx("mision")


# ── Callbacks de interacción ──────────────────────────────────

func _on_plantar_solicitado(zona: Area2D) -> void:
	if not is_instance_valid(_plantar_ui): return
	var indice : int    = zona.get("indice_mision")
	var modo   : String = zona.get("modo_interaccion") if zona.get("modo_interaccion") != null else "click"
	_plantar_ui.call("iniciar", indice, zona, modo)


func _on_reciclar_solicitado(zona: Area2D) -> void:
	if not is_instance_valid(_reciclar_ui): return
	var mision_id   : String = zona.get("mision_id")
	var zona_nombre : String = zona.get("nombre_zona")
	_reciclar_ui.call("iniciar", mision_id, zona_nombre, zona)


func _on_energia_solicitada(punto: Area2D) -> void:
	var tipo : String = punto.get("tipo")
	if tipo == "led":
		if not is_instance_valid(_interior_ui): return
		var idx : int = punto.get("indice_bloque") if punto.get("indice_bloque") != null else 0
		_interior_ui.call("iniciar", idx, punto)
	elif tipo == "solar":
		if not is_instance_valid(_solar_ui): return
		var idx : int = punto.get("indice_mision") if punto.get("indice_mision") != null else 0
		_solar_ui.call("iniciar", idx, punto)


func _on_captacion_solicitada(punto: Area2D) -> void:
	if not is_instance_valid(_captacion_ui): return
	var idx : int = punto.get("indice_mision") if punto.get("indice_mision") != null else 0
	_captacion_ui.call("iniciar", idx, punto)


func _on_movilidad_solicitada(punto: Area2D, mision_id: String) -> void:
	if not is_instance_valid(_movilidad_ui): return
	_movilidad_ui.call("iniciar", mision_id, punto)


func _on_bicicletero_solicitado(punto: Area2D) -> void:
	if not is_instance_valid(_bicicletero_ui): return
	var idx : int = punto.get("indice_mision") if punto.get("indice_mision") != null else 0
	_bicicletero_ui.call("iniciar", idx, punto)


func _on_malla_verde_solicitada(punto: Area2D) -> void:
	if not is_instance_valid(_malla_verde_ui): return
	_malla_verde_ui.call("iniciar", punto)


func _on_comite_solicitado(punto: Area2D) -> void:
	if not is_instance_valid(_comite_ui): return
	_comite_ui.call("iniciar", punto)


func _on_semana_verde_solicitada(punto: Area2D) -> void:
	if not is_instance_valid(_semana_verde_ui): return
	_semana_verde_ui.call("iniciar", punto)


func _on_informe_solicitado(punto: Area2D) -> void:
	if not is_instance_valid(_informe_ui): return
	_informe_ui.call("iniciar", punto)


# ── Callbacks de misión completada ───────────────────────────

func _on_mision_plantar_completada(mision_id: String, xp: int, ec: int) -> void:
	_aplicar_xp(xp, mision_id)
	EconomiaManager.ganar_creditos(ec)
	var nm = _nivel_mgr()
	var pct : float = nm.pct_nivel(1) if nm else 0.0
	_progreso_modulos[1] = pct
	_actualizar_sidebar()
	_actualizar_indicador_verde()
	SupabaseManager.guardar_progreso(1, mision_id, int(pct * 100), xp, nm.nivel_completo(1) if nm else false)
	_mostrar_mision_completada(mision_id, xp)
	_sfx("mision")
	print("🌿 Plantación completada: %s | +%d XP | +%d EC" % [mision_id, xp, ec])


func _actualizar_indicador_verde() -> void:
	var nm = _nivel_mgr()
	if not nm: return
	var pct : float = nm.pct_nivel(1)
	if _hud_verde_fill:
		var tw := create_tween()
		tw.tween_property(_hud_verde_fill, "size:x", 236.0 * pct, 0.4)
	if _hud_verde_lbl:
		_hud_verde_lbl.text = "🌿 Índice Verde: %.0f%%" % (pct * 100.0)


func _actualizar_indicador_agua() -> void:
	var nm = _nivel_mgr()
	if not nm: return
	var pct : float = nm.pct_nivel(4)
	if _hud_agua_fill:
		var tw := create_tween()
		tw.tween_property(_hud_agua_fill, "size:x", 236.0 * pct, 0.4)
	if _hud_agua_lbl:
		_hud_agua_lbl.text = "💧 Índice Agua: %.0f%%" % (pct * 100.0)


func _actualizar_indicador_edu() -> void:
	var nm = _nivel_mgr()
	if not nm: return
	var pct : float = nm.pct_nivel(6)
	if _hud_edu_fill:
		var tw := create_tween()
		tw.tween_property(_hud_edu_fill, "size:x", 236.0 * pct, 0.4)
	if _hud_edu_lbl:
		_hud_edu_lbl.text = "📚 Índice Educación: %.0f%%" % (pct * 100.0)


func _on_interior_completado(mision_id: String, xp: int, ec: int) -> void:
	_aplicar_xp(xp, mision_id)
	EconomiaManager.ganar_creditos(ec)
	var nm = _nivel_mgr()
	var pct : float = nm.pct_nivel(2) if nm else 0.0
	_progreso_modulos[2] = pct
	_actualizar_sidebar()
	SupabaseManager.guardar_progreso(2, mision_id, int(pct * 100), xp, nm.nivel_completo(2) if nm else false)
	_mostrar_mision_completada(mision_id, xp)
	_sfx("mision")
	print("⚡ LED completado: %s | +%d XP | +%d EC" % [mision_id, xp, ec])


func _on_reciclaje_completado(mision_id: String, xp: int, ec: int) -> void:
	_aplicar_xp(xp, mision_id)
	EconomiaManager.ganar_creditos(ec)
	var nm = _nivel_mgr()
	var pct : float = nm.pct_nivel(3) if nm else 0.0
	_progreso_modulos[3] = pct
	_actualizar_sidebar()
	SupabaseManager.guardar_progreso(3, mision_id, int(pct * 100), xp, nm.nivel_completo(3) if nm else false)
	_mostrar_mision_completada(mision_id, xp)
	_sfx("mision")
	print("♻ Reciclaje completado: %s | +%d XP | +%d EC" % [mision_id, xp, ec])


func _on_solar_completado(mision_id: String, xp: int, ec: int) -> void:
	_aplicar_xp(xp, mision_id)
	EconomiaManager.ganar_creditos(ec)
	var nm = _nivel_mgr()
	var pct : float = nm.pct_nivel(2) if nm else 0.0
	_progreso_modulos[2] = pct
	_actualizar_sidebar()
	SupabaseManager.guardar_progreso(2, mision_id, int(pct * 100), xp, nm.nivel_completo(2) if nm else false)
	_mostrar_mision_completada(mision_id, xp)
	_sfx("mision")
	print("☀️ Solar completado: %s | +%d XP | +%d EC" % [mision_id, xp, ec])


func _on_llave_cerrada(mision_id: String, xp: int, ec: int) -> void:
	_aplicar_xp(xp, mision_id)
	EconomiaManager.ganar_creditos(ec)
	var nm = _nivel_mgr()
	var pct : float = nm.pct_nivel(4) if nm else 0.0
	_progreso_modulos[4] = pct
	_actualizar_sidebar()
	_actualizar_indicador_agua()
	SupabaseManager.guardar_progreso(4, mision_id, int(pct * 100), xp, nm.nivel_completo(4) if nm else false)
	_mostrar_mision_completada(mision_id, xp)
	_sfx("mision")
	print("💧 Llave cerrada: %s | +%d XP | +%d EC" % [mision_id, xp, ec])


func _on_captacion_completado(mision_id: String, xp: int, ec: int) -> void:
	_aplicar_xp(xp, mision_id)
	EconomiaManager.ganar_creditos(ec)
	var nm = _nivel_mgr()
	var pct : float = nm.pct_nivel(4) if nm else 0.0
	_progreso_modulos[4] = pct
	_actualizar_sidebar()
	_actualizar_indicador_agua()
	SupabaseManager.guardar_progreso(4, mision_id, int(pct * 100), xp, nm.nivel_completo(4) if nm else false)
	_mostrar_mision_completada(mision_id, xp)
	_sfx("mision")
	print("🌧 Captación completada: %s | +%d XP | +%d EC" % [mision_id, xp, ec])


func _on_movilidad_completado(mision_id: String, xp: int, ec: int) -> void:
	_aplicar_xp(xp, mision_id)
	EconomiaManager.ganar_creditos(ec)
	var nm = _nivel_mgr()
	var pct : float = nm.pct_nivel(5) if nm else 0.0
	_progreso_modulos[5] = pct
	_actualizar_sidebar()
	SupabaseManager.guardar_progreso(5, mision_id, int(pct * 100), xp, nm.nivel_completo(5) if nm else false)
	_mostrar_mision_completada(mision_id, xp)
	_sfx("mision")
	print("🚲 Decisión de movilidad tomada: %s | +%d XP | +%d EC" % [mision_id, xp, ec])


func _on_bicicletero_completado(mision_id: String, xp: int, ec: int) -> void:
	_aplicar_xp(xp, mision_id)
	EconomiaManager.ganar_creditos(ec)
	var nm = _nivel_mgr()
	var pct : float = nm.pct_nivel(5) if nm else 0.0
	_progreso_modulos[5] = pct
	_actualizar_sidebar()
	SupabaseManager.guardar_progreso(5, mision_id, int(pct * 100), xp, nm.nivel_completo(5) if nm else false)
	_mostrar_mision_completada(mision_id, xp)
	_sfx("mision")
	print("🚲 Bicicletero instalado: %s | +%d XP | +%d EC" % [mision_id, xp, ec])


func _on_malla_verde_completado(mision_id: String, xp: int, ec: int) -> void:
	_aplicar_xp(xp, mision_id)
	EconomiaManager.ganar_creditos(ec)
	var nm = _nivel_mgr()
	var pct : float = nm.pct_nivel(6) if nm else 0.0
	_progreso_modulos[6] = pct
	_actualizar_sidebar()
	_actualizar_indicador_edu()
	SupabaseManager.guardar_progreso(6, mision_id, int(pct * 100), xp, nm.nivel_completo(6) if nm else false)
	_mostrar_mision_completada(mision_id, xp)
	_sfx("mision")
	print("📚 Malla verde aprobada: %s | +%d XP | +%d EC" % [mision_id, xp, ec])


func _on_comite_completado(mision_id: String, xp: int, ec: int) -> void:
	_aplicar_xp(xp, mision_id)
	EconomiaManager.ganar_creditos(ec)
	var nm = _nivel_mgr()
	var pct : float = nm.pct_nivel(6) if nm else 0.0
	_progreso_modulos[6] = pct
	_actualizar_sidebar()
	_actualizar_indicador_edu()
	SupabaseManager.guardar_progreso(6, mision_id, int(pct * 100), xp, nm.nivel_completo(6) if nm else false)
	_mostrar_mision_completada(mision_id, xp)
	_sfx("mision")
	print("🗣 Comité Ambiental formado: %s | +%d XP | +%d EC" % [mision_id, xp, ec])


func _on_semana_verde_completado(mision_id: String, xp: int, ec: int) -> void:
	_aplicar_xp(xp, mision_id)
	EconomiaManager.ganar_creditos(ec)
	var nm = _nivel_mgr()
	var pct : float = nm.pct_nivel(6) if nm else 0.0
	_progreso_modulos[6] = pct
	_actualizar_sidebar()
	_actualizar_indicador_edu()
	SupabaseManager.guardar_progreso(6, mision_id, int(pct * 100), xp, nm.nivel_completo(6) if nm else false)
	_mostrar_mision_completada(mision_id, xp)
	_sfx("mision")
	print("🎪 Semana Verde organizada: %s | +%d XP | +%d EC" % [mision_id, xp, ec])


func _on_informe_completado(mision_id: String, xp: int, ec: int) -> void:
	_aplicar_xp(xp, mision_id)
	EconomiaManager.ganar_creditos(ec)
	var nm = _nivel_mgr()
	var pct : float = nm.pct_nivel(6) if nm else 0.0
	_progreso_modulos[6] = pct
	_actualizar_sidebar()
	_actualizar_indicador_edu()
	SupabaseManager.guardar_progreso(6, mision_id, int(pct * 100), xp, nm.nivel_completo(6) if nm else false)
	_mostrar_mision_completada(mision_id, xp)
	_sfx("mision")
	print("📄 Informe de Sostenibilidad publicado: %s | +%d XP | +%d EC" % [mision_id, xp, ec])


func _on_nivel_greenmetric_completado(nivel: int) -> void:
	var nm = _nivel_mgr()
	var nombre = nm.NOMBRES_NIVEL[nivel] if nm else "Nivel %d" % nivel
	var icono  = nm.ICONOS_NIVEL[nivel]  if nm else "⭐"
	_mostrar_celebracion("%s NIVEL %d\n¡COMPLETADO!\n%s" % [icono, nivel, nombre])
	_sfx("nivel")
	var bonus_ec : int = int(nm.XP_NIVEL_BONUS.get(nivel, 150)) / 5 if nm else 30
	EconomiaManager.ganar_creditos(bonus_ec)
	var sig_nivel := nivel + 1
	if sig_nivel == 2 and nm and nm.nivel_desbloqueado(2):
		_spawn_puntos_energia()
	elif sig_nivel == 3 and nm and nm.nivel_desbloqueado(3):
		_spawn_zonas_reciclaje()
	elif sig_nivel == 4 and nm and nm.nivel_desbloqueado(4):
		_spawn_llaves_agua()
		_spawn_puntos_captacion()
	elif sig_nivel == 5 and nm and nm.nivel_desbloqueado(5):
		_spawn_oficina_movilidad()
		_spawn_puntos_bicicletero()
	elif sig_nivel == 6 and nm and nm.nivel_desbloqueado(6):
		_spawn_punto_malla_verde()
		_spawn_punto_comite()
		_spawn_punto_semana_verde()
		_spawn_punto_informe()
	print("%s Nivel GreenMetric %d completado! Desbloqueando nivel %d…" % [icono, nivel, sig_nivel])
