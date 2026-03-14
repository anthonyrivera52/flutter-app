import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { adminClient, getAuthenticatedUserId } from '../_shared/supabase.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const userId = await getAuthenticatedUserId(req);

    // Parse pagination parameters
    const url = new URL(req.url);
    const page = parseInt(url.searchParams.get('page') || '1');
    const limit = Math.min(parseInt(url.searchParams.get('limit') || '10'), 50); // Max 50 per page
    const offset = (page - 1) * limit;

    // Get total count for pagination
    const { count, error: countError } = await adminClient
      .from('orders')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId);

    if (countError) return jsonResponse({ error: countError.message }, 500);

    // Get paginated orders with order_code
    const { data, error } = await adminClient
      .from('orders')
      .select('id,user_id,order_code,total_amount,status,shipping_address,shipping_latitude,shipping_longitude,store_latitude,store_longitude,created_at,updated_at,order_items(id,order_id,quantity,price,products(id,name,description,price,image_url,unit,category_id,discounted_price))')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) return jsonResponse({ error: error.message }, 500);

    return jsonResponse({
      orders: data ?? [],
      pagination: {
        page,
        limit,
        total: count ?? 0,
        totalPages: Math.ceil((count ?? 0) / limit),
      },
    });
  } catch (e) {
    return jsonResponse({ error: e instanceof Error ? e.message : 'Unexpected error.' }, 500);
  }
});
