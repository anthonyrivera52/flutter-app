import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Search input with debounce to prevent excessive API calls
/// Improves performance by waiting for user to stop typing
class DebouncedSearchInput extends StatefulWidget {
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? hintText;
  final Duration debounceDuration;
  final TextEditingController? controller;

  const DebouncedSearchInput({
    super.key,
    this.onChanged,
    this.onSubmitted,
    this.hintText,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.controller,
  });

  @override
  State<DebouncedSearchInput> createState() => _DebouncedSearchInputState();
}

class _DebouncedSearchInputState extends State<DebouncedSearchInput> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounceDuration, () {
      widget.onChanged?.call(value);
    });
  }

  void _onSubmitted(String value) {
    _debounceTimer?.cancel();
    widget.onSubmitted?.call(value);
  }

  void clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onTextChanged,
      onSubmitted: _onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText ?? 'Buscar productos...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.clear), onPressed: clear)
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

/// Provider for debounced search term
final searchTermProvider = StateProvider<String>((ref) => '');

/// Notifier for managing search with debounce
class SearchNotifier extends StateNotifier<String> {
  Timer? _debounceTimer;

  SearchNotifier() : super('');

  void updateSearch(
    String value, {
    Duration debounce = const Duration(milliseconds: 300),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      state = value;
    });
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    state = '';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final searchNotifierProvider = StateNotifierProvider<SearchNotifier, String>((
  ref,
) {
  return SearchNotifier();
});
