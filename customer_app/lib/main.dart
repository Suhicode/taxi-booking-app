import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/passenger_provider.dart';
import 'screens/passenger_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PassengerProvider()),
      ],
      child: MaterialApp(
        title: 'RideNow Customer',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
        ),
        home: PassengerLoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
