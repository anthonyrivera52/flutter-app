import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { adminClient, getAuthenticatedUserId } from '../_shared/supabase.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const userId = await getAuthenticatedUserId(req);
    const { orderId } = await req.json();

    if (!orderId) return jsonResponse({ error: 'orderId is required.' }, 400);

    // Include order_code in the query
    const { data, error } = await adminClient
      .from('orders')
      .select('id,user_id,order_code,total_amount,status,shipping_address,shipping_latitude,shipping_longitude,store_latitude,store_longitude,created_at,updated_at,order_items(id,order_id,quantity,price,products(id,name,description,price,image_url,unit,category_id,discounted_price))')
      .eq('id', orderId)
      .eq('user_id', userId)
      .single();

    if (error) return jsonResponse({ error: error.message }, 404);

    return jsonResponse({ order: data });
  } catch (e) {
    return jsonResponse({ error: e instanceof Error ? e.message : 'Unexpected error.' }, 500);
  }
});
