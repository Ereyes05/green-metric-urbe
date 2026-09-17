# Nivel 5 nuevo — Plan de Movilidad (Proyecto B, diseño detallado)

- **Fecha:** 2026-09-17
- **Estado:** Implementado en el cliente y catálogos aplicados (2026-09-17); pendientes: migración 2 al publicar, re-export web y prueba con cuenta real.
- **Depende de:** Proyecto A (puntaje único en servidor, `registrar_decision`,
  `registrar_sinergia`, `detalles_estudiante`, `MISIONES_LEGADO`), ya implementado.
- **Diseño de alto nivel (vinculante):**
  `docs/superpowers/specs/2026-09-14-puntaje-greenmetric-cruces-design.md`, secciones
  4 (mapa por lugar con nombre), 6 (modelo de puntaje y regla Mixta), 7 (Proyecto B) y 9 (riesgos).
- **Matriz:** `docs/matriz_cobertura_greenmetric.md`, filas TR1–TR8.

---

## 1. Qué cambia

El Nivel 5 actual no mide aprendizaje: seis escenarios en una sola caseta, con el
impacto visible antes de elegir, la mejor opción siempre primera, cualquier opción
completa la misión, y dos bicicleteros que son una secuencia de "Continuar"
(diseño de alto nivel §1).

El Nivel 5 nuevo es un **Plan de Movilidad** con presupuesto:

1. La **Oficina de Movilidad** da el encargo: presentar un plan al Consejo
   Universitario con **100 puntos de presupuesto** (no son EcoCredits).
2. **Seis decisiones** repartidas por el campus, en cualquier orden, cada una en su
   lugar. Antes de elegir solo se ve el **costo** de cada opción.
3. **Dos bicicleteros** (siguen exigiendo el kit de la Tienda) con una decisión de
   **tipo** que también paga del presupuesto.
4. Al confirmar se revelan las consecuencias (Transporte, aceptación, costo,
   explicación GreenMetric y cruces). La opción **contraproducente** resta 1 en
   Decisiones de Transporte, no gasta presupuesto y deja reintentar (regla Mixta,
   Tabla 15 de la tesis).
5. **Consejo Universitario (Rectorado):** revisión del plan (hasta 2 cambios si el
   presupuesto alcanza), **3 objeciones sobre los puntos débiles reales** del plan
   y elección de argumentos. El resultado completa la calificación del plan
   (componente Decisiones de Transporte) y activa los **cruces**.
6. Lo elegido se **ve en el mapa**, anclado a lugares con nombre.

Se eliminan `mision_movilidad.gd`, `oficina_movilidad.gd`, `mision_bicicletero.gd`
y `punto_bicicletero.gd`.

## 2. Decisiones tomadas al detallar

| # | Tema | Decisión | Por qué |
|---|---|---|---|
| R1 | Reparto de los 5 puntos de Decisiones de Transporte | Mejor opción de cada una de las 6 decisiones = **0,60**; de cada bicicletero = **0,20**; Consejo con 3 argumentos al primer intento = **1,00**. 6×0,60 + 2×0,20 + 1,00 = **5,00** | Cumple §6.1 del alto nivel ("la mejor opción válida de cada decisión suma exactamente 5 entre todas") y deja al Consejo un peso visible (20 %) |
| R2 | Presupuesto | El **plan de mayor puntaje cuesta exactamente 100**; la opción más cara válida de cada decisión suma **162** ("fuertes ~160"); el plan válido más barato cuesta **74** | Lo caro no siempre es lo mejor: en 4 de las 8 decisiones la mejor opción es la más barata de las válidas. Llegar a 5,00 exige elegir bien, no gastar más |
| R3 | Qué se revela al confirmar | **Válida:** se revelan las 3 opciones (incluida la contraproducente). **Contraproducente:** solo la elegida | Revelar todo tras una contraproducente regalaría el reintento; tras una válida, ver las otras es el aprendizaje (y cambiar cuesta presupuesto) |
| R4 | Opción contraproducente ya probada | Queda **descartada** (deshabilitada) en esa decisión, también al reabrir | Evita penalizaciones repetidas por error; el servidor igual limita a 3 |
| R5 | Cruces (sinergias) | Se registran **al aprobar el Consejo**, según el plan final, con `requisito_mision = 'tr_consejo'` | Una sinergia no se revoca: si se registrara al elegir, cambiar después la decisión dejaría un cruce que ya no corresponde |
| R6 | Plan después del Consejo | **Cerrado**: las decisiones quedan de solo lectura y la calificación del Consejo es la del primer intento | Mismo principio de "primer intento" que la Comprensión (§6.1); evita presentar muchas veces para subir la nota |
| R7 | Objeciones del Consejo | Se eligen por **debilidad** de cada decisión (aceptación + no ser la mejor opción + contraproducentes probadas) | "Puntos débiles reales del plan" (§7 alto nivel), determinista y probable sin interfaz |
| R8 | Argumento incorrecto | Explica por qué no convence, se descarta y se reintenta la **misma** objeción; solo cuenta el primer intento | Tabla 15 (reintento) sin inflar la nota |
| R9 | Misión de cada decisión | Se completa con la **primera opción válida** registrada; cambiar después no vuelve a pagar XP/EC | Igual que el resto de las misiones: una sola vez |
| R10 | Migración del catálogo de misiones | Dos migraciones: **catálogos de decisiones/sinergias** (se aplica al implementar) y **cambio de misiones del Nivel 5** (se aplica recién cuando se publica el cliente nuevo) | Aplicar el cambio de misiones antes dejaría el juego publicado (que todavía guarda `mov_*`) con el avance de Transporte en 0 |
| R11 | Lugar del Consejo | Entrada oeste del Rectorado (`rectorado`), no la plaza norte | La plaza norte ya tiene al Rector, el panel solar y el bicicletero del Bloque E a < 60 px |
| R12 | Emoji | Solo los de `HUD_TEMA.EMOJIS_HUD` (el recorte de NotoColorEmoji) | Cualquier otro se ve como cuadradito en la web |
| R13 | Re-pago a quien completó el Nivel 5 viejo | **No** se paga XP ni EcoCredits (por misión ni bono de nivel) si el conjunto legado del Nivel 5 está completo; las misiones `tr_*` igual se completan y cuentan para el Avance (§11.1) | Decisión del usuario 2: ya cobró por el Nivel 5 |
| R14 | Tratamiento | Tuteo en todos los textos nuevos ("tienes", "elige", "puedes") | Decisión del usuario 7 |

## 3. Lugares con nombre (`scenes/mapa/lugares_campus.gd`)

Script propio, `extends RefCounted`, sin `class_name` (se usa con
`preload`). Constante `LUGARES : Dictionary` nombre → `Vector2` y dos funciones
estáticas:

- `existe(lugar) -> bool`
- `posicion(lugar, desplazamiento := Vector2.ZERO) -> Vector2` (lugar desconocido:
  `push_error` y `Vector2.ZERO`).

**Coordenadas PROVISIONALES del mapa actual (1408×768).** Encabezado del archivo:
"cuando llegue el mapa rediseñado, reubicar = editar SOLO este archivo y volver a
correr `tests/test_lugares_campus.tscn`".

| Lugar | Vector2 | Qué hay | Origen |
|---|---|---|---|
| `oficina_movilidad` | (600, 100) | Camino norte frente al Patio | Oficina actual (`DATOS_OFICINA_MOVILIDAD`) |
| `bicicletero_bloque_e` | (1020, 460) | Plaza entre Bloque E y Rectorado | Bicicletero actual |
| `bicicletero_cafetin` | (200, 360) | Borde este del M5, camino al Cafetín | Bicicletero actual |
| `garita_m5` | (60, 330) | Entrada vehicular del M5 | Nuevo |
| `estacionamiento_m5` | (110, 240) | Zona norte del M5 | Nuevo |
| `lote_este` | (1340, 710) | Lote poco usado detrás de Estudios a Distancia | Nuevo |
| `parada_rectorado` | (1060, 752) | Av. URBE frente a la esquina del Rectorado | Nuevo |
| `porton_vehicular` | (600, 752) | Portón de la Av. URBE | Nuevo |
| `zona_mantenimiento` | (1190, 715) | Patio de servicios, sureste | Nuevo |
| `rectorado` | (720, 560) | Entrada oeste del Rectorado (Consejo) | Nuevo |

Verificado al diseñar con el chequeo de `qa_posiciones.py` (umbral 55 px): el más
cercano a un punto existente queda a 94 px (`parada_rectorado` ↔ `llave_bloque_b`)
y entre lugares nuevos el mínimo es 103 px. Ninguno cae dentro de
`colision_tilemap.gd EDIFICIOS`.

**Chequeo de solapamientos dentro del repo:** `tests/test_lugares_campus.gd` lee
todas las constantes `DATOS_*` de `SceneMapaMundo.gd` (menos las que no se
instancian o que este registro reemplaza) y `DATOS_NPCS`, y exige ≥ 55 px a cada
punto existente, ≥ 55 px entre lugares, dentro del mapa y fuera de los rectángulos
de edificios.

**Proyecto C** agrega sus lugares (`cafetin`, `lago`, `bloque_d`, `area_salud`…) a
este mismo archivo cuando los necesite; B no los inventa.

## 4. Flujo del nivel

```
Nivel 4 superado ──► aparecen 10 puntos (Oficina, 6 decisiones, 2 bicicleteros, Consejo)
                       decisiones/bicicleteros/Consejo: 🔒 bloqueados
Oficina ──► encargo ──► [Aceptar] ──► decisiones y bicicleteros: pendientes
Cualquier orden:
  decisión ──► 3 opciones con costo ──► elegir ──► Confirmar ──► registrar_decision
      ├─ contraproducente ─► revela solo esa + "-1" + presupuesto intacto ─► Reintentar
      ├─ válida ───────────► revela las 3 ─► misión completa (1.ª vez: XP/EC) ─► mapa cambia
      └─ error de red ─────► "no se aplicó nada, vuelve a confirmar" (sin reintento automático)
  bicicletero ─► exige kit_bicicletero (Tienda) ─► misma interfaz de decisión (tipo)
8 resueltas ──► Consejo (Rectorado): pendiente
Consejo ──► Revisión (hasta 2 cambios si alcanza) ──► Presentar
        ──► 3 objeciones (argumento; incorrecto → explica y reintenta)
        ──► Resultado: calificación, tr_consejo completa, registrar_decision(tr_consejo),
            registrar_sinergia(cruces del plan) ──► plan cerrado
```

La Oficina, después del encargo, muestra el **tablero del plan**: presupuesto
comprometido y restante, estado de cada decisión (pendiente con su lugar, o la
opción elegida con su costo) y el estado del Consejo.

## 5. Presupuesto y puntos (resumen)

| Decisión | Lugar | Indicador | Mejor opción (costo · puntos) | Otra válida (costo · puntos) | Contraproducente (costo) | Cruce |
|---|---|---|---|---|---|---|
| `tr_permisos` | `garita_m5` | TR1 | Permisos por necesidad (8 · 0,60) | Lectoras de placas (24 · 0,25) | Más puestos sobre la grama (14) | — |
| `tr_lote` | `lote_este` | TR5 · TR6 | Ciclovía con árboles (22 · 0,60) | Explanada de eventos (12 · 0,35) | Asfaltar el lote (16) | Entorno +1 |
| `tr_carpool` | `estacionamiento_m5` | TR7 | Puestos para carros con 3+ (6 · 0,60) | App de carpool (26 · 0,35) | Vender puestos reservados (0) | — |
| `tr_shuttle` | `parada_rectorado` | TR2 | Busetas a las paradas (26 · 0,60) | Estacionamiento externo + busetas (34 · 0,40) | Bono de gasolina (10) | — |
| `tr_dia_sin_carros` | `porton_vehicular` | TR7 | Jornada mensual con feria (10 · 0,60) | Viernes sin carros (28 · 0,40) | Motos por la acera (4) | Educación +1 |
| `tr_flota` | `zona_mantenimiento` | TR3 · TR4 | Carritos eléctricos (18 · 0,60) | Triciclos de carga (8 · 0,40) | Camioneta diésel (20) | Energía +1 |
| `tr_bici_bloque_e` | `bicicletero_bloque_e` | TR7 | Techado con panel solar (5 · 0,20) | Simple, sin techo (2 · 0,10) | Ganchos en el sendero (1) | Energía +1 |
| `tr_bici_cafetin` | `bicicletero_cafetin` | TR7 | Techado con panel solar (5 · 0,20) | Simple, sin techo (2 · 0,10) | Ganchos en el sendero (1) | Energía +1 (misma sinergia: una vez) |
| **Totales** | | | **100 · 4,00** | máx. válida por decisión = **162** | | |

- **Consejo:** 3 argumentos al primer intento 1,00 · 2 → 0,60 · 1 → 0,30 · 0 → 0,00.
- **Decisiones de Transporte (servidor)** = Σ puntos de la opción vigente de cada
  decisión + puntos del Consejo − penalizaciones (−1 por contraproducente, máx. 3
  por decisión), acotado a 0–5 (`puntaje_greenmetric`, sin cambios).
- **Plan de 5,00:** las 8 mejores opciones (costo 100, sin contraproducentes) y los
  3 argumentos correctos al primer intento.
- **Orden de las opciones en pantalla:** fijo y distinto en cada decisión; la mejor
  nunca está siempre en el mismo lugar (ver §6).

## 6. Las decisiones

Cifras de contexto **ilustrativas** (datos mixtos, Tabla 16); validarlas con la
Dirección de Sustentabilidad (decisión del usuario 1: quedan ilustrativas). "Aceptación" es la reacción esperable
de la comunidad; alimenta las objeciones del Consejo. Las opciones se listan **en
el orden en que aparecen en pantalla**. Textos para el jugador con **tuteo** (decisión del usuario 7).

### 6.1 `tr_permisos` — Permisos de estacionamiento

- **Lugar:** `garita_m5` (Garita del Estacionamiento M5) · **Indicador:** TR1.
- **Contexto:** "En la garita del Estacionamiento M5 se entregan los permisos
  anuales. Hoy cualquiera que lo pida recibe uno: hay más carros y motos con permiso
  que puestos, y en la hora pico de la mañana la cola llega hasta la avenida.
  GreenMetric (TR1) mide cuántos vehículos entran al campus por cada persona de la
  comunidad universitaria."
- **Pregunta:** "¿Qué política de permisos llevas al plan?"

| Opción (id · corto) | Texto | Costo | Transp. | Aceptación | Contrap. | Explicación GreenMetric | Cruce |
|---|---|---|---|---|---|---|---|
| `lectoras_de_placas` · Lectoras de placas | Instalar cámaras lectoras de placas y una barrera automática para que la entrada sea más rápida | 24 | 0,25 | alta | no | Ordena la entrada y da datos reales de cuántos vehículos entran (útiles para reportar TR1), pero no reduce ni un carro: la cola se va, los vehículos se quedan. Mucho gasto para poco efecto en el indicador. | — |
| `pintar_mas_puestos` · Más puestos sobre la grama | Acabar con la cola pintando 80 puestos nuevos sobre la franja de grama que rodea el M5 | 14 | 0 | — | **sí** | Más puestos atraen más carros (TR1 empeora), aumentan el área de estacionamiento en superficie (TR5) y quitan área verde que suma en Entorno. GreenMetric lo cuenta en contra. | — |
| `permiso_por_necesidad` · Permisos por necesidad | Dar permiso anual solo a quien vive lejos y sin transporte público, tiene movilidad reducida o comparte el carro; el resto entra con pase diario | 8 | 0,60 | baja | no | Es una regla, no una obra: cuesta poco y baja directamente los vehículos por persona que mide TR1. Quien pierde su permiso anual se queja, por eso la aceptación es baja: hay que acompañarla con alternativas como la buseta y el carpool. | — |

### 6.2 `tr_lote` — El lote poco usado

- **Lugar:** `lote_este` (Lote detrás de Estudios a Distancia) · **Indicadores:** TR5, TR6.
- **Contexto:** "Detrás de Estudios a Distancia hay un lote de tierra y granzón con
  capacidad para 60 carros que casi nunca pasa de 15. Con lluvia se inunda y en
  sequía levanta polvo. GreenMetric premia reducir el área de estacionamiento en
  superficie (TR5) y tener un programa documentado para hacerlo (TR6)."
- **Pregunta:** "¿Qué haces con el lote?"

| Opción | Texto | Costo | Transp. | Aceptación | Contrap. | Explicación GreenMetric | Cruce |
|---|---|---|---|---|---|---|---|
| `asfaltar_lote` · Asfaltar el lote | Asfaltarlo y demarcarlo para que por fin se use y descongestione el M5 | 16 | 0 | — | **sí** | Convierte un lote poco usado en estacionamiento formal: sube el área de estacionamiento en superficie (TR5), va contra el programa de reducción (TR6) y el asfalto calienta y sella el suelo. | — |
| `ciclovia_arborizada` · Ciclovía con árboles | Cerrarlo a los carros y convertirlo en un tramo de ciclovía y caminería con árboles nativos de sombra, conectado al portón | 22 | 0,60 | alta | no | Quita área de estacionamiento (TR5), queda como programa de reducción con fecha y metros (TR6) y la sombra hace posible caminar o pedalear con el calor de Maracaibo. Los árboles suman también en Entorno. | `ciclovia_lote` → 🌿 Entorno +1 |
| `plaza_de_eventos` · Explanada de eventos | Cerrarlo a los carros y dejarlo como explanada de ferias y eventos con piso permeable | 12 | 0,35 | media | no | También reduce el área de estacionamiento (TR5), pero sin relación con la movilidad: nadie deja el carro por eso. Y si en cada evento vuelve a ser estacionamiento improvisado, el programa pierde credibilidad (TR6). | — |

### 6.3 `tr_carpool` — Viajes compartidos

- **Lugar:** `estacionamiento_m5` · **Indicador:** TR7.
- **Contexto:** "En el M5 casi todos los carros llegan con una sola persona. Muchos
  estudiantes viven en las mismas urbanizaciones y salen a la misma hora. Una
  iniciativa de viajes compartidos cuenta para GreenMetric como iniciativa para
  disminuir los vehículos privados en el campus (TR7)."
- **Pregunta:** "¿Qué incentivo propones?"

| Opción | Texto | Costo | Transp. | Aceptación | Contrap. | Explicación GreenMetric | Cruce |
|---|---|---|---|---|---|---|---|
| `app_carpool` · App de carpool | Pagar una aplicación de viajes compartidos con cuentas URBE y un grupo por urbanización | 26 | 0,35 | alta | no | Gusta y facilita encontrar compañeros, pero sin un beneficio concreto al llegar pocos cambian el hábito. Cuenta como iniciativa (TR7), con poco efecto para lo que cuesta. | — |
| `puestos_3_ocupantes` · Puestos para carros con 3+ | Reservar los puestos más cercanos a la entrada peatonal para carros que lleguen con 3 o más personas, verificados en la garita hasta las 9 a. m. | 6 | 0,60 | media | no | Un incentivo visible y barato: el mejor puesto se gana compartiendo. Es una iniciativa concreta de TR7. Quien llega solo pierde comodidad, por eso la aceptación no es alta. | — |
| `vender_puestos_reservados` · Vender puestos reservados | Vender puestos reservados con nombre a quien pague la cuota más alta; con lo recaudado se paga el mantenimiento del M5 | 0 | 0 | — | **sí** | Parece gratis, pero premia al que viene solo en carro y le asegura el puesto: incentiva el vehículo privado, lo contrario de lo que mide TR7. | — |

### 6.4 `tr_shuttle` — Servicio de buseta

- **Lugar:** `parada_rectorado` (Parada de la Av. URBE, frente al Rectorado) · **Indicador:** TR2.
- **Contexto:** "URBE tiene una buseta que hace una sola vuelta por la mañana.
  Muchos estudiantes llegan en por puesto o autobús hasta la avenida y caminan el
  resto bajo el sol, o prefieren venir en carro. GreenMetric (TR2) evalúa si el
  campus ofrece transporte interno y qué tan útil es."
- **Pregunta:** "¿Cómo reorganizas la buseta?"

| Opción | Texto | Costo | Transp. | Aceptación | Contrap. | Explicación GreenMetric | Cruce |
|---|---|---|---|---|---|---|---|
| `bono_gasolina` · Bono de gasolina | Eliminar la buseta, que va medio vacía, y con ese dinero dar un bono de gasolina al personal | 10 | 0 | — | **sí** | Elimina el servicio que mide TR2 y además subsidia el carro particular: más vehículos por persona (TR1) y más emisiones. | — |
| `ruta_a_paradas` · Busetas a las paradas | Dos busetas en circuito fijo cada 20 minutos entre las paradas de por puesto de la avenida, el Rectorado y los bloques, de 6:30 a. m. a 9 p. m. | 26 | 0,60 | alta | no | Conecta el campus con el transporte público que la gente ya usa y cubre los tres turnos: es el tipo de servicio que valora TR2. Con frecuencia fija la gente puede contar con él. | — |
| `park_and_ride` · Estacionamiento externo + busetas | Alquilar un estacionamiento en un centro comercial cercano y traer a la gente desde ahí en tres busetas | 34 | 0,40 | media | no | Saca carros del campus y cuenta como transporte interno (TR2), pero cada persona sigue llegando en carro hasta el centro comercial, y es la opción más cara: el alquiler se paga todos los meses. | — |

### 6.5 `tr_dia_sin_carros` — Día sin carros

- **Lugar:** `porton_vehicular` (Portón vehicular de la Av. URBE) · **Indicador:** TR7.
- **Contexto:** "Varias universidades del ranking cierran su portón vehicular un día
  al mes. En URBE la idea genera dudas: ¿cómo llega quien vive lejos? El portón de
  la avenida es el único acceso de carros. Una jornada así cuenta como iniciativa
  para disminuir los vehículos privados (TR7)."
- **Pregunta:** "¿Cómo lo organizas?"

| Opción | Texto | Costo | Transp. | Aceptación | Contrap. | Explicación GreenMetric | Cruce |
|---|---|---|---|---|---|---|---|
| `cierre_semanal` · Viernes sin carros | Cerrar el portón a los carros particulares todos los viernes desde el mes que viene, con busetas de refuerzo contratadas | 28 | 0,40 | baja | no | En papel saca más carros, pero cada viernes sin alternativas suficientes baja la asistencia y la comunidad presiona para eliminarlo. Una iniciativa que no se sostiene suma menos en TR7 que una mensual bien hecha. | — |
| `jornada_mensual_con_feria` · Jornada mensual con feria | Un miércoles al mes con el portón cerrado a carros particulares, busetas de refuerzo y una feria de movilidad con charlas y taller de mecánica de bicis | 10 | 0,60 | media | no | Es periódica, medible (se cuentan los carros que no entraron) y viene con alternativas. La feria y las charlas la convierten en un evento de sostenibilidad, que también suma en Educación. | `dia_sin_carros_feria` → 📚 Educación +1 |
| `motos_por_la_acera` · Motos por la acera | Hacer el día sin carros pero dejar pasar motos y permitir estacionarlas en las aceras cerca de los bloques | 4 | 0 | — | **sí** | Los vehículos solo cambian de tipo: las motos también cuentan en TR1, y estacionarlas en las aceras quita espacio a los peatones (TR8, senderos peatonales). | — |

### 6.6 `tr_flota` — Flota de mantenimiento

- **Lugar:** `zona_mantenimiento` (Patio de mantenimiento) · **Indicadores:** TR3, TR4.
- **Contexto:** "La cuadrilla de mantenimiento recorre el campus en dos carritos a
  gasolina con más de diez años que fallan seguido. GreenMetric evalúa si hay
  vehículos de cero emisiones en el campus —eléctricos o de pedal— (TR3) y cuántos
  hay por persona (TR4)."
- **Pregunta:** "¿Qué haces con la flota?"

| Opción | Texto | Costo | Transp. | Aceptación | Contrap. | Explicación GreenMetric | Cruce |
|---|---|---|---|---|---|---|---|
| `triciclos_de_carga` · Triciclos de carga | Comprar tres triciclos de carga a pedal para los trabajos cortos y dejar un solo carrito a gasolina | 8 | 0,40 | media | no | Los triciclos son vehículos de cero emisiones (TR3), baratos y sin combustible, pero con el calor y las distancias largas la cuadrilla sigue usando el carrito a gasolina para casi todo. | — |
| `camioneta_diesel` · Camioneta diésel | Reemplazar los dos carritos por una camioneta diésel más grande para hacer todo en un solo viaje | 20 | 0 | — | **sí** | Ningún vehículo de cero emisiones (TR3 y TR4 quedan en nada) y un motor diésel que emite más por kilómetro. Resuelve la logística a costa del indicador. | — |
| `carritos_electricos` · Carritos eléctricos | Cambiar los dos carritos por carritos eléctricos que se cargan con el techo solar del estacionamiento | 18 | 0,60 | alta | no | Dos vehículos de cero emisiones nuevos (TR3 y TR4) que además usan energía producida en el campus: menos combustible y menos emisiones. Por eso suma también en Energía. | `flota_electrica` → ⚡ Energía +1 |

### 6.7 Bicicleteros — `tr_bici_bloque_e` y `tr_bici_cafetin`

- **Requisito:** `kit_bicicletero` (60 EC) con `_verificar_herramienta("bicicletero", punto)`,
  igual que hoy; solo se pide si la decisión todavía no está resuelta. El precio
  sigue siendo menor que lo que pagan las 6 decisiones (6 × 12 = 72 EC).
- **Indicador:** TR7 (iniciativa para disminuir vehículos privados). La secuencia
  de "Continuar" desaparece: la instalación es la decisión de tipo.
- **Pregunta (ambos):** "¿Qué tipo de bicicletero instalas con el kit?"

`tr_bici_bloque_e` — lugar `bicicletero_bloque_e`. **Contexto:** "Entre el Bloque E
y el Rectorado pasan cientos de estudiantes, pero no hay dónde dejar una bicicleta
segura: quien viene en bici la amarra a una baranda. Un bicicletero forma parte de
las iniciativas para disminuir los vehículos privados (TR7)."
Orden en pantalla: `simple_con_candado`, `techado_con_panel`, `sobre_el_sendero`.

`tr_bici_cafetin` — lugar `bicicletero_cafetin`. **Contexto:** "Al borde del M5,
camino al Cafetín, llegan estudiantes y personal desde las urbanizaciones cercanas.
Con el sol de la tarde, una bicicleta dejada a la intemperie se recalienta y el
asiento se daña. Un bicicletero forma parte de las iniciativas para disminuir los
vehículos privados (TR7)."
Orden en pantalla: `sobre_el_sendero`, `simple_con_candado`, `techado_con_panel`.

| Opción | Texto | Costo | Transp. | Aceptación | Contrap. | Explicación GreenMetric | Cruce |
|---|---|---|---|---|---|---|---|
| `techado_con_panel` · Techado con panel solar | Techado, con un panel solar pequeño que alimenta la luz LED nocturna | 5 | 0,20 | alta | no | Sombra y luz hacen que la gente lo use de verdad (la seguridad percibida decide si alguien viene en bici) y la luz no consume de la red. Suma a TR7 y a Energía. | `bicicletero_techado_solar` → ⚡ Energía +1 (una sola vez aunque se elija en los dos) |
| `simple_con_candado` · Simple, sin techo | Estructura simple de tubos en U, sin techo, junto a un poste de luz existente | 2 | 0,10 | media | no | Cumple y es barato, pero sin sombra, con el sol de Maracaibo, se usa menos: un bicicletero vacío no reduce carros. | — |
| `sobre_el_sendero` · Ganchos en el sendero | Colgar ganchos en la baranda del pasillo techado peatonal, sin estructura nueva | 1 | 0 | — | **sí** | Las bicis ocupan el sendero peatonal techado (TR8) y quedan mal aseguradas: peatones y ciclistas terminan compitiendo por el mismo espacio. | — |

## 7. Consejo Universitario

### 7.1 Revisión

Disponible cuando el encargo está aceptado y las 8 decisiones resueltas. Muestra
cada decisión con la opción elegida (corto), aceptación y costo, el presupuesto
restante y "Cambios disponibles: N". El botón **Cambiar** abre el panel de decisión
en modo Consejo; al cerrarlo se vuelve a la revisión. Un cambio cuenta solo cuando
se registra una opción válida **distinta**; el máximo es 2
(`PLAN.MAX_CAMBIOS_CONSEJO`). Las opciones que no entran en el presupuesto (liberando
el costo de la actual) están deshabilitadas con "No alcanza el presupuesto (faltan N)".
Una contraproducente en modo Consejo sigue la regla Mixta y no gasta un cambio.

### 7.2 Selección de las 3 objeciones

Para cada decisión resuelta:

```
debilidad = peso(aceptación)            baja 3 · media 2 · alta 1
          + 2 si la opción no es la mejor de esa decisión
          + contraproducentes probadas en esa decisión (máx. 3)
```

Se ordena por debilidad descendente; empate → orden de las decisiones
(permisos, lote, carpool, shuttle, día sin carros, flota, bici Bloque E, bici Cafetín).
Se toman las 3 primeras. Cada opción válida tiene su objeción (16 en total).

Ejemplos (verificados en las pruebas):
- Plan de 5,00 (las 8 mejores): permisos (3), carpool (2), día sin carros (2).
- Plan barato (permisos por necesidad, explanada, 3+, busetas a paradas, jornada,
  triciclos, dos simples; costo 74): lote (4), flota (4), bici Bloque E (4). Si
  además se probó la contraproducente de permisos: permisos (4), lote, flota.

### 7.3 Objeciones y argumentos

✔ = `correcto: true`. El orden de los argumentos es el de la pantalla.

**`tr_permisos:permiso_por_necesidad`** — Consejera de Egresados: «Van a quitarle el permiso anual a cientos de personas. Va a haber quejas y hasta retiros.»
1. ✘ "GreenMetric lo exige, así que no hay nada que discutir." — GreenMetric no obliga a nada: es un ranking voluntario. Imponer sin explicar es justo lo que genera rechazo.
2. ✔ "Nadie pierde el acceso: sigue el pase diario, y la buseta y el carpool del plan dan alternativas a quien deja de tener permiso anual." — Una restricción se defiende mostrando las alternativas que la acompañan.
3. ✘ "Si hay muchas quejas, se vuelve a dar permiso a todos." — Deshacer la medida al primer reclamo borra la reducción de vehículos (TR1) y la credibilidad del plan.

**`tr_permisos:lectoras_de_placas`** — Director de Finanzas: «24 puntos del presupuesto en cámaras… ¿cuántos carros menos entran con eso?»
1. ✔ "Ninguno por sí solo: el valor está en medir. Con los datos de las placas se fija una meta de reducción y se comprueba si se cumple (TR1)." — Reconocer el límite y mostrar para qué sirve el dato es un argumento honesto y verificable.
2. ✘ "Muchos: al entrar más rápido, la gente se anima a no traer el carro." — Una entrada más rápida hace más cómodo venir en carro, no menos.
3. ✘ "Las cámaras dan seguridad, y eso es lo que mide GreenMetric en Transporte." — La seguridad importa, pero TR1 mide vehículos por persona, no vigilancia.

**`tr_lote:ciclovia_arborizada`** — Jefe de Servicios Generales: «¿Y quién riega esos árboles y mantiene la ciclovía? Eso cuesta todos los años.»
1. ✘ "Los árboles no necesitan mantenimiento." — Todo árbol recién plantado necesita riego y cuidado al principio.
2. ✘ "Si sale caro, se vuelve a abrir el lote para carros." — Reabrirlo borra la reducción de área de estacionamiento que suma en TR5 y TR6.
3. ✔ "Con especies nativas adaptadas al clima de Maracaibo, que después del primer año necesitan poco riego; el mantenimiento entra en la rutina de jardinería que ya existe." — Anticipar el costo con una elección técnica responde la objeción.

**`tr_lote:plaza_de_eventos`** — Coordinadora de Eventos: «El día de la feria la gente va a estacionar ahí igual. ¿Entonces qué redujimos?»
1. ✘ "Nada, pero queda un espacio bonito para el campus." — Si no reduce estacionamiento, no suma en TR5 ni en TR6: el plan pierde su argumento principal.
2. ✔ "Se ponen bolardos y una regla escrita: el lote no se usa como estacionamiento ni en eventos, y los visitantes llegan en buseta." — Un programa de reducción (TR6) necesita reglas que se cumplan también los días especiales.
3. ✘ "Es solo unas veces al año, no afecta el indicador." — Si se permite en cada evento, el área sigue funcionando como estacionamiento y el programa pierde credibilidad.

**`tr_carpool:puestos_3_ocupantes`** — Representante estudiantil: «Muchos vivimos en zonas donde nadie más viene a URBE. Nos quitan los buenos puestos.»
1. ✘ "Que se muden más cerca." — Una respuesta que desprecia la situación real de la gente hunde la aceptación del plan.
2. ✘ "Los puestos reservados son pocos, así que en realidad no cambia nada." — Si no cambia nada, tampoco reduce carros: el argumento contradice el objetivo.
3. ✔ "Quien llega solo conserva su puesto en el resto del M5; solo se reservan los más cercanos hasta las 9, y el grupo por urbanización ayuda a encontrar con quién venir." — Mostrar que la medida es acotada y que ofrece cómo cumplirla responde la queja.

**`tr_carpool:app_carpool`** — Director de Finanzas: «La aplicación se paga todos los años. ¿Qué pasa si nadie la usa?»
1. ✘ "Se va a usar sí o sí, porque es moderna." — Que algo sea moderno no garantiza que cambie hábitos.
2. ✔ "Cada semestre se mide cuántos viajes compartidos registra; si no llega a una meta mínima, ese dinero pasa a puestos preferenciales para carros con 3 o más personas." — Una iniciativa con meta y plan B es defendible.
3. ✘ "Es gratis para los estudiantes, así que no importa." — Que sea gratis para quien la usa no cambia que la universidad la paga.

**`tr_shuttle:ruta_a_paradas`** — Director de Finanzas: «Dos busetas de 6:30 de la mañana a 9 de la noche: chofer, gasoil, repuestos. ¿Lo podemos sostener?»
1. ✘ "Las busetas se pagan solas porque la gente las va a usar." — El pasaje interno no existe o es simbólico: el servicio siempre tiene un costo que hay que financiar.
2. ✘ "Se puede quitar el turno de la noche, que tiene pocos estudiantes." — Dejar sin transporte al turno nocturno, el que más lo necesita por seguridad, rompe la cobertura que valora TR2.
3. ✔ "Se ajusta la frecuencia con conteos de pasajeros por turno y se financia en parte con el cobro de estacionamiento a visitantes." — Datos de uso y una fuente de financiamiento concreta hacen sostenible el servicio.

**`tr_shuttle:park_and_ride`** — Consejero académico: «Igual le pedimos a la gente que maneje hasta el centro comercial. ¿Eso es sostenible?»
1. ✔ "Es un paso intermedio: reduce los carros dentro del campus y el estacionamiento que necesitamos; después la ruta puede extenderse a las paradas de transporte público." — Reconocer el límite y mostrar el camino siguiente es un argumento sólido.
2. ✘ "Sí, porque el centro comercial queda cerca." — La cercanía no elimina el viaje en carro.
3. ✘ "El indicador solo cuenta los carros dentro del campus; lo de afuera no importa." — Es cierto que TR1 cuenta vehículos del campus, pero defender el plan ignorando las emisiones de afuera lo debilita ante el Consejo.

**`tr_dia_sin_carros:jornada_mensual_con_feria`** — Decano: «Un miércoles con el portón cerrado: los profesores que vienen de lejos van a faltar a clases.»
1. ✘ "Ese día se pueden suspender las clases." — Suspender clases convierte la iniciativa en un feriado: no enseña a llegar de otra forma.
2. ✔ "Se anuncia con el calendario del semestre, hay busetas de refuerzo desde las paradas y quien tiene movilidad reducida conserva el acceso." — Anticipación, alternativas y excepciones justas responden la preocupación.
3. ✘ "Que falten: es solo un día al mes." — Minimizar el problema no lo resuelve y baja la aceptación del plan.

**`tr_dia_sin_carros:cierre_semanal`** — Representante estudiantil: «Todos los viernes sin carros, desde el mes que viene. Va a bajar la asistencia.»
1. ✘ "Quien no venga es porque no le importa el ambiente." — Culpar a la comunidad no resuelve cómo llega quien vive lejos.
2. ✘ "Con las busetas contratadas alcanza para todos." — Afirmarlo sin conteos de demanda no convence.
3. ✔ "Se empieza con una jornada mensual bien organizada y la frecuencia sube solo si los conteos muestran que las alternativas alcanzan." — Reconocer el riesgo y proponer una implementación gradual con datos es el mejor argumento.

**`tr_flota:carritos_electricos`** — Jefe de Mantenimiento: «¿Y si se acaba la batería a mitad de un trabajo? Los viejos al menos se llenan de gasolina.»
1. ✔ "Las rutas de trabajo se planifican según la autonomía y los carritos se cargan de noche o al mediodía con el techo solar; los trayectos dentro del campus son cortos." — Planificar la operación responde el riesgo real.
2. ✘ "Los carritos eléctricos nunca se descargan." — Todo vehículo eléctrico tiene una autonomía limitada.
3. ✘ "Si fallan, se vuelven a comprar carritos a gasolina." — Volver atrás al primer problema anula el cambio que suma en TR3 y TR4.

**`tr_flota:triciclos_de_carga`** — Jefe de Mantenimiento: «Con este calor nadie va a pedalear un triciclo cargado desde el M5 hasta el Rectorado.»
1. ✘ "Es buen ejercicio para la cuadrilla." — Ignora las condiciones de trabajo: sin una organización realista, los triciclos quedan guardados.
2. ✔ "Los triciclos se asignan a los trabajos cortos por zona y el carrito a gasolina queda solo para cargas pesadas, con registro de uso." — Organizar el uso real es lo que hace que un vehículo de cero emisiones reduzca emisiones.
3. ✘ "Aunque no se usen, igual cuentan como vehículos de cero emisiones." — Tenerlos guardados cuenta en papel, pero no reduce emisiones; el Consejo pregunta por el efecto real.

**`tr_bici_bloque_e:techado_con_panel`** — Jefe de Seguridad: «Un panel solar en un bicicletero, a la vista de todos. ¿No se lo van a robar?»
1. ✘ "En URBE nadie roba." — Negar el riesgo no convence a quien tiene que cuidar el campus.
2. ✔ "El panel va fijo sobre el techo con tornillería antirrobo, a la vista de la vigilancia y con la luz encendida toda la noche, que también protege las bicis." — Prevención concreta responde la objeción.
3. ✘ "Si se lo roban, se pone otro." — Reponer sin prevenir multiplica el costo.

**`tr_bici_bloque_e:simple_con_candado`** — Representante estudiantil: «Sin techo, a las dos de la tarde el asiento quema. ¿Quién lo va a usar?»
1. ✔ "Se ubica bajo la sombra de los árboles del corredor y al final del semestre se revisa cuánto se usa para decidir si se techa." — Una mejora barata con evaluación posterior es defendible.
2. ✘ "Cada uno puede traer una toalla para el asiento." — Trasladar el problema al usuario reduce el uso del bicicletero.
3. ✘ "Lo importante es tenerlo, aunque no se use." — Un bicicletero vacío no reduce ningún carro.

**`tr_bici_cafetin:techado_con_panel`** — Director de Finanzas: «¿Por qué pagar un panel solar para una sola luz?»
1. ✘ "Porque los paneles solares siempre son más baratos que cualquier otra cosa." — No siempre: depende de la instalación; el argumento es falso como regla general.
2. ✘ "Porque se ve moderno." — La imagen no justifica un gasto ante el Consejo.
3. ✔ "Porque evita cablear desde el edificio: el panel pequeño cuesta menos que la obra eléctrica y la luz no consume de la red." — Comparar con la alternativa real (cablear) justifica el costo.

**`tr_bici_cafetin:simple_con_candado`** — Jefe de Seguridad: «Sin luz ni techo, de noche esto es un bicicletero para ladrones.»
1. ✘ "De noche casi no hay estudiantes." — El turno nocturno existe y es el que más necesita seguridad.
2. ✔ "Queda junto al poste de luz existente y dentro del recorrido de vigilancia del estacionamiento, y la campaña de movilidad recomienda candado en U." — Aprovechar la luz y la vigilancia existentes responde el riesgo sin costo extra.
3. ✘ "Cada uno es responsable de su bicicleta." — Si la gente no se siente segura, no viene en bici y el bicicletero no cumple su función.

### 7.4 Argumento elegido

- **Correcto:** se muestra la explicación en verde y "Siguiente objeción" / "Ver resultado".
- **Incorrecto:** explicación en naranja, ese argumento queda deshabilitado y se
  vuelve a elegir en la misma objeción.
- Por objeción se guarda `primer_argumento`, `correcto_primer_intento` e `intentos`.

### 7.5 Resultado y relación con Decisiones

| Aciertos al primer intento | `opcion_id` en `tr_consejo` | Puntos | Nombre |
|---|---|---|---|
| 3 | `consejo_3` | 1,00 | Aprobado sin observaciones |
| 2 | `consejo_2` | 0,60 | Aprobado |
| 1 | `consejo_1` | 0,30 | Aprobado con observaciones |
| 0 | `consejo_0` | 0,00 | Aprobado con condiciones |

Al presentar, en este orden:
1. `plan.presentar(resultados)` y guardar el detalle.
2. Completar `tr_consejo` (una vez; SceneMapaMundo encola `guardar_progreso`).
3. `registrar_decision("tr_consejo", "consejo_N")` — sin opción contraproducente.
4. `registrar_sinergia(...)` por cada cruce del plan final (después del paso 2: el
   servidor exige `tr_consejo` en `misiones_estudiante`; la cola de SupabaseManager
   es FIFO).

Pantalla de resultado: nombre, aciertos, **"Calificación estimada del plan
(Decisiones de Transporte): X,XX de 5"** calculada en el cliente con la misma fórmula
del servidor (el número oficial es el del panel GreenMetric), resumen por objeción
y cruces ganados. Si la calificación no quedó registrada (sin red/sesión): aviso y
botón **"Reintentar registro"** (manual).

El Consejo nunca bloquea el nivel: con 0 aciertos la misión igual se completa.

## 8. Regla Mixta en la interfaz (panel de decisión)

Mismo patrón de interacción que `simulador_decision.gd` (consecuencias solo después
de confirmar), con estados:

| Estado | Qué se ve | Botón principal |
|---|---|---|
| `eligiendo` | Contexto, pregunta, 3 botones con texto; debajo de cada uno **solo "Costo: N"** (si la decisión ya estaba resuelta: las consecuencias de las 3, ya vistas). Descartadas: "Descartada: es contraproducente." Sin presupuesto: "No alcanza el presupuesto (faltan N)." | "Confirmar decisión" / "Cambiar decisión" (deshabilitado sin elección o si es la opción actual) |
| `esperando` | "Registrando tu decisión…"; opciones y cerrar deshabilitados | "Registrando…" (deshabilitado) |
| `revelado_contra` | Consecuencias **solo** de la elegida + "Opción contraproducente: -1 en Decisiones de Transporte. El presupuesto no se gastó; puedes reintentar." (variantes: sin penalización extra por tope de 3; sin sesión) | "Reintentar" |
| `revelado_valida` | "Decisión registrada. Así quedan las tres opciones:" + consecuencias de las 3, la elegida resaltada | "Listo" |
| `solo_lectura` | Plan presentado, o modo Consejo sin cambios disponibles | "Listo" |

Consecuencias de una opción: `Transporte +0,60 · Aceptación media · Costo 10`
(o `Contraproducente según GreenMetric · Costo 14`), la explicación y, si tiene
cruce, `✨ Cruce: 📚 Educación +1 (se suma cuando el Consejo aprueba el plan)`.

**Respuesta de `registrar_decision`** (llega por `PuntajeManager.decision_resuelta`):

| Respuesta | Qué hace el panel |
|---|---|
| `{ok:true, contraproducente:true, penalizado:true}` | Descarta la opción, `revelado_contra` con "-1" |
| `{ok:true, contraproducente:true, penalizado:false}` | Igual, con "ya tenías el máximo de 3 penalizaciones" |
| `{ok:true, contraproducente:false}` | `plan.aplicar_valida`, `revelado_valida` |
| `{ok:false, error:"sin_sesion"}` | Modo local (escena corrida desde el editor): usa la marca `contraproducente` de los datos, sin penalización |
| `{ok:false, error:otro}` (red, HTTP, `opcion_inexistente`) | Vuelve a `eligiendo`, **no aplica nada**, mensaje "No se pudo registrar la decisión… vuelve a confirmar"; **nunca reintenta solo** |

Si el servidor y los datos locales discrepan sobre `contraproducente`, manda el
servidor (la prueba de espejo evita que pase).

## 9. Persistencia: `detalles_estudiante`, clave `plan_movilidad`

Se guarda con `NivelManager.guardar_detalle("plan_movilidad", plan.a_detalle())`
(archivo local + `guardar_detalle` en el servidor vía PuntajeManager) después de:
aceptar el encargo, cada respuesta de decisión (válida o contraproducente), presentar
y confirmar el registro de la calificación.

```json
{
  "version": 1,
  "encargo_aceptado": true,
  "presupuesto": {"total": 100, "comprometido": 100},
  "decisiones": {
    "tr_permisos": {"opcion": "permiso_por_necesidad", "costo": 8,
                    "contraproducentes": ["pintar_mas_puestos"], "cambios": 0},
    "tr_carpool":  {"opcion": "puestos_3_ocupantes", "costo": 6,
                    "contraproducentes": [], "cambios": 1}
  },
  "cambios_en_consejo": 1,
  "consejo": {
    "presentado": true,
    "aciertos": 2,
    "calificacion": "consejo_2",
    "objeciones": [
      {"decision": "tr_permisos", "opcion": "permiso_por_necesidad",
       "primer_argumento": 1, "correcto_primer_intento": true, "intentos": 1},
      {"decision": "tr_carpool", "opcion": "puestos_3_ocupantes",
       "primer_argumento": 0, "correcto_primer_intento": false, "intentos": 2},
      {"decision": "tr_dia_sin_carros", "opcion": "jornada_mensual_con_feria",
       "primer_argumento": 1, "correcto_primer_intento": true, "intentos": 1}
    ],
    "sinergias": ["ciclovia_lote", "dia_sin_carros_feria", "flota_electrica",
                  "bicicletero_techado_solar"],
    "registrado": true
  }
}
```

- `decisiones` puede tener entradas con `"opcion": ""` (solo contraproducentes probadas).
- `consejo` es `{}` hasta presentar.
- **Al cargar**, el costo se toma de los datos (no del JSON), se ignoran decisiones
  u opciones desconocidas y una opción contraproducente guardada como elegida se
  trata como vacía. `presupuesto` es informativo (para la tesis); se recalcula.
- Tamaño con el plan completo: ~1,5 KB (límite 8 KB, verificado en prueba).
- **Restauración tardía:** si el detalle llega del servidor después de abrir el mapa
  (timeout de login), el controlador recarga el plan desde `NivelManager` la
  primera vez que se interactúa y el plan local está vacío.
- **Limitación documentada:** el presupuesto lo calcula el cliente (no es moneda);
  cada opción sí se valida en `registrar_decision` contra el catálogo.

## 10. Servidor

Sin funciones nuevas: se usan `registrar_decision`, `registrar_sinergia`,
`guardar_detalle` y `puntaje_greenmetric` tal como están. Copia versionada en
`sql/nivel5_plan_movilidad.sql` con dos migraciones.

### 10.1 Migración `nivel5_plan_movilidad_catalogos` (se aplica al implementar)

`catalogo_decisiones` (categoría 5), 28 filas:

| decision_id | opcion_id | puntos | contraproducente | costo |
|---|---|---|---|---|
| tr_permisos | permiso_por_necesidad | 0.60 | false | 8 |
| tr_permisos | lectoras_de_placas | 0.25 | false | 24 |
| tr_permisos | pintar_mas_puestos | 0.00 | true | 14 |
| tr_lote | ciclovia_arborizada | 0.60 | false | 22 |
| tr_lote | plaza_de_eventos | 0.35 | false | 12 |
| tr_lote | asfaltar_lote | 0.00 | true | 16 |
| tr_carpool | puestos_3_ocupantes | 0.60 | false | 6 |
| tr_carpool | app_carpool | 0.35 | false | 26 |
| tr_carpool | vender_puestos_reservados | 0.00 | true | 0 |
| tr_shuttle | ruta_a_paradas | 0.60 | false | 26 |
| tr_shuttle | park_and_ride | 0.40 | false | 34 |
| tr_shuttle | bono_gasolina | 0.00 | true | 10 |
| tr_dia_sin_carros | jornada_mensual_con_feria | 0.60 | false | 10 |
| tr_dia_sin_carros | cierre_semanal | 0.40 | false | 28 |
| tr_dia_sin_carros | motos_por_la_acera | 0.00 | true | 4 |
| tr_flota | carritos_electricos | 0.60 | false | 18 |
| tr_flota | triciclos_de_carga | 0.40 | false | 8 |
| tr_flota | camioneta_diesel | 0.00 | true | 20 |
| tr_bici_bloque_e | techado_con_panel | 0.20 | false | 5 |
| tr_bici_bloque_e | simple_con_candado | 0.10 | false | 2 |
| tr_bici_bloque_e | sobre_el_sendero | 0.00 | true | 1 |
| tr_bici_cafetin | techado_con_panel | 0.20 | false | 5 |
| tr_bici_cafetin | simple_con_candado | 0.10 | false | 2 |
| tr_bici_cafetin | sobre_el_sendero | 0.00 | true | 1 |
| tr_consejo | consejo_3 | 1.00 | false | 0 |
| tr_consejo | consejo_2 | 0.60 | false | 0 |
| tr_consejo | consejo_1 | 0.30 | false | 0 |
| tr_consejo | consejo_0 | 0.00 | false | 0 |

`catalogo_sinergias`, 4 filas (todas con `requisito_mision = 'tr_consejo'`):

| accion_id | categoría | puntos |
|---|---|---|
| ciclovia_lote | 1 Entorno | 1 |
| flota_electrica | 2 Energía | 1 |
| dia_sin_carros_feria | 6 Educación | 1 |
| bicicletero_techado_solar | 2 Energía | 1 |

Solo agrega filas: el juego publicado no las usa, así que aplicarla no cambia nada
para los jugadores actuales.

### 10.2 Migración `nivel5_plan_movilidad_misiones` (se aplica al publicar)

- Borra de `catalogo_misiones` los 8 IDs viejos: `mov_parqueo`, `mov_shuttle`,
  `mov_ciclovia`, `mov_dia_sin_carros`, `mov_zev`, `mov_carpool`,
  `bicicletero_bloque_e`, `bicicletero_cafetin`.
- Inserta los 9 nuevos (`categoria 5`, `tipo 'mision'`, `preguntas 0`):
  `tr_permisos`, `tr_lote`, `tr_carpool`, `tr_shuttle`, `tr_dia_sin_carros`,
  `tr_flota`, `tr_bici_bloque_e`, `tr_bici_cafetin`, `tr_consejo`.
- Las filas de `misiones_estudiante` con IDs viejos **no se tocan** (son historia y
  sostienen el legado del cliente). No cuentan para el Avance nuevo.
- Se prueba en un bloque `DO` que aplica las sentencias, verifica y termina en
  excepción (no queda nada). Se aplica de verdad junto con el re-export web del
  cliente nuevo, con OK del usuario.

### 10.3 Espejo cliente/servidor

- `plan_movilidad_datos.gd` ↔ `catalogo_decisiones`/`catalogo_sinergias`: la prueba
  del controlador lee `sql/nivel5_plan_movilidad.sql` y compara id, puntos,
  contraproducente y costo de las 28 filas y las 4 sinergias.
- `NivelManager.MISIONES_NIVEL[5]` ↔ `catalogo_misiones` categoría 5 (comentario en
  ambos lados, como hoy).

## 11. Misiones, XP/EC y legado

- `NivelManager.MISIONES_NIVEL[5]` = los 9 `tr_*` (orden de §10.2);
  `TOTAL_MISIONES[5] = 9`.
- `NivelManager.MISIONES_LEGADO` deja de ser alias de `MISIONES_NIVEL`: se escribe
  completo, igual en 1–4 y 6, y `MISIONES_LEGADO[5]` = los 8 IDs viejos.
- Efecto: quien superó el Nivel 5 viejo **mantiene desbloqueado el Nivel 6**
  (`nivel_superado`), pero el Nivel 5 aparece reabierto (`nivel_completo` falso,
  avance 0/9) hasta que haga el plan. Quien lo tenía a medias debe hacer el nuevo
  para desbloquear el 6.
- Cada `tr_*` paga `XP_POR_MISION[5]` (35) y `EC_POR_MISION[5]` (12) **una vez**
  (primera opción válida; el Consejo al presentar). Sin cambios en
  `guardar_progreso_modulo` ni en `acreditar_mision` (validan por ID registrado, no
  por catálogo).
- **Jugadores con el Nivel 5 viejo completo no cobran de nuevo** (decisión del
  usuario 2; detalle en §11.1).

### 11.1 Sin re-pago de XP/EC a quien completó el Nivel 5 viejo

**Regla.** Si `NivelManager.legado_completo(5)` es verdadero, las misiones `tr_*`
**no pagan XP ni EcoCredits** y completar el Nivel 5 nuevo **no paga el bono de
nivel**. Todo lo demás es igual: la misión se marca completa, se guarda en el
servidor (Avance de Transporte, requisito `tr_consejo` de los cruces), cuenta para
`nivel_completo(5)`, suma decisiones/sinergias y muestra el aviso de misión.

**`NivelManager.legado_completo(n) -> bool`** (nuevo): verdadero si
`misiones_legado[n]` es distinto de `misiones_nivel[n]` y todas las misiones del
legado están hechas. Para los niveles 1–4 y 6 (legado = actual) siempre es falso,
así que su bono no cambia. Como las misiones `mov_*` ya no se pueden completar con
el cliente nuevo, el valor no cambia durante la partida: da igual evaluarlo antes o
después de empezar el plan.

**Dónde se decide (cliente, en el momento de pagar):**

| Paso | Archivo | Con legado completo | Sin legado completo |
|---|---|---|---|
| Monto de la misión | `nivel5_movilidad.gd` `_completar()` | emite `mision_completada(id, 0, 0)` | emite `mision_completada(id, 35, 12)` |
| XP local | `SceneMapaMundo._on_movilidad_completado` | no llama `aplicar_bono_xp` ni `_aplicar_xp` | igual que hoy |
| EC | `SceneMapaMundo._on_movilidad_completado` | **no llama** `EconomiaManager.acreditar_mision` → nunca se encola la RPC `acreditar_mision` (es la única vía por la que el servidor paga EC de misión) | igual que hoy |
| Progreso | `SupabaseManager.guardar_progreso(5, id, pct, xp, completo)` | **se llama siempre**, con `xp = 0` → `guardar_progreso_modulo` registra la misión y no suma XP | con el XP de la misión |
| Aviso | `_mostrar_mision_completada(id, xp)` | se muestra con "+0 XP" | igual que hoy |
| Bono de nivel | `SceneMapaMundo._on_nivel_greenmetric_completado` | no llama `ganar_creditos(bonus, "nivel", "5")`; la celebración sí se muestra | igual que hoy |

Regla en `SceneMapaMundo`: `xp <= 0 and ec <= 0` = misión sin pago. No se cambia
ninguna función del servidor.

**Limitación:** es una decisión del cliente (mismo modelo de confianza que el XP);
un cliente modificado podría cobrar. Para quien tenía el Nivel 5 viejo a medias
(legado incompleto) se paga normal, aunque haya cobrado algunas `mov_*`.

## 12. Cambios visibles en el mapa

Nodo `scenes/mapa/cambios_movilidad.gd` (`Node2D`, hijo de SceneMapaMundo, debajo de
los puntos) que dibuja con `_draw` (sin sprites, mismo estilo procedural que
`mapa_campus.gd`) según el plan. Cada elemento se ubica con
`LUGARES.posicion(lugar, DESPLAZAMIENTO[elemento])`. La lista de elementos sale de
una función pura `elementos()` (probada sin dibujar).

| Plan | Elemento | Lugar | Dibujo |
|---|---|---|---|
| siempre | `autos_m5` | `estacionamiento_m5` | Grilla de carritos de colores: `8 − reducciones` (mín. 1). Reducen: permisos por necesidad 3, 3+ 2, app 1, busetas a paradas 2, estacionamiento externo 2 |
| lote sin decidir | `lote_vacio` | `lote_este` | Rectángulo de tierra con líneas de puesto tenues |
| `ciclovia_arborizada` | `ciclovia` | `lote_este` | Césped, franja gris con línea discontinua verde, 6 copas de árbol |
| `plaza_de_eventos` | `plaza` | `lote_este` | Piso claro con 4 bolardos |
| `puestos_3_ocupantes` | `senal_carpool` | `estacionamiento_m5` | Cartel "3+" verde |
| `app_carpool` | `cartel_app_carpool` | `estacionamiento_m5` | Cartel "CARPOOL" cian |
| `permiso_por_necesidad` | `cartel_permisos` | `garita_m5` | Cartel "PERMISOS" dorado |
| `lectoras_de_placas` | `barrera_placas` | `garita_m5` | Barrera roja/blanca y caja de cámara |
| `ruta_a_paradas` / `park_and_ride` | `buseta` | `parada_rectorado` | Buseta violeta con ventanas y poste de parada |
| `jornada_mensual_con_feria` | `cartel_dia_sin_carros` | `porton_vehicular` | Cartel "DÍA SIN CARROS" |
| `cierre_semanal` | `cartel_viernes_sin_carros` | `porton_vehicular` | Cartel "VIERNES SIN CARROS" |
| `carritos_electricos` | `carrito_electrico` | `zona_mantenimiento` | Carrito blanco con rayo dorado (polilínea) |
| `triciclos_de_carga` | `triciclos` | `zona_mantenimiento` | Tres triciclos naranja |
| `techado_con_panel` | `bicicletero_techado` | lugar de cada bicicletero | Soportes en U, techo, panel azul y luz |
| `simple_con_candado` | `bicicletero_simple` | lugar de cada bicicletero | Soportes en U |

Colores de acento tomados de `hud_tema.gd`. Las contraproducentes nunca se dibujan
(no quedan elegidas). Se redibuja solo cuando cambia el plan.

## 13. Interfaz

- **Puntos** (`scenes/misiones/punto_movilidad.gd`, un script para los 4 tipos:
  `oficina`, `decision`, `bicicletero`, `consejo`): `Area2D` en el grupo
  `punto_movilidad`, radio 55, ubicado por `lugar` + `desplazamiento`, ícono dibujado
  por tipo (caseta, cartel, bicicletero, edificio con columnas) con estado
  `bloqueado` (gris, sin brillo), `pendiente` (brillo que late) o `resuelto` (tilde
  verde). Cartel flotante con `HUD_TEMA.caja` y textos "E · Decidir — …", "E ·
  Revisar decisión — …", "🔒 Primero pasa por la Oficina de Movilidad", "🔒 El Consejo
  recibe el plan con las 8 decisiones listas", etc. Solo el estado `pendiente`
  redibuja cada frame (rendimiento web).
- **Paneles** (`panel_decision_movilidad.gd`, `panel_oficina_movilidad.gd`,
  `panel_consejo_movilidad.gd`): `CanvasLayer` capa 20, fondo oscuro, panel centrado
  que se ajusta al contenido, construidos con `scenes/misiones/ui_movilidad.gd`, que
  solo usa tokens de `hud_tema.gd` (`panel(VIOLETA)`, `caja`, `label`, `rubik`,
  colores `TEXTO*`, `VERDE`, `NARANJA`, `VIDAS`, `DORADO`). **Ningún `Color(...)`
  literal en los paneles.** Emoji solo de `EMOJIS_HUD`.
- **Teclado:** mientras un panel del nivel está abierto, `E` y los atajos 1–5 no
  abren otra cosa (`_hay_ui_modal_abierta` y el manejo de `E` consultan
  `hay_panel_abierto()`).
- **Controlador** (`scenes/misiones/nivel5_movilidad.gd`, `Node`): tiene el plan,
  crea los 10 puntos y el nodo de cambios, abre los paneles, guarda el detalle,
  completa misiones, registra decisiones/sinergias/telemetría y emite
  `mision_completada(mision_id, xp, ec)` (0 y 0 si `legado_completo(5)`, §11.1), que
  SceneMapaMundo conecta a su `_on_movilidad_completado` (XP y EC solo si hay pago;
  `guardar_progreso` y aviso siempre). Dependencias
  inyectadas (`configurar(mapa, NivelManager, PuntajeManager, SupabaseManager)`) para
  probarlo sin red.

## 14. Telemetría (`eventos_aprendizaje`, nivel 5)

| tipo_evento | mision_id | detalle | correcto | intento_num |
|---|---|---|---|---|
| `encargo_aceptado` | `plan_movilidad` | `{}` | null | null |
| `mision_iniciada` | decisión | `{}` (solo si no estaba resuelta) | null | null |
| `decision_tomada` | decisión | `{decision_id, opcion_id, contraproducente, costo, presupuesto_restante, ms_hasta_elegir}` (§6.5 alto nivel) | `not contraproducente` | null |
| `argumento_consejo` | `tr_consejo` | `{decision_id, opcion_id, argumento}` | acierto | número de intento en esa objeción |
| `plan_presentado` | `tr_consejo` | `{aciertos, calificacion, presupuesto_restante, sinergias}` | null | null |

Disparar y olvidar; el puntaje nunca depende de la telemetría.

## 15. Casos borde

| Caso | Comportamiento |
|---|---|
| Contraproducente y reintento | El costo nunca se compromete; el presupuesto mostrado no cambia; la opción queda descartada en esa decisión |
| 4.ª contraproducente en la misma decisión | Imposible desde la interfaz (descartada); si el servidor responde `penalizado:false`, se informa el tope |
| Falla de red al confirmar | No se aplica nada, no se reintenta solo; el jugador vuelve a confirmar |
| Falla de red después de un registro válido en el servidor pero antes de la respuesta | `_emitir_fallo` responde `{ok:false,error:"red"}`: el panel no aplica; al reconfirmar la misma opción, el servidor reemplaza la fila (idempotente para válidas). Si era contraproducente, puede sumarse una penalización (máx. 3): riesgo aceptado |
| Cerrar el panel mientras espera | Deshabilitado ("Cerrar" inactivo en `esperando`) |
| Reabrir una decisión resuelta | Muestra las consecuencias ya vistas y la opción actual resaltada; elegir otra y "Cambiar decisión" registra de nuevo; la misión no vuelve a pagar |
| Sin presupuesto para una opción | Botón deshabilitado con "No alcanza el presupuesto (faltan N)"; se libera cambiando otra decisión (desde su lugar o, en el Consejo, con "Cambiar"). Siempre existe un plan válido: el más barato cuesta 74 |
| Bicicletero sin kit | Aviso de `_verificar_herramienta` y se abre la Tienda; no se abre el panel |
| Interactuar antes del encargo | Punto bloqueado, el cartel lo explica, no abre nada |
| Consejo con decisiones pendientes | Punto bloqueado, no abre |
| Plan ya presentado | Decisiones de solo lectura; el Consejo muestra el resultado y reenvía las sinergias del plan (idempotente) |
| Calificación del Consejo sin registrar | Botón "Reintentar registro" (manual) |
| Sin sesión (escena desde el editor) | Todo funciona en local con los datos; sin puntos ni penalizaciones en servidor |
| Detalle restaurado tarde | El plan se recarga en la primera interacción si el local está vacío |
| Jugador con Nivel 5 viejo completo | Nivel 6 sigue desbloqueado; Nivel 5 reabierto con 10 puntos nuevos; misiones y bono de nivel sin XP/EC (§11.1), Avance y puntaje normales |
| Jugador con Nivel 5 viejo a medias | Paga XP/EC normal por las `tr_*` |
| Respuestas de `decision_resuelta` de otra decisión | El panel las ignora (compara decision_id y opcion_id y el estado `esperando`) |

## 16. Criterios de aceptación

**Lugares**
- `tests/test_lugares_campus.tscn` pasa: 10 lugares, coordenadas heredadas iguales a
  las actuales, ≥ 55 px a todo punto existente y entre sí, fuera de edificios.
- Cambiar una coordenada de `LUGARES` mueve el punto y su cambio de mapa sin tocar
  otro archivo.

**Datos**
- 8 decisiones × 3 opciones, exactamente 1 contraproducente por decisión, IDs
  `^[a-z0-9_]{1,60}$`, textos no vacíos.
- Mejores opciones = 4,00; + Consejo = 5,00; plan de mayor puntaje cuesta 100; opción
  más cara válida por decisión suma 162; plan válido más barato ≤ 100.
- Cada opción válida tiene 1 objeción con 3 argumentos y exactamente 1 correcto;
  las contraproducentes no tienen.

**Lógica**
- Presupuesto, `alcanza`/`faltante`, descartes, cambios (máx. 2 en Consejo),
  selección de objeciones (ejemplos de §7.2), calificación estimada, sinergias y
  serialización (ida y vuelta, < 8 KB, tolerante a datos corruptos) probados sin interfaz.

**Servidor**
- Migración 1 aplicada; bloque `DO` termina en `PRUEBA_OK`: suma de mejores = 5,00,
  1 contraproducente por decisión (0 en el Consejo), mejor plan = 100, penalización
  y reemplazo, reemplazo de la opción del Consejo, sinergia rechazada sin
  `tr_consejo` y aceptada con ella, repetir no suma.
- Bloque `DO` de la migración 2 termina en `PRUEBA_OK` (9 misiones; los IDs viejos no
  cuentan) sin aplicarla.
- `get_advisors` sin avisos nuevos.

**Interfaz**
- Antes de confirmar ninguna opción muestra Transporte ni aceptación.
- Contraproducente: revela solo esa, no gasta, permite reintentar, queda descartada.
- Error de red: no aplica, no vuelve a llamar solo.
- Válida: revela las 3; la misión se completa una sola vez.
- Paneles sin `Color(` literal.

**Consejo**
- 3 objeciones según §7.2; incorrecto → reintento en la misma; resultado con la
  calificación de §7.5; `tr_consejo` completa; `registrar_decision("tr_consejo", …)`
  y las sinergias del plan, en ese orden, después de completar la misión.

**Integración**
- `test_compila`, `test_niveles`, `test_rangos` y las pruebas nuevas pasan.
- No quedan referencias a los 4 scripts eliminados.
- Con Nivel 4 superado aparecen los 10 puntos; con el Nivel 5 viejo completo el 6
  sigue desbloqueado.
- **Sin re-pago (§11.1):** `legado_completo(5)` probado (legado completo, a medias,
  niveles con legado igual al actual); el controlador emite 35/12 sin legado y 0/0
  con legado; `SceneMapaMundo` omite `_aplicar_xp`, `acreditar_mision` y el bono de
  nivel cuando no hay pago, y siempre llama `guardar_progreso`.
- Todos los textos nuevos para el jugador usan tuteo (sin "podés", "tenés", "elegí"…).
- **Prueba del usuario con cuenta real** (tras publicar): plan completo, número de
  Transporte igual en HUD, mapa de avance, resultados e informe; decisiones y plan
  visibles en `detalles_estudiante`; sinergias en Entorno/Energía/Educación.

## 17. Fuera de alcance

- Mapa rediseñado y reubicación definitiva (solo `lugares_campus.gd` provisional).
- Migrar a `LUGARES` los puntos de otros niveles.
- Pregunta de TR8 (senderos peatonales): va en la entrega de "quizzes faltantes".
- Cambios en `ranking_publico` (sigue contando solo el catálogo vigente: quien superó
  el Nivel 5 solo por legado muestra un nivel menos en el ranking que en el HUD,
  limitación ya documentada en `sql/ranking_publico.sql`).
- Minijuegos del proyecto C (incluido el Inventario de emisiones, que leerá este plan).
- Re-export web, merge y publicación (con OK del usuario).
- Capítulo 4 de la tesis (se actualiza aparte; la matriz y `ESTADO_PROYECTO.md` sí
  se tocan en este proyecto).
- **Seguimiento (tarea chica aparte):** unificar a tuteo los textos con voseo que ya
  existen en el juego, por ejemplo "Necesitás el …" (`SceneMapaMundo._verificar_herramienta`),
  "Practicá decisiones reales del campus…" (`simulador_decision.gd`), "Probá con ↻
  Actualizar" (`leaderboard.gd`) y los del HUD/Tienda. Buscar con
  `grep -rnE "(ás|és|ís)|á |Probá|Practicá|Necesitás" scenes autoload`.

## 18. Riesgos y limitaciones

- **Presupuesto calculado en el cliente** (no es moneda). Un cliente modificado podría
  elegir todo lo caro; el servidor valida cada opción y los topes 0–5 acotan el efecto.
- **Consejo confiado al cliente:** el servidor no puede comprobar los aciertos
  (mismo modelo de confianza que los quizzes).
- **Contenido ilustrativo:** cifras del campus y costos relativos no son datos
  oficiales de URBE.
- **Espejo de datos:** si alguien cambia `plan_movilidad_datos.gd` sin migración, la
  prueba del controlador falla.
- **Sin re-pago decidido en el cliente** (§11.1): el servidor no lo impide.
- **Ventana entre migraciones:** si se aplica la migración 2 sin publicar el cliente,
  el Avance de Transporte de todos baja; por eso se aplica junto con la publicación.

## 19. Decisiones del usuario (2026-09-17)

1. **Cifras del contexto:** ilustrativas y documentadas así en el código y en la tesis.
2. **Sin re-pago de XP/EC** a quien completó el Nivel 5 viejo (conjunto legado completo):
   las `tr_*` cuentan para Avance, puntaje y completar el nivel, pero no pagan XP ni
   EcoCredits por misión ni bono de nivel. Quien no lo había completado cobra normal.
   Diseño en §11.1.
3. **Peso del Consejo:** 1,00 de los 5 puntos de Decisiones de Transporte.
4. **Plan cerrado tras el Consejo:** no se vuelve a presentar.
5. **El plan de 5,00 cuesta exactamente 100.**
6. **Migración 2:** se aplica junto con el re-export web, antes de la prueba con cuenta real.
7. **Tuteo** en todos los textos nuevos para el jugador ("tienes", "elige", "presiona",
   "puedes"). Unificar el voseo existente queda como tarea aparte (§17).
8. **Consejo con 0 aciertos:** "Aprobado con condiciones"; la misión se completa igual.
