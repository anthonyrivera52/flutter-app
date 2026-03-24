import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { adminClient, getAuthenticatedUserId } from '../_shared/supabase.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const userId = await getAuthenticatedUserId(req);
    const { orderId } = await req.json();

    if (!orderId) return jsonResponse({ error: 'orderId is required.' }, 400);

    // Get order from sales table
    const { data: sale, error: saleError } = await adminClient
      .from('sales')
      .select(`
        id, customer_id, verification_code, total_amount, subtotal_amount,
        shipping_amount, tip_amount, status, shipping_address, created_at,
        updated_at, driver_id, driver_assigned_at, picked_up_at,
        payment_method, payment_status, notes,
        store_id
      `)
      .eq('id', orderId)
      .eq('customer_id', userId)
      .single();

    if (saleError || !sale) return jsonResponse({ error: 'Order not found.' }, 404);

    // Get store location
    let storeLatitude = 0;
    let storeLongitude = 0;
    let storeName = '';
    if (sale.store_id) {
      const { data: location } = await adminClient
        .from('locations')
        .select('latitude, longitude, name')
        .eq('id', sale.store_id)
        .single();
      if (location) {
        storeLatitude = Number(location.latitude ?? 0);
        storeLongitude = Number(location.longitude ?? 0);
        storeName = location.name ?? '';
      }
    }

    // Get sale items with product info
    const { data: saleItems } = await adminClient
      .from('sale_items')
      .select('id, sale_id, product_id, product_name, quantity, unit_price, total_price')
      .eq('sale_id', orderId);

    // Get product images for items
    const productIds = (saleItems ?? []).map((i) => i.product_id);
    const { data: products } = await adminClient
      .from('products')
      .select('id, name, image_url')
      .in('id', productIds);

    const productMap = new Map((products ?? []).map((p) => [p.id, p]));

    // Build items array compatible with OrderModel.fromJson
    const items = (saleItems ?? []).map((item) => {
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

    // Get driver info if assigned
    let driver = null;
    if (sale.driver_id) {
      const { data: driverData } = await adminClient
        .from('drivers')
        .select('id, name, phone, vehicle_type, vehicle_plate')
        .eq('id', sale.driver_id)
        .single();
      if (driverData) {
        driver = {
          id: driverData.id,
          name: driverData.name,
          phone: driverData.phone,
          photo_url: null,
          vehicle_type: driverData.vehicle_type,
          vehicle_plate: driverData.vehicle_plate,
        };
      }
    }

    // Extract coordinates from shipping_address JSONB
    const addr = sale.shipping_address ?? {};
    const shippingLatitude = Number(addr.lat ?? 0);
    const shippingLongitude = Number(addr.lng ?? 0);
    const shippingAddressText = addr.line1 ?? addr.formatted_address ?? '';

    // Build response compatible with OrderModel.fromJson()
    const order = {
      id: sale.id,
      user_id: sale.customer_id,
      order_code: sale.verification_code,
      verification_code: sale.verification_code,
      total_amount: sale.total_amount,
      subtotal_amount: sale.subtotal_amount,
      shipping_amount: sale.shipping_amount,
      tip_amount: sale.tip_amount,
      status: sale.status,
      shipping_address: shippingAddressText,
      shipping_latitude: shippingLatitude,
      shipping_longitude: shippingLongitude,
      store_latitude: storeLatitude,
      store_longitude: storeLongitude,
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
      driver: driver,
    };

    return jsonResponse({ order });
  } catch (e) {
    return jsonResponse({ error: e instanceof Error ? e.message : 'Unexpected error.' }, 500);
  }
});
