import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'my_appointments_screen.dart';
import 'my_deposit_orders_screen.dart';
import 'upload_avatar_screen.dart';

class AccountScreen extends StatefulWidget {
  final User? currentUser;
  final VoidCallback onLogout;

  const AccountScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  static const primary = Color(0xFF2361DB);
  static const secondary = Color(0xFFF8C034);

  int _depositOrderCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDepositOrderCount();
  }

  Future<void> _fetchDepositOrderCount() async {
    final userId = widget.currentUser?.id;
    if (userId == null || userId.isEmpty) return;
    try {
      final res = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/deposit-orders/buyer/$userId/'),
      );
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes)) as List<dynamic>;
        if (mounted) {
          setState(() {
            _depositOrderCount = data.length;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return _buildLoggedInView(context);
  }

  // ─── Logged In ───────────────────────────────────────────────────────────

  Widget _buildLoggedInView(BuildContext context) {
    final user = widget.currentUser!;
    final initials = '${user.firstName.isNotEmpty ? user.firstName[0] : ''}'
        '${user.lastName.isNotEmpty ? user.lastName[0] : ''}'.toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primary, Color(0xFF1A4BBE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Avatar
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UploadAvatarScreen(currentUser: user),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 38,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 34,
                                    backgroundColor: secondary,
                                    backgroundImage: (user.image != null && user.image!.isNotEmpty)
                                        ? NetworkImage(user.image!)
                                        : null,
                                    child: (user.image == null || user.image!.isEmpty)
                                        ? Text(
                                            initials,
                                            style: const TextStyle(
                                                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    width: 16, height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${user.firstName} ${user.lastName}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.email_outlined, size: 13, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        user.email,
                                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: secondary.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: secondary, width: 1),
                                  ),
                                  child: Text(
                                    user.role,
                                    style: const TextStyle(
                                        color: secondary, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Quick stats
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _statItem('0', 'Listings', Icons.home_work_outlined),
                            _vDivider(),
                            _statItem('0', 'Saved', Icons.bookmark_outline),
                            _vDivider(),
                            _statItem('0', 'Contracts', Icons.description_outlined),
                            _vDivider(),
                            _statItem('-', 'Rating', Icons.star_outline),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Info Card ─────────────────────────────────────────────────
            _sectionCard(
              child: Column(
                children: [
                  _infoRow(Icons.phone_android_rounded, 'Phone', user.phone, Colors.teal),
                  _divider(),
                  _infoRow(Icons.cake_outlined, 'Date of Birth', user.dob, Colors.orange),
                  _divider(),
                  _infoRow(Icons.badge_outlined, 'CCCD', user.cccd, Colors.indigo),
                  _divider(),
                  _infoRow(Icons.person_outline_rounded, 'Gender', user.gender, Colors.pink),
                  _divider(),
                  _infoRow(Icons.home_outlined, 'Address', user.address, Colors.green),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── My Transactions ───────────────────────────────────────────
            _sectionCard(
              child: Column(
                children: [
                  _sectionHeader('My Transactions', 'View All'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _orderStatus(context, Icons.pending_outlined, 'Pending', primary, onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MyDepositOrdersScreen(userId: user.id),
                          ),
                        ).then((_) => _fetchDepositOrderCount());
                      }, badgeCount: _depositOrderCount),
                      _orderStatus(context, Icons.handshake_outlined, 'Negotiating', primary),
                      _orderStatus(context, Icons.draw_outlined, 'Signing', primary),
                      _orderStatus(context, Icons.check_circle_outline, 'Completed', primary),
                      _orderStatus(context, Icons.cancel_outlined, 'Cancelled', primary),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Menu ─────────────────────────────────────────────────────
            _sectionCard(
              child: Column(
                children: [
                  _menuTile(Icons.favorite_outline, Colors.redAccent, 'My Properties', 'Your apartments'),
                  _divider(),
                  _menuTile(Icons.calendar_month_outlined, Colors.teal, 'My Appointments', 'Schedule & history', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => MyAppointmentsScreen(userId: user.id)));
                  }),
                  _divider(),
                  _menuTile(Icons.home_work_outlined, Colors.indigo, 'My Listings', 'Manage your properties'),
                  _divider(),
                  _menuTile(Icons.notifications_outlined, secondary, 'Notifications', ''),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Logout ───────────────────────────────────────────────────
            _sectionCard(
              child: ListTile(
                onTap: () => _confirmLogout(context),
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout, color: Colors.red, size: 22),
                ),
                title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _statItem(String value, String label, IconData icon) => Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      );

  Widget _vDivider() => Container(height: 40, width: 1, color: Colors.white24);

  Widget _sectionCard({required Widget child}) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: child,
        ),
      );

  Widget _sectionHeader(String title, String action) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                children: [
                  Text('View All', style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right, size: 16, color: primary),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _infoRow(IconData icon, String label, String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      );

  Widget _orderStatus(BuildContext context, IconData icon, String label, Color color, {VoidCallback? onTap, int badgeCount = 0}) => GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: onTap != null ? color.withOpacity(0.15) : color.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: onTap != null ? Border.all(color: color.withOpacity(0.3), width: 1.5) : null,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
          ],
        ),
      );

  Widget _menuTile(IconData icon, Color color, String title, String subtitle, {VoidCallback? onTap}) => ListTile(
        onTap: onTap ?? () {},
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey))
            : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      );

  Widget _divider() => const Divider(height: 1, indent: 56, endIndent: 16, thickness: 0.5);
}
