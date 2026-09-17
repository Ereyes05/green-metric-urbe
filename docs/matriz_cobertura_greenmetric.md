# Matriz de cobertura UI GreenMetric 2024 — GreenMetric URBE

Fuente: UI GreenMetric Guideline 2024, Table 3 (51 indicadores).
Criterio (decisión D9 del diseño 2026-09-14): los 51 indicadores se aprenden
(quiz o ficha); los que un estudiante puede ver o influir en el campus se juegan.

Convenciones de esta matriz:
- **Tratamiento** ∈ `misión`, `minijuego`, `decisión`, `quiz`, `ficha` (regla D9: ninguna fila queda vacía).
- **Nivel** = nivel del juego que corresponde a la categoría (1 Entorno, 2 Energía,
  3 Residuos, 4 Agua, 5 Transporte, 6 Educación), igual a `NivelManager.NOMBRES_NIVEL`.
- **Cubierto hoy por** cita IDs reales del código actual (rama `nivel-6-educacion-investigacion`);
  `—` significa que hoy no hay contenido jugable ni pregunta de quiz para ese indicador.
- **Propuesto** es lo que falta para que el indicador tenga tratamiento completo
  (pregunta nueva de quiz, ficha informativa, o el minijuego/decisión de los
  proyectos B/C del diseño 2026-09-14).
- **Cruces** son las sinergias entre categorías descritas en la sección 7/8 del
  diseño (`catalogo_sinergias`); `—` si el indicador no tiene cruce definido.
- **Accionable** = si un estudiante puede influir el indicador jugando: `sí`, `parcial`
  (lo hace indirectamente, vía un cruce o un dato sujeto a decisión ajena) o `no`
  (indicador puramente institucional: presupuesto, política, investigación...).

## Resumen por categoría

| Categoría | Peso | Indicadores | Cubiertos hoy | Minijuego/misión nuevos | Solo quiz/ficha |
|---|---|---|---|---|---|
| 1. Entorno e Infraestructura (SI) | 15% | 11 | 1 | 3 | 7 |
| 2. Energía y Cambio Climático (EC) | 21% | 10 | 2 | 2 | 6 |
| 3. Manejo de Residuos (WS) | 18% | 6 | 3 | 1 | 2 |
| 4. Uso del Agua (WR) | 10% | 5 | 1 | 1 | 3 |
| 5. Transporte Sostenible (TR) | 18% | 8 | 8 | 0 | 1 |
| 6. Educación e Investigación (ED) | 18% | 11 | 6 | 0 | 7 |
| **Total** | **100%** | **51** | **21** | **7** | **26** |

> "Cubiertos hoy" cuenta indicadores con al menos un ID real citado en "Cubierto
> hoy por" (incluye coberturas parciales). "Minijuego/misión nuevos" cuenta solo
> los 7 minijuegos de la decisión D10 — las 7 nuevas decisiones de Transporte del
> proyecto B (sección 7 del diseño) no se cuentan aquí porque su tratamiento es
> `decisión`, no `minijuego`/`misión`. Las tres columnas no suman "Indicadores":
> son conteos independientes sobre el mismo conjunto de 11/10/6/5/8/11 filas.

## 1. Entorno e Infraestructura (SI) — 15%

| Código | Indicador | Puntos | Tratamiento | Nivel | Cubierto hoy por | Propuesto | Cruces | Accionable |
|---|---|---|---|---|---|---|---|---|
| SI1 | Proporción de área abierta sobre el área total | 200 | quiz | 1 | — | pregunta nueva en quiz de Entorno | — | parcial |
| SI2 | Área total del campus cubierta por vegetación boscosa | 100 | quiz | 1 | — | pregunta nueva en quiz de Entorno | — | no |
| SI3 | Área total del campus cubierta por vegetación plantada | 200 | misión | 1 | `plantar_rectorado`, `plantar_patio`, `plantar_este`, `plantar_corredores`, `plantar_norte`, `plantar_oeste` (`mision_plantar.gd`, vía `DATOS_ZONAS_TIERRA`) | ya cubierto (ver anomalía de `plantar_sur`/`plantar_cafetín` sin usar) | — | sí |
| SI4 | Área total del campus para absorción de agua además de la vegetación boscosa y plantada | 100 | quiz | 1 | — | pregunta nueva en quiz de Entorno | — | no |
| SI5 | Área de espacio abierto total dividida entre la población total del campus | 200 | quiz | 1 | — | pregunta nueva en quiz de Entorno | — | no |
| SI6 | Porcentaje del presupuesto universitario destinado a esfuerzos de sostenibilidad | 200 | ficha | 1 | — | ficha informativa (indicador institucional) | — | no |
| SI7 | Porcentaje de actividades de operación y mantenimiento de edificios en un período de un año | 100 | minijuego | 1 | — | **Órdenes de trabajo** (Bloque D) — proyecto C, D10 | AC atendido → Energía (EC); filtración reparada → Agua (WR) | sí |
| SI8 | Instalaciones del campus para personas con discapacidad, necesidades especiales y/o cuidado maternal | 100 | ficha | 1 | — | ficha informativa | — | no |
| SI9 | Instalaciones de seguridad y protección | 100 | ficha | 1 | — | ficha informativa | — | no |
| SI10 | Infraestructura de salud para el bienestar de estudiantes, académicos y personal administrativo | 100 | minijuego | 1 | — | **Campus saludable** (Área de salud, junto al Rectorado) — proyecto C, D10 | bebederos → Agua (WR4); sombra con árboles → Entorno (SI) | sí |
| SI11 | Conservación de recursos genéticos de flora, fauna o vida silvestre para alimentación y agricultura, resguardados en instalaciones de conservación de mediano o largo plazo | 100 | minijuego | 1 | — | **Censo del Lago URBE** (Lago) — proyecto C, D10 | especies nativas del vivero → Agua (WR) | sí |

## 2. Energía y Cambio Climático (EC) — 21%

| Código | Indicador | Puntos | Tratamiento | Nivel | Cubierto hoy por | Propuesto | Cruces | Accionable |
|---|---|---|---|---|---|---|---|---|
| EC1 | Uso de electrodomésticos de bajo consumo energético | 200 | misión | 2 | `led_bloque_a`…`led_bloque_f` (`interior_bloque.gd`, vía `punto_critico_energia.gd`/`DATOS_PUNTOS_ENERGIA`) | ya cubierto | — | sí |
| EC2 | Implementación de edificios inteligentes | 300 | minijuego | 2 | — | **Sala de control del Bloque E** — proyecto C, D10 | kWh ahorrados reducen la huella de carbono (minijuego EC8) | sí |
| EC3 | Número de fuentes de energía renovable en el campus | 300 | misión | 2 | `solar_rectorado`, `solar_estacionamiento` (`mision_solar.gd`, vía `DATOS_PUNTOS_ENERGIA`) | ya cubierto | — | sí |
| EC4 | Consumo total de electricidad dividido entre la población total del campus (kWh por persona) | 300 | ficha | 2 | — | ficha informativa (indicador institucional) | — | no |
| EC5 | Proporción de producción de energía renovable dividida entre el consumo total de energía al año | 200 | ficha | 2 | — | ficha informativa (indicador institucional) | — | no |
| EC6 | Elementos de construcción sostenible reflejados en todas las políticas de construcción y renovación | 200 | ficha | 2 | — | ficha informativa | — | no |
| EC7 | Programa de reducción de emisiones de gases de efecto invernadero | 200 | quiz | 2 | — | pregunta nueva en quiz de Energía (cruce narrativo con el minijuego de Inventario de emisiones, EC8) | — | parcial |
| EC8 | Huella de carbono total dividida entre la población total del campus (toneladas métricas por persona) | 200 | minijuego | 2 | — | **Inventario de emisiones** (Rectorado) — proyecto C, D10; lee resultados de LED, Plan de Movilidad y reciclaje | centro de cruces: recibe de EC1/EC3 (LED, solares), TR (Plan de Movilidad) y WS (reciclaje) | sí |
| EC9 | Número de programas innovadores en energía y cambio climático | 100 | ficha | 2 | — | ficha informativa | — | no |
| EC10 | Programas universitarios de alto impacto sobre el cambio climático | 100 | ficha | 2 | — | ficha informativa | — | no |

## 3. Manejo de Residuos (WS) — 18%

| Código | Indicador | Puntos | Tratamiento | Nivel | Cubierto hoy por | Propuesto | Cruces | Accionable |
|---|---|---|---|---|---|---|---|---|
| WS1 | Programa 3R (Reducir, Reutilizar, Reciclar) para los residuos de la universidad | 300 | misión | 3 | `reciclar_corredor_n`, `reciclar_patio_e`, `reciclar_bloque_e`, `reciclar_oeste`, `reciclar_sur`, `reciclar_este` (`zona_reciclaje.gd`, vía `DATOS_ZONAS_RECICLAJE`); refuerzo en `minijuego_residuos.gd` | ya cubierto | — | sí |
| WS2 | Programa para reducir el uso de papel y plástico en el campus | 300 | quiz | 3 | `mision_fotocopiado` (quiz, `QUIZ_POR_MISION`; nota: la zona `ZonaFotocopiado` está codificada como `modulo_id: 1`/Entorno aunque el tema es Residuos — ver Anomalías) | ya cubierto | — | sí |
| WS3 | Tratamiento de residuos orgánicos | 300 | minijuego | 3 | — | **Compostera del Cafetín** (equilibrar verdes/marrones, humedad, volteo) — proyecto C, D10 | abono producido va a los árboles del Nivel 1 → Entorno (SI) | sí |
| WS4 | Tratamiento de residuos inorgánicos | 300 | misión | 3 | `minijuego_residuos.gd` (clasificar 10 residuos, incluye reciclables inorgánicos como botellas PET); mismas zonas de `zona_reciclaje.gd` que WS1 | ya cubierto† | — | sí |
| WS5 | Tratamiento de residuos tóxicos | 300 | ficha | 3 | — | ficha informativa | — | no |
| WS6 | Disposición de aguas residuales (alcantarillado) | 300 | quiz | 3 | — | pregunta nueva en quiz de Residuos | — | no |

> † WS4 se clasifica como `misión` y no como `minijuego` aunque el contenido
> que la cubre hoy (`minijuego_residuos.gd`) es, en el código, un minijuego
> real y jugable: la decisión D10 del diseño 2026-09-14 reserva la etiqueta
> `minijuego` únicamente para los 7 juegos nuevos que introduce (SI7, SI10,
> SI11, EC2, EC8, WS3, WR2), así que esta fila no puede usar ese valor sin
> romper esa cuenta. `minijuego_residuos.gd` sigue siendo el mismo objeto que
> además alimenta la Comprensión de Residuos (proyecto A, sección 6.1 del
> diseño: "Residuos: su Comprensión sale del minijuego de clasificación —
> aciertos del primer intento / ítems — hasta que tenga quiz propio").

## 4. Uso del Agua (WR) — 10%

| Código | Indicador | Puntos | Tratamiento | Nivel | Cubierto hoy por | Propuesto | Cruces | Accionable |
|---|---|---|---|---|---|---|---|---|
| WR1 | Programa e implementaciones de conservación del agua | 200* | misión | 4 | `llave_bloque_c`, `llave_bloque_a`, `llave_corredor_n`, `llave_patio_e`, `llave_este`, `llave_bloque_b` (`llave_agua.gd`, vía `DATOS_LLAVES_AGUA`); `captacion_biblioteca`, `captacion_bloque_c` (`mision_captacion.gd`); refuerzo en quiz `mision_agua` | ya cubierto | — | sí |
| WR2 | Implementación de programa de reciclaje de agua | 200 | minijuego | 4 | — | **Circuito de aguas grises** (rompecabezas de tuberías: lavamanos → filtro → tanque → riego/inodoros, Patio) — proyecto C, D10 | riego con agua reciclada → Agua (WR) + Entorno (SI) | sí |
| WR3 | Uso de artefactos eficientes en el consumo de agua | 200 | quiz | 4 | — | pregunta nueva en quiz de Agua | — | no |
| WR4 | Consumo de agua tratada | 200 | quiz | 4 | — | pregunta nueva en quiz de Agua | recibe cruce del minijuego SI10 (Campus saludable): bebederos → Agua (WR4) | parcial |
| WR5 | Control de la contaminación del agua en el área del campus | 200 | quiz | 4 | — | pregunta nueva en quiz de Agua | — | no |

> \* El punto asignado a WR1 aparece como "200*" en la Table 3 de la guía 2024
> (líneas 255–356 de la fuente extraída); el texto extraído no incluye la nota
> al pie que explica el asterisco. Se preserva el valor y el símbolo tal como
> figuran en la fuente.

## 5. Transporte Sostenible (TR) — 18%

| Código | Indicador | Puntos | Tratamiento | Nivel | Cubierto hoy por | Propuesto | Cruces | Accionable |
|---|---|---|---|---|---|---|---|---|
| TR1 | Número total de vehículos (carros y motos) dividido entre la población total del campus | 200 | decisión | 5 | `tr_permisos` (Plan de Movilidad, garita del M5: permisos por necesidad · lectoras de placas · más puestos, contraproducente) | — (proyecto B implementado) | — | sí |
| TR2 | Servicios de transporte interno (shuttle) | 300 | decisión | 5 | `tr_shuttle` (parada de la Av. URBE: busetas a las paradas · estacionamiento externo · bono de gasolina, contraproducente) | — (proyecto B implementado) | — | sí |
| TR3 | Disponibilidad de Vehículos de Cero Emisiones (ZEV) en el campus | 200 | decisión | 5 | `tr_flota` (patio de mantenimiento: carritos eléctricos · triciclos de carga · camioneta diésel, contraproducente) | — (proyecto B implementado) | flota eléctrica → Energía (`flota_electrica`) | sí |
| TR4 | Número total de Vehículos de Cero Emisiones (ZEV) dividido entre la población total del campus | 200 | decisión | 5 | `tr_flota` (mismo escenario que TR3) | — (proyecto B implementado) | flota eléctrica → Energía (`flota_electrica`) | sí |
| TR5 | Proporción del área de estacionamiento en superficie sobre el área total del campus | 200 | decisión | 5 | `tr_lote` (lote detrás de Estudios a Distancia: ciclovía con árboles · explanada de eventos · asfaltar, contraproducente) | — (proyecto B implementado) | ciclovía → Entorno (`ciclovia_lote`) | sí |
| TR6 | Programa para limitar o disminuir el área de estacionamiento en el campus en los últimos 3 años (2021-2023) | 200 | decisión | 5 | `tr_lote` | — (proyecto B implementado) | ciclovía → Entorno (`ciclovia_lote`) | sí |
| TR7 | Número de iniciativas para disminuir los vehículos privados en el campus | 200 | decisión | 5 | `tr_carpool`, `tr_dia_sin_carros`, `tr_bici_bloque_e`, `tr_bici_cafetin` (bicicleteros con kit y decisión de tipo); objeciones del Consejo en `tr_consejo` | — (proyecto B implementado) | día sin carros con feria → Educación (`dia_sin_carros_feria`); bicicletero techado con panel → Energía (`bicicletero_techado_solar`) | sí |
| TR8 | Los senderos peatonales del campus | 300 | quiz | 5 | `mision_transporte` (quiz existente, general — no pregunta específicamente sobre senderos peatonales) | pregunta nueva en quiz de Transporte sobre senderos peatonales | — | no |

## 6. Educación e Investigación (ED) — 18%

| Código | Indicador | Puntos | Tratamiento | Nivel | Cubierto hoy por | Propuesto | Cruces | Accionable |
|---|---|---|---|---|---|---|---|---|
| ED1 | Proporción de asignaturas de sostenibilidad sobre el total de asignaturas | 300 | misión | 6 | `malla_verde` (`mision_malla_verde.gd`, cita ED1 en su propio texto); refuerzo en quiz `mision_educacion` | ya cubierto | — | sí |
| ED2 | Proporción del financiamiento de investigación en sostenibilidad sobre el financiamiento total de investigación | 200 | ficha | 6 | — | ficha informativa (indicador institucional) | — | no |
| ED3 | Número de publicaciones académicas sobre sostenibilidad | 200 | ficha | 6 | `mision_educacion` (quiz, pregunta parcial: "más investigación publicada en revistas") | ficha informativa (indicador institucional) | — | no |
| ED4 | Número de eventos relacionados con la sostenibilidad (ambiente) | 200 | misión | 6 | `semana_verde` (`mision_semana_verde.gd`, cita ED4 en su propio texto) | ya cubierto | — | sí |
| ED5 | Número de actividades relacionadas con la sostenibilidad organizadas por organizaciones estudiantiles al año | 200 | misión | 6 | `comite_ambiental` (`mision_comite_ambiental.gd`, cita ED5 en su propio comentario de cabecera) | ya cubierto | — | sí |
| ED6 | Sitio web de sostenibilidad administrado por la universidad | 200 | ficha | 6 | — | ficha informativa | — | no |
| ED7 | Informe de sostenibilidad | 100 | misión | 6 | `informe_final` (`mision_informe_final.gd`, cita ED7 en su propio comentario de cabecera) | ya cubierto | — | sí |
| ED8 | Número de actividades culturales en el campus (p. ej., Festival Cultural) | 100 | ficha | 6 | — | ficha informativa | — | no |
| ED9 | Número de programas de sostenibilidad universitarios con colaboraciones internacionales | 100 | ficha | 6 | — | ficha informativa (indicador institucional) | — | no |
| ED10 | Número de servicios comunitarios relacionados con la sostenibilidad organizados por la universidad con participación de estudiantes | 100 | quiz | 6 | `semana_verde` (parcial: actividad "Maratón de Siembra Comunitaria") | pregunta nueva en quiz de Educación sobre servicio comunitario | — | parcial |
| ED11 | Número de startups relacionadas con la sostenibilidad | 100 | ficha | 6 | — | ficha informativa (indicador institucional) | — | no |

## Anomalías del inventario actual

1. **`mision_residuos` nunca juega su quiz.** `QUIZ_POR_MISION` define un quiz de
   3 preguntas para `mision_residuos`, pero `ZONA_A_MISION["ZonaCafetin"]` apunta
   a esa misma `mision_id`, y `_on_dialogo_terminado()` (`SceneMapaMundo.gd:971-979`)
   intercepta ese id específico y abre `minijuego_residuos` en su lugar (`return`
   antes de llegar al bloque que abre el quiz). El quiz de `mision_residuos` es
   código muerto: existe pero un jugador nunca lo ve. Esto coincide con el
   inventario del diseño ("Residuos 0" quizzes reachable) — ver sección 5 del
   documento de diseño.
2. **`mision_bloque_g` es un quiz huérfano.** Tiene 3 preguntas en
   `QUIZ_POR_MISION` (temática: jardines internos, área verde mínima, política
   ambiental — relevantes para SI1/SI3/SI6), pero ninguna entrada de
   `ZONA_A_MISION` usa `"mision_bloque_g"` como `mision_id`, así que ninguna zona
   del mapa lo dispara. Es contenido ya escrito que no se juega.
3. **`plantar_sur` no forma parte del Nivel 1 jugable.** `mision_plantar.gd`
   define el bloque de datos `"id": "plantar_sur"` (zona "Zona Sur del Campus",
   `araguaney` como respuesta correcta), pero `DATOS_ZONAS_TIERRA` en
   `SceneMapaMundo.gd` solo enumera 6 zonas (`plantar_rectorado`, `plantar_patio`,
   `plantar_este`, `plantar_corredores`, `plantar_norte`, `plantar_oeste`) y
   `NivelManager.TOTAL_MISIONES[1] = 6`. `plantar_sur` (y también
   `plantar_cafetín`, que existe en el mismo array de datos) no tienen zona en
   el mapa ni cuentan para el progreso del Nivel 1: son datos sin usar, igual
   que `mision_bloque_g`.
4. **WS4 se clasifica como `misión`, no `minijuego`, aunque su cobertura real
   es un minijuego jugable.** `minijuego_residuos.gd` (clasificar 10 residuos
   en el contenedor correcto en 60 segundos) cubre WS4 hoy y es, en el
   código, un minijuego real — pero la decisión D10 del diseño 2026-09-14
   reserva la etiqueta `minijuego` en esta matriz únicamente para los 7
   juegos nuevos que introduce (SI7, SI10, SI11, EC2, EC8, WS3, WR2); si WS4
   también usara `minijuego`, el conteo de verificación del Step 4
   (`minijuego = 7`) se rompería. Por eso WS4 queda como `misión` en la
   columna Tratamiento, con `minijuego_residuos.gd` citado igual en
   "Cubierto hoy por" (ver también la nota † en la tabla de Residuos). El
   mismo objeto es, además, la fuente de Comprensión de Residuos hasta que
   exista un quiz propio (proyecto A, sección 6.1 del diseño: "Residuos: su
   Comprensión sale del minijuego de clasificación — aciertos del primer
   intento / ítems").

**Anomalía adicional detectada durante el inventario** (no estaba en la lista
del brief, se registra por transparencia): `ZonaFotocopiado` → `mision_fotocopiado`
está codificada con `modulo_id: 1` (Entorno) en `ZONA_A_MISION`, pero sus 3
preguntas de quiz son temáticamente sobre reducción de papel/plástico (WS2,
categoría Residuos). No rompe nada — el quiz se juega igual y suma XP al nivel
correcto para el jugador — pero cualquier atribución de "Comprensión por
categoría" (proyecto A) que use el `modulo_id` de la zona en vez del indicador
real asignaría estos aciertos a Entorno en lugar de a Residuos. Se documenta
para que el proyecto A decida si migra el `modulo_id` o si el mapeo
indicador→categoría del catálogo de misiones se define aparte del `modulo_id`
de la zona.

## Preguntas nuevas necesarias

Lista por categoría de los indicadores que necesitan una pregunta de quiz
nueva (ya sea porque hoy no tienen ninguna, o porque un minijuego del proyecto
C debe sumar una pregunta de refuerzo a su categoría, sección 8 del diseño).
Se redactan en el proyecto C, junto a cada minijuego, y en una entrega aparte
de "quizzes faltantes" (ver sección 3 del diseño).

**Entorno (SI):**
- SI1: proporción de área abierta sobre el área total del campus.
- SI2: diferencia entre vegetación boscosa (bosque) y vegetación plantada (jardinería).
- SI4: superficies de absorción de agua distintas a la vegetación (pisos permeables, drenaje natural).
- SI5: espacio abierto disponible por persona en el campus.
- SI7: mantenimiento preventivo vs. correctivo (refuerzo del minijuego Órdenes de trabajo).
- SI10: infraestructura de salud del campus (refuerzo del minijuego Campus saludable).
- SI11: conservación de flora y fauna nativa (refuerzo del minijuego Censo del Lago URBE).

**Energía (EC):**
- EC2: qué es y qué automatiza un edificio inteligente (refuerzo del minijuego Sala de control del Bloque E).
- EC7: en qué consiste un programa de reducción de gases de efecto invernadero.
- EC8: huella de carbono por persona y cómo se reduce (refuerzo del minijuego Inventario de emisiones).

**Residuos (WS):**
- WS3: qué es el compostaje y cómo se trata el residuo orgánico (refuerzo del minijuego Compostera del Cafetín).
- WS6: qué es la disposición de aguas residuales / alcantarillado.

**Agua (WR):**
- WR2: en qué consiste un programa de reciclaje de agua (refuerzo del minijuego Circuito de aguas grises).
- WR3: qué hace eficiente a un artefacto de consumo de agua.
- WR4: qué es el agua tratada y para qué se reutiliza.
- WR5: cómo se controla la contaminación del agua en un campus.

**Transporte (TR):**
- TR8: qué mide GreenMetric sobre los senderos peatonales del campus.

**Educación (ED):**
- ED10: qué cuenta como servicio comunitario relacionado con sostenibilidad.
