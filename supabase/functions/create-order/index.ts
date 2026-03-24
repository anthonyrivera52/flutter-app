import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { adminClient, getAuthenticatedUserId } from '../_shared/supabase.ts';

type ItemPayload = { productId: string; quantity: number };

function generateVerificationCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 4; i++) code += chars.charAt(Math.floor(Math.random() * chars.length));
  code += '-';
  for (let i = 0; i < 4; i++) code += chars.charAt(Math.floor(Math.random() * chars.length));
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

    // Get store info from locations table
    const { data: location, error: locationError } = await adminClient
      .from('locations')
      .select('id, latitude, longitude, organization_id, name')
      .eq('id', shopId)
      .single();

    if (locationError || !location) {
      return jsonResponse({ error: 'Store not found.' }, 404);
    }

    // Get products with price
    const productIds = normalizedItems.map((i) => i.productId);
    const { data: products, error: productsError } = await adminClient
      .from('products')
      .select('id, name, price, is_available')
      .in('id', productIds)
      .eq('is_available', true);

    if (productsError) return jsonResponse({ error: productsError.message }, 500);

    const byId = new Map((products ?? []).map((p) => [p.id, p]));
    let subtotal = 0;

    for (const item of normalizedItems) {
      const product = byId.get(item.productId);
      if (!product) return jsonResponse({ error: `Invalid product ${item.productId}.` }, 400);
      subtotal += Number(product.price) * item.quantity;
    }

    const deliveryFee = 1.2;
    const totalAmount = Number((subtotal + deliveryFee + Number(tipAmount)).toFixed(2));

    // Generate unique verification code
    let verificationCode: string;
    let isUnique = false;
    let attempts = 0;

    do {
      verificationCode = generateVerificationCode();
      const { data: existing } = await adminClient
        .from('sales')
        .select('id')
        .eq('verification_code', verificationCode)
        .maybeSingle();
      isUnique = !existing;
      attempts++;
    } while (!isUnique && attempts < 10);

    if (!isUnique) {
      verificationCode = `ORD-${Date.now().toString(36).toUpperCase()}-${Math.random().toString(36).substring(2, 6).toUpperCase()}`;
    }

    // Build shipping_address JSONB
    const shippingAddressJson = {
      lat: Number(shippingLatitude ?? 0),
      lng: Number(shippingLongitude ?? 0),
      line1: typeof shippingAddress === 'string' ? shippingAddress : (shippingAddress?.line1 ?? shippingAddress?.address ?? ''),
      phone: typeof shippingAddress === 'object' ? (shippingAddress?.phone ?? '') : '',
      recipient_name: typeof shippingAddress === 'object' ? (shippingAddress?.recipient_name ?? '') : '',
    };

    // Insert into sales
    const { data: createdOrder, error: orderError } = await adminClient
      .from('sales')
      .insert({
        customer_id: userId,
        store_id: shopId,
        organization_id: location.organization_id,
        total_amount: totalAmount,
        subtotal_amount: subtotal,
        shipping_amount: deliveryFee,
        tip_amount: Number(tipAmount ?? 0),
        status: 'NEW',
        order_type: 'DELIVERY_LOCAL',
        verification_code: verificationCode,
        shipping_address: shippingAddressJson,
        notes: notes ?? null,
      })
      .select('id, status, total_amount, created_at, verification_code')
      .single();

    if (orderError) return jsonResponse({ error: orderError.message }, 500);

    // Insert sale_items
    const saleItems = normalizedItems.map((item) => {
      const product = byId.get(item.productId)!;
      return {
        sale_id: createdOrder.id,
        product_id: item.productId,
        product_name: product.name,
        quantity: item.quantity,
        unit_price: Number(product.price),
        total_price: Number(product.price) * item.quantity,
        organization_id: location.organization_id,
      };
    });

    const { error: itemsError } = await adminClient.from('sale_items').insert(saleItems);
    if (itemsError) return jsonResponse({ error: itemsError.message }, 500);

    return jsonResponse({
      orderId: createdOrder.id,
      orderCode: createdOrder.verification_code,
      status: createdOrder.status,
      totalAmount: createdOrder.total_amount,
      createdAt: createdOrder.created_at,
    });
  } catch (e) {
    return jsonResponse({ error: e instanceof Error ? e.message : 'Unexpected error.' }, 500);
  }
});
