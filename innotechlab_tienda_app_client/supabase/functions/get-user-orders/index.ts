import { corsHeaders, jsonResponse } from '../_shared/cors.ts';
import { adminClient, getAuthenticatedUserId } from '../_shared/supabase.ts';

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const userId = await getAuthenticatedUserId(req);

    const { data: sales, error: salesError } = await adminClient
      .from('sales')
      .select(`
        id,
        user_id,
        customer_id,
        total_amount,
        subtotal_amount,
        shipping_amount,
        tax_iva_amount,
        tip_amount,
        status,
        payment_status,
        payment_method,
        shipping_address,
        shipping_latitude,
        shipping_longitude,
        store_latitude,
        store_longitude,
        created_at,
        updated_at,
        order_code,
        verification_code,
        driver_id,
        driver_assigned_at,
        picked_up_at,
        driver:drivers(id,name,phone,photo_url,vehicle_type,vehicle_plate,vehicle_brand,vehicle_model,status),
        sale_items(id,sale_id,product_id,quantity,unit_price,total_price,products(id,name,description,price,image_url,unit_code,is_available))
      `)
      .eq('customer_id', userId)
      .order('created_at', { ascending: false });

    if (salesError) return jsonResponse({ error: salesError.message }, 500);

    if (!sales || sales.length === 0) {
      return jsonResponse({ orders: [] });
    }

    const saleIds = sales.map(s => s.id);

    const { data: transactions, error: txError } = await adminClient
      .from('payment_transactions')
      .select('*')
      .in('sale_id', saleIds);

    if (txError) {
      console.error('Error fetching transactions:', txError);
    }

    const txMap = new Map<string, Record<string, unknown>>();
    if (transactions) {
      for (const tx of transactions) {
        txMap.set(tx.sale_id, {
          transactionId: tx.id,
          kushkiTransactionId: tx.kushki_transaction_id,
          paymentMethod: tx.payment_method,
          paymentStatus: tx.payment_status,
          cardLastFour: tx.card_last_four,
          cardBrand: tx.card_brand,
          amount: tx.amount,
          currency: tx.currency,
          paidAt: tx.created_at,
        });
      }
    }

    const orders = sales.map(sale => ({
      ...sale,
      paymentInfo: txMap.get(sale.id) || null,
    }));

    return jsonResponse({ orders });
  } catch (e) {
    return jsonResponse({ error: e instanceof Error ? e.message : 'Unexpected error.' }, 500);
  }
});
