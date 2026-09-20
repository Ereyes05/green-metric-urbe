# Auditoría: lo que el Capítulo 4 promete vs. lo que el juego hace

**Fecha:** 2026-09-20 · **Método:** se leyó el texto de `Capítulo 4.docx` (solo lectura) y se verificó cada afirmación técnica contra el código del repositorio.

**Por qué existe este documento.** La tesis termina en el Capítulo 4, así que el entregable es el sistema y lo que un jurado revisa es si el sistema hace lo que el capítulo afirma. El capítulo tiene 18 tablas de instrumento (11 de encuesta a 20 estudiantes + 7 a la experta del Departamento de Sustentabilidad), y **el párrafo de conclusión de cada una declara un requisito técnico**. Cada uno de esos párrafos es una promesa verificable.

> Las citas son fragmentos cortos, lo mínimo para que cada fila sea comprobable. Los `.docx` no se tocaron ni se copiaron al repositorio.

---

## Resumen

| Tabla | Promete | Estado |
|---|---|---|
| 1 | *"mandatorio... Responsive Web Design"*, escritorio **y** móvil | 🔴 **No cumplido** |
| 2 | Flat Design y minimalista | 🟡 Parcial — falta el login |
| 3 | Barra de XP visible + Supabase en tiempo real | 🟢 Cumplido |
| 4 | Ranking global e interactivo | 🟢 Cumplido |
| 5 | Narrativa + desbloqueo secuencial de zonas | 🟢 Cumplido |
| 6 | *"motor de reglas en el backend"* de insignias, con rachas de acceso | 🔴 **No cumplido** |
| 7 | Trivia contrarreloj + módulo de simulación de decisiones | 🟢 Cumplido |
| 8 | *"se contempla"* Web Push API / Service Workers | 🟡 No existe, pero el verbo lo salva |
| 9 | Microlearning: sesiones de 10–15 min | ⚪ Sin verificar (medible hoy) |
| 10 | Sistema de vidas + reposición con quiz remedial | 🔴 **No cumplido** — ver nota abajo |
| 11 | Tutorial interactivo **obligatorio** | 🟡 Existe, pero no es obligatorio |
| 12 | Progresión por rangos Semilla→Brote→Árbol→Estratega | 🟢 Cumplido |
| 13 | Simuladores de decisión sobre casos | 🟢 Cumplido |
| 14 | Eco-puntos canjeables **por insignias** | 🟡 Canjeables por herramientas, no por insignias |
| 15 | Penalización + reintento, **sin bloqueo** | 🟢 Cumplido |
| 16 | Datos mixtos: campus real + estándar GreenMetric | 🟢 Cumplido |
| 17 | Zonas verdes (M1) y puntos de residuos (M3) | 🟢 Cumplido |
| 18 | Minijuego de clasificación con tiempo límite | 🟢 Cumplido |

**11 cumplidas, 4 parciales, 3 no cumplidas, 1 sin verificar.**

---

## Las tres que no están

### Tabla 1 — Responsive Web Design 🔴

> *"es mandatorio adoptar un enfoque multi-plataforma mediante un diseño web adaptable (Responsive Web Design)... tanto en navegadores de escritorio como en dispositivos móviles"*

Y el párrafo anterior: *"el EVA no puede limitarse a una sola resolución de pantalla"*.

El juego es 1280×720 fijo. **El equipo decidió (2026-09-20) que el alcance es navegador de escritorio.** No alcanza con argumentar que "web ya es multi-plataforma": el texto nombra *Responsive Web Design* y *dispositivos móviles* de forma explícita.

Es la brecha más verificable de todas: el jurado abre la URL en su teléfono.

**Salida:** declarar el alcance de escritorio en *alcance y limitaciones*, y bajarle el tono a la palabra *"mandatorio"*, que es más fuerte de lo que el dato sostiene (35% smartphone, 35% indiferente, 30% escritorio no hace nada *mandatorio*). Una limitación declarada se lee como decisión; descubierta, como incumplimiento.

### Tabla 6 — Motor de insignias 🔴

> *"se definirá un motor de reglas en el backend que dispare diferentes tipos de insignias o trofeos digitales... bonificadores por rachas de acceso continuo o medallas especiales por alcanzar la máxima calificación"*

Tres incumplimientos en una sola frase:

1. **No está en el backend.** `otorgar_insignia()` vive en `EconomiaManager` (cliente).
2. **No persisten.** `_insignias_obtenidas` es un array en memoria: se pierde al cerrar. Existen las tablas `insignias` e `insignias_estudiante` en Supabase y el juego no las usa.
3. **No hay rachas de acceso continuo.** La insignia `racha_fuego` ("Racha Ardiente") está declarada en el catálogo y **nunca se otorga**: no hay código que la dispare.

Lo que sí funciona: `m1..m6_completo`, `quiz_perfecto`, `crisis_resuelta` y `ecolider` se otorgan correctamente — pero solo hasta que cerrás el juego.

**Salida:** persistir insignias en Supabase es trabajo real (tablas ya existen, faltan las RPC y el cliente). Las rachas de acceso son una funcionalidad nueva. Alternativa: acotar la promesa del Capítulo 4 a lo que hay.

### Tabla 10 — Sistema de vidas 🔴

> *"se establecerá un sistema de vidas representadas visualmente, de modo que el agotamiento de intentos restrinja temporalmente el acceso... ofreciendo la opción de reponer energía respondiendo a preguntas de menor dificultad"*

**Los 3 corazones del HUD son decorativos.** `energia_actual` arranca en 3 y nada la baja.

**Divulgación completa:** el código que implementaba esto (`on_fallo_quiz` con racha de fallos, `recuperar_con_remedial`, `recuperar_con_creditos` y 7 preguntas remediales) existía pero **nunca estuvo conectado a ninguna pantalla**, y se borró el 2026-09-20 en el commit `38b2d1a` durante la limpieza de código muerto. Está recuperable en git. Estaba muerto porque la funcionalidad quedó a medio hacer, no porque se hubiera descartado.

**Pero hay una salida buena, y sale del propio capítulo** — ver abajo.

---

## El hallazgo que ayuda: la Tabla 15 contradice a la Tabla 10

La **Tabla 10** es la encuesta a estudiantes: el 55% quiere vidas con bloqueo temporal.

La **Tabla 15** es la encuesta a la experta del Departamento de Sustentabilidad, y dice lo contrario:

> *"La opción seleccionada fue mostrar una penalización inmediata en la puntuación y permitir el reintento de la acción, **descartando el bloqueo temporal del avance**"*

Y el propio análisis del capítulo ya lo adopta: *"ante una respuesta incorrecta, el EVA no interrumpe la progresión, sino que aplica la penalización correspondiente y habilita un nuevo intento"*.

**Eso es exactamente lo que el juego hace hoy** — la Regla Mixta del Nivel 5: la opción contraproducente resta 1 punto, no gasta presupuesto y deja reintentar.

**Por lo tanto:** el sistema de vidas no es una deuda, es un criterio **superado por la autoridad experta**, y el capítulo ya documenta esa decisión. Solo hay que redactarlo así: preferencia estudiantil (Tabla 10) contra criterio experto (Tabla 15), se optó por el experto.

Queda un detalle cosmético: **si no hay vidas, los 3 corazones del HUD no deberían estar.** Sacarlos toma minutos y elimina la única evidencia visual que contradice el argumento.

---

## Las parciales

| Tabla | Qué falta |
|---|---|
| **2** — Flat Design | El HUD del mapa ya es plano (2026-09-16). **El login sigue en pixel art** con fuente Press Start 2P, y es la primera pantalla que ve el jurado. La Tabla 2 dice 65% plano contra 10% pixel art. |
| **8** — Push | No existe ningún módulo de notificaciones. El `serviceWorker` que aparece en el build es código propio de Godot, no un módulo de avisos. **Riesgo bajo:** el texto dice *"se contempla el desarrollo"*, que se lee como consideración de diseño, no como entrega. |
| **11** — Tutorial obligatorio | `tutorial_onboarding.gd` existe y su contenido es bueno, pero se marca como visto en `user://tutorial_visto.dat`, que es **por máquina, no por cuenta**. Y no es obligatorio: se puede cerrar. |
| **14** — Eco-puntos canjeables por insignias | Los EcoCredits se canjean por **herramientas y cosméticos** (kits, termo, credencial, estela, título), no por insignias. La promesa dice *"canjeables por insignias digitales de estatus"*. Está cerca: `titulo_embajador` y `credencial_voluntario` son cosméticos de estatus. Puede resolverse redactando, o renombrando esos ítems como insignias. |

---

## La que se puede cerrar con datos que ya tenés

**Tabla 9 — Microlearning, sesiones de 10 a 15 minutos.** Nadie lo verificó, pero `eventos_aprendizaje` ya guarda `mision_iniciada` y `mision_completada` con `creado_en`. La diferencia entre ambos **es** la duración de cada misión.

Es la única promesa del capítulo que podés **demostrar con evidencia del propio sistema** en vez de afirmarla. Ver `sql/metricas_tesis.sql`.

---

## Prioridades sugeridas

**Documento (no requieren código):**
1. Declarar el alcance de escritorio y suavizar *"mandatorio"* — Tabla 1.
2. Redactar la decisión Tabla 10 vs. Tabla 15 como lo que es: criterio experto por encima de preferencia estudiantil.
3. Acotar la promesa de la Tabla 6 a las insignias que sí existen, o asumir el trabajo de persistirlas.

**Código, por relación esfuerzo/beneficio:**
1. **Sacar los corazones del HUD** — minutos. Elimina la contradicción visual con la decisión de la Tabla 15.
2. **Tutorial: mover `tutorial_visto` a la cuenta** — es el mismo bug que ya se arregló para los EcoCredits, con el mismo patrón.
3. **Login a Flat Design** — cierra la Tabla 2 completa y es la primera pantalla que se ve.
4. **HU-002** (*"al punto exacto donde lo dejó"*) — historia de usuario con criterio de aceptación escrito, a medio cumplir.
5. **Persistir insignias** — el más caro; solo si se decide cumplir la Tabla 6 en vez de acotarla.

**Fuera de esta lista** quedan el mapa nuevo, los minijuegos del proyecto C y la instrumentación de los niveles 1, 2 y 4: no los promete ninguna tabla del Capítulo 4.
