export default {
  async fetch(request, env) {
    if (request.method !== "POST") return new Response("Method Not Allowed", { status: 405 });

    const auth = request.headers.get("Authorization") || "";
    if (auth !== `Bearer ${env.REVALIDATE_TOKEN}`) return new Response("Unauthorized", { status: 401 });

    const { urls = [] } = await request.json().catch(() => ({ urls: [] }));
    if (!Array.isArray(urls) || urls.length === 0) {
      return new Response(JSON.stringify({ ok: true, purged: 0 }), { headers: { "Content-Type": "application/json" } });
    }

    // Purge no CF
    await fetch(`https://api.cloudflare.com/client/v4/zones/${env.CF_ZONE_ID}/purge_cache`, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${env.CF_API_TOKEN}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ files: urls })
    });

    // (Opcional) ISR revalidate do Next (se tiver handler):
    for (const u of urls) {
      await fetch(`${env.NEXT_REVALIDATE_URL}?path=${encodeURIComponent(new URL(u).pathname)}&secret=${env.NEXT_REVALIDATE_SECRET}`);
    }

    return new Response(JSON.stringify({ ok: true, purged: urls.length }), {
      headers: { "Content-Type": "application/json" }
    });
  }
}