import 'package:flutter/material.dart';

class FareSummaryWidget extends StatelessWidget {
  final Map<String, dynamic>? fareData;

  const FareSummaryWidget({
    Key? key,
    this.fareData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (fareData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fare Estimate',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select locations to see fare',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final distance = fareData!['distance'] as double? ?? 0.0;
    final duration = fareData!['duration'] as double? ?? 0.0;
    final baseFare = fareData!['baseFare'] as double? ?? 0.0;
    final distanceFare = fareData!['distanceFare'] as double? ?? 0.0;
    final timeFare = fareData!['timeFare'] as double? ?? 0.0;
    final surgeMultiplier = fareData!['surgeMultiplier'] as double? ?? 1.0;
    final finalFare = fareData!['finalFare'] as double? ?? 0.0;
    final total = fareData!['total'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fare Breakdown',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (surgeMultiplier > 1.0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(surgeMultiplier * 100).toInt()}% Surge',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Distance and time
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Distance',
                  '${distance.toStringAsFixed(1)} km',
                  Icons.straighten,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  'Est. Time',
                  '${duration.toInt()} min',
                  Icons.access_time,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Fare breakdown
          _buildFareBreakdown('Base Fare', baseFare),
          _buildFareBreakdown('Distance Fare', distanceFare),
          _buildFareBreakdown('Time Fare', timeFare),
          
          if (surgeMultiplier > 1.0) ...[
            const SizedBox(height: 4),
            _buildFareBreakdown(
              'Surge (${(surgeMultiplier * 100).toInt()}%)',
              finalFare - baseFare - distanceFare - timeFare,
              isSurge: true,
            ),
          ],
          
          const Divider(height: 16),
          
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹$total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFareBreakdown(String label, double amount, {bool isSurge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSurge ? Colors.orange.shade800 : Colors.grey.shade700,
              fontWeight: isSurge ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '₹${amount.toInt()}',
            style: TextStyle(
              fontSize: 12,
              color: isSurge ? Colors.orange.shade800 : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
