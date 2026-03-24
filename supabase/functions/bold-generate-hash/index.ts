import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    const { orderId, amount, currency } = await req.json();

    if (!orderId || !amount || !currency) {
      return jsonResponse({ error: "orderId, amount y currency son requeridos" }, 400);
    }

    const secretKey = Deno.env.get("BOLD_SECRET_KEY");
    if (!secretKey) {
      console.error("BOLD_SECRET_KEY no configurada");
      return jsonResponse({ error: "Configuración de Bold no encontrada" }, 500);
    }

    const concatenated = `${orderId}${amount}${currency}${secretKey}`;

    const encoder = new TextEncoder();
    const data = encoder.encode(concatenated);
    const hashBuffer = await crypto.subtle.digest("SHA-256", data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const hash = hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");

    return jsonResponse({ hash });
  } catch (e) {
    console.error("Error generando hash Bold:", e);
    return jsonResponse(
      { error: e instanceof Error ? e.message : "Error inesperado" },
      500,
    );
  }
});
