import 'package:flutter/material.dart';

class VehicleTile extends StatelessWidget {
  final String vehicleType;
  final bool isSelected;
  final int estimatedPrice;
  final VoidCallback? onTap;

  const VehicleTile({
    super.key,
    required this.vehicleType,
    required this.isSelected,
    required this.estimatedPrice,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed width ensures each horizontal item has enough room and avoids tight constraints.
    return SizedBox(
      width: 110, // adjust width to taste (100-140)
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.12) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
              width: isSelected ? 1.6 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // IMPORTANT: do not expand vertically
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // small icon circle
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconFor(vehicleType),
                  size: 22,
                  color: isSelected ? Colors.black : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              // Vehicle type label
              Text(
                vehicleType,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              // Price
              Text(
                '₹$estimatedPrice',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String v) {
    final s = v.toLowerCase();
    if (s.contains('bike')) return Icons.sports_motorsports;
    if (s.contains('scooty')) return Icons.two_wheeler;
    if (s.contains('xl')) return Icons.local_shipping;
    if (s.contains('premium')) return Icons.directions_car;
    if (s.contains('comfort')) return Icons.airline_seat_recline_normal;
    return Icons.directions_car;
  }
}
