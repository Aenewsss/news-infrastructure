// Script mínimo de consumer (módulos/ESM)
// Recebe lotes e só loga (troque pela lógica de flush p/ seu backend)
export default {
    async queue(batch, env, ctx) {
        console.log("Batch size:", batch.messages.length);
        for (const msg of batch.messages) {
            try {
                console.log("message:", msg.body);
                msg.ack();
            } catch (e) {
                console.error("failed:", e);
                msg.retry();
            }
        }
    }
};