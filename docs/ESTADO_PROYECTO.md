# Estado del proyecto — GreenMetric URBE

Este documento es el contexto completo del proyecto para cualquiera que se
sume: qué es, qué hay hecho, por qué se hizo así, y qué falta. **Se actualiza
en cada cambio importante** — ver la sección final para las reglas de eso.

Última actualización: 2026-09-09 (commit `eb0747f` + fix de estilo del botón
del modal QR y actualización del remote de GitHub).

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
  **Cobertura incompleta:** solo la escriben `mision_movilidad.gd`,
  `mision_comite_ambiental.gd`, `mision_malla_verde.gd` y
  `mision_semana_verde.gd` — es decir, Nivel 5 (solo la parte de movilidad)
  y todo Nivel 6. Niveles 1-4 nunca llaman `registrar_evento()`. No es un
  bug de red, es que nadie instrumentó esas misiones — pendiente si se
  quiere el log de proceso completo para la tesis.
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
  `DATOS_PUNTOS_CAPTACION`) se calcularon como punto medio entre pares de
  puntos ya verificados, **nunca confirmadas visualmente en el editor**.
  Probablemente estén bien, pero es una suposición, no un hecho verificado.
- **Nivel 5 (Transporte)**: probado en vivo al menos una vez (sesión del
  2026-09-02, confirmó que el guardado funciona).
- **Nivel 6 (Educación)**: igual que Nivel 4 — **nunca verificado
  visualmente**. Es el nivel más nuevo del proyecto.

Si alguien va a tocar posiciones de Nivel 4 o 6, verificarlas en el editor
antes de asumir que están bien — no repetir el error de asumirlo por
geometría sola.

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
- [ ] **Posiciones de Nivel 4 y 6 nunca verificadas visualmente** — ver
  sección 5.
- [ ] **Cobertura de `registrar_evento()`** — solo Nivel 5 (movilidad) y
  Nivel 6. Si se quiere el log de proceso completo para la tesis, falta
  instrumentar Niveles 1-4.
- [ ] **XP validado solo del lado del cliente en su primer envío** — ver
  sección 6, "Modelo de confianza".
- [ ] **Migración a TileMaps** — evaluado (2026-09-09), no iniciado. Hace
  falta un tileset real (arte) antes de poder empezar; la lógica de juego
  no depende del mapa visual, pero reubicar las ~40 posiciones de misiones/
  NPCs sobre la nueva grilla va a necesitar verificación visual, no solo
  matemática.
- [ ] **Export Web/HTML5** — no configurado. Decisión consciente: no hace
  falta mientras las pruebas se hagan desde el editor (F5).
- [x] **El remoto de GitHub avisaba que el repo se movió** — resuelto
  2026-09-09: fue un cambio de username en GitHub (`thewasiii123` →
  `Ereyes05`), no un cambio de dueño. `origin` actualizado a
  `https://github.com/Ereyes05/green-metric-urbe.git`.
- [ ] **`sql/guardar_progreso_modulo.sql` y `sql/solicitudes_qr.sql`** son
  copias fieles de lo aplicado en Supabase — si se edita el esquema desde
  el dashboard sin actualizar estos archivos, quedan desincronizados.

## 9. Cómo mantener este documento

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
