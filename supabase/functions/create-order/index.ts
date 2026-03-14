import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { adminClient, getAuthenticatedUserId } from '../_shared/supabase.ts';

type ItemPayload = { productId: string; quantity: number };

/**
 * Generate a random verification code for order
 * Format: XXXX-XXXX (8 characters alphanumeric)
 * This code is used to verify the delivery to the customer
 */
function generateOrderCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluding confusing chars (0, O, 1, I)
  let code = '';
  for (let i = 0; i < 4; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  code += '-';
  for (let i = 0; i < 4; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const userId = await getAuthenticatedUserId(req);
    const {
      shopId,
      shippingAddress,
      shippingLatitude,
      shippingLongitude,
      notes,
      tipAmount = 0,
      items,
    } = await req.json();

    if (!shopId || !shippingAddress || !Array.isArray(items) || items.length === 0) {
      return jsonResponse({ error: 'shopId, shippingAddress and items are required.' }, 400);
    }

    const normalizedItems: ItemPayload[] = items
      .map((i: ItemPayload) => ({ productId: i.productId, quantity: Number(i.quantity) }))
      .filter((i: ItemPayload) => i.productId && i.quantity > 0);

    if (normalizedItems.length === 0) {
      return jsonResponse({ error: 'No valid items provided.' }, 400);
    }

    const productIds = normalizedItems.map((i) => i.productId);
    const { data: products, error: productsError } = await adminClient
      .from('products')
      .select('id,price,discounted_price,shop_id,is_active')
      .in('id', productIds)
      .eq('shop_id', shopId)
      .eq('is_active', true);

    if (productsError) return jsonResponse({ error: productsError.message }, 500);

    const byId = new Map((products ?? []).map((p) => [p.id, p]));
    let subtotal = 0;

    for (const item of normalizedItems) {
      const product = byId.get(item.productId);
      if (!product) return jsonResponse({ error: `Invalid product ${item.productId}.` }, 400);
      const unitPrice = Number(product.discounted_price ?? product.price);
      subtotal += unitPrice * item.quantity;
    }

    const deliveryFee = 1.2;
    const totalAmount = Number((subtotal + deliveryFee + Number(tipAmount)).toFixed(2));

    const { data: shop, error: shopError } = await adminClient
      .from('shops')
      .select('latitude,longitude')
      .eq('id', shopId)
      .single();

    if (shopError) return jsonResponse({ error: shopError.message }, 500);

    // Generate unique order code
    let orderCode: string;
    let isUnique = false;
    let attempts = 0;

    // Ensure the code is unique
    do {
      orderCode = generateOrderCode();
      const { data: existing } = await adminClient
        .from('orders')
        .select('id')
        .eq('order_code', orderCode)
        .maybeSingle();
      isUnique = !existing;
      attempts++;
    } while (!isUnique && attempts < 10);

    // If we couldn't generate a unique code after 10 attempts, use UUID-based code
    if (!isUnique) {
      orderCode = `ORD-${Date.now().toString(36).toUpperCase()}-${Math.random().toString(36).substring(2, 6).toUpperCase()}`;
    }

    const { data: createdOrder, error: orderError } = await adminClient
      .from('orders')
      .insert({
        user_id: userId,
        shop_id: shopId,
        order_code: orderCode, // ✅ Store the verification code
        total_amount: totalAmount,
        status: 'pending',
        shipping_address: shippingAddress,
        shipping_latitude: Number(shippingLatitude ?? 0),
        shipping_longitude: Number(shippingLongitude ?? 0),
        store_latitude: Number(shop.latitude ?? 0),
        store_longitude: Number(shop.longitude ?? 0),
        notes: notes ?? null,
      })
      .select('id,status,total_amount,created_at,order_code')
      .single();

    if (orderError) return jsonResponse({ error: orderError.message }, 500);

    const orderItems = normalizedItems.map((item) => {
      const product = byId.get(item.productId)!;
      const unitPrice = Number(product.discounted_price ?? product.price);
      return {
        order_id: createdOrder.id,
        product_id: item.productId,
        quantity: item.quantity,
        price: unitPrice,
      };
    });

    const { error: itemsError } = await adminClient.from('order_items').insert(orderItems);
    if (itemsError) return jsonResponse({ error: itemsError.message }, 500);

    return jsonResponse({
      orderId: createdOrder.id,
      orderCode: createdOrder.order_code, // ✅ Return the code to the client
      status: createdOrder.status,
      totalAmount: createdOrder.total_amount,
      createdAt: createdOrder.created_at,
    });
  } catch (e) {
    return jsonResponse({ error: e instanceof Error ? e.message : 'Unexpected error.' }, 500);
  }
});
