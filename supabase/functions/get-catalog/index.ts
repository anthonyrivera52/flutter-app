import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { adminClient } from '../_shared/supabase.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { shopId, categoryId, search, limit = 200 } = await req.json();

    if (!shopId || typeof shopId !== 'string') {
      return jsonResponse({ error: 'shopId is required.' }, 400);
    }

    let query = adminClient
      .from('products')
      .select('id,name,description,price,image_url,unit,category_id,discounted_price,shop_id,is_active')
      .eq('shop_id', shopId)
      .eq('is_active', true)
      .limit(limit);

    if (categoryId && typeof categoryId === 'string') query = query.eq('category_id', categoryId);
    if (search && typeof search === 'string') query = query.ilike('name', `%${search}%`);

    const { data, error } = await query;
    if (error) return jsonResponse({ error: error.message }, 500);

    const products = (data ?? []).map((p) => ({
      id: p.id,
      name: p.name,
      description: p.description,
      price: p.price,
      image_url: p.image_url,
      unit: p.unit,
      category_id: p.category_id,
      discounted_price: p.discounted_price,
      shop_id: p.shop_id,
    }));

    return jsonResponse({ products });
  } catch (e) {
    return jsonResponse({ error: e instanceof Error ? e.message : 'Unexpected error.' }, 500);
  }
});
