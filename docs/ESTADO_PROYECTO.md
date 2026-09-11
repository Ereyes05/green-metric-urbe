# Estado del proyecto — GreenMetric URBE

Este documento es el contexto completo del proyecto para cualquiera que se
sume: qué es, qué hay hecho, por qué se hizo así, y qué falta. **Se actualiza
en cada cambio importante** — ver la sección final para las reglas de eso.

Última actualización: 2026-09-11 (rediseño del login + lectura de los
capítulos de la tesis, análisis de brechas y export web — ver secciones 9 y 10).

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
    audio, utilidades de ventana. `EconomiaManager` es puramente en memoria,
    no persiste a disco (arranca en 0 cada vez que se abre el juego).
- **`scenes/mapa/SceneMapaMundo.gd`** — el archivo más grande del proyecto
  (~2900 líneas). Mapa, HUD, sidebar, spawns de las 40 misiones, panel de
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
  ⚠️ Falta confirmar que los eventos llegan al servidor y no solo al log
  local — ver el pendiente correspondiente en la sección 8.
- **`estudiantes`** — perfil del estudiante (`xp_total`, etc.), creada por
  un trigger `on_auth_user_created`. El cliente Godot **nunca** la toca
  directo — solo la RPC (`security definer`) le suma XP.

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
- `_progreso_modulos` (el dict que pinta el sidebar) y los índices del HUD
  (💧🌿📚) **no se actualizan solos** al entrar — hay que sembrarlos desde
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
  `servicio_solicitado`. **Pendiente de verificar en el servidor:** correr
  el `grant` de `sql/eventos_aprendizaje.sql` y confirmar que los eventos
  están llegando de verdad (ver abajo).
- [ ] ⚠️ **Verificar que `eventos_aprendizaje` recibe los eventos.** El
  archivo `sql/eventos_aprendizaje.sql` no tenía `grant` — el mismo
  descuido que dejó `misiones_estudiante` sin permisos el 2026-09-02, donde
  las peticiones fallaban en silencio. Si falta, los eventos de Niveles 5 y
  6 de todo este tiempo podrían existir **solo** en el log local
  (`user://eventos_aprendizaje.jsonl`) y no en Supabase. Cómo comprobarlo,
  en el SQL Editor:
  ```sql
  select tipo_evento, count(*) from eventos_aprendizaje group by tipo_evento;
  ```
  Si devuelve 0 filas, correr el `grant` del archivo y volver a probar.
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
- [ ] 🔴 **HU-012 "Tienda del Conocimiento" no existe** — única historia de
  usuario de la tesis sin implementar. Requiere primero **persistir los
  EcoCredits** (`EconomiaManager` hoy no guarda nada, arrancan en 0 cada
  sesión). Criterios de aceptación ya escritos en el Cap. 4, ver sección 9.
- [x] **El tutorial de onboarding casi nadie lo ve** — resuelto el
  2026-09-11: `NivelManager.ruta_usuario()` centraliza los archivos de
  estado local por cuenta, y `tutorial_visto`/`hints_vistas` ahora lo usan.
  Efecto secundario buscado: quien ya lo había visto lo vuelve a ver una
  vez por cuenta.
- [ ] **Al volver, el juego no dice "dónde quedaste"** — HU-002 pide
  devolver al estudiante "al punto exacto donde lo dejó"; hoy se restaura el
  progreso pero no la posición ni se le comunica nada.
- [ ] **Decidir qué hacer con el conflicto pixel art vs Flat Design** — ver
  brecha 4 de la sección 9. Es una decisión del equipo, no un bug: o se
  ajusta el juego, o se justifica el desvío en la tesis. **Mientras no se
  decida, no invertir más en arte pixel.**
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
| HU-012 | Gestionar EcoCredits en la tienda | ❌ **no existe** |

### Brechas detectadas entre lo que la tesis afirma y lo que el juego hace

1. 🔴 **El Cap. 4 afirma que el juego se exportó para la web.** La Tabla 33
   dice textual *"Godot 4 | Motor con el que se creó el juego y se exportó
   para la web"*, y justifica la elección de Godot por poder abrirse *"desde
   el navegador sin necesidad de instalar nada"*. **No está exportado.** Es
   la brecha más verificable por un jurado (basta pedir la URL).
2. 🔴 **HU-012 "Tienda del Conocimiento" no existe.** Tiene criterios de
   aceptación escritos (compra exitosa/fallida, saldo nunca negativo, costo
   fijo, sin recompra, *"ciertas herramientas son requisito para completar
   misiones"*). **Bloqueante previo:** `EconomiaManager` no persiste nada —
   los EcoCredits arrancan en 0 cada sesión, así que primero hay que
   persistirlos por cuenta (mismo patrón que el Plan B de la sección 6).
3. 🟡 **HU-002 pide devolver al estudiante *"al punto exacto donde lo
   dejó"*.** Hoy se restaura el progreso (Plan B) pero no la posición en el
   mapa, y no se le comunica nada al estudiante al volver.
4. 🟡 **Conflicto de estilo visual.** La Tabla 2 del Cap. 4 reporta que el
   **65% de los encuestados eligió "diseño plano y minimalista"** y solo el
   **10% "estilo videojuego clásico (pixel art)"**; la conclusión escrita es
   que *"se debe implementar una interfaz basada en Flat Design y
   minimalista... evitando la saturación cognitiva"*. El juego es pixel art,
   y el login (2026-09-11) suma fondo pixel-art y fuente Press Start 2P.
   **Decisión pendiente y consciente del equipo**, no un descuido: o se
   ajusta el juego, o se justifica el desvío en la tesis.
5. 🟡 **Requisito responsive/móvil.** La Tabla 1 concluye que es
   *"mandatorio adoptar un enfoque multi-plataforma"* (70% de la muestra usa
   móvil parcial o totalmente). Existe `touch_controls.gd` y está conectado,
   pero el juego es 1280x720 de escritorio y no hay export web.

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

### Qué quedó verificado y qué no

- ✅ **El juego carga y muestra la pantalla de login en la URL pública**,
  verificado con un navegador headless contra el sitio real.
- ✅ Pages sirve los tipos MIME correctos, que es lo que más suele romper:
  `index.wasm` → `application/wasm` (si viniera como texto, el navegador
  rechaza el módulo y no arranca nada), `.pck` → `application/octet-stream`.
- ✅ Supabase responde al preflight CORS desde el origen de Pages
  (`Access-Control-Allow-Origin: *`).
- ❌ **Sin verificar: iniciar sesión de verdad y jugar** — login con
  credenciales reales, guardado de progreso, audio, y controles táctiles en
  móvil. Requiere una cuenta real, así que lo tiene que probar una persona.

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
