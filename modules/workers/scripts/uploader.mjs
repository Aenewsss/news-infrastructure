/**
 * Rotas:
 *  - OPTIONS *            → CORS
 *  - PUT   /upload/:key   → upload direto (body raw); header Content-Type é obrigatório
 *  - GET   /file/:key     → serve arquivo com cache na borda
 *  - DELETE /file/:key    → (opcional) remover arquivo (proteja com token no cabeçalho)
 *
 * Observações:
 *  - Comece com esse fluxo (Worker intermediando upload). É simples e seguro.
 *  - Depois dá pra evoluir para presigned URLs/multipart se precisar.
 */

export default {
    async fetch(request, env) {
        const url = new URL(request.url);
        const { pathname } = url;

        // CORS básico
        if (request.method === "OPTIONS") {
            return new Response(null, { status: 204, headers: corsHeaders() });
        }

        // Rotas
        if (request.method === "PUT" && pathname.startsWith("/upload/")) {
            return handlePutUpload(request, env);
        }
        if (request.method === "GET" && pathname.startsWith("/file/")) {
            return handleGetFile(request, env);
        }
        if (request.method === "DELETE" && pathname.startsWith("/file/")) {
            // ATENÇÃO: adicione autenticação (ex.: Bearer token) antes de habilitar em prod
            return handleDeleteFile(request, env);
            return new Response(JSON.stringify({ error: "DELETE disabled" }), { status: 403, headers: jsonCors() });
        }

        return new Response(JSON.stringify({ ok: true, msg: "R2 media worker" }), { status: 200, headers: jsonCors() });
    }
};

function corsHeaders() {
    return {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization, X-File-Name"
    };
}
function jsonCors() {
    return { ...corsHeaders(), "Content-Type": "application/json" };
}

async function handlePutUpload(request, env) {
    // path: /upload/:key
    const key = decodeURIComponent(new URL(request.url).pathname.replace(/^\/upload\//, ""));
    if (!key) {
        return new Response(JSON.stringify({ error: "Missing key" }), { status: 400, headers: jsonCors() });
    }

    const contentType = request.headers.get("content-type") || "";
    if (!contentType) {
        return new Response(JSON.stringify({ error: "Content-Type required" }), { status: 400, headers: jsonCors() });
    }

    // Valida MIME "allow list" simples
    const allow = (env.ALLOWED_MIME_PREFIX || "").split(",").map(s => s.trim()).filter(Boolean);
    if (allow.length && !allow.some(prefix => contentType.startsWith(prefix))) {
        return new Response(JSON.stringify({ error: `MIME not allowed: ${contentType}` }), { status: 415, headers: jsonCors() });
    }

    // Limite de tamanho (se Content-Length vier)
    const max = Number(env.MAX_UPLOAD_BYTES || "10000000");
    const len = Number(request.headers.get("content-length") || "0");
    if (len > 0 && len > max) {
        return new Response(JSON.stringify({ error: `Payload too large (>${max} bytes)` }), { status: 413, headers: jsonCors() });
    }

    // Grava direto no R2 (streaming)
    // httpMetadata controla o Content-Type do objeto servido depois
    await env.R2_MEDIA.put(key, request.body, {
        httpMetadata: { contentType },
        // Opcional: metadados customizados
        customMetadata: { uploadedAt: String(Date.now()) }
    });

    return new Response(JSON.stringify({ ok: true, key }), { status: 201, headers: jsonCors() });
}

async function handleGetFile(request, env) {
    // path: /file/:key
    const key = decodeURIComponent(new URL(request.url).pathname.replace(/^\/file\//, ""));
    if (!key) {
        return new Response("Not Found", { status: 404, headers: corsHeaders() });
    }

    const obj = await env.R2_MEDIA.get(key);
    if (!obj) {
        return new Response("Not Found", { status: 404, headers: corsHeaders() });
    }

    const headers = new Headers(corsHeaders());
    // Cache agressivo na borda, 1 ano; cliente pode ter menos se quiser
    headers.set("Cache-Control", "public, max-age=31536000, immutable");

    // Propaga Content-Type correto
    const ct = obj.httpMetadata?.contentType || "application/octet-stream";
    headers.set("Content-Type", ct);

    return new Response(obj.body, { status: 200, headers });
}

// Exemplo de delete com proteção — HABILITE SÓ COM AUTH
async function handleDeleteFile(request, env) {
  const key = decodeURIComponent(new URL(request.url).pathname.replace(/^\/file\//, ""));
  // Ex.: checar header Authorization com token
  // const auth = request.headers.get("authorization");
  // if (!auth || auth !== `Bearer ${env.ADMIN_TOKEN}`) return new Response("Forbidden", { status: 403, headers: corsHeaders() });
  await env.R2_MEDIA.delete(key);
  return new Response(null, { status: 204, headers: corsHeaders() });
}