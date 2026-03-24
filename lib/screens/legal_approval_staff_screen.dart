import 'package:flutter/material.dart';
import '../models/user.dart';
import 'apartment_approval_staff_screen.dart';

class LegalApprovalStaffScreen extends StatelessWidget {
  final User currentUser;
  final VoidCallback onLogout;

  const LegalApprovalStaffScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ApprovalTaskStaffScreen(
      currentUser: currentUser,
      onLogout: onLogout,
      stepConfig: legalApprovalConfig,
    );
  }
}
