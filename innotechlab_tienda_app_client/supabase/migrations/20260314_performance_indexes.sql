-- ============================================================
-- PERFORMANCE INDEXES - Supabase / PostgreSQL
-- Ref: supabase-postgres-best-practices
-- ============================================================

-- ============================================================
-- 1. FOREIGN KEY INDEXES
-- Evita sequential scans en JOINs y queries con FK
-- Impact: CRITICAL - 100-1000x más rápido en tablas grandes
-- ============================================================

-- sales (orders): user_id, driver_id, shop_id
CREATE INDEX IF NOT EXISTS idx_sales_user_id       ON sales (user_id);
CREATE INDEX IF NOT EXISTS idx_sales_driver_id     ON sales (driver_id);
CREATE INDEX IF NOT EXISTS idx_sales_shop_id       ON sales (shop_id);
CREATE INDEX IF NOT EXISTS idx_sales_status        ON sales (status);

-- Índice compuesto para paginación cursor-based (created_at + id)
-- Permite: WHERE (created_at, id) < (cursor_ts, cursor_id) ORDER BY created_at DESC, id DESC
CREATE INDEX IF NOT EXISTS idx_sales_user_cursor
  ON sales (user_id, created_at DESC, id DESC);

-- sale_items: sale_id, product_id
CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id    ON sale_items (sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_product_id ON sale_items (product_id);

-- products: category_id, shop_id
CREATE INDEX IF NOT EXISTS idx_products_category_id ON products (category_id);
CREATE INDEX IF NOT EXISTS idx_products_shop_id     ON products (shop_id);

-- drivers: status (para queries de disponibilidad)
CREATE INDEX IF NOT EXISTS idx_drivers_status ON drivers (status);

-- ============================================================
-- 2. ÍNDICES GIN PARA JSONB
-- Para columnas JSONB con búsquedas frecuentes
-- Impact: HIGH - búsquedas en JSON sin sequential scan
-- ============================================================

-- shipping_address si es JSONB
CREATE INDEX IF NOT EXISTS idx_sales_shipping_address_gin
  ON sales USING GIN (shipping_address jsonb_path_ops)
  WHERE shipping_address IS NOT NULL;

-- user_metadata en auth.users (si se consulta frecuentemente)
-- CREATE INDEX IF NOT EXISTS idx_users_metadata_gin
--   ON auth.users USING GIN (raw_user_meta_data jsonb_path_ops);

-- ============================================================
-- 3. ÍNDICES ESPACIALES GiST (PostGIS)
-- Para queries de geolocalización (tiendas cercanas)
-- Impact: CRITICAL para get-nearby-shops edge function
-- ============================================================

-- Habilitar extensión PostGIS si no está activa
CREATE EXTENSION IF NOT EXISTS postgis;

-- Índice espacial en shops/locations
-- Asume columna geometry o que se usa lat/lng como punto
CREATE INDEX IF NOT EXISTS idx_shops_location_gist
  ON shops USING GIST (
    ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
  );

-- Índice espacial en sales para shipping location
CREATE INDEX IF NOT EXISTS idx_sales_shipping_location_gist
  ON sales USING GIST (
    ST_SetSRID(ST_MakePoint(shipping_longitude, shipping_latitude), 4326)::geography
  );

-- ============================================================
-- 4. ÍNDICES PARCIALES
-- Solo indexar filas relevantes (menor tamaño, más rápido)
-- ============================================================

-- Solo pedidos activos (no completados/cancelados)
CREATE INDEX IF NOT EXISTS idx_sales_active
  ON sales (user_id, created_at DESC)
  WHERE status NOT IN ('completed', 'delivered', 'cancelled');

-- Solo drivers disponibles
CREATE INDEX IF NOT EXISTS idx_drivers_available
  ON drivers (status, latitude, longitude)
  WHERE status = 'available';

-- ============================================================
-- 5. OPTIMIZACIÓN RLS POLICIES
-- Ref: security-rls-performance.md
-- Usar (select auth.uid()) en lugar de auth.uid() directo
-- Impact: HIGH - 5-10x más rápido con tablas grandes
-- ============================================================

-- Ejemplo de policy optimizada para sales:
-- DROP POLICY IF EXISTS sales_user_policy ON sales;
-- CREATE POLICY sales_user_policy ON sales
--   USING ((select auth.uid()) = user_id);

-- Ejemplo de policy optimizada para sale_items:
-- DROP POLICY IF EXISTS sale_items_user_policy ON sale_items;
-- CREATE POLICY sale_items_user_policy ON sale_items
--   USING (
--     sale_id IN (
--       SELECT id FROM sales WHERE user_id = (select auth.uid())
--     )
--   );

-- ============================================================
-- 6. VACUUM / ANALYZE después de crear índices
-- ============================================================
ANALYZE sales;
ANALYZE sale_items;
ANALYZE products;
ANALYZE drivers;
