/**
 * Worker cron – lê Redis Stream via Upstash REST, processa e avança cursor no KV.
 * Stream: env.STREAM_KEY (default: "views")
 * Cursor em KV: env.KV_CURSOR_KEY (default: "views:last_id")
 *
 * Formato esperado no stream (exemplo):
 * XADD views * articleId abc123 count 1 ts 1734384000
 */
import { neon, neonConfig } from "@neondatabase/serverless";

export default {
    async scheduled(event, env, ctx) {
        const started = Date.now();

        try {
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

            // 3) agrega por articleId
            const counters = new Map(); // articleId -> soma
            let newCursor = lastId;

            for (const item of batch) {
                const aId = String(item.fields.articleId || "");
                const inc = Number(item.fields.count ?? 1) || 0;
                if (aId && inc) counters.set(aId, (counters.get(aId) || 0) + inc);
                newCursor = item.id; // último processado
            }

            // 3.5) se não houve eventos válidos, só avança cursor e retorna
            if (counters.size === 0) {
                await env.CURSORS.put(cursorKey, newCursor, { expirationTtl: 60 * 60 * 24 * 7 });
                console.log("No valid items; cursor advanced to", newCursor);
                return;
            }

            neonConfig.fetch = fetch; // obrigatório em Workers
            const sql = neon(env.NEON_DATABASE_URL);

            await sql`BEGIN`;
            try {
                for (const [articleId, viewsInc] of counters.entries()) {
                    const v = BigInt(viewsInc || 0);
                    await sql`
                        INSERT INTO article_metrics (article_id, views, likes, updated_at)
                        VALUES (${articleId}, ${v}, 0, now())
                        ON CONFLICT (article_id) DO UPDATE
                        SET
                        views      = article_metrics.views + EXCLUDED.views,
                        updated_at = now()
                    `;
                }

                // (Opcional) rollup diário
                for (const [articleId, viewsInc] of counters.entries()) {
                    const v = BigInt(viewsInc || 0);
                    await sql`
                        INSERT INTO article_metrics_daily (article_id, day, views, likes)
                        VALUES (${articleId}, CURRENT_DATE, ${v}, 0)
                        ON CONFLICT (article_id, day) DO UPDATE
                        SET
                        views = article_metrics_daily.views + EXCLUDED.views
                    `;
                }

                await sql`COMMIT`;
            } catch (e) {
                await sql`ROLLBACK`;
                throw e;
            }
            // 4) salva cursor
            await env.CURSORS.put(cursorKey, newCursor, { expirationTtl: 60 * 60 * 24 * 7 }); // 7 dias ttl
            console.log("Updated cursor to", newCursor);

            await pushLoki(env, { worker: "redis-stream-consumer", type: "batch" }, [{
                level: "info",
                msg: "flush batch",
                stream: env.STREAM_KEY,
                batchSize: batch.length,
                durationMs: Date.now() - started,
                aggregated: Object.fromEntries(counters) // { "art-123": 42, "art-456": 7 }
            }]);
        } catch (error) {
            await pushLoki(env, { worker: "redis-stream-consumer", type: "error" }, [{
                level: "error",
                msg: "flush failed",
                error: String(error)
            }]);
        }
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

// helper: envia 1..N linhas para o Loki (Grafana Cloud)
async function pushLoki(env, labels, lines) {
    // se não configurou (dev/local), não faz nada
    if (!env.LOKI_ENDPOINT || !env.LOKI_USERNAME || !env.LOKI_PASSWORD) return;

    // Loki exige timestamp em nanos (string)
    const nowNs = () => (BigInt(Date.now()) * 1_000_000n).toString();

    const streams = [{
        stream: {
            app: env.LOG_APP || "news-portal",
            env: env.LOG_ENV || "prod",
            worker: labels.worker || "worker",
            type: labels.type || "log",
            // adicione outros labels fixos se quiser (ex.: region, service, etc.)
        },
        values: lines.map(line => [nowNs(), typeof line === "string" ? line : JSON.stringify(line)])
    }];

    const res = await fetch(env.LOKI_ENDPOINT, {
        method: "POST",
        headers: {
            "content-type": "application/json",
            // Grafana Cloud usa Basic Auth: username = stack id, password = API key
            "authorization": "Basic " + btoa(`${env.LOKI_USERNAME}:${env.LOKI_PASSWORD}`)
        },
        body: JSON.stringify({ streams })
    });
    if (!res.ok) {
        // evita loop logando no Loki; deixe só no console para debug
        console.error("loki push failed", res.status, await res.text().catch(() => ""));
    }
}