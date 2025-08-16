// Script mínimo: publica a requisição na fila
export default {
    async fetch(request, env) {
        const payload = {
            url: request.url,
            method: request.method,
            ip: request.headers.get("cf-connecting-ip") ?? null,
            ua: request.headers.get("user-agent") ?? null,
            ts: Date.now()
        };
        await env.FLUSH_QUEUE.send(payload);
        return new Response("queued", { status: 202 });
    }
};