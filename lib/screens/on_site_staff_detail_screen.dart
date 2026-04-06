import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'create_deposit_order_screen.dart';

class OnSiteStaffDetailScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final User currentUser;

  const OnSiteStaffDetailScreen({
    super.key,
    required this.appointment,
    required this.currentUser,
  });

  @override
  State<OnSiteStaffDetailScreen> createState() =>
      _OnSiteStaffDetailScreenState();
}

class _OnSiteStaffDetailScreenState extends State<OnSiteStaffDetailScreen> {
  static const primaryBlue = Color.fromRGBO(35, 97, 219, 1);
  static const accentYellow = Color.fromRGBO(248, 192, 52, 1);
  final ImagePicker _picker = ImagePicker();
  bool _isAccepting = false;
  bool _isUpdatingAppointmentTime = false;
  bool _isUploadingViewingImage = false;
  bool _isUploadingCompleteImage = false;
  DateTime? _selectedAppointmentDateTime;

  XFile? _localViewingImage;
  XFile? _localCompleteImage;

  late Map<String, dynamic> _appt;

  @override
  void initState() {
    super.initState();
    _appt = Map<String, dynamic>.from(widget.appointment);
  }

  bool _isUpdatingStatus = false;

  String _appointmentId() {
    return _appt['id']?.toString() ?? _appt['_id']?.toString() ?? '';
  }

  bool _hasImageValue(String key) {
    final value = _appt[key];
    if (value == null) return false;
    return value.toString().trim().isNotEmpty;
  }

  String _resolveImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final trimmed = value.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return ApiConfig.url(trimmed);
    }
    return ApiConfig.url('/$trimmed');
  }

  Future<void> _reloadAppointment() async {
    final id = _appointmentId();
    if (id.isEmpty) return;

    try {
      final response =
          await http.get(ApiConfig.uri('/api/viewing-appointments/$id/'));
      if (response.statusCode != 200 || !mounted) return;

      final body = json.decode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) {
        setState(() {
          _appt = {
            ..._appt,
            ...body,
          };
        });
      }
    } catch (_) {
      // Keep the current UI if a silent reload fails.
    }
  }

  Future<void> _pickAppointmentImage(String fieldKey) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;

    setState(() {
      if (fieldKey == 'viewingImage') {
        _localViewingImage = file;
      } else {
        _localCompleteImage = file;
      }
    });
  }

  Future<void> _uploadAppointmentImage(String fieldKey) async {
    final id = _appointmentId();
    if (id.isEmpty) return;

    final file = fieldKey == 'viewingImage' ? _localViewingImage : _localCompleteImage;
    if (file == null) return;

    setState(() {
      if (fieldKey == 'viewingImage') {
        _isUploadingViewingImage = true;
      } else {
        _isUploadingCompleteImage = true;
      }
    });

    try {
      final updated = Map<String, dynamic>.from(_appt)
        ..remove('_apartment')
        ..remove('_user');

      if (fieldKey == 'viewingImage') {
        updated['status'] = 'Dang xem';
      } else if (fieldKey == 'completeImage') {
        updated['status'] = 'Hoan thanh';
      }

      final request = http.MultipartRequest(
        'PUT',
        ApiConfig.uri('/api/viewing-appointments/$id/'),
      );
      request.fields['data'] = json.encode(updated);
      request.files.add(await http.MultipartFile.fromPath(fieldKey, file.path));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Map<String, dynamic>? decodedBody;
        final rawBody = utf8.decode(response.bodyBytes).trim();
        if (rawBody.isNotEmpty) {
          try {
            final decoded = json.decode(rawBody);
            if (decoded is Map<String, dynamic>) {
              decodedBody = decoded;
            }
          } catch (_) {}
        }

        if (decodedBody != null) {
          setState(() {
            _appt = {
              ..._appt,
              ...decodedBody!,
            };
            if (fieldKey == 'viewingImage') {
              _localViewingImage = null;
            } else {
              _localCompleteImage = null;
            }
          });
        } else {
          await _reloadAppointment();
          if (mounted) {
            setState(() {
              if (fieldKey == 'viewingImage') {
                _localViewingImage = null;
              } else {
                _localCompleteImage = null;
              }
            });
          }
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              fieldKey == 'viewingImage'
                  ? 'Đã upload viewing image'
                  : 'Đã upload complete image',
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload thất bại: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi upload ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          if (fieldKey == 'viewingImage') {
            _isUploadingViewingImage = false;
          } else {
            _isUploadingCompleteImage = false;
          }
        });
      }
    }
  }

  void _showImagePreview(String title, String? rawUrl) {
    final imageUrl = _resolveImageUrl(rawUrl);
    if (imageUrl.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.82,
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: InteractiveViewer(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.broken_image_rounded,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAppointmentDateTime() async {
    final now = DateTime.now();
    final currentValue = _selectedAppointmentDateTime ??
        (_appt['appointmentTime'] != null &&
                _appt['appointmentTime'].toString().isNotEmpty
            ? DateTime.tryParse(_appt['appointmentTime'].toString())?.toLocal()
            : null) ??
        now;

    final date = await showDatePicker(
      context: context,
      initialDate: currentValue.isBefore(now) ? now : currentValue,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: currentValue.hour, minute: currentValue.minute),
    );
    if (time == null || !mounted) return;

    setState(() {
      _selectedAppointmentDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _updateAppointmentDateTime() async {
    if (_selectedAppointmentDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày giờ trước khi bấm OK'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final id = _appointmentId();
    if (id.isEmpty) return;

    setState(() {
      _isUpdatingAppointmentTime = true;
    });

    try {
      final updated = Map<String, dynamic>.from(_appt)
        ..remove('_apartment')
        ..remove('_user');
      final isoUtc = _selectedAppointmentDateTime!.toUtc().toIso8601String();
      updated['appointmentTime'] = isoUtc;
      updated['status'] = 'Da xac nhan lich';

      final response = await http.put(
        ApiConfig.uri('/api/viewing-appointments/$id/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updated),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _appt['appointmentTime'] = isoUtc;
          _appt['status'] = 'Da xac nhan lich';
          _selectedAppointmentDateTime = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã cập nhật thời gian hẹn và trạng thái'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật thời gian: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingAppointmentTime = false;
        });
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final id = _appointmentId();
    if (id.isEmpty) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final updated = Map<String, dynamic>.from(_appt)
        ..remove('_apartment')
        ..remove('_user');
      updated['status'] = newStatus;

      final response = await http.put(
        ApiConfig.uri('/api/viewing-appointments/$id/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updated),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _appt['status'] = newStatus;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Đã cập nhật trạng thái!'),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi cập nhật: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  void _showStatusConfirmation(String newStatus) {
    if (newStatus == _appt['status']) return; // No change

    final statusLabels = {
      'Dang lien he': 'Đang liên hệ',
      'Da xac nhan lich': 'Đã xác nhận lịch',
      'Dang xem': 'Đang xem',
      'Hoan thanh': 'Hoàn thành',
    };
    final label = statusLabels[newStatus] ?? newStatus;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận cập nhật'),
        content:
            Text('Bạn có chắc chắn muốn chuyển trạng thái?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (newStatus == 'Hoan thanh') {
                _showCompleteConfirmation();
              } else {
                _updateStatus(newStatus);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue, foregroundColor: Colors.white),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showCompleteConfirmation() {
    if (!_hasImageValue('viewingImage') || !_hasImageValue('completeImage')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Cần đủ ảnh xem nhà và hoàn thành xem nhà trước khi close deal'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm hoàn thành',
            style: TextStyle(color: Colors.red)),
        content:
            const Text('Khi đã close deal sẽ không thể hoàn tác. Xác nhận?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus('Hoan thanh');
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Chắc chắn'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptAppointment() async {
    final id = _appointmentId();
    if (id.isEmpty) return;

    setState(() {
      _isAccepting = true;
    });

    try {
      // Build the updated payload, keeping all existing fields
      final updated = Map<String, dynamic>.from(_appt)
        ..remove('_apartment')
        ..remove('_user');
      updated['staffInCharge'] = widget.currentUser.id;

      final response = await http.put(
        ApiConfig.uri('/api/viewing-appointments/$id/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updated),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Nhận việc thành công'),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.pop(context, true); // Return true to trigger refresh
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi cập nhật: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }

  String _formatDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return 'Chưa có';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _formatPrice(dynamic price) {
    try {
      final n = (price as num).toInt();
      if (n >= 1000000000) {
        return '${(n / 1000000000).toStringAsFixed(1)} tỷ';
      } else if (n >= 1000000) {
        return '${(n / 1000000).toStringAsFixed(0)} triệu';
      }
      return '$n đ';
    } catch (_) {
      return price.toString();
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'Yeu cau xem':
        return Colors.orange;
      case 'Dang lien he':
        return Colors.deepOrange;
      case 'Da xac nhan':
      case 'Da xac nhan lich':
        return Colors.blue;
      case 'Dang xem':
        return Colors.purple;
      case 'Hoan thanh':
        return Colors.green;
      case 'Huy':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'Yeu cau xem':
        return 'Yêu cầu xem';
      case 'Dang lien he':
        return 'Đang liên hệ';
      case 'Da xac nhan':
        return 'Đã xác nhận';
      case 'Da xac nhan lich':
        return 'Đã xác nhận lịch';
      case 'Dang xem':
        return 'Đang xem';
      case 'Hoan thanh':
        return 'Hoàn thành';
      case 'Huy':
        return 'Đã hủy';
      default:
        return status ?? 'Unknown';
    }
  }

  Widget _buildImageUploadCard({
    required String title,
    required bool hasImage,
    required String imageUrl,
    required XFile? localImage,
    required bool isUploading,
    required bool canUpload,
    required VoidCallback onPickLocal,
    required VoidCallback onConfirmSend,
    required VoidCallback onView,
  }) {
    final hasAnyImage = hasImage || localImage != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasAnyImage
              ? Colors.green.withOpacity(0.35)
              : primaryBlue.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasAnyImage ? Icons.check_circle_rounded : Icons.image_outlined,
                color: hasAnyImage ? Colors.green : primaryBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            localImage != null
                ? 'Đã chọn ảnh (chưa gửi)'
                : (hasImage ? 'Đã tải ảnh lên' : 'Chưa có ảnh'),
            style: TextStyle(
              fontSize: 13,
              color: localImage != null
                  ? Colors.orange[700]
                  : (hasImage ? Colors.green[700] : Colors.grey[700]),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (localImage != null) ...[
            const SizedBox(height: 6),
            Text(
              localImage.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[600],
              ),
            ),
          ] else if (imageUrl.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              imageUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isUploading || !canUpload ? null : onPickLocal,
                  icon: const Icon(Icons.image_rounded, size: 18),
                  label: Text(hasAnyImage ? 'Chọn lại' : 'Chọn ảnh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    side: BorderSide(color: primaryBlue.withOpacity(0.35)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (localImage != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isUploading || !canUpload ? null : onConfirmSend,
                    icon: isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Xác nhận gửi', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: hasImage ? onView : null,
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text('Xem ảnh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          hasImage ? primaryBlue : Colors.grey[350],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apartment = _appt['_apartment'] as Map<String, dynamic>?;
    final user = _appt['_user'] as Map<String, dynamic>?;
    final customer = _appt['customer'] as Map<String, dynamic>?;
    final status = _appt['status']?.toString();
    final staffInCharge = _appt['staffInCharge'];
    final appointmentTime = _appt['appointmentTime']?.toString();

    final isMine = staffInCharge?.toString() == widget.currentUser.id;
    final hasStaff =
        staffInCharge != null && staffInCharge.toString().isNotEmpty;

    final customerPhone = customer?['phone']?.toString() ?? '';
    final userPhone = user?['phone']?.toString() ?? '';
    final isReferred = customerPhone.isNotEmpty &&
        userPhone.isNotEmpty &&
        customerPhone != userPhone;

    final aptTitle =
        apartment?['title']?.toString() ?? 'Căn hộ #${_appt['apartmentId']}';
    final aptProject = apartment?['projectInfo']?['project']?.toString() ?? '';
    final aptBuilding =
        apartment?['projectInfo']?['building']?.toString() ?? '';
    final aptFloor = apartment?['projectInfo']?['floor']?.toString() ?? '';
    final aptNumber =
        apartment?['projectInfo']?['apartmentNumber']?.toString() ?? '';
    final aptWard = apartment?['location']?['ward']?.toString() ?? '';
    final aptCommune = apartment?['location']?['commune']?.toString() ?? '';
    final aptPrice = apartment?['price'];
    final aptStatus = apartment?['houseStatus']?.toString() ?? '';

    final userName = user != null
        ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim()
        : _appt['userId']?.toString() ?? 'Unknown';
    final userPhone2 = user?['phone']?.toString() ?? '';

    final customerName = customer?['name']?.toString() ?? '';
    final customerPhoneDisplay = customer?['phone']?.toString() ?? '';
    final viewingImage = _appt['viewingImage']?.toString() ?? '';
    final completeImage = _appt['completeImage']?.toString() ?? '';
    final hasViewingImage = _hasImageValue('viewingImage');
    final hasCompleteImage = _hasImageValue('completeImage');
    final canFinishAppointment =
        status == 'Dang xem' && hasViewingImage && hasCompleteImage;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryBlue),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'Chi Tiết Lịch Hẹn',
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: isMine
                ? (status == 'Hoan thanh')
                    ? LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                : LinearGradient(
                    colors: [accentYellow, primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            boxShadow: [
              BoxShadow(
                color: isMine
                    ? (status == 'Hoan thanh'
                        ? Colors.green.withOpacity(0.4)
                        : Colors.blue.withOpacity(0.4))
                    : primaryBlue.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(21),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.08),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(21)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TRẠNG THÁI',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _statusColor(status).withOpacity(0.5),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: _statusColor(status).withOpacity(0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Text(
                            _statusLabel(status),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _statusColor(status),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── APPOINTMENT TIME ────────────────────────────
                        _SectionHeader(
                            icon: Icons.schedule_rounded,
                            label: 'Thời gian hẹn'),
                        const SizedBox(height: 10),
                        _InfoRow(Icons.calendar_today_rounded,
                            _formatDateTime(appointmentTime)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAFF),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: primaryBlue.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isUpdatingAppointmentTime
                                      ? null
                                      : _pickAppointmentDateTime,
                                  icon: const Icon(Icons.edit_calendar_rounded,
                                      size: 18),
                                  label: Text(
                                    _selectedAppointmentDateTime == null
                                        ? 'Chọn ngày giờ mới'
                                        : _formatDateTime(
                                            _selectedAppointmentDateTime!
                                                .toUtc()
                                                .toIso8601String(),
                                          ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: primaryBlue,
                                    side: BorderSide(
                                        color: primaryBlue.withOpacity(0.45)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 40,
                                child: ElevatedButton(
                                  onPressed: _isUpdatingAppointmentTime
                                      ? null
                                      : _updateAppointmentDateTime,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: _isUpdatingAppointmentTime
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('OK'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildImageUploadCard(
                          title: 'Hình ảnh xem nhà',
                          hasImage: hasViewingImage,
                          imageUrl: viewingImage,
                          localImage: _localViewingImage,
                          isUploading: _isUploadingViewingImage,
                          canUpload: isMine,
                          onPickLocal: () =>
                              _pickAppointmentImage('viewingImage'),
                          onConfirmSend: () =>
                              _uploadAppointmentImage('viewingImage'),
                          onView: () =>
                              _showImagePreview('Viewing Image', viewingImage),
                        ),
                        const SizedBox(height: 12),
                        _buildImageUploadCard(
                          title: 'Hình ảnh hoàn thành',
                          hasImage: hasCompleteImage,
                          imageUrl: completeImage,
                          localImage: _localCompleteImage,
                          isUploading: _isUploadingCompleteImage,
                          canUpload: isMine,
                          onPickLocal: () =>
                              _pickAppointmentImage('completeImage'),
                          onConfirmSend: () =>
                              _uploadAppointmentImage('completeImage'),
                          onView: () => _showImagePreview(
                              'Complete Image', completeImage),
                        ),

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // ── APARTMENT INFO ──────────────────────────────
                        _SectionHeader(
                            icon: Icons.apartment_rounded,
                            label: 'Apartment Information'),
                        const SizedBox(height: 10),
                        _InfoRow(Icons.home_work_rounded, aptTitle),
                        if (aptProject.isNotEmpty || aptBuilding.isNotEmpty)
                          _InfoRow(Icons.business_rounded,
                              'Dự án / Tòa: $aptProject - $aptBuilding'),
                        if (aptFloor.isNotEmpty || aptNumber.isNotEmpty)
                          _InfoRow(Icons.layers_rounded,
                              'Tầng $aptFloor - Căn $aptNumber'),
                        if (aptWard.isNotEmpty || aptCommune.isNotEmpty)
                          _InfoRow(Icons.location_on_rounded,
                              '$aptWard, $aptCommune'),
                        if (aptPrice != null)
                          _InfoRow(Icons.attach_money_rounded,
                              'Giá: ${_formatPrice(aptPrice)}'),
                        if (aptStatus.isNotEmpty)
                          _InfoRow(
                              Icons.info_outline_rounded, 'Status: $aptStatus'),

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // ── USER / BOOKER INFO ──────────────────────────
                        _SectionHeader(
                            icon: Icons.person_rounded, label: 'Booker'),
                        const SizedBox(height: 10),
                        _InfoRow(Icons.badge_rounded,
                            userName.isNotEmpty ? userName : 'Unknown'),
                        if (userPhone2.isNotEmpty)
                          _InfoRow(Icons.phone_rounded, userPhone2),

                        // ── CUSTOMER (referred) ─────────────────────────
                        if (isReferred) ...[
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          _SectionHeader(
                            icon: Icons.handshake_rounded,
                            label: 'Khách được môi giới',
                            color: const Color(0xFF9C27B0),
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(Icons.person_outline_rounded, customerName,
                              iconColor: const Color(0xFF9C27B0)),
                          _InfoRow(Icons.phone_outlined, customerPhoneDisplay,
                              iconColor: const Color(0xFF9C27B0)),
                        ],

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // ── STAFF IN CHARGE ─────────────────────────────
                        if (hasStaff) ...[
                          _InfoRow(
                            Icons.manage_accounts_rounded,
                            isMine
                                ? '✅ Bạn đang phụ trách'
                                : '👤 Đã có nhân viên phụ trách',
                            iconColor: isMine ? Colors.green : Colors.blueGrey,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: (!hasStaff)
              ? SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isAccepting ? null : _acceptAppointment,
                    icon: _isAccepting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.assignment_turned_in_rounded,
                            size: 22),
                    label: Text(
                      _isAccepting ? 'Đang Nhận Việc...' : 'Nhận Việc',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: primaryBlue.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                )
              : (isMine)
                  ? (status == 'Hoan thanh')
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: Colors.green.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: Colors.green[600], size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Công việc đã hoàn thành !',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  // Navigate to CreateDepositOrderScreen
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CreateDepositOrderScreen(
                                        apartmentId: widget
                                                .appointment['apartmentId']
                                                ?.toString() ??
                                            '',
                                        staffId: widget.currentUser?.id ?? '',
                                        appointmentId: widget.appointment['_id']
                                                ?.toString() ??
                                            widget.appointment['id']
                                                ?.toString() ??
                                            '',
                                        currentUser: widget.currentUser,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    // Could refresh something here, but we'll already trigger a pop later
                                    Navigator.pop(context, true);
                                  }
                                },
                                icon: const Icon(Icons.request_quote_rounded,
                                    size: 22),
                                label: const Text(
                                  'Tạo yêu cầu đặt cọc',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentYellow,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shadowColor: accentYellow.withOpacity(0.35),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : (status == 'Da yeu cau coc')
                          ? const SizedBox.shrink()
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 12),
                                if (canFinishAppointment)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: ElevatedButton.icon(
                                      onPressed: _isUpdatingStatus
                                          ? null
                                          : _showCompleteConfirmation,
                                      icon: const Icon(
                                        Icons.verified_rounded,
                                        size: 22,
                                      ),
                                      label: const Text(
                                        'Hoàn thành',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  )
                                else if (status == 'Dang xem')
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.orange.shade200,
                                      ),
                                    ),
                                    child: const Text(
                                      'Cần upload đủ ảnh xem nhà và hoàn thành xem để hoàn tất',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                              ],
                            )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded,
                              color: Colors.grey[500], size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Đã có nhân viên phụ trách',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    this.color = const Color.fromRGBO(35, 97, 219, 1),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;

  const _InfoRow(this.icon, this.text,
      {this.iconColor = const Color(0xFF9E9E9E)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
