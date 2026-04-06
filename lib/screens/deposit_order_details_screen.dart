import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../models/user.dart';

class DepositOrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> deposit;
  final String staffName;
  final String buyerName;
  final String apartmentName;
  final VoidCallback onActionCompleted;
  final User currentUser;

  const DepositOrderDetailsScreen({
    super.key,
    required this.deposit,
    required this.staffName,
    required this.buyerName,
    required this.apartmentName,
    required this.onActionCompleted,
    required this.currentUser,
  });

  @override
  State<DepositOrderDetailsScreen> createState() => _DepositOrderDetailsScreenState();
}

class _DepositOrderDetailsScreenState extends State<DepositOrderDetailsScreen> {
  static const primaryBlue = Color.fromRGBO(35, 97, 219, 1);
  bool _isLoading = false;
  
  // State for expandable details
  bool _isStaffExpanded = false;
  bool _isBuyerExpanded = false;
  Map<String, dynamic>? _staffDetails;
  Map<String, dynamic>? _buyerDetails;
  bool _isLoadingStaff = false;
  bool _isLoadingBuyer = false;

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0 đ';
    final numberFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return numberFormat.format(amount);
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
    } catch (e) {
      return isoString;
    }
  }

  Future<void> _approveDeposit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận duyệt cọc'),
        content: const Text('Bạn có chắc chắn muốn duyệt đơn cọc này? Trạng thái sẽ chuyển thành "Pending Payment".'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final orderId = widget.deposit['id'];
      
      // Update logic via mapping matching other systems
      final updatedData = Map<String, dynamic>.from(widget.deposit);
      updatedData['status'] = 'Cho thanh toan';
      updatedData['approvedStaff'] = widget.currentUser.id;

      final response = await http.put(
        ApiConfig.uri('/api/deposit-orders/$orderId/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedData),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã duyệt đơn cọc thành công!'), backgroundColor: Colors.green),
          );
          widget.onActionCompleted();
          Navigator.pop(context);
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isHighlight ? primaryBlue : Colors.black87,
                fontSize: 15,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchUserDetails(String userId, bool isStaff) async {
    if (userId.isEmpty) return;
    
    setState(() {
      if (isStaff) _isLoadingStaff = true;
      else _isLoadingBuyer = true;
    });

    try {
      final response = await http.get(ApiConfig.uri('/api/users/$userId/'));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          if (isStaff) _staffDetails = data;
          else _buyerDetails = data;
        });
      }
    } catch (e) {
      // Ignore error for expandable UI, just show N/A
    } finally {
      setState(() {
        if (isStaff) _isLoadingStaff = false;
        else _isLoadingBuyer = false;
      });
    }
  }

  Widget _buildExpandedUserInfo(Map<String, dynamic>? user, bool isLoading) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: SizedBox(
            width: 20, 
            height: 20, 
            child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue)
          ),
        ),
      );
    }
    
    if (user == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Text('Không tải được thông tin', style: TextStyle(color: Colors.red, fontSize: 13)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0, left: 56.0), // Align with text
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(user['phone']?.toString().isNotEmpty == true ? user['phone'] : 'N/A', style: const TextStyle(fontSize: 13))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.email_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(user['email']?.toString().isNotEmpty == true ? user['email'] : 'N/A', style: const TextStyle(fontSize: 13))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.badge_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(user['cccd']?.toString().isNotEmpty == true ? user['cccd'] : 'N/A', style: const TextStyle(fontSize: 13))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.home_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(child: Text(user['address']?.toString().isNotEmpty == true ? user['address'] : 'N/A', style: const TextStyle(fontSize: 13))),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.deposit['status'] ?? 'Unknown';
    final isPending = status == 'cho duyet coc';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Chi tiết đơn cọc',
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryBlue),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Apartment Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: primaryBlue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.apartment_rounded, color: primaryBlue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Căn hộ đặt cọc',
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.apartmentName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 20),
                      
                      const Text(
                        'Thông tin chính',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDetailRow('Số tiền cọc:', _formatCurrency(widget.deposit['depositAmount']), isHighlight: true),
                      _buildDetailRow('Ngày tạo:', _formatDate(widget.deposit['createdAt']?.toString())),
                      _buildDetailRow('Hạn chót thanh toán:', _formatDate(widget.deposit['expiredAt']?.toString())),
                      _buildDetailRow('Ghi chú:', widget.deposit['notes']?.toString() ?? 'None'),
                      _buildDetailRow('Trạng thái:', status.toString()),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // People Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Người liên quan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isStaffExpanded = !_isStaffExpanded;
                            if (_isStaffExpanded && _staffDetails == null) {
                              _fetchUserDetails(widget.deposit['staffId']?.toString() ?? '', true);
                            }
                          });
                        },
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.blue[50],
                                  child: const Icon(Icons.support_agent_rounded, color: primaryBlue),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Người phụ trách', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                      Text(widget.staffName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _isStaffExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey,
                                )
                              ],
                            ),
                            if (_isStaffExpanded)
                              _buildExpandedUserInfo(_staffDetails, _isLoadingStaff),
                          ],
                        ),
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(height: 1),
                      ),
                      
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isBuyerExpanded = !_isBuyerExpanded;
                            if (_isBuyerExpanded && _buyerDetails == null) {
                              _fetchUserDetails(widget.deposit['buyerId']?.toString() ?? '', false);
                            }
                          });
                        },
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.orange[50],
                                  child: Icon(Icons.person_rounded, color: Colors.orange[700]),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Khách hàng đặt cọc', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                      Text(widget.buyerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    ],
                                  ),
                                ),
                                Icon(
                                  _isBuyerExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey,
                                )
                              ],
                            ),
                            if (_isBuyerExpanded)
                               _buildExpandedUserInfo(_buyerDetails, _isLoadingBuyer),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Space for bottom button
                const SizedBox(height: 100),
              ],
            ),
          ),
          
          if (isPending)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _approveDeposit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Duyệt Đơn Cọc Này',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
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


