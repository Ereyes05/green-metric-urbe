# ============================================================
# plan_movilidad_datos.gd — contenido del Plan de Movilidad (Nivel 5).
# Decisiones, opciones, objeciones del Consejo y sinergias. Solo datos y
# consultas; las reglas están en plan_movilidad.gd.
#
# ESPEJO de public.catalogo_decisiones y public.catalogo_sinergias
# (sql/nivel5_plan_movilidad.sql): id, puntos, contraproducente y costo
# deben coincidir; tests/test_nivel5_movilidad.gd lo verifica leyendo el
# .sql. Si cambia uno, cambiar el otro con una migración nueva.
# Diseño: docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md §5–7
# Cifras de contexto ILUSTRATIVAS (datos mixtos, Tabla 16): validar con la
# Dirección de Sustentabilidad de URBE.
# ============================================================
extends RefCounted

const CATEGORIA := 5
const PRESUPUESTO := 100
const DECISION_CONSEJO := "tr_consejo"

const ENCARGO := "La Dirección de Sustentabilidad y el Rectorado te encargan un Plan de Movilidad para URBE, que vas a presentar ante el Consejo Universitario. Tienes un presupuesto de 100 puntos para seis decisiones repartidas por el campus (en el orden que quieras) y dos bicicleteros (necesitas el kit de la Tienda). Antes de elegir solo vas a ver el costo de cada opción: sus efectos se conocen al confirmar. Una opción contraproducente según GreenMetric resta 1 punto en Decisiones de Transporte, no gasta presupuesto y te deja reintentar. Cuando tengas todo listo, presenta el plan en el Rectorado."

const ACEPTACION_TEXTO : Dictionary = {
	"alta": "Aceptación alta", "media": "Aceptación media", "baja": "Aceptación baja",
}
const ACEPTACION_PESO : Dictionary = {"alta": 1, "media": 2, "baja": 3}

const NOMBRE_LUGAR : Dictionary = {
	"oficina_movilidad": "Oficina de Movilidad (camino norte)",
	"garita_m5": "Garita del Estacionamiento M5",
	"estacionamiento_m5": "Estacionamiento M5",
	"lote_este": "Lote detrás de Estudios a Distancia",
	"parada_rectorado": "Parada de la Av. URBE, frente al Rectorado",
	"porton_vehicular": "Portón vehicular de la Av. URBE",
	"zona_mantenimiento": "Patio de mantenimiento",
	"bicicletero_bloque_e": "Plaza entre el Bloque E y el Rectorado",
	"bicicletero_cafetin": "Borde del M5, camino al Cafetín",
	"rectorado": "Rectorado · Consejo Universitario",
}

const SINERGIAS : Dictionary = {
	"ciclovia_lote":             {"categoria": 1, "puntos": 1, "efecto": "🌿 Entorno +1"},
	"flota_electrica":           {"categoria": 2, "puntos": 1, "efecto": "⚡ Energía +1"},
	"dia_sin_carros_feria":      {"categoria": 6, "puntos": 1, "efecto": "📚 Educación +1"},
	"bicicletero_techado_solar": {"categoria": 2, "puntos": 1, "efecto": "⚡ Energía +1"},
}

const CONSEJO_OPCIONES : Array = [
	{"id": "consejo_0", "aciertos": 0, "puntos": 0.00, "nombre": "Aprobado con condiciones"},
	{"id": "consejo_1", "aciertos": 1, "puntos": 0.30, "nombre": "Aprobado con observaciones"},
	{"id": "consejo_2", "aciertos": 2, "puntos": 0.60, "nombre": "Aprobado"},
	{"id": "consejo_3", "aciertos": 3, "puntos": 1.00, "nombre": "Aprobado sin observaciones"},
]

# ESPEJO de NivelManager.MISIONES_NIVEL[5].
const MISIONES : Array = [
	"tr_permisos", "tr_lote", "tr_carpool", "tr_shuttle", "tr_dia_sin_carros",
	"tr_flota", "tr_bici_bloque_e", "tr_bici_cafetin", "tr_consejo",
]

# Orden = tablero de la Oficina y desempate de objeciones. Las opciones están
# en el orden en que se muestran (la mejor no está siempre en el mismo lugar).
const DECISIONES : Array = [
	{
		"id": "tr_permisos", "tipo": "decision", "lugar": "garita_m5", "indicador": "TR1",
		"titulo": "Permisos de estacionamiento",
		"contexto": "En la garita del Estacionamiento M5 se entregan los permisos anuales. Hoy cualquiera que lo pida recibe uno: hay más carros y motos con permiso que puestos, y en la hora pico de la mañana la cola llega hasta la avenida. GreenMetric (TR1) mide cuántos vehículos entran al campus por cada persona de la comunidad universitaria.",
		"pregunta": "¿Qué política de permisos llevas al plan?",
		"opciones": [
			{"id": "lectoras_de_placas", "corto": "Lectoras de placas",
			 "texto": "Instalar cámaras lectoras de placas y una barrera automática para que la entrada sea más rápida",
			 "costo": 24, "puntos": 0.25, "contraproducente": false, "aceptacion": "alta", "sinergia": "",
			 "explicacion": "Ordena la entrada y da datos reales de cuántos vehículos entran (útiles para reportar TR1), pero no reduce ni un carro: la cola se va, los vehículos se quedan. Mucho gasto para poco efecto en el indicador."},
			{"id": "pintar_mas_puestos", "corto": "Más puestos sobre la grama",
			 "texto": "Acabar con la cola pintando 80 puestos nuevos sobre la franja de grama que rodea el M5",
			 "costo": 14, "puntos": 0.0, "contraproducente": true, "aceptacion": "", "sinergia": "",
			 "explicacion": "Más puestos atraen más carros (TR1 empeora), aumentan el área de estacionamiento en superficie (TR5) y quitan área verde que suma en Entorno. GreenMetric lo cuenta en contra."},
			{"id": "permiso_por_necesidad", "corto": "Permisos por necesidad",
			 "texto": "Dar permiso anual solo a quien vive lejos y sin transporte público, tiene movilidad reducida o comparte el carro; el resto entra con pase diario",
			 "costo": 8, "puntos": 0.60, "contraproducente": false, "aceptacion": "baja", "sinergia": "",
			 "explicacion": "Es una regla, no una obra: cuesta poco y baja directamente los vehículos por persona que mide TR1. Quien pierde su permiso anual se queja, por eso la aceptación es baja: hay que acompañarla con alternativas como la buseta y el carpool."},
		],
	},
	{
		"id": "tr_lote", "tipo": "decision", "lugar": "lote_este", "indicador": "TR5 · TR6",
		"titulo": "El lote poco usado",
		"contexto": "Detrás de Estudios a Distancia hay un lote de tierra y granzón con capacidad para 60 carros que casi nunca pasa de 15. Con lluvia se inunda y en sequía levanta polvo. GreenMetric premia reducir el área de estacionamiento en superficie (TR5) y tener un programa documentado para hacerlo (TR6).",
		"pregunta": "¿Qué haces con el lote?",
		"opciones": [
			{"id": "asfaltar_lote", "corto": "Asfaltar el lote",
			 "texto": "Asfaltarlo y demarcarlo para que por fin se use y descongestione el M5",
			 "costo": 16, "puntos": 0.0, "contraproducente": true, "aceptacion": "", "sinergia": "",
			 "explicacion": "Convierte un lote poco usado en estacionamiento formal: sube el área de estacionamiento en superficie (TR5), va contra el programa de reducción (TR6) y el asfalto calienta y sella el suelo."},
			{"id": "ciclovia_arborizada", "corto": "Ciclovía con árboles",
			 "texto": "Cerrarlo a los carros y convertirlo en un tramo de ciclovía y caminería con árboles nativos de sombra, conectado al portón",
			 "costo": 22, "puntos": 0.60, "contraproducente": false, "aceptacion": "alta", "sinergia": "ciclovia_lote",
			 "explicacion": "Quita área de estacionamiento (TR5), queda como programa de reducción con fecha y metros (TR6) y la sombra hace posible caminar o pedalear con el calor de Maracaibo. Los árboles suman también en Entorno."},
			{"id": "plaza_de_eventos", "corto": "Explanada de eventos",
			 "texto": "Cerrarlo a los carros y dejarlo como explanada de ferias y eventos con piso permeable",
			 "costo": 12, "puntos": 0.35, "contraproducente": false, "aceptacion": "media", "sinergia": "",
			 "explicacion": "También reduce el área de estacionamiento (TR5), pero sin relación con la movilidad: nadie deja el carro por eso. Y si en cada evento vuelve a ser estacionamiento improvisado, el programa pierde credibilidad (TR6)."},
		],
	},
	{
		"id": "tr_carpool", "tipo": "decision", "lugar": "estacionamiento_m5", "indicador": "TR7",
		"titulo": "Viajes compartidos",
		"contexto": "En el M5 casi todos los carros llegan con una sola persona. Muchos estudiantes viven en las mismas urbanizaciones y salen a la misma hora. Una iniciativa de viajes compartidos cuenta para GreenMetric como iniciativa para disminuir los vehículos privados en el campus (TR7).",
		"pregunta": "¿Qué incentivo propones?",
		"opciones": [
			{"id": "app_carpool", "corto": "App de carpool",
			 "texto": "Pagar una aplicación de viajes compartidos con cuentas URBE y un grupo por urbanización",
			 "costo": 26, "puntos": 0.35, "contraproducente": false, "aceptacion": "alta", "sinergia": "",
			 "explicacion": "Gusta y facilita encontrar compañeros, pero sin un beneficio concreto al llegar pocos cambian el hábito. Cuenta como iniciativa (TR7), con poco efecto para lo que cuesta."},
			{"id": "puestos_3_ocupantes", "corto": "Puestos para carros con 3+",
			 "texto": "Reservar los puestos más cercanos a la entrada peatonal para carros que lleguen con 3 o más personas, verificados en la garita hasta las 9 a. m.",
			 "costo": 6, "puntos": 0.60, "contraproducente": false, "aceptacion": "media", "sinergia": "",
			 "explicacion": "Un incentivo visible y barato: el mejor puesto se gana compartiendo. Es una iniciativa concreta de TR7. Quien llega solo pierde comodidad, por eso la aceptación no es alta."},
			{"id": "vender_puestos_reservados", "corto": "Vender puestos reservados",
			 "texto": "Vender puestos reservados con nombre a quien pague la cuota más alta; con lo recaudado se paga el mantenimiento del M5",
			 "costo": 0, "puntos": 0.0, "contraproducente": true, "aceptacion": "", "sinergia": "",
			 "explicacion": "Parece gratis, pero premia al que viene solo en carro y le asegura el puesto: incentiva el vehículo privado, lo contrario de lo que mide TR7."},
		],
	},
	{
		"id": "tr_shuttle", "tipo": "decision", "lugar": "parada_rectorado", "indicador": "TR2",
		"titulo": "Servicio de buseta",
		"contexto": "URBE tiene una buseta que hace una sola vuelta por la mañana. Muchos estudiantes llegan en por puesto o autobús hasta la avenida y caminan el resto bajo el sol, o prefieren venir en carro. GreenMetric (TR2) evalúa si el campus ofrece transporte interno y qué tan útil es.",
		"pregunta": "¿Cómo reorganizas la buseta?",
		"opciones": [
			{"id": "bono_gasolina", "corto": "Bono de gasolina",
			 "texto": "Eliminar la buseta, que va medio vacía, y con ese dinero dar un bono de gasolina al personal",
			 "costo": 10, "puntos": 0.0, "contraproducente": true, "aceptacion": "", "sinergia": "",
			 "explicacion": "Elimina el servicio que mide TR2 y además subsidia el carro particular: más vehículos por persona (TR1) y más emisiones."},
			{"id": "ruta_a_paradas", "corto": "Busetas a las paradas",
			 "texto": "Dos busetas en circuito fijo cada 20 minutos entre las paradas de por puesto de la avenida, el Rectorado y los bloques, de 6:30 a. m. a 9 p. m.",
			 "costo": 26, "puntos": 0.60, "contraproducente": false, "aceptacion": "alta", "sinergia": "",
			 "explicacion": "Conecta el campus con el transporte público que la gente ya usa y cubre los tres turnos: es el tipo de servicio que valora TR2. Con frecuencia fija la gente puede contar con él."},
			{"id": "park_and_ride", "corto": "Estacionamiento externo + busetas",
			 "texto": "Alquilar un estacionamiento en un centro comercial cercano y traer a la gente desde ahí en tres busetas",
			 "costo": 34, "puntos": 0.40, "contraproducente": false, "aceptacion": "media", "sinergia": "",
			 "explicacion": "Saca carros del campus y cuenta como transporte interno (TR2), pero cada persona sigue llegando en carro hasta el centro comercial, y es la opción más cara: el alquiler se paga todos los meses."},
		],
	},
	{
		"id": "tr_dia_sin_carros", "tipo": "decision", "lugar": "porton_vehicular", "indicador": "TR7",
		"titulo": "Día sin carros",
		"contexto": "Varias universidades del ranking cierran su portón vehicular un día al mes. En URBE la idea genera dudas: ¿cómo llega quien vive lejos? El portón de la avenida es el único acceso de carros. Una jornada así cuenta como iniciativa para disminuir los vehículos privados (TR7).",
		"pregunta": "¿Cómo lo organizas?",
		"opciones": [
			{"id": "cierre_semanal", "corto": "Viernes sin carros",
			 "texto": "Cerrar el portón a los carros particulares todos los viernes desde el mes que viene, con busetas de refuerzo contratadas",
			 "costo": 28, "puntos": 0.40, "contraproducente": false, "aceptacion": "baja", "sinergia": "",
			 "explicacion": "En papel saca más carros, pero cada viernes sin alternativas suficientes baja la asistencia y la comunidad presiona para eliminarlo. Una iniciativa que no se sostiene suma menos en TR7 que una mensual bien hecha."},
			{"id": "jornada_mensual_con_feria", "corto": "Jornada mensual con feria",
			 "texto": "Un miércoles al mes con el portón cerrado a carros particulares, busetas de refuerzo y una feria de movilidad con charlas y taller de mecánica de bicis",
			 "costo": 10, "puntos": 0.60, "contraproducente": false, "aceptacion": "media", "sinergia": "dia_sin_carros_feria",
			 "explicacion": "Es periódica, medible (se cuentan los carros que no entraron) y viene con alternativas. La feria y las charlas la convierten en un evento de sostenibilidad, que también suma en Educación."},
			{"id": "motos_por_la_acera", "corto": "Motos por la acera",
			 "texto": "Hacer el día sin carros pero dejar pasar motos y permitir estacionarlas en las aceras cerca de los bloques",
			 "costo": 4, "puntos": 0.0, "contraproducente": true, "aceptacion": "", "sinergia": "",
			 "explicacion": "Los vehículos solo cambian de tipo: las motos también cuentan en TR1, y estacionarlas en las aceras quita espacio a los peatones (TR8, senderos peatonales)."},
		],
	},
	{
		"id": "tr_flota", "tipo": "decision", "lugar": "zona_mantenimiento", "indicador": "TR3 · TR4",
		"titulo": "Flota de mantenimiento",
		"contexto": "La cuadrilla de mantenimiento recorre el campus en dos carritos a gasolina con más de diez años que fallan seguido. GreenMetric evalúa si hay vehículos de cero emisiones en el campus, eléctricos o de pedal (TR3), y cuántos hay por persona (TR4).",
		"pregunta": "¿Qué haces con la flota?",
		"opciones": [
			{"id": "triciclos_de_carga", "corto": "Triciclos de carga",
			 "texto": "Comprar tres triciclos de carga a pedal para los trabajos cortos y dejar un solo carrito a gasolina",
			 "costo": 8, "puntos": 0.40, "contraproducente": false, "aceptacion": "media", "sinergia": "",
			 "explicacion": "Los triciclos son vehículos de cero emisiones (TR3), baratos y sin combustible, pero con el calor y las distancias largas la cuadrilla sigue usando el carrito a gasolina para casi todo."},
			{"id": "camioneta_diesel", "corto": "Camioneta diésel",
			 "texto": "Reemplazar los dos carritos por una camioneta diésel más grande para hacer todo en un solo viaje",
			 "costo": 20, "puntos": 0.0, "contraproducente": true, "aceptacion": "", "sinergia": "",
			 "explicacion": "Ningún vehículo de cero emisiones (TR3 y TR4 quedan en nada) y un motor diésel que emite más por kilómetro. Resuelve la logística a costa del indicador."},
			{"id": "carritos_electricos", "corto": "Carritos eléctricos",
			 "texto": "Cambiar los dos carritos por carritos eléctricos que se cargan con el techo solar del estacionamiento",
			 "costo": 18, "puntos": 0.60, "contraproducente": false, "aceptacion": "alta", "sinergia": "flota_electrica",
			 "explicacion": "Dos vehículos de cero emisiones nuevos (TR3 y TR4) que además usan energía producida en el campus: menos combustible y menos emisiones. Por eso suma también en Energía."},
		],
	},
	{
		"id": "tr_bici_bloque_e", "tipo": "bicicletero", "lugar": "bicicletero_bloque_e", "indicador": "TR7",
		"titulo": "Bicicletero del Bloque E",
		"contexto": "Entre el Bloque E y el Rectorado pasan cientos de estudiantes, pero no hay dónde dejar una bicicleta segura: quien viene en bici la amarra a una baranda. Un bicicletero forma parte de las iniciativas para disminuir los vehículos privados (TR7).",
		"pregunta": "¿Qué tipo de bicicletero instalas con el kit?",
		"opciones": [
			{"id": "simple_con_candado", "corto": "Simple, sin techo",
			 "texto": "Estructura simple de tubos en U, sin techo, junto a un poste de luz existente",
			 "costo": 2, "puntos": 0.10, "contraproducente": false, "aceptacion": "media", "sinergia": "",
			 "explicacion": "Cumple y es barato, pero sin sombra, con el sol de Maracaibo, se usa menos: un bicicletero vacío no reduce carros."},
			{"id": "techado_con_panel", "corto": "Techado con panel solar",
			 "texto": "Techado, con un panel solar pequeño que alimenta la luz LED nocturna",
			 "costo": 5, "puntos": 0.20, "contraproducente": false, "aceptacion": "alta", "sinergia": "bicicletero_techado_solar",
			 "explicacion": "Sombra y luz hacen que la gente lo use de verdad (la seguridad percibida decide si alguien viene en bici) y la luz no consume de la red. Suma a TR7 y a Energía."},
			{"id": "sobre_el_sendero", "corto": "Ganchos en el sendero",
			 "texto": "Colgar ganchos en la baranda del pasillo techado peatonal, sin estructura nueva",
			 "costo": 1, "puntos": 0.0, "contraproducente": true, "aceptacion": "", "sinergia": "",
			 "explicacion": "Las bicis ocupan el sendero peatonal techado (TR8) y quedan mal aseguradas: peatones y ciclistas terminan compitiendo por el mismo espacio."},
		],
	},
	{
		"id": "tr_bici_cafetin", "tipo": "bicicletero", "lugar": "bicicletero_cafetin", "indicador": "TR7",
		"titulo": "Bicicletero del Cafetín",
		"contexto": "Al borde del M5, camino al Cafetín, llegan estudiantes y personal desde las urbanizaciones cercanas. Con el sol de la tarde, una bicicleta dejada a la intemperie se recalienta y el asiento se daña. Un bicicletero forma parte de las iniciativas para disminuir los vehículos privados (TR7).",
		"pregunta": "¿Qué tipo de bicicletero instalas con el kit?",
		"opciones": [
			{"id": "sobre_el_sendero", "corto": "Ganchos en el sendero",
			 "texto": "Colgar ganchos en la baranda del pasillo techado peatonal, sin estructura nueva",
			 "costo": 1, "puntos": 0.0, "contraproducente": true, "aceptacion": "", "sinergia": "",
			 "explicacion": "Las bicis ocupan el sendero peatonal techado (TR8) y quedan mal aseguradas: peatones y ciclistas terminan compitiendo por el mismo espacio."},
			{"id": "simple_con_candado", "corto": "Simple, sin techo",
			 "texto": "Estructura simple de tubos en U, sin techo, junto a un poste de luz existente",
			 "costo": 2, "puntos": 0.10, "contraproducente": false, "aceptacion": "media", "sinergia": "",
			 "explicacion": "Cumple y es barato, pero sin sombra, con el sol de Maracaibo, se usa menos: un bicicletero vacío no reduce carros."},
			{"id": "techado_con_panel", "corto": "Techado con panel solar",
			 "texto": "Techado, con un panel solar pequeño que alimenta la luz LED nocturna",
			 "costo": 5, "puntos": 0.20, "contraproducente": false, "aceptacion": "alta", "sinergia": "bicicletero_techado_solar",
			 "explicacion": "Sombra y luz hacen que la gente lo use de verdad (la seguridad percibida decide si alguien viene en bici) y la luz no consume de la red. Suma a TR7 y a Energía."},
		],
	},
]

# Una objeción por opción válida, clave "decision:opcion" (spec §7.3).
# Orden de los argumentos = orden en pantalla.
const OBJECIONES : Dictionary = {
	"tr_permisos:permiso_por_necesidad": {
		"texto": "Consejera de Egresados: «Van a quitarle el permiso anual a cientos de personas. Va a haber quejas y hasta retiros.»",
		"argumentos": [
			{"texto": "GreenMetric lo exige, así que no hay nada que discutir.", "correcto": false,
			 "explicacion": "GreenMetric no obliga a nada: es un ranking voluntario. Imponer sin explicar es justo lo que genera rechazo."},
			{"texto": "Nadie pierde el acceso: sigue el pase diario, y la buseta y el carpool del plan dan alternativas a quien deja de tener permiso anual.", "correcto": true,
			 "explicacion": "Una restricción se defiende mostrando las alternativas que la acompañan."},
			{"texto": "Si hay muchas quejas, se vuelve a dar permiso a todos.", "correcto": false,
			 "explicacion": "Deshacer la medida al primer reclamo borra la reducción de vehículos (TR1) y la credibilidad del plan."},
		],
	},
	"tr_permisos:lectoras_de_placas": {
		"texto": "Director de Finanzas: «24 puntos del presupuesto en cámaras… ¿cuántos carros menos entran con eso?»",
		"argumentos": [
			{"texto": "Ninguno por sí solo: el valor está en medir. Con los datos de las placas se fija una meta de reducción y se comprueba si se cumple (TR1).", "correcto": true,
			 "explicacion": "Reconocer el límite y mostrar para qué sirve el dato es un argumento honesto y verificable."},
			{"texto": "Muchos: al entrar más rápido, la gente se anima a no traer el carro.", "correcto": false,
			 "explicacion": "Una entrada más rápida hace más cómodo venir en carro, no menos."},
			{"texto": "Las cámaras dan seguridad, y eso es lo que mide GreenMetric en Transporte.", "correcto": false,
			 "explicacion": "La seguridad importa, pero TR1 mide vehículos por persona, no vigilancia."},
		],
	},
	"tr_lote:ciclovia_arborizada": {
		"texto": "Jefe de Servicios Generales: «¿Y quién riega esos árboles y mantiene la ciclovía? Eso cuesta todos los años.»",
		"argumentos": [
			{"texto": "Los árboles no necesitan mantenimiento.", "correcto": false,
			 "explicacion": "Todo árbol recién plantado necesita riego y cuidado al principio."},
			{"texto": "Si sale caro, se vuelve a abrir el lote para carros.", "correcto": false,
			 "explicacion": "Reabrirlo borra la reducción de área de estacionamiento que suma en TR5 y TR6."},
			{"texto": "Con especies nativas adaptadas al clima de Maracaibo, que después del primer año necesitan poco riego; el mantenimiento entra en la rutina de jardinería que ya existe.", "correcto": true,
			 "explicacion": "Anticipar el costo con una elección técnica responde la objeción."},
		],
	},
	"tr_lote:plaza_de_eventos": {
		"texto": "Coordinadora de Eventos: «El día de la feria la gente va a estacionar ahí igual. ¿Entonces qué redujimos?»",
		"argumentos": [
			{"texto": "Nada, pero queda un espacio bonito para el campus.", "correcto": false,
			 "explicacion": "Si no reduce estacionamiento, no suma en TR5 ni en TR6: el plan pierde su argumento principal."},
			{"texto": "Se ponen bolardos y una regla escrita: el lote no se usa como estacionamiento ni en eventos, y los visitantes llegan en buseta.", "correcto": true,
			 "explicacion": "Un programa de reducción (TR6) necesita reglas que se cumplan también los días especiales."},
			{"texto": "Es solo unas veces al año, no afecta el indicador.", "correcto": false,
			 "explicacion": "Si se permite en cada evento, el área sigue funcionando como estacionamiento y el programa pierde credibilidad."},
		],
	},
	"tr_carpool:puestos_3_ocupantes": {
		"texto": "Representante estudiantil: «Muchos vivimos en zonas donde nadie más viene a URBE. Nos quitan los buenos puestos.»",
		"argumentos": [
			{"texto": "Que se muden más cerca.", "correcto": false,
			 "explicacion": "Una respuesta que desprecia la situación real de la gente hunde la aceptación del plan."},
			{"texto": "Los puestos reservados son pocos, así que en realidad no cambia nada.", "correcto": false,
			 "explicacion": "Si no cambia nada, tampoco reduce carros: el argumento contradice el objetivo."},
			{"texto": "Quien llega solo conserva su puesto en el resto del M5; solo se reservan los más cercanos hasta las 9, y el grupo por urbanización ayuda a encontrar con quién venir.", "correcto": true,
			 "explicacion": "Mostrar que la medida es acotada y que ofrece cómo cumplirla responde la queja."},
		],
	},
	"tr_carpool:app_carpool": {
		"texto": "Director de Finanzas: «La aplicación se paga todos los años. ¿Qué pasa si nadie la usa?»",
		"argumentos": [
			{"texto": "Se va a usar sí o sí, porque es moderna.", "correcto": false,
			 "explicacion": "Que algo sea moderno no garantiza que cambie hábitos."},
			{"texto": "Cada semestre se mide cuántos viajes compartidos registra; si no llega a una meta mínima, ese dinero pasa a puestos preferenciales para carros con 3 o más personas.", "correcto": true,
			 "explicacion": "Una iniciativa con meta y plan B es defendible."},
			{"texto": "Es gratis para los estudiantes, así que no importa.", "correcto": false,
			 "explicacion": "Que sea gratis para quien la usa no cambia que la universidad la paga."},
		],
	},
	"tr_shuttle:ruta_a_paradas": {
		"texto": "Director de Finanzas: «Dos busetas de 6:30 de la mañana a 9 de la noche: chofer, gasoil, repuestos. ¿Lo podemos sostener?»",
		"argumentos": [
			{"texto": "Las busetas se pagan solas porque la gente las va a usar.", "correcto": false,
			 "explicacion": "El pasaje interno no existe o es simbólico: el servicio siempre tiene un costo que hay que financiar."},
			{"texto": "Se puede quitar el turno de la noche, que tiene pocos estudiantes.", "correcto": false,
			 "explicacion": "Dejar sin transporte al turno nocturno, el que más lo necesita por seguridad, rompe la cobertura que valora TR2."},
			{"texto": "Se ajusta la frecuencia con conteos de pasajeros por turno y se financia en parte con el cobro de estacionamiento a visitantes.", "correcto": true,
			 "explicacion": "Datos de uso y una fuente de financiamiento concreta hacen sostenible el servicio."},
		],
	},
	"tr_shuttle:park_and_ride": {
		"texto": "Consejero académico: «Igual le pedimos a la gente que maneje hasta el centro comercial. ¿Eso es sostenible?»",
		"argumentos": [
			{"texto": "Es un paso intermedio: reduce los carros dentro del campus y el estacionamiento que necesitamos; después la ruta puede extenderse a las paradas de transporte público.", "correcto": true,
			 "explicacion": "Reconocer el límite y mostrar el camino siguiente es un argumento sólido."},
			{"texto": "Sí, porque el centro comercial queda cerca.", "correcto": false,
			 "explicacion": "La cercanía no elimina el viaje en carro."},
			{"texto": "El indicador solo cuenta los carros dentro del campus; lo de afuera no importa.", "correcto": false,
			 "explicacion": "Es cierto que TR1 cuenta vehículos del campus, pero defender el plan ignorando las emisiones de afuera lo debilita ante el Consejo."},
		],
	},
	"tr_dia_sin_carros:jornada_mensual_con_feria": {
		"texto": "Decano: «Un miércoles con el portón cerrado: los profesores que vienen de lejos van a faltar a clases.»",
		"argumentos": [
			{"texto": "Ese día se pueden suspender las clases.", "correcto": false,
			 "explicacion": "Suspender clases convierte la iniciativa en un feriado: no enseña a llegar de otra forma."},
			{"texto": "Se anuncia con el calendario del semestre, hay busetas de refuerzo desde las paradas y quien tiene movilidad reducida conserva el acceso.", "correcto": true,
			 "explicacion": "Anticipación, alternativas y excepciones justas responden la preocupación."},
			{"texto": "Que falten: es solo un día al mes.", "correcto": false,
			 "explicacion": "Minimizar el problema no lo resuelve y baja la aceptación del plan."},
		],
	},
	"tr_dia_sin_carros:cierre_semanal": {
		"texto": "Representante estudiantil: «Todos los viernes sin carros, desde el mes que viene. Va a bajar la asistencia.»",
		"argumentos": [
			{"texto": "Quien no venga es porque no le importa el ambiente.", "correcto": false,
			 "explicacion": "Culpar a la comunidad no resuelve cómo llega quien vive lejos."},
			{"texto": "Con las busetas contratadas alcanza para todos.", "correcto": false,
			 "explicacion": "Afirmarlo sin conteos de demanda no convence."},
			{"texto": "Se empieza con una jornada mensual bien organizada y la frecuencia sube solo si los conteos muestran que las alternativas alcanzan.", "correcto": true,
			 "explicacion": "Reconocer el riesgo y proponer una implementación gradual con datos es el mejor argumento."},
		],
	},
	"tr_flota:carritos_electricos": {
		"texto": "Jefe de Mantenimiento: «¿Y si se acaba la batería a mitad de un trabajo? Los viejos al menos se llenan de gasolina.»",
		"argumentos": [
			{"texto": "Las rutas de trabajo se planifican según la autonomía y los carritos se cargan de noche o al mediodía con el techo solar; los trayectos dentro del campus son cortos.", "correcto": true,
			 "explicacion": "Planificar la operación responde el riesgo real."},
			{"texto": "Los carritos eléctricos nunca se descargan.", "correcto": false,
			 "explicacion": "Todo vehículo eléctrico tiene una autonomía limitada."},
			{"texto": "Si fallan, se vuelven a comprar carritos a gasolina.", "correcto": false,
			 "explicacion": "Volver atrás al primer problema anula el cambio que suma en TR3 y TR4."},
		],
	},
	"tr_flota:triciclos_de_carga": {
		"texto": "Jefe de Mantenimiento: «Con este calor nadie va a pedalear un triciclo cargado desde el M5 hasta el Rectorado.»",
		"argumentos": [
			{"texto": "Es buen ejercicio para la cuadrilla.", "correcto": false,
			 "explicacion": "Ignora las condiciones de trabajo: sin una organización realista, los triciclos quedan guardados."},
			{"texto": "Los triciclos se asignan a los trabajos cortos por zona y el carrito a gasolina queda solo para cargas pesadas, con registro de uso.", "correcto": true,
			 "explicacion": "Organizar el uso real es lo que hace que un vehículo de cero emisiones reduzca emisiones."},
			{"texto": "Aunque no se usen, igual cuentan como vehículos de cero emisiones.", "correcto": false,
			 "explicacion": "Tenerlos guardados cuenta en papel, pero no reduce emisiones; el Consejo pregunta por el efecto real."},
		],
	},
	"tr_bici_bloque_e:techado_con_panel": {
		"texto": "Jefe de Seguridad: «Un panel solar en un bicicletero, a la vista de todos. ¿No se lo van a robar?»",
		"argumentos": [
			{"texto": "En URBE nadie roba.", "correcto": false,
			 "explicacion": "Negar el riesgo no convence a quien tiene que cuidar el campus."},
			{"texto": "El panel va fijo sobre el techo con tornillería antirrobo, a la vista de la vigilancia y con la luz encendida toda la noche, que también protege las bicis.", "correcto": true,
			 "explicacion": "Prevención concreta responde la objeción."},
			{"texto": "Si se lo roban, se pone otro.", "correcto": false,
			 "explicacion": "Reponer sin prevenir multiplica el costo."},
		],
	},
	"tr_bici_bloque_e:simple_con_candado": {
		"texto": "Representante estudiantil: «Sin techo, a las dos de la tarde el asiento quema. ¿Quién lo va a usar?»",
		"argumentos": [
			{"texto": "Se ubica bajo la sombra de los árboles del corredor y al final del semestre se revisa cuánto se usa para decidir si se techa.", "correcto": true,
			 "explicacion": "Una mejora barata con evaluación posterior es defendible."},
			{"texto": "Cada uno puede traer una toalla para el asiento.", "correcto": false,
			 "explicacion": "Trasladar el problema al usuario reduce el uso del bicicletero."},
			{"texto": "Lo importante es tenerlo, aunque no se use.", "correcto": false,
			 "explicacion": "Un bicicletero vacío no reduce ningún carro."},
		],
	},
	"tr_bici_cafetin:techado_con_panel": {
		"texto": "Director de Finanzas: «¿Por qué pagar un panel solar para una sola luz?»",
		"argumentos": [
			{"texto": "Porque los paneles solares siempre son más baratos que cualquier otra cosa.", "correcto": false,
			 "explicacion": "No siempre: depende de la instalación; el argumento es falso como regla general."},
			{"texto": "Porque se ve moderno.", "correcto": false,
			 "explicacion": "La imagen no justifica un gasto ante el Consejo."},
			{"texto": "Porque evita cablear desde el edificio: el panel pequeño cuesta menos que la obra eléctrica y la luz no consume de la red.", "correcto": true,
			 "explicacion": "Comparar con la alternativa real (cablear) justifica el costo."},
		],
	},
	"tr_bici_cafetin:simple_con_candado": {
		"texto": "Jefe de Seguridad: «Sin luz ni techo, de noche esto es un bicicletero para ladrones.»",
		"argumentos": [
			{"texto": "De noche casi no hay estudiantes.", "correcto": false,
			 "explicacion": "El turno nocturno existe y es el que más necesita seguridad."},
			{"texto": "Queda junto al poste de luz existente y dentro del recorrido de vigilancia del estacionamiento, y la campaña de movilidad recomienda candado en U.", "correcto": true,
			 "explicacion": "Aprovechar la luz y la vigilancia existentes responde el riesgo sin costo extra."},
			{"texto": "Cada uno es responsable de su bicicleta.", "correcto": false,
			 "explicacion": "Si la gente no se siente segura, no viene en bici y el bicicletero no cumple su función."},
		],
	},
}


static func decision(id: String) -> Dictionary:
	for d in DECISIONES:
		if d["id"] == id:
			return d
	return {}


# Título legible de cualquier misión del Nivel 5, incluida tr_consejo (que no
# está en DECISIONES). Usado por SceneMapaMundo para el aviso de misión
# completada — antes mostraba el id crudo ("Tr Permisos", "Tr Consejo").
static func titulo(mision_id: String) -> String:
	if mision_id == DECISION_CONSEJO:
		return "Consejo Universitario"
	return str(decision(mision_id).get("titulo", ""))


static func opcion(decision_id: String, opcion_id: String) -> Dictionary:
	for o in decision(decision_id).get("opciones", []):
		if o["id"] == opcion_id:
			return o
	return {}


static func ids_decisiones() -> Array:
	var ids := []
	for d in DECISIONES:
		ids.append(d["id"])
	return ids


# Opción válida con más puntos (sin empates en los datos).
static func mejor_opcion(decision_id: String) -> String:
	var mejor := ""
	var max_puntos := -1.0
	for o in decision(decision_id).get("opciones", []):
		if not o["contraproducente"] and float(o["puntos"]) > max_puntos:
			max_puntos = float(o["puntos"])
			mejor = o["id"]
	return mejor


static func objecion(decision_id: String, opcion_id: String) -> Dictionary:
	return OBJECIONES.get("%s:%s" % [decision_id, opcion_id], {})


static func calificacion(aciertos: int) -> Dictionary:
	var a := clampi(aciertos, 0, 3)
	for c in CONSEJO_OPCIONES:
		if int(c["aciertos"]) == a:
			return c
	return {}


static func texto_sinergia(accion_id: String) -> String:
	var s : Dictionary = SINERGIAS.get(accion_id, {})
	if s.is_empty():
		return ""
	return "✨ Sinergia: %s (se suma cuando el Consejo aprueba el plan)" % s["efecto"]
