-- ============================================================
-- ranking_publico — tabla de clasificación sin datos sensibles.
-- Registro de la migración aplicada en Supabase (no re-ejecutar a mano).
--
-- Devuelve nombre + inicial del apellido, XP, niveles completos (para el
-- rango: ver autoload/rangos.gd) y el título de la tienda. NUNCA cédula,
-- correo ni user_id: "es_yo" se calcula acá con auth.uid(), así el cliente
-- no necesita ids ajenos para marcar "(Tú)".
-- Nivel completo = todas las misiones tipo 'mision' de esa categoría (según
-- el catálogo ACTUAL, catalogo_misiones) que estén en misiones_estudiante.
-- OJO: no es lo mismo que el rango que pinta el HUD. El servidor solo cuenta
-- el conjunto vigente; el cliente usa NivelManager.nivel_superado(), que
-- ADEMÁS acepta el conjunto de misiones legado (misiones_legado) para no
-- des-completar a quien ya había pasado un nivel con IDs viejos. Un jugador
-- que superó un nivel solo por el conjunto legado puede entonces mostrar un
-- rango más alto en el HUD que en este ranking.
-- ============================================================
create or replace function public.ranking_publico()
returns jsonb language sql stable security definer set search_path to 'public' as $$
  with totales as (
    select categoria, count(*) as total
    from catalogo_misiones where tipo = 'mision'
    group by categoria
  ), hechas as (
    select me.user_id, cm.categoria, count(distinct me.mision_id) as n
    from misiones_estudiante me
    join catalogo_misiones cm on cm.mision_id = me.mision_id and cm.tipo = 'mision'
    group by me.user_id, cm.categoria
  ), completos as (
    select h.user_id, count(*) filter (where h.n >= t.total) as niveles
    from hechas h join totales t using (categoria)
    group by h.user_id
  ), top as (
    select e.id, coalesce(e.xp_total, 0) as xp, coalesce(c.niveles, 0) as niveles,
           regexp_split_to_array(trim(coalesce(e.nombre, '')), '\s+') as p
    from estudiantes e
    left join completos c on c.user_id = e.id
    order by xp desc, niveles desc
    limit 50
  )
  select coalesce(jsonb_agg(jsonb_build_object(
           'nombre', case
              when t.p[1] = '' or array_to_string(t.p, ' ') ~ '@' then 'Eco-Ranger'
              when array_length(t.p, 1) = 1 then initcap(t.p[1])
              else initcap(t.p[1]) || ' '
                   || upper(left(t.p[case when array_length(t.p, 1) >= 4 then 3 else 2 end], 1)) || '.'
            end,
           'xp_total', t.xp,
           'niveles_completos', t.niveles,
           'titulo', (select c.nombre from inventario_estudiante i
                      join catalogo_tienda c on c.item_id = i.item_id
                      where i.user_id = t.id and c.item_id = 'titulo_embajador' limit 1),
           'es_yo', coalesce(t.id = auth.uid(), false)
         ) order by t.xp desc, t.niveles desc), '[]'::jsonb)
  from top t
$$;

revoke execute on function public.ranking_publico() from public;
grant  execute on function public.ranking_publico() to anon, authenticated;
