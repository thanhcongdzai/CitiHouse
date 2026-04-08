import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';
import 'on_site_staff_detail_screen.dart';
import 'staff_drawer.dart';

class OnSiteStaffScreen extends StatefulWidget {
  final User currentUser;
  final VoidCallback onLogout;

  const OnSiteStaffScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  State<OnSiteStaffScreen> createState() => _OnSiteStaffScreenState();
}

class _OnSiteStaffScreenState extends State<OnSiteStaffScreen> {
  static const primaryBlue = Color.fromRGBO(35, 97, 219, 1);
  static const accentYellow = Color.fromRGBO(248, 192, 52, 1);
  static const bgColor = Color(0xFFF4F6FA);

  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  String? _error;
  int _selectedTab =
      0; // 0 = Hiện có, 1 = Accepted, 2 = Completed, 3 = Deposit Requested

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        ApiConfig.uri('/api/viewing-appointments/'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> raw = json.decode(utf8.decode(response.bodyBytes));
        final List<Map<String, dynamic>> appointments =
            raw.cast<Map<String, dynamic>>();

        // Fetch apartment and user info concurrently for each appointment
        final enriched = await Future.wait(appointments.map((appt) async {
          final aptIdRaw = appt['apartmentId'];
          final apartmentId = (aptIdRaw is Map && aptIdRaw.containsKey('\$oid'))
              ? aptIdRaw['\$oid']?.toString() ?? ''
              : aptIdRaw?.toString() ?? '';

          final userIdRaw = appt['userId'];
          final userId = (userIdRaw is Map && userIdRaw.containsKey('\$oid'))
              ? userIdRaw['\$oid']?.toString() ?? ''
              : userIdRaw?.toString() ?? '';

          Map<String, dynamic>? apartmentData;
          Map<String, dynamic>? userData;

          try {
            if (apartmentId.isNotEmpty) {
              final aRes = await http.get(
                ApiConfig.uri('/api/apartments/$apartmentId/'),
              );
              if (aRes.statusCode == 200) {
                apartmentData = json.decode(utf8.decode(aRes.bodyBytes));
              }
            }
          } catch (_) {}

          try {
            if (userId.isNotEmpty) {
              final uRes = await http.get(
                ApiConfig.uri('/api/users/$userId/'),
              );
              if (uRes.statusCode == 200) {
                userData = json.decode(utf8.decode(uRes.bodyBytes));
              }
            }
          } catch (_) {}

          return {
            ...appt,
            '_apartment': apartmentData,
            '_user': userData,
          };
        }));

        if (mounted) {
          setState(() {
            _appointments = enriched;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Lỗi máy chủ: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi kết nối: $e';
          _isLoading = false;
        });
      }
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Yeu cau xem':
      case 'Dang lien he':
        return Colors.orange;
      case 'Da xac nhan':
      case 'Da xac nhan lich':
        return Colors.blue;
      case 'Dang xem':
        return Colors.purple;
      case 'Hoan thanh':
        return Colors.green;
      case 'Da huy lich':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'Yeu cau xem':
        return 'Viewing Request';
      case 'Dang lien he':
        return 'Contacting';
      case 'Da xac nhan':
      case 'Da xac nhan lich':
        return 'Schedule confirmed';
      case 'Dang xem':
        return 'Viewing';
      case 'Hoan thanh':
        return 'Completed';
      case 'Da huy lich':
        return 'Cancelled';
      default:
        return status ?? 'Unknown';
    }
  }

  Widget _buildRoomBadge(dynamic value, String suffix) {
    final v = value?.toString() ?? '0';
    if (v == '0' || v == '0.0' || v.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text('$v $suffix', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter appointments based on active tab
    final displayedAppointments = _appointments.where((appt) {
      final staffInCharge = appt['staffInCharge']?.toString();
      final status = appt['status']?.toString();

      if (_selectedTab == 0) {
        // Hiện có: staffInCharge is null or empty
        return staffInCharge == null || staffInCharge.isEmpty;
      } else if (_selectedTab == 1) {
        // Accepted: Assigned to me, NOT Hoan thanh, Da yeu cau coc, Da huy lich or Huy
        return staffInCharge == widget.currentUser.id &&
            status != 'Hoan thanh' &&
            status != 'Da yeu cau coc' &&
            status != 'Da huy lich' &&
            status != 'Huy';
      } else if (_selectedTab == 2) {
        // Đã hoàn thành / Hủy: Assigned to me AND status is Hoan thanh or cancelled
        return staffInCharge == widget.currentUser.id && 
            (status == 'Hoan thanh' || status == 'Da huy lich' || status == 'Huy');
      } else if (_selectedTab == 3) {
        // Deposit Requested: Assigned to me AND Da yeu cau coc
        return staffInCharge == widget.currentUser.id &&
            status == 'Da yeu cau coc';
      }
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryBlue),
        title: Text(
          _selectedTab == 0
              ? 'Viewing Requests Detail'
              : _selectedTab == 1
                  ? 'My Jobs'
                  : _selectedTab == 2
                      ? 'Đã Hoàn Thành'
                      : 'Đã Yêu Cầu Cọc',
          style: const TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: primaryBlue),
            onPressed: _fetchAppointments,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: StaffDrawer(
        currentUser: widget.currentUser,
        onLogout: widget.onLogout,
        isMyJobsSelected: _selectedTab == 1,
        isCompletedJobsSelected: _selectedTab == 2,
        isDepositRequestedSelected: _selectedTab == 3,
        onAllJobsTapped: () {
          setState(() {
            _selectedTab = 0;
          });
          Navigator.pop(context);
        },
        onMyJobsTapped: () {
          setState(() {
            _selectedTab = 1;
          });
          Navigator.pop(context);
        },
        onCompletedJobsTapped: () {
          setState(() {
            _selectedTab = 2;
          });
          Navigator.pop(context);
        },
        onDepositRequestedTapped: () {
          setState(() {
            _selectedTab = 3;
          });
          Navigator.pop(context);
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _error != null
              ? _buildErrorState()
              : displayedAppointments.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _fetchAppointments,
                      color: primaryBlue,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedAppointments.length,
                        itemBuilder: (context, index) {
                          return _buildListTile(displayedAppointments[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildErrorState() {
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
            onPressed: _fetchAppointments,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.event_available_rounded,
                size: 72, color: primaryBlue.withOpacity(0.6)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Không lịch hẹn nào',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text('Không có yêu cầu xem nhà nào.',
              style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildListTile(Map<String, dynamic> appt) {
    final apartment = appt['_apartment'] as Map<String, dynamic>?;
    final user = appt['_user'] as Map<String, dynamic>?;
    final customer = appt['customer'] as Map<String, dynamic>?;
    final status = appt['status']?.toString();
    final staffInCharge = appt['staffInCharge'];

    final isMine = staffInCharge?.toString() == widget.currentUser.id;

    final customerPhone = customer?['phone']?.toString() ?? '';
    final userPhone = user?['phone']?.toString() ?? '';
    final isReferred = customerPhone.isNotEmpty &&
        userPhone.isNotEmpty &&
        customerPhone != userPhone;

    final userName = user != null
        ? (user['fullName']?.toString() ?? user['name']?.toString() ?? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}').trim()
        : (appt['userId'] is Map ? appt['userId']['\$oid']?.toString() ?? 'Unknown' : appt['userId']?.toString() ?? 'Unknown');

    final customerName = customer?['name']?.toString() ?? '';
    final aptTitle =
        apartment?['title']?.toString() ?? 'Căn hộ #${appt['apartmentId']}';

    final hasStaff =
        staffInCharge != null && staffInCharge.toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      // Outer container for glowing effect
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isMine
            ? (status == 'Da huy lich' || status == 'Huy')
                ? LinearGradient(
                    colors: [Colors.redAccent.shade200, Colors.red.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [Colors.greenAccent.shade400, Colors.green.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
            : LinearGradient(
                colors: [
                  primaryBlue.withOpacity(0.4),
                  accentYellow.withOpacity(0.6)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        boxShadow: [
          if (isMine)
            BoxShadow(
              color: (status == 'Da huy lich' || status == 'Huy')
                  ? Colors.red.withOpacity(0.4)
                  : Colors.green.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: primaryBlue.withOpacity(0.25),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2.5), // Border width
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OnSiteStaffDetailScreen(
                    appointment: appt,
                    currentUser: widget.currentUser,
                  ),
                ),
              );
              _fetchAppointments();
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header: Apartment Info & Status ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryBlue, primaryBlue.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.apartment_rounded,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              aptTitle,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              children: [
                                _buildRoomBadge(apartment?['bedRoom'], 'Phòng ngủ'),
                                _buildRoomBadge(apartment?['livingRoom'], 'Phòng khách'),
                                _buildRoomBadge(apartment?['diningRoom'], 'Phòng ăn'),
                                _buildRoomBadge(apartment?['kitchen'], 'Bếp'),
                                _buildRoomBadge(apartment?['bathRoom'], 'Phòng tắm'),
                                if (apartment?['area'] != null && apartment?['area'].toString() != '0' && apartment?['area'].toString() != '0.0')
                                  _buildRoomBadge(apartment?['area'], 'm²'),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        _statusColor(status).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: _statusColor(status)
                                            .withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    _statusLabel(status),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _statusColor(status),
                                    ),
                                  ),
                                ),
                                if (isMine) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.green.shade300),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded,
                                            size: 12, color: Colors.green),
                                        SizedBox(width: 4),
                                        Text(
                                          'In Charge',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (hasStaff) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.lock_rounded,
                                            size: 12, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(
                                          'Accepted',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          color: Colors.black26, size: 18),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.grey.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── People Info ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Booker Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentYellow.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_rounded,
                                      size: 14, color: Colors.orange.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Booker',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                userName.isNotEmpty ? userName : 'Unknown',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Referred Column
                      if (isReferred) ...[
                        Container(
                          width: 1,
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: Colors.grey.shade200,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.handshake_rounded,
                                        size: 14,
                                        color: Colors.purple.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Brokered Client',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.purple.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  customerName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
