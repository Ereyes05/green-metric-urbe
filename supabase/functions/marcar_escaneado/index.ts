// marcar_escaneado — Edge Function
// GreenMetric_URBE — Nivel 3 (Manejo de Residuos)
//
// A esto apunta el link que codifica el QR que se muestra en el juego
// (zona_reciclaje.gd) cuando una papelera está llena. Un teléfono real
// abre este link al escanear el código — SIN estar logueado en el
// juego, sin sesión de Supabase de ningún tipo — así que esta función
// no puede depender de auth.uid(): usa la service_role key para
// escribir directo, bypasando RLS.
//
// Desplegar con --no-verify-jwt (ver README de despliegue en el repo):
// sin eso, el runtime de Supabase exige un JWT válido en el header
// Authorization, que un navegador de teléfono simplemente no manda al
// abrir un link. El gateway de Supabase (Kong) SÍ exige de todas
// formas que exista algún apikey reconocido — por eso la URL que
// codifica el QR incluye ?apikey=<anon key>, que es pública por diseño
// (ya viaja embebida en el cliente Godot).
//
// Nunca otorga XP ni toca progreso_estudiante/misiones_estudiante —
// solo marca esta fila. El único efecto real es que el juego, que está
// consultando esta tabla, ve escaneado=true y hace aparecer al
// trabajador animado. No dispara ninguna notificación a personal real
// de la URBE (eso quedó fuera de alcance a propósito).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Supabase fuerza el Content-Type de las respuestas de Edge Functions a
// text/plain sin importar lo que la función devuelva (limitación
// documentada de la plataforma, no algo que se pueda evitar desde el
// código) — así que no tiene sentido mandar HTML con estilos, el
// teléfono lo mostraría como texto crudo con las etiquetas visibles.
// Texto plano, prolijo, es lo que realmente se ve del otro lado.
function mensaje(texto: string, status = 200): Response {
  return new Response(texto, {
    status,
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
}

Deno.serve(async (req: Request) => {
  const token = new URL(req.url).searchParams.get("token");
  if (!token) {
    return mensaje("⚠ Código inválido: falta el identificador de la solicitud.", 400);
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

  // Solo actualiza si todavía no estaba escaneada — así el juego (que
  // detecta el cambio por polling) recibe un escaneado=true limpio una
  // sola vez, sin importar si el link se abre más de una vez.
  const { data, error } = await supabase
    .from("solicitudes_qr")
    .update({ escaneado: true, escaneado_en: new Date().toISOString() })
    .eq("token", token)
    .eq("escaneado", false)
    .select("mision_id")
    .maybeSingle();

  if (error) {
    console.error("marcar_escaneado:", error);
    return mensaje("⚠ Error del servidor. Intentá de nuevo en un momento.", 500);
  }

  if (!data) {
    // Ya estaba escaneada, o el token no existe/venció — mismo mensaje
    // para los dos casos: no hay nada útil que distinguir acá.
    return mensaje("✅ Solicitud ya enviada — GreenMetric URBE.\nEl servicio de limpieza ya fue notificado. Podés cerrar esta pestaña.");
  }

  return mensaje("✅ Solicitud enviada — GreenMetric URBE.\nEl servicio de limpieza fue notificado. Podés cerrar esta pestaña.");
});
