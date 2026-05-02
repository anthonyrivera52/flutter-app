---
inclusion: always
---

# Arquitectura del Proyecto — Innotech Tienda

## Estructura Feature-First

```
lib/
├── features/
│   ├── auth/          → Login, signup, OTP
│   ├── cart/          → Carrito en memoria
│   ├── orders/        → Pedidos, checkout, detalles
│   ├── products/      → Catálogo, home, tiendas cercanas
│   └── profile/       → Perfil de usuario
├── shared/
│   ├── core/constants/  → AppConstants (dotenv)
│   └── data/services/   → ConnectivityService
├── core/              → Errores, location, security, theme, usecases
├── config/            → Router (GoRouter), constants legacy
└── presentation/      → Páginas compartidas (dashboard, cart, checkout)
```

## Reglas de Arquitectura

- Cada feature es **autocontenida**: data → domain → presentation
- Los providers viven **dentro de su feature** (no en presentation/provider/)
- `lib/shared/` para código usado por 2+ features
- `lib/core/` para infraestructura transversal (no negocio)
- **No importar** entre features directamente — usar shared/ o core/

## State Management

- Riverpod `StateNotifierProvider` para estado complejo
- `Provider` para dependencias simples
- `autoDispose` en providers de pantallas específicas (orderDetails)

## Supabase

- Todas las operaciones de negocio van por **Edge Functions**
- Paginación **cursor-based** (no OFFSET) — ver `features/orders/`
- RLS policies usan `(select auth.uid())` — no `auth.uid()` directo

## Convenciones de Nombres

- Archivos: `snake_case.dart`
- Clases: `PascalCase`
- Providers: `featureNameProvider` (ej: `cartProvider`, `homeProvider`)
- ViewModels: `FeatureNameNotifier` + `FeatureNameState`
