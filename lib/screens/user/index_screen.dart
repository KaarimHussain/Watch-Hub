import 'package:flutter/material.dart';
import 'package:watch_hub/screens/user/cart_screen.dart';
import 'package:watch_hub/screens/user/home_screen.dart';
import 'package:watch_hub/screens/user/profile_screen.dart';
import 'package:watch_hub/screens/user/search_screen.dart';
import 'package:watch_hub/screens/user/wishlist_screen.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({super.key});

  @override
  State<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  // Controllers
  final _searchBarController = TextEditingController();

  int _selectedIndex = 0;

  @override
  void dispose() {
    _searchBarController.dispose();
    super.dispose();
  }

  List<Widget> _pages() => [
    const HomeScreen(),
    const SearchScreen(),
    const CartScreen(),
    const WishlistScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _pages()[_selectedIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          top: 20,
          left: 16,
          right: 16,
          bottom: 20,
        ),
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: theme.bottomNavigationBarTheme.backgroundColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.3),
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
              _buildFloatingNavItem(
                2,
                Icons.shopping_cart_outlined,
                Icons.shopping_cart,
              ),
              _buildFloatingNavItem(3, Icons.bookmark_outline, Icons.bookmark),
              _buildFloatingNavItem(4, Icons.person_outline, Icons.person),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem(int index, IconData icon, IconData activeIcon) {
    final theme = Theme.of(context);
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF000000), // Pure black
                    Color(0xFF333333), // Dark gray
                    Color(0xFF555555), // Medium gray
                  ],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected
              ? Colors.white
              : theme.bottomNavigationBarTheme.unselectedItemColor,
          size: 24,
        ),
      ),
    );
  }
}
