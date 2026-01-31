import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_app/widgets/vehicle_tile.dart';

void main() {
  group('VehicleTile Widget', () {
    testWidgets('VehicleTile displays vehicle type and price', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VehicleTile(
              vehicleType: 'Standard',
              isSelected: false,
              estimatedPrice: 150,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('₹150'), findsOneWidget);
    });

    testWidgets('VehicleTile shows selected style when isSelected is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VehicleTile(
              vehicleType: 'Premium',
              isSelected: true,
              estimatedPrice: 250,
              onTap: () {},
            ),
          ),
        ),
      );

      final container = find.byType(Container);
      expect(container, findsWidgets);
      expect(find.text('Premium'), findsOneWidget);
    });

    testWidgets('VehicleTile calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VehicleTile(
              vehicleType: 'Comfort',
              isSelected: false,
              estimatedPrice: 200,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(tapped, true);
    });

    testWidgets('VehicleTile displays correct icon for vehicle type', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VehicleTile(
              vehicleType: 'Bike',
              isSelected: false,
              estimatedPrice: 100,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.two_wheeler), findsOneWidget);
    });

    testWidgets('VehicleTile renders multiple instances in list', (WidgetTester tester) async {
      final vehicles = ['Bike', 'Standard', 'Premium'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                return VehicleTile(
                  vehicleType: vehicles[index],
                  isSelected: index == 0,
                  estimatedPrice: 100 + (index * 50),
                  onTap: () {},
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Bike'), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
    });
  });
}
