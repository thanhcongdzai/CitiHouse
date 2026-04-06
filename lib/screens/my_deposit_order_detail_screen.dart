import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:intl/intl.dart';

class MyDepositOrderDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const MyDepositOrderDetailScreen({super.key, required this.order});

  @override
  State<MyDepositOrderDetailScreen> createState() => _MyDepositOrderDetailScreenState();
}

class _MyDepositOrderDetailScreenState extends State<MyDepositOrderDetailScreen> {
  static const primaryBlue = Color.fromRGBO(35, 97, 219, 1);
  
  bool _isLoading = true;
  bool _isPaymentProcessing = false;
  String? _error;
  Map<String, dynamic>? _apartmentInfo;
  Map<String, dynamic>? _staffInfo;
  int _currentImageIndex = 0;
  late Map<String, dynamic> _order;

  @override
  void initState() {
    super.initState();
    _order = Map<String, dynamic>.from(widget.order);
    _fetchDetails();
  }

  Future<void> _processPayment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận thanh toán',
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
        content: const Text('Bạn có chắc chắn muốn thanh toán đơn cọc này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isPaymentProcessing = true);

    try {
      final orderId = _order['id'];
      final updatedData = Map<String, dynamic>.from(_order);
      updatedData['status'] = 'Da thanh toan';

      final response = await http.put(
        ApiConfig.uri('/api/deposit-orders/$orderId/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedData),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _order['status'] = 'Da thanh toan';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thanh toán thành công!'),
              backgroundColor: Colors.green,
            ),
          );
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
      if (mounted) setState(() => _isPaymentProcessing = false);
    }
  }

  void _showFullScreenImage(BuildContext context, List<String> imageUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenGallery(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  // initState is above with _order initialization

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final aptId = widget.order['apartmentId'];
      final staffId = widget.order['staffId'];

      if (aptId != null && aptId.toString().isNotEmpty) {
        final aptRes = await http.get(ApiConfig.uri('/api/apartments/$aptId/'));
        if (aptRes.statusCode == 200) {
          _apartmentInfo = json.decode(utf8.decode(aptRes.bodyBytes));
        }
      }

      if (staffId != null && staffId.toString().isNotEmpty) {
        final staffRes = await http.get(ApiConfig.uri('/api/users/$staffId/'));
        if (staffRes.statusCode == 200) {
          _staffInfo = json.decode(utf8.decode(staffRes.bodyBytes));
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Lỗi kết nối khi tải chi tiết';
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0 đ';
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(amount);
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
        return status ?? 'Unknown';
    }
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: color ?? Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              Icon(icon, color: primaryBlue, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  List<String> _extractAllImages(Map<String, dynamic>? info) {
    if (info == null) return [];
    List<String> imgUrls = [];
    
    // Check imageUrl which might be comma-separated
    if (info['imageUrl'] is String && info['imageUrl'].toString().isNotEmpty) {
      imgUrls.addAll(info['imageUrl'].toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
    }
    
    // Check images array
    if (info['images'] is List && info['images'].isNotEmpty) {
      for (var img in info['images']) {
        if (img is String && img.isNotEmpty) {
          imgUrls.addAll(img.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
        }
      }
    }
    
    return imgUrls.toSet().toList(); // Remove duplicates
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final createdAt = order['createdAt']?.toString();
    final expiredAt = order['expiredAt']?.toString();
    final status = order['status']?.toString();
    final amount = order['depositAmount'];
    
    final aptName = _apartmentInfo?['title']?.toString() ?? 'N/A';
    final subject = _apartmentInfo?['subject']?.toString() ?? '';
    final description = _apartmentInfo?['description']?.toString() ?? '';
    
    // Address or location might be an object, so we concatenate its parts securely.
    String locationText = 'N/A';
    if (_apartmentInfo?['location'] is Map) {
      final loc = _apartmentInfo!['location'] as Map;
      List<String> parts = [];
      if (loc['address'] != null && loc['address'].toString().trim().isNotEmpty) {
        parts.add(loc['address'].toString().trim());
      }
      if (loc['ward'] != null && loc['ward'].toString().trim().isNotEmpty) {
        parts.add(loc['ward'].toString().trim());
      } else if (loc['commune'] != null && loc['commune'].toString().trim().isNotEmpty) {
        parts.add(loc['commune'].toString().trim());
      }
      if (loc['district'] != null && loc['district'].toString().trim().isNotEmpty) {
        parts.add(loc['district'].toString().trim());
      }
      if (loc['city'] != null && loc['city'].toString().trim().isNotEmpty) {
        parts.add(loc['city'].toString().trim());
      } else if (loc['province'] != null && loc['province'].toString().trim().isNotEmpty) {
        parts.add(loc['province'].toString().trim());
      }
      locationText = parts.isNotEmpty ? parts.join(', ') : loc.toString();
    } else if (_apartmentInfo?['address'] != null) {
      locationText = _apartmentInfo!['address'].toString();
    } else if (_apartmentInfo?['location'] != null) {
      locationText = _apartmentInfo!['location'].toString();
    }
    final location = locationText;
    
    final displayCode = _apartmentInfo?['displayCode']?.toString() ?? 'N/A';
    final imageUrls = _extractAllImages(_apartmentInfo);
    
    final projectInfo = _apartmentInfo?['projectInfo'] as Map<String, dynamic>?;
    
    final rawPrice = _apartmentInfo?['price'];
    double priceVal = 0;
    if (rawPrice != null) {
      if (rawPrice is Map && rawPrice.containsKey('\$numberLong')) {
        priceVal = double.tryParse(rawPrice['\$numberLong'].toString()) ?? 0;
      } else {
        priceVal = double.tryParse(rawPrice.toString()) ?? 0;
      }
    }
    final priceDisplay = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ').format(priceVal);
    
    final staffName = _staffInfo == null ? 'N/A' : '${_staffInfo!['firstName'] ?? ''} ${_staffInfo!['lastName'] ?? ''}'.trim();

    final Map<String, String> projectInfoLabels = {
      'project': 'Tên dự án',
      'building': 'Tòa nhà',
      'floor': 'Tầng',
      'host': 'Chủ nhà',
      'investor': 'Chủ đầu tư',
      'handoverYear': 'Năm bàn giao',
      'area': 'Diện tích',
      'status': 'Trạng thái dự án',
      'contractType': 'Loại hợp đồng',
      'scale': 'Quy mô',
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Chi tiết đơn cọc', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image Section
                      if (imageUrls.isNotEmpty)
                        SizedBox(
                          height: 250,
                          child: Stack(
                            children: [
                              PageView.builder(
                                itemCount: imageUrls.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () => _showFullScreenImage(context, imageUrls, index),
                                    child: Image.network(
                                      imageUrls[index],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey));
                                      },
                                    ),
                                  );
                                },
                              ),
                              if (imageUrls.length > 1)
                                Positioned(
                                  bottom: 15,
                                  right: 15,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${_currentImageIndex + 1}/${imageUrls.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Apartment Info Card
                            _buildSectionCard(
                              title: 'Thông tin căn hộ',
                              icon: Icons.apartment_rounded,
                              children: [
                                Text(
                                  aptName,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                if (subject.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(subject, style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic)),
                                ],
                                const SizedBox(height: 16),
                                _detailRow(Icons.tag, 'Mã căn hộ', displayCode),
                                const SizedBox(height: 12),
                                _detailRow(Icons.location_on_outlined, 'Vị trí', location),
                                const SizedBox(height: 12),
                                _detailRow(Icons.attach_money_rounded, 'Giá bán', priceDisplay, color: Colors.orange[800]),
                                
                                if (projectInfo != null) ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  const Text('Chi tiết dự án', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 12),
                                  ...projectInfo.entries
                                      .where((e) => e.key != 'apartmentNumber' && e.key != 'projectId')
                                      .map((e) {
                                        final label = projectInfoLabels[e.key] ?? e.key;
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.arrow_right, size: 20, color: Colors.grey),
                                              Text('$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                              Expanded(child: Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                                            ],
                                          ),
                                        );
                                      }),
                                ],
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  const Text('Mô tả', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 12),
                                  Text(description, style: TextStyle(color: Colors.grey[800], height: 1.5, fontSize: 14)),
                                ]
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Deposit Info Card
                            _buildSectionCard(
                              title: 'Thông tin đặt cọc',
                              icon: Icons.receipt_long_rounded,
                              children: [
                                _detailRow(Icons.person_outline, 'Nhân viên thực hiện', staffName.isEmpty ? 'N/A' : staffName),
                                const SizedBox(height: 16),
                                _detailRow(Icons.calendar_today_outlined, 'Ngày mở cọc', _formatDate(createdAt)),
                                const SizedBox(height: 16),
                                _detailRow(Icons.timer_outlined, 'Hạn cọc', _formatDate(expiredAt)),
                                const SizedBox(height: 16),
                                _detailRow(Icons.monetization_on_outlined, 'Số tiền cọc', _formatCurrency(amount), color: primaryBlue),
                                const SizedBox(height: 16),
                                _detailRow(Icons.info_outline_rounded, 'Trạng thái', _statusLabel(status), color: _statusColor(status)),
                                if (order['notes'] != null && order['notes'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  _detailRow(Icons.notes_rounded, 'Ghi chú', order['notes'].toString()),
                                ],
                              ],
                            ),
                            const SizedBox(height: 100), // padding for bottom button
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      bottomSheet: _isLoading || _error != null || status != 'Cho thanh toan' ? null : Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 16,
        ),
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
        child: ElevatedButton(
          onPressed: _isPaymentProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isPaymentProcessing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  'Thanh toán',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}

class FullScreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenGallery({super.key, required this.imageUrls, required this.initialIndex});

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${_currentIndex + 1}/${widget.imageUrls.length}', style: const TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              widget.imageUrls[index],
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: Colors.white, size: 50)),
            ),
          );
        },
      ),
    );
  }
}

