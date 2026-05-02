-- Tabla para registrar errores de la aplicación
-- Esta tabla permite hacer seguimiento de errores por usuario, módulo y acción

CREATE TABLE IF NOT EXISTS app_errors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    module TEXT NOT NULL,
    action TEXT NOT NULL,
    error_message TEXT NOT NULL,
    stack_trace TEXT,
    timestamp_utc TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    additional_data TEXT
);

-- Índice para búsquedas rápidas por usuario
CREATE INDEX IF NOT EXISTS idx_app_errors_user_id ON app_errors(user_id);

-- Índice para búsquedas por módulo
CREATE INDEX IF NOT EXISTS idx_app_errors_module ON app_errors(module);

-- Índice para búsquedas por fecha
CREATE INDEX IF NOT EXISTS idx_app_errors_timestamp ON app_errors(timestamp_utc DESC);

-- Habilitar RLS (Row Level Security)
ALTER TABLE app_errors ENABLE ROW LEVEL SECURITY;

-- Política: usuarios pueden ver sus propios errores
CREATE POLICY "Users can view own errors" ON app_errors
    FOR SELECT
    USING (auth.uid()::text = user_id OR auth.jwt() ->> 'role' = 'admin');

-- Política: cualquier usuario puede insertar errores (para capturar crashes)
CREATE POLICY "Anyone can insert errors" ON app_errors
    FOR INSERT
    WITH CHECK (true);

-- Política: solo admins pueden eliminar errores
CREATE POLICY "Admins can delete errors" ON app_errors
    FOR DELETE
    USING (auth.jwt() ->> 'role' = 'admin');

-- Comentario para la tabla
COMMENT ON TABLE app_errors IS 'Tabla para registrar errores de la aplicación Flutter. Almacena usuario, módulo, acción, mensaje, stack trace y timestamp UTC.';
