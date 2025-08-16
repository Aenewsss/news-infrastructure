/**
 * Worker cron – lê Redis Stream via Upstash REST, processa e avança cursor no KV.
 * Stream: env.STREAM_KEY (default: "views")
 * Cursor em KV: env.KV_CURSOR_KEY (default: "views:last_id")
 *
 * Formato esperado no stream (exemplo):
 * XADD views * articleId abc123 count 1 ts 1734384000
 */
export default {
    async scheduled(event, env, ctx) {
        const stream = env.STREAM_KEY || "views";
        const cursorKey = env.KV_CURSOR_KEY || "views:last_id";

        // 1) cursor atual; default "0-0" para ler tudo na primeira vez
        const lastId = (await env.CURSORS.get(cursorKey)) || "0-0";

        // 2) lê um lote sem bloquear (COUNT 200); usa XREAD
        const cmd = ["XREAD", "COUNT", "200", "STREAMS", stream, lastId];

        const res = await fetch(env.UPSTASH_REDIS_REST_URL, {
            method: "POST",
            headers: {
                Authorization: `Bearer ${env.UPSTASH_REDIS_REST_TOKEN}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ command: cmd })
        });

        if (!res.ok) {
            console.error("Upstash error", res.status, await safeText(res));
            return;
        }

        const data = await res.json();
        // Upstash resposta típica: [[stream, [[id, [k1, v1, k2, v2, ...]], ... ]]]
        const batch = normalizeXread(data);

        if (batch.length === 0) {
            console.log("No messages");
            return;
        }

        // 3) processa o lote (aqui só logamos; depois pluga no Neon)
        let newCursor = lastId;
        for (const item of batch) {
            // item: { id, fields: { articleId, count, ts, ... } }
            console.log("event:", JSON.stringify(item));
            newCursor = item.id;
        }

        // 4) salva cursor
        await env.CURSORS.put(cursorKey, newCursor, { expirationTtl: 60 * 60 * 24 * 7 }); // 7 dias ttl
        console.log("Updated cursor to", newCursor);
    }
};

async function safeText(res) { try { return await res.text(); } catch { return ""; } }

/** Converte retorno XREAD (Upstash REST) para array de {id, fields:{...}} */
function normalizeXread(json) {
    if (!Array.isArray(json) || json.length === 0) return [];
    // json[0] => [streamName, [[id, [k1, v1, ...]], ...]]
    const [, entries] = json[0];
    if (!Array.isArray(entries)) return [];
    return entries.map(([id, kv]) => ({ id, fields: arrayToObj(kv) }));
}

function arrayToObj(arr) {
    const obj = {};
    for (let i = 0; i < arr.length; i += 2) {
        const k = String(arr[i]);
        const v = arr[i + 1];
        obj[k] = v;
    }
    return obj;
}