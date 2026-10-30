// enviar_resumen — Edge Function
// GreenMetric_URBE — correo con el avance del estudiante
//
// El juego la llama después de guardar un test de cierre de nivel (o el
// test final): SupabaseManager.enviar_resumen(test_id). Manda al correo con
// el que el estudiante se registró su resultado en el test y sus
// estadísticas: avance por nivel, puntaje GreenMetric, XP, EcoCredits,
// puesto en el ranking e insignias.
//
// El usuario sale del JWT, nunca del cuerpo: nadie puede pedir el resumen
// de otro. Se despliega CON verificación de JWT (el default).
//
// Por qué Gmail y no el correo de Supabase: el servicio de fábrica solo
// entrega a las direcciones del equipo y admite ~2 mensajes por hora
// (docs/supabase_correos.md). Se usa una cuenta de Gmail del proyecto con
// contraseña de aplicación, por el puerto 465: las Edge Functions no dejan
// salir por el 25 ni el 587.
//
// Secretos (supabase secrets set ...): GMAIL_USER, GMAIL_APP_PASSWORD.
// Opcionales, para otro servidor SMTP (p. ej. Brevo) sin tocar el código:
// SMTP_HOST (smtp.gmail.com), SMTP_PORT (465) y MAIL_FROM (el remitente
// verificado; por defecto GMAIL_USER).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const GMAIL_USER = Deno.env.get("GMAIL_USER") ?? "";
const GMAIL_APP_PASSWORD = Deno.env.get("GMAIL_APP_PASSWORD") ?? "";
const SMTP_HOST = Deno.env.get("SMTP_HOST") || "smtp.gmail.com";
const SMTP_PORT = Number(Deno.env.get("SMTP_PORT") || "465");
const MAIL_FROM = Deno.env.get("MAIL_FROM") || GMAIL_USER;

// Espejo de NivelManager.NOMBRES_NIVEL / ICONOS_NIVEL y de rangos.gd.
const NIVELES: Record<string, string> = {
  "1": "🌿 Infraestructura y Entorno",
  "2": "⚡ Energía y Cambio Climático",
  "3": "♻ Manejo de Residuos",
  "4": "💧 Uso del Agua",
  "5": "🚲 Transporte Sostenible",
  "6": "📚 Educación e Investigación",
};
const RANGOS = ["Semilla", "Brote", "Árbol", "Estratega", "Investigador", "EcoLíder"];

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, prefer",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(cuerpo: unknown, status = 200): Response {
  return new Response(JSON.stringify(cuerpo), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

function escapar(t: string): string {
  return t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

type Par = { aciertos: number; total: number };
type Resumen = {
  nombre: string | null;
  xp: number;
  puesto: number | null;
  jugadores: number;
  ecocredits: number;
  puntaje: { total: number; categorias: Record<string, { total: number }> };
  niveles: Record<string, { hechas: number; total: number }>;
  tests: Record<string, Par>;
  insignias: string[];
};

function rango(r: Resumen): string {
  const completos = Object.values(r.niveles).filter((n) => n.total > 0 && n.hechas >= n.total).length;
  return RANGOS[completos >= 6 ? 5 : Math.min(completos, 4)];
}

function armarCorreo(r: Resumen, testId: string): { asunto: string; html: string } {
  const nombre = escapar((r.nombre ?? "").trim().split(/\s+/)[0] || "Eco-Ranger");
  const test = r.tests[testId];
  const esFinal = testId === "final";
  const nivel = testId.replace("nivel_", "");
  const asunto = esFinal
    ? "Terminaste URBE Rangers: tu resumen final"
    : `Completaste el Nivel ${nivel}: tu avance en URBE Rangers`;
  const titulo = esFinal
    ? "¡Terminaste los 6 niveles!"
    : `¡Completaste el Nivel ${nivel}: ${NIVELES[nivel] ?? ""}!`;

  const filas = Object.keys(NIVELES).map((n) => {
    const av = r.niveles[n] ?? { hechas: 0, total: 0 };
    const t = r.tests[`nivel_${n}`];
    const pts = r.puntaje?.categorias?.[n]?.total ?? 0;
    return `<tr>
      <td style="padding:6px 8px">${NIVELES[n]}</td>
      <td style="padding:6px 8px;text-align:center">${av.hechas} / ${av.total}</td>
      <td style="padding:6px 8px;text-align:center">${Math.round(pts)} / 100</td>
      <td style="padding:6px 8px;text-align:center">${t ? `${t.aciertos} / ${t.total}` : "—"}</td>
    </tr>`;
  }).join("");

  const insignias = r.insignias.length
    ? r.insignias.map((i) => escapar(i)).join(" · ")
    : "Todavía ninguna. ¡Sigue jugando!";

  const html = `<div style="font-family:Arial,sans-serif;max-width:620px;color:#1d2b22">
  <h2 style="color:#1f7a3a">${titulo}</h2>
  <p>Hola, ${nombre}. Este es tu avance en <b>URBE Rangers: Eco-Quest</b>.</p>
  ${test ? `<p style="font-size:18px">📝 En el test ${esFinal ? "final" : "del nivel"} acertaste
    <b>${test.aciertos} de ${test.total}</b> preguntas.</p>` : ""}
  <table style="border-collapse:collapse;width:100%;font-size:14px">
    <tr style="background:#e3f2e7">
      <th style="padding:6px 8px;text-align:left">Nivel</th>
      <th style="padding:6px 8px">Misiones</th>
      <th style="padding:6px 8px">Puntaje</th>
      <th style="padding:6px 8px">Test</th>
    </tr>${filas}
  </table>
  <p style="font-size:15px;line-height:1.7">
    🏅 Puntaje GreenMetric: <b>${Number(r.puntaje?.total ?? 0).toFixed(1)} / 100</b><br>
    🌱 Rango: <b>${rango(r)}</b><br>
    ⭐ XP: <b>${r.xp}</b> · 🪙 EcoCredits: <b>${r.ecocredits}</b><br>
    🏆 Puesto en el ranking: <b>${r.puesto ?? "—"} de ${r.jugadores}</b><br>
    🎖 Insignias: ${insignias}
  </p>
  <p style="color:#5b6b60;font-size:12px">Recibes este correo porque completaste un nivel del juego.
  Proyecto de tesis GreenMetric URBE.</p>
</div>`;
  return { asunto, html };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  if (req.method !== "POST") return json({ ok: false, error: "metodo" }, 405);
  if (!GMAIL_USER || !GMAIL_APP_PASSWORD) {
    console.error("enviar_resumen: faltan los secretos GMAIL_USER / GMAIL_APP_PASSWORD");
    return json({ ok: false, error: "sin_configurar" }, 500);
  }

  const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
  const { data: auth, error: errAuth } = await supabase.auth.getUser(jwt);
  if (errAuth || !auth?.user?.email) return json({ ok: false, error: "no_autenticado" }, 401);
  const user = auth.user;

  let testId = "";
  try {
    testId = String((await req.json())?.test_id ?? "");
  } catch { /* cuerpo inválido: cae en el chequeo de abajo */ }
  if (!/^(nivel_[1-6]|final)$/.test(testId)) return json({ ok: false, error: "test_inexistente" }, 400);

  const { data: fila, error: errFila } = await supabase
    .from("resultados_test")
    .select("correo_enviado_at")
    .eq("user_id", user.id)
    .eq("test_id", testId)
    .maybeSingle();
  if (errFila) {
    console.error("enviar_resumen:", errFila);
    return json({ ok: false, error: "servidor" }, 500);
  }
  if (!fila) return json({ ok: false, error: "test_no_registrado" }, 404);
  // Un correo por test: repetir la llamada no vuelve a mandarlo.
  if (fila.correo_enviado_at) return json({ ok: true, ya_enviado: true });

  const { data: resumen, error: errResumen } = await supabase
    .rpc("resumen_estudiante", { p_user: user.id });
  if (errResumen || !resumen) {
    console.error("enviar_resumen:", errResumen);
    return json({ ok: false, error: "servidor" }, 500);
  }

  const { asunto, html } = armarCorreo(resumen as Resumen, testId);
  const smtp = new SMTPClient({
    connection: {
      hostname: SMTP_HOST,
      port: SMTP_PORT,
      tls: true,
      auth: { username: GMAIL_USER, password: GMAIL_APP_PASSWORD },
    },
  });
  try {
    await smtp.send({
      from: `URBE Rangers: Eco-Quest <${MAIL_FROM}>`,
      to: user.email,
      subject: asunto,
      content: "auto",
      html,
    });
  } catch (e) {
    console.error("enviar_resumen: falló el envío:", e);
    return json({ ok: false, error: "smtp" }, 502);
  } finally {
    await smtp.close().catch(() => {});
  }

  await supabase
    .from("resultados_test")
    .update({ correo_enviado_at: new Date().toISOString() })
    .eq("user_id", user.id)
    .eq("test_id", testId);

  return json({ ok: true });
});
