// lib/pages/customer_book_ride_refactored.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as lat;
import '../models/ride_booking_state.dart';
import '../models/ride_state.dart';
import '../providers/ride_cubit.dart';
import '../repositories/ride_repository.dart';
import '../services/pricing_service.dart';
import '../widgets/vehicle_tile.dart';
import '../widgets/simple_map.dart';
import '../widgets/free_autocomplete_field.dart';
import '../widgets/booking_overlay.dart';
import '../widgets/ride_notification_banner.dart';

class CustomerBookRidePage extends StatelessWidget {
  const CustomerBookRidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RideCubit()..initializeLocation(),
      child: const CustomerBookRideView(),
    );
  }
}

class CustomerBookRideView extends StatefulWidget {
  const CustomerBookRideView({super.key});

  @override
  State<CustomerBookRideView> createState() => _CustomerBookRideViewState();
}

class _CustomerBookRideViewState extends State<CustomerBookRideView> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<RideCubit, RideBookingState>(
        builder: (context, state) {
          if (state.isLoading && state.currentLocation == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              // Map background
              _buildMap(context, state),

              // Customer ride status notification banner
              if (state.showNotification && state.notificationTitle != null)
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: RideNotificationBanner(
                    icon: Icons.local_taxi,
                    title: state.notificationTitle!,
                    subtitle: state.notificationSubtitle,
                    onTap: () {
                      context.read<RideCubit>().clearNotification();
                    },
                    onClose: () {
                      context.read<RideCubit>().clearNotification();
                    },
                  ),
                ),

              // Top gradient header + greeting card
              _buildTopHeader(context, state),

              // Vehicle selector
              if (state.rideState.isIdle)
                _buildVehicleSelector(context, state),

              // Booking / in-trip bottom sheet
              if (state.rideState.isIdle)
                BookingOverlay(
                  pickupText: state.pickupText.isNotEmpty 
                      ? state.pickupText 
                      : _pickupController.text,
                  destinationText: state.destinationText.isNotEmpty 
                      ? state.destinationText 
                      : _destinationController.text,
                  estimatedFare: '₹${state.estimatedPrice}',
                  onPickupTap: () => _showLocationSelector(context, isPickup: true),
                  onDestinationTap: () => _showLocationSelector(context, isPickup: false),
                  onBookTap: () => context.read<RideCubit>().requestRide(),
                ),

              // Driver assigned UI
              if (state.rideState.isDriverAccepted)
                _buildDriverAssignedUI(context, state),

              // Custom locate-me FAB
              if (!kIsWeb)
                Positioned(
                  right: 16,
                  bottom: 320,
                  child: FloatingActionButton(
                    heroTag: 'locFab',
                    mini: true,
                    onPressed: () => context.read<RideCubit>().getCurrentLocation(),
                    child: const Icon(Icons.my_location),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(BuildContext context, RideBookingState state) {
    if (state.currentLocation == null) {
      return Container(
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Create markers for drivers, pickup, and destination
    final Set<Marker> allMarkers = {};
    
    // Add driver markers
    allMarkers.addAll(context.read<RideCubit>().driverMarkers);

    // Add pickup marker
    if (state.pickupLocation != null) {
      allMarkers.add(Marker(
        point: state.pickupLocation!,
        width: 30.0,
        height: 30.0,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.0),
          ),
          child: const Icon(Icons.my_location, size: 16, color: Colors.white),
        ),
      ));
    }

    // Add destination marker
    if (state.destination != null) {
      allMarkers.add(Marker(
        point: state.destination!,
        width: 30.0,
        height: 30.0,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.0),
          ),
          child: const Icon(Icons.location_on, size: 16, color: Colors.white),
        ),
      ));
    }

    return SimpleMap(
      center: state.currentLocation ?? lat.LatLng(37.7749, -122.4194),
      zoom: 15.0,
      markers: allMarkers,
      onTap: (dest) {
        _destinationController.text = 'Selected Destination';
        context.read<RideCubit>().onDestinationSelected('Selected Destination', dest);
      },
    );
  }

  Widget _buildTopHeader(BuildContext context, RideBookingState state) {
    final theme = Theme.of(context);
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF6C200),
              Color(0xFFFFE58A),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.black87),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good day 👋',
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ),
                        Text(
                          'Where are you going?',
                          style: theme.textTheme.titleLarge!.copyWith(
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications coming soon')),
                      );
                    },
                    icon: const Icon(Icons.notifications_none, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Compact pickup/destination quick card
              Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _showLocationSelector(context, isPickup: true),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            Container(
                              height: 26,
                              width: 26,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.my_location, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.pickupText.isNotEmpty ? state.pickupText : 'Current location',
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Divider(color: Colors.grey.shade200, height: 1),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _showLocationSelector(context, isPickup: false),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            Container(
                              height: 26,
                              width: 26,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEE2E2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.destinationText.isNotEmpty
                                    ? state.destinationText
                                    : 'Where to?',
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: state.destinationText.isNotEmpty
                                      ? theme.textTheme.bodyMedium!.color
                                      : Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleSelector(BuildContext context, RideBookingState state) {
    final List<String> vehicleTypes = ['Bike', 'Scooty', 'Standard', 'Comfort', 'Premium', 'XL'];
    
    return Positioned(
      left: 0,
      right: 0,
      bottom: 210,
      child: SizedBox(
        height: 120,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          scrollDirection: Axis.horizontal,
          itemCount: vehicleTypes.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final vehicle = vehicleTypes[index];
            final distance = state.pickupLocation != null && state.destination != null
                ? context.read<RideCubit>().calculateDistance(
                      state.pickupLocation!,
                      state.destination!,
                    )
                : 5.0;
            final fare = PricingService.calculateFare(
              vehicleType: vehicle,
              distanceKm: distance,
              durationMin: 15,
            );
            return VehicleTile(
              vehicleType: vehicle,
              isSelected: state.selectedVehicle == vehicle,
              estimatedPrice: fare['total'] as int,
              onTap: () {
                context.read<RideCubit>().selectVehicle(vehicle);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDriverAssignedUI(BuildContext context, RideBookingState state) {
    final theme = Theme.of(context);
    
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: Material(
        elevation: 24,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_car, color: Colors.black87),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.notificationSubtitle ?? 'Driver',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.selectedVehicle,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calling driver...')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chat coming soon')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'ETA ~ 5 min',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '₹${state.estimatedPrice}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.read<RideCubit>().cancelRide(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (state.currentLocation != null) {
                          context.read<RideCubit>().moveToLocation(state.currentLocation!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Centering on driver')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Driver location not available')),
                          );
                        }
                      },
                      icon: const Icon(Icons.navigation),
                      label: const Text('Track driver'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (ctx) => SafeArea(
                            child: Wrap(
                              children: const [
                                ListTile(
                                  leading: Icon(Icons.support_agent),
                                  title: Text('Contact support'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: const Text('Help'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationSelector({required BuildContext context, required bool isPickup}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: FreeAutocompleteField(
            hint: isPickup ? 'Enter pickup location' : 'Enter destination',
            controller: isPickup ? _pickupController : _destinationController,
            onSelected: (name, loc) {
              Navigator.of(context).pop();
              if (isPickup) {
                context.read<RideCubit>().onPickupSelected(name, loc);
                _pickupController.text = name;
              } else {
                context.read<RideCubit>().onDestinationSelected(name, loc);
                _destinationController.text = name;
              }
            },
          ),
        );
      },
    );
  }
}
