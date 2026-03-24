import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/user.dart';
import 'staff_drawer.dart';

enum StaffApprovalTab { registrationApproval, accountActivation }

class StaffApprovalScreen extends StatefulWidget {
  final User currentUser;
  final VoidCallback onLogout;
  final StaffApprovalTab initialTab;

  const StaffApprovalScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
    this.initialTab = StaffApprovalTab.registrationApproval,
  });

  @override
  State<StaffApprovalScreen> createState() => _StaffApprovalScreenState();
}

class _StaffApprovalScreenState extends State<StaffApprovalScreen> {
  static const primaryBlue = Color.fromRGBO(35, 97, 219, 1);
  static const accentYellow = Color.fromRGBO(248, 192, 52, 1);

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;
  late StaffApprovalTab _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(ApiConfig.uri('/api/users/'));
      if (response.statusCode == 200) {
        final List<dynamic> all = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _users = all.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _registrationUsers => _users
      .where(
        (u) => u['isActive'] == false,
      )
      .toList();

  List<Map<String, dynamic>> get _activationUsers => _users
      .where(
        (u) =>
            _extractCccdImages(u).isNotEmpty &&
            (u['status']?.toString().trim() ?? '') == 'Pending',
      )
      .toList();

  List<String> _extractCccdImages(Map<String, dynamic> user) {
    final raw = user['cccdImage']?.toString() ?? '';
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _approveUser(Map<String, dynamic> user) async {
    final userId = user['id']?.toString() ?? '';
    final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    if (userId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xác nhận phê duyệt',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Bạn có chắc muốn phê duyệt tài khoản "$name" không?',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final updated = Map<String, dynamic>.from(user);
      updated['isActive'] = true;
      updated['status'] = 'Approved';

      final response = await http.put(
        ApiConfig.uri('/api/users/$userId/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updated),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã duyệt tài khoản $name'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _fetchUsers();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectUser(Map<String, dynamic> user) async {
    final userId = user['id']?.toString() ?? '';
    final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    if (userId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm từ chối',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Bạn có chắc muốn từ chối và xóa tài khoản của "$name" không?\n\nHành động này không thể hoàn tác!',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Từ Chối & Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.delete(ApiConfig.uri('/api/users/$userId/'));

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Từ chối và xóa tài khoản "$name"'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _fetchUsers();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openCccdImages(Map<String, dynamic> user) {
    final images = _extractCccdImages(user);
    if (images.isEmpty) return;

    final userName =
        '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CccdImageViewerScreen(
          images: images,
          userName: userName,
        ),
      ),
    );
  }

  String get _screenTitle =>
      _selectedTab == StaffApprovalTab.registrationApproval
          ? 'Phê duyệt đăng ký'
          : 'Kích hoạt tài khoản';

  String get _emptyTitle =>
      _selectedTab == StaffApprovalTab.registrationApproval
          ? 'Không có tài khoản chờ duyệt'
          : 'Không có tài khoản cần kích hoạt';

  String get _emptySubtitle =>
      _selectedTab == StaffApprovalTab.registrationApproval
          ? 'Tất cả tài khoản đã được xử lý.'
          : 'Chưa có người dùng nào tải ảnh căn cước.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          _screenTitle,
          style: const TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryBlue),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchUsers,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: StaffDrawer(
        currentUser: widget.currentUser,
        onLogout: widget.onLogout,
        isRegistrationApprovalsSelected:
            _selectedTab == StaffApprovalTab.registrationApproval,
        isAccountActivationSelected:
            _selectedTab == StaffApprovalTab.accountActivation,
        onRegistrationApprovalsTapped: () {
          Navigator.pop(context);
          setState(() {
            _selectedTab = StaffApprovalTab.registrationApproval;
          });
        },
        onAccountActivationTapped: () {
          Navigator.pop(context);
          setState(() {
            _selectedTab = StaffApprovalTab.accountActivation;
          });
        },
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final users = _selectedTab == StaffApprovalTab.registrationApproval
        ? _registrationUsers
        : _activationUsers;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryBlue),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 72,
                color: Colors.green[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _emptyTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _emptySubtitle,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUsers,
      color: primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) => _buildUserCard(users[index]),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final phone = user['phone']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final gender = user['gender']?.toString() ?? '';
    final dob = user['dob']?.toString() ?? '';
    final cccd = user['cccd']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: primaryBlue.withOpacity(0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: primaryBlue,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'No name' : name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accentYellow.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: accentYellow.withOpacity(0.5)),
                        ),
                        child: Text(
                          _selectedTab == StaffApprovalTab.registrationApproval
                              ? 'Pending Registration'
                              : 'Pending Activation',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB8860B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _buildInfoRow(Icons.phone_rounded, phone),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.email_outlined, email),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.badge_outlined, 'CMND/CCCD: $cccd'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today_rounded, 'Ngày sinh: $dob'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person_outline_rounded, 'Giới tính: $gender'),
            if (_selectedTab == StaffApprovalTab.accountActivation) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () => _openCccdImages(user),
                  icon: const Icon(Icons.credit_card_rounded, size: 18),
                  label: const Text(
                    'Xem căn cước',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: BorderSide(color: primaryBlue.withOpacity(0.35)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _approveUser(user),
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Phê duyệt',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectUser(user),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text(
                        'Từ chối',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class CccdImageViewerScreen extends StatefulWidget {
  final List<String> images;
  final String userName;

  const CccdImageViewerScreen({
    super.key,
    required this.images,
    required this.userName,
  });

  @override
  State<CccdImageViewerScreen> createState() => _CccdImageViewerScreenState();
}

class _CccdImageViewerScreenState extends State<CccdImageViewerScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          widget.userName.isEmpty
              ? 'Ảnh căn cước'
              : 'Căn cước - ${widget.userName}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white54,
                      size: 72,
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
