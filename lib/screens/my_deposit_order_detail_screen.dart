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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: primaryBlue),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: color ?? Colors.black87, height: 1.3)),
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
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryBlue, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
                          height: 300,
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
                              // Beautiful gradient overlay to make images look more premium
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                height: 80,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.6),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (imageUrls.length > 1)
                                Positioned(
                                  bottom: 20,
                                  right: 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                        )
                                      ]
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.photo_library_outlined, color: Colors.white, size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${_currentImageIndex + 1}/${imageUrls.length}',
                                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ],
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
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3, letterSpacing: -0.5, color: Colors.black87),
                                ),
                                if (subject.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(subject, style: TextStyle(color: Colors.grey[600], fontSize: 15, fontWeight: FontWeight.w500)),
                                ],
                                const SizedBox(height: 24),
                                Divider(color: Colors.grey.shade200, thickness: 1.5),
                                const SizedBox(height: 20),
                                _detailRow(Icons.tag, 'Mã căn hộ', displayCode),
                                const SizedBox(height: 16),
                                _detailRow(Icons.location_on_outlined, 'Vị trí', location),
                                const SizedBox(height: 16),
                                _detailRow(Icons.attach_money_rounded, 'Giá bán', priceDisplay, color: Colors.orange[800]),
                                const SizedBox(height: 16),
                                
                                Builder(
                                  builder: (context) {
                                    final bed = _apartmentInfo?['bedRoom']?.toString();
                                    final bath = _apartmentInfo?['bathRoom']?.toString();
                                    final living = _apartmentInfo?['livingRoom']?.toString();
                                    final dining = _apartmentInfo?['diningRoom']?.toString();
                                    final kitchen = _apartmentInfo?['kitchen']?.toString();

                                    List<Widget> rooms = [];
                                    
                                    void addRoomText(String label, String? value) {
                                      if (value != null && value != '0' && value.trim().isNotEmpty) {
                                          rooms.add(
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                              margin: const EdgeInsets.only(bottom: 8.0),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8F9FA),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.grey.shade200),
                                              ),
                                              child: Row(
                                                children: [
                                                  Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500)),
                                                  const Spacer(),
                                                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                                                ],
                                              ),
                                            )
                                          );
                                      }
                                    }

                                    addRoomText('Phòng ngủ', bed);
                                    addRoomText('Phòng tắm', bath);
                                    addRoomText('Phòng khách', living);
                                    addRoomText('Phòng ăn', dining);
                                    addRoomText('Nhà bếp', kitchen);

                                    if (rooms.isEmpty) return const SizedBox.shrink();

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ...rooms,
                                        const SizedBox(height: 4),
                                      ],
                                    );
                                  },
                                ),
                                
                                if (projectInfo != null && projectInfo.keys.any((k) => k != 'apartmentNumber' && k != 'projectId')) ...[
                                  const SizedBox(height: 20),
                                  Divider(color: Colors.grey.shade200, thickness: 1.5),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Icon(Icons.business_rounded, size: 18, color: Colors.grey[700]),
                                      const SizedBox(width: 8),
                                      const Text('Chi tiết dự án', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ...projectInfo.entries
                                      .where((e) => e.key != 'apartmentNumber' && e.key != 'projectId')
                                      .map((e) {
                                        final label = projectInfoLabels[e.key] ?? e.key;
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 12.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                margin: const EdgeInsets.only(top: 6),
                                                child: const Icon(Icons.circle, size: 6, color: primaryBlue),
                                              ),
                                              const SizedBox(width: 12),
                                              SizedBox(width: 100, child: Text('$label', style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500))),
                                              Expanded(child: Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87))),
                                            ],
                                          ),
                                        );
                                      }),
                                ],
                                if (description.isNotEmpty) ...[
                                  const SizedBox(height: 20),
                                  Divider(color: Colors.grey.shade200, thickness: 1.5),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Icon(Icons.description_outlined, size: 18, color: Colors.grey[700]),
                                      const SizedBox(width: 8),
                                      const Text('Mô tả căn hộ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.shade200)
                                    ),
                                    child: Text(description, style: TextStyle(color: Colors.grey[800], height: 1.6, fontSize: 14)),
                                  ),
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
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isPaymentProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            shadowColor: primaryBlue.withOpacity(0.4),
          ),
          child: _isPaymentProcessing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                )
              : const Text(
                  'Thanh toán ngay',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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

