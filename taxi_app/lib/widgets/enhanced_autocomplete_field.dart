import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as lat;
import '../services/openstreetmap_search_service.dart';

class EnhancedAutocompleteField extends StatefulWidget {
  final String hint;
  final Function(String address, lat.LatLng location) onSelected;
  final TextEditingController? controller;

  const EnhancedAutocompleteField({
    super.key,
    required this.hint,
    required this.onSelected,
    this.controller,
  });

  @override
  State<EnhancedAutocompleteField> createState() => _EnhancedAutocompleteFieldState();
}

class _EnhancedAutocompleteFieldState extends State<EnhancedAutocompleteField> {
  final TextEditingController _textController = TextEditingController();
  List<LocationSuggestion> _suggestions = [];
  Timer? _debounceTimer;
  bool _isLoading = false;

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

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_textController.text.length >= 2) {
        await _searchLocations(_textController.text);
      }
    });
  }

  Future<void> _searchLocations(String query) async {
    setState(() => _isLoading = true);
    
    try {
      // Use OpenStreetMap service for real location search
      final locations = await OpenStreetMapSearchService.searchLocations(query);
      
      if (mounted) {
        setState(() {
          _suggestions = locations.map((location) => LocationSuggestion(
            address: location.address ?? location.name ?? 'Unknown Location',
            location: location.toLatLng(),
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      final currentLocation = await OpenStreetMapSearchService.getCurrentLocation();
      if (currentLocation != null && mounted) {
        widget.onSelected(
          currentLocation.address ?? 'Current Location',
          currentLocation.toLatLng(),
        );
        _textController.text = currentLocation.address ?? 'Current Location';
        setState(() => _suggestions = []);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get current location')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller ?? _textController,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.my_location),
                        onPressed: _useCurrentLocation,
                        tooltip: 'Use current location',
                      ),
                      if (_suggestions.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _textController.clear();
                            setState(() => _suggestions = []);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_suggestions.isNotEmpty)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(suggestion.address),
                  subtitle: Text('${suggestion.location.latitude.toStringAsFixed(4)}, ${suggestion.location.longitude.toStringAsFixed(4)}'),
                  onTap: () {
                    widget.onSelected(suggestion.address, suggestion.location);
                    _textController.text = suggestion.address;
                    setState(() => _suggestions = []);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class LocationSuggestion {
  final String address;
  final lat.LatLng location;

  const LocationSuggestion({
    required this.address,
    required this.location,
  });
}
