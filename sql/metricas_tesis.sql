-- ============================================================
-- metricas_tesis.sql — GreenMetric_URBE
--
-- Consulta de SOLO LECTURA para saber cuántos datos de proceso hay
-- recolectados. NO crea ni modifica nada.
--
-- CÓMO USARLA
--   1. Abrí https://supabase.com/dashboard/project/ikohikbpvtbvsgyumvbr/sql/new
--   2. Copiá el PASO 1 completo (hasta el punto y coma) y pegalo ahí.
--   3. Run (o Ctrl+Enter).
--
-- OJO: el editor de Supabase muestra solo el resultado de la ÚLTIMA
-- consulta. Por eso el PASO 1 es una sola consulta que devuelve todo junto.
-- Las del PASO 2 son para profundizar y van de a una por vez.
--
-- PARA QUÉ SIRVE: `eventos_aprendizaje` es la evidencia de proceso de la
-- tesis (qué decidió cada estudiante, cuándo, cuántas veces reintentó). Al
-- 2026-09-14 tenía 1 fila, porque hasta el 2026-09-11 casi nada registraba
-- eventos. Esto dice cómo va la recolección real.
--
-- Corre como dueño del proyecto desde el panel, así que ve todas las filas:
-- el RLS de la tabla solo limita al cliente del juego, que únicamente puede
-- leer y escribir lo suyo.
-- ============================================================


-- ════════════════════════════════════════════════════════════
-- PASO 1 — Pegá desde acá hasta el punto y coma del final
-- ════════════════════════════════════════════════════════════
select '1. resumen' as seccion, 'estudiantes registrados' as dato,
       count(*)::text as valor
  from estudiantes
union all
select '1. resumen', 'eventos de aprendizaje (TOTAL)', count(*)::text
  from eventos_aprendizaje
union all
select '1. resumen', 'estudiantes con al menos 1 evento', count(distinct user_id)::text
  from eventos_aprendizaje
union all
select '1. resumen', 'sesiones de juego distintas', count(distinct session_id)::text
  from eventos_aprendizaje
union all
select '1. resumen', 'misiones completadas', count(*)::text
  from misiones_estudiante
union all
select '1. resumen', 'estudiantes con misiones', count(distinct user_id)::text
  from misiones_estudiante
union all
select '1. resumen', 'primer evento', coalesce(min(creado_en)::date::text, 'sin datos')
  from eventos_aprendizaje
union all
select '1. resumen', 'ultimo evento', coalesce(max(creado_en)::date::text, 'sin datos')
  from eventos_aprendizaje

-- Qué se está capturando. Si 'respuesta_quiz' y 'opcion_elegida' están en
-- cero, no hay con qué medir aprendizaje por repetición ni toma de
-- decisiones, que es el corazón del análisis.
union all
select '2. eventos por tipo', tipo_evento, count(*)::text
  from eventos_aprendizaje
 group by tipo_evento

-- Qué niveles se juegan de verdad. Un nivel en cero es un nivel del que la
-- tesis no va a poder decir nada.
union all
select '3. eventos por nivel', 'nivel ' || nivel::text, count(*)::text
  from eventos_aprendizaje
 group by nivel

-- Si la recolección está viva o se frenó.
union all
select '4. eventos por dia (30 dias)', creado_en::date::text, count(*)::text
  from eventos_aprendizaje
 where creado_en >= now() - interval '30 days'
 group by creado_en::date

-- Misiones completadas cruzadas contra el catálogo vigente: una misión que
-- ya no está en el catálogo (pasó con el Nivel 5 viejo) no le suma puntaje
-- a nadie.
union all
select '5. misiones por categoria', 'categoria ' || c.categoria::text, count(*)::text
  from misiones_estudiante m
  join catalogo_misiones c on c.mision_id = m.mision_id
 group by c.categoria

 order by 1, 2;
-- ════════════════════════════════════════════════════════════
-- FIN DEL PASO 1
-- ════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════
-- PASO 2 — Para profundizar. Corré UNA por vez.
-- ════════════════════════════════════════════════════════════

-- 2.a) Detalle por tipo de evento, con quién y cuándo.
-- select tipo_evento, count(*) as eventos, count(distinct user_id) as estudiantes,
--        min(creado_en)::date as primero, max(creado_en)::date as ultimo
--   from eventos_aprendizaje group by tipo_evento order by eventos desc;

-- 2.b) Quiz: aciertos y reintentos. Es la medición de aprendizaje por
-- repetición — si intento_num nunca pasa de 1, nadie está reintentando.
-- select nivel, intento_num, correcto, count(*) as respuestas
--   from eventos_aprendizaje where tipo_evento = 'respuesta_quiz'
--  group by nivel, intento_num, correcto order by nivel, intento_num;

-- 2.c) Decisiones tomadas. El jsonb `detalle` no tiene una forma única: cada
-- misión guarda sus propias claves, así que se mira crudo.
-- select tipo_evento, mision_id, detalle, count(*) as veces
--   from eventos_aprendizaje
--  where tipo_evento in ('opcion_elegida', 'decision_tomada', 'opcion_quitada')
--  group by tipo_evento, mision_id, detalle order by veces desc limit 50;

-- 2.d) Cuánto avanzó cada estudiante (sin nombres: solo el id).
-- select user_id, count(*) as misiones, max(completada_at)::date as ultima
--   from misiones_estudiante group by user_id order by misiones desc;
