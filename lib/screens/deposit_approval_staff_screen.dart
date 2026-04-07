import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';
import 'staff_drawer.dart';
import 'deposit_order_details_screen.dart';

class DepositApprovalStaffScreen extends StatefulWidget {
  final User currentUser;
  final VoidCallback onLogout;

  const DepositApprovalStaffScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  State<DepositApprovalStaffScreen> createState() => _DepositApprovalStaffScreenState();
}

class _DepositApprovalStaffScreenState extends State<DepositApprovalStaffScreen> {
  static const primaryBlue = Color.fromRGBO(35, 97, 219, 1);
  static const accentYellow = Color.fromRGBO(248, 192, 52, 1);

  bool _isLoading = true;
  String? _error;
  bool _showApproved = false; // false = 'Pending Approval' (cho duyet coc), true = 'Approved' (cho thanh toan)

  List<dynamic> _deposits = [];
  Map<String, String> _staffNames = {};
  Map<String, String> _buyerNames = {};
  Map<String, String> _apartmentNames = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch Deposits
      final depositRes = await http.get(ApiConfig.uri('/api/deposit-orders/'));
      if (depositRes.statusCode != 200) throw Exception('Failed to load deposit orders');
      final fetchedDeposits = json.decode(utf8.decode(depositRes.bodyBytes)) as List<dynamic>;

      // Fetch Apartments
      final aptRes = await http.get(ApiConfig.uri('/api/apartments/'));
      if (aptRes.statusCode != 200) throw Exception('Failed to load apartments');
      final apts = json.decode(utf8.decode(aptRes.bodyBytes)) as List<dynamic>;

      final Map<String, String> aptMap = {};
      for (var a in apts) {
        final id = a['id']?.toString() ?? '';
        aptMap[id] = a['title'] ?? 'Unknown Apartment';
      }

      // Fetch individual user data for staff and buyers that are in the fetched deposits
      final Map<String, String> staffMap = {};
      final Map<String, String> buyerMap = {};

      for (var deposit in fetchedDeposits) {
        final staffId = deposit['staffId']?.toString();
        final buyerId = deposit['buyerId']?.toString();

        if (staffId != null && staffId.isNotEmpty && !staffMap.containsKey(staffId)) {
          final res = await http.get(ApiConfig.uri('/api/users/$staffId/'));
          if (res.statusCode == 200) {
            final u = json.decode(utf8.decode(res.bodyBytes));
            staffMap[staffId] = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim();
          } else {
            staffMap[staffId] = 'Unknown Staff';
          }
        }

        if (buyerId != null && buyerId.isNotEmpty && !buyerMap.containsKey(buyerId)) {
          final res = await http.get(ApiConfig.uri('/api/users/$buyerId/'));
          if (res.statusCode == 200) {
            final u = json.decode(utf8.decode(res.bodyBytes));
            buyerMap[buyerId] = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim();
          } else {
            buyerMap[buyerId] = 'Unknown Buyer';
          }
        }
      }

      setState(() {
        _deposits = fetchedDeposits;
        _staffNames = staffMap;
        _buyerNames = buyerMap;
        _apartmentNames = aptMap;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter by status
    final targetStatus = _showApproved ? 'Cho thanh toan' : 'cho duyet coc';
    final filteredDeposits = _deposits.where((d) => d['status'] == targetStatus).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          _showApproved ? 'Approved' : 'Pending Approval',
          style: const TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryBlue),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: StaffDrawer(
        currentUser: widget.currentUser,
        onLogout: widget.onLogout,
        isPendingDepositsSelected: !_showApproved,
        isApprovedDepositsSelected: _showApproved,
        onPendingDepositsTapped: () {
          setState(() {
            _showApproved = false;
          });
          Navigator.pop(context); // Close drawer
        },
        onApprovedDepositsTapped: () {
          setState(() {
            _showApproved = true;
          });
          Navigator.pop(context); // Close drawer
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : filteredDeposits.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withOpacity(0.1),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: Colors.blue[300],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _showApproved ? 'Chưa có đơn cọc nào đã duyệt' : 'Không có đơn cọc nào',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _showApproved ? 'Danh sách trống' : 'Hiện chưa có yêu cầu duyệt cọc',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      color: primaryBlue,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDeposits.length,
                        itemBuilder: (context, index) {
                          final deposit = filteredDeposits[index];
                          final staffId = deposit['staffId']?.toString() ?? '';
                          final buyerId = deposit['buyerId']?.toString() ?? '';
                          final aptId = deposit['apartmentId']?.toString() ?? '';

                          final staffName = _staffNames[staffId] ?? 'N/A';
                          final buyerName = _buyerNames[buyerId] ?? 'N/A';
                          final aptName = _apartmentNames[aptId] ?? 'N/A';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withOpacity(0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(color: Colors.blue.shade50, width: 2),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DepositOrderDetailsScreen(
                                        deposit: deposit,
                                        staffName: staffName,
                                        buyerName: buyerName,
                                        apartmentName: aptName,
                                        onActionCompleted: _fetchData,
                                        currentUser: widget.currentUser,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: primaryBlue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            child: const Icon(Icons.apartment_rounded, color: primaryBlue, size: 24),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  aptName,
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w800,
                                                    color: Colors.black87,
                                                    height: 1.3,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: _showApproved ? Colors.green.shade50 : Colors.orange.shade50,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        _showApproved ? Icons.check_circle_rounded : Icons.pending_rounded,
                                                        size: 14,
                                                        color: _showApproved ? Colors.green[600] : Colors.orange[800],
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        _showApproved ? 'Đã duyệt (Chờ thanh toán)' : 'Chờ duyệt cọc',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w700,
                                                          color: _showApproved ? Colors.green[700] : Colors.orange[800],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: Colors.blue.shade50,
                                                  child: const Icon(Icons.support_agent_rounded, size: 16, color: primaryBlue),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text('Nhân viên', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                                      Text(
                                                        staffName,
                                                        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(width: 1, height: 30, color: const Color(0xFFE5E7EB), margin: const EdgeInsets.symmetric(horizontal: 10)),
                                          Expanded(
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: Colors.orange.shade50,
                                                  child: Icon(Icons.person_outline_rounded, size: 16, color: Colors.orange.shade700),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text('Khách hàng', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                                      Text(
                                                        buyerName,
                                                        style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}


