import 'package:flutter/material.dart';
import '../models/location_model.dart';

class LocationSearchWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final IconData icon;
  final Function(LocationModel) onLocationSelected;
  final VoidCallback? onClear;

  const LocationSearchWidget({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.icon,
    required this.onLocationSelected,
    this.onClear,
  }) : super(key: key);

  @override
  State<LocationSearchWidget> createState() => _LocationSearchWidgetState();
}

class _LocationSearchWidgetState extends State<LocationSearchWidget> {
  bool _isSearching = false;
  List<LocationModel> _searchResults = [];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // Input field
          TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: Icon(widget.icon, color: Colors.blue),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        widget.controller.clear();
                        widget.onClear?.call();
                        setState(() {
                          _searchResults.clear();
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: _onSearchChanged,
            onTap: _showLocationSuggestions,
          ),
          
          // Search results
          if (_searchResults.isNotEmpty)
            Container(
              height: 200,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final location = _searchResults[index];
                  return ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: Colors.grey.shade600,
                    ),
                    title: Text(
                      location.name ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      location.address ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      widget.onLocationSelected(location);
                      widget.controller.text = location.address ?? location.name ?? '';
                      setState(() {
                        _searchResults.clear();
                      });
                      FocusScope.of(context).unfocus();
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    // Simulate search with delay
    setState(() {
      _isSearching = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        // Mock search results - in real app, this would call an API
        final results = _mockSearchResults(query);
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  List<LocationModel> _mockSearchResults(String query) {
    // Mock locations for demo
    final mockLocations = [
      LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        name: 'Indira Gandhi International Airport',
        address: 'New Delhi, Delhi, India',
      ),
      LocationModel(
        latitude: 28.6353,
        longitude: 77.2245,
        name: 'Connaught Place',
        address: 'New Delhi, Delhi, India',
      ),
      LocationModel(
        latitude: 28.6315,
        longitude: 77.2197,
        name: 'India Gate',
        address: 'New Delhi, Delhi, India',
      ),
      LocationModel(
        latitude: 28.6129,
        longitude: 77.2295,
        name: 'Red Fort',
        address: 'New Delhi, Delhi, India',
      ),
      LocationModel(
        latitude: 28.6139,
        longitude: 77.2090,
        name: 'Qutub Minar',
        address: 'New Delhi, Delhi, India',
      ),
    ];

    return mockLocations
        .where((location) =>
            (location.name?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
            (location.address?.toLowerCase().contains(query.toLowerCase()) ?? false))
        .take(5)
        .toList();
  }

  void _showLocationSuggestions() {
    // Show some default suggestions when tapped
    if (_searchResults.isEmpty && widget.controller.text.isEmpty) {
      setState(() {
        _searchResults = [
          LocationModel(
            latitude: 28.6139,
            longitude: 77.2090,
            name: 'Current Location',
            address: 'Use your current location',
          ),
          LocationModel(
            latitude: 28.6353,
            longitude: 77.2245,
            name: 'Home',
            address: 'Set your home address',
          ),
          LocationModel(
            latitude: 28.6315,
            longitude: 77.2197,
            name: 'Work',
            address: 'Set your work address',
          ),
        ];
      });
    }
  }
}
