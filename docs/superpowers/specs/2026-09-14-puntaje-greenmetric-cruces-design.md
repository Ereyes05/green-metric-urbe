# Puntaje GreenMetric unificado, cruces entre categorías y rediseño de niveles

- **Fecha:** 2026-09-14
- **Estado:** Paso 0 y proyecto A implementados (2026-09-14); verificación en juego con cuenta real pendiente (Task 10 Step 1); B y C pendientes.
- **Alcance de este documento:** hoja de ruta completa (0 → A → B → C), diseño
  detallado del **paso 0** y del **proyecto A**, y diseño de alto nivel de **B** y **C**.
  B y C reciben su propio documento detallado antes de implementarse.

---

## 1. Por qué

Evidencia recogida el 2026-09-14 (partida real de la cuenta principal + código + tesis):

1. **El Nivel 5 no mide aprendizaje.** Las 6 decisiones de movilidad se resolvieron
   en 36 segundos (2–4 s cada una), siempre con la mejor opción: el impacto
   ("+20%" en verde, "−10%" en rojo) se ve antes de elegir y la mejor opción es
   siempre la primera. Cualquier opción completa la misión y paga lo mismo;
   la telemetría guarda `correcto = null`. El bicicletero es una secuencia de
   "Continuar".
2. **Cada categoría tiene tres números distintos que no coinciden:** la barra del
   HUD (% de misiones, pisado por un ImpactRating que no se guarda), el mapa de
   calor (valores fijos inventados: 0.35, 0.40…) y el informe final / resultados
   (% de misiones).
3. **Las decisiones del Nivel 6 se guardan solo en la computadora**
   (`NivelManager._detalles` → archivo local). En otra máquina o tras borrar
   datos del navegador, el informe final dice "Sin datos".
4. **Cobertura de GreenMetric desbalanceada.** La guía oficial UI GreenMetric 2024
   tiene 51 indicadores; el juego trabaja ~17. Entorno cubre 1 de 11 (SI3,
   vegetación plantada); Transporte cubre casi todos.
5. **Idea del tutor:** misiones que suman a más de una categoría, como ocurre en
   el ranking real (una ciclovía mejora Transporte y Entorno).
6. **Tesis, Capítulo 4, Tabla 15:** ante una decisión incorrecta el sistema debe
   aplicar "penalización inmediata en la puntuación y permitir el reintento".
   **Tabla 13:** la experta prioriza simuladores de decisión sobre trivia.
   **Tabla 16:** datos mixtos (reales de URBE + metas del ranking).

## 2. Decisiones tomadas

| # | Decisión | Elegido |
|---|---|---|
| D1 | Alcance del Nivel 5 | Rehacer con Plan de Movilidad |
| D2 | Modelo de decisiones | **Mixto** — cada decisión tiene 1 opción contraproducente según GreenMetric (penaliza + reintento, cumple Tabla 15) y opciones válidas con compensaciones (costo, aceptación) |
| D3 | Presupuesto | Presupuesto de movilidad que corre durante el nivel (no son EcoCredits) + cierre en el Consejo |
| D4 | Progreso previo del Nivel 5 | Se reabre; no se bloquea nada ya desbloqueado |
| D5 | Cruces | Se aplican en todo el juego; los puntos cruzados no afectan el desbloqueo de niveles |
| D6 | Orden | 0 Matriz → A Base de puntaje → B Nivel 5 → C Minijuegos |
| D7 | Qué representa la barra de categoría | Un solo número 0–100: **avance + calidad** |
| D8 | Fuentes de calidad | Comprensión (quizzes), decisiones y sinergias |
| D9 | Cobertura | Los 51 indicadores se aprenden (quiz/ficha); los accionables se juegan |
| D10 | Minijuegos nuevos | SI7, SI10, SI11, EC8, EC2, WS3, WR2 (sección 8) |
| D11 | Mapa | El mapa se está rediseñando aparte: nada nuevo depende de coordenadas fijas (sección 4) |

## 3. Hoja de ruta

| Paso | Entrega publicable | Depende de |
|---|---|---|
| **0 Matriz de cobertura** | `docs/matriz_cobertura_greenmetric.md` (anexo para la tesis) | — |
| **A Base de puntaje** | puntaje único en servidor + HUD/mapa de calor/resultados/informe unificados; quizzes suman a Comprensión; detalles en servidor | 0 |
| **B Nivel 5 nuevo** | presupuesto, 6 decisiones repartidas, bicicleteros con decisión, Consejo, cruces de Transporte | A |
| **C Minijuegos** | 7 minijuegos, uno por entrega, con sus cruces y preguntas | A (y la matriz) |

Cada entrega se publica en la web con `scripts/exportar_web.py` y la prueba
final con cuenta real la hace el usuario; después se verifica en la base.

## 4. Restricción transversal: el mapa se está rediseñando

Un compañero rediseña el mapa del campus en otro proyecto. Hoy cada nivel
guarda posiciones fijas (`DATOS_PUNTOS_BICICLETERO` con `Vector2(1020, 460)`,
etc.), dispersas en `SceneMapaMundo.gd`.

**Regla:** todo lo nuevo (B y C) se ubica por **lugar con nombre**, nunca con
coordenadas en el código de la misión.

- Un único registro `LUGARES_CAMPUS` (constante en un script propio,
  `scenes/mapa/lugares_campus.gd`): `{"rectorado": Vector2(...), "cafetin": ...,
  "area_salud": ..., "lago": ..., "bloque_d": ..., "estacionamiento_m5": ...}`.
- Cada punto nuevo declara `lugar` + `desplazamiento` pequeño.
- Los puntos existentes se migran al registro **solo cuando se tocan** (B migra
  los de Transporte). No se hace una migración masiva ahora.
- **Criterio:** cuando llegue el mapa nuevo, reubicar lo nuevo = editar solo
  `lugares_campus.gd` y volver a correr el chequeo de solapamientos.
- **Área de salud:** junto al Rectorado, pequeña. Se usa como ubicación provisional.

## 5. Paso 0 — Matriz de cobertura

**Archivo:** `docs/matriz_cobertura_greenmetric.md`.

**Una fila por indicador (51)**, con columnas:

| Código | Indicador (español) | Puntos guía 2024 | Tratamiento | Nivel | Misión/quiz actual | Misión/quiz propuesto | Cruces | Accionable por un estudiante |

- **Tratamiento:** `misión` · `minijuego` · `decisión` · `quiz` · `ficha`.
- **Regla D9:** ningún indicador queda sin tratamiento. Los institucionales
  (SI6 presupuesto, ED2/ED3 investigación…) quedan como `quiz` o `ficha`.
- **Inventario actual detectado al diseñar** (a confirmar en la matriz):
  - Quizzes por categoría: Energía 5 (15 preguntas), Entorno 2 (6),
    Educación 2 (6), Agua 1 (3), Transporte 1 (3), Residuos 0 (el quiz
    `mision_residuos` existe pero la zona abre el minijuego).
  - `mision_bloque_g` tiene quiz pero ninguna zona lo usa.
  - Hay 7 IDs `plantar_*` en el código y `TOTAL_MISIONES[1] = 6`.
- **Salida adicional:** lista de preguntas nuevas necesarias para que la
  Comprensión cubra cada indicador (se redactan en C, junto a cada minijuego, y
  en una entrega de "quizzes faltantes").

**Criterios de aceptación**
- Las 51 filas existen, con código y puntos idénticos a la guía 2024.
- Cada fila tiene tratamiento; ninguna queda vacía.
- Los 7 indicadores de D10 aparecen como `minijuego` con sus cruces.
- Las anomalías del inventario quedan resueltas o anotadas.

## 6. Proyecto A — Base de puntaje

### 6.1 Modelo

Cada categoría vale 0–100:

| Componente | Máx. | Cálculo |
|---|---|---|
| Avance | 80 | `80 × misiones_válidas_completadas / total_misiones_categoría` |
| Comprensión | 10 | `10 × aciertos_primer_intento / total_preguntas_categoría` |
| Decisiones | 5 | `clamp(Σ puntos de decisión − penalizaciones, 0, 5)` |
| Sinergias | 5 | `clamp(Σ puntos cruzados recibidos, 0, 5)` |

> **Cambio respecto de lo conversado:** se había acordado 80+10+5+5 para
> Transporte/Educación y 80+10+10 para el resto, porque solo esas dos tenían
> decisiones. Con los minijuegos de C (D10) **las 6 categorías tienen
> decisiones**, así que el reparto queda uniforme: 80+10+5+5. Mientras C no
> esté terminado, las categorías sin decisiones tienen un techo transitorio de 95.

- **Puntos de decisión:** en `catalogo_decisiones`, la mejor opción válida de cada
  decisión de una categoría suma exactamente 5 entre todas; las otras válidas, menos;
  la contraproducente, 0 (y genera penalización).
- **Total GreenMetric** = `Σ categoría × peso / 100`, con los pesos de la guía:
  Entorno 15, Energía 21, Residuos 18, Agua 10, Transporte 18, Educación 18.
- **Desbloqueo de niveles:** sigue dependiendo solo de misiones (sección 6.4).
- **Primer intento:** en quizzes y minijuegos con aciertos, cuenta el primero;
  los reintentos se juegan pero no cambian la Comprensión.
- **Residuos:** su Comprensión sale del minijuego de clasificación (aciertos del
  primer intento / ítems) hasta que tenga quiz propio.
- **Una sinergia se gana una vez por acción** (id único), no por repetición.

### 6.2 Servidor (Supabase)

Mismo patrón que la tienda: RLS en todas las tablas, el cliente solo lee lo
propio y escribe mediante funciones `SECURITY DEFINER` con `search_path` fijo.
Copia versionada en `sql/puntaje_greenmetric.sql`.

**Catálogos** (lectura pública, escritura solo por migración):

- `catalogo_misiones(mision_id pk, categoria int, tipo text, preguntas int)` —
  `tipo ∈ {mision, quiz, minijuego}`; `preguntas` para quizzes y minijuegos con aciertos.
  Solo `tipo = mision|minijuego` cuenta para Avance.
- `catalogo_sinergias(accion_id, categoria, puntos, requisito_mision text null)`,
  pk `(accion_id, categoria)`. Ej.: `riego_agua_reciclada` → (Agua, 1), (Entorno, 1),
  requisito `aguas_grises`.
- `catalogo_decisiones(decision_id, opcion_id, categoria, puntos, contraproducente bool, costo int)`,
  pk `(decision_id, opcion_id)`.

**Datos del estudiante:**

- `detalles_estudiante(user_id, clave, detalle jsonb, actualizado_en)`, pk
  `(user_id, clave)`; tamaño máximo de `detalle` 8 KB.
- `puntos_calidad(id, user_id, categoria, componente, puntos, ref, creado_en)`,
  único `(user_id, ref, categoria)`; `componente ∈ {comprension, decision, sinergia}`.

**Funciones:**

| Función | Comportamiento |
|---|---|
| `guardar_detalle(p_clave, p_detalle)` | upsert; clave `^[a-z0-9_:.-]{1,80}$` |
| `obtener_detalles()` | todos los detalles propios (para restaurar al iniciar sesión) |
| `registrar_quiz(p_mision_id, p_aciertos)` | valida contra `catalogo_misiones`; `0 ≤ aciertos ≤ preguntas`; inserta en `puntos_calidad` (`componente = comprension`, `puntos = aciertos`, `ref = quiz:<mision_id>`); **si ya existe, no hace nada** (primer intento). La normalización a 10 la hace `puntaje_greenmetric` |
| `registrar_decision(p_decision_id, p_opcion_id)` | opción válida → reemplaza la fila `ref = decision:<id>` con sus puntos (borra la anterior aunque fuera de otra categoría); contraproducente → inserta penalización `ref = penal:<id>:<n>` (−1, máx. 3 por decisión) y devuelve `{ok:true, contraproducente:true, penalizado}` para que el cliente ofrezca reintento (`ok:false` queda para errores reales, p. ej. `opcion_inexistente`) |
| `registrar_sinergia(p_accion_id)` | valida catálogo y `requisito_mision` en `misiones_estudiante`; inserta una fila por categoría con `ref = sinergia:<accion>`; repetir no suma |
| `puntaje_greenmetric()` | devuelve `{categorias: {1: {avance, comprension, decisiones, sinergias, total}, …}, total}` |

Errores: `42501` sin sesión; respuestas `{ok:false, error:…}` para catálogo
inexistente, requisito incumplido y valores fuera de rango (mismo estilo que
`comprar_item`).

### 6.3 Cliente (Godot)

**Nuevo autoload `PuntajeManager`:**
- Estado: `desglose` (por categoría), `total`.
- Señal `puntaje_actualizado(desglose, total)`.
- API: `cargar()`, `registrar_quiz(mision_id, aciertos)`,
  `registrar_decision(decision_id, opcion_id) -> resultado`,
  `registrar_sinergia(accion_id)`, `categoria(n) -> float`, `total() -> float`.
- Optimista con reconciliación, como `EconomiaManager`: aplica el cambio local y
  se alinea con `puntaje_greenmetric()` cuando no quedan operaciones en vuelo.
- `cargar()` se llama al iniciar sesión, después de restaurar misiones y billetera.

**Integraciones (todas pasan a leer `PuntajeManager`):**
- Barra del HUD: `SceneMapaMundo._progreso_modulos` / `_actualizar_sidebar`.
- Mapa de calor: `mapa_campus.impacto` (se eliminan los valores fijos).
- Pantalla de resultados: `resultados_greenmetric.gd`.
- Informe final: `mision_informe_final.gd` (reemplaza `pct_nivel × PESOS`).
- Se elimina el ImpactRating de las barras: `EconomiaManager.impacto`,
  `actualizar_impacto` en crisis, simulador y `on_modulo_completado`. Crisis y
  simulador siguen dando EC.
- `quiz_npc.gd` llama a `registrar_quiz` al terminar el **primer** intento.
- `minijuego_residuos.gd` registra aciertos para la Comprensión de Residuos.
- **Aviso de sinergia** en pantalla al ganar un cruce: "✨ Sinergia: 🌿 +1 💧 +1".
- `NivelManager` guarda y lee detalles en el servidor (el archivo local queda
  como caché). **Migración:** al iniciar sesión, los detalles locales que el
  servidor no tenga se suben una vez (rescata las decisiones del Nivel 6 ya tomadas).
- **Espejo de constantes:** `catalogo_misiones` refleja `NivelManager.TOTAL_MISIONES`
  y las listas de IDs; si cambia uno hay que cambiar el otro (igual que
  `_ec_por_modulo` / `EC_POR_MISION`).

### 6.4 Reapertura de niveles sin bloquear lo ya desbloqueado

B y C agregan o reemplazan misiones en niveles que algunos ya completaron.

- `NivelManager.MISIONES_NIVEL[n]`: lista explícita de IDs válidos por nivel.
  `nivel_completo(n)` cuenta solo esos (hoy cuenta cualquier ID guardado).
- `NivelManager.MISIONES_LEGADO[n]`: el conjunto de IDs con el que el nivel se
  consideraba completo antes del cambio.
- `nivel_superado(n) = nivel_completo(n) or todas(MISIONES_LEGADO[n])`.
- `nivel_desbloqueado(n) = n == 1 or nivel_superado(n - 1)`.
- `nivel_actual` y los avisos de "nivel completado" usan `nivel_completo`
  (lo nuevo queda pendiente); el desbloqueo usa `nivel_superado`.
- En A, `MISIONES_LEGADO` coincide con `MISIONES_NIVEL` (no cambia nada). B y C lo aprovechan.

### 6.5 Telemetría (`eventos_aprendizaje`)

- `respuesta_quiz` y `tiempo_agotado` ya existen; se agrega `detalle.intento_quiz` (1 = primer intento, 2 = repetición). `intento_num` no cambia: ya guarda el número de pregunta.
- `decision_tomada` lo emiten B y C (necesita costo y presupuesto del llamador); A deja lista la función `registrar_decision`.
- `sinergia_obtenida`: `{accion_id, categorias}`.
- `decision_tomada`: `{decision_id, opcion_id, contraproducente, costo, presupuesto_restante, ms_hasta_elegir}`, con `correcto = not contraproducente`.

La telemetría sigue siendo "disparar y olvidar"; **el puntaje nunca depende de ella**.

### 6.6 Pruebas y criterios de aceptación de A

**Servidor**, en bloques que terminan en excepción para no dejar datos:
1. Todas las funciones devuelven `42501` sin sesión.
2. `registrar_quiz`: el segundo registro de la misma misión no cambia el valor;
   aciertos fuera de rango rechazados; misión inexistente rechazada.
3. `registrar_sinergia`: sin requisito → rechazada; con requisito → suma; repetir no suma;
   acción inexistente rechazada.
4. `registrar_decision`: válida suma; contraproducente penaliza −1 y marca
   `contraproducente`; más de 3 penalizaciones en la misma decisión no restan más;
   cambiar a otra opción válida reemplaza los puntos (upsert).
5. `puntaje_greenmetric`: topes 80/10/5/5, nunca negativo, total ponderado correcto.
6. Un usuario no puede leer detalles ni puntos de otro.
   *(Verificado 2026-09-14: con una fila de detalle y una de puntos de la
   cuenta de prueba, la sesión de la cuenta principal ve 0 y 0; la del dueño
   ve 1 y 1. Bloque terminado en excepción, tablas en 0 filas al final.)*
7. `get_advisors` sin alertas nuevas de seguridad.

**Cliente:**
1. Prueba sin interfaz de `nivel_superado`/`nivel_desbloqueado` con listas de legado.
2. Captura del HUD con la cuenta principal: categorías con misiones completas en
   80 + comprensión + decisiones + sinergias reales, **igual número** en HUD, mapa
   de calor, resultados e informe.
3. Tras iniciar sesión en otra máquina o en la web, las decisiones del Nivel 6
   aparecen en el informe (detalles restaurados).
4. Repetir un quiz no cambia la Comprensión.

### 6.7 Fuera de alcance de A

Cruces jugables (los catálogos arrancan con los quizzes existentes y sin
sinergias), cambios de contenido en niveles, ubicación en el mapa nuevo.

## 7. Proyecto B — Nivel 5 nuevo (alto nivel)

- **Inicio:** la Oficina de Movilidad da el encargo ("presentar un Plan de
  Movilidad al Consejo Universitario") y un **presupuesto de 100 puntos**.
- **Seis decisiones en su lugar** (vía `LUGARES_CAMPUS`): permisos, lote poco
  usado, carpool (Estacionamiento M5), shuttle (parada frente al Rectorado),
  día sin carros (portón vehicular), flota (zona de mantenimiento). Orden libre.
- **Cada decisión:** 3 opciones que muestran solo su costo antes de elegir.
  1 contraproducente (penaliza, reintento, se devuelve el presupuesto) y 2
  válidas con compensaciones distintas. Tras confirmar se ven Transporte,
  aceptación, costo, explicación GreenMetric y **cruces**. Las opciones fuertes
  suman ~160 frente a 100 de presupuesto.
- **Cambios visibles en el mapa** según lo elegido (lote → ciclovía, bus del
  shuttle, menos carros en M5, cartel del día sin carros, vehículo eléctrico,
  señal carpool 3+), anclados a lugares.
- **Bicicleteros:** siguen exigiendo el kit; la secuencia de "Continuar" se
  reemplaza por una decisión de tipo (techado con luz/panel vs. simple) que paga
  del presupuesto.
- **Consejo (Rectorado):** plan completo; cambiar hasta 2 decisiones si alcanza
  el presupuesto; 3 objeciones sobre los puntos débiles reales del plan; el
  estudiante elige argumentos (`correcto` true/false). Resultado = calificación
  del plan (componente Decisiones de Transporte).
- **Misiones:** `tr_permisos`, `tr_lote`, `tr_carpool`, `tr_shuttle`,
  `tr_dia_sin_carros`, `tr_flota`, `tr_bici_bloque_e`, `tr_bici_cafetin`,
  `tr_consejo` (9). `MISIONES_LEGADO[5]` = los 6 `mov_*` + 2 bicicleteros actuales.
- **Cruces de Transporte:** ciclovía → Entorno; flota eléctrica → Energía;
  día sin carros → Educación (evento); bicicletero techado con panel → Energía.
- **Datos:** decisiones, presupuesto y argumentos en `detalles_estudiante`
  (`plan_movilidad`). El presupuesto lo calcula el cliente (no es moneda;
  limitación documentada), pero cada opción se valida en `registrar_decision`.
- Se reemplazan `mision_movilidad.gd` y `oficina_movilidad.gd`.

## 8. Proyecto C — Minijuegos (alto nivel)

Estructura común: CanvasLayer propio, se abre desde un punto anclado a un lugar,
usa `registrar_decision` para la opción contraproducente (penaliza + reintento),
`registrar_sinergia` para sus cruces, registra aciertos del primer intento y
suma preguntas nuevas al quiz de su categoría para cubrir su indicador.

| # | Indicador | Minijuego | Lugar | Contraproducente | Cruces |
|---|---|---|---|---|---|
| 1 | WS3 Orgánicos | **Compostera del Cafetín**: equilibrar verdes/marrones, humedad, volteo → abono | Cafetín | echar carne/grasa/lácteos | abono en árboles del Nivel 1 → Entorno |
| 2 | WR2 Aguas grises | **Circuito de aguas grises**: rompecabezas de tuberías lavamanos → filtro → tanque → riego/inodoros | Patio | conectar aguas grises al bebedero | riego con agua reciclada → Agua + Entorno |
| 3 | EC8 Huella de carbono | **Inventario de emisiones**: barra por fuente; lo hecho en otros niveles la baja; reducciones con presupuesto | Rectorado | compensar con bonos sin reducir / omitir transporte | centro de cruces: lee LED, Plan de Movilidad, reciclaje |
| 4 | EC2 Edificio inteligente | **Sala de control del Bloque E**: día acelerado; el control de acceso da ocupación; reglas de apagado, 24 °C, luz natural | Bloque E | AC a 18 °C todo el día / apagar todo | kWh ahorrados bajan la huella (#3) |
| 5 | SI7 Mantenimiento | **Órdenes de trabajo**: 40 h de cuadrilla/semana, preventivo vs correctivo, simulación de un mes | Bloque D | pintar fachada antes que reparar filtración | AC atendido → Energía; filtración → Agua |
| 6 | SI11 Flora y fauna | **Censo del Lago URBE**: registrar especies nativas/exóticas; vivero para reforestar | Lago | reforestar con exóticas de alto riego | nativas → Agua |
| 7 | SI10 Salud | **Campus saludable**: ubicar bebederos, sombra, botiquín/DEA, sala de lactancia según quejas; % de cobertura | Área de salud (junto al Rectorado) | máquinas de bebidas en botella plástica | bebederos → Agua (WR4); sombra con árboles → Entorno |

- **Orden de entrega:** 1 y 2 primero (cierran el ciclo con los árboles que ya
  existen), luego 3 y 4, luego 5, 6 (espera validación de especies) y 7 (espera
  el mapa nuevo para su ubicación definitiva).
- **Misiones por nivel tras C:** Entorno 6→9, Energía 8→10, Residuos 6→7,
  Agua 8→9, con `MISIONES_LEGADO` = conjuntos actuales.

## 9. Riesgos, limitaciones y pendientes externos

- **Constantes espejo cliente/servidor** (catálogo de misiones, EC por misión):
  riesgo de desincronización; se documenta en ambos lados.
- **Presupuesto del Nivel 5 calculado en el cliente** (no es moneda).
- **Especies del minijuego 6:** deben validarse con la Dirección de Sustentabilidad (Tabla 16).
- **Mapa nuevo:** las ubicaciones de B y C son provisionales hasta que llegue;
  se ajustan editando `lugares_campus.gd`.
- **Tesis:** el Capítulo 4 y `docs/ESTADO_PROYECTO.md` deben reflejar el modelo
  de puntaje, la regla Mixta y los minijuegos (la matriz del paso 0 sirve de anexo).
  Los capítulos 1–3 no se tocan.
- **Reapertura de niveles:** los jugadores verán niveles antes completos otra vez
  pendientes; lo ya desbloqueado se mantiene.
- **Avisos `authenticated_security_definer_function_executable` (6) intencionales:**
  `get_advisors` marca las seis funciones del puntaje (`puntaje_greenmetric`,
  `guardar_detalle`, `obtener_detalles`, `registrar_quiz`, `registrar_decision`,
  `registrar_sinergia`) por ser `security definer` ejecutables por
  `authenticated`. Es el mismo patrón que la tienda de EcoCredits: las tablas
  no tienen permisos de escritura para el cliente y la única vía es la función,
  que valida `auth.uid()` y los datos. No son alertas nuevas a corregir.
- **Comprensión y Avance confían en datos enviados por el cliente:** los
  aciertos de un quiz llegan como `p_aciertos` y las misiones completas en
  `misiones_estudiante` vía `guardar_progreso_modulo`. El servidor acota
  topes y rangos, pero no puede comprobar que el estudiante realmente jugó —
  mismo modelo de confianza que el XP.
