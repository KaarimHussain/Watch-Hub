import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:watch_hub/screens/admin/add_watch_screen.dart';
import 'package:watch_hub/screens/admin/admin_collection_screen.dart';
import 'package:watch_hub/screens/admin/admin_home_screen.dart';
import 'package:watch_hub/screens/admin/admin_orders_screen.dart';
import 'package:watch_hub/screens/admin/admin_recent_activities_screen.dart';
import 'package:watch_hub/screens/admin/user_screen.dart';
import 'package:watch_hub/screens/admin/view_feedback.dart';
import 'package:watch_hub/screens/admin/watch_screen.dart';
import 'package:watch_hub/screens/base/login_screen.dart';
import 'package:watch_hub/screens/base/signup_screen.dart';
import 'package:watch_hub/screens/base/splash_screen.dart';
import 'package:watch_hub/screens/user/collection_screen.dart';
import 'package:watch_hub/screens/user/faq_screen.dart';
import 'package:watch_hub/screens/user/feedback_screen.dart';
import 'package:watch_hub/screens/user/home_screen.dart';
import 'package:watch_hub/screens/user/info_screen.dart';
import 'package:watch_hub/screens/user/order_screen.dart';
import 'package:watch_hub/screens/user/profile_screen.dart';
import 'package:watch_hub/screens/user/view_feedback_screen.dart';
import 'package:watch_hub/screens/user/index_screen.dart';
import 'package:watch_hub/screens/user/wishlist_screen.dart';
import 'package:watch_hub/services/auth_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCvg1_WWShLO09l-fMG9nQg5333YQIDl1k',
        appId: '1:883631800883:android:e27cdf595a623674c29946',
        messagingSenderId: '883631800883',
        projectId: 'watch-hub-1f030',
        storageBucket: 'watch-hub-1f030.firebasestorage.app',
      ),
    );
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Soft Neutral Palette Colors
    const Color lightBackground = Color(0xFFF8F9FA);
    const Color darkGray = Color(0xFF343A40);
    const Color mediumGray = Color(0xFF6C757D);
    const Color lightGray = Color(0xFFCED4DA);
    const Color accentGray = Color(0xFFADB5BD);

    return MaterialApp(
      title: 'Watch Hub - Finest Timepieces',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        // Light background instead of black
        scaffoldBackgroundColor: lightBackground,
        // Primary color scheme
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: darkGray,
          onPrimary: lightBackground,
          secondary: mediumGray,
          onSecondary: lightBackground,
          error: Colors.red.shade700,
          onError: Colors.white,
          background: lightBackground,
          onBackground: darkGray,
          surface: Colors.white,
          onSurface: darkGray,
        ),
        // Card theme
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: lightGray, width: 1),
          ),
        ),
        // AppBar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: lightBackground,
          foregroundColor: darkGray,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: darkGray,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
          iconTheme: IconThemeData(color: darkGray),
        ),
        // Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkGray,
            foregroundColor: lightBackground,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        // Text theme
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: darkGray),
          displayMedium: TextStyle(color: darkGray),
          displaySmall: TextStyle(color: darkGray),
          headlineLarge: TextStyle(color: darkGray),
          headlineMedium: TextStyle(color: darkGray),
          headlineSmall: TextStyle(color: darkGray),
          titleLarge: TextStyle(color: darkGray),
          titleMedium: TextStyle(color: darkGray),
          titleSmall: TextStyle(color: darkGray),
          bodyLarge: TextStyle(color: darkGray),
          bodyMedium: TextStyle(color: mediumGray),
          bodySmall: TextStyle(color: mediumGray),
          labelLarge: TextStyle(color: darkGray),
          labelMedium: TextStyle(color: mediumGray),
          labelSmall: TextStyle(color: mediumGray),
        ),
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: lightGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: lightGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: darkGray),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.red),
          ),
          labelStyle: TextStyle(color: mediumGray),
          hintStyle: TextStyle(color: accentGray),
        ),
        // Divider theme
        dividerTheme: DividerThemeData(
          color: lightGray,
          thickness: 1,
          space: 24,
        ),
        // Icon theme
        iconTheme: IconThemeData(color: mediumGray, size: 24),
        // Bottom navigation bar theme
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: darkGray,
          unselectedItemColor: mediumGray,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          elevation: 8,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      initialRoute: '/',
      routes: {
        // base routes
        '/': (context) => SplashScreen(),
        '/auth': (context) => AuthPage(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
        // user routes
        '/user_index': (context) => IndexScreen(),
        '/user_home': (context) => HomeScreen(),
        '/user_wishlist': (context) => WishlistScreen(),
        '/user_profile': (context) => ProfileScreen(),
        '/user_feedback': (context) => FeedbackScreen(),
        '/user_info': (context) => InformationScreen(),
        '/user_faq': (context) => FAQScreen(),
        '/view_feedback': (context) => ViewFeedbackScreen(),
        '/user_orders': (context) => OrdersScreen(),
        '/user_collection': (context) => CollectionScreen(),
        // admin routes
        '/admin_home': (context) => AdminHomeScreen(),
        '/admin_watch': (context) => WatchScreen(),
        '/admin_add_watch': (context) => AddWatchScreen(),
        '/admin_view_feedback': (context) => ViewFeedback(),
        '/admin_user': (context) => UserListScreen(),
        '/admin_collection': (context) => AdminCollectionScreen(),
        '/admin_orders': (context) => AdminOrdersScreen(),
        '/admin_recent_activities': (context) => RecentActivitiesScreen(),
      },
    );
  }
}
