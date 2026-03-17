import 'package:flutter/material.dart';

class SearchInputWidget extends StatefulWidget {
  final ValueNotifier<String> searchTermNotifier;
  final ValueChanged<bool>? onSearchModeChanged;
  final bool initialIsSearching; // Indica si el widget debe iniciar en modo búsqueda (pasado por el padre)
  final bool isShowCancelButton; // Añadido para controlar si se muestra el botón de cancelar

  const SearchInputWidget({
    super.key,
    required this.searchTermNotifier,
    this.onSearchModeChanged,
    this.initialIsSearching = false,
    this.isShowCancelButton = false, // Añadido para controlar si se muestra el botón de cancelar
  });

  @override
  State<SearchInputWidget> createState() => _SearchInputWidgetState();
}

class _SearchInputWidgetState extends State<SearchInputWidget> {
  late TextEditingController _searchController;
  // bool _isSearching = false; // Ya no gestionamos el estado interno aquí, el padre lo controla

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchTermNotifier.value);
  }

  @override
  void didUpdateWidget(covariant SearchInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sincronizar el texto del controlador con el notificador del padre si cambia externamente
    if (widget.searchTermNotifier.value != _searchController.text) {
      _searchController.text = widget.searchTermNotifier.value;
      // Mueve el cursor al final del texto al actualizarlo
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTapped() {
    // Al presionar el TextField, notificamos al padre que queremos activar el modo búsqueda
    widget.onSearchModeChanged?.call(true);
  }

  void _onCancelSearch() {
    _searchController.clear();
    widget.searchTermNotifier.value = ''; // Limpiar el término de búsqueda
    widget.onSearchModeChanged?.call(false); // Notificar que se ha salido del modo búsqueda
  }

  void _onClearSearch() {
    _searchController.clear();
    widget.searchTermNotifier.value = ''; // Limpiar el término de búsqueda
    // Opcional: si quieres salir del modo búsqueda al borrar todo el texto
    // if (_searchController.text.isEmpty) {
    //   widget.onSearchModeChanged?.call(false);
    // }
  }

  @override
  Widget build(BuildContext context) {
    // El widget SIEMPRE es un Row con un TextField
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            readOnly: !widget.initialIsSearching, // Solo editable si initialIsSearching es true
            autofocus: widget.initialIsSearching, // Autofocus solo si estamos en modo búsqueda
            onTap: _onSearchTapped, // Manejar el tap para activar el modo búsqueda
            decoration: InputDecoration(
              hintText: 'Search something...', // Ajustado para coincidir con la captura
              prefixIcon: const Icon(Icons.search), // Icono de lupa a la izquierda
              suffixIcon: widget.initialIsSearching && _searchController.text.isNotEmpty // Mostrar 'X' solo si estamos buscando y hay texto
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _onClearSearch,
                    )
                  : null, // No mostrar nada si no estamos buscando o no hay texto
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            ),
            onChanged: (value) {
              widget.searchTermNotifier.value = value;
            },
          ),
        ),
        if (widget.initialIsSearching) // Mostrar 'Cancel' solo si estamos en modo búsqueda
          const SizedBox(width: 8.0),
        if (widget.isShowCancelButton) // Mostrar 'Cancel' solo si estamos en modo búsqueda
          TextButton(
            onPressed: _onCancelSearch,
            child: Text(
              'Cancel', // Texto "Cancel"
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
      ],
    );
  }
}