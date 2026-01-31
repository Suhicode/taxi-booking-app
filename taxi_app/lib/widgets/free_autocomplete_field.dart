import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as lat;
import '../widgets/free_places_service_fixed.dart';

typedef FreePlaceCallback = void Function(String name, lat.LatLng location);

class FreeAutocompleteField extends StatefulWidget {
  final String hint;
  final FreePlaceCallback onSelected;
  final TextEditingController? controller;

  const FreeAutocompleteField({
    super.key,
    required this.hint,
    required this.onSelected,
    this.controller,
  });

  @override
  State<FreeAutocompleteField> createState() => _FreeAutocompleteFieldState();
}

class _FreeAutocompleteFieldState extends State<FreeAutocompleteField> {
  final TextEditingController _textController = TextEditingController();
  List<FreePlace> _suggestions = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _textController?.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController?.removeListener(_onTextChanged);
    _textController?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (_textController.text.length >= 2) {
        final results = await FreePlacesService.searchPlaces(_textController.text);
        if (mounted) {
          setState(() {
            _suggestions = results;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _suggestions.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _textController.clear();
                      setState(() => _suggestions = []);
                    },
                  )
                : null,
          ),
        ),
        if (_suggestions.isNotEmpty)
          ..._suggestions.map((place) => ListTile(
                title: Text(place.name),
                subtitle: Text('${place.location.latitude}, ${place.location.longitude}'),
                onTap: () {
                  widget.onSelected(place.name, place.location);
                  _textController.clear();
                  setState(() => _suggestions = []);
                },
              )),
      ],
    );
  }
}
