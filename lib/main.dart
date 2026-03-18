import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'screens/dashboard.dart';
import 'screens/news.dart';
import 'screens/service_screen.dart';
import 'screens/account.dart';
import 'screens/login_screen.dart';
import 'screens/on_site_staff_screen.dart';
import 'screens/staff_approval_screen.dart';
import 'screens/apartment_approval_staff_screen.dart';
import 'screens/deposit_approval_staff_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/post_apartment_screen.dart';
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

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  User? _currentUser;
  bool _authChecked = false;
  late final AnimationController _centerButtonController;
  late final Animation<double> _centerPulse;
  bool _isCenterPressed = false;

  @override
  void initState() {
    super.initState();
    _centerButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _centerPulse = CurvedAnimation(
      parent: _centerButtonController,
      curve: Curves.easeInOut,
    );
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _centerButtonController.dispose();
    super.dispose();
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
    // Still loading auth state — show splash
    if (!_authChecked) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2361DB)),
        ),
      );
    }

    // Not logged in → show login as the root screen
    if (_currentUser == null) {
      return LoginScreen(onLoginSuccess: _handleLoginSuccess);
    }

    // accountStaff role → show staff approval screen directly
    if (_currentUser!.role == 'accountStaff') {
      return StaffApprovalScreen(currentUser: _currentUser!, onLogout: _handleLogout);
    }
    
    // onSiteStaff role → show on site staff screen directly
    if (_currentUser!.role == 'onSiteStaff') {
      return OnSiteStaffScreen(currentUser: _currentUser!, onLogout: _handleLogout);
    }
    
    // apartmentApprovalStaff role → show apartment approval staff screen directly
    if (_currentUser!.role == 'apartmentApprovalStaff') {
      return ApartmentApprovalStaffScreen(currentUser: _currentUser!, onLogout: _handleLogout);
    }

    // depositApprovalStaff role → show deposit approval staff screen directly
    if (_currentUser!.role == 'depositApprovalStaff') {
      return DepositApprovalStaffScreen(currentUser: _currentUser!, onLogout: _handleLogout);
    }

    // admin role → show admin screen directly
    if (_currentUser!.role == 'admin') {
      return AdminScreen(currentUser: _currentUser!, onLogout: _handleLogout);
    }

    // Logged in → show main app with bottom navigation
    final List<Widget> widgetOptions = [
      DashboardScreen(currentUser: _currentUser),
      const NewsScreen(),
      const ServiceScreen(),
      AccountScreen(
        currentUser: _currentUser,
        onLogout: _handleLogout,
      ),
    ];

    return Scaffold(
      body: widgetOptions[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    const Color primaryBlue = Color.fromRGBO(35, 97, 219, 1);
    const Color accentYellow = Color.fromRGBO(248, 192, 52, 1);

    Widget navItem(int index, IconData icon, IconData selectedIcon, String label) {
      final bool selected = _selectedIndex == index;
      return InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? selectedIcon : icon,
                color: selected ? Colors.white : Colors.white.withOpacity(0.6),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: primaryBlue,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Left + Right nav items
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  navItem(0, Icons.home_outlined, Icons.home, 'Dashboard'),
                  navItem(1, Icons.article_outlined, Icons.article, 'News'),
                  const SizedBox(width: 72), // space for center button
                  navItem(2, Icons.design_services_outlined, Icons.design_services, 'Service'),
                  navItem(3, Icons.person_outline, Icons.person, 'Account'),
                ],
              ),
              // Center prominent + button with 3D + multi-layer glow animation
              Positioned(
                top: -20,
                child: AnimatedBuilder(
                  animation: _centerPulse,
                  builder: (context, child) {
                    final double baseScale = 1.0;
                    final double idlePulse = 0.03 * _centerPulse.value;
                    final double pressOffset = _isCenterPressed ? -0.08 : 0.0;
                    final double scale = baseScale + idlePulse + pressOffset;

                    return GestureDetector(
                      onTapDown: (_) {
                        setState(() {
                          _isCenterPressed = true;
                        });
                      },
                      onTapUp: (_) {
                        setState(() {
                          _isCenterPressed = false;
                        });
                      },
                      onTapCancel: () {
                        setState(() {
                          _isCenterPressed = false;
                        });
                      },
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostApartmentScreen(currentUser: _currentUser),
                          ),
                        );
                      },
                      child: Transform.scale(
                        scale: scale.clamp(0.88, 1.10),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // rotating soft white layers (elliptical glow)
                              Transform.rotate(
                                angle: 2 * 3.1415926 * _centerPulse.value,
                                child: Container(
                                  width: 78,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(40),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.24),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              Transform.rotate(
                                angle: -2 * 3.1415926 * (_centerPulse.value * 0.7),
                                child: Container(
                                  width: 70,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(40),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.16),
                                      width: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              Transform.rotate(
                                angle: 2 * 3.1415926 * (_centerPulse.value * 0.4),
                                child: Container(
                                  width: 64,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(40),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.12),
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                              // main 3D button
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primaryBlue,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color.fromRGBO(60, 124, 240, 1),
                                      Color.fromRGBO(22, 74, 185, 1),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: accentYellow.withOpacity(0.55 + 0.25 * _centerPulse.value),
                                      blurRadius: 20 + 6 * _centerPulse.value,
                                      spreadRadius: 1.5 + 2 * _centerPulse.value,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: accentYellow,
                                  size: 34,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
