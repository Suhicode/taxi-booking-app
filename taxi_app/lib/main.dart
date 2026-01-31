import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/simple_ride_provider.dart';
import 'pages/customer_book_ride.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(); // Firebase removed - using free solution
  runApp(const TaxiApp());
}

class TaxiApp extends StatelessWidget {
  const TaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SimpleRideProvider()),
      ],
      child: MaterialApp(
        title: 'RideNow Customer',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: CustomerBookRidePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
