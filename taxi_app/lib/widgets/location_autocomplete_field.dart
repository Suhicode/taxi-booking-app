import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/openstreetmap_service.dart';

class LocationAutocompleteField extends StatefulWidget {
  final String hintText;
  final Function(LocationSuggestion) onSelected;
  final TextEditingController? controller;
  final Widget? prefixIcon;

  const LocationAutocompleteField({
    Key? key,
    required this.hintText,
    required this.onSelected,
    this.controller,
    this.prefixIcon,
  }) : super(key: key);

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = widget.controller ?? TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<LocationSuggestion>(
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon ?? const Icon(Icons.search),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        );
      },
      suggestionsCallback: (pattern) async {
        if (pattern.length < 2) return [];
        return await OpenStreetMapService.searchLocation(pattern);
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          leading: const Icon(Icons.location_on),
          title: Text(suggestion.name),
          subtitle: Text(
            suggestion.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
      onSelected: (suggestion) {
        _textController.text = suggestion.displayName;
        widget.onSelected(suggestion);
        FocusScope.of(context).unfocus();
      },
      emptyBuilder: (context) => const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No locations found'),
      ),
      loadingBuilder: (context) => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorBuilder: (context, error) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $error'),
      ),
    );
  }
}
