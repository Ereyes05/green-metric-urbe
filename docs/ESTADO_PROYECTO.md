# Estado del proyecto — GreenMetric URBE

Este documento es el contexto completo del proyecto para cualquiera que se
sume: qué es, qué hay hecho, por qué se hizo así, y qué falta. **Se actualiza
en cada cambio importante** — ver la sección final para las reglas de eso.

Última actualización: 2026-09-17 (Nivel 5 — Plan de Movilidad, proyecto B del
puntaje GreenMetric, implementado en el cliente; migración de misiones,
re-export y prueba con cuenta real pendientes — ver secciones 3, 4 y 8).

> ⚠️ **Si vas a tomar cualquier decisión de diseño, leé primero la
> [sección 9: El marco académico](#9-el-marco-académico-la-tesis--leer-antes-de-decidir-diseño).**
> El juego no es un proyecto libre: responde a una tesis con variables,
> objetivos e historias de usuario ya escritas y aprobadas. Varias
> decisiones que parecen inocentes (el estilo visual, por ejemplo) ya
> están comprometidas por escrito ahí.

---

## 1. Qué es esto

Juego educativo 2D en Godot 4.7 ("URBE Rangers: Eco-Quest"). El jugador
recorre un campus universitario y resuelve misiones de campo mapeadas 1:1 a
los 6 módulos del ranking [UI GreenMetric World University Ranking](https://greenmetric.ui.ac.id/):

| Nivel | Módulo GreenMetric              | Misiones |
|-------|----------------------------------|----------|
| 1     | Infraestructura y Entorno        | 6 |
| 2     | Energía y Cambio Climático        | 8 |
| 3     | Manejo de Residuos                | 6 |
| 4     | Uso del Agua                      | 8 |
| 5     | Transporte Sostenible              | 8 |
| 6     | Educación e Investigación         | 4 |

Es parte de una pasantía/tesis en la URBE (Universidad Privada Dr. Rafael
Belloso Chacín). El progreso de cada estudiante se guarda en Supabase para
poder analizarlo después.

## 2. Cómo correrlo

Ver `README.md` en la raíz — requisitos, comando para abrir el editor,
escena principal. No lo repito aquí para no duplicar y desincronizar.

## 3. Arquitectura del cliente (Godot)

- **`autoload/`** — singletons globales:
  - `SupabaseManager.gd` — toda la comunicación HTTP con Supabase (auth,
    progreso, telemetría, ranking, QR). Cola de peticiones serializada
    (`_cola`/`_ocupado`/`_despachar`), una sola `HTTPRequest` compartida.
  - `NivelManager.gd` — fuente de verdad LOCAL del progreso (qué misiones de
    campo están completas). **Guardado por cuenta** desde el 2026-09-02: ver
    sección 6.
  - `EconomiaManager.gd`, `AudioManager.gd`, `WindowManager.gd` — EcoCredits,
    audio, utilidades de ventana. **Desde el 2026-09-14 los EcoCredits y el
    inventario de la tienda viven en el servidor** (antes estaban solo en
    memoria y volvían a 50 en cada sesión). `EconomiaManager` muestra los
    cambios al instante y se alinea con el saldo del servidor cuando no
    quedan operaciones en vuelo. Energía e insignias siguen solo en memoria.
    **`EconomiaManager` ya no tiene `ImpactRating`** (2026-09-14): ese cálculo
    local, inventado y desalineado del resto de los números, lo reemplaza
    `PuntajeManager` — ver abajo y la sección 4.
  - `PuntajeManager.gd` (+ `autoload/puntaje_formula.gd`, nuevos, 2026-09-14)
    — el puntaje GreenMetric por categoría (0–100), **un solo número** que
    usan el HUD, el mapa de avance, el simulador de movilidad y el informe
    final (antes cada uno mostraba un valor distinto — ver sección 4,
    "Puntaje GreenMetric (proyecto A)"). Lo calcula el servidor
    (`puntaje_greenmetric`); `puntaje_formula.gd` es un espejo local sin
    autoloads (para poder probarlo solo) que muestra el avance al instante
    mientras llega la respuesta del servidor, que sigue siendo la fuente de
    verdad. También sincroniza con el servidor los "detalles" de
    `NivelManager` (decisiones con criterio propio del Nivel 6), que antes
    vivían solo en el archivo local de la máquina.
  - `rangos.gd` (nuevo, 2026-09-16) — rango por niveles de misiones
    completados (Semilla → Brote N1 → Árbol N2 → Estratega N3 →
    Investigador N4-5 → EcoLíder los 6), sin autoloads, testeable a solas.
    Reemplaza el rango calculado por XP (con ~2.800 XP totales en el juego
    nadie pasaba de Árbol/Estratega).
- **`scenes/ui/hud_*.gd`** (nuevo, 2026-09-16) — HUD plano de la
  especificación `docs/diseno/hud_plano_2b.md`, partido en componentes chicos
  que solo muestran lo que les pasan (no leen autoloads); `SceneMapaMundo.gd`
  los crea y les pasa los datos:
  - `hud_tema.gd` — únicos tokens de color/fuente/radio del HUD.
  - `hud_barra.gd` — barra de progreso genérica (fracción → ancho, con tween).
  - `hud_ficha_jugador.gd` — nombre, vidas, nivel de misiones, rango,
    EcoCredits y barra hacia el siguiente rango. **No muestra categorías**:
    hasta el 2026-09-20 repetía Verde/Agua/Educación con el mismo número que
    el panel GreenMetric y con otro nombre para la categoría 1. El panel es la
    única vista de categorías.
  - `hud_panel_greenmetric.gd` — puntaje 0–100, 6 filas con barra partida
    80/10/5/5 y popover de desglose por categoría al pasar el mouse.
  - `hud_acciones.gd` — 5 botones con teclas 1–5, señal `accion(indice)`.
  - `hud_banner_zona.gd` — banner de zona, visible mientras el jugador está
    en ella.
  - `hud_aviso.gd` — aviso central con cola (máx. 2 pendientes).
  Pruebas: `timeout 120 "$GODOT" --headless --path . res://tests/<t>.tscn`
  con `t` = `test_rangos`, `test_hud_tema`, `test_hud_paneles`,
  `test_hud_controles`, `test_hud_rango_aviso`. Captura de verificación
  1280×720 (no headless, necesita dibujar): `timeout 60 "$GODOT" --path .
  --resolution 1280x720 res://tests/captura_hud.tscn -- <ruta.png>`.
- **Nivel 5 — Plan de Movilidad** (nuevo, 2026-09-17; proyecto B del puntaje
  GreenMetric, ver sección 4). Reemplaza los seis escenarios y los dos
  bicicleteros viejos por un plan con presupuesto de 100 puntos. Diseño
  completo en `docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md`.
  - `scenes/mapa/lugares_campus.gd` — lugares del campus por nombre
    (coordenadas provisionales hasta que llegue el mapa rediseñado).
  - `scenes/mapa/cambios_movilidad.gd` — cambios visibles en el mapa según lo
    elegido (ciclovía, buseta, vehículo eléctrico, etc.), anclados a lugares.
  - `scenes/misiones/plan_movilidad_datos.gd` — contenido (decisiones,
    opciones, objeciones del Consejo); copia literal de la spec, espejo de
    `sql/nivel5_plan_movilidad.sql`.
  - `plan_movilidad.gd` — reglas puras del plan (presupuesto, decisiones,
    Consejo, regla Mixta), sin autoloads.
  - `punto_movilidad.gd` — un solo script para los 4 tipos de punto (Oficina,
    decisión, bicicletero, Consejo), grupo `punto_movilidad`.
  - `ui_movilidad.gd` — helpers de interfaz sobre `hud_tema.gd`.
  - `panel_decision_movilidad.gd` — panel de decisión (revela consecuencias
    solo tras confirmar; la contraproducente penaliza y permite reintentar).
  - `panel_oficina_movilidad.gd` — encargo y tablero del plan (presupuesto
    comprometido/restante, estado de cada decisión).
  - `panel_consejo_movilidad.gd` — revisión (hasta 2 cambios), 3 objeciones y
    calificación del plan.
  - `nivel5_movilidad.gd` — controlador del nivel: conecta puntos y paneles,
    guarda el detalle `plan_movilidad`, registra decisiones/sinergias y
    respeta la regla de sin re-pago a quien ya tenía el Nivel 5 viejo completo
    (sección 8).
  Pruebas: `timeout 120 "$GODOT" --headless --path . res://tests/<t>.tscn`
  con `t` = `test_lugares_campus`, `test_cambios_movilidad`,
  `test_plan_movilidad`, `test_punto_movilidad`, `test_ui_movilidad`,
  `test_panel_decision_movilidad`, `test_panel_consejo_movilidad`,
  `test_nivel5_movilidad`.
- **`scenes/ui/tienda_conocimiento.gd`** — pantalla de la Tienda del
  Conocimiento (HU-012). Se abre con el botón 🛒 del HUD o sola, cuando una
  misión exige una herramienta que el estudiante no tiene
  (`SceneMapaMundo._verificar_herramienta`).
- **`scenes/mapa/SceneMapaMundo.gd`** — el archivo más grande del proyecto
  (~2900 líneas). Mapa, HUD, spawns de las 40 misiones, panel de
  resultados, leaderboard, y el sistema legacy de NPCs/quiz (`ZONA_A_MISION`,
  `DATOS_NPCS` — ver sección 6). Punto de entrada para entender cómo se
  conecta todo.
- **`scenes/misiones/`** — una misión de campo = típicamente 2 scripts:
  `punto_*.gd`/`zona_*.gd` (el `Area2D` interactivo en el mapa, detecta al
  jugador, dibuja su propio ícono con `_draw()`) + `mision_*.gd` (el
  `CanvasLayer` con la UI/lógica de la interacción). Copiar el par más
  parecido es más rápido que empezar de cero.
- **`scenes/login/SceneLogin.gd`** — login, registro, recuperación de
  contraseña en 3 pasos. Orquesta el login automático post-registro y la
  reconstrucción del progreso al entrar (sección 6).
- **`addons/qrcode_generator/`** — librería de terceros vendorizada
  ([Greaby/godot-qrcode-generator](https://github.com/Greaby/godot-qrcode-generator),
  GDScript puro, MIT, `LICENSE` incluido). Genera QR reales y escaneables
  (`QrCode.new().get_texture("texto")`). La usa `zona_reciclaje.gd` para el
  QR de "llamar al servicio de limpieza" (sección 7).
- **`sql/`** — migraciones para correr a mano en el SQL Editor del dashboard
  de Supabase (no hay migraciones automáticas). Ver sección 4.
- **`supabase/functions/`** — Edge Functions desplegadas con el Supabase
  CLI. Ver sección 4.

## 4. Backend (Supabase)

Proyecto: `ikohikbpvtbvsgyumvbr` (ver `SUPABASE_URL` en `SupabaseManager.gd`).
La anon key es pública por diseño (protegida por RLS, no por estar oculta).

### Tablas

- **`modulos_greenmetric`** — catálogo de los 6 módulos. Solo lectura desde
  el cliente.
- **`progreso_estudiante`** — agregado por módulo (no por misión):
  `xp_ganada`, `puntaje_obtenido`, `completado`, `intentos`. Es la tabla
  vieja, de antes de que existiera el guardado por misión. El HUD todavía
  suma su `xp_ganada` para el XP total al cargar (`_on_progreso_cargado` en
  `SceneMapaMundo.gd`) — cuidado, esto puede incluir XP de antes del 2 de
  septiembre de 2026 (antes de la RPC idempotente), potencialmente inflado
  por bugs ya corregidos (ver sección 6). No tiene migración versionada en
  el repo — existe en Supabase pero hay que reconstruir su esquema desde el
  dashboard si hay que recrearla.
- **`misiones_estudiante`** (nueva, 2026-09-02) — estado por misión
  individual: `(user_id, modulo_id, mision_id, xp_otorgada, completada_at)`,
  PK `(user_id, mision_id)`. Esta es la fuente real para saber "qué misiones
  completó este estudiante", usada para repoblar `NivelManager` en una
  máquina nueva (sección 6). Ver `sql/guardar_progreso_modulo.sql`.
- **`solicitudes_qr`** (nueva, 2026-09-09) — soporte de la mecánica de QR de
  Nivel 3 (sección 7). `(token, user_id, mision_id, escaneado, creado_en,
  escaneado_en)`, PK `token`. Ver `sql/solicitudes_qr.sql`.
- **`eventos_aprendizaje`** — log de eventos de proceso (no solo resultado
  final): cada elección, acierto, intento. Ver `sql/eventos_aprendizaje.sql`.
  **Cobertura (actualizada el 2026-09-11): los 6 niveles.** La escriben 14
  scripts. El evento más valioso es `respuesta_quiz` (en `quiz_npc.gd`), que
  registra por cada pregunta si acertó, cuál eligió, cuántos segundos tardó
  y en qué racha venía — es decir, el proceso, no solo el resultado.
  `quiz_npc.iniciar()` recibe el nivel y la misión justamente para poder
  atribuir esos eventos a un indicador GreenMetric.
  Verificado el 2026-09-14 que los eventos con sesión iniciada llegan al
  servidor; los generados sin sesión quedan solo en el log local
  (`user://eventos_aprendizaje.jsonl`). Ver sección 8.
- **`estudiantes`** — perfil del estudiante (`xp_total`, etc.), creada por
  un trigger `on_auth_user_created`. El cliente Godot **nunca** la toca
  directo — solo la RPC (`security definer`) le suma XP.
- **`catalogo_tienda`**, **`movimientos_ecocredits`**, **`inventario_estudiante`**
  (nuevas, 2026-09-14) — la Tienda del Conocimiento. Ver
  `sql/tienda_ecocredits.sql` y la subsección de abajo.

### EcoCredits y tienda (HU-012)

- **El saldo es la suma de `movimientos_ecocredits`**, no un número suelto.
  Cada ganancia y gasto queda con su motivo (evidencia de "toma de
  decisiones" para la tesis). Cada movimiento tiene un `ref` único por
  estudiante: reintentar nunca paga ni cobra dos veces.
- **El cliente no puede escribir estas tablas.** Todo pasa por funciones
  `SECURITY DEFINER`: `obtener_billetera`, `acreditar_mision`,
  `sumar_ecocredits`, `gastar_ecocredits` y `comprar_item`. (La pública
  `titulos_ranking` sigue existiendo en Supabase pero el cliente ya no la
  llama: `ranking_publico` devuelve el título junto con el resto de la fila.
  El código que la consumía se borró el 2026-09-20.)
- `acreditar_mision` solo paga misiones que `misiones_estudiante` ya tiene
  registradas, con el monto que decide el servidor (`_ec_por_modulo`, espejo
  de `NivelManager.EC_POR_MISION`: **si cambia uno hay que cambiar el
  otro**). El cliente la llama recién cuando llega la confirmación de
  `guardar_progreso`, porque en los callbacks el cobro ocurre antes que el
  guardado.
- `sumar_ecocredits` / `gastar_ecocredits` aceptan una **lista cerrada de
  motivos** y un monto máximo por evento. Si se agrega una fuente o un
  gasto nuevo de EC en el juego, **hay que agregar su motivo en el
  servidor**, o se rechaza (ya pasó: faltaban nivel, riego, quiz y
  semana_verde).
- **Catálogo** (aprobado 2026-09-14): 3 herramientas obligatorias
  (`kit_solar` 100, `kit_captacion` 60, `kit_bicicletero` 60), 2
  bonificaciones (`termo_reutilizable` +10% EC, `credencial_voluntario` +10%
  XP) y 2 de avatar (`estela_hojas`, `titulo_embajador`). Regla de precio:
  cada herramienta obligatoria cuesta menos que lo que dan las misiones del
  mismo nivel que no la necesitan, así nadie queda trabado.
- **Probado en el servidor** (2026-09-14, dentro de bloques que terminan en
  excepción para no dejar datos): compra sin saldo rechazada sin tocar el
  saldo, compra válida, recompra, ítem inexistente, doble pago, misión
  inventada, montos y motivos inválidos, Termo 20→22 EC, saldo nunca
  negativo, y todas las funciones con 401 sin sesión.
- **EC retroactivos:** 50 iniciales + EC de cada misión de campo ya
  completada + bonus de cada nivel completo. Los EC que se ganaron antes
  por minijuegos, decisiones, riego o quizzes no se pudieron recuperar
  (nunca se guardaron).

### La RPC: `guardar_progreso_modulo`

```sql
guardar_progreso_modulo(p_modulo_id int, p_mision_id text, p_xp_delta int,
                        p_completitud_pct int, p_completado boolean)
returns jsonb  -- {"xp_otorgada": n, "ya_registrada": bool}
```

Reemplaza el POST directo que hacía el cliente contra `progreso_estudiante`.
Es **idempotente por misión**: intenta insertar `(user_id, mision_id)` en
`misiones_estudiante`; solo otorga XP si esa inserción ocurre de verdad. Los
duplicados (ver sección 6, por qué hay duplicados) cuentan como intento pero
no vuelven a sumar XP. `security definer` porque necesita escribir en
`estudiantes.xp_total`, que el cliente no puede tocar directo.
Ver `sql/guardar_progreso_modulo.sql` para el SQL completo con el historial
de por qué se diseñó así (409 → reemplazo pisando datos → suma inflando XP
2-4x → idempotencia).

### Edge Function: `marcar_escaneado`

Soporte de la mecánica de QR de Nivel 3 — ver sección 7 para el detalle
completo. Desplegada con `supabase functions deploy marcar_escaneado
--no-verify-jwt` (sin esa flag, rechaza cualquier request sin un JWT válido,
y un teléfono que abre un link no manda ninguno).

### Supabase CLI en esta máquina

Instalado vía Scoop (`scoop install supabase`), logueado, y linkeado al
proyecto (`supabase link --project-ref ikohikbpvtbvsgyumvbr`). Para
desplegar cambios a una Edge Function:

```powershell
supabase functions deploy <nombre_de_la_funcion> --no-verify-jwt
```

(la flag `--no-verify-jwt` solo aplica a funciones que reciben pedidos sin
sesión de Supabase, como `marcar_escaneado`; si se agrega una función que sí
espera que el cliente Godot logueado la llame, no hace falta esa flag).

### Puntaje GreenMetric (proyecto A)

Nuevo (2026-09-14). Diseño completo en
`docs/superpowers/specs/2026-09-14-puntaje-greenmetric-cruces-design.md`.
Reemplaza los tres números que no coincidían entre sí (barra del HUD con
`ImpactRating`, mapa de avance con valores fijos inventados, informe final por
% de misiones) por **un solo puntaje 0–100 por categoría**, calculado en el
servidor.

**Modelo 80/10/5/5** — cada categoría (1 a 6) suma hasta 100 puntos:

| Componente | Tope | De dónde sale |
|---|---|---|
| Avance | 80 | % de misiones de campo completas de esa categoría (mismo criterio que `NivelManager.pct_nivel`) |
| Comprensión | 10 | Quizzes acertados (primer intento, ver abajo) |
| Decisiones | 5 | Opciones válidas elegidas en decisiones con criterio propio (Nivel 6) |
| Sinergias | 5 | Acciones que suman a más de una categoría a la vez |

El total del juego pondera cada categoría por el peso de la guía GreenMetric
2024 (`{1: 15, 2: 21, 3: 18, 4: 10, 5: 18, 6: 18}`, ver
`autoload/puntaje_formula.gd`) y divide entre 100.

**Tablas nuevas:** `catalogo_misiones` (52 filas — espejo de
`NivelManager.MISIONES_NIVEL`/`MISIONES_LEGADO`, ver abajo),
`catalogo_sinergias`, `catalogo_decisiones` (los `id` de decisión y opción
siguen `^[a-z0-9_]{1,60}$`), `detalles_estudiante` (las decisiones del
Nivel 6, antes solo en `user://`) y `puntos_calidad` (comprensión/decisiones/
sinergias ya otorgados, para no volver a pagarlos).

**Funciones (`security definer`):** `puntaje_greenmetric()` (público — arma
el desglose por categoría + total para el HUD/mapa de avance/resultados),
`guardar_detalle`/`obtener_detalles` (sincronizan `detalles_estudiante`),
`registrar_quiz(mision_id, aciertos)`, `registrar_decision(decision_id,
opcion_id)`, `registrar_sinergia(accion_id)`. `_puntaje_greenmetric(p_user)`
es la interna que arma el cálculo real; `autoload/puntaje_formula.gd` es su
espejo en GDScript para mostrar el avance sin esperar la red.

`get_advisors` muestra 6 avisos `authenticated_security_definer_function_executable`
(uno por cada función de arriba). **Son intencionales**, mismo patrón que la
tienda de EcoCredits: el cliente no puede escribir en las tablas y la única
vía es la función, que valida `auth.uid()` y los datos.

- **Regla del primer intento:** `registrar_quiz` solo otorga puntos de
  Comprensión la primera vez que se resuelve una misión de quiz; reintentos
  no vuelven a sumar (ni restan). Ver `puntos_calidad`.
- **Regla Mixta (Decisiones, Tabla 15 de la tesis):** cada decisión tiene una
  opción contraproducente (`catalogo_decisiones`) que **penaliza en vez de
  sumar** — resta 1 punto, hasta 3 veces por decisión — y permite reintentar;
  `registrar_decision` devuelve `{"ok": true, "contraproducente": true,
  "penalizado": true|false}` en ese caso — `penalizado` es booleano: `true`
  si esta elección todavía restó punto (sigue bajo el tope de 3), `false` una
  vez alcanzado el tope para esa decisión (ya no resta más, pero sigue
  marcada como contraproducente). Elegir después una opción válida **reemplaza
  la anterior**, incluso si la decisión anterior había sumado a otra
  categoría (no se acumulan intentos de la misma decisión).
- **Espejo `catalogo_misiones` ↔ `NivelManager.MISIONES_NIVEL`:** el avance
  (80 pts) depende de qué misiones existen por categoría; el servidor tiene
  su propia copia en `catalogo_misiones` (52 filas) que debe seguir igual a
  `MISIONES_NIVEL`/`MISIONES_LEGADO` del cliente. Si se agrega o saca una
  misión de un nivel, **hay que actualizar las dos copias** o el % de avance
  del HUD y el del servidor van a divergir.
- Copia completa del SQL aplicado: `sql/puntaje_greenmetric.sql`. Migraciones
  aplicadas: `puntaje_greenmetric_esquema`, `puntaje_greenmetric_funciones`,
  `puntaje_greenmetric_ajustes`.
- `SupabaseManager` agrega las señales `puntaje_recibido`, `puntaje_fallido`,
  `calidad_respuesta`, `detalles_recibidos` y `detalles_fallidos` para estos
  wrappers. Todos los fallos por acción (red caída o `request()` que no llega
  a salir) pasan por `_emitir_fallo`, para que nadie quede esperando.
- `SceneLogin` espera hasta 6 s la respuesta de `obtener_detalles` al iniciar
  sesión, mezcla esos detalles con los locales y recién ahí llama a
  `PuntajeManager.iniciar_sesion`. Si la petición falla o no llega a tiempo
  **no** mezcla nada (consola: `detalles NO cargados (fallo o timeout)`):
  subir los locales sin saber qué tiene el servidor podría pisar datos más
  nuevos; se reintenta en el próximo login.

### Ranking público

Nuevo (2026-09-16). `ranking_publico()` (pública, `security definer`) arma el
top 50 leyendo `estudiantes` directo (antes `cargar_ranking` leía
`progreso_estudiante`, la tabla vieja, con la clave anónima, y la RLS solo
dejaba ver filas propias — por eso el ranking salía vacío). Copia completa en
`sql/ranking_publico.sql`.

Devuelve, por fila: `nombre` (primer nombre + inicial del apellido, ver
sección 9 — "Eco-Ranger" si está vacío o tiene "@"), `xp_total`,
`niveles_completos` (para que el cliente calcule el rango con
`autoload/rangos.gd`), `titulo` (el de la tienda, si compró
`titulo_embajador`) y `es_yo` (calculado en el servidor con `auth.uid()`, no
por nombre). **Nunca expone** cédula, correo ni `user_id`: ninguno de esos
campos sale de la función.

**OJO — `niveles_completos` puede quedar por debajo del rango del HUD:** el
servidor solo cuenta el catálogo vigente de misiones (`catalogo_misiones`),
mientras que el cliente usa `NivelManager.nivel_superado()`, que además
acepta el conjunto de misiones legado — un jugador que superó un nivel solo
por el legado puede mostrar un rango más alto en el HUD que en este ranking.

### Plan de Movilidad (proyecto B del puntaje GreenMetric)

Nuevo (2026-09-17). Diseño completo en
`docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md`. Reemplaza
el Nivel 5 (seis escenarios de "Continuar" y dos bicicleteros) por un plan con
presupuesto de 100 puntos y, en cada decisión, una opción contraproducente que
penaliza y permite reintentar (regla Mixta, sección 4).

**Aplicado:** `catalogo_decisiones` (28 filas, categoría 5: 6 decisiones × 3
opciones + 2 bicicleteros × 3 opciones + 4 calificaciones de `tr_consejo`) y
`catalogo_sinergias` (4 filas nuevas, todas con `requisito_mision = 'tr_consejo'`:
`ciclovia_lote` → Entorno, `flota_electrica` → Energía,
`dia_sin_carros_feria` → Educación, `bicicletero_techado_solar` → Energía).
Copia versionada: `sql/nivel5_plan_movilidad.sql`.

**Pendiente de aplicar al publicar:** la migración
`nivel5_plan_movilidad_misiones` — borra de `catalogo_misiones` los 8 IDs
viejos (`mov_parqueo`, `mov_shuttle`, `mov_ciclovia`, `mov_dia_sin_carros`,
`mov_zev`, `mov_carpool`, `bicicletero_bloque_e`, `bicicletero_cafetin`) e
inserta los 9 `tr_*` nuevos — se aplica **junto con el re-export web**, nunca
antes: ver sección 8 para el orden exacto y la consecuencia de adelantarla.

**Cliente:** el detalle `plan_movilidad` (presupuesto, decisiones, Consejo,
sinergias ganadas) se guarda en `detalles_estudiante` con
`NivelManager.guardar_detalle`, mismo mecanismo que las decisiones del
Nivel 6.

## 5. Estado por nivel — qué está verificado visualmente

- **Nivel 1-3**: verificados jugando, colisiones chequeadas geométricamente
  contra `EDIFICIOS` en `colision_tilemap.gd` en algún momento del
  desarrollo (ej. el fix de `reciclar_sur`, commit `ed8eea0`).
- **Nivel 4 (Agua)**: las 8 posiciones (`DATOS_LLAVES_AGUA`,
  `DATOS_PUNTOS_CAPTACION`) se verificaron por geometría el 2026-09-09
  (comparadas contra `EDIFICIOS` en `colision_tilemap.gd`): ninguna cae
  dentro de un edificio, y el jugador (cápsula de 16px de ancho) tiene
  margen de sobra incluso en los pasillos más angostos (~40px). **No
  verificado a simple vista todavía** — ver el desajuste de nombres abajo.
- **Nivel 5 (Transporte)**: probado en vivo al menos una vez (sesión del
  2026-09-02, confirmó que el guardado funciona).
- **Nivel 6 (Educación)**: mismo chequeo geométrico que Nivel 4, mismo
  resultado (sin colisiones). **No verificado a simple vista todavía.**

**Desajuste encontrado (2026-09-09, por geometría, no por vista):**
`captacion_bloque_c` ("Techo del Bloque C", Nivel 4) y `captacion_biblioteca`
("Techo de la Biblioteca", Nivel 4) no están cerca de ningún edificio con
ese nombre — de hecho **no existe ningún edificio "Biblioteca" en el mapa**
(comparado contra `mapa_campus.gd`, que solo dibuja los mismos 10 edificios
de `EDIFICIOS`). Lo mismo con `malla_verde` e `informe_final` (Nivel 6, "el
Decanato" — tampoco existe). Estos 4 puntos caen en pasillos abiertos, sin
ningún edificio visualmente asociado al nombre de la misión. No bloquea al
jugador, pero probablemente se vea raro (el prompt dice "techo de la
biblioteca" parado en un pasillo vacío). Pendiente: alguien con el editor
abierto confirme a simple vista si estos 4 puntos quedan bien ambientados o
si conviene reubicarlos cerca de un edificio real / darles otro nombre.

## 6. Decisiones de diseño importantes (y por qué)

### Modelo de confianza: el cliente sigue siendo quien decide el XP

`guardar_progreso_modulo` es idempotente (no se puede inflar XP jugando la
misma misión muchas veces), pero **el valor de XP que se otorga la primera
vez lo manda el cliente** (`p_xp_delta`), no lo calcula el servidor. Un
cliente modificado podría mandar cualquier número la primera vez que llama
con un `mision_id` nuevo. No es un problema si esto es solo una demo; sí
importa si el leaderboard o `progreso_estudiante`/`misiones_estudiante` se
usan para evaluar a estudiantes de verdad. Pendiente si se quiere cerrar
esto del todo (validar `p_xp_delta` contra una tabla de XP-por-misión en el
servidor).

### Guardado local por cuenta + repoblación desde el servidor ("Plan B")

Hasta el 2026-09-02, `NivelManager` guardaba a un único archivo global
(`user://nivel_progreso.json`), cargado al arrancar el juego, **antes** de
que existiera cualquier sesión. Una cuenta nueva en una máquina con
progreso previo de otra cuenta arrancaba viendo el campus como si todo
estuviera completado.

Solución actual:
- `NivelManager.iniciar_sesion(uid)` — se llama al loguearse/registrarse
  (`SceneLogin.gd`), resetea el estado en memoria y usa
  `user://nivel_progreso_<uid>.json`, uno por cuenta.
- `NivelManager.repoblar_desde_servidor(filas)` — después de
  `iniciar_sesion()`, `SceneLogin.gd` pide `misiones_estudiante` y mezcla
  (unión, nunca reemplaza) lo que el servidor reporte. Necesario para
  jugar desde una máquina sin save local. No emite señales de
  misión/nivel completado (evita popups fantasma) ni vuelve a llamar
  `guardar_progreso` (tráfico de red de más, aunque sería inofensivo).
- Con timeout de 8s y fail-open: si no hay red al loguearse, entra igual
  con lo que haya en el archivo local, no traba al estudiante.
- **No se migró** el archivo global viejo a uno por cuenta — cualquier
  misión completada solo en local y nunca sincronizada (jugada sin
  internet, sin la sincronización automática) queda huérfana. Decisión
  consciente: el servidor es la fuente de verdad de ahora en más.
- `_progreso_modulos` (el dict que pinta el mapa de avance) **no se actualiza
  solo** al entrar — hay que sembrarlo desde
  `NivelManager.pct_nivel()` en `SceneMapaMundo._ready()` (ya está hecho).
  Si se agrega un indicador visual nuevo que dependa del progreso, hay que
  sembrarlo ahí también, no asumir que se actualiza solo.

### Por qué `guardar_progreso()` se llamaba 2-4 veces por misión

`interior_bloque.gd` (LED) y `mision_solar.gd` tienen tweens de finalización
sin guard contra clics repetidos — un jugador impaciente que clickea de
nuevo durante la ventana de la animación dispara la lógica de completado
más de una vez. **No se arregló** (es cosmético/de tráfico de red desde que
la RPC es idempotente) — pendiente, ver sección 8.

### Por qué NO se usa `eventos_aprendizaje` para reconstruir estado

Es un log de eventos de proceso (append-only), no una tabla de estado. Usar
un log como fuente de verdad de "qué está completo" requeriría reproducirlo
entero cada vez — por eso existe `misiones_estudiante` como tabla de estado
separada.

## 7. Mecánica de QR — "llamar al servicio de limpieza" (Nivel 3)

Sugerencia del tutor de pasantías: al llenarse una papelera, mostrar un QR
real que, escaneado con un teléfono de verdad, dispare la animación del
trabajador en el juego. Implementado como activación real a distancia (no
solo decorativo):

1. El jugador presiona [E] en una papelera llena → `zona_reciclaje.gd`
   genera un token random, inserta una fila en `solicitudes_qr`, genera un
   QR real (librería vendorizada, ver sección 3) apuntando a
   `https://ikohikbpvtbvsgyumvbr.supabase.co/functions/v1/marcar_escaneado?token=<token>&apikey=<anon key>`
   y lo muestra en un panel modal.
2. El jugador escanea con su cámara. El teléfono abre ese link — sin login,
   sin sesión de Supabase de ningún tipo.
3. La Edge Function `marcar_escaneado` marca `escaneado=true` en esa fila,
   usando la `service_role` key (bypassa RLS) porque el teléfono no tiene
   ninguna sesión. Responde con **texto plano** (no HTML: Supabase fuerza
   `Content-Type: text/plain` en las respuestas de Edge Functions sin
   importar lo que la función devuelva — limitación documentada de la
   plataforma, no vale la pena pelear contra eso).
4. El juego, mientras tanto, consulta `solicitudes_qr` cada 1.5s. Al ver
   `escaneado=true`, cierra el modal y hace aparecer al trabajador animado
   (que ahora sale de un punto fijo del campus, `PUNTO_SERVICIO` en
   `zona_reciclaje.gd`, y camina hasta la papelera que llamó — no aparece
   de la nada al lado de cada una).
5. Nunca traba al jugador: hay un botón "no tengo el celular a mano" y un
   timeout de 60s.

No dispara ninguna notificación a personal real de la URBE — el "servicio"
sigue siendo ficticio dentro del juego, la parte real es solo el
mecanismo técnico de escaneo → activación a distancia.

## 8. Pendientes conocidos

- [x] **Las decisiones del Nivel 6 se guardaban solo en la computadora** —
  resuelto el 2026-09-14 con el puntaje GreenMetric unificado (sección 4):
  `NivelManager._detalles` ahora se sincroniza con la tabla
  `detalles_estudiante` vía `guardar_detalle`/`obtener_detalles`, y
  `SceneLogin` los mezcla con los locales al iniciar sesión. Antes, en otra
  máquina o tras borrar datos del navegador, el informe final decía "Sin
  datos".
- [ ] **Cuentas con niveles completos ven 80% hasta ganar calidad** — al
  pasar de "% de misiones" al modelo 80/10/5/5 (sección 4), una cuenta que ya
  tenía un nivel al 100% pero nunca hizo un quiz, una decisión válida o una
  sinergia en esa categoría ve el puntaje bajar a 80/100 (el tope de Avance)
  hasta que gane algo de Comprensión/Decisiones/Sinergias. Es el
  comportamiento esperado del nuevo modelo, pero conviene que quien lo vea
  por primera vez lo sepa antes de asumir que es un bug.
- [x] **Si `obtener_detalles` fallaba al iniciar sesión, se subían todos los
  detalles locales sin comparar** — resuelto el 2026-09-14: el fallo emite
  `detalles_fallidos` (ya no `detalles_recibidos({})`, que era
  indistinguible de "servidor vacío") y `SceneLogin` no llama a
  `restaurar_detalles` ni ante fallo ni ante timeout.
- [ ] **`resultados_greenmetric.gd` conserva su propia copia de los pesos**
  por categoría (`{1: 15, 2: 21, 3: 18, 4: 10, 5: 18, 6: 18}`), pero ya solo
  para la etiqueta "×N" de cada barra: el total mostrado sale de
  `PuntajeManager.total`. Si el peso de una categoría cambia, la etiqueta
  hay que actualizarla a mano.
- [ ] **Textos "Impacto estimado" más largos podrían solaparse en botones**
  del simulador de movilidad — no verificado visualmente todavía.
- [ ] **Falta la verificación con la cuenta de prueba (Step 1 de Task 10) y
  publicar (Step 5)** — no se hicieron en esta tarea por no tener las
  credenciales de la cuenta de prueba a mano; ver el spec para el detalle de
  qué falta confirmar (consola `SceneLogin: detalles N del servidor`, barra
  del HUD = mapa de avance = resultados, quiz dos veces solo suma la primera).
- [x] **Proyecto B — Nivel 5 nuevo** — implementado el 2026-09-17: Plan de
  Movilidad con presupuesto de 100 puntos, 6 decisiones con opción
  contraproducente (regla Mixta), 2 bicicleteros con decisión de tipo y
  Consejo Universitario (3 objeciones, calificación). Diseño detallado en
  `docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md`; ver
  sección 3 (archivos) y sección 4 (backend, "Plan de Movilidad") de este
  documento. **Pendiente, en este orden y con OK del usuario, antes de dar por
  cerrado el proyecto** (orden corregido — ver el porqué después de la
  lista):
  1. Correr la checklist completa **desde el editor**, con la migración 2
     (`nivel5_plan_movilidad_misiones`) **todavía sin aplicar**. Todo
     funciona salvo el Avance de Transporte del HUD, que arranca en 0 y se
     enciende recién en retrospectiva al aplicar la migración más tarde:
     `guardar_progreso_modulo` no valida `mision_id` contra el catálogo, así
     que guarda el progreso de las misiones `tr_*` igual aunque el catálogo
     todavía no las tenga.
  2. Re-exportar el cliente web: `python scripts/exportar_web.py`.
  3. Verificar el `.pck` — que no lleve `tests/`, `docs/` ni `sql/`, que
     contenga `nivel5_movilidad` y que ya **no** contenga `mision_bicicletero`
     (ver sección 10 más abajo).
  4. Push/merge, y confirmar que GitHub Pages ya sirve el build nuevo (el
     `index.pck?v=<hash>` cambió).
  5. Recién unos minutos después, aplicar la migración
     `nivel5_plan_movilidad_misiones` (`sql/nivel5_plan_movilidad.sql`,
     sección 10.2 del diseño).
  6. Verificación corta post-migración con la cuenta real (que el Avance de
     Transporte ahora sí sube, que el Consejo registra la calificación).
  **Por qué este orden y no el anterior (migración antes del build
  publicado):** con la migración antes, el juego que todavía estaba publicado
  (el que guarda `mov_*`) se hubiera quedado leyendo un catálogo que ya no
  tiene esos IDs: el Avance de Transporte de **todos los jugadores activos**
  habría caído a 0 durante las horas entre aplicar la migración y terminar de
  publicar el build nuevo, y el ranking público habría mostrado un nivel
  menos para esos jugadores (cuenta niveles por el catálogo vigente) sin que
  hubiera ningún nivel nuevo disponible todavía para compensarlo. Migrar
  **después** de confirmar que Pages ya sirve el cliente que guarda `tr_*`
  evita esa ventana; el costo a cambio es la checklist del paso 1 corriendo
  contra un catálogo viejo, que es solo una lectura del HUD y se corrige sola
  al aplicar la migración. Detalle completo en
  `docs/pruebas/checklist_nivel5_plan_movilidad.md`.
  - [ ] **Tarea de seguimiento — unificar a tuteo los textos con voseo que ya
    existían en el juego** (spec `2026-09-17-nivel5-plan-movilidad-design.md`
    §17; no se tocan en este proyecto, solo los textos nuevos usan tuteo).
    Ejemplos encontrados: `SceneMapaMundo._verificar_herramienta` ("Necesitás
    el %s"), `leaderboard.gd` ("Probá con ↻ Actualizar"),
    `simulador_decision.gd` ("Practicá decisiones reales del campus…") y los
    del HUD/Tienda. Buscar con
    `grep -rnE "(ás|és|ís)|á |Probá|Practicá|Necesitás" scenes autoload`.
- [ ] **Proyecto C del puntaje GreenMetric, pendiente** — minijuegos nuevos
  SI7, SI10, SI11, EC8, EC2, WS3, WR2 todavía no están implementados. Diseño
  de alto nivel en
  `docs/superpowers/specs/2026-09-14-puntaje-greenmetric-cruces-design.md`,
  sección 8 (cada uno recibe su propio documento detallado antes de
  implementarse).
- [ ] **El ranking cuenta niveles por el catálogo vigente; el HUD acepta
  también el legado** — con el Nivel 5 nuevo esto ya no es solo teórico: un
  jugador que superó el Nivel 5 solo por las misiones `mov_*`/bicicleteros
  viejas (legado) ve un rango más alto en el HUD (`nivel_superado`, sección 4
  "Ranking público" más arriba) que el nivel que `ranking_publico()` le
  cuenta (solo `catalogo_misiones` vigente, sin los `tr_*`). Limitación ya
  documentada en `sql/ranking_publico.sql` y en el diseño (§17); no se corrige
  en este proyecto.
- [ ] **Íconos de autos reducidos en el mapa, tamaño no verificado a simple
  vista con el zoom real del juego** — `cambios_movilidad.gd` los dibuja del
  mismo tamaño que otros íconos del mapa, pero nadie confirmó todavía si se
  distinguen bien al zoom con el que se juega normalmente (no solo en la
  captura de prueba). Pendiente de mirar en el editor o en una partida real.
- [ ] **Tweens sin guard** en `interior_bloque.gd` y `mision_solar.gd` —
  causan llamadas de red duplicadas (inofensivas gracias a la RPC
  idempotente, pero innecesarias). No arreglado a propósito, ver sección 6.
- [ ] **Posiciones de Nivel 4 y 6 verificadas por geometría, no a simple
  vista** — sin colisiones, pero 4 puntos con nombre de edificio que no
  existe en el mapa (`captacion_bloque_c`, `captacion_biblioteca`,
  `malla_verde`, `informe_final`). Ver sección 5.
- [x] **Cobertura de `registrar_evento()`** — resuelto el 2026-09-11: pasó
  de 4 scripts (Niveles 5 y 6) a 14, cubriendo los 6 niveles. Se agregaron
  los tipos `respuesta_quiz`, `tiempo_agotado`, `crisis_resuelta` y
  `servicio_solicitado`.
- [x] **¿Llegan los eventos al servidor?** — verificado el 2026-09-14: **sí.**
  Se sospechó que faltaba el `grant` (como pasó con `misiones_estudiante`),
  pero **fue una falsa alarma**: `authenticated` tiene INSERT y SELECT (son
  los privilegios por defecto de Supabase). El único evento del servidor
  (nivel 5, `mov_parqueo`, 2026-09-03 23:33:18) coincide con el único
  evento del log local generado con sesión iniciada: 1 de 1. Los otros 35
  eventos del log local son de una prueba del 2026-09-02 en nivel 6 que casi
  seguro corrió sin sesión (con una cuenta real no se podía llegar al
  nivel 6 ese día), y sin sesión el evento se guarda solo en local, a
  propósito.
- [ ] ⚠️ **Casi no hay datos de proceso para la tesis.** `eventos_aprendizaje`
  tiene **1 fila** al 2026-09-14. No es un bug: hasta el 2026-09-11 solo
  registraban eventos los niveles 5 y 6, y nadie completó nunca una misión
  de esos niveles (0 filas de módulos 5 y 6 en `misiones_estudiante`). Con la
  instrumentación de los 6 niveles, la recolección real **empieza ahora**. Si
  el análisis de la tesis necesita estos datos, hace falta que estudiantes
  jueguen la versión web (con cuenta propia) antes de la fecha de análisis.
- [ ] **XP validado solo del lado del cliente en su primer envío** — ver
  sección 6, "Modelo de confianza".
- [ ] **Migración a TileMaps** — evaluado (2026-09-09), no iniciado. Hace
  falta un tileset real (arte) antes de poder empezar; la lógica de juego
  no depende del mapa visual, pero reubicar las ~40 posiciones de misiones/
  NPCs sobre la nueva grilla va a necesitar verificación visual, no solo
  matemática.
- [x] **Export Web/HTML5 — publicado y funcionando** (2026-09-11):
  **https://ereyes05.github.io/green-metric-urbe/juego/** — verificado que
  carga el motor, el `.pck` y la pantalla de login en un navegador real.
  Ver sección 10.
- [x] **HU-012 "Tienda del Conocimiento"** — implementada el 2026-09-14
  (ver "EcoCredits y tienda" en la sección 4). Servidor probado caso por
  caso; pantalla verificada por captura con el catálogo real.
  **Falta: una compra real de punta a punta con una cuenta** (no se pudo
  hacer sin credenciales). Verificable consultando
  `movimientos_ecocredits` e `inventario_estudiante` después de probar.
- [ ] **Insignias no se guardan** — siguen solo en memoria. Existen tablas
  `insignias` e `insignias_estudiante` en Supabase que el juego no usa.
- [ ] **Las 3 vidas del HUD son decorativas.** `energia_actual` arranca en 3
  y nada la baja: el código que la descontaba (racha de fallos en quiz) y el
  que la recuperaba (25 EC, o un quiz remedial de 7 preguntas) nunca tuvo
  quien lo llamara, y se borró el 2026-09-20. Hay que decidir: darle
  significado a las vidas, o sacar los corazones de `hud_ficha_jugador`.
- [x] **Zonas verdes mejorables: código muerto** — resuelto el 2026-09-20:
  se borró `zona_verde.gd` con su panel de mejora, `DATOS_ZONAS_VERDES` y
  `refs_zonas`/`zonas_restauradas` en `EconomiaManager`. **Ojo si se
  reactivan:** los EC que algún estudiante ya gastó en adoptar o mejorar una
  zona siguen en `movimientos_ecocredits` del servidor, pero el cliente ya
  no lee esas refs, así que habría que reconstruir el estado de la zona
  desde ahí o el estudiante pierde lo pagado. El código está en git
  (commit anterior a la limpieza).
- [x] **Contenedores de basura grandes: código muerto** — resuelto el
  2026-09-20: `_spawn_contenedores()` era un `return` desde que se dejaron
  solo las papeleras de colores, pero quedaban `contenedor_basura.gd`, el
  panel de servicio y 7 funciones. Todo borrado.
- [x] **`leaderboard.gd`: restos de otro proyecto** — resuelto el
  2026-09-16: se borraron las constantes `SUPABASE_URL`/`SUPABASE_KEY` del
  proyecto anterior (`qjuiwnwqkfmmfsdacpgd`) y el "(Tú)" del ranking ahora
  se marca con el `es_yo` que devuelve el servidor (`auth.uid()`), no
  comparando el nombre mostrado contra `nombre_usuario`.
- [x] **El tutorial de onboarding casi nadie lo ve** — resuelto el
  2026-09-11: `NivelManager.ruta_usuario()` centraliza los archivos de
  estado local por cuenta, y `tutorial_visto`/`hints_vistas` ahora lo usan.
  Efecto secundario buscado: quien ya lo había visto lo vuelve a ver una
  vez por cuenta.
- [ ] **Al volver, el juego no dice "dónde quedaste"** — HU-002 pide
  devolver al estudiante "al punto exacto donde lo dejó"; hoy se restaura el
  progreso pero no la posición ni se le comunica nada.
- [x] **Decidir qué hacer con el conflicto pixel art vs Flat Design** — decidido
  2026-09-15: **estilo plano** (se probó una variante pixel art del HUD y se
  descartó). Queda por reflejarlo en la tesis (brecha 4 de la sección 9).
- [x] **Rediseño del HUD plano + rangos por nivel + ranking** — implementado
  el 2026-09-16 (aprobado 2026-09-15). Todo el detalle y las medidas en
  `docs/diseno/hud_plano_2b.md` (sección "Desvíos respecto de la spec" para
  lo que cambió respecto del mockup 2a). Hecho:
  1. **Rangos uno por nivel completado** (Semilla → Brote N1 → Árbol N2 →
     Estratega N3 → Investigador N4-5 → EcoLíder con los 6) — `autoload/rangos.gd`.
  2. **Ranking arreglado** — `ranking_publico()` sobre `estudiantes`, nombre +
     inicial, XP, título y "(Tú)" por `user_id` (ver sección 4, "Ranking
     público").
  3. **HUD plano según la especificación 2b** — componentes
     `scenes/ui/hud_*.gd` (sección 3), tema centralizado, ficha con nivel y
     rango separados, panel GreenMetric 80/10/5/5 con
     desglose al pasar el mouse, 5 botones con teclas 1–5, banner de zona y
     aviso central con cola.
  4. **Verificación:** los 8 tests headless (`test_compila`, `test_puntaje`,
     `test_niveles`, `test_rangos`, `test_hud_tema`, `test_hud_paneles`,
     `test_hud_controles`, `test_hud_rango_aviso`) pasan; captura 1280×720
     revisada contra el mockup 2a (`tests/captura_hud.gd`/`.tscn`).
     **Pendiente:** prueba en el juego con la cuenta real del usuario,
     re-export web (`python scripts/exportar_web.py`) y merge/publicación —
     ninguno se hizo todavía porque falta el OK del usuario.
- [ ] **Antes de publicar lo del proyecto A:** el build de `docs/juego` es
  anterior a los últimos fixes (commit f3c6690) — re-exportar con
  `python scripts/exportar_web.py`. La prueba del usuario en escritorio salió
  bien el 2026-09-15 (categorías 80%, Energía 83% por quizzes, ambos quizzes
  registrados en `puntos_calidad`).
- [x] **El remoto de GitHub avisaba que el repo se movió** — resuelto
  2026-09-09: fue un cambio de username en GitHub (`thewasiii123` →
  `Ereyes05`), no un cambio de dueño. `origin` actualizado a
  `https://github.com/Ereyes05/green-metric-urbe.git`.
- [ ] **`sql/guardar_progreso_modulo.sql` y `sql/solicitudes_qr.sql`** son
  copias fieles de lo aplicado en Supabase — si se edita el esquema desde
  el dashboard sin actualizar estos archivos, quedan desincronizados.

## 9. El marco académico (la tesis) — leer antes de decidir diseño

Todo lo de esta sección sale de leer los capítulos de la tesis el
2026-09-11. Los documentos **no están en el repo** (viven fuera, en la
carpeta personal del autor) y **no deben commitearse**. Acá queda solo lo
que hace falta para tomar decisiones técnicas correctas.

### Título y objetivos

**Título:** *"Estrategias de gamificación aplicadas al aprendizaje de
indicadores GreenMetric para el empoderamiento estudiantil en la gestión
ambiental."*

Objetivos específicos (Cap. 1): (1) analizar conocimiento previo de los
estudiantes, (2) determinar requerimientos funcionales, (3) diseñar
lógicamente el entorno virtual, (4) construir el diseño físico, (5)
validar mediante pruebas técnicas, (6) **explicar el funcionamiento a
través del manual de usuarios**.

### Las dos variables (Cap. 2)

- **Estrategias de gamificación** (Deterding, 2022): usar elementos de
  diseño de juegos fuera de contextos lúdicos para satisfacer necesidades
  psicológicas de **competencia** y **autonomía**.
- **Empoderamiento estudiantil** (Zimmerman, 2015): **conciencia crítica**
  + **autoeficacia** + **participación** + **toma de decisiones**; el
  estudiante pasa de pasivo a proactivo.

**Definición operacional:** se mide *"mediante el monitoreo de la
interacción del usuario con las dinámicas y componentes del juego"* y la
evaluación del *"incremento en la autoeficacia y conciencia crítica"*.
👉 Ese monitoreo es la tabla `eventos_aprendizaje` — que hoy está
instrumentada solo en Nivel 5 (parcial) y Nivel 6. **La variable que da
nombre a la tesis se mide con una tubería a un tercio de cobertura.**

### Marco de diseño comprometido

La tesis se compromete con el **modelo DMC** (Werbach y Hunter, 2012) y el
**modelo MDA** (Hunicke, 2004). El Cap. 4 ya tiene escritas las 4
dinámicas (motivación por avanzar, aprendizaje por ensayo, sentido de
logro, curiosidad por explorar), las mecánicas, y 6 componentes: avatar,
puntos/XP, niveles, barra de progreso, insignias y mapa. Metodología:
Kendall y Kendall (ciclo de vida clásico) + Scrum.

### Historias de usuario (Cap. 4) y su estado real

| ID | Historia | Estado en el código |
|----|----------|---------------------|
| HU-001 | Registrarse | ✅ |
| HU-002 | Iniciar sesión | ⚠️ parcial — ver brecha 3 |
| HU-003 | Explorar la universidad | ✅ |
| HU-004 | Dialogar con NPC | ✅ |
| HU-005 | Consultar indicador GreenMetric | ✅ |
| HU-006 | Completar misión | ✅ |
| HU-007 | Clasificar residuos | ✅ |
| HU-008 | Responder a crisis ambiental | ✅ `crisis_evento.gd` |
| HU-009 | Subir de nivel | ✅ |
| HU-010 | Consultar mapa y estado de zonas | ✅ |
| HU-011 | Consultar progreso y ranking | ✅ |
| HU-012 | Gestionar EcoCredits en la tienda | ✅ desde 2026-09-14 (falta prueba con cuenta real) |

### Brechas detectadas entre lo que la tesis afirma y lo que el juego hace

1. ✅ ~~**El Cap. 4 afirma que el juego se exportó para la web y no lo
   está.**~~ Resuelta el 2026-09-11 (ver sección 8): el juego se sirve en
   **https://ereyes05.github.io/green-metric-urbe/juego/** y se re-exporta en
   cada publicación. Texto original de la brecha: la Tabla 33 dice textual
   *"Godot 4 | Motor con el que se creó el juego y se exportó para la web"*, y
   justifica la elección de Godot por poder abrirse *"desde el navegador sin
   necesidad de instalar nada"*. Era la brecha más verificable por un jurado
   (basta pedir la URL) — hoy la URL responde.
2. ✅ ~~**HU-012 "Tienda del Conocimiento" no existe.**~~ Resuelta el
   2026-09-14, ver sección 4. Texto original de la brecha: tiene criterios de
   aceptación escritos (compra exitosa/fallida, saldo nunca negativo, costo
   fijo, sin recompra, *"ciertas herramientas son requisito para completar
   misiones"*). **Bloqueante previo:** `EconomiaManager` no persiste nada —
   los EcoCredits arrancan en 0 cada sesión, así que primero hay que
   persistirlos por cuenta (mismo patrón que el Plan B de la sección 6).
3. ✅ ~~**HU-002 pide devolver al estudiante *"al punto exacto donde lo
   dejó"*.**~~ Resuelta el 2026-09-20. La posición se guarda por cuenta
   (`user://posicion_jugador_<uid>.dat`, misma ruta que el resto del estado
   local), cada 5 s si el jugador se movió más de 24 px, y además al salir de
   la escena. Al entrar se **valida** antes de usarla —dentro del mundo y a 14
   px de cualquier edificio de `colision_tilemap.gd`— porque un archivo de una
   versión anterior del mapa podría dejar al estudiante dentro de una pared y
   sin salida; si no pasa la validación, vuelve al Patio Central. Se le avisa
   con "📍 Seguimos donde lo dejaste".

   **Limitación conocida:** la posición es local, no del servidor. Si el
   estudiante entra desde otra computadora recupera todo su progreso pero
   aparece en el Patio Central. El criterio de aceptación formal de HU-002
   solo exige "el mapa en el último estado guardado con el nivel y la
   experiencia reflejados en el HUD", que sí se cumple en cualquier máquina;
   el "punto exacto" está en el párrafo descriptivo.
4. 🟡 **Conflicto de estilo visual.** La Tabla 2 del Cap. 4 reporta que el
   **65% de los encuestados eligió "diseño plano y minimalista"** y solo el
   **10% "estilo videojuego clásico (pixel art)"**; la conclusión escrita es
   que *"se debe implementar una interfaz basada en Flat Design y
   minimalista... evitando la saturación cognitiva"*. El juego es pixel art,
   y el login (2026-09-11) suma fondo pixel-art y fuente Press Start 2P.
   **Decisión pendiente y consciente del equipo**, no un descuido: o se
   ajusta el juego, o se justifica el desvío en la tesis.
   **Actualización 2026-09-16:** el HUD del mapa (la pantalla que más tiempo
   ve el estudiante) ya es Flat Design (`docs/diseno/hud_plano_2b.md`, y
   sección 3 y 8 de este documento). Sigue pendiente el login y cualquier
   otra pantalla en pixel art — la tesis tiene que reflejar el HUD nuevo y no
   puede seguir afirmando sin matices que "el juego es pixel art".
5.a ✅ ~~**El juego no llenaba la ventana del navegador.**~~ Resuelto y
   **verificado por el usuario en su navegador el 2026-09-24**: entra completo,
   el panel queda centrado y escala al achicar la ventana.

   Se conserva el diagnóstico porque fueron **dos** defectos distintos y el
   primer intento de arreglo empeoró el problema. Reportado por el usuario:
   *"cuando se abre el juego en la web no se abre completo"*. **No era el
   desvío móvil: era un defecto de escritorio.**

   - `html/canvas_resize_policy=1` ("Project"): `updateSize()` del motor
     escribe `canvas.style.width/height` en píxeles del tamaño del proyecto
     (1280x720) y pisa el `width:min(100vw, 100vh*16/9)` de la plantilla. En
     una laptop, con la barra del navegador, el borde inferior quedaba fuera.
     **Ese era el problema original.**
   - Pasar a `2` ("Adaptive") **solo** no alcanzaba: con esa política
     `_godot_js_display_setup_canvas()` fuerza `position:absolute; top:0;
     left:0` pero **no borra** el `transform:translate(-50%,-50%)` que la
     plantilla usa para centrar, y el lienzo quedaba corrido media pantalla
     arriba y a la izquierda, con el login fuera de vista.
   - El arreglo es la política 2 **más** quitarle ese centrado al CSS. Lo hace
     `parchear_canvas()` en `scripts/exportar_web.py` después de exportar; si
     Godot cambia su plantilla, esa función corta la exportación en vez de
     publicar una pantalla rota. El `.pck` y el `.wasm` no se tocan.

5. 🔴 **Requisito responsive/móvil — DESVÍO DECIDIDO (2026-09-20).** El
   equipo decidió que el alcance del juego es **navegador de escritorio
   únicamente**. No se va a probar ni adaptar a móvil.

   El problema no es técnico, es documental: la **Tabla 1 del Cap. 4 concluye
   textualmente que es *"mandatorio adoptar un enfoque multi-plataforma"***
   porque el 70% de la muestra usa móvil parcial o totalmente. Esa conclusión
   es del propio documento y sale de datos de encuesta que no se pueden
   cambiar. Queda una afirmación de la tesis que el producto entregado no
   cumple, y es de las pocas que un jurado puede verificar sin tocar el
   código: abre la URL en su teléfono.

   **Lo que hay que hacer, y es en el documento, no en el código:** declarar
   el alcance de escritorio de forma explícita en el Cap. 4 (alcance y
   limitaciones), de manera que la limitación esté declarada por los autores
   y no descubierta por el jurado. Una limitación declarada se lee como una
   decisión; una no declarada, como un incumplimiento.

   Estado del código: `touch_controls.gd` existe y sigue conectado
   (`SceneMapaMundo` lo instancia, `jugador.gd` lo lee), o sea que hoy el
   juego **carga igual** en un teléfono y se comporta de forma no verificada.
   Pendiente de decidir: mostrar un aviso de "abrir en computadora" en
   pantallas chicas, para que el alcance lo diga también el producto.

### Bug encontrado el 2026-09-11: el tutorial casi nadie lo ve

`scenes/ui/tutorial_onboarding.gd` **existe, está conectado y su contenido
es bueno** (4 pantallas: rol de Eco-Ranger, qué es GreenMetric con los 6
módulos, controles de teclado y móvil, y la primera misión concreta). El
problema es que se marca como visto en `user://tutorial_visto.dat`, que es
**por máquina, no por cuenta** — exactamente el mismo bug que tenía el
guardado antes del Plan B. En una sala de computación compartida, solo el
primer estudiante que se siente ve el tutorial; el resto entra sin ninguna
explicación. Lo mismo aplica a `hints_vistas.dat`.

## 10. Export web y publicación

Hecho el 2026-09-11, para cerrar la brecha 1 de la sección 9 (el Cap. 4
afirmaba que el juego ya estaba exportado a la web).

### Cómo regenerar el build

```
python scripts/exportar_web.py
```

**Usar el script, no el comando de Godot pelado.** Además de exportar, hace
dos cosas imprescindibles:

- **Le pone versión al `.pck`** (`index.pck?v=<hash>`). GitHub Pages manda
  `Cache-Control: max-age=600`, y como el archivo siempre se llama igual, el
  navegador se queda con el `.pck` viejo aunque el `index.html` sea nuevo.
  El resultado es un juego a medio actualizar — HTML nuevo, código viejo —
  que **parece un bug del juego y no lo es**. Ya nos pasó el 2026-09-11: se
  publicó el arreglo de los emoji y seguían viéndose cuadraditos. El `.wasm`
  no se versiona a propósito: pesa 39 MB y solo cambia al actualizar Godot.
- **Revisa que no se hayan empaquetado archivos sensibles** antes de
  publicar (ver la advertencia de abajo).

El preset vive en `export_presets.cfg` (versionado). Dos cosas de ahí que
**no hay que cambiar sin entender por qué están**:

- **`variant/thread_support=false`** — la variante con hilos de Godot 4
  exige las cabeceras COOP/COEP, y GitHub Pages no permite enviar
  cabeceras propias. Con hilos activados el juego no carga en Pages.
- **`exclude_filter`** — ver la advertencia de seguridad de abajo.

Las plantillas de exportación (~41 MB, solo las web) van en
`%APPDATA%\Godot\export_templates\4.7.stable\`. El paquete oficial
completo pesa 1.28 GB; alcanza con los cuatro `web_*.zip` y `version.txt`.

### ⚠️ Por qué `exclude_filter` no es opcional

El primer export empaquetó **`.mcp.json` dentro del `.pck`**, y ese archivo
contiene el **Personal Access Token de Supabase** (`sbp_...`, token de
administración de la cuenta). Godot 4 trata los `.json` como recursos, así
que `export_filter="all_resources"` se lo llevó puesto — aunque el archivo
esté en `.gitignore`, porque el `.gitignore` no tiene nada que ver con lo
que Godot exporta.

Lo detuvo **GitHub Push Protection** al intentar publicarlo; el token nunca
llegó a GitHub y el commit contaminado se deshizo antes de subirse. Pero el
riesgo real es claro: **cualquiera que descargue el juego exportado puede
abrir el `.pck` y leer lo que haya adentro.**

Regla a partir de ahora: **antes de publicar un build, verificar qué se
empaquetó.** El índice de archivos del `.pck` se guarda en texto plano, así
que basta con buscar rutas sospechosas:

```python
import re, pathlib
data = pathlib.Path('docs/juego/index.pck').read_bytes()
rutas = sorted(set(m.decode('latin1') for m in re.findall(rb'res://[A-Za-z0-9_./\-]{3,80}', data)))
print([r for r in rutas if r.endswith('.json') or 'mcp' in r or 'supabase' in r])
```

(Buscar el token como texto **no** sirve para descartar: el contenido de los
archivos va comprimido dentro del `.pck`. El índice de rutas sí es fiable.)

La anon key de Supabase sí está en el build y está bien que esté: es
pública por diseño y el cliente la necesita (la protección real es RLS).

### Publicación

Se publica desde **`docs/juego/` en la rama `main`**. No se usa una rama
`gh-pages` porque el push de esa rama fue rechazado por el mismo problema
del token (y una vez resuelto, publicar desde `docs/` evita tener que
crear y mantener una rama aparte).

`docs/juego/.nojekyll` existe para que Pages no procese la carpeta con
Jekyll y descarte archivos.

Pages quedó activo el 2026-09-11 (*Settings → Pages → Deploy from a branch
→ `main` / `/docs`*). **URL pública:**
**https://ereyes05.github.io/green-metric-urbe/juego/**

### ⚠️ Problemas propios del navegador (no se ven desde el editor)

Tres cosas que en escritorio funcionan y en web se rompían. Si algo "anda
en Godot pero no en la página", empezar por acá:

1. **Emoji como cuadraditos.** En escritorio Godot usa las fuentes del
   sistema para los glifos que le faltan; en el navegador no hay. Se
   empaqueta `assets/fonts/NotoColorEmoji-subset.ttf` (recortada a los 121
   emoji del juego, 192 KB) y `WindowManager` la registra como fallback.
   **Si se agregan emoji nuevos a la UI hay que regenerar el recorte**:
   ```
   pip install fonttools
   python -m fontTools.subset NotoColorEmoji.ttf --unicodes-file=unicodes.txt \
          --output-file=assets/fonts/NotoColorEmoji-subset.ttf
   ```
   (`unicodes.txt` = lista `U+XXXX` de los emoji usados en `scenes/` y
   `autoload/`; la fuente completa está en
   `github.com/googlefonts/noto-emoji/raw/main/fonts/NotoColorEmoji.ttf`).

2. **El progreso no carga: "Sin conexión: no pudo descomprimir (8)".**
   Resuelto el 2026-09-14. Causa: `HTTPRequest.accept_gzip` viene en `true`
   por defecto. En web el navegador ya descomprime las respuestas, pero
   Supabase expone el header `Content-Encoding: gzip` a JavaScript, así que
   Godot intentaba descomprimir **otra vez** JSON plano. El login andaba
   (auth no comprime) y todo `/rest/v1` fallaba. Arreglo: `accept_gzip`
   apagado solo en web (`SupabaseManager._ready`).
   - Detalle que despistó: Cloudflare manda las respuestas **chicas en
     Brotli** (que Godot no intenta descomprimir) y las **grandes en gzip**.
     Una prueba con una respuesta chica pasa aunque el bug esté presente.
   - Antes de dar con la causa se probó una hipótesis equivocada (que el
     problema era lanzar peticiones desde el callback de `request_completed`,
     commit `15d6a3d`). **Esa no era la causa.** El cambio quedó porque no
     hace daño y además agregó revisar el retorno de `request()` — sin eso,
     un fallo al lanzar una petición dejaba la cola trabada para siempre.

3. **El `.pck` viejo en caché.** Ver "Cómo regenerar el build" arriba.

**Autoprueba de red:** abrir el juego con **`?diag=red`** al final de la URL
(`.../juego/?diag=red`) hace una petición REST real sin necesidad de login e
imprime el resultado en la consola del navegador (F12). Sirve para
comprobar la capa HTTP del export web sin usar una cuenta real.

### Qué quedó verificado y qué no

- ✅ **El juego carga y muestra la pantalla de login en la URL pública**,
  verificado con un navegador headless contra el sitio real.
- ✅ Pages sirve los tipos MIME correctos, que es lo que más suele romper:
  `index.wasm` → `application/wasm` (si viniera como texto, el navegador
  rechaza el módulo y no arranca nada), `.pck` → `application/octet-stream`.
- ✅ Supabase responde al preflight CORS desde el origen de Pages
  (`Access-Control-Allow-Origin: *`).
- ✅ **Login con cuenta real y recuperación del progreso** — verificado por
  el usuario el 2026-09-14 en la URL pública (Nv.2, 1130 XP y los cuatro
  módulos completados aparecen igual que en escritorio), después del
  arreglo de `accept_gzip`.
- ✅ Iconos (emoji) y canvas a pantalla completa en 16:9 — verificados el
  mismo día.
- 🟡 **Rendimiento en el navegador: mejorando, todavía bajo.** En escritorio
  va fluido. WebGL está acelerado por hardware (no es renderizado por
  software). Arreglos medidos en el Chrome del usuario, en el mapa:
  - 2026-09-14: `mapa_campus.gd` redibujaba el campus entero en cada frame
    solo para mover 6 pájaros y 12 reflejos del lago. Ahora el campus se
    dibuja una vez y se anima una capa aparte → **11 → 14-15 FPS**.
  - 2026-09-14: perfilado por FPS (escritorio sin vsync, congelando un tipo
    de script a la vez, 3 repeticiones) mostró dos culpables claros:
    **NPCs (`npc.gd`, 30-39% del frame)** y **zonas de plantar
    (`zona_tierra.gd`, ~26%)**. Ambos redibujaban figuras complejas en cada
    frame para animar un balanceo de menos de 1 px, un brillo o un hoyo que
    late. Ahora se dibujan una vez y se anima posición/escala/transparencia
    (que no obliga a redibujar). Escritorio: **89 → 124-132 FPS**. Verificado
    por captura con todos los estados forzados (brillo de NPCs, hoyo, árbol
    adulto con cartel, indicador de agua). El usuario confirmó en la web
    que se nota "súper mejor" (sin número de FPS).
  - Descartados por la medición (eran ruido): `mision_bicicletero`,
    `mision_comite_ambiental`.
  - Todavía redibujan en cada frame: puntos de misión de los niveles 2-6,
    papeleras, llaves de agua. Medidos como costo menor; atacarlos solo si
    los FPS en web siguen bajos.
  - **Patrón a evitar en código nuevo:** `_process(): queue_redraw()` para
    animar algo que se puede animar moviendo, escalando o cambiando
    `modulate` del nodo. Redibujar solo cuando cambia lo que se dibuja.

### Cómo medir rendimiento sin engañarse (lecciones del 2026-09-14)

- **Usar FPS, no `TIME_PROCESS`.** Según `main.cpp` de Godot 4.7,
  `Performance.TIME_PROCESS` es el **peor** frame del último segundo e
  **incluye el dibujo y la presentación** (con vsync, también la espera).
  Sirve para ver tirones; para atribuir costos da resultados sin sentido.
- **No medir FPS en una ventana tapada.** Chrome frena a ~1 FPS las
  ventanas que otras tapan. Un navegador automatizado que se abre detrás
  del editor mide eso, no el juego. Un "1,0 FPS" clavado es la señal.
- **Comparar builds antes/después** en el mismo navegador, con la ventana
  adelante, sin tocar nada durante ~10 s. Es la única medición en la que
  se basaron las decisiones de arriba.
- ❌ Sin verificar: audio, guardado de misiones nuevas desde la web, y
  controles táctiles en móvil.

## 11. Cómo mantener este documento

**Regla:** cualquier cambio que agregue una tabla, una función/RPC, una
decisión de diseño no obvia, o que resuelva/agregue un pendiente de la
sección 8, actualiza este archivo en el mismo cambio (no después, no "en
algún momento"). Si estás trabajando con Claude Code: pedile explícitamente
que actualice `docs/ESTADO_PROYECTO.md` como parte de la tarea, no asumas
que lo hace solo.

Al actualizar:
- Sumá la fila/decisión nueva en la sección que corresponda.
- Si resolviste un pendiente de la sección 8, sacalo de ahí (o marcalo
  hecho con la fecha, si vale la pena el rastro).
- Actualizá la fecha y el commit de "Última actualización" al principio.
