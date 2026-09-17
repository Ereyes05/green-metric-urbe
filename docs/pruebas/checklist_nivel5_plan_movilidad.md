# Checklist de prueba del Nivel 5 — Plan de Movilidad (cuenta real)

Esta checklist es para que **jueges con tu cuenta real** el Nivel 5 nuevo
(Plan de Movilidad, proyecto B del puntaje GreenMetric) **antes de publicar**
— después de aplicar la migración de misiones y de re-exportar, y antes del
push/merge final. Ver `docs/ESTADO_PROYECTO.md`, sección 8 ("Proyecto B —
Nivel 5 nuevo") y el diseño completo en
`docs/superpowers/specs/2026-09-17-nivel5-plan-movilidad-design.md`.

## Orden de publicación

1. **Re-exportar el cliente web:** `python scripts/exportar_web.py`.
2. **Verificar el `.pck`** — que no se haya empaquetado nada sensible (el
   script de comprobación está en `docs/ESTADO_PROYECTO.md`, sección 10,
   "⚠️ Por qué `exclude_filter` no es opcional").
3. **Aplicar la migración `nivel5_plan_movilidad_misiones`**
   (`sql/nivel5_plan_movilidad.sql`, sección 10.2 del diseño) — recién en
   este punto el catálogo del servidor pasa de los 8 IDs viejos (`mov_*`,
   `bicicletero_bloque_e`, `bicicletero_cafetin`) a los 9 `tr_*` nuevos.
4. **Correr esta checklist con tu cuenta real** (con el código de esta rama,
   ya sea en el editor o con el build recién exportado). Si algo falla,
   **no sigas al paso 5** hasta resolverlo.
5. **Push / merge** — recién ahí el juego publicado queda al día.

**Por qué la migración va antes del push/merge y no al revés:** la
migración y la publicación comparten el mismo Supabase de producción, sin
entorno de prueba aparte. Si se aplicara la migración **antes** de tener
listos los pasos 1-2 (o mucho antes del push/merge del paso 5), el juego
*publicado* — que todavía guarda las misiones con los IDs viejos `mov_*` —
quedaría leyendo un catálogo que ya no los tiene: **el Avance de Transporte
de todos los jugadores activos caería a 0** hasta que el cliente nuevo (que
guarda `tr_*`) quedara publicado. Por eso los pasos 3, 4 y 5 se hacen
seguidos, sin dejarlos para otro día.

## Cómo probar

Jugá con tu cuenta real (la que ya tiene progreso) y, si podés, con una
cuenta nueva para el punto 10. Para cada paso, fijate en lo que se describe
en "Qué vas a ver".

### 1. Cuentas y desbloqueo

**Qué hacer:** iniciá sesión con una cuenta que tenga el Nivel 4 completo.

**Qué vas a ver:** en el mapa aparecen los 10 puntos del Nivel 5 (Oficina, 6
decisiones, 2 bicicleteros, Consejo) y el Avance de Transporte del HUD
arranca en 0/9.

**Con una cuenta que tenía el Nivel 5 viejo completo** (los 6 escenarios y
los 2 bicicleteros de antes): el Nivel 6 sigue abierto — no se te bloqueó
nada —, pero el Nivel 5 aparece reabierto con el Plan de Movilidad en 0/9.

### 2. Oficina de Movilidad → encargo

**Qué hacer:** acercate al punto de la Oficina y presioná `E`.

**Qué vas a ver:** el encargo — presentar un Plan de Movilidad al Consejo
con 100 puntos de presupuesto — con un botón para aceptarlo. Al aceptar, los
6 puntos de decisión y los 2 bicicleteros dejan de estar `🔒 bloqueados` y
pasan a pendientes. Si volvés a la Oficina después, ves el tablero del plan
(presupuesto comprometido/restante y el estado de cada decisión).

### 3. Una decisión normal (válida)

**Qué hacer:** ir a cualquier punto de decisión (por ejemplo `tr_permisos`,
en la garita del Estacionamiento M5), elegir una de las dos opciones
**válidas** y confirmar.

**Qué vas a ver:** antes de confirmar, solo el **costo** de cada opción,
sin impacto. Después de confirmar, se revelan las consecuencias de **las 3**
opciones (Transporte, aceptación, costo, explicación GreenMetric), con la
elegida resaltada. El presupuesto restante del tablero baja por el costo. La
misión se completa (aviso de misión/XP, salvo el caso sin pago del punto
10).

### 4. Una decisión contraproducente + reintento

**Qué hacer:** en otra decisión, elegí la opción marcada como
contraproducente y confirmá.

**Qué vas a ver:** se revela **solo esa opción**, con el aviso "Opción
contraproducente: -1 en Decisiones de Transporte. El presupuesto no se
gastó; puedes reintentar." En el panel GreenMetric del HUD (categoría
Transporte, componente Decisiones) el número baja 1 punto. El presupuesto
del tablero de la Oficina **no cambia**. Al presionar "Reintentar", esa
opción queda descartada (deshabilitada) y tenés que elegir una de las otras
dos.

### 5. Cambiar una decisión antes del Consejo

**Qué hacer:** volvé a un punto de decisión ya resuelto con una opción
válida y confirmá una opción **distinta**.

**Qué vas a ver:** se aplica el cambio (nuevo costo, nuevas consecuencias) y
el presupuesto del tablero se recalcula. Este cambio es libre porque todavía
no presentaste el plan al Consejo — una vez presentado, los cambios solo se
hacen desde el panel del Consejo y cuentan contra el máximo de 2 (punto 7).

### 6. Los dos bicicleteros (kit obligatorio)

**Qué hacer:** ir a un bicicletero sin el `kit_bicicletero` comprado.

**Qué vas a ver:** un aviso de que falta la herramienta, con acceso directo
a la Tienda del Conocimiento. Comprá el kit (60 EC) y volvé: ahora se abre
la decisión de **tipo** de bicicletero (techado con panel solar / simple sin
techo / ganchos en el sendero, esta última contraproducente), con el mismo
patrón de costo → confirmar → revelar que las decisiones normales. Repetí
en el segundo bicicletero — el mismo kit sirve para los dos.

### 7. Consejo Universitario (Rectorado)

**Qué hacer:** con las 8 decisiones resueltas, ir al Rectorado.

**Qué vas a ver:** un panel de revisión con cada decisión (opción elegida,
aceptación, costo), el presupuesto restante y "Cambios disponibles: 2".
Probá el botón "Cambiar" en una decisión: abre el panel de decisión en modo
Consejo; al volver, el contador de cambios disponibles bajó a 1.

Al presionar "Presentar": aparecen **3 objeciones**, cada una con 3
argumentos. Elegí a propósito un argumento incorrecto primero: se explica
por qué no convence y podés reintentar la **misma** objeción sin perder las
otras dos. Elegí después el correcto para avanzar.

Al terminar las 3: pantalla de resultado con los aciertos, la calificación
("Aprobado sin observaciones" / "Aprobado" / "Aprobado con observaciones" /
"Aprobado con condiciones") y la "Calificación estimada del plan (Decisiones
de Transporte)". Tras presentar, el plan queda cerrado: los puntos de
decisión pasan a "Listo" de solo lectura — no se puede volver a presentar.

### 8. Cambios visibles en el mapa y sinergias

**Qué hacer:** después del Consejo, recorré el mapa.

**Qué vas a ver:** los cambios elegidos anclados a sus lugares — por
ejemplo, si elegiste la ciclovía en `tr_lote`, se ve dibujada en el lote; si
elegiste la flota eléctrica, el vehículo cambia de aspecto en la zona de
mantenimiento; si elegiste un bicicletero techado, se ve el techo/panel.
También deben aparecer los avisos "✨ Sinergia" que correspondan a tu plan
(por ejemplo 🌿 Entorno, ⚡ Energía, 📚 Educación, según lo que elegiste), y
esas categorías suben en el panel GreenMetric del HUD (componente
Sinergias).

### 9. El número de Transporte es el mismo en todos lados

**Qué hacer:** después del Consejo, comparar la barra de Transporte en
cuatro lugares distintos.

**Qué vas a ver:** la barra del HUD, el mapa de calor, la pantalla de
resultados y el informe final muestran **el mismo número** para la
categoría Transporte.

### 10. Caso sin XP/EC (cuenta con el Nivel 5 viejo completo)

**Qué hacer:** con la cuenta del punto 1 que ya tenía el Nivel 5 viejo
completo, terminá todo el Plan de Movilidad nuevo. Después, repetí lo mismo
con una cuenta **nueva** (sin ese legado), para comparar.

**Qué vas a ver:** con la cuenta legado, las misiones `tr_*` y el nivel se
completan igual (los avisos de misión/nivel se ven normal), pero el XP
total y los EcoCredits **no suben** por esas misiones ni por el bono de
nivel. El Avance de Transporte del panel GreenMetric **sí sube** con cada
`tr_*` completada. Con la cuenta nueva, las mismas misiones **sí** pagan XP
y EC.

### 11. Verificación en Supabase

**Qué hacer:** abrir el dashboard de Supabase (proyecto
`ikohikbpvtbvsgyumvbr`) y revisar, para tu cuenta de prueba:

- `detalles_estudiante`: una fila con clave `plan_movilidad` y el JSON de
  decisiones/Consejo.
- `puntos_calidad`: filas con `ref` tipo `decision:tr_*` (opciones válidas
  elegidas), `penal:tr_*:1` (o `:2`/`:3`, si probaste la contraproducente
  más de una vez) y `sinergia:*` (los cruces que ganaste).
- `eventos_aprendizaje`: filas con `tipo` `decision_tomada` (una por
  decisión confirmada), `argumento_consejo` (una por intento de argumento) y
  `plan_presentado` (una, al presentar).
