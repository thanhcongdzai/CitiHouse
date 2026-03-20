import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/apartment.dart';
import '../models/user.dart';
import 'apartment_images_screen.dart';

class ApartmentApprovalDetailScreen extends StatefulWidget {
  final Apartment apartment;
  final User currentUser;
  final bool isMyJob; // True if from "Công việc đã nhận", false if "Công việc hiện có"

  const ApartmentApprovalDetailScreen({
    super.key,
    required this.apartment,
    required this.currentUser,
    required this.isMyJob,
  });

  @override
  State<ApartmentApprovalDetailScreen> createState() => _ApartmentApprovalDetailScreenState();
}

class _ApartmentApprovalDetailScreenState extends State<ApartmentApprovalDetailScreen> {
  static const primaryBlue = Color.fromRGBO(35, 97, 219, 1);
  static const accentYellow = Color.fromRGBO(248, 192, 52, 1);

  bool _isProcessing = false;
  late Apartment _currentApt;

  @override
  void initState() {
    super.initState();
    _currentApt = widget.apartment;
  }

  Future<void> _acceptJob() async {
    setState(() => _isProcessing = true);
    try {
      // Create a full payload combining the existing apartment data and the updated verification fields
      final v = _currentApt.verifications ?? {};
      final img = v['image'] ?? {};
      final leg = v['legal'] ?? {};
      final oi = v['ownerIntent'] ?? {};

      // Update staffId for all three steps
      img['staffId'] = widget.currentUser.id;
      leg['staffId'] = widget.currentUser.id;
      oi['staffId'] = widget.currentUser.id;
      v['image'] = img;
      v['legal'] = leg;
      v['ownerIntent'] = oi;

      final updatedApt = {
        'id': _currentApt.id,
        'title': _currentApt.title,
        'subject': _currentApt.subject,
        'description': _currentApt.description,
        'price': _currentApt.price,
        'displayCode': _currentApt.displayCode,
        'imageUrl': _currentApt.imageUrl,
        'userImageUrl': _currentApt.imageUrl,
        'houseStatus': _currentApt.houseStatus,
        'location': {
          'ward': _currentApt.ward,
          'commune': _currentApt.commune,
        },
        'projectInfo': {
          'project': _currentApt.project,
          'building': _currentApt.building,
          'floor': _currentApt.floor,
          'apartmentNumber': _currentApt.apartmentNumber,
        },
        'verifications': v,
      };

      final response = await http.put(
        ApiConfig.uri('/api/apartments/${_currentApt.id}/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedApt),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Nhận việc thành công!'),
              backgroundColor: Colors.green[600],
            ),
          );
          Navigator.pop(context, true); // Return true to trigger refresh on previous screen
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${response.statusCode}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showConfirmPublishDialog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận cho đăng', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn duyệt không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _approveAndPublish();
    }
  }

  Future<void> _approveAndPublish() async {
    setState(() => _isProcessing = true);
    try {
      final v = _currentApt.verifications ?? {};
      final updatedApt = {
        'id': _currentApt.id,
        'title': _currentApt.title,
        'subject': _currentApt.subject,
        'description': _currentApt.description,
        'price': _currentApt.price,
        'displayCode': _currentApt.displayCode,
        'imageUrl': _currentApt.imageUrl,
        'userImageUrl': _currentApt.imageUrl,
        'houseStatus': 'Available', // Update status here
        'location': {
          'ward': _currentApt.ward,
          'commune': _currentApt.commune,
        },
        'projectInfo': {
          'project': _currentApt.project,
          'building': _currentApt.building,
          'floor': _currentApt.floor,
          'apartmentNumber': _currentApt.apartmentNumber,
        },
        'verifications': v,
      };

      final response = await http.put(
        ApiConfig.uri('/api/apartments/${_currentApt.id}/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedApt),
      );

      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Text('Duyệt thành công', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
              content: const Text('Bài đăng đã được duyệt.', style: TextStyle(fontSize: 16)),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context, true);
                  },
                  child: const Text('Đóng'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${response.statusCode}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showConfirmStepDialog(String stepKey, String title) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận duyệt', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc chắn đánh dấu mục "$title" là hợp lệ và đã được duyệt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _approveStep(stepKey);
    }
  }

  Future<void> _approveStep(String stepKey) async {
    setState(() => _isProcessing = true);
    try {
      final v = _currentApt.verifications ?? {};
      final stepMap = v[stepKey] ?? {};
      
      stepMap['status'] = 'Approved';
      stepMap['updatedAt'] = DateTime.now().toUtc().toIso8601String();
      v[stepKey] = stepMap;

      final updatedApt = {
        'id': _currentApt.id,
        'title': _currentApt.title,
        'subject': _currentApt.subject,
        'description': _currentApt.description,
        'price': _currentApt.price,
        'displayCode': _currentApt.displayCode,
        'imageUrl': _currentApt.imageUrl,
        'userImageUrl': _currentApt.imageUrl,
        'houseStatus': _currentApt.houseStatus,
        'location': {
          'ward': _currentApt.ward,
          'commune': _currentApt.commune,
        },
        'projectInfo': {
          'project': _currentApt.project,
          'building': _currentApt.building,
          'floor': _currentApt.floor,
          'apartmentNumber': _currentApt.apartmentNumber,
        },
        'verifications': v,
      };

      final response = await http.put(
        ApiConfig.uri('/api/apartments/${_currentApt.id}/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedApt),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã duyệt $stepKey!'),
              backgroundColor: Colors.green[600],
            ),
          );
          // Refetch to reflect exact state locally if needed, but we can also just pop back or update local object.
          setState(() {
            _currentApt = Apartment.fromJson(json.decode(json.encode(updatedApt)));
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${response.statusCode}'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _currentApt.verifications ?? {};
    final imgMap = v['image'] as Map<String, dynamic>? ?? {};
    final legMap = v['legal'] as Map<String, dynamic>? ?? {};
    final oiMap = v['ownerIntent'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Chi Tiết Phê Duyệt',
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryBlue),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context, true), // Return true just in case we changed state
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Apartment Info
                Container(
                  padding: const EdgeInsets.all(20),
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
                      Text(
                        _currentApt.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.location_city_rounded, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_currentApt.project} - ${_currentApt.building}',
                              style: TextStyle(fontSize: 15, color: Colors.grey[800], fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_currentApt.ward}, ${_currentApt.commune}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tiến Trình Phê Duyệt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Approval Steps
                _buildApprovalStep(
                  '1. Hình Ảnh Thực Tế (Image)',
                  imgMap,
                  Icons.image_rounded,
                  () => _showConfirmStepDialog('image', 'Hình Ảnh Thực Tế'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ApartmentImagesScreen(apartment: _currentApt),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildApprovalStep(
                  '2. Giấy Tờ Pháp Lý (Legal)',
                  legMap,
                  Icons.gavel_rounded,
                  () => _showConfirmStepDialog('legal', 'Giấy Tờ Pháp Lý'),
                ),
                const SizedBox(height: 12),
                _buildApprovalStep(
                  '3. Xác Nhận Chủ Nhà (Owner Intent)',
                  oiMap,
                  Icons.verified_user_rounded,
                  () => _showConfirmStepDialog('ownerIntent', 'Xác Nhận Chủ Nhà'),
                ),
                const SizedBox(height: 100), // spacing for bottom button
              ],
            ),
          ),
          
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.2),
              child: const Center(
                child: CircularProgressIndicator(color: primaryBlue),
              ),
            ),
        ],
      ),
      bottomSheet: !widget.isMyJob
          ? Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: primaryBlue.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isProcessing ? null : _acceptJob,
                    icon: const Icon(Icons.handshake_rounded),
                    label: const Text(
                      'NHẬN VIỆC',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : (imgMap['status'] == 'Approved' && legMap['status'] == 'Approved' && oiMap['status'] == 'Approved')
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      )
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: Colors.green.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isProcessing ? null : _showConfirmPublishDialog,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text(
                          'DUYỆT VÀ CHO ĐĂNG',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
    );
  }

  Widget _buildApprovalStep(String title, Map<String, dynamic> statusMap, IconData icon, VoidCallback onApprove, {VoidCallback? onTap}) {
    final status = statusMap['status'] ?? 'Not Verified';
    final bool isApproved = status == 'Approved';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isApproved ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
            width: 2,
          ),
        ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isApproved ? Colors.green.withOpacity(0.1) : primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isApproved ? Colors.green[600] : primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isApproved 
                    ? 'Đã duyệt${statusMap['updatedAt'] != null ? ' (${DateTime.parse(statusMap['updatedAt']).toLocal().toString().split('.')[0]})' : ''}' 
                    : 'Chưa được duyệt',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isApproved ? Colors.green[600] : Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
          if (widget.isMyJob)
            isApproved
                ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28)
                : ElevatedButton(
                    onPressed: _isProcessing ? null : onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Duyệt', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
        ],
      ),
      ),
    );
  }
}
