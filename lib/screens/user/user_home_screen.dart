import 'package:flutter/material.dart';
import 'package:watch_hub/screens/user/profile_screen.dart';
import 'package:watch_hub/screens/user/search_screen.dart';
import 'package:watch_hub/screens/user/wishlist_screen.dart';
// import 'package:watch_hub/services/auth_service.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  // Auth Service
  // final _auth = AuthService();
  // Controllers
  final _searchBarController = TextEditingController();

  int _selectedIndex = 0;

  @override
  void dispose() {
    _searchBarController.dispose();
    super.dispose();
  }

  List<Widget> _pages() => [
    buildHomeContent(),
    SearchScreen(),
    WishlistScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // Option 4: Floating Navigation Bar with Gradient
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 30, 30, 30),
      body: _pages()[_selectedIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFloatingNavItem(0, Icons.home_outlined, Icons.home),
              _buildFloatingNavItem(1, Icons.search_outlined, Icons.search),
              _buildFloatingNavItem(2, Icons.favorite_border, Icons.favorite),
              _buildFloatingNavItem(3, Icons.person_outline, Icons.person),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem(int index, IconData icon, IconData activeIcon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? Colors.black : Colors.grey,
          size: 24,
        ),
      ),
    );
  }

  Widget buildHomeContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Home",
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Cal_Sans',
              fontSize: 35,
              // fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
