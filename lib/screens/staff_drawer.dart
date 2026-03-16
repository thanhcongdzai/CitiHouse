// Helper widget for staff drawer
import 'package:flutter/material.dart';
import '../models/user.dart';

class StaffDrawer extends StatelessWidget {
  final User currentUser;
  final VoidCallback onLogout;
  final VoidCallback? onAllJobsTapped;
  final VoidCallback? onMyJobsTapped;
  final VoidCallback? onCompletedJobsTapped;
  final VoidCallback? onDepositRequestedTapped;
  final VoidCallback? onAdminViewingStatsTapped;
  final VoidCallback? onAdminDepositStatsTapped;
  final bool isMyJobsSelected;
  final bool isCompletedJobsSelected;
  final bool isDepositRequestedSelected;
  final bool isAdminViewingStatsSelected;
  final bool isAdminDepositStatsSelected;

  const StaffDrawer({
    super.key,
    required this.currentUser,
    required this.onLogout,
    this.onAllJobsTapped,
    this.onMyJobsTapped,
    this.onCompletedJobsTapped,
    this.onDepositRequestedTapped,
    this.onAdminViewingStatsTapped,
    this.onAdminDepositStatsTapped,
    this.isMyJobsSelected = false,
    this.isCompletedJobsSelected = false,
    this.isDepositRequestedSelected = false,
    this.isAdminViewingStatsSelected = false,
    this.isAdminDepositStatsSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color.fromRGBO(35, 97, 219, 1);
    final fullName = '${currentUser.firstName} ${currentUser.lastName}'.trim();
    final displayName = fullName.isNotEmpty ? fullName : 'Người Dùng';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    // Helper boolean
    final isAllJobsSelected = !isMyJobsSelected && !isCompletedJobsSelected && !isDepositRequestedSelected && !isAdminViewingStatsSelected && !isAdminDepositStatsSelected;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: primaryBlue,
            ),
            accountName: Text(
              displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(
              currentUser.role == 'onSiteStaff'
                  ? 'Nhân viên tư vấn On-Site'
                  : currentUser.role == 'accountStaff'
                      ? 'Nhân viên duyệt tài khoản'
                      : currentUser.role == 'admin'
                          ? 'Quản trị viên'
                          : currentUser.role,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: const TextStyle(
                  color: primaryBlue,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Display user contact info
                ListTile(
                  leading: const Icon(Icons.phone_rounded, color: Colors.grey),
                  title: Text(currentUser.phone.isNotEmpty ? currentUser.phone : 'Chưa cập nhật SĐT'),
                  dense: true,
                ),
                ListTile(
                  leading: const Icon(Icons.email_rounded, color: Colors.grey),
                  title: Text(currentUser.email.isNotEmpty ? currentUser.email : 'Chưa cập nhật Email'),
                  dense: true,
                ),
                const Divider(),
                
                // Add conditional tabs based on role and callbacks
                if (currentUser.role == 'admin') ...[
                  ListTile(
                    leading: Icon(
                      Icons.pie_chart_rounded,
                      color: isAdminViewingStatsSelected ? primaryBlue : Colors.black87,
                    ),
                    title: Text(
                      'Tỷ lệ xem nhà hoàn thành',
                      style: TextStyle(
                        fontWeight: isAdminViewingStatsSelected ? FontWeight.bold : FontWeight.normal,
                        color: isAdminViewingStatsSelected ? primaryBlue : Colors.black87,
                      ),
                    ),
                    selected: isAdminViewingStatsSelected,
                    selectedTileColor: primaryBlue.withOpacity(0.05),
                    onTap: onAdminViewingStatsTapped,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.monetization_on_rounded,
                      color: isAdminDepositStatsSelected ? primaryBlue : Colors.black87,
                    ),
                    title: Text(
                      'Tỷ lệ yêu cầu cọc',
                      style: TextStyle(
                        fontWeight: isAdminDepositStatsSelected ? FontWeight.bold : FontWeight.normal,
                        color: isAdminDepositStatsSelected ? primaryBlue : Colors.black87,
                      ),
                    ),
                    selected: isAdminDepositStatsSelected,
                    selectedTileColor: primaryBlue.withOpacity(0.05),
                    onTap: onAdminDepositStatsTapped,
                  ),
                  const Divider(),
                ],

                if (currentUser.role == 'onSiteStaff' || currentUser.role == 'apartmentApprovalStaff') ...[
                  ListTile(
                    leading: Icon(
                      Icons.list_alt_rounded,
                      color: isAllJobsSelected ? primaryBlue : Colors.black87,
                    ),
                    title: Text(
                      'Công việc hiện có',
                      style: TextStyle(
                        fontWeight: isAllJobsSelected ? FontWeight.bold : FontWeight.normal,
                        color: isAllJobsSelected ? primaryBlue : Colors.black87,
                      ),
                    ),
                    selected: isAllJobsSelected,
                    selectedTileColor: primaryBlue.withOpacity(0.05),
                    onTap: onAllJobsTapped,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.work_outline_rounded,
                      color: isMyJobsSelected ? primaryBlue : Colors.black87,
                    ),
                    title: Text(
                      'Công việc đã nhận',
                      style: TextStyle(
                        fontWeight: isMyJobsSelected ? FontWeight.bold : FontWeight.normal,
                        color: isMyJobsSelected ? primaryBlue : Colors.black87,
                      ),
                    ),
                    selected: isMyJobsSelected,
                    selectedTileColor: primaryBlue.withOpacity(0.05),
                    onTap: onMyJobsTapped,
                  ),
                  
                  // Only show "Hoàn thành" and "Đã yêu cầu cọc" tabs for onSiteStaff
                  if (currentUser.role == 'onSiteStaff') ...[
                    ListTile(
                      leading: Icon(
                        Icons.task_alt_rounded,
                        color: isCompletedJobsSelected ? primaryBlue : Colors.black87,
                      ),
                      title: Text(
                        'Công việc đã hoàn thành',
                        style: TextStyle(
                          fontWeight: isCompletedJobsSelected ? FontWeight.bold : FontWeight.normal,
                          color: isCompletedJobsSelected ? primaryBlue : Colors.black87,
                        ),
                      ),
                      selected: isCompletedJobsSelected,
                      selectedTileColor: primaryBlue.withOpacity(0.05),
                      onTap: onCompletedJobsTapped,
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.monetization_on_outlined,
                        color: isDepositRequestedSelected ? primaryBlue : Colors.black87,
                      ),
                      title: Text(
                        'Đã yêu cầu cọc',
                        style: TextStyle(
                          fontWeight: isDepositRequestedSelected ? FontWeight.bold : FontWeight.normal,
                          color: isDepositRequestedSelected ? primaryBlue : Colors.black87,
                        ),
                      ),
                      selected: isDepositRequestedSelected,
                      selectedTileColor: primaryBlue.withOpacity(0.05),
                      onTap: onDepositRequestedTapped,
                    ),
                  ],
                    
                  const Divider(),
                ],
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: onLogout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
