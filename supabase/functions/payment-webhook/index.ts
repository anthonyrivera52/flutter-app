import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { adminClient } from '../_shared/supabase.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const signature = req.headers.get('x-signature');
    const webhookSecret = Deno.env.get('WOMPI_WEBHOOK_SECRET');

    if (!signature || !webhookSecret || signature !== webhookSecret) {
      return jsonResponse({ error: 'Invalid webhook signature.' }, 401);
    }

    const payload = await req.json();
    const orderId = payload?.data?.order_id ?? payload?.orderId;
    const paymentStatus = payload?.data?.status ?? payload?.status;

    if (!orderId || !paymentStatus) {
      return jsonResponse({ error: 'Invalid webhook payload.' }, 400);
    }

    const orderStatus =
      paymentStatus === 'APPROVED' || paymentStatus === 'paid'
        ? 'accepted'
        : paymentStatus === 'DECLINED' || paymentStatus === 'failed'
          ? 'cancelled'
          : 'pending';

    const { error } = await adminClient
      .from('orders')
      .update({ status: orderStatus })
      .eq('id', orderId);

    if (error) return jsonResponse({ error: error.message }, 500);

    return jsonResponse({ ok: true, orderId, orderStatus });
  } catch (e) {
    return jsonResponse({ error: e instanceof Error ? e.message : 'Unexpected error.' }, 500);
  }
});
