# Documento de Migración - App Delivery Recompry v2.0

**Fecha:** 8 de Marzo de 2026
**Versión:** 2.0.0
**Proyecto ID Supabase:** ldvtazoxloqdystdvbnq

---

## Resumen Ejecutivo

Este documento detalla todos los cambios necesarios para implementar el sistema completo de delivery con:
1. **Gestión de Drivers** - Asignación, seguimiento y control de repartidores
2. **Sistema de Geolocalización** - Pedidos por zona en tiempo real
3. **Notificaciones** - Notificar a sucursal cuando driver toma el domicilio
4. **UX/UI Mejorada** - Diseño adaptativo y competitivo
5. **Rendimiento** - Optimizaciones para velocidad y eficiencia

---

## 1. Análisis del Estado Actual

### 1.1 Tablas Existentes en Supabase

| Tabla | Estado | Uso Actual |
|-------|--------|------------|
| `sales` | ✅ Existe | Pedidos (no tiene campos de delivery) |
| `profiles` | ✅ Existe | Perfiles de usuario |
| `users` (auth) | ✅ Existe | Autenticación |
| `zones` | ✅ Existe | Zonas de cobertura |
| `location_coverage_zones` | ✅ Existe | Zonas de entrega |
| `delivery_codes` | ✅ Existe | Códigos de verificación |
| `order_track` | ✅ Existe | Seguimiento de pedidos |
| `location_service_zones` | ✅ Existe | Zonas de servicio |

### 1.2 Tabla Faltante CRÍTICA

| Tabla | Estado | Acción Requerida |
|-------|--------|------------------|
| `orders` | ❌ No existe | **CREAR** - Tabla principal de pedidos |

### 1.3 Problema Identificado

El código Flutter referencia `orders` pero la tabla no existe en Supabase. Los pedidos actuales están en `sales` pero sin campos de delivery.

---

## 2. Migración de Base de Datos

### 2.1 SQL Migration - Crear Tabla `orders`

```sql
-- =====================================================
-- MIGRACIÓN COMPLETA v2.0 - APP DELIVERY RECOMPRY
-- Fecha: 2026-03-08
-- =====================================================

-- Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- =====================================================
-- TABLA: orders (Pedidos de Delivery)
-- =====================================================
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    branch_id UUID NOT NULL, -- ID de la sucursal/tienda
    customer_id UUID REFERENCES auth.users(id),

    -- Información del restaurante/sucursal
    restaurant_name TEXT NOT NULL,
    restaurant_address TEXT NOT NULL,
    restaurant_location GEOGRAPHY(POINT, 4326),

    -- Información del cliente
    customer_name TEXT NOT NULL,
    customer_address TEXT NOT NULL,
    customer_phone TEXT,
    customer_location GEOGRAPHY(POINT, 4326),

    -- Detalles del pedido
    order_type TEXT DEFAULT 'delivery', -- delivery, pickup
    status TEXT DEFAULT 'pending', -- pending, accepted, arrived_at_restaurant, picking_up, picked_up, delivering, delivered, rejected, cancelled
    total_amount NUMERIC(12, 2) DEFAULT 0,
    estimated_earnings NUMERIC(12, 2) DEFAULT 0, -- Ganancia del driver
    estimated_time_minutes INTEGER DEFAULT 30,
    distance_km NUMERIC(10, 2) DEFAULT 0,

    -- Códigos de verificación
    pickup_code VARCHAR(4),
    delivery_code VARCHAR(4),
    pickup_used BOOLEAN DEFAULT false,
    delivery_used BOOLEAN DEFAULT false,
    pickup_used_at TIMESTAMPTZ,
    delivery_used_at TIMESTAMPTZ,

    -- Asignación de driver
    driver_id UUID REFERENCES auth.users(id),
    zone_id UUID REFERENCES zones(id),

    -- Metadatos
    items JSONB DEFAULT '[]'::jsonb,
    delivery_metadata JSONB DEFAULT '{}'::jsonb,
    notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    accepted_at TIMESTAMPTZ,
    picked_up_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    cancelled_reason TEXT
);

-- =====================================================
-- ÍNDICES PARA RENDIMIENTO
-- =====================================================

-- Índices de búsqueda principal
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_driver ON orders(driver_id) WHERE driver_id IS NOT NULL;
CREATE INDEX idx_orders_branch ON orders(branch_id);
CREATE INDEX idx_orders_zone ON orders(zone_id) WHERE zone_id IS NOT NULL;
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);

-- Índices geoespaciales
CREATE INDEX idx_orders_restaurant_location ON orders USING GIST(restaurant_location);
CREATE INDEX idx_orders_customer_location ON orders USING GIST(customer_location);

-- Índice compuesto para pedidos pendientes por zona
CREATE INDEX idx_orders_pending_zone ON orders(status, zone_id) WHERE status IN ('pending', 'ready_for_pickup');

-- Índice para buscar pedidos cercanos
CREATE INDEX idx_orders_nearby ON orders USING GIST(
    ST_Buffer(restaurant_location, 5000) -- 5km buffer
) WHERE status IN ('pending', 'ready_for_pickup');

-- =====================================================
-- ACTUALIZAR TABLA: profiles
-- =====================================================
DO $$
BEGIN
    -- Agregar campos de delivery si no existen
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'is_online') THEN
        ALTER TABLE profiles ADD COLUMN is_online BOOLEAN DEFAULT false;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'current_latitude') THEN
        ALTER TABLE profiles ADD COLUMN current_latitude DOUBLE PRECISION;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'current_longitude') THEN
        ALTER TABLE profiles ADD COLUMN current_longitude DOUBLE PRECISION;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'zone_id') THEN
        ALTER TABLE profiles ADD COLUMN zone_id UUID REFERENCES zones(id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'vehicle_type') THEN
        ALTER TABLE profiles ADD COLUMN vehicle_type VARCHAR(50);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'vehicle_plate') THEN
        ALTER TABLE profiles ADD COLUMN vehicle_plate VARCHAR(20);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'total_earnings') THEN
        ALTER TABLE profiles ADD COLUMN total_earnings NUMERIC(12, 2) DEFAULT 0;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'is_driver') THEN
        ALTER TABLE profiles ADD COLUMN is_driver BOOLEAN DEFAULT false;
    END IF;
END $$;

-- =====================================================
-- TABLA: driver_locations (Ubicación en tiempo real)
-- =====================================================
CREATE TABLE IF NOT EXISTS driver_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    speed DOUBLE PRECISION,
    heading DOUBLE PRECISION,
    battery_level INTEGER,
    is_online BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true, -- Si está disponible para recibir pedidos
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_driver_locations_driver ON driver_locations(driver_id);
CREATE INDEX idx_driver_locations_online ON driver_locations(is_online, is_active) WHERE is_online = true AND is_active = true;
CREATE INDEX idx_driver_locations_updated ON driver_locations(updated_at DESC);

-- =====================================================
-- TABLA: driver_zones (Relación conductor-zonas)
-- =====================================================
CREATE TABLE IF NOT EXISTS driver_zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    zone_id UUID NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(driver_id, zone_id)
);

CREATE INDEX idx_driver_zones_driver ON driver_zones(driver_id);
CREATE INDEX idx_driver_zones_zone ON driver_zones(zone_id);

-- =====================================================
-- ACTUALIZAR TABLA: order_track (Agregar campos si no existen)
-- =====================================================
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'order_track' AND column_name = 'pickup_code_verified') THEN
        ALTER TABLE order_track ADD COLUMN pickup_code_verified BOOLEAN DEFAULT false;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'order_track' AND column_name = 'delivery_code_verified') THEN
        ALTER TABLE order_track ADD COLUMN delivery_code_verified BOOLEAN DEFAULT false;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'order_track' AND column_name = 'driver_location_lat') THEN
        ALTER TABLE order_track ADD COLUMN driver_location_lat DOUBLE PRECISION;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'order_track' AND column_name = 'driver_location_lng') THEN
        ALTER TABLE order_track ADD COLUMN driver_location_lng DOUBLE PRECISION;
    END IF;
END $$;

-- =====================================================
-- FUNCIONES Y TRIGGERS
-- =====================================================

-- Función para actualizar timestamp automático
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para updated_at
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_driver_locations_updated_at BEFORE UPDATE ON driver_locations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_driver_zones_updated_at BEFORE UPDATE ON driver_zones
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- FUNCIONES RPC
-- =====================================================

-- 1. Función para obtener pedidos cercanos al driver
CREATE OR REPLACE FUNCTION get_nearby_orders(
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_radius_km DOUBLE PRECISION DEFAULT 5.0,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    id UUID,
    restaurant_name TEXT,
    restaurant_address TEXT,
    customer_name TEXT,
    customer_address TEXT,
    total_amount NUMERIC,
    estimated_earnings NUMERIC,
    distance_km NUMERIC,
    status TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        o.id,
        o.restaurant_name,
        o.restaurant_address,
        o.customer_name,
        o.customer_address,
        o.total_amount,
        o.estimated_earnings,
        o.distance_km,
        o.status,
        o.created_at
    FROM orders o
    WHERE o.status IN ('pending', 'ready_for_pickup')
      AND o.driver_id IS NULL
      AND ST_DWithin(
          COALESCE(o.restaurant_location, ST_SetSRID(ST_MakePoint(0, 0), 4326)::geography),
          ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
          p_radius_km * 1000
      )
    ORDER BY
        ST_Distance(
            COALESCE(o.restaurant_location, ST_SetSRID(ST_MakePoint(0, 0), 4326)::geography),
            ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography
        )
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 2. Función para aceptar orden por código
CREATE OR REPLACE FUNCTION accept_order_by_code(
    p_order_id UUID,
    p_driver_id UUID,
    p_pickup_code TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_order RECORD;
    v_driver RECORD;
    v_result JSONB;
BEGIN
    -- Verificar que la orden existe y está en estado pending
    SELECT * INTO v_order
    FROM orders
    WHERE id = p_order_id
      AND status IN ('pending', 'ready_for_pickup');

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Orden no encontrada o ya fue tomada'
        );
    END IF;

    -- Verificar código de pickup si se proporciona
    IF v_order.pickup_code IS NOT NULL AND p_pickup_code IS NOT NULL THEN
        IF v_order.pickup_code != p_pickup_code THEN
            RETURN jsonb_build_object(
                'success', false,
                'message', 'Código de recogida incorrecto'
            );
        END IF;
    END IF;

    -- Verificar que no tenga driver asignado
    IF v_order.driver_id IS NOT NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Esta orden ya fue asignada a otro conductor'
        );
    END IF;

    -- Obtener info del driver
    SELECT * INTO v_driver
    FROM profiles
    WHERE id = p_driver_id;

    -- Asignar driver a la orden
    UPDATE orders
    SET
        driver_id = p_driver_id,
        status = 'accepted',
        accepted_at = NOW(),
        updated_at = NOW()
    WHERE id = p_order_id;

    -- Crear/actualizar registro de tracking
    INSERT INTO order_track (order_id, driver_id, status, driver_name, driver_phone, vehicle_info)
    VALUES (p_order_id, p_driver_id, 'accepted', v_driver.full_name, v_driver.phone, v_driver.vehicle_type)
    ON CONFLICT (order_id) DO UPDATE SET
        driver_id = p_driver_id,
        status = 'accepted',
        driver_name = v_driver.full_name,
        driver_phone = v_driver.phone,
        vehicle_info = v_driver.vehicle_type,
        updated_at = NOW();

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Orden aceptada correctamente',
        'order_id', p_order_id,
        'driver_name', v_driver.full_name
    );
END;
$$ LANGUAGE plpgsql;

-- 3. Función para actualizar estado de orden
CREATE OR REPLACE FUNCTION update_order_status_by_driver(
    p_order_id UUID,
    p_driver_id UUID,
    p_new_status TEXT,
    p_delivery_code TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_order RECORD;
    v_allowed_statuses TEXT[] := ARRAY['arrived_at_restaurant', 'picking_up', 'picked_up', 'delivering', 'delivered', 'cancelled'];
BEGIN
    -- Validar que el nuevo estado sea permitido
    IF p_new_status NOT IN ('arrived_at_restaurant', 'picking_up', 'picked_up', 'delivering', 'delivered', 'cancelled') THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Estado no válido'
        );
    END IF;

    -- Verificar que la orden existe y pertenece al driver
    SELECT * INTO v_order
    FROM orders
    WHERE id = p_order_id
      AND driver_id = p_driver_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Orden no encontrada o no te pertenece'
        );
    END IF;

    -- Validar transición de estado
    IF p_new_status = 'picked_up' AND v_order.status NOT IN ('accepted', 'arrived_at_restaurant', 'picking_up') THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Debes llegar al restaurante primero'
        );
    END IF;

    IF p_new_status = 'delivered' AND p_delivery_code IS NOT NULL THEN
        IF v_order.delivery_code != p_delivery_code THEN
            RETURN jsonb_build_object(
                'success', false,
                'message', 'Código de entrega incorrecto'
            );
        END IF;
    END IF;

    IF p_new_status = 'delivered' AND v_order.status NOT IN ('picked_up', 'delivering') THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'No puedes entregar sin haber recogido el pedido'
        );
    END IF;

    -- Actualizar estado de la orden
    UPDATE orders
    SET
        status = p_new_status,
        updated_at = NOW(),
        picked_up_at = CASE WHEN p_new_status = 'picked_up' THEN NOW() ELSE picked_up_at END,
        delivered_at = CASE WHEN p_new_status = 'delivered' THEN NOW() ELSE delivered_at END,
        pickup_used = CASE WHEN p_new_status = 'picked_up' THEN true ELSE pickup_used END,
        pickup_used_at = CASE WHEN p_new_status = 'picked_up' THEN NOW() ELSE pickup_used_at END,
        delivery_used = CASE WHEN p_new_status = 'delivered' THEN true ELSE delivery_used END,
        delivery_used_at = CASE WHEN p_new_status = 'delivered' THEN NOW() ELSE delivery_used_at END
    WHERE id = p_order_id;

    -- Actualizar tracking
    UPDATE order_track
    SET
        status = p_new_status,
        updated_at = NOW(),
        picked_up_at = CASE WHEN p_new_status = 'picked_up' THEN NOW() ELSE picked_up_at END,
        delivered_at = CASE WHEN p_new_status = 'delivered' THEN NOW() ELSE delivered_at END,
        pickup_code_verified = CASE WHEN p_new_status = 'picked_up' THEN true ELSE pickup_code_verified END,
        delivery_code_verified = CASE WHEN p_new_status = 'delivered' THEN true ELSE delivery_code_verified END
    WHERE order_id = p_order_id AND driver_id = p_driver_id;

    -- Si se entrega, agregar ganancias al driver
    IF p_new_status = 'delivered' THEN
        UPDATE profiles
        SET total_earnings = COALESCE(total_earnings, 0) + v_order.estimated_earnings,
            updated_at = NOW()
        WHERE id = p_driver_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Estado actualizado correctamente',
        'order_id', p_order_id,
        'new_status', p_new_status
    );
END;
$$ LANGUAGE plpgsql;

-- 4. Función para actualizar ubicación del driver
CREATE OR REPLACE FUNCTION update_driver_location(
    p_driver_id UUID,
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_accuracy DOUBLE PRECISION DEFAULT NULL,
    p_speed DOUBLE PRECISION DEFAULT NULL,
    p_heading DOUBLE PRECISION DEFAULT NULL,
    p_is_online BOOLEAN DEFAULT true,
    p_is_active BOOLEAN DEFAULT true
)
RETURNS JSONB AS $$
DECLARE
    v_location_id UUID;
BEGIN
    -- Verificar si existe registro de ubicación
    SELECT id INTO v_location_id
    FROM driver_locations
    WHERE driver_id = p_driver_id
    ORDER BY updated_at DESC
    LIMIT 1;

    IF v_location_id IS NULL THEN
        -- Crear nuevo registro
        INSERT INTO driver_locations (
            driver_id, latitude, longitude, accuracy, speed, heading, is_online, is_active
        ) VALUES (
            p_driver_id, p_latitude, p_longitude, p_accuracy, p_speed, p_heading, p_is_online, p_is_active
        );
    ELSE
        -- Actualizar existente
        UPDATE driver_locations
        SET
            latitude = p_latitude,
            longitude = p_longitude,
            accuracy = p_accuracy,
            speed = p_speed,
            heading = p_heading,
            is_online = p_is_online,
            is_active = p_is_active,
            last_active_at = NOW(),
            updated_at = NOW()
        WHERE id = v_location_id;
    END IF;

    -- También actualizar en profiles
    UPDATE profiles
    SET
        current_latitude = p_latitude,
        current_longitude = p_longitude,
        is_online = p_is_online,
        updated_at = NOW()
    WHERE id = p_driver_id;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Ubicación actualizada'
    );
END;
$$ LANGUAGE plpgsql;

-- 5. Función para obtener pedidos del driver
CREATE OR REPLACE FUNCTION get_driver_orders(
    p_driver_id UUID,
    p_status TEXT DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    restaurant_name TEXT,
    restaurant_address TEXT,
    customer_name TEXT,
    customer_address TEXT,
    customer_phone TEXT,
    total_amount NUMERIC,
    estimated_earnings NUMERIC,
    status TEXT,
    created_at TIMESTAMPTZ,
    accepted_at TIMESTAMPTZ,
    picked_up_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        o.id,
        o.restaurant_name,
        o.restaurant_address,
        o.customer_name,
        o.customer_address,
        o.customer_phone,
        o.total_amount,
        o.estimated_earnings,
        o.status,
        o.created_at,
        o.accepted_at,
        o.picked_up_at
    FROM orders o
    WHERE o.driver_id = p_driver_id
      AND (p_status IS NULL OR o.status = p_status)
    ORDER BY
        CASE o.status
            WHEN 'accepted' THEN 1
            WHEN 'arrived_at_restaurant' THEN 2
            WHEN 'picking_up' THEN 3
            WHEN 'picked_up' THEN 4
            WHEN 'delivering' THEN 5
            ELSE 6
        END,
        o.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- 6. Función para obtener info del driver asignado a una orden
CREATE OR REPLACE FUNCTION get_order_driver_info(
    p_order_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_order RECORD;
    v_driver RECORD;
BEGIN
    SELECT * INTO v_order FROM orders WHERE id = p_order_id;

    IF v_order.driver_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'No hay driver asignado a esta orden'
        );
    END IF;

    SELECT
        p.id,
        p.full_name,
        p.phone,
        p.vehicle_type,
        p.vehicle_plate,
        p.current_latitude,
        p.current_longitude,
        dl.is_online
    INTO v_driver
    FROM profiles p
    LEFT JOIN driver_locations dl ON dl.driver_id = p.id
    WHERE p.id = v_order.driver_id;

    RETURN jsonb_build_object(
        'success', true,
        'driver', v_driver
    );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- NOTIFICACIONES EN BASE DE DATOS (pg_notify)
-- =====================================================

-- Notificar a la sucursal cuando se asigna driver
CREATE OR REPLACE FUNCTION notify_branch_on_driver_assignment()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.driver_id IS DISTINCT FROM OLD.driver_id AND NEW.driver_id IS NOT NULL THEN
        PERFORM pg_notify(
            'driver_assigned',
            jsonb_build_object(
                'order_id', NEW.id,
                'driver_id', NEW.driver_id,
                'branch_id', NEW.branch_id,
                'event', 'driver_assigned',
                'timestamp', NOW()::text
            )::text
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_driver_assignment
AFTER UPDATE ON orders
FOR EACH ROW
WHEN (NEW.driver_id IS DISTINCT FROM OLD.driver_id AND NEW.driver_id IS NOT NULL)
EXECUTE FUNCTION notify_branch_on_driver_assignment();

-- Notificar cambio de estado
CREATE OR REPLACE FUNCTION notify_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        PERFORM pg_notify(
            'order_status_changed',
            jsonb_build_object(
                'order_id', NEW.id,
                'old_status', OLD.status,
                'new_status', NEW.status,
                'driver_id', NEW.driver_id,
                'branch_id', NEW.branch_id,
                'event', 'status_changed',
                'timestamp', NOW()::text
            )::text
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_order_status
AFTER UPDATE ON orders
FOR EACH ROW
WHEN (NEW.status IS DISTINCT FROM OLD.status)
EXECUTE FUNCTION notify_order_status_change();

-- =====================================================
-- RLS POLICIES
-- =====================================================

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_zones ENABLE ROW LEVEL SECURITY;

-- Orders: Drivers ven sus pedidos, sucursales ven los suyos
CREATE POLICY "orders_driver_select" ON orders
    FOR SELECT USING (driver_id = auth.uid());

CREATE POLICY "orders_branch_select" ON orders
    FOR SELECT USING (branch_id IN (
        SELECT store_id FROM sales WHERE organization_id = (
            SELECT primary_organization_id FROM profiles WHERE id = auth.uid()
        )
    ));

-- Driver locations: Solo el propio driver
CREATE POLICY "driver_locations_own" ON driver_locations
    FOR ALL USING (driver_id = auth.uid());

-- =====================================================
-- SEED DATA - Zonas de ejemplo
-- =====================================================
INSERT INTO zones (name, description, center_latitude, center_longitude, radius_km) VALUES
('Centro', 'Zona centro - Sabaneta', 6.195618, -75.575971, 5.0),
('Norte', 'Zona norte', 6.210000, -75.570000, 4.0),
('Sur', 'Zona sur', 6.180000, -75.580000, 4.0),
('Este', 'Zona este', 6.195000, -75.560000, 3.0),
('Oeste', 'Zona oeste', 6.196000, -75.590000, 3.5)
ON CONFLICT DO NOTHING;

-- =====================================================
-- COMENTARIOS
-- =====================================================
COMMENT ON TABLE orders IS 'Tabla principal de pedidos de delivery';
COMMENT ON TABLE driver_locations IS 'Ubicación en tiempo real de los drivers';
COMMENT ON TABLE driver_zones IS 'Relación entre drivers y zonas de cobertura';
COMMENT ON FUNCTION get_nearby_orders IS 'Obtiene pedidos cercanos a una ubicación específica';
COMMENT ON FUNCTION accept_order_by_code IS 'Acepta una orden usando código de verificación opcional';
COMMENT ON FUNCTION update_order_status_by_driver IS 'Actualiza el estado de una orden por el driver';
COMMENT ON FUNCTION update_driver_location IS 'Actualiza la ubicación del driver';
COMMENT ON FUNCTION get_driver_orders IS 'Obtiene todos los pedidos de un driver';
COMMENT ON FUNCTION get_order_driver_info IS 'Obtiene información del driver asignado a una orden';
```

---

## 3. Edge Functions

### 3.1 Función: `accept-order` (Aceptar pedido con código)

```typescript
// supabase/functions/accept-order/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ success: false, message: 'No autorizado' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401
      })
    }

    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authHeader } }
    })

    const { order_id, pickup_code } = await req.json()

    if (!order_id) {
      return new Response(JSON.stringify({ success: false, message: 'order_id requerido' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      })
    }

    // Obtener usuario actual
    const { data: { user }, error: authError } = await supabase.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ success: false, message: 'Usuario no autorizado' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401
      })
    }

    // Llamar RPC
    const { data, error } = await supabase.rpc('accept_order_by_code', {
      p_order_id: order_id,
      p_driver_id: user.id,
      p_pickup_code: pickup_code
    })

    if (error) throw error

    // Notificar a la sucursal
    if (data?.success) {
      const { data: order } = await supabase
        .from('orders')
        .select('branch_id, restaurant_name')
        .eq('id', order_id)
        .single()

      if (order) {
        // Aquí puedes enviar notificación a la sucursal via webhook o push
        console.log(`Notificar a sucursal ${order.branch_id}: Driver ${user.id} tomó el pedido ${order_id}`)
      }
    }

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500
    })
  }
})
```

### 3.2 Función: `update-order-status` (Actualizar estado)

```typescript
// supabase/functions/update-order-status/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const ALLOWED_STATUSES = [
  'arrived_at_restaurant',
  'picking_up',
  'picked_up',
  'delivering',
  'delivered',
  'cancelled'
]

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ success: false, message: 'No autorizado' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401
      })
    }

    const supabase = createClient(supabaseUrl, supabaseKey, {
      global: { headers: { Authorization: authHeader } }
    })

    const { order_id, new_status, delivery_code } = await req.json()

    if (!order_id || !new_status) {
      return new Response(JSON.stringify({ success: false, message: 'order_id y new_status requeridos' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      })
    }

    if (!ALLOWED_STATUSES.includes(new_status)) {
      return new Response(JSON.stringify({ success: false, message: 'Estado no válido' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      })
    }

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      return new Response(JSON.stringify({ success: false, message: 'Usuario no autorizado' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 401
      })
    }

    // Llamar RPC
    const { data, error } = await supabase.rpc('update_order_status_by_driver', {
      p_order_id: order_id,
      p_driver_id: user.id,
      p_new_status: new_status,
      p_delivery_code: delivery_code
    })

    if (error) throw error

    // Notificar a la sucursal sobre el cambio de estado
    if (data?.success) {
      const { data: order } = await supabase
        .from('orders')
        .select('branch_id')
        .eq('id', order_id)
        .single()

      if (order) {
        console.log(`Notificar a sucursal ${order.branch_id}: Estado cambiado a ${new_status}`)
      }
    }

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500
    })
  }
})
```

### 3.3 Función: `get-nearby-orders` (Obtener pedidos cercanos)

```typescript
// supabase/functions/get-nearby-orders/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { latitude, longitude, radius_km = 5, limit = 20 } = await req.json()

    const supabase = createClient(supabaseUrl, supabaseKey)

    // Llamar RPC
    const { data, error } = await supabase.rpc('get_nearby_orders', {
      p_latitude: latitude,
      p_longitude: longitude,
      p_radius_km: radius_km,
      p_limit: limit
    })

    if (error) throw error

    return new Response(JSON.stringify({ success: true, orders: data }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500
    })
  }
})
```

### 3.4 Función: `get-order-driver` (Obtener driver de orden para sucursal)

```typescript
// supabase/functions/get-order-driver/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { order_id } = await req.json()

    if (!order_id) {
      return new Response(JSON.stringify({ success: false, message: 'order_id requerido' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400
      })
    }

    const supabase = createClient(supabaseUrl, supabaseKey)

    // Obtener info del driver
    const { data, error } = await supabase.rpc('get_order_driver_info', {
      p_order_id: order_id
    })

    if (error) throw error

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })

  } catch (error) {
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500
    })
  }
})
```

---

## 4. Mejoras de Rendimiento

### 4.1 Optimización del Location Service

```dart
// lib/service/optimized_location_service.dart

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:delivery_app_mvvm/model/location_data.dart';
import 'package:delivery_app_mvvm/service/location_service.dart';

class OptimizedLocationService implements LocationService {
  StreamController<LocationData>? _locationController;
  StreamSubscription<Position>? _positionSubscription;

  // Configuración optimizada
  static const int _distanceFilter = 30; // metros - reduce actualizaciones
  static const Duration _throttleDuration = Duration(seconds: 5);
  DateTime? _lastEmitTime;

  // Cache de última ubicación
  LocationData? _lastLocation;
  static const Duration _cacheMaxAge = Duration(minutes: 2);

  OptimizedLocationService() {
    _locationController = StreamController<LocationData>.broadcast();
    _initLocationStream();
  }

  Future<void> _initLocationStream() async {
    // Verificar permisos
    final permission = await _checkPermissions();
    if (!permission) return;

    // Configuración optimizada para battery saving
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.balanced, // balanced en lugar de high
        distanceFilter: _distanceFilter,
      ),
    ).listen(
      (Position position) {
        final now = DateTime.now();

        // Throttle: no emitir más de una vez cada 5 segundos
        if (_lastEmitTime != null &&
            now.difference(_lastEmitTime!) < _throttleDuration) {
          return;
        }

        // Verificar que la ubicación sea válida
        if (position.accuracy > 100) return; // Ignorar si precisión > 100m

        final location = LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: position.timestamp,
        );

        _lastLocation = location;
        _lastEmitTime = now;
        _locationController?.add(location);
      },
      onError: (e) {
        _locationController?.addError('Error en stream: $e');
      },
    );
  }

  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _locationController?.addError('Servicios de ubicación deshabilitados');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _locationController?.addError('Permisos denegados');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _locationController?.addError('Permisos denegados permanentemente');
      return false;
    }

    return true;
  }

  @override
  Future<LocationData> getCurrentLocation() async {
    // Retornar cache si es reciente
    if (_lastLocation != null &&
        DateTime.now().difference(_lastLocation!.timestamp) < _cacheMaxAge) {
      return _lastLocation!;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.balanced,
      );

      final location = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp,
      );

      _lastLocation = location;
      return location;
    } catch (e) {
      // Retornar última ubicación conocida si hay error
      if (_lastLocation != null) {
        return _lastLocation!;
      }
      rethrow;
    }
  }

  @override
  Stream<LocationData> getLocationStream() {
    return _locationController!.stream;
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _locationController?.close();
  }
}
```

### 4.2 Optimización de Búsqueda de Pedidos

```dart
// Optimización: Solo buscar cuando el driver está en zona válida
class ZoneMatchingService {
  final SupabaseClient _supabase;

  Future<List<Order>> getNearbyOrders({
    required double latitude,
    required double longitude,
    double radiusKm = 3.0, // Reducido para menor carga
  }) async {
    try {
      final response = await _supabase.rpc('get_nearby_orders', params: {
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_radius_km': radiusKm,
        'p_limit': 10, // Reducido de 20 a 10
      });

      if (response.error != null) {
        throw response.error!;
      }

      return response.data.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching nearby orders: $e');
      return [];
    }
  }
}
```

### 4.3 Optimización del Realtime

```dart
// Reducir carga de realtime con filtros más específicos
class OptimizedOrderSubscription {
  void subscribeToZoneOrders({
    required String zoneId,
    required Function(Order) onNewOrder,
  }) {
    supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .eq('zone_id', zoneId) // Filtrar por zona
        .limit(5) // Limitar a 5 pedidos
        .listen((data) {
          // Solo procesar si hay datos nuevos
          for (final orderData in data) {
            onNewOrder(Order.fromJson(orderData));
          }
        });
  }
}
```

---

## 5. Sistema de Geolocalización

### 5.1 Flujo Completo de Geolocalización

```
┌─────────────────────────────────────────────────────────────────┐
│              FLUJO DE GEOLOCALIZACIÓN v2.0                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. APP DRIVER                                                  │
│     ├─ Login → Solicitar permisos ubicación                    │
│     ├─ Go Online                                               │
│     │   └→ Actualizar ubicación en BDD (driver_locations)    │
│     │   └→ Asignar a zona más cercana                         │
│     │   └→ Activar escucha de pedidos por zona                │
│     │                                                          │
│  2. SISTEMA                                                     │
│     ├─ Driver entra en zona activa                             │
│     ├─ Buscar pedidos pending en esa zona                      │
│     ├─ Notificar al driver (push notification)                │
│     │                                                          │
│  3. ACCEPT ORDER                                                │
│     ├─ Driver acepta con código (opcional)                   │
│     ├─ Asignar driver_id a orders                              │
│     ├─ Crear registro en order_track                           │
│     └─ Notificar a sucursal (web/app):                        │
│         "Driver [NOMBRE] tomó el pedido [CÓDIGO]"            │
│                                                                  │
│  4. DURANTE ENTREGA                                             │
│     ├─ Driver actualiza estado ( arrived → picked_up )       │
│     ├─ Driver actualiza ubicación en tiempo real              │
│     └─ Sucursal puede ver ubicación del driver                │
│                                                                  │
│  5. COMPLETADO                                                  │
│     ├─ Driver entrega y verifica código                      │
│     ├─ Estado → delivered                                      │
│     └─ Agregar ganancias al driver                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Servicio de Zona en Flutter

```dart
// lib/service/zone_matching_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/order.dart';

class ZoneMatchingService {
  final SupabaseClient _supabase;

  ZoneMatchingService(this._supabase);

  /// Obtiene la zona más cercana a una ubicación
  Future<Zone?> getNearestZone({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _supabase
          .from('zones')
          .select('*')
          .eq('is_active', true)
          .execute();

      if (response.error != null || response.data == null) {
        return null;
      }

      Zone? nearestZone;
      double minDistance = double.infinity;

      for (final zone in response.data) {
        final distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          zone['center_latitude'],
          zone['center_longitude'],
        );

        // Convertir a km
        final distanceKm = distance / 1000;

        if (distanceKm <= zone['radius_km'] && distanceKm < minDistance) {
          minDistance = distanceKm;
          nearestZone = Zone.fromJson(zone);
        }
      }

      return nearestZone;
    } catch (e) {
      debugPrint('Error getting nearest zone: $e');
      return null;
    }
  }

  /// Asigna el driver a una zona
  Future<bool> assignDriverToZone({
    required String driverId,
    required String zoneId,
    bool isPrimary = true,
  }) async {
    try {
      // Si es primary, desvincular otros primary
      if (isPrimary) {
        await _supabase
            .from('driver_zones')
            .update({'is_primary': false})
            .eq('driver_id', driverId)
            .eq('is_primary', true);
      }

      // Insertar o actualizar
      final response = await _supabase
          .from('driver_zones')
          .upsert({
            'driver_id': driverId,
            'zone_id': zoneId,
            'is_primary': isPrimary,
          }, onConflict: 'driver_id,zone_id');

      return response.error == null;
    } catch (e) {
      debugPrint('Error assigning driver to zone: $e');
      return false;
    }
  }

  /// Obtiene pedidos cercanos al driver
  Future<List<Order>> getNearbyOrders({
    required double latitude,
    required double longitude,
    double radiusKm = 3.0,
    int limit = 10,
  }) async {
    try {
      final response = await _supabase.rpc('get_nearby_orders', params: {
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_radius_km': radiusKm,
        'p_limit': limit,
      });

      if (response.error != null) {
        debugPrint('Error getting nearby orders: ${response.error}');
        return [];
      }

      return (response.data as List)
          .map((json) => Order.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching nearby orders: $e');
      return [];
    }
  }
}

// Modelo Zone
class Zone {
  final String id;
  final String name;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusKm;
  final bool isActive;

  Zone({
    required this.id,
    required this.name,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusKm,
    required this.isActive,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id'],
      name: json['name'],
      centerLatitude: (json['center_latitude'] as num).toDouble(),
      centerLongitude: (json['center_longitude'] as num).toDouble(),
      radiusKm: (json['radius_km'] as num).toDouble(),
      isActive: json['is_active'] ?? true,
    );
  }
}
```

---

## 6. UX/UI Mejoras

### 6.1 Diseño Adaptativo

```dart
// lib/core/utils/adaptive_layout.dart

import 'package:flutter/material.dart';

class AdaptiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget? tabletLayout;
  final Widget? desktopLayout;

  const AdaptiveLayout({
    super.key,
    required this.mobileLayout,
    this.tabletLayout,
    this.desktopLayout,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Breakpoints
    if (screenWidth >= 1200 && desktopLayout != null) {
      return desktopLayout!;
    } else if (screenWidth >= 600 && tabletLayout != null) {
      return tabletLayout!;
    }
    return mobileLayout;
  }

  // Métodos helper
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;
}
```

### 6.2 Componentes de UI

```dart
// lib/widget/delivery_button.dart

import 'package:flutter/material.dart';

class DeliveryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final DeliveryButtonStyle style;
  final IconData? icon;

  const DeliveryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.style = DeliveryButtonStyle.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _getBackgroundColor(),
          foregroundColor: _getTextColor(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: style == DeliveryButtonStyle.primary ? 2 : 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (style) {
      case DeliveryButtonStyle.primary:
        return const Color(0xFF6C63FF); // Primary purple
      case DeliveryButtonStyle.secondary:
        return const Color(0xFFF5F5F5);
      case DeliveryButtonStyle.success:
        return const Color(0xFF4CAF50);
      case DeliveryButtonStyle.danger:
        return const Color(0xFFF44336);
    }
  }

  Color _getTextColor() {
    switch (style) {
      case DeliveryButtonStyle.primary:
      case DeliveryButtonStyle.success:
      case DeliveryButtonStyle.danger:
        return Colors.white;
      case DeliveryButtonStyle.secondary:
        return const Color(0xFF333333);
    }
  }
}

enum DeliveryButtonStyle {
  primary,
  secondary,
  success,
  danger,
}
```

```dart
// lib/widget/order_card.dart

import 'package:flutter/material.dart';
import '../model/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final bool showActions;

  const OrderCard({
    super.key,
    required this.order,
    this.onAccept,
    this.onDecline,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.restaurantName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${order.estimatedEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Restaurant
            Row(
              children: [
                const Icon(Icons.store, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.restaurantAddress,
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Customer
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.customerName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.customerAddress,
                    style: const TextStyle(color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info row
            Row(
              children: [
                _InfoChip(
                  icon: Icons.straighten,
                  label: '${order.distanceKm.toStringAsFixed(1)} km',
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.timer,
                  label: '${order.estimatedTimeMinutes} min',
                ),
                const Spacer(),
                if (order.totalAmount > 0)
                  Text(
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),

            // Actions
            if (showActions && onAccept != null && onDecline != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
```

### 6.3 Pantalla de Home Mejorada

```dart
// Improved home_screen con diseño competitivo
// (Simplificado - versión completa en el código)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ... existing code ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdaptiveLayout(
        mobileLayout: _buildMobileLayout(),
        tabletLayout: _buildTabletLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        // Mapa
        GoogleMap(/* ... */),

        // Header flotante
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildHeaderCard(),
          ),
        ),

        // Panel inferior
        if (homeViewModel.userStatus.status == UserConnectionStatus.online)
          _buildOnlinePanel(),
        else if (homeViewModel.userStatus.status == UserConnectionStatus.offline)
          _buildOfflinePanel(),

        // Notificación de nuevo pedido
        if (newOrderViewModel.currentNewOrder != null)
          _buildNewOrderAlert(),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: homeViewModel.userStatus.status == UserConnectionStatus.online
                  ? Colors.green
                  : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homeViewModel.userStatus.status == UserConnectionStatus.online
                      ? 'En línea'
                      : 'Desconectado',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  homeViewModel.userStatus.message,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Earnings
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Ganancias',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Text(
                '\$${homeViewModel.totalEarnings.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 7. Momentos de Appearance del Delivery

### 7.1 Cuándo Mostrar Pedidos al Driver

```
┌─────────────────────────────────────────────────────────────────┐
│              FLUJO DE APARICIÓN DE PEDIDOS                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  CONDICIONES PARA QUE UN PEDIDO APAREZCA AL DRIVER:            │
│  ─────────────────────────────────────────────────────────────  │
│                                                                  │
│  1. Driver debe estar ONLINE                                     │
│     └→ profiles.is_online = true                                │
│     └→ driver_locations.is_active = true                        │
│                                                                  │
│  2. Driver debe tener zona asignada                              │
│     └→ driver_zones.is_active = true                            │
│     └→ O estar dentro de una zona de cobertura                   │
│                                                                  │
│  3. Pedido debe estar en estado PENDIENTE                       │
│     └→ orders.status = 'pending'                                │
│     └→ O orders.status = 'ready_for_pickup'                     │
│                                                                  │
│  4. Pedido debe estar en la zona del driver                     │
│     └→ orders.zone_id = driver's zone_id                        │
│     O                                                            │
│     └→ orders.restaurant_location dentro del radio del driver   │
│                                                                  │
│  5. Pedido NO debe tener driver asignado                        │
│     └→ orders.driver_id = NULL                                   │
│                                                                  │
│  ─────────────────────────────────────────────────────────────  │
│                                                                  │
│  MOMENTO DE NOTIFICAR:                                          │
│  ──────────────────────                                          │
│                                                                  │
│  ✓ Cuando se crea un nuevo pedido                               │
│  ✓ Cuando un pedido pendiente entra en la zona del driver      │
│  ✓ Cuando un pedido السابق se cancela y hay nuevo disponible  │
│                                                                  │
│  NO NOTIFICAR:                                                   │
│  ─────────────                                                   │
│  ✗ Si el driver tiene una orden activa                          │
│  ✗ Si el driver está en modo offline                            │
│  ✗ Si no hay pedidos en su zona                                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 7.2 Lógica de Matching

```dart
class OrderMatchingLogic {
  /// Verifica si un pedido debe mostrarse a un driver específico
  static bool shouldShowOrderToDriver({
    required Order order,
    required Driver driver,
    required List<Zone> driverZones,
  }) {
    // 1. El pedido debe estar pendiente
    if (order.status != 'pending' && order.status != 'ready_for_pickup') {
      return false;
    }

    // 2. El pedido no debe tener driver asignado
    if (order.driverId != null) {
      return false;
    }

    // 3. El driver debe estar online y activo
    if (!driver.isOnline || !driver.isActive) {
      return false;
    }

    // 4. Verificar si el pedido está en alguna de las zonas del driver
    final orderZone = order.zoneId;
    if (orderZone != null) {
      final isInDriverZone = driverZones.any((z) => z.id == orderZone);
      if (!isInDriverZone) {
        return false;
      }
    } else {
      // Si no tiene zona, verificar por distancia
      final distance = Geolocator.distanceBetween(
        order.restaurantLocation.latitude,
        order.restaurantLocation.longitude,
        driver.currentLatitude,
        driver.currentLongitude,
      );

      // Si está a más de 5km, no mostrar
      if (distance > 5000) {
        return false;
      }
    }

    // 5. El driver no debe tener una orden activa
    if (driver.hasActiveOrder) {
      return false;
    }

    return true;
  }
}
```

---

## 8. Notificaciones a Sucursal

### 8.1 Cuándo Notificar

```
┌─────────────────────────────────────────────────────────────────┐
│              NOTIFICACIONES A SUCURSAL                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  EVENTO                      │  CUANDO ENVIAR                   │
│  ────────────────────────────────────────────────────────────   │
│                                                                  │
│  1. DRIVER ASIGNADO         │  Cuando un driver acepta un      │
│     (driver_assigned)       │  pedido y se asigna su ID         │
│                             │  → Mostrar: "Driver [NOMBRE]      │
│                             │     tomó el pedido #[CÓDIGO]"    │
│                             │  → Mostrar info del driver        │
│                             │     (nombre, teléfono, vehículo)  │
│                                                                  │
│  2. ESTADO CAMBIADO         │  Cuando el driver cambia el       │
│     (status_changed)        │  estado del pedido:               │
│                             │  → "En camino al restaurante"     │
│                             │  → "Llegó al restaurante"        │
│                             │  → "Pedido recogido"              │
│                             │  → "En camino al cliente"         │
│                             │  → "Entregado"                   │
│                                                                  │
│  3. DRIVER CANCELÓ         │  Cuando el driver rechaza o      │
│     (order_cancelled)      │  cancela un pedido asignado      │
│                                                                  │
│  4. UBICACIÓN ACTUALIZADA  │  Durante entrega: cada 30 seg    │
│     (location_update)     │  → Para tracking en tiempo real   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Webhook para Sucursal

```typescript
// La sucursal/web debe escuchar estos eventos:
// - Via Supabase Realtime: channel 'orders'
// - Via pg_notify: 'driver_assigned', 'order_status_changed'

// Ejemplo de payload para driver_assigned:
{
  "event": "driver_assigned",
  "order_id": "uuid-orden",
  "driver_id": "uuid-driver",
  "branch_id": "uuid-sucursal",
  "driver_info": {
    "name": "Juan Pérez",
    "phone": "+573001234567",
    "vehicle": "Moto - ABC123",
    "photo_url": "https://..."
  },
  "pickup_code": "1234",
  "timestamp": "2026-03-08T10:30:00Z"
}
```

---

## 9. Checklist de Implementación

### 9.1 Base de Datos
- [ ] Ejecutar script SQL completo
- [ ] Verificar creación de tabla `orders`
- [ ] Verificar tablas `driver_locations`, `driver_zones`
- [ ] Probar funciones RPC
- [ ] Configurar RLS policies

### 9.2 Edge Functions
- [ ] Desplegar `accept-order`
- [ ] Desplegar `update-order-status`
- [ ] Desplegar `get-nearby-orders`
- [ ] Desplegar `get-order-driver`

### 9.3 Flutter App
- [ ] Actualizar modelo `Order`
- [ ] Crear `ZoneMatchingService`
- [ ] Actualizar `LocationService` con optimizaciones
- [ ] Implementar diseño adaptativo
- [ ] Crear componentes UI reutilizables

### 9.4 Pruebas
- [ ] Probar flujo completo: login → online → pedido → accept → entrega
- [ ] Probar notificaciones a sucursal
- [ ] Probar geolocalización
- [ ] Probar rendimiento en dispositivo real

---

## 10. Notas de Producción

### 10.1 Configuración Android
```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### 10.2 Configuración iOS
```xml
<!-- ios/Runner/Info.plist -->
<key>NSLocationWhenInUseUsageDescription</key>
<string> necesitamos tu ubicación para encontrar pedidos cercanos</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string> necesitamos tu ubicación para notificaciones en segundo plano</string>
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

---

**Documento creado:** 8 de Marzo de 2026
**Versión:** 2.0.0
