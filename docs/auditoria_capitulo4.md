# Auditoría: lo que el Capítulo 4 promete vs. lo que el juego hace

**Fecha:** 2026-09-20 · **Método:** se leyó el texto de `Capítulo 4.docx` (solo lectura) y se verificó cada afirmación técnica contra el código del repositorio.

**Por qué existe este documento.** La tesis termina en el Capítulo 4, así que el entregable es el sistema y lo que un jurado revisa es si el sistema hace lo que el capítulo afirma. El capítulo tiene 18 tablas de instrumento (11 de encuesta a 20 estudiantes + 7 a la experta del Departamento de Sustentabilidad), y **el párrafo de conclusión de cada una declara un requisito técnico**. Cada uno de esos párrafos es una promesa verificable.

> Las citas son fragmentos cortos, lo mínimo para que cada fila sea comprobable. Los `.docx` no se tocaron ni se copiaron al repositorio.

---

## Resumen

| Tabla | Promete | Estado |
|---|---|---|
| 1 | *"mandatorio... Responsive Web Design"*, escritorio **y** móvil | 🔴 **No cumplido** |
| 2 | Flat Design y minimalista | 🟢 Cumplido (2026-09-20) |
| 3 | Barra de XP visible + Supabase en tiempo real | 🟢 Cumplido |
| 4 | Ranking global e interactivo | 🟢 Cumplido |
| 5 | Narrativa + desbloqueo secuencial de zonas | 🟢 Cumplido |
| 6 | *"motor de reglas en el backend"* de insignias, con rachas de acceso | 🟢 Cumplido (2026-09-23) |
| 7 | Trivia contrarreloj + módulo de simulación de decisiones | 🟢 Cumplido |
| 8 | *"se contempla"* Web Push API / Service Workers | 🟡 No existe, pero el verbo lo salva |
| 9 | Microlearning: sesiones de 10–15 min | 🟡 Medido el 2026-09-24 — parcial |
| 10 | Sistema de vidas + reposición con quiz remedial | 🟢 **Superada por la Tabla 15** (2026-09-20) |
| 11 | Tutorial interactivo **obligatorio** | 🟢 Cumplido (2026-09-20) |
| 12 | Progresión por rangos Semilla→Brote→Árbol→Estratega | 🟢 Cumplido |
| 13 | Simuladores de decisión sobre casos | 🟢 Cumplido |
| 14 | Eco-puntos canjeables **por insignias** | 🟢 Cumplido (2026-09-23) |
| 15 | Penalización + reintento, **sin bloqueo** | 🟢 Cumplido |
| 16 | Datos mixtos: campus real + estándar GreenMetric | 🟢 Cumplido |
| 17 | Zonas verdes (M1) y puntos de residuos (M3) | 🟢 Cumplido |
| 18 | Minijuego de clasificación con tiempo límite | 🟢 Cumplido |

**16 cumplidas, 1 parcial, 1 no cumplida.**

> **Actualizado el 2026-09-20** tras la primera tanda de arreglos: las Tablas
> 2, 10 y 11 pasaron a cumplidas. El detalle original de cada una se conserva
> abajo con la nota de cómo se resolvió.

---

## Las que no están (y la que se resolvió)

### Tabla 1 — Responsive Web Design 🔴

> *"es mandatorio adoptar un enfoque multi-plataforma mediante un diseño web adaptable (Responsive Web Design)... tanto en navegadores de escritorio como en dispositivos móviles"*

Y el párrafo anterior: *"el EVA no puede limitarse a una sola resolución de pantalla"*.

El juego es 1280×720 fijo. **El equipo decidió (2026-09-20) que el alcance es navegador de escritorio.** No alcanza con argumentar que "web ya es multi-plataforma": el texto nombra *Responsive Web Design* y *dispositivos móviles* de forma explícita.

Es la brecha más verificable de todas: el jurado abre la URL en su teléfono.

**Salida:** declarar el alcance de escritorio en *alcance y limitaciones*, y bajarle el tono a la palabra *"mandatorio"*, que es más fuerte de lo que el dato sostiene (35% smartphone, 35% indiferente, 30% escritorio no hace nada *mandatorio*). Una limitación declarada se lee como decisión; descubierta, como incumplimiento.

### Tabla 6 — Motor de insignias 🟢 (resuelta el 2026-09-23)

> *"se definirá un motor de reglas en el backend que dispare diferentes tipos de insignias o trofeos digitales... bonificadores por rachas de acceso continuo o medallas especiales por alcanzar la máxima calificación"*

Tres incumplimientos en una sola frase:

1. **No está en el backend.** `otorgar_insignia()` vive en `EconomiaManager` (cliente).
2. **No persisten.** `_insignias_obtenidas` es un array en memoria: se pierde al cerrar. Existen las tablas `insignias` e `insignias_estudiante` en Supabase y el juego no las usa.
3. **No hay rachas de acceso continuo.** La insignia `racha_fuego` ("Racha Ardiente") está declarada en el catálogo y **nunca se otorga**: no hay código que la dispare.

Lo que sí funciona: `m1..m6_completo`, `quiz_perfecto`, `crisis_resuelta` y `ecolider` se otorgan correctamente — pero solo hasta que cerrás el juego.

**Hallazgo posterior (2026-09-23): el capítulo lo afirma dos veces, y la segunda es peor.** El párrafo de la Fase III ("Integración de las mecánicas de gamificación en el código fuente") dice, en **pasado**: *"se integró el sistema de insignias, programando las condiciones que debe cumplir el estudiante para obtener cada recompensa **y guardándolas en su perfil**"*, y cierra con *"Todas estas mecánicas se conectaron con la base de datos, de modo que el progreso quedara guardado **de forma permanente**"*.

La Tabla 6 está en futuro ("se definirá") y se puede leer como planificación. **Este párrafo no**: es una afirmación sobre lo construido. Es el punto más falsable del capítulo — alcanza con completar un nivel, cerrar el juego, volver a entrar y pedir ver la insignia.

**RESUELTO el 2026-09-23.** Se implementó el motor en el servidor
(`sql/insignias_1_migracion.sql`, aplicada y verificada en producción):

- `catalogo_insignias` — nombres, íconos y descripciones en el servidor. El
  cliente ya no tiene copia propia.
- `insignias_obtenidas` — RLS de solo lectura propia; insert/update/delete
  revocados a `anon` y `authenticated`.
- `_insignias_merecidas(uuid)` — **las deriva** de lo que el servidor ya
  guarda: `misiones_estudiante` contra `catalogo_misiones` para m1..m6,
  eventos `respuesta_quiz` para `quiz_perfecto`, `crisis_resuelta`, y días
  calendario consecutivos para **`racha_fuego`**, que estaba declarada y no
  se otorgaba nunca. Con eso queda cubierto el *"bonificadores por rachas de
  acceso continuo"* de la tabla.
- `evaluar_insignias()` — única vía de escritura. El cliente no manda
  ninguna insignia, solo pide la evaluación, así que no puede otorgarse una
  que no ganó.

El párrafo de la Fase III (*"guardándolas en su perfil"*) queda verdadero
sin tocar el documento.

**Nota:** el diagnóstico previo confirmó que existen dos tablas viejas del
panel (`insignias`, `insignias_estudiante`) con otro diseño — ids `integer`,
columnas `condicion_tipo`/`condicion_valor`. No se tocaron. Quedan sin uso.

~~**Salida:** persistir insignias en Supabase es trabajo real (tablas ya existen, faltan las RPC y el cliente). Las rachas de acceso son una funcionalidad nueva. Alternativa: acotar la promesa del Capítulo 4 a lo que hay.~~

### Tabla 10 — Sistema de vidas 🟢 (resuelta por la Tabla 15)

> *"se establecerá un sistema de vidas representadas visualmente, de modo que el agotamiento de intentos restrinja temporalmente el acceso... ofreciendo la opción de reponer energía respondiendo a preguntas de menor dificultad"*

**Los 3 corazones del HUD son decorativos.** `energia_actual` arranca en 3 y nada la baja.

**Divulgación completa:** el código que implementaba esto (`on_fallo_quiz` con racha de fallos, `recuperar_con_remedial`, `recuperar_con_creditos` y 7 preguntas remediales) existía pero **nunca estuvo conectado a ninguna pantalla**, y se borró el 2026-09-20 en el commit `38b2d1a` durante la limpieza de código muerto. Está recuperable en git. Estaba muerto porque la funcionalidad quedó a medio hacer, no porque se hubiera descartado.

**RESUELTO el 2026-09-20.** Se siguió el criterio experto de la Tabla 15 (ver
abajo) y se quitó el sistema de energía completo, incluidos los 3 corazones
del HUD, que eran la única señal visual que contradecía esa decisión. La
promesa de la Tabla 10 no se cumple, pero está superada por un criterio de
mayor autoridad que el propio capítulo documenta.

---

## El hallazgo que ayuda: la Tabla 15 contradice a la Tabla 10

La **Tabla 10** es la encuesta a estudiantes: el 55% quiere vidas con bloqueo temporal.

La **Tabla 15** es la encuesta a la experta del Departamento de Sustentabilidad, y dice lo contrario:

> *"La opción seleccionada fue mostrar una penalización inmediata en la puntuación y permitir el reintento de la acción, **descartando el bloqueo temporal del avance**"*

Y el propio análisis del capítulo ya lo adopta: *"ante una respuesta incorrecta, el EVA no interrumpe la progresión, sino que aplica la penalización correspondiente y habilita un nuevo intento"*.

**Eso es exactamente lo que el juego hace hoy** — la Regla Mixta del Nivel 5: la opción contraproducente resta 1 punto, no gasta presupuesto y deja reintentar.

**Por lo tanto:** el sistema de vidas no es una deuda, es un criterio **superado por la autoridad experta**, y el capítulo ya documenta esa decisión. Solo hay que redactarlo así: preferencia estudiantil (Tabla 10) contra criterio experto (Tabla 15), se optó por el experto.

Quedaba un detalle cosmético — los 3 corazones del HUD contradecían el argumento — y **se quitaron el 2026-09-20** junto con el resto del estado de energía.

---

## Corrección de diagnóstico: el login y la "fuente pixel art"

La primera versión de esta auditoría decía que el login incumplía la Tabla 2
por usar **Press Start 2P**, repitiendo lo que afirmaba `ESTADO_PROYECTO.md`.
**Era incorrecto, y se verificó el 2026-09-20.**

El HUD plano —el que la propia auditoría daba por cumplido— usa esa misma
fuente en cuatro lugares: el nombre del jugador, el título del banner de zona,
el título "GreenMetric" y el número de puntaje. O sea que el sistema de diseño
del proyecto **es un híbrido deliberado**: Rubik para el cuerpo, Press Start 2P
para los acentos de identidad. El título del login en esa fuente es
*coherente con el sistema*, no una violación.

**El incumplimiento real era otro:** el login no usaba el sistema de diseño en
absoluto. Tenía **69 `Color()` escritos a mano**, parecidos a los del tema pero
nunca iguales (verde `#59F280` contra `#62D06A`, cian propio, texto propio),
radios distintos (14 y 11 contra 12 y 10) y **7 sombras proyectadas** —
el recurso menos "plano" que había. Login y juego se veían como dos productos.

**Qué se hizo:** `SceneLogin.gd` ahora importa `hud_tema.gd` y toma de ahí
colores, radios y semántica de los mensajes (aviso, error, en curso, éxito).
Se quitó la sombra proyectada del panel; el resplandor de foco y hover se
conserva, porque eso es respuesta a la interacción y no profundidad simulada.
El panel de login usa el mismo color que los del HUD pero al 96 % en vez del
86 %: en el mapa se apoya sobre césped plano, acá va sobre una ilustración con
mucho detalle y a esa transparencia el formulario perdía legibilidad.

Se conservaron las decisiones que el usuario había pedido explícitamente en su
momento: panel azul-cian en vez de verde, y botones de contorno en vez de
relleno sólido.

**La ilustración de fondo se deja como está.** Flat Design aplica a la interfaz
—paneles, tipografía, botones, controles—, no al arte del juego.

---

## Las parciales

| Tabla | Qué falta |
|---|---|
| **2** — Flat Design | ✅ **Resuelto el 2026-09-20.** Ver la corrección de diagnóstico abajo: el problema no era la tipografía sino que el login tenía su propia paleta. Ahora lee `hud_tema.gd`, igual que el HUD. |
| **8** — Push | No existe ningún módulo de notificaciones. El `serviceWorker` que aparece en el build es código propio de Godot, no un módulo de avisos. **Riesgo bajo:** el texto dice *"se contempla el desarrollo"*, que se lee como consideración de diseño, no como entrega. |
| **11** — Tutorial obligatorio | ✅ **Resuelto el 2026-09-20.** Dos correcciones: la marca de "visto" se escribía **antes** de mostrar el tutorial, así que si el estudiante cerraba el juego a mitad no lo veía nunca más — ahora se escribe al terminarlo. Y se quitó el botón "Saltar intro", que contradecía el *"obligatorio"* de la tabla. (La ruta del archivo ya era por cuenta, no por máquina: eso estaba desactualizado en `ESTADO_PROYECTO.md`.) |
| **14** — Eco-puntos canjeables por insignias | ✅ **Resuelto el 2026-09-23** (`sql/insignias_3_compras.sql`, aplicada y verificada). Los dos ítems de estatus de la tienda —`estela_hojas` (90 EC) y `titulo_embajador` (150 EC), tipo `avatar`, sin efecto mecánico— otorgan ahora su insignia del perfil, así que la frase *"canjear por insignias digitales de estatus dentro del perfil"* es literal. Las herramientas y bonificaciones no otorgan ninguna: habilitan misiones o dan bonos, no son estatus. Y `ecolider` cuenta solo las que se ganan jugando (`por_compra = false`), para que coronar el juego no dependa de gastar 240 EC en cosméticos. |

---

## Tabla 9 — Microlearning: medido el 2026-09-24

Se midió con `sql/metricas_microlearning.sql`. Resultado en dos partes:

**Lo que queda verificado.** Las misiones individuales se completan en menos de tres minutos: promedio **0,8 min**, máximo **2,7 min**, sobre **14 casos** (9 quizzes de NPC entre 0,3 y 0,7 min, y 5 misiones de campo entre 0,6 y 2,7 min). La afirmación *"no deben requerir más de 15 minutos para completarse"* se cumple con holgura. Esto es sólido.

**Lo que NO queda verificado.** El *"rango ideal de interacción continua por sesión entre los 10 y los 15 minutos"* no se observa. Midiendo **tiempo activo** —sumando los huecos entre acciones e ignorando los mayores a 5 minutos— los tramos por nivel dan entre **0,9 y 14,3 minutos**, y solo **1 de 14** cae en el rango declarado.

**Por qué no alcanza para concluir nada en contra.** Cada "recorrido" es la combinación (estudiante, sesión, nivel), o sea **un tramo de juego, no un nivel completo**. Un estudiante que hizo dos misiones del Nivel 2 en una sentada cuenta como un recorrido de 0,9 min. Se están midiendo fragmentos, no recorridos completos, así que el número no puede leerse como "un nivel dura un minuto". Con 2 estudiantes y 14 tramos, el dato no da para afirmar ni desmentir la promesa.

**Qué haría falta:** recorridos completos de estudiantes que jueguen un nivel de punta a punta. Eso llega con la **prueba de usabilidad con los 4 estudiantes piloto** (`docs/guia_prueba_usabilidad.md`). Conviene volver a correr la consulta después de esas sesiones.

**Sobre la limpieza del dato.** Sin descartar la inactividad, el Nivel 1 daba **783,9 minutos** (trece horas: alguien dejó la pestaña abierta). Con el umbral de 5 minutos baja a **4,1**. El umbral es una decisión declarada, no un dato, y está en una sola línea de la consulta para poder probarla con 3 y con 10 minutos y ver si la conclusión aguanta.

**Hallazgo de diseño, aparte de la tesis:** el **Nivel 5** es el único que se acerca al rango (14,3 min de promedio activo, máximo 25,2). Tiene sentido —9 misiones y un Plan de Movilidad con presupuesto— y es el único que roza el techo de 15 minutos que el propio capítulo declara.

---

## Prioridades sugeridas

**Documento (no requieren código):**
1. Declarar el alcance de escritorio y suavizar *"mandatorio"* — Tabla 1.
2. Redactar la decisión Tabla 10 vs. Tabla 15 como lo que es: criterio experto por encima de preferencia estudiantil.
3. Acotar la promesa de la Tabla 6 a las insignias que sí existen, o asumir el trabajo de persistirlas.

**Código, por relación esfuerzo/beneficio:**
1. ~~**Sacar los corazones del HUD**~~ ✅ hecho el 2026-09-20.
2. ~~**Tutorial obligatorio**~~ ✅ hecho el 2026-09-20.
3. **Login a Flat Design** — cierra la Tabla 2 completa y es la primera pantalla que se ve.
4. **HU-002** (*"al punto exacto donde lo dejó"*) — historia de usuario con criterio de aceptación escrito, a medio cumplir.
5. **Persistir insignias** — el más caro; solo si se decide cumplir la Tabla 6 en vez de acotarla.

**Fuera de esta lista** quedan el mapa nuevo, los minijuegos del proyecto C y la instrumentación de los niveles 1, 2 y 4: no los promete ninguna tabla del Capítulo 4.
