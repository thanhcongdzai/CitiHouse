import 'package:flutter/material.dart';

import '../models/user.dart';
import 'admin_screen.dart';
import 'deposit_approval_staff_screen.dart';
import 'image_approval_staff_screen.dart';
import 'legal_approval_staff_screen.dart';
import 'on_site_staff_screen.dart';
import 'owner_approval_staff_screen.dart';
import 'staff_approval_screen.dart';

class StaffDrawer extends StatelessWidget {
  final User currentUser;
  final VoidCallback onLogout;
  final VoidCallback? onRegistrationApprovalsTapped;
  final VoidCallback? onAccountActivationTapped;
  final VoidCallback? onAllJobsTapped;
  final VoidCallback? onMyJobsTapped;
  final VoidCallback? onCompletedJobsTapped;
  final VoidCallback? onDepositRequestedTapped;
  final VoidCallback? onAdminViewingStatsTapped;
  final VoidCallback? onAdminDepositStatsTapped;
  final VoidCallback? onPendingDepositsTapped;
  final VoidCallback? onApprovedDepositsTapped;
  final bool isRegistrationApprovalsSelected;
  final bool isAccountActivationSelected;
  final bool isMyJobsSelected;
  final bool isCompletedJobsSelected;
  final bool isDepositRequestedSelected;
  final bool isAdminViewingStatsSelected;
  final bool isAdminDepositStatsSelected;
  final bool isPendingDepositsSelected;
  final bool isApprovedDepositsSelected;

  const StaffDrawer({
    super.key,
    required this.currentUser,
    required this.onLogout,
    this.onRegistrationApprovalsTapped,
    this.onAccountActivationTapped,
    this.onAllJobsTapped,
    this.onMyJobsTapped,
    this.onCompletedJobsTapped,
    this.onDepositRequestedTapped,
    this.onAdminViewingStatsTapped,
    this.onAdminDepositStatsTapped,
    this.onPendingDepositsTapped,
    this.onApprovedDepositsTapped,
    this.isRegistrationApprovalsSelected = false,
    this.isAccountActivationSelected = false,
    this.isMyJobsSelected = false,
    this.isCompletedJobsSelected = false,
    this.isDepositRequestedSelected = false,
    this.isAdminViewingStatsSelected = false,
    this.isAdminDepositStatsSelected = false,
    this.isPendingDepositsSelected = false,
    this.isApprovedDepositsSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color.fromRGBO(35, 97, 219, 1);
    final fullName = '${currentUser.firstName} ${currentUser.lastName}'.trim();
    final displayName = fullName.isNotEmpty ? fullName : 'User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    final isAllJobsSelected = !isMyJobsSelected &&
        !isCompletedJobsSelected &&
        !isDepositRequestedSelected &&
        !isAdminViewingStatsSelected &&
        !isAdminDepositStatsSelected &&
        !isPendingDepositsSelected &&
        !isApprovedDepositsSelected &&
        !isRegistrationApprovalsSelected &&
        !isAccountActivationSelected;

    void goTo(Widget screen) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => screen),
      );
    }

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: primaryBlue),
            accountName: Text(
              displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(
              currentUser.role == 'onSiteStaff'
                  ? 'Consultant On-Site'
                  : currentUser.role == 'accountStaff'
                      ? 'Account Approval Staff'
                      : currentUser.role == 'admin'
                          ? 'Administrator'
                          : currentUser.role == 'depositApprovalStaff'
                              ? 'Deposit Approval Staff'
                              : currentUser.role == 'imageApprovalStaff'
                                  ? 'Image Approval Staff'
                                  : currentUser.role == 'legalApprovalStaff'
                                      ? 'Legal Approval Staff'
                                      : currentUser.role == 'ownerApprovalStaff'
                                          ? 'Owner Approval Staff'
                                          : currentUser.role ==
                                                  'apartmentApprovalStaff'
                                              ? 'Post Approval Staff'
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
                ListTile(
                  leading: const Icon(Icons.phone_rounded, color: Colors.grey),
                  title: Text(
                    currentUser.phone.isNotEmpty
                        ? currentUser.phone
                        : 'Phone not updated',
                  ),
                  dense: true,
                ),
                ListTile(
                  leading: const Icon(Icons.email_rounded, color: Colors.grey),
                  title: Text(
                    currentUser.email.isNotEmpty
                        ? currentUser.email
                        : 'Email not updated',
                  ),
                  dense: true,
                ),
                const Divider(),
                if (currentUser.role == 'admin') ...[
                  ListTile(
                    leading: Icon(
                      Icons.pie_chart_rounded,
                      color: isAdminViewingStatsSelected
                          ? primaryBlue
                          : Colors.black87,
                    ),
                    title: Text(
                      'Viewing Completion Rate',
                      style: TextStyle(
                        fontWeight: isAdminViewingStatsSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isAdminViewingStatsSelected
                            ? primaryBlue
                            : Colors.black87,
                      ),
                    ),
                    selected: isAdminViewingStatsSelected,
                    selectedTileColor: primaryBlue.withOpacity(0.05),
                    onTap: onAdminViewingStatsTapped ??
                        () => goTo(
                              AdminScreen(
                                currentUser: currentUser,
                                onLogout: onLogout,
                              ),
                            ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.monetization_on_rounded,
                      color: isAdminDepositStatsSelected
                          ? primaryBlue
                          : Colors.black87,
                    ),
                    title: Text(
                      'Deposit Request Rate',
                      style: TextStyle(
                        fontWeight: isAdminDepositStatsSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isAdminDepositStatsSelected
                            ? primaryBlue
                            : Colors.black87,
                      ),
                    ),
                    selected: isAdminDepositStatsSelected,
                    selectedTileColor: primaryBlue.withOpacity(0.05),
                    onTap: onAdminDepositStatsTapped ??
                        () => goTo(
                              AdminScreen(
                                currentUser: currentUser,
                                onLogout: onLogout,
                              ),
                            ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.verified_user_rounded),
                    title: const Text('Approve tài khoản'),
                    onTap: () => goTo(
                      StaffApprovalScreen(
                        currentUser: currentUser,
                        onLogout: onLogout,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.image_rounded),
                    title: const Text('Duyệt hình ảnh'),
                    onTap: () => goTo(
                      ImageApprovalStaffScreen(
                        currentUser: currentUser,
                        onLogout: onLogout,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.gavel_rounded),
                    title: const Text('Duyệt pháp lý'),
                    onTap: () => goTo(
                      LegalApprovalStaffScreen(
                        currentUser: currentUser,
                        onLogout: onLogout,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.verified_user_rounded),
                    title: const Text('Duyệt chủ nhà'),
                    onTap: () => goTo(
                      OwnerApprovalStaffScreen(
                        currentUser: currentUser,
                        onLogout: onLogout,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.event_available_rounded),
                    title: const Text('Xử lý lịch hẹn xem nhà'),
                    onTap: () => goTo(
                      OnSiteStaffScreen(
                        currentUser: currentUser,
                        onLogout: onLogout,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.request_quote_rounded),
                    title: const Text('Approve Deposits'),
                    onTap: () => goTo(
                      DepositApprovalStaffScreen(
                        currentUser: currentUser,
                        onLogout: onLogout,
                      ),
                    ),
                  ),
                  const Divider(),
                ],
                if (currentUser.role == 'accountStaff') ...[
                  ListTile(
                    leading: Icon(
                      Icons.person_add_alt_1_rounded,
                      color: isRegistrationApprovalsSelected
                          ? primaryBlue
                          : Colors.black87,
                    ),
                    title: Text(
                      'Phê duyệt đăng ký',
                      style: TextStyle(
                        fontWeight: isRegistrationApprovalsSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isRegistrationApprovalsSelected
                            ? primaryBlue
                            : Colors.black87,
                      ),
                    ),
                    selected: isRegistrationApprovalsSelected,
                    selectedTileColor: primaryBlue.withOpacity(0.05),
                    onTap: onRegistrationApprovalsTapped ??
                        () => goTo(
                              StaffApprovalScreen(
                                currentUser: currentUser,
                                onLogout: onLogout,
                                initialTab:
                                    StaffApprovalTab.registrationApproval,
                              ),
                            ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.badge_rounded,
                      color: isAccountActivationSelected
                          ? primaryBlue
                          : Colors.black87,
                    ),
                    title: Text(
                      'Kích hoạt tài khoản',
                      style: TextStyle(
                        fontWeight: isAccountActivationSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isAccountActivationSelected
                            ? primaryBlue
                            : Colors.black87,
                      ),
                    ),
                    selected: isAccountActivationSelected,
                    selectedTileColor: primaryBlue.withOpacity(0.05),
                    onTap: onAccountActivationTapped ??
                        () => goTo(
                              StaffApprovalScreen(
                                currentUser: currentUser,
                                onLogout: onLogout,
                                initialTab:
                                    StaffApprovalTab.accountActivation,
                              ),
                            ),
                  ),
                  const Divider(),
                ],
                if (currentUser.role == 'depositApprovalStaff') ...[
                  ListTile(
                    leading: Icon(
                      Icons.pending_actions_rounded,
                      color: isPendingDepositsSelected
                          ? primaryBlue
                          : Colors.black87,
                    ),
                    title: Text(
                      'Pending Approval',
                      style: TextStyle(
                        fontWeight: isPendingDepositsSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isPendingDepositsSelected
                            ? primaryBlue
                            : Colors.black87,
                      ),
                    ),
                    selected: isPendingDepositsSelected,
                    selectedTileColor: primaryBlue.withOpacity(0.05),
                    onTap: onPendingDepositsTapped,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.check_circle_outline_rounded,
                      color: isApprovedDepositsSelected
                          ? primaryBlue
                          : Colors.black87,
                    ),
                    title: Text(
                      'Approved',
                      style: TextStyle(
                        fontWeight: isApprovedDepositsSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isApprovedDepositsSelected
                            ? primaryBlue
                            : Colors.black87,
                      ),
                    ),
                    selected: isApprovedDepositsSelected,
                    selectedTileColor: primaryBlue.withOpacity(0.05),
                    onTap: onApprovedDepositsTapped,
                  ),
                  const Divider(),
                ],
                if (currentUser.role == 'onSiteStaff' ||
                    currentUser.role == 'apartmentApprovalStaff' ||
                    currentUser.role == 'imageApprovalStaff' ||
                    currentUser.role == 'legalApprovalStaff' ||
                    currentUser.role == 'ownerApprovalStaff') ...[
                  ListTile(
                    leading: Icon(
                      Icons.list_alt_rounded,
                      color: isAllJobsSelected ? primaryBlue : Colors.black87,
                    ),
                    title: Text(
                      'Available Jobs',
                      style: TextStyle(
                        fontWeight: isAllJobsSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
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
                      'Accepted Jobs',
                      style: TextStyle(
                        fontWeight: isMyJobsSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isMyJobsSelected ? primaryBlue : Colors.black87,
                      ),
                    ),
                    selected: isMyJobsSelected,
                    selectedTileColor: primaryBlue.withOpacity(0.05),
                    onTap: onMyJobsTapped,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.task_alt_rounded,
                      color: isCompletedJobsSelected
                          ? primaryBlue
                          : Colors.black87,
                    ),
                    title: Text(
                      'Completed Jobs',
                      style: TextStyle(
                        fontWeight: isCompletedJobsSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCompletedJobsSelected
                            ? primaryBlue
                            : Colors.black87,
                      ),
                    ),
                    selected: isCompletedJobsSelected,
                    selectedTileColor: primaryBlue.withOpacity(0.05),
                    onTap: onCompletedJobsTapped,
                  ),
                  if (currentUser.role == 'onSiteStaff')
                    ListTile(
                      leading: Icon(
                        Icons.monetization_on_outlined,
                        color: isDepositRequestedSelected
                            ? primaryBlue
                            : Colors.black87,
                      ),
                      title: Text(
                        'Deposit Requested',
                        style: TextStyle(
                          fontWeight: isDepositRequestedSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isDepositRequestedSelected
                              ? primaryBlue
                              : Colors.black87,
                        ),
                      ),
                      selected: isDepositRequestedSelected,
                      selectedTileColor: primaryBlue.withOpacity(0.05),
                      onTap: onDepositRequestedTapped,
                    ),
                  const Divider(),
                ],
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: const Text(
              'Log out',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              onLogout();
              Navigator.of(context, rootNavigator: true)
                  .popUntil((route) => route.isFirst);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
