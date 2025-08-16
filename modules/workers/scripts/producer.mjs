/**
 * Producer HTTP (com filtro de bots):
 * - POST / (JSON): { articleId: "abc123", count?: 1, ts?: Date.now() }
 * - Ignora crawlers/bots conhecidos (Googlebot, Bingbot, social scrapers, etc.)
 * - Enfileira no Upstash Redis Stream (XADD) apenas tráfego humano
 */
export default {
  async fetch(request, env) {
    // Preflight/CORS
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: cors() });
    }
    if (request.method !== "POST") {
      return new Response("Method Not Allowed", { status: 405, headers: cors() });
    }

    // --- Filtro de bots ---
    const ua = request.headers.get("user-agent") || "";
    if (isLikelyBot(ua)) {
      // Não conta view/like de crawler
      return new Response(JSON.stringify({ ok: true, skipped: "bot" }), {
        status: 204,
        headers: jsonCors()
      });
    }

    // Parse body
    let payload;
    try {
      payload = await request.json();
    } catch {
      return new Response(JSON.stringify({ error: "Invalid JSON" }), {
        status: 400,
        headers: jsonCors()
      });
    }

    const articleId = String(payload.articleId || "");
    const count = clampInt(payload.count ?? 1, 1, 10); // sanidade básica
    const ts = Number.isFinite(payload.ts) ? Number(payload.ts) : Date.now();

    if (!articleId) {
      return new Response(JSON.stringify({ error: "articleId is required" }), {
        status: 400,
        headers: jsonCors()
      });
    }

    // XADD <stream> * articleId <id> count <n> ts <ms>
    const cmd = [
      "XADD",
      env.STREAM_KEY || "views",
      "*",
      "articleId",
      articleId,
      "count",
      String(count),
      "ts",
      String(ts)
    ];

    const res = await fetch(env.UPSTASH_REDIS_REST_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${env.UPSTASH_REDIS_REST_TOKEN}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ command: cmd })
    });

    if (!res.ok) {
      const txt = await safeText(res);
      return new Response(
        JSON.stringify({ ok: false, error: "Upstash error", detail: txt }),
        { status: 502, headers: jsonCors() }
      );
    }

    const data = await res.json(); // normalmente retorna o ID da entrada
    return new Response(JSON.stringify({ ok: true, id: data }), {
      status: 202,
      headers: jsonCors()
    });
  }
};

// ---------- helpers ----------
function cors() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type"
  };
}
function jsonCors() {
  return { ...cors(), "Content-Type": "application/json" };
}
async function safeText(res) {
  try { return await res.text(); } catch { return ""; }
}
function clampInt(n, min, max) {
  const x = Math.floor(Number(n));
  if (!Number.isFinite(x)) return min;
  return Math.min(max, Math.max(min, x));
}

/**
 * Heurística simples de detecção de bots.
 * Bloqueia crawlers conhecidos (busca/SEO) e social scrapers (OG preview).
 * Evita substrings genéricas falsas-positivas quando possível.
 */
function isLikelyBot(ua) {
  const s = ua.toLowerCase();

  // Social scrapers / link previews
  if (
    s.includes("facebookexternalhit") ||
    s.includes("twitterbot") ||
    s.includes("slackbot") ||
    s.includes("discordbot") ||
    s.includes("linkedinbot") ||
    s.includes("whatsapp") ||
    s.includes("embedly") ||
    s.includes("pinterest") ||
    s.includes("skypeuripreview")
  ) return true;

  // Buscadores e SEO crawlers
  if (
    /googlebot|bingbot|duckduckbot|baiduspider|yandex(bot|images)|sogou|exabot|seznam|petalbot/i.test(ua) ||
    /ahrefsbot|semrushbot|mj12bot|dotbot|bytespider|spbot|coccocbot/i.test(ua)
  ) return true;

  // Heurística genérica: contém "bot" / "crawler" / "spider"
  // (cuidado com falso-positivo; mantemos por último)
  if (/\b(bot|crawler|spider)\b/i.test(ua)) return true;

  return false;
}