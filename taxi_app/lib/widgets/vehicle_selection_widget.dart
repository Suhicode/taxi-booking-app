import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class VehicleSelectionWidget extends StatefulWidget {
  final String selectedVehicleType;
  final Function(String) onVehicleSelected;

  const VehicleSelectionWidget({
    Key? key,
    required this.selectedVehicleType,
    required this.onVehicleSelected,
  }) : super(key: key);

  @override
  State<VehicleSelectionWidget> createState() => _VehicleSelectionWidgetState();
}

class _VehicleSelectionWidgetState extends State<VehicleSelectionWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.vehicleTypes.length,
        itemBuilder: (context, index) {
          final vehicleType = AppConstants.vehicleTypes[index];
          final isSelected = widget.selectedVehicleType == vehicleType;
          final baseFare = AppConstants.baseFares[vehicleType] ?? 0;
          
          return GestureDetector(
            onTap: () => widget.onVehicleSelected(vehicleType),
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade50 : Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Vehicle icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getVehicleIcon(vehicleType),
                      color: isSelected ? Colors.blue : Colors.grey.shade600,
                      size: 24,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Vehicle name
                  Text(
                    vehicleType,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.blue : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Base fare
                  Text(
                    '₹${baseFare.toInt()}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType) {
      case 'Bike':
        return Icons.motorcycle;
      case 'Scooty':
        return Icons.electric_scooter;
      case 'Standard':
        return Icons.directions_car;
      case 'Comfort':
        return Icons.airport_shuttle;
      case 'Premium':
        return Icons.directions_car_filled;
      case 'XL':
        return Icons.airport_shuttle;
      default:
        return Icons.directions_car;
    }
  }
}
