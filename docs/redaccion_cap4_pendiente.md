# Redacción pendiente del Capítulo 4

**Fecha:** 2026-09-23 · **Para:** Ramon, para revisar y pegar en `Capítulo 4.docx`.

Tres pasajes que cierran las brechas que quedaron abiertas en [auditoria_capitulo4.md](auditoria_capitulo4.md). Están redactados en el mismo registro impersonal del capítulo, pero **son borradores**: leelos, cambiá lo que no suene tuyo y verificá los números contra tu documento antes de pegarlos.

> Yo no toco los `.docx`. Estos textos salen de haber leído el capítulo y el código; la decisión de qué entra es tuya.

---

## 1. Tabla 1 — El alcance de escritorio

**El problema.** La conclusión del Ítem N° 1 afirma que *"es mandatorio adoptar un enfoque multi-plataforma mediante un diseño web adaptable (Responsive Web Design)... tanto en navegadores de escritorio como en dispositivos móviles"*, y el párrafo anterior remata que *"el EVA no puede limitarse a una sola resolución de pantalla"*. El juego entregado corre a 1280×720 en navegador de escritorio.

Es la brecha más fácil de verificar: alcanza con abrir la URL desde un teléfono.

### Edición A — bajarle el tono a la conclusión

La palabra *"mandatorio"* es más fuerte de lo que el dato sostiene: 35% prefiere smartphone, 35% es indiferente y 30% prefiere escritorio. Eso no hace mandatorio nada; hace *deseable* la cobertura amplia.

> **Reemplazar** la frase que empieza en *"Desde la perspectiva de la ingeniería del software..."* **por:**
>
> Desde la perspectiva de la ingeniería del software y el diseño de la interfaz de usuario (UI), la distribución de las preferencias señala como deseable un enfoque multi-plataforma mediante un diseño web adaptable (Responsive Web Design), que permita que las hojas de estilo y los componentes interactivos del modelo de gamificación se rendericen de forma óptima tanto en navegadores de escritorio como en dispositivos móviles. Dado que el 30% de la muestra se inclina por computadoras de escritorio o laptops y otro 35% declara utilizar ambos dispositivos de manera indistinta, el entorno de escritorio constituye la plataforma con mayor cobertura garantizada para la versión inicial del sistema, y es la que se adopta como alcance de esta investigación (véase el apartado de alcance y limitaciones).

### Edición B — declarar el alcance

El capítulo **no tiene** una sección de alcance y limitaciones: está organizado por fases de la metodología y cierra con *"queda construido el modelo físico del entorno virtual de aprendizaje..."*. Hay dos lugares razonables para esto, y conviene que lo consultes con tu tutor:

- **Opción 1 (recomendada):** un apartado corto al final del capítulo, después del párrafo que cierra la Fase III.
- **Opción 2:** en la delimitación de la investigación del Capítulo 1, si esa sección existe allí.

> **Texto a insertar, bajo el subtítulo "ALCANCE Y LIMITACIONES DE LA VERSIÓN ENTREGADA":**
>
> La versión del entorno virtual de aprendizaje entregada en esta investigación está delimitada al uso en navegadores web de escritorio, con una resolución base de 1280×720 píxeles. Esta delimitación responde a una decisión de alcance tomada por los investigadores: el desarrollo de una interfaz adaptable a dispositivos móviles, señalada como deseable en el análisis del Ítem N° 1, implica un rediseño del sistema de interfaz y de los controles de interacción que excede el tiempo previsto para la presente investigación.
>
> Cabe destacar que la elección del motor Godot 4 y su exportación a formato web (véase la Tabla 33) sí garantiza la independencia del sistema operativo: el entorno se ejecuta en cualquier computador con navegador —Windows, macOS o Linux— sin requerir instalación previa por parte del estudiante, lo que satisface el criterio de accesibilidad multi-plataforma en su dimensión de sistema operativo. La adaptación a pantallas de dispositivos móviles se plantea como recomendación para trabajos futuros.

**Por qué conviene:** una limitación declarada por los autores se lee como una decisión de alcance fundamentada. La misma limitación descubierta por el jurado se lee como un incumplimiento. El hecho es idéntico; el resultado en la defensa, no.

---

## 2. Tablas 10 y 15 — Por qué el juego no tiene vidas

**El problema.** La conclusión del Ítem N° 10 afirma que *"se establecerá un sistema de vidas representadas visualmente, de modo que el agotamiento de intentos restrinja temporalmente el acceso"*. El juego no tiene vidas.

**La salida está en tu propio capítulo.** El Ítem N° 15, del instrumento aplicado a la experta del Departamento de Sustentabilidad, dice lo contrario: *"La opción seleccionada fue mostrar una penalización inmediata en la puntuación y permitir el reintento de la acción, descartando el bloqueo temporal del avance"*. Y eso **sí** es lo que el juego implementa.

No es una deuda: es un criterio superado por una fuente de mayor autoridad, y el capítulo ya lo documenta. Solo falta que el texto lo diga.

> **Agregar** al final del análisis del Ítem N° 10:
>
> No obstante, este criterio fue posteriormente contrastado con el instrumento aplicado a la autoridad institucional en materia ambiental (véase el Ítem N° 15), donde se descarta de manera explícita el bloqueo temporal del avance y se opta por una penalización inmediata en la puntuación acompañada del reintento de la acción. Ante la divergencia entre la preferencia estudiantil, orientada al reto lúdico, y el criterio experto, orientado a la continuidad del proceso formativo, se adoptó este último por corresponder a la finalidad pedagógica del entorno. En consecuencia, el sistema implementado no restringe el acceso ante el error: aplica la penalización correspondiente sobre la puntuación del indicador, conserva el presupuesto o los recursos del estudiante y habilita un nuevo intento acompañado de retroalimentación educativa, convirtiendo el error en una oportunidad de aprendizaje y no en una sanción.

**Ya está respaldado por el código:** la Regla Mixta del Nivel 5 resta un punto en Decisiones, no gasta presupuesto y permite reintentar. Y el 2026-09-20 se quitaron los tres corazones del HUD, que eran la única señal visual que contradecía este argumento.

---

## 3. Tabla 6 y el párrafo de la Fase III — Las insignias

**Acá hay que decidir, no solo redactar.** Y es más grave que las dos anteriores, por dónde está escrito.

### Lo que el capítulo afirma

**Tabla 6**, en futuro: *"se definirá un motor de reglas en el backend que dispare diferentes tipos de insignias o trofeos digitales... bonificadores por rachas de acceso continuo o medallas especiales por alcanzar la máxima calificación"*.

**Fase III, "Integración de las mecánicas de gamificación en el código fuente"**, en pasado y de forma mucho más comprometida:

> *"se integró el sistema de insignias, programando las condiciones que debe cumplir el estudiante para obtener cada recompensa **y guardándolas en su perfil**. ... Todas estas mecánicas se conectaron con la base de datos, de modo que el progreso quedara guardado **de forma permanente**."*

### Lo que el código hace

| Afirmación | Realidad |
|---|---|
| "guardándolas en su perfil" | `_insignias_obtenidas` es un arreglo en memoria: se pierde al cerrar el juego |
| "conectadas con la base de datos" | Las tablas `insignias` e `insignias_estudiante` existen en Supabase y el juego **no las usa** |
| "motor de reglas en el backend" | `otorgar_insignia()` corre en el cliente |
| "rachas de acceso continuo" | La insignia `racha_fuego` está declarada y **nunca se otorga** |

Sí funcionan y se otorgan correctamente: `m1`–`m6_completo`, `quiz_perfecto`, `crisis_resuelta` y `ecolider`. Pero solo durante la sesión.

El párrafo de la Fase III está en **pasado** y es una afirmación sobre lo construido, no sobre lo planificado. Es el punto más falsable del capítulo: alcanza con completar un nivel, cerrar el juego, volver a entrar y pedir ver la insignia.

### Las dos salidas

**Opción A — Implementarlo.** Es la única brecha de código que queda y es abarcable: las tablas ya existen en Supabase, falta la función que las escriba y lea, y conectar el cliente. Se sigue el mismo patrón que `guardar_progreso_modulo`. Si elegís esta, el párrafo de la Fase III queda verdadero sin tocar una coma.

**Opción B — Ajustar el texto.** Si no hay tiempo:

> **Reemplazar** *"y guardándolas en su perfil"* **por:** *"y mostrándolas al estudiante en el momento en que las obtiene"*.
>
> **Reemplazar** *"Todas estas mecánicas se conectaron con la base de datos, de modo que el progreso quedara guardado de forma permanente"* **por:** *"Las mecánicas de puntuación y progresión por niveles se conectaron con la base de datos, de modo que el avance del estudiante quedara guardado de forma permanente y pudiera recuperarse en cualquier sesión posterior."*
>
> Y en la Tabla 6, cambiar *"se definirá un motor de reglas en el backend"* por *"se definió un motor de reglas"*, eliminando *"bonificadores por rachas de acceso continuo"*, que no se implementó.

**Mi recomendación: la Opción A.** El resto de la Fase III (puntos, niveles, progreso) sí está conectado a la base de datos y es verdadero; las insignias son la única excepción, y arreglarlas es menos trabajo que recortar el párrafo en tres lugares distintos sin que se note.

---

## Resumen

| # | Qué | Quién |
|---|---|---|
| 1 | Alcance de escritorio: suavizar *"mandatorio"* + declarar la limitación | Vos, en el `.docx` |
| 2 | Decisión Tabla 10 vs. 15 sobre las vidas | Vos, en el `.docx` |
| 3 | Insignias: **decidir** entre implementar o ajustar el texto | Vos decidís, yo implemento si elegís A |

Los dos primeros son pegar y revisar. El tercero es la única decisión de fondo que queda.
