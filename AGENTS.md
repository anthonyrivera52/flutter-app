# AGENTS.md — InnotechLab Tienda Flutter Monorepo

## Monorepo structure

```
flutter-app/
├── innotechlab_tienda_app_client/   ← Main consumer app (ACTIVE — focus here)
├── innotechlab_tienda_app_admin/    ← Admin panel (legacy, uses older supabase_flutter)
├── innotechlab_tienda_app_delivery/ ← Delivery driver app (legacy)
├── innotechlab_tienda_app_test/     ← Test/prototype app
└── supabase/                        ← Edge Functions + migrations (Deno/TypeScript)
```

Each Flutter app is **independent** — no shared packages, no melos, no workspace-level pubspec. They share a git repo but are developed separately.

## Commands

### Client app (primary)

```bash
cd innotechlab_tienda_app_client

flutter pub get                    # Install deps
flutter run                        # Run on connected device/emulator
flutter run -d chrome              # Run on web
flutter analyze                    # Static analysis (uses flutter_lints)
flutter test                       # Run tests (currently only default template test)
flutter build apk --release        # Android release
flutter build ios --release        # iOS release
flutter gen-l10n                   # Regenerate localization files (auto-runs on build)
flutter pub run flutter_launcher_icons  # Regenerate app icons
```

### Supabase Edge Functions

```bash
cd supabase
supabase login
supabase link --project-ref <project-ref>
supabase functions deploy <function-name>    # Deploy single function
supabase functions serve <function-name>     # Local dev with Deno
```

### Code generation

- **Localization**: ARB-based, template is `app_es.arb` (Spanish). Run `flutter gen-l10n` or it auto-runs on build. Output goes to `lib/l10n/`.
- **Icons**: Configured in `pubspec.yaml` under `flutter_launcher_icons`. Source: `assets/icons/icon-512x512.png`.
- **No build_runner, no freezed, no json_serializable** — all models use manual `fromJson`/`toJson`.

## Environment

- `.env.development` and `.env.production` at project root, loaded via `flutter_dotenv`
- Loaded in `main.dart` with fallback: tries `.env.development` first, then `.env.production`
- Both `.env` files are **committed to git** and listed as Flutter assets — handle with caution
- `AppConstants` reads from dotenv: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `OTP_METHOD`, `BOLD_*_KEY`
- Dart SDK `^3.8.0`, Flutter Riverpod `^2.5.1`, Supabase Flutter `^2.9.0`

## Architecture — current state (hybrid)

The codebase is **mid-migration** from a flat architecture to Clean Architecture + feature-based organization. Only the `orders` feature follows full clean architecture. Other features have the directory structure but call Supabase directly from viewmodels.

### Directory layout inside `lib/`

```
lib/
├── main.dart                    # Entry point — Supabase init, dotenv, ProviderScope
├── exports.dart                 # Barrel file for cross-cutting exports
├── config/                      # App-wide config (constants, router)
├── core/                        # Shared services (location, security, payments, errors, theme)
├── features/                    # Feature modules (auth, cart, orders, payments, products, profile)
├── shared/                      # Underused — contains duplicates, map widgets, a Category model
├── presentation/                # Legacy pages + providers + reusable widgets
└── l10n/                        # Localization ARB files + generated output
```

### Clean Architecture target (orders feature is the reference)

```
feature/
├── data/
│   ├── datasources/     # Abstract + Impl — Supabase client calls
│   ├── models/          # DTOs with fromJson/toEntity
│   └── repositories/    # RepositoryImpl with dartz Either<Failure, T>
├── domain/
│   ├── models/          # Entities (Equatable)
│   ├── repositories/    # Abstract repository interfaces
│   └── usecases/        # UseCase<T, P> returning Future<Either<Failure, T>>
└── presentation/
    ├── viewmodels/      # StateNotifier / StateNotifierProvider
    └── views/           # Pages
```

### What to follow when adding/modifying features

1. **Use the orders feature as the pattern** — DataSource → Repository → UseCase → ViewModel
2. **Entities** in domain layer use `Equatable` for value equality
3. **Models** extend entities, add `fromJson`/`toEntity` — no codegen
4. **UseCases** extend `UseCase<T, Params>` from `core/usecases/usecase.dart`
5. **Repositories** return `Future<Either<Failure, T>>` using dartz
6. **ViewModels** are `StateNotifier`-based, consume use cases via providers
7. **Barrel files** — each feature has one (e.g., `orders.dart`) that exports its public API

## State management

- **Riverpod v2** exclusively — no Provider, no BLoC, no GetX
- Primary pattern: `StateNotifierProvider` + `StateNotifier`
- Simple state: `StateProvider`
- Computed/derived: `Provider`
- Parameterized: `.family` modifier
- Ephemeral: `.autoDispose` modifier
- **Legacy providers** exist in `presentation/provider/` — new code should live in feature viewmodels

### Known duplication issues

- `AppConstants` exists in both `config/constants/` and `shared/core/constants/` — prefer `config/constants/`
- `ConnectivityProvider` exists in both `presentation/provider/` and `shared/data/services/` — prefer `presentation/provider/`
- `Category` model exists in both `features/products/domain/` and `shared/domain/` — prefer the feature one

## Supabase integration patterns

### How the app consumes Supabase

| Pattern | Where used | Approach |
|---------|-----------|----------|
| **Edge Functions** | orders, products (catalog), shop status, payments | `_supabase.functions.invoke('function-name', body: {...})` |
| **PostgREST (direct queries)** | products, app_config, error logging | `_supabase.from('table').select()...` |
| **RPC** | nearby shops, location hours | `_supabase.rpc('function_name', params: {...})` |
| **Auth** | sign in, sign up, OTP, profile update | `Supabase.instance.client.auth.*` |
| **Storage** | avatar upload | `Supabase.instance.client.storage.from('avatars').uploadBinary(...)` |
| **Realtime** | driver tracking | `supabase.channel('driver:$id').onBroadcast(...)` |

### Supabase best practices for this project

- **Always use Edge Functions for write operations** (create-order, create-payment-intent) — never write directly from client via PostgREST for business logic
- **Use RLS policies** on all tables — client reads via PostgREST should be RLS-protected
- **Prefer Edge Functions over RPC** for complex queries (joins, business logic, geospatial)
- **Use `.select()` with column filtering** — never `select('*')` in production code
- **Use `.eq()`, `.gte()`, `.lte()`** for server-side filtering — avoid fetching all rows
- **Use `.order()` with `.limit()`** for pagination
- **Use `.maybeSingle()`** when expecting one result — avoids exceptions on empty results
- **Realtime channels**: always `unsubscribe` in `dispose`/`close` to prevent memory leaks
- **Edge Function errors**: always check `response.status` before parsing body
- **Secure storage**: `SecureLocalStorage` wraps `FlutterSecureStorage` for auth tokens — do not use `SharedPreferences` for sensitive data

### Real DB schema (verified against production — `supabase/README.md` is STALE)

The `supabase/README.md` documents a `shops` schema that **does not exist**. The real tables are:

| Table | Role | Key columns |
|-------|------|-------------|
| `organizations` | Multi-tenant root | `id` (uuid PK), 30 columns |
| `locations` | Physical shops (NOT `shops`) | `id`, `organization_id` (FK→organizations), `name`, `latitude`, `longitude`, `is_active`, 26 cols |
| `products` | Products | `id`, `organization_id` (FK→organizations), `name`, `price`, `image_url`, `is_available`, `measurement_unit`, 53 cols |
| `product_categories` | Categories (NOT `categories`) | `id`, `organization_id`, `name`, `slug`, `parent_id`, `image_url`, `is_active`, `position`, 14 cols |
| `product_category_products` | Junction: product↔category | `product_id` (FK→products), `category_id` (FK→product_categories) |

**Columns that DO NOT exist** (don't reference them):
- `products.category_id` — use junction table `product_category_products`
- `products.unit` — use `products.measurement_unit`
- `products.discounted_price` — compute from promotions/discounts tables
- `shops` table — it's `locations`
- `categories` table — it's `product_categories`

**RLS**: `products` and `product_categories` have public read policies (`qual: true`). The junction table `product_category_products` only allows `authenticated` role via `is_member_of_org()`.

### Edge Functions (TypeScript/Deno)

Located in `supabase/functions/`:
- `get-nearby-shops` — geospatial shop search
- `get-catalog` — product catalog per shop
- `create-order` — order creation + order_code generation
- `create-payment-intent` — Bold payment hash
- `payment-webhook` — Bold webhook handler
- `track-order` — order status tracking
- `get-user-orders` — user order history
- `bold-generate-hash` — Bold payment hash generation
- Shared utilities: `_shared/supabase.ts`, `_shared/cors.ts`

## Routing

- **go_router** via `Provider<GoRouter>` in `config/router/app_router.dart`
- No auth guards in router — splash screen handles auth/onboarding routing logic
- Data passed between routes via `state.extra` (not typed)
- Dashboard uses `BottomNavigationBar` with `MotionTabBar`

## Localization

- Template language: **Spanish** (`app_es.arb`)
- English: `app_en.arb`
- Access via `AppLocalizations.of(context)!`
- `intl` package used for currency formatting

## Payments

- **Bold** (Colombian payment gateway) — WebView-based checkout
- Payment hash generated server-side via Edge Function
- `BoldPaymentService` in `core/services/payments/`
- Test keys in `.env.development`, production keys in `.env.production`

## Maps

- **OpenStreetMap** via `flutter_map` (NOT Google Maps)
- Tile caching via `flutter_map_tile_caching`
- Marker clustering via `flutter_map_marker_cluster`
- Geocoding via `geocoding` package
- Location service with Haversine distance calculation in `core/location/`

## Multi-country support

- 9 South American countries configured in `core/services/region_config_service.dart`
- Country-specific: currency symbol, IVA rate, commerce fees
- Region loaded from Supabase `app_country_config` table via `AppConfigProvider`

## Performance notes

- **Cart is in-memory only** — no persistence across restarts (TODO in codebase)
- **Favorites are in-memory only** — no persistence (TODO in codebase)
- **Shops polling** runs every 30s via `shops_polling_provider.dart`
- **Shop status polling** runs every 30s via `shop_status_provider.dart`
- **Shimmer skeleton loaders** used for loading states (`shimmer` package)
- **Cached network images** via `cached_network_image` package
- **Connectivity monitoring** via `connectivity_plus`

## Testing

- **No meaningful tests exist** — only the default Flutter template `widget_test.dart`
- When adding tests, use `flutter_test` (already in dev_dependencies)
- No test framework, no mocks, no fixtures configured
- Edge functions have no tests — test locally with `supabase functions serve`

## Design system

- **Material 3** theme in `core/theme/app_theme.dart`
- Color palette in `core/utils/app_colors.dart`
- Reusable widgets in `presentation/widget/common/` (buttons, text fields, skeletons, maps, error displays, responsive widgets, debounced search)
- Feature-specific widgets alongside their views

## Key files to read first

| File | Why |
|------|-----|
| `lib/main.dart` | App init sequence, Supabase setup, dotenv loading |
| `lib/config/router/app_router.dart` | All routes and navigation |
| `lib/config/constants/app_constants.dart` | Supabase config, environment vars |
| `lib/core/usecases/usecase.dart` | Base UseCase class pattern |
| `lib/features/orders/` | Reference for clean architecture implementation |
| `lib/core/services/app_config_provider.dart` | Multi-country config loading from Supabase |
| `supabase/README.md` | Edge Functions, DB schema, deployment |

## Common pitfalls

1. **Do not use `Supabase.instance.client` directly in viewmodels** — follow the orders feature pattern with DataSource/Repository/UseCase
2. **Do not add new code to `presentation/provider/`** — use feature-level viewmodels
3. **Do not add new code to `shared/`** — it contains legacy duplicates, prefer `core/` or feature modules
4. **Do not use `SharedPreferences` for tokens** — use `FlutterSecureStorage` via `SecureLocalStorage`
5. **Do not forget to unsubscribe from Realtime channels** — causes memory leaks
6. **The `.env` files contain real API keys** — do not expose in logs or error messages
7. **All three apps share the same Supabase project** — schema changes affect all apps
8. **The admin and delivery apps use older `supabase_flutter: ^1.10.25`** — client uses `^2.9.0` (breaking API differences)
