import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';

class CreateDepositOrderScreen extends StatefulWidget {
  final String apartmentId;
  final String staffId;
  final String appointmentId;
  final User? currentUser;

  const CreateDepositOrderScreen({
    super.key,
    required this.apartmentId,
    required this.staffId,
    required this.appointmentId,
    this.currentUser,
  });

  @override
  State<CreateDepositOrderScreen> createState() =>
      _CreateDepositOrderScreenState();
}

class _CreateDepositOrderScreenState extends State<CreateDepositOrderScreen> {
  final Color primaryBlue = const Color.fromRGBO(35, 97, 219, 1);
  final Color accentYellow = const Color.fromRGBO(248, 192, 52, 1);

  final TextEditingController _phoneController = TextEditingController();

  bool _isLoadingInfo = true;
  bool _isSearchingUser = false;
  bool _isSubmitting = false;

  Map<String, dynamic>? _apartmentInfo;
  Map<String, dynamic>? _foundUser;
  double _depositAmount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchApartmentInfo();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  Future<void> _fetchApartmentInfo() async {
    try {
      final response = await http
          .get(ApiConfig.uri('/api/apartments/${widget.apartmentId}/'));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _apartmentInfo = data;

          double price = 0;
          if (data['price'] != null) {
            // Handle MongoDB $numberLong object or direct int/double
            if (data['price'] is Map &&
                data['price'].containsKey('\$numberLong')) {
              price =
                  double.tryParse(data['price']['\$numberLong'].toString()) ??
                      0;
            } else {
              price = double.tryParse(data['price'].toString()) ?? 0;
            }
          }
          _depositAmount = price * 0.12; // 12% of price
          _isLoadingInfo = false;
        });
      } else {
        setState(() {
          _error =
              'Failed to load apartment info. Status: ${response.statusCode}';
          _isLoadingInfo = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error fetching apartment info.';
        _isLoadingInfo = false;
      });
    }
  }

  Future<void> _searchUserByPhone() async {
    final phone = _normalizePhone(_phoneController.text.trim());
    if (phone.isEmpty) return;

    setState(() {
      _isSearchingUser = true;
      _foundUser = null;
    });

    try {
      final response = await http.get(ApiConfig.uri('/api/users/'));
      if (response.statusCode == 200) {
        final List<dynamic> users =
            json.decode(utf8.decode(response.bodyBytes));

        // Find user by phone
        final match = users.whereType<Map<String, dynamic>>().firstWhere(
              (user) => _normalizePhone(user['phone']?.toString() ?? '') == phone,
              orElse: () => {},
            );

        setState(() {
          if (match.isNotEmpty) {
            _foundUser = match;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No user found with this phone number!')),
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi tải danh sách người dùng!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi kết nối khi tìm kiếm người dùng!')),
      );
    } finally {
      setState(() {
        _isSearchingUser = false;
      });
    }
  }

  Future<void> _submitDepositOrder() async {
    if (_foundUser == null) return;

    setState(() {
      _isSubmitting = true;
    });

    String buyerIdStr = '';
    final rawUserId = _foundUser!['_id'] ?? _foundUser!['id'];

    if (rawUserId != null) {
      if (rawUserId is Map) {
        buyerIdStr = rawUserId['\$oid']?.toString() ??
            rawUserId['oid']?.toString() ??
            '';
      } else {
        buyerIdStr = rawUserId.toString();
      }
    }

    // Default payload matching requirements
    final payload = {
      "apartmentId": widget.apartmentId,
      "staffId": widget.staffId,
      "buyerId": buyerIdStr,
      "depositAmount": _depositAmount,
      "status": "cho duyet coc",
      "createdAt": DateTime.now().toUtc().toIso8601String(),
      "expiredAt": DateTime.now().add(const Duration(days: 3)).toUtc().toIso8601String(),
      "paymentEvidence": "",
      "notes": "Yeu cau coc"
    };

    try {
      final depositResponse = await http.post(
        ApiConfig.uri('/api/deposit-orders/'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(payload),
      );

      if (depositResponse.statusCode == 200 ||
          depositResponse.statusCode == 201) {
        // Also update apartment houseStatus to inContract
        try {
          if (_apartmentInfo != null) {
            final updatedApartment = Map<String, dynamic>.from(_apartmentInfo!);
            updatedApartment['houseStatus'] = 'inContract';

            await http.put(
              ApiConfig.uri('/api/apartments/${widget.apartmentId}/'),
              headers: {'Content-Type': 'application/json; charset=UTF-8'},
              body: json.encode(updatedApartment),
            );
          }
        } catch (_) {
          // Silently fail - deposit was still created
        }

        // Also update the appointment status to 'Da yeu cau coc'
        try {
          await http.put(
            ApiConfig.uri('/api/viewing-appointments/${widget.appointmentId}/'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: json.encode({'status': 'Da yeu cau coc'}),
          );
        } catch (_) {
          // Silently fail - deposit was still created
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gửi yêu cầu đặt cọc thành công!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Lỗi: ${depositResponse.statusCode} - ${depositResponse.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi kết nối khi tạo yêu cầu!')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} Tỷ VNĐ';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(0)} Triệu VNĐ';
    }
    return '${amount.toStringAsFixed(0)} VNĐ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Deposit Request',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        foregroundColor: primaryBlue,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingInfo
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: TextStyle(color: Colors.red[700])))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Apartment Info Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.apartment_rounded,
                                    color: primaryBlue, size: 24),
                                const SizedBox(width: 10),
                                const Text('Apartment Information',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _apartmentInfo?['title'] ?? 'N/A',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Mã CH: ${_apartmentInfo?['displayCode'] ?? widget.apartmentId}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: accentYellow.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: accentYellow.withOpacity(0.5)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tiền cọc (12%):',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  Text(
                                    _formatCurrency(_depositAmount),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: Colors.orange[800]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Customer Search Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person_search_rounded,
                                    color: primaryBlue, size: 24),
                                const SizedBox(width: 10),
                                const Text('Tìm khách hàng (Người mua)',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: 'Enter phone number...',
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 14),
                                    ),
                                    onSubmitted: (_) => _searchUserByPhone(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 48,
                                  width: 48,
                                  child: ElevatedButton(
                                    onPressed: _isSearchingUser
                                        ? null
                                        : _searchUserByPhone,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    child: _isSearchingUser
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2))
                                        : const Icon(Icons.search_rounded),
                                  ),
                                ),
                              ],
                            ),
                            if (_foundUser != null) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.green.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.check_circle_rounded,
                                            color: Colors.green[600], size: 20),
                                        const SizedBox(width: 8),
                                        Text('Đã tìm thấy khách hàng',
                                            style: TextStyle(
                                                color: Colors.green[800],
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                        'Họ tên: ${_foundUser!['firstName']} ${_foundUser!['lastName']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text('SĐT: ${_foundUser!['phone']}'),
                                    const SizedBox(height: 4),
                                    Text('CCCD: ${_foundUser!['cccd']}'),
                                  ],
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (_foundUser == null || _isSubmitting)
                              ? null
                              : _submitDepositOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            elevation: _foundUser == null ? 0 : 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Create Deposit Request',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

