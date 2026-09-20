-- ============================================================
-- metricas_tesis.sql — GreenMetric_URBE
--
-- Consulta de solo lectura para saber cuántos datos de proceso hay
-- recolectados. NO crea nada ni modifica nada: se pega tal cual en el SQL
-- Editor de Supabase (panel web → SQL Editor → New query → Run).
--
-- Para qué sirve: `eventos_aprendizaje` es la evidencia de proceso de la
-- tesis (qué decidió cada estudiante, cuándo, cuántas veces reintentó).
-- Al 2026-09-14 tenía 1 fila, porque hasta el 2026-09-11 casi nada
-- registraba eventos. Esta consulta dice cómo va la recolección real.
--
-- Se corre como el dueño del proyecto desde el panel, así que ve todas las
-- filas: el RLS de la tabla solo limita al cliente del juego, que únicamente
-- puede leer y escribir lo suyo.
-- ============================================================

-- ── 1. Resumen general ───────────────────────────────────────
select
  (select count(*) from estudiantes)                             as estudiantes_registrados,
  (select count(*) from eventos_aprendizaje)                     as eventos_totales,
  (select count(distinct user_id) from eventos_aprendizaje)      as estudiantes_con_eventos,
  (select count(distinct session_id) from eventos_aprendizaje)   as sesiones_de_juego,
  (select count(*) from misiones_estudiante)                     as misiones_completadas,
  (select count(distinct user_id) from misiones_estudiante)      as estudiantes_con_misiones,
  (select min(creado_en)::date from eventos_aprendizaje)         as primer_evento,
  (select max(creado_en)::date from eventos_aprendizaje)         as ultimo_evento;

-- ── 2. Eventos por tipo ──────────────────────────────────────
-- Dice QUÉ se está capturando. Si 'respuesta_quiz' y 'opcion_elegida' están
-- en cero, no hay con qué medir aprendizaje por repetición ni toma de
-- decisiones, que es el corazón del análisis.
select
  tipo_evento,
  count(*)                     as eventos,
  count(distinct user_id)      as estudiantes,
  max(creado_en)::date         as ultimo
from eventos_aprendizaje
group by tipo_evento
order by eventos desc;

-- ── 3. Eventos por nivel ─────────────────────────────────────
-- Dice QUÉ NIVELES se están jugando de verdad. Un nivel en cero es un nivel
-- del que la tesis no va a poder decir nada.
select
  nivel,
  count(*)                     as eventos,
  count(distinct user_id)      as estudiantes,
  count(distinct session_id)   as sesiones
from eventos_aprendizaje
group by nivel
order by nivel;

-- ── 4. Actividad por día (últimos 30 días) ───────────────────
-- Sirve para ver si la recolección está viva o se frenó.
select
  creado_en::date              as dia,
  count(*)                     as eventos,
  count(distinct user_id)      as estudiantes
from eventos_aprendizaje
where creado_en >= now() - interval '30 days'
group by dia
order by dia desc;

-- ── 5. Misiones completadas por categoría GreenMetric ────────
-- Cruce contra el catálogo vigente: una misión completada que ya no está en
-- el catálogo (pasó con el Nivel 5 viejo) no suma al puntaje de nadie.
select
  c.categoria,
  count(*)                     as completadas,
  count(distinct m.user_id)    as estudiantes
from misiones_estudiante m
join catalogo_misiones c on c.mision_id = m.mision_id
group by c.categoria
order by c.categoria;
