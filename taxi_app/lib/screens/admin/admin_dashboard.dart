import 'package:flutter/material.dart';
import 'user_details_page.dart';
import 'edit_user_page.dart';
import 'ride_details_page.dart';
import '../../services/admin_auth_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardOverviewPage(),
    const UserManagementPage(),
    const RideMonitoringPage(),
  ];

  final List<String> _titles = [
    'Dashboard Overview',
    'User Management',
    'Ride Monitoring',
  ];

  Future<void> _logout() async {
    // Show confirmation dialog
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
      await AdminAuthService.logout();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Rides',
          ),
        ],
      ),
    );
  }
}

class DashboardOverviewPage extends StatelessWidget {
  const DashboardOverviewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Users',
                  '1,234',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Active Rides',
                  '45',
                  Icons.directions_car,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Drivers',
                  '89',
                  Icons.drive_eta,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Revenue Today',
                  '\$2,450',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildActivityItem('New user registered', 'John Doe', '2 mins ago'),
                _buildActivityItem('Ride completed', 'Trip #1234', '5 mins ago'),
                _buildActivityItem('Driver went online', 'Driver #89', '10 mins ago'),
                _buildActivityItem('Payment processed', '\$45.00', '15 mins ago'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String action, String details, String time) {
    return ListTile(
      leading: const Icon(Icons.circle, size: 8, color: Colors.blue),
      title: Text(action),
      subtitle: Text(details),
      trailing: Text(
        time,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
    );
  }
}

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'All';
  String _selectedStatus = 'All';
  List<Map<String, dynamic>> _allUsers = List.generate(10, (index) => {
    'id': 'USR${(index + 1).toString().padLeft(3, '0')}',
    'name': 'User ${index + 1}',
    'email': 'user${index + 1}@example.com',
    'phone': '+123456789${index}',
    'role': index % 3 == 0 ? 'Driver' : 'Customer',
    'isActive': index % 5 != 0,
    'joinDate': '${(index + 1)}/01/2024',
  });
  List<Map<String, dynamic>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = List.from(_allUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        // Search filter
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch = user['name'].toString().toLowerCase().contains(searchQuery) ||
                            user['email'].toString().toLowerCase().contains(searchQuery) ||
                            user['id'].toString().toLowerCase().contains(searchQuery);
        
        // Role filter
        final matchesRole = _selectedRole == 'All' || user['role'] == _selectedRole;
        
        // Status filter
        final matchesStatus = _selectedStatus == 'All' || 
                             (_selectedStatus == 'Active' && user['isActive']) ||
                             (_selectedStatus == 'Inactive' && !user['isActive']);
        
        return matchesSearch && matchesRole && matchesStatus;
      }).toList();
    });
  }

  void _showSuspendDialog(BuildContext context, int index) {
    final user = _filteredUsers[index];
    final isCurrentlyActive = user['isActive'] as bool;
    final originalIndex = _allUsers.indexWhere((u) => u['id'] == user['id']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCurrentlyActive ? 'Suspend User' : 'Activate User'),
        content: Text(
          isCurrentlyActive 
            ? 'Are you sure you want to suspend ${user['name']}? They will not be able to access the system.'
            : 'Are you sure you want to activate ${user['name']}? They will regain access to the system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _allUsers[originalIndex]['isActive'] = !isCurrentlyActive;
              });
              _filterUsers();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isCurrentlyActive ? 'User suspended successfully' : 'User activated successfully'
                  ),
                  backgroundColor: isCurrentlyActive ? Colors.orange : Colors.green,
                ),
              );
            },
            child: Text(
              isCurrentlyActive ? 'Suspend' : 'Activate',
              style: TextStyle(color: isCurrentlyActive ? Colors.orange : Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, int index) {
    final user = _filteredUsers[index];
    final originalIndex = _allUsers.indexWhere((u) => u['id'] == user['id']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user['name']}? This action cannot be undone and all their data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _allUsers.removeAt(originalIndex);
              });
              _filterUsers();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Management',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Add user functionality coming soon')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Search and Filter Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search Field
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users by name, email, or ID...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) => _filterUsers(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filter Row
                  Row(
                    children: [
                      // Role Filter
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Role',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: const ['All', 'Customer', 'Driver', 'Admin'].map((role) {
                                return DropdownMenuItem<String>(
                                  value: role,
                                  child: Text(role),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value!;
                                });
                                _filterUsers();
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Status Filter
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: const ['All', 'Active', 'Inactive'].map((status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value!;
                                });
                                _filterUsers();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Results Count
          Text(
            'Showing ${_filteredUsers.length} of ${_allUsers.length} users',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          
          // Users List
          Expanded(
            child: _filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(context, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, int index) {
    final user = _filteredUsers[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user['name'].toString().substring(0, 2).toUpperCase()),
        ),
        title: Text(user['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email']),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user['role']),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user['role'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: user['isActive'] ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user['isActive'] ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          onSelected: (value) {
            if (value == 'view') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserDetailsPage(
                    userId: user['id'],
                    userName: user['name'],
                    userEmail: user['email'],
                    userPhone: user['phone'],
                    userRole: user['role'],
                    joinDate: user['joinDate'],
                    isActive: user['isActive'],
                  ),
                ),
              );
            } else if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditUserPage(
                    userId: user['id'],
                    userName: user['name'],
                    userEmail: user['email'],
                    userPhone: user['phone'],
                    userRole: user['role'],
                    isActive: user['isActive'],
                  ),
                ),
              ).then((result) {
                if (result == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User updated successfully!')),
                  );
                }
              });
            } else if (value == 'suspend') {
              _showSuspendDialog(context, index);
            } else if (value == 'delete') {
              _showDeleteDialog(context, index);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'edit', child: Text('Edit User')),
            PopupMenuItem(
              value: 'suspend',
              child: Text(user['isActive'] ? 'Suspend' : 'Activate'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Driver':
        return Colors.blue;
      case 'Admin':
        return Colors.purple;
      case 'Customer':
      default:
        return Colors.orange;
    }
  }
}

class RideMonitoringPage extends StatefulWidget {
  const RideMonitoringPage({Key? key}) : super(key: key);

  @override
  State<RideMonitoringPage> createState() => _RideMonitoringPageState();
}

class _RideMonitoringPageState extends State<RideMonitoringPage> {
  bool _showActiveRides = true;
  List<Map<String, dynamic>> _allRides = [
    {
      'id': 'R1001',
      'driver': 'Driver 1',
      'customer': 'Customer 1',
      'status': 'In Progress',
      'fare': 15.50,
      'pickup': '123 Main St',
      'dropoff': '456 Oak Ave',
      'startTime': '10:30 AM',
      'endTime': null,
      'distance': '3.2 miles',
      'duration': '15 mins',
      'paymentMethod': 'Credit Card',
      'paymentStatus': 'Pending',
    },
    {
      'id': 'R1002',
      'driver': 'Driver 2',
      'customer': 'Customer 2',
      'status': 'In Progress',
      'fare': 22.00,
      'pickup': '789 Elm St',
      'dropoff': '321 Pine Rd',
      'startTime': '11:15 AM',
      'endTime': null,
      'distance': '5.8 miles',
      'duration': '22 mins',
      'paymentMethod': 'Cash',
      'paymentStatus': 'Pending',
    },
    {
      'id': 'R1003',
      'driver': 'Driver 3',
      'customer': 'Customer 3',
      'status': 'In Progress',
      'fare': 18.75,
      'pickup': '456 Maple Dr',
      'dropoff': '789 Cedar Ln',
      'startTime': '12:00 PM',
      'endTime': null,
      'distance': '4.1 miles',
      'duration': '18 mins',
      'paymentMethod': 'Credit Card',
      'paymentStatus': 'Pending',
    },
    {
      'id': 'R1004',
      'driver': 'Driver 4',
      'customer': 'Customer 4',
      'status': 'Completed',
      'fare': 31.25,
      'pickup': '321 Birch St',
      'dropoff': '654 Spruce Way',
      'startTime': '09:45 AM',
      'endTime': '10:05 AM',
      'distance': '7.3 miles',
      'duration': '20 mins',
      'paymentMethod': 'Credit Card',
      'paymentStatus': 'Paid',
    },
    {
      'id': 'R1005',
      'driver': 'Driver 5',
      'customer': 'Customer 5',
      'status': 'Completed',
      'fare': 19.00,
      'pickup': '987 Oak St',
      'dropoff': '246 Pine Ave',
      'startTime': '08:30 AM',
      'endTime': '08:50 AM',
      'distance': '4.5 miles',
      'duration': '20 mins',
      'paymentMethod': 'Cash',
      'paymentStatus': 'Paid',
    },
    {
      'id': 'R1006',
      'driver': 'Driver 6',
      'customer': 'Customer 6',
      'status': 'Completed',
      'fare': 27.50,
      'pickup': '159 Elm Dr',
      'dropoff': '357 Maple Rd',
      'startTime': '07:15 AM',
      'endTime': '07:40 AM',
      'distance': '6.2 miles',
      'duration': '25 mins',
      'paymentMethod': 'Credit Card',
      'paymentStatus': 'Paid',
    },
    {
      'id': 'R1007',
      'driver': 'Driver 7',
      'customer': 'Customer 7',
      'status': 'Cancelled',
      'fare': 0.00,
      'pickup': '753 Cedar St',
      'dropoff': '951 Birch Ave',
      'startTime': '11:00 AM',
      'endTime': '11:05 AM',
      'distance': '0.0 miles',
      'duration': '5 mins',
      'paymentMethod': 'Credit Card',
      'paymentStatus': 'Refunded',
    },
    {
      'id': 'R1008',
      'driver': 'Driver 8',
      'customer': 'Customer 8',
      'status': 'Completed',
      'fare': 21.75,
      'pickup': '456 Spruce Ln',
      'dropoff': '123 Oak Way',
      'startTime': '10:00 AM',
      'endTime': '10:25 AM',
      'distance': '5.5 miles',
      'duration': '25 mins',
      'paymentMethod': 'Credit Card',
      'paymentStatus': 'Paid',
    },
  ];

  List<Map<String, dynamic>> get _filteredRides {
    return _allRides.where((ride) {
      if (_showActiveRides) {
        return ride['status'] == 'In Progress';
      } else {
        return ride['status'] != 'In Progress';
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ride Monitoring',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Filter Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showActiveRides = true;
                    });
                  },
                  icon: const Icon(Icons.play_circle),
                  label: const Text('Active Rides'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showActiveRides ? Colors.green : Colors.grey.shade300,
                    foregroundColor: _showActiveRides ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showActiveRides = false;
                    });
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('Ride History'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_showActiveRides ? Colors.blue : Colors.grey.shade300,
                    foregroundColor: !_showActiveRides ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  '${_allRides.where((r) => r['status'] == 'In Progress').length}',
                  'Active Rides',
                  Icons.directions_car,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  context,
                  '${_allRides.where((r) => r['status'] == 'Completed').length}',
                  'Completed Today',
                  Icons.check_circle,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  context,
                  '\$${_allRides.where((r) => r['status'] == 'Completed').fold<double>(0.0, (sum, ride) => sum + ride['fare']).toStringAsFixed(2)}',
                  'Revenue Today',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Results Count
          Text(
            'Showing ${_filteredRides.length} rides',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          
          // Rides List
          Expanded(
            child: _filteredRides.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showActiveRides ? Icons.no_crash : Icons.history,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _showActiveRides ? 'No active rides' : 'No ride history',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _showActiveRides ? 'All rides are completed' : 'No completed rides found',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredRides.length,
                    itemBuilder: (context, index) {
                      return _buildRideCard(context, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, int index) {
    final ride = _filteredRides[index];
    final isActive = ride['status'] == 'In Progress';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusColor(ride['status']),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isActive ? Icons.directions_car : Icons.history,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text('Ride ${ride['id']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Driver: ${ride['driver']}'),
            Text('Customer: ${ride['customer']}'),
            Text('Status: ${ride['status']}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${ride['fare'].toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.green : Colors.grey,
              ),
            ),
            Text(
              ride['startTime'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RideDetailsPage(
                rideId: ride['id'],
                driverName: ride['driver'],
                customerName: ride['customer'],
                pickupLocation: ride['pickup'],
                dropoffLocation: ride['dropoff'],
                status: ride['status'],
                fare: ride['fare'],
                startTime: ride['startTime'],
                endTime: ride['endTime'],
                distance: ride['distance'],
                duration: ride['duration'],
                paymentMethod: ride['paymentMethod'],
                paymentStatus: ride['paymentStatus'],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Progress':
        return Colors.green;
      case 'Completed':
        return Colors.blue;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
