# Análisis Completo y Plan de Migración - App Delivery Recompry

**Fecha de creación:** 8 de Marzo de 2026
**Versión actual:** 1.0.0
**Estado:** En Análisis

---

## 1. Resumen Ejecutivo

Este documento presenta el análisis completo de la aplicación de delivery actual y define la hoja de ruta para las mejoras necesarias. La aplicación está construida con Flutter usando una arquitectura MVVM con Clean Architecture, integrando Supabase como backend. Se identificaron oportunidades significativas de mejora en rendimiento, UX/UI, y funcionalidad de geolocalización.

---

## 2. Análisis de la Arquitectura Actual

### 2.1 Estructura del Proyecto

```
lib/
├── core/
│   ├── error/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── usecases/
│   │   └── usecase.dart
│   └── utils/
│       └── constants.dart
├── data/
│   ├── datasources/
│   │   ├── auth_remote_data_source.dart
│   │   ├── earning_remote_datasource.dart
│   │   ├── home_local_data_source.dart
│   │   └── home_remote_data_source.dart
│   └── repositories/
│       ├── auth_repository_impl.dart
│       ├── earning_repository_impl.dart
│       ├── home_repository_impl.dart
│       └── wallet_repository.dart
├── domain/
│   ├── entities/
│   │   ├── auth_user.dart
│   │   ├── bank_account.dart
│   │   ├── earning.dart
│   │   ├── transaction.dart
│   │   └── user_status.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── earning_repository.dart
│   │   └── home_repository.dart
│   └── usecases/
│       ├── get_auth_session.dart
│       ├── get_daily_earnings.dart
│       ├── get_earnings_usecase.dart
│       ├── get_user_online_status.dart
│       ├── go_offline.dart
│       ├── sign_in_user.dart
│       ├── sign_out_user.dart
│       └── sign_up_user.dart
├── model/
│   ├── earning_model.dart
│   ├── location_data.dart
│   └── order.dart
├── service/
│   ├── connectivity_service.dart
│   ├── location_service.dart
│   ├── mock_location_service.dart
│   ├── mock_order_service.dart
│   ├── notification_service.dart
│   ├── order_service.dart
│   └── real_location_service.dart
├── view/
│   ├── active_order_screen.dart
│   ├── auth_screen.dart
│   ├── configuration_screen.dart
│   ├── earning_detail_page.dart
│   ├── earning_page.dart
│   ├── feed_back_screen.dart
│   ├── home_screen.dart
│   ├── new_order_notification_screen.dart
│   └── wallet_screen.dart
├── viewmodel/
│   ├── active_order_viewmodel.dart
│   ├── auth_view_model.dart
│   ├── earning_viewmodel.dart
│   ├── home_view_model.dart
│   ├── new_order_viewmodel.dart
│   └── wallet_view_model.dart
├── widget/
│   └── (various widgets)
└── main.dart
```

### 2.2 Tecnologías y Dependencias

- **Flutter SDK:** ^3.8.0
- **State Management:** Provider ^6.1.2
- **Backend:** Supabase ^2.5.0
- **Maps:** google_maps_flutter ^2.5.0
- **Geolocation:** geolocator ^11.0.0
- **Notifications:** flutter_local_notifications ^17.0.0
- **Charts:** fl_chart ^0.68.0
- **HTTP:**2.1

---

## 3 http ^1.. Análisis de la Base de Datos Supabase

### 3.1 Estado Actual de las Tablas

Basado en el análisis del código, se identificaron las siguientes tablas necesarias:

#### Tabla: `orders` (Pedidos)
- **Propósito:** Almacenar todos los pedidos del sistema
- **Campos identificados del código:**
  - `id` (UUID, Primary Key)
  - `customer_name` (TEXT)
  - `customer_address` (TEXT)
  - `customer_phone` (TEXT)
  - `customer_location` (POINT/GEOMETRY)
  - `restaurant_name` (TEXT)
  - `restaurant_address` (TEXT)
  - `restaurant_location` (POINT/GEOMETRY)
  - `order_type` (TEXT) - Ej: "Comida", "Supermercado", "Farmacia"
  - `estimated_earnings` (DOUBLE PRECISION)
  - `estimated_time_minutes` (INTEGER)
  - `distance_km` (DOUBLE PRECISION)
  - `items` (JSONB)
  - `total_amount` (DOUBLE PRECISION)
  - `status` (TEXT) - Estados: pending, accepted, arrived_at_restaurant, picking_up, picked_up, delivering, delivered, rejected
  - `driver_id` (UUID, Foreign Key a auth.users)
  - `created_at` (TIMESTAMPTZ)
  - `updated_at` (TIMESTAMPTZ)

#### Tabla: `profiles` (Perfiles de usuario)
- **Propósito:** Almacenar información extendida del usuario
- **Campos identificados:**
  - `id` (UUID, Primary Key, FK a auth.users)
  - `total_earnings` (DOUBLE PRECISION)
  - `is_online` (BOOLEAN)
  - `current_latitude` (DOUBLE PRECISION)
  - `current_longitude` (DOUBLE PRECISION)
  - `zone_id` (UUID, FK a zones)
  - `vehicle_type` (TEXT)
  - `phone` (TEXT)
  - `created_at` (TIMESTAMPTZ)
  - `updated_at` (TIMESTAMPTZ)

### 3.2 Tablas Faltantes Identificadas

Se requieren las siguientes tablas adicionales para completar el sistema:

1. **`zones`** - Zonas de cobertura
2. **`order_track`** - Seguimiento del pedido con conductor asignado
3. **`delivery_codes`** - Códigos de verificación
4. **`driver_zones`** - Relación conductor-zonas

---

## 4. Migración de Base de Datos - Supabase

### 4.1 SQL Migration - Versión 1.0

```sql
-- =====================================================
-- MIGRACIÓN COMPLETA PARA APP DELIVERY RECOMPRY
-- Fecha: 2026-03-08
-- Versión: 1.0.0
-- =====================================================

-- Habilitar extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- =====================================================
-- TABLA: zones (Zonas de cobertura)
-- =====================================================
CREATE TABLE IF NOT EXISTS zones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    center_latitude DOUBLE PRECISION NOT NULL,
    center_longitude DOUBLE PRECISION NOT NULL,
    radius_km DOUBLE PRECISION NOT NULL DEFAULT 5.0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Índices para zonas
CREATE INDEX idx_zones_active ON zones(is_active) WHERE is_active = true;
CREATE INDEX idx_zones_location ON zones(center_latitude, center_longitude);

-- =====================================================
-- TABLA: delivery_codes (Códigos de verificación)
-- =====================================================
CREATE TABLE IF NOT EXISTS delivery_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    pickup_code VARCHAR(4) NOT NULL,
    delivery_code VARCHAR(4) NOT NULL,
    pickup_used BOOLEAN DEFAULT false,
    delivery_used BOOLEAN DEFAULT false,
    pickup_used_at TIMESTAMPTZ,
    delivery_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '24 hours')
);

CREATE INDEX idx_delivery_codes_order ON delivery_codes(order_id);
CREATE INDEX idx_delivery_codes_pickup ON delivery_codes(pickup_code);
CREATE INDEX idx_delivery_codes_delivery ON delivery_codes(delivery_code);

-- =====================================================
-- TABLA: order_track (Seguimiento de pedidos)
-- =====================================================
CREATE TABLE IF NOT EXISTS order_track (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    driver_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    branch_id UUID NOT NULL, -- ID de la sucursal
    status VARCHAR(50) NOT NULL DEFAULT 'assigned',
    assigned_at TIMESTAMPTZ DEFAULT NOW(),
    picked_up_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    driver_name VARCHAR(255),
    driver_phone VARCHAR(20),
    vehicle_info TEXT,
    estimated_arrival TIMESTAMPTZ,
    actual_arrival TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_order_track_order ON order_track(order_id);
CREATE INDEX idx_order_track_driver ON order_track(driver_id);
CREATE INDEX idx_order_track_branch ON order_track(branch_id);
CREATE INDEX idx_order_track_status ON order_track(status);

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
CREATE INDEX idx_driver_zones_active ON driver_zones(is_active) WHERE is_active = true;

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
    last_active_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_driver_locations_driver ON driver_locations(driver_id);
CREATE INDEX idx_driver_locations_online ON driver_locations(is_online) WHERE is_online = true;
CREATE INDEX idx_driver_locations_updated ON driver_locations(updated_at DESC);

-- =====================================================
-- ACTUALIZAR TABLA: orders
-- =====================================================
DO $$
BEGIN
    -- Agregar campos faltantes si no existen
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'branch_id') THEN
        ALTER TABLE orders ADD COLUMN branch_id UUID;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'pickup_code') THEN
        ALTER TABLE orders ADD COLUMN pickup_code VARCHAR(4);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'delivery_code') THEN
        ALTER TABLE orders ADD COLUMN delivery_code VARCHAR(4);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'customer_location') THEN
        ALTER TABLE orders ADD COLUMN customer_location GEOGRAPHY(POINT, 4326);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'restaurant_location') THEN
        ALTER TABLE orders ADD COLUMN restaurant_location GEOGRAPHY(POINT, 4326);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'orders' AND column_name = 'zone_id') THEN
        ALTER TABLE orders ADD COLUMN zone_id UUID REFERENCES zones(id);
    END IF;
END $$;

-- =====================================================
-- ACTUALIZAR TABLA: profiles
-- =====================================================
DO $$
BEGIN
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

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'photo_url') THEN
        ALTER TABLE profiles ADD COLUMN photo_url TEXT;
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

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_zones_updated_at BEFORE UPDATE ON zones
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_driver_locations_updated_at BEFORE UPDATE ON driver_locations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- POLÍTICAS RLS (Row Level Security)
-- =====================================================

-- Habilitar RLS en todas las tablas
ALTER TABLE zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE delivery_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_track ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Políticas para orders
CREATE POLICY "orders_select_policy" ON orders
    FOR SELECT USING (true);

CREATE POLICY "orders_insert_policy" ON orders
    FOR INSERT WITH CHECK (true);

CREATE POLICY "orders_update_policy" ON orders
    FOR UPDATE USING (true);

-- Políticas para driver_locations
CREATE POLICY "driver_locations_select_own" ON driver_locations
    FOR SELECT USING (auth.uid() = driver_id);

CREATE POLICY "driver_locations_insert_own" ON driver_locations
    FOR INSERT WITH CHECK (auth.uid() = driver_id);

CREATE POLICY "driver_locations_update_own" ON driver_locations
    FOR UPDATE USING (auth.uid() = driver_id);

-- Políticas para order_track
CREATE POLICY "order_track_select_policy" ON order_track
    FOR SELECT USING (
        driver_id = auth.uid() OR
        EXISTS (SELECT 1 FROM orders WHERE id = order_track.order_id AND branch_id IN (SELECT branch_id FROM profiles WHERE id = auth.uid()))
    );

CREATE POLICY "order_track_insert_policy" ON order_track
    FOR INSERT WITH CHECK (true);

CREATE POLICY "order_track_update_policy" ON order_track
    FOR UPDATE USING (true);

-- Políticas para profiles
CREATE POLICY "profiles_select_own" ON profiles
    FOR SELECT USING (id = auth.uid());

CREATE POLICY "profiles_update_own" ON profiles
    FOR UPDATE USING (id = auth.uid());

-- Políticas para zones (públicas para lectura)
CREATE POLICY "zones_select_policy" ON zones
    FOR SELECT USING (true);

-- =====================================================
-- SEED DATA - Zonas de ejemplo
-- =====================================================
INSERT INTO zones (name, description, center_latitude, center_longitude, radius_km) VALUES
('Centro', 'Zona centro de la ciudad', 6.195618, -75.575971, 5.0),
('Norte', 'Zona norte de la ciudad', 6.210000, -75.570000, 4.0),
('Sur', 'Zona sur de la ciudad', 6.180000, -75.580000, 4.0),
('Este', 'Zona este de la ciudad', 6.195000, -75.560000, 3.0),
('Oeste', 'Zona oeste de la ciudad', 6.196000, -75.590000, 3.5)
ON CONFLICT DO NOTHING;

-- =====================================================
-- CREACIÓN DE ÍNDICES PARA RENDIMIENTO
-- =====================================================

-- Índices para búsquedas geoespaciales
CREATE INDEX IF NOT EXISTS idx_orders_customer_location ON orders USING GIST(customer_location);
CREATE INDEX IF NOT EXISTS idx_orders_restaurant_location ON orders USING GIST(restaurant_location);
CREATE INDEX IF NOT EXISTS idx_orders_status_branch ON orders(status, branch_id);
CREATE INDEX IF NOT EXISTS idx_orders_zone_status ON orders(zone_id, status) WHERE status IN ('pending', 'ready_for_pickup');

-- Función para buscar pedidos cercanos
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
    estimated_earnings DOUBLE PRECISION,
    distance_km DOUBLE PRECISION,
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
        o.estimated_earnings,
        o.distance_km,
        o.status,
        o.created_at
    FROM orders o
    WHERE o.status IN ('pending', 'ready_for_pickup')
      AND ST_DWithin(
          o.restaurant_location::geography,
          ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography,
          p_radius_km * 1000
      )
    ORDER BY
        ST_Distance(
            o.restaurant_location::geography,
            ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography
        )
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- FUNCIONES RPC PARA ASIGNACIÓN DE ÓRDENES
-- =====================================================

-- Función para aceptar orden por código
CREATE OR REPLACE FUNCTION accept_order_by_code(
    p_order_id UUID,
    p_driver_id UUID,
    p_pickup_code TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_order RECORD;
    v_result JSONB;
BEGIN
    -- Verificar que la orden existe y está en estado pending
    SELECT * INTO v_order
    FROM orders
    WHERE id = p_order_id
      AND status IN ('pending', 'ready_for_pickup')
      AND (pickup_code = p_pickup_code OR p_pickup_code IS NULL);

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Orden no encontrada o código incorrecto'
        );
    END IF;

    -- Verificar que no tenga driver asignado
    IF v_order.driver_id IS NOT NULL THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Esta orden ya fue asignada a otro conductor'
        );
    END IF;

    -- Asignar driver a la orden
    UPDATE orders
    SET
        driver_id = p_driver_id,
        status = 'accepted',
        updated_at = NOW()
    WHERE id = p_order_id;

    -- Crear registro de tracking
    INSERT INTO order_track (order_id, driver_id, status, driver_name)
    SELECT
        p_order_id,
        p_driver_id,
        'accepted',
        p.full_name
    FROM profiles p
    WHERE p.id = p_driver_id;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Orden aceptada correctamente',
        'order_id', p_order_id
    );
END;
$$ LANGUAGE plpgsql;

-- Función para actualizar estado de orden
CREATE OR REPLACE FUNCTION update_order_status_by_driver(
    p_order_id UUID,
    p_driver_id UUID,
    p_new_status TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_order RECORD;
    v_result JSONB;
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
            'message', 'No puedes marcar como recogido sin haber llegado al restaurante'
        );
    END IF;

    IF p_new_status = 'delivered' AND v_order.status NOT IN ('picked_up', 'delivering') THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'No puedes entregar sin haber recogido el pedido'
        );
    END IF;

    -- Actualizar estado
    UPDATE orders
    SET
        status = p_new_status,
        updated_at = NOW()
    WHERE id = p_order_id;

    -- Actualizar tracking
    UPDATE order_track
    SET
        status = p_new_status,
        updated_at = NOW(),
        picked_up_at = CASE WHEN p_new_status = 'picked_up' THEN NOW() ELSE picked_up_at END,
        delivered_at = CASE WHEN p_new_status = 'delivered' THEN NOW() ELSE delivered_at END
    WHERE order_id = p_order_id AND driver_id = p_driver_id;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Estado actualizado correctamente',
        'order_id', p_order_id,
        'new_status', p_new_status
    );
END;
$$ LANGUAGE plpgsql;

-- Función para verificar código de entrega
CREATE OR REPLACE FUNCTION verify_delivery_code(
    p_order_id UUID,
    p_delivery_code TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_order RECORD;
BEGIN
    SELECT * INTO v_order
    FROM orders
    WHERE id = p_order_id
      AND delivery_code = p_delivery_code
      AND status IN ('picked_up', 'delivering');

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Código de entrega incorrecto o orden no lista'
        );
    END IF;

    -- Marcar orden como entregada
    UPDATE orders
    SET
        status = 'delivered',
        updated_at = NOW()
    WHERE id = p_order_id;

    -- Actualizar tracking
    UPDATE order_track
    SET
        status = 'delivered',
        delivered_at = NOW(),
        updated_at = NOW()
    WHERE order_id = p_order_id;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Entrega verificada correctamente',
        'order_id', p_order_id
    );
END;
$$ LANGUAGE plpgsql;

-- Función para obtener pedidos por zona
CREATE OR REPLACE FUNCTION get_orders_by_zone(
    p_zone_id UUID,
    p_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    id UUID,
    restaurant_name TEXT,
    restaurant_address TEXT,
    customer_name TEXT,
    customer_address TEXT,
    estimated_earnings DOUBLE PRECISION,
    distance_km DOUBLE PRECISION,
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
        o.estimated_earnings,
        o.distance_km,
        o.status,
        o.created_at
    FROM orders o
    WHERE o.zone_id = p_zone_id
      AND o.status IN ('pending', 'ready_for_pickup')
      AND o.driver_id IS NULL
    ORDER BY o.created_at DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- Función para asignar conductor a zona
CREATE OR REPLACE FUNCTION assign_driver_to_zone(
    p_driver_id UUID,
    p_zone_id UUID,
    p_is_primary BOOLEAN DEFAULT false
)
RETURNS JSONB AS $$
BEGIN
    -- Verificar que el driver existe
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = p_driver_id) THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Driver no encontrado'
        );
    END IF;

    -- Verificar que la zona existe
    IF NOT EXISTS (SELECT 1 FROM zones WHERE id = p_zone_id) THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Zona no encontrada'
        );
    END IF;

    -- Si es primary, desvincular otros primary
    IF p_is_primary THEN
        UPDATE driver_zones
        SET is_primary = false
        WHERE driver_id = p_driver_id;
    END IF;

    -- Insertar o actualizar relación
    INSERT INTO driver_zones (driver_id, zone_id, is_primary)
    VALUES (p_driver_id, p_zone_id, p_is_primary)
    ON CONFLICT (driver_id, zone_id)
    DO UPDATE SET is_primary = p_is_primary, updated_at = NOW();

    -- Actualizar zona en perfil
    UPDATE profiles
    SET zone_id = p_zone_id
    WHERE id = p_driver_id;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Driver asignado a zona correctamente'
    );
END;
$$ LANGUAGE plpgsql;

-- Función para actualizar ubicación del driver
CREATE OR REPLACE FUNCTION update_driver_location(
    p_driver_id UUID,
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_accuracy DOUBLE PRECISION DEFAULT NULL,
    p_speed DOUBLE PRECISION DEFAULT NULL,
    p_heading DOUBLE PRECISION DEFAULT NULL,
    p_is_online BOOLEAN DEFAULT true
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
            driver_id, latitude, longitude, accuracy, speed, heading, is_online
        ) VALUES (
            p_driver_id, p_latitude, p_longitude, p_accuracy, p_speed, p_heading, p_is_online
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

-- =====================================================
-- NOTIFICACIONES EN BASE DE DATOS
-- =====================================================

-- Función para notificar a la sucursal cuando se asigna driver
CREATE OR REPLACE FUNCTION notify_branch_on_driver_assignment()
RETURNS TRIGGER AS $$
BEGIN
    -- Aquí se dispara la notificación a la sucursal
    -- La implementación real dependerá del sistema de notificaciones
    PERFORM pg_notify(
        'driver_assigned',
        jsonb_build_object(
            'order_id', NEW.id,
            'driver_id', NEW.driver_id,
            'branch_id', NEW.branch_id,
            'event', 'driver_assigned'
        )::text
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_branch_assignment
AFTER UPDATE ON orders
FOR EACH ROW
WHEN (NEW.driver_id IS DISTINCT FROM OLD.driver_id AND NEW.driver_id IS NOT NULL)
EXECUTE FUNCTION notify_branch_on_driver_assignment();

-- Función para notificar cuando cambia el estado
CREATE OR REPLACE FUNCTION notify_order_status_change()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM pg_notify(
        'order_status_changed',
        jsonb_build_object(
            'order_id', NEW.id,
            'old_status', OLD.status,
            'new_status', NEW.status,
            'driver_id', NEW.driver_id,
            'event', 'status_changed'
        )::text
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_order_status
AFTER UPDATE ON orders
FOR EACH ROW
WHEN (NEW.status IS DISTINCT FROM OLD.status)
EXECUTE FUNCTION notify_order_status_change();

-- =====================================================
-- COMENTARIOS PARA DOCUMENTACIÓN
-- =====================================================
COMMENT ON TABLE zones IS 'Zonas de cobertura para los pedidos';
COMMENT ON TABLE delivery_codes IS 'Códigos de verificación para recogida y entrega';
COMMENT ON TABLE order_track IS 'Seguimiento detallado de cada pedido';
COMMENT ON TABLE driver_zones IS 'Relación entre conductores y zonas';
COMMENT ON TABLE driver_locations IS 'Ubicación en tiempo real de los conductores';
COMMENT ON FUNCTION get_nearby_orders IS 'Obtiene pedidos cercanos a una ubicación';
COMMENT ON FUNCTION accept_order_by_code IS 'Acepta una orden usando código de verificación';
COMMENT ON FUNCTION update_order_status_by_driver IS 'Actualiza el estado de una orden por el driver';
COMMENT ON FUNCTION verify_delivery_code IS 'Verifica el código de entrega';
COMMENT ON FUNCTION get_orders_by_zone IS 'Obtiene pedidos de una zona específica';
COMMENT ON FUNCTION assign_driver_to_zone AS 'Asigna un conductor a una zona';
COMMENT ON FUNCTION update_driver_location IS 'Actualiza la ubicación del conductor';
```

---

## 5. Edge Functions Necesarias

### 5.1 Edge Function: `assign-order-to-driver`

```typescript
// supabase/functions/assign-order-to-driver/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } })
  }

  try {
    const { order_id, driver_id, pickup_code } = await req.json()

    // Verificar código de recogida
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select('*')
      .eq('id', order_id)
      .in('status', ['pending', 'ready_for_pickup'])
      .single()

    if (orderError || !order) {
      return new Response(
        JSON.stringify({ success: false, message: 'Orden no encontrada o ya asignada' }),
        { headers: { 'Content-Type': 'application/json' }, status: 404 }
      )
    }

    if (order.pickup_code && order.pickup_code !== pickup_code) {
      return new Response(
        JSON.stringify({ success: false, message: 'Código incorrecto' }),
        { headers: { 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    // Asignar driver
    const { error: updateError } = await supabase
      .from('orders')
      .update({
        driver_id,
        status: 'accepted',
        updated_at: new Date().toISOString()
      })
      .eq('id', order_id)

    if (updateError) throw updateError

    // Crear tracking
    const { data: profile } = await supabase
      .from('profiles')
      .select('full_name, phone')
      .eq('id', driver_id)
      .single()

    await supabase.from('order_track').insert({
      order_id,
      driver_id,
      status: 'accepted',
      driver_name: profile?.full_name,
      driver_phone: profile?.phone
    })

    return new Response(
      JSON.stringify({ success: true, message: 'Orden asignada correctamente' }),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
```

### 5.2 Edge Function: `get-driver-orders`

```typescript
// supabase/functions/get-driver-orders/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } })
  }

  try {
    const { driver_id } = await req.json()

    const { data: orders, error } = await supabase
      .from('orders')
      .select('*')
      .eq('driver_id', driver_id)
      .in('status', ['accepted', 'arrived_at_restaurant', 'picking_up', 'picked_up', 'delivering'])
      .order('created_at', { ascending: false })

    if (error) throw error

    return new Response(
      JSON.stringify({ success: true, orders }),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
```

### 5.3 Edge Function: `update-order-status`

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

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { 'Access-Control-Allow-Origin': '*' } })
  }

  try {
    const { order_id, driver_id, new_status, delivery_code } = await req.json()

    // Validar estado
    if (!ALLOWED_STATUSES.includes(new_status)) {
      return new Response(
        JSON.stringify({ success: false, message: 'Estado no válido' }),
        { headers: { 'Content-Type': 'application/json' }, status: 400 }
      )
    }

    // Verificar ownership
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select('*')
      .eq('id', order_id)
      .eq('driver_id', driver_id)
      .single()

    if (orderError || !order) {
      return new Response(
        JSON.stringify({ success: false, message: 'Orden no encontrada o no te pertenece' }),
        { headers: { 'Content-Type': 'application/json' }, status: 404 }
      )
    }

    // Si es entrega, verificar código
    if (new_status === 'delivered' && delivery_code) {
      if (order.delivery_code !== delivery_code) {
        return new Response(
          JSON.stringify({ success: false, message: 'Código de entrega incorrecto' }),
          { headers: { 'Content-Type': 'application/json' }, status: 400 }
        )
      }
    }

    // Actualizar orden
    const { error: updateError } = await supabase
      .from('orders')
      .update({
        status: new_status,
        updated_at: new Date().toISOString()
      })
      .eq('id', order_id)

    if (updateError) throw updateError

    // Actualizar tracking
    const trackUpdate: any = {
      status: new_status,
      updated_at: new Date().toISOString()
    }

    if (new_status === 'picked_up') trackUpdate.picked_up_at = new Date().toISOString()
    if (new_status === 'delivered') trackUpdate.delivered_at = new Date().toISOString()

    await supabase
      .from('order_track')
      .update(trackUpdate)
      .eq('order_id', order_id)
      .eq('driver_id', driver_id)

    // Si se entrega, agregar ganancias
    if (new_status === 'delivered') {
      const { data: profile } = await supabase
        .from('profiles')
        .select('total_earnings')
        .eq('id', driver_id)
        .single()

      const newEarnings = (profile?.total_earnings || 0) + (order.estimated_earnings || 0)

      await supabase
        .from('profiles')
        .update({ total_earnings: newEarnings })
        .eq('id', driver_id)
    }

    return new Response(
      JSON.stringify({ success: true, message: 'Estado actualizado', new_status }),
      { headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { 'Content-Type': 'application/json' }, status: 500 }
    )
  }
})
```

---

## 6. Mejoras de Rendimiento

### 6.1 Optimizaciones Identificadas

1. **Stream de ubicación**
   - Actualmente actualiza cada 10 metros
   - Recomendación: Aumentar a 20-50 metros para reducir consumo de batería

2. **Consultas Realtime**
   - El stream actual escucha todas las órdenes pendientes
   - Implementar filtro por zona para reducir carga

3. **Caché local**
   - Implementar caché con SharedPreferences para datos de perfil
   - Guardar última ubicación conocida

4. **Optimización de map markers**
   - No recrear markers en cada frame
   - Usar marker clustering para múltiples pedidos

### 6.2 Código de Optimización - Location Service

```dart
// Optimización: Reducir frecuencia de actualizaciones
class OptimizedLocationService implements LocationService {
  static const int _distanceFilter = 30; // metros
  static const Duration _throttleDuration = Duration(seconds: 5);

  DateTime? _lastEmitTime;

  // ... resto de implementación con throttle
}
```

---

## 7. Mejoras UX/UI

### 7.1 Análisis de Pantallas Actuales

| Pantalla | Estado | Problemas Identificados |
|----------|--------|-------------------------|
| HomeScreen | ✅ Existente | UI básica, sin optimización responsive |
| ActiveOrderScreen | ✅ Existente | Información dispersa |
| AuthScreen | ✅ Existente | Diseño a mejorar |
| WalletScreen | ✅ Existente | Gráficos básicos |
| EarningPage | ✅ Existente | Sin detalles de rutas |

### 7.2 Propuestas de Mejora

#### A. Diseño Adaptativo (Responsive)

```dart
// Widget helper para diseño adaptativo
class AdaptiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget tabletLayout;
  final Widget desktopLayout;

  // Implementar usando MediaQuery y LayoutBuilder
}
```

#### B. Animaciones y Transiciones

- Implementar `Hero` animations para transiciones entre pantallas
- Agregar `AnimatedContainer` para cambios de estado
- Usar `AnimatedOpacity` para notificaciones

#### C. Sistema de Diseño

Crear widgets reutilizables:
- `DeliveryButton` - Botones personalizados
- `OrderCard` - Tarjetas de pedido
- `StatusBadge` - Badges de estado
- `EarningsWidget` - Widget de ganancias

### 7.3 Mockups de Componentes

```
┌─────────────────────────────────────────┐
│  🎯 Nuevo Pedido - Card Compact         │
├─────────────────────────────────────────┤
│  🍕 Restaurant Name           $5.50     │
│  📍 0.8 km • 8 min            🕐       │
│  👤 Cliente: Juan Pérez                  │
│  ┌─────────────────────────────────────┐│
│  │  [Aceptar]  [Rechazar]             ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

```
┌─────────────────────────────────────────┐
│  🚴 Estado: ONLINE          💰 $45.50   │
│  ─────────────────────────────────────  │
│  ┌─────────────────────────────────────┐│
│  │         🗺️ Google Maps             ││
│  │                                     ││
│  │    📍 Restaurante                   ││
│  │         ↓                           ││
│  │    📍 Cliente                       ││
│  │    🚗 (Tu ubicación)                ││
│  └─────────────────────────────────────┘│
│  ─────────────────────────────────────  │
│  Estado: Picking Up                     │
│  [📞 Llamar] [💬 WhatsApp] [✓ Items]   │
└─────────────────────────────────────────┘
```

---

## 8. Sistema de Geolocalización

### 8.1 Flujo de Geolocalización

```
┌─────────────────────────────────────────────────────────┐
│                    FLUJO COMPLETO                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. Driver entra a la app                               │
│     ↓                                                   │
│  2. Solicitar permisos de ubicación                    │
│     ↓                                                   │
│  3. Obtener ubicación actual                           │
│     ↓                                                   │
│  4. Driver hace "GO ONLINE"                            │
│     ↓                                                   │
│  5. Asignar a zonas cercanas                           │
│     ↓                                                   │
│  6. Guardar ubicación en BDD (driver_locations)        │
│     ↓                                                   │
│  7. Escuchar pedidos de su(s) zona(s)                   │
│     ↓                                                   │
│  8. Cuando hay pedido → Notificar al driver             │
│     ↓                                                   │
│  9. Driver acepta → Asignar orden                       │
│     ↓                                                   │
│ 10. Actualizar track (driver asignado)                 │
│     ↓                                                   │
│ 11. Notificar a sucursal (web)                          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 8.2 Lógica de Matching por Zona

```dart
class ZoneMatchingService {
  /// Obtiene pedidos cercanos basados en la ubicación del driver
  Future<List<Order>> getNearbyOrders({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    int limit = 20,
  }) async {
    // Llamar a RPC get_nearby_orders
    final response = await supabase.rpc('get_nearby_orders', params: {
      'p_latitude': latitude,
      'p_longitude': longitude,
      'p_radius_km': radiusKm,
      'p_limit': limit,
    });
    return response.map((json) => Order.fromJson(json)).toList();
  }

  /// Asigna el driver a la mejor zona
  Future<void> assignToOptimalZone(String driverId) async {
    // Obtener ubicación actual
    final location = await locationService.getCurrentLocation();

    // Buscar zona más cercana
    final zones = await getActiveZones();
    Zone? nearestZone;
    double minDistance = double.infinity;

    for (final zone in zones) {
      final distance = Geolocator.distanceBetween(
        location.latitude,
        location.longitude,
        zone.centerLatitude,
        zone.centerLongitude,
      );

      if (distance < minDistance && distance <= zone.radiusKm * 1000) {
        minDistance = distance;
        nearestZone = zone;
      }
    }

    if (nearestZone != null) {
      await supabase.rpc('assign_driver_to_zone', params: {
        'p_driver_id': driverId,
        'p_zone_id': nearestZone.id,
        'p_is_primary': true,
      });
    }
  }
}
```

### 8.3 Actualización de Ubicación en Tiempo Real

```dart
class LocationTracker {
  Timer? _periodicUpdateTimer;
  static const Duration _updateInterval = Duration(seconds: 30);

  void startTracking(String driverId) {
    // Actualizar cada 30 segundos
    _periodicUpdateTimer = Timer.periodic(_updateInterval, (_) async {
      final location = await _locationService.getCurrentLocation();
      await _updateLocationInDb(driverId, location);
    });
  }

  void stopTracking() {
    _periodicUpdateTimer?.cancel();
  }
}
```

---

## 9. Plan de Implementación

### 9.1 Fase 1: Base de Datos (Semana 1)

- [ ] Ejecutar migración de SQL
- [ ] Crear Edge Functions
- [ ] Configurar RLS policies
- [ ] Probar RPC functions

### 9.2 Fase 2: Backend Flutter (Semana 2)

- [ ] Actualizar modelos de datos
- [ ] Implementar ZoneMatchingService
- [ ] Actualizar LocationService
- [ ] Crear OrderRepository

### 9.3 Fase 3: UI/UX (Semana 3)

- [ ] Implementar diseño responsive
- [ ] Crear componentes reutilizables
- [ ] Mejorar animaciones
- [ ] Optimizar mapas

### 9.4 Fase 4: Testing y Optimización (Semana 4)

- [ ] Pruebas de carga
- [ ] Optimización de rendimiento
- [ ] Testing de geolocalización
- [ ] Documentación final

---

## 10. Checklist de Migración

### 10.1 Pre-Migración

- [ ] Hacer backup de la base de datos actual
- [ ] Documentar tablas existentes
- [ ] Notificar a usuarios de mantenimiento

### 10.2 Migración

- [ ] Ejecutar script SQL completo
- [ ] Verificar creación de tablas
- [ ] Verificar índices
- [ ] Probar funciones RPC
- [ ] Desplegar Edge Functions

### 10.3 Post-Migración

- [ ] Verificar integridad de datos
- [ ] Probar flujos de autenticación
- [ ] Probar creación de pedidos
- [ ] Probar asignación de drivers
- [ ] Monitorear errores

---

## 11. Notas Adicionales

### 11.1 Configuración de Permisos Android

Agregar en `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.INTERNET" />
```

### 11.2 Configuración de Permisos iOS

Agregar en `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>我们需要您的位置来 encontrar pedidos cercanos</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>我们需要您的位置 para notificaciones en segundo plano</string>
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>fetch</string>
</array>
```

---

## 12. Contacto y Soporte

Para dudas sobre esta migración, contactar al equipo de desarrollo.

---

**Documento generado automáticamente**
*Análisis de App Delivery Recompry - Versión 1.0*
