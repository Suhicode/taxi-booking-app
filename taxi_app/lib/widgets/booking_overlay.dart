import 'package:flutter/material.dart';

class BookingOverlay extends StatelessWidget {
  final String pickupText;
  final String destinationText;
  final VoidCallback onPickupTap;
  final VoidCallback onDestinationTap;
  final VoidCallback onBookTap;
  final String estimatedFare;

  const BookingOverlay({
    super.key,
    required this.pickupText,
    required this.destinationText,
    required this.onPickupTap,
    required this.onDestinationTap,
    required this.onBookTap,
    required this.estimatedFare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Material(
            borderRadius: BorderRadius.circular(16),
            elevation: 18,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LocationRow(
                    icon: Icons.my_location,
                    text: pickupText,
                    placeholder: 'Set pickup location',
                    onTap: onPickupTap,
                  ),
                  const SizedBox(height: 8),
                  _LocationRow(
                    icon: Icons.location_on,
                    text: destinationText,
                    placeholder: 'Set destination',
                    onTap: onDestinationTap,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Estimated fare', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                              estimatedFare,
                              style: theme.textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      ElevatedButton(
                        onPressed: onBookTap,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(140, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('Book Ride'),
                            SizedBox(width: 6),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String placeholder;
  final VoidCallback onTap;

  const _LocationRow({
    required this.icon,
    required this.text,
    required this.placeholder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasText = text.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: hasText ? Colors.white : const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: hasText ? Colors.black : Colors.grey, size: 20),
            const SizedBox(width: 12),

            Expanded(
              child: Text(
                hasText ? text : placeholder,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: hasText ? FontWeight.w600 : FontWeight.w400,
                  color: hasText ? Colors.black : Colors.grey[600],
                ),
              ),
            ),

            if (!hasText)
              const Icon(Icons.search, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
