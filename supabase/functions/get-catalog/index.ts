import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { adminClient } from '../_shared/supabase.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const { locationId, shopId, categoryId, search, limit = 200 } = await req.json();

    const locId = locationId ?? shopId;
    if (!locId || typeof locId !== 'string') {
      return jsonResponse({ error: 'locationId (or shopId) is required.' }, 400);
    }

    // 1. Get organization_id from the selected location
    const { data: location, error: locError } = await adminClient
      .from('locations')
      .select('id, name, organization_id, latitude, longitude')
      .eq('id', locId)
      .single();

    if (locError || !location) {
      return jsonResponse({ error: 'Location not found.' }, 404);
    }

    const orgId = location.organization_id;

// 2. Get all products for this organization
     // NOTE: category_id NO existe en products — se resuelve vía junction table abajo
     // NOTE: discounted_price NO existe en products — se computa aparte si es necesario
     let query = adminClient
       .from('products')
       .select('id, name, description, price, image_url, measurement_unit')
       .eq('organization_id', orgId)
       .eq('is_available', true)
       .limit(limit);

    if (search && typeof search === 'string') {
      query = query.ilike('name', `%${search}%`);
    }

    const { data: products, error: pError } = await query;
    if (pError) return jsonResponse({ error: pError.message }, 500);

    const allProductIds = (products ?? []).map((p) => p.id);
    if (allProductIds.length === 0) {
      return jsonResponse({
        products: [],
        locationId: locId,
        organizationId: orgId,
        categories: [],
      });
    }

    // 3. Get category-product links (junction table first, then fallback to direct category_id)
    let catLinks: { product_id: string; category_id: string }[] = [];

    // Try junction table first
    const { data: junctionLinks } = await adminClient
      .from('product_category_products')
      .select('product_id, category_id')
      .in('product_id', allProductIds);

    catLinks = junctionLinks ?? [];

    // 4. Get category details
    const catIds = [...new Set(catLinks.map((cl) => cl.category_id))];
    const { data: categories } = catIds.length > 0
      ? await adminClient
          .from('product_categories')
          .select('id, name, slug')
          .in('id', catIds)
      : { data: [] };

    const categoryMap = new Map((categories ?? []).map((c) => [c.id, c]));
    const productCatMap = new Map<string, { id: string; slug: string; name: string }>();
    for (const link of catLinks) {
      const cat = categoryMap.get(link.category_id);
      if (cat && !productCatMap.has(link.product_id)) {
        productCatMap.set(link.product_id, { id: cat.id, slug: cat.slug, name: cat.name });
      }
    }

    // 5. Filter by category slug if requested
    let filtered = products ?? [];
    if (categoryId && typeof categoryId === 'string') {
      const matchingProductIds = new Set(
        catLinks
          .filter((cl) => {
            const cat = categoryMap.get(cl.category_id);
            return cat?.slug === categoryId;
          })
          .map((cl) => cl.product_id)
      );
      filtered = filtered.filter((p) => matchingProductIds.has(p.id));
    }

    // 6. Build unique categories list for the UI
    const uniqueCategories = new Map<string, { id: string; slug: string; name: string }>();
    for (const link of catLinks) {
      const cat = categoryMap.get(link.category_id);
      if (cat) {
        uniqueCategories.set(cat.slug, { id: cat.id, slug: cat.slug, name: cat.name });
      }
    }

// 7. Build response (sin category_id ni discounted_price — no existen en products)
     const result = filtered.map((p) => {
       const cat = productCatMap.get(p.id);
       return {
         'id': p.id,
         'name': p.name,
         'description': p.description,
         'price': p.price,
         'image_url': p.image_url,
         // measurement_unit viene del select como string o null
         'unit': p['measurement_unit'] ?? 'unidad',
         'category_id': cat?.id ?? '',
       };
     });

    return jsonResponse({
      products: result,
      locationId: locId,
      organizationId: orgId,
      categories: [...uniqueCategories.values()],
    });
  } catch (e) {
    return jsonResponse({ error: e instanceof Error ? e.message : 'Unexpected error.' }, 500);
  }
});
