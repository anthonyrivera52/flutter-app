-- =====================================================
-- MIGRATION: Agregar código de verificación a orders
-- Ejecuta este SQL en el SQL Editor de Supabase
-- =====================================================

-- 1. Agregar columna order_code a la tabla orders
ALTER TABLE orders ADD COLUMN IF NOT EXISTS order_code TEXT UNIQUE;

-- 2. Crear índice para búsquedas rápidas por código
CREATE INDEX IF NOT EXISTS idx_orders_order_code ON orders(order_code);

-- 3. Verificar que la columna existe
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'orders' AND column_name = 'order_code';

-- =====================================================
-- Verificación de la tabla orders
-- =====================================================
SELECT
    id,
    order_code,
    user_id,
    total_amount,
    status,
    created_at
FROM orders
ORDER BY created_at DESC
LIMIT 5;
