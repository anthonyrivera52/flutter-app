import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { adminClient, getAuthenticatedUserId } from '../_shared/supabase.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const userId = await getAuthenticatedUserId(req);

    // Parse pagination parameters (request body takes precedence over URL params)
    const url = new URL(req.url);
    let bodyPage: number | undefined;
    let bodyLimit: number | undefined;
    try {
      const body = await req.json();
      bodyPage = body.page;
      bodyLimit = body.limit;
    } catch { /* body not JSON, fall back to URL params */ }
    const page = bodyPage ?? parseInt(url.searchParams.get('page') || '1');
    const limit = Math.min(bodyLimit ?? parseInt(url.searchParams.get('limit') || '10'), 50);
    const offset = (page - 1) * limit;

    // Get total count
    const { count, error: countError } = await adminClient
      .from('sales')
      .select('id', { count: 'exact', head: true })
      .eq('customer_id', userId);

    if (countError) return jsonResponse({ error: countError.message }, 500);

    // Get paginated orders
    const { data: sales, error: salesError } = await adminClient
      .from('sales')
      .select(`
        id, customer_id, verification_code, total_amount, subtotal_amount,
        shipping_amount, tip_amount, status, shipping_address, created_at,
        updated_at, driver_id, driver_assigned_at, picked_up_at,
        payment_method, payment_status, notes, store_id
      `)
      .eq('customer_id', userId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (salesError) return jsonResponse({ error: salesError.message }, 500);

    // Get store locations for all orders
    const storeIds = [...new Set((sales ?? []).map((s) => s.store_id).filter(Boolean))];
    const { data: locations } = storeIds.length > 0
      ? await adminClient.from('locations').select('id, latitude, longitude, name').in('id', storeIds)
      : { data: [] };
    const locationMap = new Map((locations ?? []).map((l) => [l.id, l]));

    // Get all sale_items for these orders
    const saleIds = (sales ?? []).map((s) => s.id);
    const { data: allItems } = saleIds.length > 0
      ? await adminClient
          .from('sale_items')
          .select('id, sale_id, product_id, product_name, quantity, unit_price, total_price')
          .in('sale_id', saleIds)
      : { data: [] };

    // Get product images
    const allProductIds = [...new Set((allItems ?? []).map((i) => i.product_id))];
    const { data: products } = allProductIds.length > 0
      ? await adminClient.from('products').select('id, name, image_url').in('id', allProductIds)
      : { data: [] };
    const productMap = new Map((products ?? []).map((p) => [p.id, p]));

    // Group items by sale_id
    const itemsBySaleId = new Map<string, typeof allItems>();
    for (const item of allItems ?? []) {
      const list = itemsBySaleId.get(item.sale_id) ?? [];
      list.push(item);
      itemsBySaleId.set(item.sale_id, list);
    }

    // Get driver info for orders with driver_id
    const driverIds = [...new Set((sales ?? []).map((s) => s.driver_id).filter(Boolean))];
    const { data: drivers } = driverIds.length > 0
      ? await adminClient.from('drivers').select('id, name, phone, vehicle_type, vehicle_plate').in('id', driverIds)
      : { data: [] };
    const driverMap = new Map((drivers ?? []).map((d) => [d.id, d]));

    // Build response compatible with OrderModel.fromJson()
    const orders = (sales ?? []).map((sale) => {
      const location = sale.store_id ? locationMap.get(sale.store_id) : null;
      const addr = sale.shipping_address ?? {};
      const saleItems = itemsBySaleId.get(sale.id) ?? [];
      const driverData = sale.driver_id ? driverMap.get(sale.driver_id) : null;

      const items = saleItems.map((item) => {
        const product = productMap.get(item.product_id);
        return {
          id: item.id,
          sale_id: item.sale_id,
          order_id: item.sale_id,
          quantity: item.quantity,
          unit_price: item.unit_price,
          price: item.unit_price,
          products: {
            id: item.product_id,
            name: item.product_name ?? product?.name ?? '',
            description: '',
            price: item.unit_price,
            image_url: product?.image_url ?? '',
            unit: '',
            category_id: '',
            discounted_price: null,
          },
        };
      });

      return {
        id: sale.id,
        user_id: sale.customer_id,
        order_code: sale.verification_code,
        verification_code: sale.verification_code,
        total_amount: sale.total_amount,
        subtotal_amount: sale.subtotal_amount,
        shipping_amount: sale.shipping_amount,
        tip_amount: sale.tip_amount,
        status: sale.status,
        shipping_address: addr.line1 ?? addr.formatted_address ?? '',
        shipping_latitude: Number(addr.lat ?? 0),
        shipping_longitude: Number(addr.lng ?? 0),
        store_latitude: Number(location?.latitude ?? 0),
        store_longitude: Number(location?.longitude ?? 0),
        created_at: sale.created_at,
        updated_at: sale.updated_at,
        driver_id: sale.driver_id,
        driver_assigned_at: sale.driver_assigned_at,
        picked_up_at: sale.picked_up_at,
        payment_method: sale.payment_method,
        payment_status: sale.payment_status,
        notes: sale.notes,
        sale_items: items,
        order_items: items,
        driver: driverData ? {
          id: driverData.id,
          name: driverData.name,
          phone: driverData.phone,
          photo_url: null,
          vehicle_type: driverData.vehicle_type,
          vehicle_plate: driverData.vehicle_plate,
        } : null,
      };
    });

    return jsonResponse({
      orders,
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
