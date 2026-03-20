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
  bool _showApproved = false; // false = 'Đợi duyệt' (cho duyet coc), true = 'Đã duyệt' (cho thanh toan)

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
          _showApproved ? 'Đã duyệt' : 'Đợi duyệt',
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
                        label: const Text('Thử lại'),
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
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inbox_outlined,
                              size: 72,
                              color: Colors.blue[400],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _showApproved ? 'Chưa có đơn cọc nào đã duyệt' : 'Không có đơn cọc nào cần duyệt',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
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

                          return GestureDetector(
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
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.apartment_rounded, color: primaryBlue, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          aptName,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.support_agent_rounded, size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Nhân viên: $staffName',
                                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Khách Hàng: $buyerName',
                                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _showApproved ? Colors.green.withOpacity(0.1) : accentYellow.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _showApproved ? Colors.green.withOpacity(0.5) : accentYellow.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Text(
                                        _showApproved ? 'Đã duyệt' : 'Chờ duyệt',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: _showApproved ? Colors.green[700] : const Color(0xFFB8860B),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

