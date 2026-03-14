# Supabase Edge Functions

## Functions created
- `get-nearby-shops`
- `get-catalog`
- `create-order`
- `create-payment-intent`
- `payment-webhook`
- `track-order`
- `get-user-orders`

## Deploy
```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase functions deploy get-nearby-shops
supabase functions deploy get-catalog
supabase functions deploy create-order
supabase functions deploy create-payment-intent
supabase functions deploy payment-webhook
supabase functions deploy track-order
supabase functions deploy get-user-orders
```

## Required secrets
```bash
supabase secrets set SUPABASE_URL=https://<project-ref>.supabase.co
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
supabase secrets set WOMPI_WEBHOOK_SECRET=<your-webhook-shared-secret>
```

## Database Schema

### Required tables
```sql
-- Shops table
CREATE TABLE shops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  logo_url TEXT,
  address TEXT,
  schedule TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  service_radius_km DOUBLE PRECISION DEFAULT 5,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Products table
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  price DOUBLE PRECISION NOT NULL,
  discounted_price DOUBLE PRECISION,
  image_url TEXT,
  unit TEXT DEFAULT 'unidad',
  category_id TEXT,
  shop_id UUID REFERENCES shops(id),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Orders table (UPDATED with order_code)
CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  shop_id UUID REFERENCES shops(id),
  order_code TEXT UNIQUE, -- ✅ Código de verificación aleatorio (ej: X7K9-MN2P)
  total_amount DOUBLE PRECISION NOT NULL,
  status TEXT DEFAULT 'pending',
  shipping_address TEXT NOT NULL,
  shipping_latitude DOUBLE PRECISION,
  shipping_longitude DOUBLE PRECISION,
  store_latitude DOUBLE PRECISION,
  store_longitude DOUBLE PRECISION,
  notes TEXT,
  tip_amount DOUBLE PRECISION DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Order items table
CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id),
  quantity INTEGER NOT NULL,
  price DOUBLE PRECISION NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_orders_order_code ON orders(order_code);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_products_shop_id ON products(shop_id);
CREATE INDEX idx_shops_location ON shops(latitude, longitude);
```

## Security (RLS)
```sql
-- Enable Row Level Security
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Users can only see their own orders
CREATE POLICY "Users can view own orders" ON orders
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own order items" ON order_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.user_id = auth.uid()
    )
  );
```

## Order Code Generation
The `create-order` edge function automatically generates a unique verification code:
- Format: `XXXX-XXXX` (8 alphanumeric characters)
- Excludes confusing characters (0, O, 1, I)
- Code is displayed in the app for delivery verification
