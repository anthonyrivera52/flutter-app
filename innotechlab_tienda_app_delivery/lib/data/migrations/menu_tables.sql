-- lib/data/migrations/menu_tables.sql

-- ============================================
-- TABLA: menu_items
-- ============================================
-- Tabla para almacenar los items del menú (puede ser dinámica)

CREATE TABLE IF NOT EXISTS menu_items (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    subtitle TEXT,
    icon TEXT NOT NULL,
    route TEXT NOT NULL,
    section TEXT NOT NULL,
    "order" INTEGER DEFAULT 0,
    is_visible BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insertar menú por defecto
INSERT INTO menu_items (id, title, subtitle, icon, route, section, "order", is_visible) VALUES
-- Principal
('home', 'Inicio', 'Pantalla principal', 'home', '/home', 'principal', 1, true),
('orders', 'Pedidos', 'Historial de pedidos', 'receipt', '/orders', 'principal', 2, true),

-- Finanzas
('wallet', 'Billetera', 'Gestiona tu dinero', 'wallet', '/wallet', 'finanzas', 1, true),
('earnings', 'Ganancias', 'Ver tus ganancias', 'trending_up', '/earnings', 'finanzas', 2, true),

-- Ajustes
('settings', 'Configuración', 'Ajustes de la app', 'settings', '/settings', 'ajustes', 1, true),
('help', 'Ayuda y Feedback', 'Contáctanos', 'help', '/help', 'ajustes', 2, true),

-- Aprende
('courses', 'Cursos', 'Mejora tus habilidades', 'school', '/courses', 'aprende', 1, true)
ON CONFLICT (id) DO NOTHING;

-- Habilitar RLS
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;

-- Política: cualquier usuario puede leer
CREATE POLICY "menu_items_public_read" ON menu_items
    FOR SELECT USING (true);


-- ============================================
-- TABLA: user_preferences
-- ============================================
-- Preferencias del usuario

CREATE TABLE IF NOT EXISTS user_preferences (
    user_id TEXT PRIMARY KEY,
    default_tab INTEGER DEFAULT 0,
    notifications_enabled BOOLEAN DEFAULT true,
    language TEXT DEFAULT 'es',
    dark_mode BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Política: usuarios solo pueden ver/editar sus propias preferencias
CREATE POLICY "user_preferences_owner" ON user_preferences
    FOR ALL USING (auth.uid()::text = user_id);

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para auto-actualizar updated_at
CREATE TRIGGER update_user_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();


-- ============================================
-- TABLA: user_stats
-- ============================================
-- Estadísticas del usuario (cacheadas)

CREATE TABLE IF NOT EXISTS user_stats (
    user_id TEXT PRIMARY KEY,
    total_orders INTEGER DEFAULT 0,
    total_earnings NUMERIC(10, 2) DEFAULT 0,
    rating NUMERIC(3, 2) DEFAULT 5.0,
    orders_today INTEGER DEFAULT 0,
    earnings_today NUMERIC(10, 2) DEFAULT 0,
    last_order_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE user_stats ENABLE ROW LEVEL SECURITY;

-- Política
CREATE POLICY "user_stats_owner" ON user_stats
    FOR ALL USING (auth.uid()::text = user_id);

-- Trigger para auto-actualizar updated_at
CREATE TRIGGER update_user_stats_updated_at
    BEFORE UPDATE ON user_stats
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
