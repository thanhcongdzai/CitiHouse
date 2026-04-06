import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
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
  late String _firstName;
  late String _lastName;
  late String _dob;
  late String _gender;
  late String _address;
  late String _email;

  @override
  void initState() {
    super.initState();
    final user = widget.currentUser!;
    _firstName = user.firstName;
    _lastName = user.lastName;
    _dob = user.dob;
    _gender = user.gender;
    _address = user.address;
    _email = user.email;
    _fetchDepositOrderCount();
  }

  String _displayValue(String value) {
    return value.trim().isEmpty ? '-' : value.trim();
  }

  String _displayName() {
    final fullName = '${_firstName.trim()} ${_lastName.trim()}'.trim();
    return fullName.isEmpty ? '-' : fullName;
  }

  Future<void> _openMyInformations() async {
    final user = widget.currentUser!;
    final updatedData = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => _MyInformationsScreen(
          user: user,
          initialFirstName: _firstName,
          initialLastName: _lastName,
          initialDob: _dob,
          initialGender: _gender,
          initialAddress: _address,
          initialEmail: _email,
        ),
      ),
    );

    if (updatedData == null || !mounted) return;

    setState(() {
      _firstName = (updatedData['firstName'] ?? '').toString();
      _lastName = (updatedData['lastName'] ?? '').toString();
      _dob = (updatedData['dob'] ?? '').toString();
      _gender = (updatedData['gender'] ?? '').toString();
      _address = (updatedData['address'] ?? '').toString();
      _email = (updatedData['email'] ?? '').toString();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cập nhật thông tin thành công'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _fetchDepositOrderCount() async {
    final userId = widget.currentUser?.id;
    if (userId == null || userId.isEmpty) return;
    try {
      final res = await http.get(
        ApiConfig.uri('/api/deposit-orders/buyer/$userId/'),
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
    final initials = '${_firstName.isNotEmpty ? _firstName[0] : ''}'
            '${_lastName.isNotEmpty ? _lastName[0] : ''}'
        .toUpperCase();

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
                                  builder: (_) =>
                                      UploadAvatarScreen(currentUser: user),
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
                                    backgroundImage: (user.image != null &&
                                            user.image!.isNotEmpty)
                                        ? NetworkImage(user.image!)
                                        : null,
                                    child: (user.image == null ||
                                            user.image!.isEmpty)
                                        ? Text(
                                            initials,
                                            style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white),
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
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
                                  _displayName(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.email_outlined,
                                        size: 13, color: Colors.white70),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        _displayValue(_email),
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: secondary.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(20),
                                    border:
                                        Border.all(color: secondary, width: 1),
                                  ),
                                  child: Text(
                                    user.status.trim().isNotEmpty
                                        ? '${user.role} • ${user.status}'
                                        : user.role,
                                    style: const TextStyle(
                                        color: secondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
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
                            _statItem(
                                '0', 'Listings', Icons.home_work_outlined),
                            _vDivider(),
                            _statItem('0', 'Saved', Icons.bookmark_outline),
                            _vDivider(),
                            _statItem(
                                '0', 'Contracts', Icons.description_outlined),
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
                  _infoRow(Icons.phone_android_rounded, 'Phone',
                      _displayValue(user.phone), Colors.teal),
                  _divider(),
                  _infoRow(Icons.cake_outlined, 'Date of Birth',
                      _displayValue(_dob), Colors.orange),
                  _divider(),
                  _infoRow(Icons.badge_outlined, 'CCCD',
                      _displayValue(user.cccd), Colors.indigo),
                  _divider(),
                  _infoRow(Icons.person_outline_rounded, 'Gender',
                      _displayValue(_gender), Colors.pink),
                  _divider(),
                  _infoRow(Icons.home_outlined, 'Address',
                      _displayValue(_address), Colors.green),
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
                      _orderStatus(
                          context, Icons.pending_outlined, 'Pending', primary,
                          onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MyDepositOrdersScreen(userId: user.id),
                          ),
                        ).then((_) => _fetchDepositOrderCount());
                      }, badgeCount: _depositOrderCount),
                      _orderStatus(context, Icons.handshake_outlined,
                          'Negotiating', primary),
                      _orderStatus(
                          context, Icons.draw_outlined, 'Signing', primary),
                      _orderStatus(context, Icons.check_circle_outline,
                          'Completed', primary),
                      _orderStatus(
                          context, Icons.cancel_outlined, 'Cancelled', primary),
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
                  _menuTile(Icons.favorite_outline, Colors.redAccent,
                      'My Properties', 'Your apartments'),
                  _divider(),
                  _menuTile(Icons.calendar_month_outlined, Colors.teal,
                      'My Appointments', 'Schedule & history', onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                MyAppointmentsScreen(userId: user.id)));
                  }),
                  _divider(),
                  _menuTile(Icons.home_work_outlined, Colors.indigo,
                      'My Listings', 'Manage your properties'),
                  _divider(),
                  _menuTile(Icons.notifications_outlined, secondary,
                      'Update My Informations', 'Update your profile',
                      onTap: _openMyInformations),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Logout ───────────────────────────────────────────────────
            _sectionCard(
              child: ListTile(
                onTap: () => _confirmLogout(context),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout, color: Colors.red, size: 22),
                ),
                title: const Text('Log Out',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w700)),
                trailing: const Icon(Icons.chevron_right,
                    color: Colors.grey, size: 20),
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
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
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      );

  Widget _vDivider() => Container(height: 40, width: 1, color: Colors.white24);

  Widget _sectionCard({required Widget child}) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
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
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Row(
                children: [
                  Text('View All',
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

  Widget _infoRow(IconData icon, String label, String value, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      );

  Widget _orderStatus(
          BuildContext context, IconData icon, String label, Color color,
          {VoidCallback? onTap, int badgeCount = 0}) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: onTap != null
                        ? color.withOpacity(0.15)
                        : color.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: onTap != null
                        ? Border.all(color: color.withOpacity(0.3), width: 1.5)
                        : null,
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
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.black87)),
          ],
        ),
      );

  Widget _menuTile(IconData icon, Color color, String title, String subtitle,
          {VoidCallback? onTap}) =>
      ListTile(
        onTap: onTap ?? () {},
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey))
            : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      );

  Widget _divider() =>
      const Divider(height: 1, indent: 56, endIndent: 16, thickness: 0.5);
}

class _MyInformationsScreen extends StatefulWidget {
  final User user;
  final String initialFirstName;
  final String initialLastName;
  final String initialDob;
  final String initialGender;
  final String initialAddress;
  final String initialEmail;

  const _MyInformationsScreen({
    required this.user,
    required this.initialFirstName,
    required this.initialLastName,
    required this.initialDob,
    required this.initialGender,
    required this.initialAddress,
    required this.initialEmail,
  });

  @override
  State<_MyInformationsScreen> createState() => _MyInformationsScreenState();
}

class _MyInformationsScreenState extends State<_MyInformationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final RegExp _emailRegex =
      RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _dobController;
  late final TextEditingController _genderController;
  late final TextEditingController _addressController;
  late final TextEditingController _emailController;

  File? _cccdFrontImage;
  File? _cccdBackImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.initialFirstName);
    _lastNameController = TextEditingController(text: widget.initialLastName);
    _dobController = TextEditingController(text: widget.initialDob);
    _genderController = TextEditingController(text: widget.initialGender);
    _addressController = TextEditingController(text: widget.initialAddress);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;

    setState(() {
      if (isFront) {
        _cccdFrontImage = File(file.path);
      } else {
        _cccdBackImage = File(file.path);
      }
    });
  }

  Future<void> _saveInformations() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final request = http.MultipartRequest(
        'PUT',
        ApiConfig.uri('/api/users/${widget.user.id}/'),
      );

      request.fields.addAll({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': widget.user.phone,
        'dob': _dobController.text.trim(),
        'cccd': widget.user.cccd,
        'gender': _genderController.text.trim(),
        'address': _addressController.text.trim(),
        'email': _emailController.text.trim(),
        'role': widget.user.role,
      });

      if (_cccdFrontImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'cccdImage',
            _cccdFrontImage!.path,
          ),
        );
      }

      if (_cccdBackImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'cccdImage',
            _cccdBackImage!.path,
          ),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pop<Map<String, dynamic>>(context, {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'dob': _dobController.text.trim(),
          'gender': _genderController.text.trim(),
          'address': _addressController.text.trim(),
          'email': _emailController.text.trim(),
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('My Informations'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _fieldCard(
                title: 'First Name',
                child: TextFormField(
                  controller: _firstNameController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              _fieldCard(
                title: 'Last Name',
                child: TextFormField(
                  controller: _lastNameController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              _fieldCard(
                title: 'Date of Birth (yyyy-mm-dd)',
                child: TextFormField(
                  controller: _dobController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              _fieldCard(
                title: 'Gender',
                child: TextFormField(
                  controller: _genderController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              _fieldCard(
                title: 'Address',
                child: TextFormField(
                  controller: _addressController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              _fieldCard(
                title: 'Email',
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Required';
                    if (!_emailRegex.hasMatch(value)) return 'Invalid email';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'CCCD Images',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _uploadTile(
                title: 'CCCD Front Side',
                file: _cccdFrontImage,
                onTap: () => _pickImage(true),
              ),
              const SizedBox(height: 10),
              _uploadTile(
                title: 'CCCD Back Side',
                file: _cccdBackImage,
                onTap: () => _pickImage(false),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveInformations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2361DB),
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Informations',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldCard({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _uploadTile({
    required String title,
    required File? file,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
              ),
              clipBehavior: Clip.antiAlias,
              child: file != null
                  ? Image.file(file, fit: BoxFit.cover)
                  : Icon(Icons.add_a_photo_outlined,
                      color: Colors.grey.shade600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file != null ? '$title selected' : 'Tap to upload $title',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
