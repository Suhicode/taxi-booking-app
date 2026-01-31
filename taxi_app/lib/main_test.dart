import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/simple_ride_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Simplified test - just run the app without location services
  runApp(const TaxiApp());
}
