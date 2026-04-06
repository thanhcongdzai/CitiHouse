import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/apartment.dart';
import '../models/user.dart';
import 'apartment_images_screen.dart';
import 'owner_detail_screen.dart';

class ApartmentApprovalDetailScreen extends StatefulWidget {
  final Apartment apartment;
  final User currentUser;
  final bool isMyJob;
  final String? focusStepKey;

  const ApartmentApprovalDetailScreen({
    super.key,
    required this.apartment,
    required this.currentUser,
    required this.isMyJob,
    this.focusStepKey,
  });

  @override
  State<ApartmentApprovalDetailScreen> createState() =>
      _ApartmentApprovalDetailScreenState();
}

class _ApartmentApprovalDetailScreenState
    extends State<ApartmentApprovalDetailScreen> {
  static const primaryBlue = Color.fromRGBO(35, 97, 219, 1);
  static const accentYellow = Color.fromRGBO(248, 192, 52, 1);

  bool _isProcessing = false;
  late Apartment _currentApt;

  @override
  void initState() {
    super.initState();
    _currentApt = widget.apartment;
  }

  bool get _isScoped => widget.focusStepKey != null;

  bool _canActOnStep(String stepKey) {
    return widget.isMyJob && (!_isScoped || widget.focusStepKey == stepKey);
  }

  Map<String, dynamic> _buildApartmentPayload({
    required Map<String, dynamic> verifications,
    String? houseStatus,
  }) {
    return {
      'id': _currentApt.id,
      'title': _currentApt.title,
      'subject': _currentApt.subject,
      'description': _currentApt.description,
      'price': _currentApt.price,
      'displayCode': _currentApt.displayCode,
      'imageUrl': _currentApt.imageUrl,
      'userImageUrl': _currentApt.imageUrl,
      'houseStatus': houseStatus ?? _currentApt.houseStatus,
      'location': {
        'ward': _currentApt.ward,
        'commune': _currentApt.commune,
      },
      'projectInfo': {
        'projectId': _currentApt.projectId ?? '',
        'project': _currentApt.project,
        'building': _currentApt.building,
        'floor': _currentApt.floor,
        'apartmentNumber': _currentApt.apartmentNumber,
      },
      'verifications': verifications,
      if (_currentApt.owner != null) 'owner': _currentApt.owner,
    };
  }

  int _countRejectedSteps(Map<String, dynamic> verifications) {
    const stepKeys = ['image', 'legal', 'ownerIntent'];
    return stepKeys.where((key) {
      final stepMap = verifications[key] as Map<String, dynamic>? ?? {};
      return stepMap['status'] == 'Rejected';
    }).length;
  }

  String _formatUpdatedAt(dynamic updatedAt) {
    if (updatedAt == null) return '';
    final parsed = DateTime.tryParse(updatedAt.toString());
    if (parsed == null) return '';
    return ' (${parsed.toLocal().toString().split('.')[0]})';
  }

  Future<void> _acceptJob() async {
    setState(() => _isProcessing = true);
    try {
      final v = _currentApt.verifications ?? {};
      if (_isScoped) {
        final stepKey = widget.focusStepKey!;
        final stepMap = v[stepKey] ?? {};
        stepMap['staffId'] = widget.currentUser.id;
        v[stepKey] = stepMap;
      } else {
        final img = v['image'] ?? {};
        final leg = v['legal'] ?? {};
        final oi = v['ownerIntent'] ?? {};

        img['staffId'] = widget.currentUser.id;
        leg['staffId'] = widget.currentUser.id;
        oi['staffId'] = widget.currentUser.id;
        v['image'] = img;
        v['legal'] = leg;
        v['ownerIntent'] = oi;
      }

      final updatedApt = _buildApartmentPayload(verifications: v);

      final response = await http.put(
        ApiConfig.uri('/api/apartments/${_currentApt.id}/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedApt),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Nhận việc thành công!'),
              backgroundColor: Colors.green[600],
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
          ),
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
        title: const Text(
          'Xác nhận cho đăng',
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
        content: const Text('Bạn có chắc chắn muốn duyệt không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
      final updatedApt = _buildApartmentPayload(
        verifications: v,
        houseStatus: 'Available',
      );

      final response = await http.put(
        ApiConfig.uri('/api/apartments/${_currentApt.id}/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedApt),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Duyệt thành công',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Bài đăng đã được duyệt.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
            SnackBar(
              content: Text('Lỗi: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showConfirmStepDialog(String stepKey, String title) async {
    if (_isScoped && widget.focusStepKey != stepKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không có quyền duyệt bước này.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (stepKey == 'image') {
      final staffImage =
          _currentApt.verifications?['image']?['staffImage']?.toString() ?? '';
      if (staffImage.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cần upload hình ảnh thực tế trước khi duyệt.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận duyệt',
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc đánh dấu mục "$title" là hợp lệ và đã được duyệt?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateStepStatus(
        stepKey,
        'Approved',
        successMessage: 'Đã duyệt $title!',
      );
    }
  }

  Future<void> _showConfirmRejectStepDialog(
      String stepKey, String title) async {
    if (_isScoped && widget.focusStepKey != stepKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không có quyền từ chối bước này.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xac nhan từ chối',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc chắn muốn đánh dấu mục "$title" là bị từ chối?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateStepStatus(
        stepKey,
        'Rejected',
        successMessage: 'Đã từ chối $title!',
      );
    }
  }

  Future<void> _updateStepStatus(
    String stepKey,
    String status, {
    required String successMessage,
  }) async {
    if (_isScoped && widget.focusStepKey != stepKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn không có quyền xử lý bước này.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final v = _currentApt.verifications ?? {};
      final stepMap = v[stepKey] ?? {};

      stepMap['status'] = status;
      stepMap['updatedAt'] = DateTime.now().toUtc().toIso8601String();
      v[stepKey] = stepMap;

      final updatedApt = _buildApartmentPayload(verifications: v);

      final response = await http.put(
        ApiConfig.uri('/api/apartments/${_currentApt.id}/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedApt),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor:
                  status == 'Approved' ? Colors.green[600] : Colors.red[600],
            ),
          );
          setState(() {
            _currentApt =
                Apartment.fromJson(json.decode(json.encode(updatedApt)));
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showConfirmRejectRequestDialog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận từ chối yêu cầu',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bài đăng này đã có 2 tiến trình bị từ chối. Bạn có chắc chắn muốn từ chối yêu cầu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Từ chối yêu cầu'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _rejectRequest();
    }
  }

  Future<void> _rejectRequest() async {
    setState(() => _isProcessing = true);
    try {
      final v = _currentApt.verifications ?? {};
      final updatedApt = _buildApartmentPayload(
        verifications: v,
        houseStatus: 'Rejected',
      );

      final response = await http.put(
        ApiConfig.uri('/api/apartments/${_currentApt.id}/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedApt),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        final projectId = (_currentApt.projectId ?? '').trim();
        if (projectId.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Đã từ chối yêu cầu nhưng không tìm thấy projectId để clear occupiedBy.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        try {
          await _clearProjectOccupiedBy(projectId);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Đã từ chối yêu cầu nhưng clear occupiedBy thất bại: $e',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              scrollable: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.cancel_rounded, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Từ chối thành công',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Yêu cầu đã bị từ chối.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
            SnackBar(
              content: Text('Lỗi: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _clearProjectOccupiedBy(String projectId) async {
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({'occupiedBy': ''});

    final withSlash = '/api/projects/$projectId/';
    final withoutSlash = '/api/projects/$projectId';

    final patchWithSlash = await http.patch(
      ApiConfig.uri(withSlash),
      headers: headers,
      body: body,
    );
    if (patchWithSlash.statusCode >= 200 && patchWithSlash.statusCode < 300) {
      return;
    }

    final patchWithoutSlash = await http.patch(
      ApiConfig.uri(withoutSlash),
      headers: headers,
      body: body,
    );
    if (patchWithoutSlash.statusCode >= 200 &&
        patchWithoutSlash.statusCode < 300) {
      return;
    }

    final putWithSlash = await http.put(
      ApiConfig.uri(withSlash),
      headers: headers,
      body: body,
    );
    if (putWithSlash.statusCode >= 200 && putWithSlash.statusCode < 300) {
      return;
    }

    throw Exception(
      'PATCH ${patchWithSlash.statusCode}/${patchWithoutSlash.statusCode}, PUT ${putWithSlash.statusCode}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = _currentApt.verifications ?? {};
    final imgMap = v['image'] as Map<String, dynamic>? ?? {};
    final legMap = v['legal'] as Map<String, dynamic>? ?? {};
    final oiMap = v['ownerIntent'] as Map<String, dynamic>? ?? {};
    final approvedAll = imgMap['status'] == 'Approved' &&
        legMap['status'] == 'Approved' &&
        oiMap['status'] == 'Approved';
    final rejectedCount = _countRejectedSteps(v);
    final canRejectRequest = rejectedCount >= 2;

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
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          Icon(Icons.location_city_rounded,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_currentApt.project} - ${_currentApt.building}',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${_currentApt.ward}, ${_currentApt.commune}',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[700]),
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
                _buildApprovalStep(
                  '1. Hình ảnh thực tế (Image)',
                  imgMap,
                  Icons.image_rounded,
                  () => _showConfirmStepDialog('image', 'Hình Ảnh Thực Tế'),
                  () => _showConfirmRejectStepDialog(
                    'image',
                    'Hình Ảnh Thực Tế',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ApartmentImagesScreen(
                          apartment: _currentApt,
                          canUploadStaffImage: _canActOnStep('image'),
                        ),
                      ),
                    ).then((updatedApartment) {
                      if (updatedApartment is Apartment && mounted) {
                        setState(() {
                          _currentApt = updatedApartment;
                        });
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildApprovalStep(
                  '2. Giấy Tờ Pháp Lý (Legal)',
                  legMap,
                  Icons.gavel_rounded,
                  () => _showConfirmStepDialog('legal', 'Giấy Tờ Pháp Lý'),
                  () => _showConfirmRejectStepDialog(
                    'legal',
                    'Giấy Tờ Pháp Lý',
                  ),
                ),
                const SizedBox(height: 12),
                _buildApprovalStep(
                  '3. Xác Nhận Chủ Nhà (Owner Intent)',
                  oiMap,
                  Icons.verified_user_rounded,
                  () =>
                      _showConfirmStepDialog('ownerIntent', 'Xác Nhận Chủ Nhà'),
                  () => _showConfirmRejectStepDialog(
                    'ownerIntent',
                    'Xác Nhận Chủ Nhà',
                  ),
                  onTap: () {
                    final ownerMap = _currentApt.owner;
                    final ownerData = ownerMap != null ? [ownerMap] : <Map<String, dynamic>>[];
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OwnerDetailScreen(
                          ownerList: ownerData,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 100),
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
          ? _buildActionSheet(
              color: primaryBlue,
              shadowColor: primaryBlue.withOpacity(0.5),
              icon: Icons.handshake_rounded,
              label: 'NHẬN VIỆC',
              onPressed: _acceptJob,
            )
          : canRejectRequest
              ? _buildActionSheet(
                  color: Colors.red,
                  shadowColor: Colors.red.withOpacity(0.35),
                  icon: Icons.cancel_rounded,
                  label: 'Từ chối yêu cầu',
                  onPressed: _showConfirmRejectRequestDialog,
                )
              : approvedAll
                  ? _buildActionSheet(
                      color: Colors.green[600]!,
                      shadowColor: Colors.green.withOpacity(0.5),
                      icon: Icons.check_circle_rounded,
                      label: 'Duyệt và Cho Đăng',
                      onPressed: _showConfirmPublishDialog,
                    )
                  : null,
    );
  }

  Widget _buildActionSheet({
    required Color color,
    required Color shadowColor,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
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
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: shadowColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _isProcessing ? null : onPressed,
            icon: Icon(icon),
            label: Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalStep(
    String title,
    Map<String, dynamic> statusMap,
    IconData icon,
    VoidCallback onApprove,
    VoidCallback onReject, {
    VoidCallback? onTap,
  }) {
    final status = statusMap['status'] ?? 'Not Verified';
    final bool isApproved = status == 'Approved';
    final bool isRejected = status == 'Rejected';

    final Color borderColor = isApproved
        ? Colors.green.withOpacity(0.3)
        : isRejected
            ? Colors.red.withOpacity(0.3)
            : Colors.grey.withOpacity(0.2);
    final Color iconBackground = isApproved
        ? Colors.green.withOpacity(0.1)
        : isRejected
            ? Colors.red.withOpacity(0.1)
            : primaryBlue.withOpacity(0.1);
    final Color iconColor = isApproved
        ? Colors.green[600]!
        : isRejected
            ? Colors.red[600]!
            : primaryBlue;
    final String timeSuffix = _formatUpdatedAt(statusMap['updatedAt']);
    final String statusText = isApproved
        ? 'Đã duyệt$timeSuffix'
        : isRejected
            ? 'Đã từ chối$timeSuffix'
            : 'Chưa được duyệt';
    final Color statusColor = isApproved
        ? Colors.green[600]!
        : isRejected
            ? Colors.red[600]!
            : Colors.orange[800]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
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
                    statusText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isMyJob)
              isApproved
                  ? const Icon(Icons.check_circle_rounded,
                      color: Colors.green, size: 28)
                  : isRejected
                      ? const Icon(Icons.cancel_rounded,
                          color: Colors.red, size: 28)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton(
                              onPressed: _isProcessing ? null : onReject,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'Từ chối',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isProcessing ? null : onApprove,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'Duyệt',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
          ],
        ),
      ),
    );
  }
}
