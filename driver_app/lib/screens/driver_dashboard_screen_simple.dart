import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/driver_provider.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    await driverProvider.getCurrentLocation();
    await driverProvider.loadRides();
    await driverProvider.loadEarnings();
  }

  Future<void> _toggleOnlineStatus() async {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    await driverProvider.toggleOnlineStatus();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      await driverProvider.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DriverProvider>(
      builder: (context, driverProvider, child) {
        final driver = driverProvider.driver;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Driver Dashboard'),
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              DashboardOverviewPage(
                driver: driver,
                isOnline: driverProvider.isOnline,
                earnings: driverProvider.earnings,
                onToggleOnlineStatus: _toggleOnlineStatus,
                isLoading: driverProvider.isLoading,
              ),
              RideRequestsPage(
                rides: driverProvider.rides,
                isLoading: driverProvider.isLoading,
                onRefresh: _loadData,
              ),
              ProfilePage(
                driver: driver,
                currentPosition: driverProvider.currentPosition,
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: Colors.white,
            selectedItemColor: Colors.orange.shade700,
            unselectedItemColor: Colors.grey.shade600,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_taxi),
                label: 'Ride Requests',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
