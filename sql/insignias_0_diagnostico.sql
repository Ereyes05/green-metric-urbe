-- ============================================================
-- PASO 0 — DIAGNÓSTICO (no cambia nada)
-- GreenMetric_URBE — insignias
--
-- Panel: https://supabase.com/dashboard/project/ikohikbpvtbvsgyumvbr/sql/new
-- Abrí este archivo, seleccioná TODO (Ctrl+A), copiá (Ctrl+C), pegalo en el
-- editor y dale Run. Te va a devolver una tablita: copiámela.
-- ============================================================

-- Hay dos tablas `insignias` e `insignias_estudiante` creadas a mano en el
-- panel que el juego nunca usó, y su definición no está en el repositorio.
-- Esto dice qué tienen adentro. No las toca. Si no devuelve NINGUNA fila,
-- es que no existen, y está perfecto: seguí con el PASO 1 igual.

select c.table_name, c.column_name, c.data_type, c.is_nullable
  from information_schema.columns c
 where c.table_schema = 'public'
   and c.table_name in ('insignias', 'insignias_estudiante')
 order by c.table_name, c.ordinal_position;
