import 'package:flutter/material.dart';
import 'package:flutter_app/presentation/widget/common/search_input_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider para el término de búsqueda en la página de búsqueda
final searchPageTermProvider = StateProvider<String>((ref) => '');

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final ValueNotifier<String> _searchTermNotifier;

  @override
  void initState() {
    super.initState();
    _searchTermNotifier = ValueNotifier<String>('');
  }

  @override
  void dispose() {
    _searchTermNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Buscar'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchInputWidget(
              searchTermNotifier: _searchTermNotifier,
              initialIsSearching: true,
              isShowCancelButton: false,
              onSearchModeChanged: (_) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Busca productos, tiendas o categorías',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
