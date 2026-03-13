import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'screens/dashboard.dart';
import 'screens/news.dart';
import 'screens/service_screen.dart';
import 'screens/account.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'models/user.dart';

void main() {
  runApp(const RealEstateApp());
}

class RealEstateApp extends StatelessWidget {
  const RealEstateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CitiHouse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2361DB),
          primary: const Color(0xFF2361DB),
          secondary: const Color(0xFFF8C034),
          secondaryContainer: const Color(0xFFF8C034),
          onSecondaryContainer: Colors.black87,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  User? _currentUser;
  bool _authChecked = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final userId = await AuthService.getLoggedInUserId();
    if (userId != null && userId.isNotEmpty) {
      await _fetchAndSetUser(userId);
    } else {
      if (mounted) setState(() => _authChecked = true);
    }
  }

  Future<void> _fetchAndSetUser(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/users/$userId/'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (mounted) {
          setState(() {
            _currentUser = User.fromJson(data);
            _authChecked = true;
          });
        }
      } else {
        // Invalid session, clear it
        await AuthService.logout();
        if (mounted) setState(() => _authChecked = true);
      }
    } catch (_) {
      if (mounted) setState(() => _authChecked = true);
    }
  }

  Future<void> _handleLoginSuccess() async {
    // Reload user from SharedPreferences then fetch from API
    final userId = await AuthService.getLoggedInUserId();
    if (userId != null && userId.isNotEmpty) {
      await _fetchAndSetUser(userId);
    }
    // Navigate to dashboard after successful login
    if (mounted) {
      setState(() {
        _selectedIndex = 0;
      });
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      setState(() {
        _currentUser = null;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_authChecked) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2361DB)),
        ),
      );
    }

    final List<Widget> widgetOptions = [
      DashboardScreen(currentUser: _currentUser),
      const NewsScreen(),
      const ServiceScreen(),
      AccountScreen(
        currentUser: _currentUser,
        onLogout: _handleLogout,
        onLoginTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoginScreen(
                onLoginSuccess: _handleLoginSuccess,
              ),
            ),
          );
        },
      ),
    ];

    return Scaffold(
      body: widgetOptions[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
        selectedIndex: _selectedIndex,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Dashboard',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.article),
            icon: Icon(Icons.article_outlined),
            label: 'News',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.design_services),
            icon: Icon(Icons.design_services_outlined),
            label: 'Service',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.person),
            icon: Icon(Icons.person_outline),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
