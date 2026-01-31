import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/driver_provider.dart';
import 'screens/driver_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DriverProvider()),
      ],
      child: MaterialApp(
        title: 'RideNow Driver',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            brightness: Brightness.light,
          ),
        ),
        home: DriverLoginScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
