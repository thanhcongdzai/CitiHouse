import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MyDepositOrdersScreen extends StatefulWidget {
  final String userId;

  const MyDepositOrdersScreen({super.key, required this.userId});

  @override
  State<MyDepositOrdersScreen> createState() => _MyDepositOrdersScreenState();
}

class _MyDepositOrdersScreenState extends State<MyDepositOrdersScreen> {
  static const primaryBlue = Color.fromRGBO(35, 97, 219, 1);
  static const accentYellow = Color.fromRGBO(248, 192, 52, 1);

  bool _isLoading = true;
  String? _error;
  List<dynamic> _orders = [];
  Map<String, String> _apartmentNames = {};

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/deposit-orders/buyer/${widget.userId}/'),
      );

      if (res.statusCode != 200) throw Exception('Lỗi server: ${res.statusCode}');

      final orders = json.decode(utf8.decode(res.bodyBytes)) as List<dynamic>;

      // Fetch apartment names
      final aptRes = await http.get(Uri.parse('http://127.0.0.1:8000/api/apartments/'));
      final Map<String, String> aptMap = {};
      if (aptRes.statusCode == 200) {
        final apts = json.decode(utf8.decode(aptRes.bodyBytes)) as List<dynamic>;
        for (var a in apts) {
          aptMap[a['id']?.toString() ?? ''] = a['title'] ?? 'N/A';
        }
      }

      setState(() {
        _orders = orders;
        _apartmentNames = aptMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0 đ';
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(amount);
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'cho duyet coc':
        return Colors.orange;
      case 'Cho thanh toan':
        return Colors.blue;
      case 'Da thanh toan':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'cho duyet coc':
        return 'Chờ duyệt cọc';
      case 'Cho thanh toan':
        return 'Chờ thanh toán';
      case 'Da thanh toan':
        return 'Đã thanh toán';
      default:
        return status ?? 'Không rõ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Đơn đặt cọc của tôi',
          style: TextStyle(
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
            onPressed: _fetchOrders,
          ),
          const SizedBox(width: 8),
        ],
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
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchOrders,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                )
              : _orders.isEmpty
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
                            child: Icon(Icons.inbox_outlined, size: 72, color: Colors.blue[400]),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Bạn chưa có đơn đặt cọc nào',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchOrders,
                      color: primaryBlue,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final aptId = order['apartmentId']?.toString() ?? '';
                          final aptName = _apartmentNames[aptId] ?? 'N/A';
                          final status = order['status']?.toString();
                          final statusColor = _statusColor(status);
                          final statusLabel = _statusLabel(status);
                          final amount = order['depositAmount'];
                          final createdAt = order['createdAt']?.toString();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(18),
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
                                // Apartment name + status badge
                                Row(
                                  children: [
                                    const Icon(Icons.apartment_rounded,
                                        color: primaryBlue, size: 20),
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
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: statusColor.withOpacity(0.4)),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),
                                const Divider(height: 1, thickness: 0.5),
                                const SizedBox(height: 14),

                                // Deposit amount
                                Row(
                                  children: [
                                    const Icon(Icons.monetization_on_outlined,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Số tiền cọc: ',
                                      style: TextStyle(
                                          color: Colors.grey[600], fontSize: 13),
                                    ),
                                    Text(
                                      _formatCurrency(amount),
                                      style: const TextStyle(
                                        color: primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Created date
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Ngày tạo: ${_formatDate(createdAt)}',
                                      style: TextStyle(
                                          color: Colors.grey[600], fontSize: 13),
                                    ),
                                  ],
                                ),

                                if (order['notes'] != null &&
                                    order['notes'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.notes_rounded,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Ghi chú: ${order['notes']}',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
