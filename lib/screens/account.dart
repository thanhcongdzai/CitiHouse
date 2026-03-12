import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2361DB);
    const secondary = Color(0xFFF8C034);

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Profile Header ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primary, primary.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 33,
                            backgroundColor: secondary,
                            child: Text(
                              'JD',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Name & info
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'John Doe',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.email_outlined,
                                  size: 13, color: Colors.white70),
                              SizedBox(width: 4),
                              Text(
                                'johndoe@email.com',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.verified_user_outlined,
                                  size: 13, color: Colors.white70),
                              SizedBox(width: 4),
                              Text(
                                'Verified Member',
                                style: TextStyle(
                                  color: secondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined,
                          color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Quick Stats Row ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statItem('3', 'Listings', Icons.home_work_outlined),
                      _vDivider(),
                      _statItem('8', 'Saved', Icons.bookmark_outline),
                      _vDivider(),
                      _statItem('2', 'Contracts', Icons.description_outlined),
                      _vDivider(),
                      _statItem('5★', 'Rating', Icons.star_outline),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── My Transactions ──────────────────────────────────────────────
          const SizedBox(height: 12),
          _sectionCard(
            context,
            child: Column(
              children: [
                _sectionHeader(context, 'My Transactions', 'View All', primary),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _orderStatus(Icons.pending_outlined, 'Pending', primary),
                    _orderStatus(Icons.handshake_outlined, 'Negotiating', primary),
                    _orderStatus(Icons.draw_outlined, 'Signing', primary),
                    _orderStatus(Icons.check_circle_outline, 'Completed', primary),
                    _orderStatus(Icons.cancel_outlined, 'Cancelled', primary),
                  ],
                ),
              ],
            ),
          ),

          // ── Menu Items ───────────────────────────────────────────────────
          const SizedBox(height: 12),
          _sectionCard(
            context,
            child: Column(
              children: [
                _menuTile(
                  context,
                  icon: Icons.description_outlined,
                  iconColor: primary,
                  title: 'My Contracts',
                  subtitle: '2 active contracts',
                  badge: '2',
                  badgeColor: secondary,
                  onTap: () {},
                ),
                _divider(),
                _menuTile(
                  context,
                  icon: Icons.favorite_outline,
                  iconColor: Colors.redAccent,
                  title: 'Saved Properties',
                  subtitle: '8 properties saved',
                  onTap: () {},
                ),
                _divider(),
                _menuTile(
                  context,
                  icon: Icons.calendar_month_outlined,
                  iconColor: Colors.teal,
                  title: 'My Appointments',
                  subtitle: 'Schedule & history',
                  onTap: () {},
                ),
                _divider(),
                _menuTile(
                  context,
                  icon: Icons.home_work_outlined,
                  iconColor: Colors.indigo,
                  title: 'My Listings',
                  subtitle: '3 active listings',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _sectionCard(
            context,
            child: Column(
              children: [
                _menuTile(
                  context,
                  icon: Icons.wallet_outlined,
                  iconColor: Colors.green,
                  title: 'Payment Methods',
                  subtitle: 'Cards & bank accounts',
                  onTap: () {},
                ),
                _divider(),
                _menuTile(
                  context,
                  icon: Icons.notifications_outlined,
                  iconColor: const Color(0xFFF8C034),
                  title: 'Notifications',
                  subtitle: '3 unread',
                  badge: '3',
                  badgeColor: Colors.redAccent,
                  onTap: () {},
                ),
                _divider(),
                _menuTile(
                  context,
                  icon: Icons.shield_outlined,
                  iconColor: Colors.blueGrey,
                  title: 'Privacy & Security',
                  subtitle: 'Password, 2FA',
                  onTap: () {},
                ),
                _divider(),
                _menuTile(
                  context,
                  icon: Icons.help_outline,
                  iconColor: Colors.orange,
                  title: 'Help & Support',
                  subtitle: 'FAQs, contact us',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _sectionCard(
            context,
            child: _menuTile(
              context,
              icon: Icons.logout,
              iconColor: Colors.red,
              title: 'Log Out',
              titleColor: Colors.red,
              onTap: () {},
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _statItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _vDivider() => Container(
        height: 40,
        width: 1,
        color: Colors.white24,
      );

  Widget _sectionCard(BuildContext context, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: child,
      ),
    );
  }

  Widget _sectionHeader(
      BuildContext context, String title, String action, Color primary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              children: [
                Text(action,
                    style: TextStyle(
                        color: primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                Icon(Icons.chevron_right, size: 16, color: primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderStatus(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }

  Widget _menuTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    String? badge,
    Color? badgeColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(badge,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        indent: 56,
        endIndent: 16,
        thickness: 0.5,
      );
}
