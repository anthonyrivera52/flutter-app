import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provides a list of favorite shop IDs
final favoriteShopIdsProvider = StateNotifierProvider<FavoriteShopsNotifier, Set<String>>((ref) {
  return FavoriteShopsNotifier();
});

class FavoriteShopsNotifier extends StateNotifier<Set<String>> {
  FavoriteShopsNotifier() : super({});

  void toggleFavorite(String shopId) {
    if (state.contains(shopId)) {
      state = {...state}..remove(shopId);
    } else {
      state = {...state}..add(shopId);
    }
    // TODO: Persist favorites to local storage
  }
}
