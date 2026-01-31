import 'package:flutter/material.dart';

class DriverCard extends StatelessWidget {
  final String driverName;
  final String vehicle;
  final String eta;
  final String fare;
  final VoidCallback onCall;
  final VoidCallback onChat;
  final VoidCallback onPrimary;

  const DriverCard({
    super.key,
    required this.driverName,
    required this.vehicle,
    required this.eta,
    required this.fare,
    required this.onCall,
    required this.onChat,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Material(
            elevation: 18,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driverName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(vehicle, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Icon(Icons.timer, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text("ETA: $eta"),

                            const SizedBox(width: 10),
                            Text("Fare: $fare", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Column(
                    children: [
                      IconButton(onPressed: onCall, icon: const Icon(Icons.call)),
                      IconButton(onPressed: onChat, icon: const Icon(Icons.chat)),
                      ElevatedButton(
                        onPressed: onPrimary,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        child: const Text("Contact"),
                      ),
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
