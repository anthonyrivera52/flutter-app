import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { getAuthenticatedUserId } from '../_shared/supabase.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    await getAuthenticatedUserId(req);
    const { orderId, amount, currency = 'COP' } = await req.json();

    if (!orderId || typeof amount !== 'number') {
      return jsonResponse({ error: 'orderId and amount are required.' }, 400);
    }

    // Placeholder: connect Wompi/Stripe here.
    // Never expose private keys in the client app.
    const paymentIntentId = crypto.randomUUID();

    return jsonResponse({
      paymentIntentId,
      orderId,
      amount,
      currency,
      status: 'requires_confirmation',
      provider: 'wompi',
      nextAction: 'complete_payment_in_provider_sdk',
    });
  } catch (e) {
    return jsonResponse({ error: e instanceof Error ? e.message : 'Unexpected error.' }, 500);
  }
});
