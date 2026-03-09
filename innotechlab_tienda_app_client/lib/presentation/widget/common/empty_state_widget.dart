import 'package:flutter/material.dart';

/// Empty state widget for when there's no data to display
/// Provides consistent UX across the app
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  /// Factory for empty products state
  factory EmptyStateWidget.products({VoidCallback? onRefresh}) {
    return EmptyStateWidget(
      icon: Icons.inventory_2_outlined,
      title: 'No hay productos disponibles',
      subtitle: 'Intenta seleccionar otro comercio o categoría',
      actionLabel: onRefresh != null ? 'Recargar' : null,
      onAction: onRefresh,
    );
  }

  /// Factory for empty cart state
  factory EmptyStateWidget.cart({VoidCallback? onBrowse}) {
    return EmptyStateWidget(
      icon: Icons.shopping_cart_outlined,
      title: 'Tu carrito está vacío',
      subtitle: 'Agrega productos para comenzar',
      actionLabel: onBrowse != null ? 'Explorar productos' : null,
      onAction: onBrowse,
    );
  }

  /// Factory for empty orders state
  factory EmptyStateWidget.orders({VoidCallback? onBrowse}) {
    return EmptyStateWidget(
      icon: Icons.receipt_long_outlined,
      title: 'No tienes pedidos',
      subtitle: 'Tu historial de pedidos aparecerá aquí',
      actionLabel: onBrowse != null ? 'Hacer un pedido' : null,
      onAction: onBrowse,
    );
  }

  /// Factory for empty search results
  factory EmptyStateWidget.searchResults({VoidCallback? onClear}) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'Sin resultados',
      subtitle: 'No encontramos productos que coincidan con tu búsqueda',
      actionLabel: onClear != null ? 'Limpiar búsqueda' : null,
      onAction: onClear,
    );
  }

  /// Factory for no nearby shops
  factory EmptyStateWidget.noNearbyShops({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.location_off,
      title: 'No hay comercios cercanos',
      subtitle: 'Intenta cambiar tu ubicación o verificar tu conexión',
      actionLabel: onRetry != null ? 'Reintentar' : null,
      onAction: onRetry,
    );
  }

  /// Factory for offline state
  factory EmptyStateWidget.offline({VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.wifi_off,
      title: 'Sin conexión',
      subtitle: 'Verifica tu conexión a internet',
      actionLabel: onRetry != null ? 'Reintentar' : null,
      onAction: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading state widget with shimmer effect
class LoadingStateWidget extends StatelessWidget {
  final String? message;

  const LoadingStateWidget({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error state widget with retry option
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Algo salió mal',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
