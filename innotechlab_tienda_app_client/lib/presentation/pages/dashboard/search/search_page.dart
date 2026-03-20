import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/features/products/domain/models/shop_entity.dart';
import 'package:flutter_app/features/products/presentation/viewmodels/home_viewmodel.dart';
import 'package:flutter_app/presentation/provider/shops_polling_provider.dart';
import 'package:flutter_app/presentation/provider/dashboard_provider.dart';
import 'package:flutter_app/presentation/provider/favorites_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pollingState = ref.watch(shopsPollingProvider);
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

    final filteredShops = pollingState.shops.where((shopDistance) {
      if (searchQuery.isEmpty) return true;
      final shop = shopDistance.shop;
      final name = (shop.organizationName ?? shop.name).toLowerCase();
      final address = shop.address.toLowerCase();
      return name.contains(searchQuery) || address.contains(searchQuery);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.grey.shade50],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(pollingState),
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: filteredShops.isEmpty
                    ? _buildEmptyState(searchQuery.isNotEmpty)
                    : _buildShopsList(filteredShops, pollingState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ShopsPollingState pollingState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Descubre',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor.withOpacity(0.7),
                  letterSpacing: 1.2,
                ),
              ),
              const Text(
                'Comercios',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (pollingState.lastUpdate != null)
            _LastUpdateBadge(lastUpdate: pollingState.lastUpdate!),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final searchQuery = ref.watch(searchQueryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Busca por nombre o dirección...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.primaryColor, size: 22),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool hasSearch) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasSearch ? Icons.search_off_rounded : Icons.store_rounded,
                size: 64,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              hasSearch ? 'Sin resultados' : 'No hay comercios cercanos',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              hasSearch
                  ? 'No pudimos encontrar lo que buscas. Prueba con otros términos.'
                  : 'Parece que no hay tiendas en tu área en este momento.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopsList(List<ShopDistance> shops, ShopsPollingState pollingState) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: shops.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final shopDistance = shops[index];
        return _ShopCard(
          shop: shopDistance.shop,
          distanceKm: shopDistance.distanceKm,
          onTap: () {
            ref.read(homeProvider.notifier).selectShop(shopDistance.shop);
            ref.read(dashboardTabIndexProvider.notifier).state = 0;
          },
        );
      },
    );
  }
}

class _LastUpdateBadge extends StatelessWidget {
  final DateTime lastUpdate;
  const _LastUpdateBadge({required this.lastUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.sync, size: 14, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Text(
            '${lastUpdate.hour}:${lastUpdate.minute.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  final Shop shop;
  final double distanceKm;
  final VoidCallback onTap;

  const _ShopCard({required this.shop, required this.distanceKm, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: shop.isOpen ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Hero Section (Logo + Basic Info)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade100, Colors.grey.shade50],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: shop.logoUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: shop.logoUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                errorWidget: (_, __, ___) => Icon(Icons.storefront_rounded, color: Colors.grey.shade400, size: 30),
                              )
                            : Icon(Icons.storefront_rounded, color: Colors.grey.shade400, size: 30),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (shop.organizationName != null)
                            Text(
                              shop.organizationName!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          Text(
                            shop.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildStatusBadge(),
                              const SizedBox(width: 8),
                              Icon(Icons.location_on, size: 14, color: Colors.grey.shade400),
                              const SizedBox(width: 2),
                              Text(
                                '${distanceKm.toStringAsFixed(1)} km',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _FavoriteButton(shopId: shop.id),
                  ],
                ),
              ),
              // Footer Section (Address + Action)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.directions_rounded, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              shop.address,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: shop.isOpen ? AppColors.primaryColor : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: shop.isOpen
                            ? [BoxShadow(color: AppColors.primaryColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))]
                            : null,
                      ),
                      child: Text(
                        shop.isOpen ? 'Ver menú' : 'Cerrado',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: shop.isOpen ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color textColor;
    String text;
    IconData icon;

    if (shop.deliveryStatus == ShopDeliveryStatus.waiting) {
      textColor = Colors.amber.shade700;
      text = 'Demora';
      icon = Icons.access_time_filled_rounded;
    } else if (shop.isOpen) {
      textColor = Colors.green.shade600;
      text = 'Abierto';
      icon = Icons.check_circle_rounded;
    } else {
      textColor = Colors.grey.shade500;
      text = 'Cerrado';
      icon = Icons.remove_circle_rounded;
    }

    return Row(
      children: [
        Icon(icon, size: 14, color: textColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
        ),
      ],
    );
  }
}

class _FavoriteButton extends ConsumerWidget {
  final String shopId;
  const _FavoriteButton({required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteShopIdsProvider);
    final isFavorite = favorites.contains(shopId);

    return Container(
      decoration: BoxDecoration(
        color: isFavorite ? Colors.red.shade50 : Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: () => ref.read(favoriteShopIdsProvider.notifier).toggleFavorite(shopId),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(isFavorite),
            color: isFavorite ? Colors.red : Colors.grey.shade400,
            size: 22,
          ),
        ),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(),
      ),
    );
  }
}
