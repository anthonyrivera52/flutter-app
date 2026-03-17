import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/utils/app_colors.dart';
import 'package:flutter_app/features/products/domain/models/shop_entity.dart';
import 'package:flutter_app/features/products/presentation/viewmodels/home_viewmodel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final homeState = ref.watch(homeProvider);
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

    final filteredShops = homeState.nearbyShops.where((shopDistance) {
      if (searchQuery.isEmpty) return true;
      final shop = shopDistance.shop;
      final name = (shop.organizationName ?? shop.name).toLowerCase();
      final address = shop.address.toLowerCase();
      return name.contains(searchQuery) || address.contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(homeState),
            _buildSearchBar(),
            Expanded(
              child: filteredShops.isEmpty
                  ? _buildEmptyState(searchQuery.isNotEmpty)
                  : _buildShopsList(filteredShops, homeState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(HomeState homeState) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text(
            'Comercios',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (homeState.locationMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _formatLocation(homeState.locationMessage ?? ''),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatLocation(String message) {
    if (message.contains(',')) {
      final parts = message.split(',');
      return parts.first.trim();
    }
    return message.length > 20 ? '${message.substring(0, 20)}...' : message;
  }

  Widget _buildSearchBar() {
    final searchQuery = ref.watch(searchQueryProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o dirección...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade500),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool hasSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch ? Icons.search_off : Icons.store_mall_directory,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch
                ? 'No se encontraron comercios'
                : 'No hay comercios cercanos',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          if (hasSearch)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Intenta con otro nombre o dirección',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShopsList(List<ShopDistance> shops, HomeState homeState) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: shops.length,
      itemBuilder: (context, index) {
        final shopDistance = shops[index];
        final shop = shopDistance.shop;
        return _ShopCard(
          shop: shop,
          distanceKm: shopDistance.distanceKm,
          onTap: () {
            ref.read(homeProvider.notifier).selectShop(shop);
            context.go('/');
          },
        );
      },
    );
  }
}

class _ShopCard extends StatelessWidget {
  final Shop shop;
  final double distanceKm;
  final VoidCallback onTap;

  const _ShopCard({
    required this.shop,
    required this.distanceKm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: shop.isOpen ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: shop.logoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: shop.logoUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) =>
                            Icon(Icons.store, color: Colors.grey.shade400),
                      )
                    : Icon(Icons.store, color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (shop.organizationName != null)
                        Text(
                          '${shop.organizationName} • ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          shop.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatusBadge(),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${distanceKm.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    shop.address,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: shop.isOpen
                    ? AppColors.primaryColor
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                shop.isOpen ? 'Ver menú' : 'Cerrado',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: shop.isOpen ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String text;
    IconData icon;

    if (shop.deliveryStatus == ShopDeliveryStatus.waiting) {
      bgColor = Colors.amber.shade100;
      textColor = Colors.amber.shade800;
      text = 'Alta demanda';
      icon = Icons.warning_amber_rounded;
    } else if (shop.isOpen) {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
      text = 'Abierto';
      icon = Icons.check_circle;
    } else {
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade700;
      text = 'Cerrado';
      icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: textColor),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
