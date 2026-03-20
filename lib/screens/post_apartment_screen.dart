import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'select_apartment_images_screen.dart';

class PostApartmentScreen extends StatefulWidget {
  final User? currentUser;
  const PostApartmentScreen({super.key, this.currentUser});

  @override
  State<PostApartmentScreen> createState() => _PostApartmentScreenState();
}

class _PostApartmentScreenState extends State<PostApartmentScreen> {
  static const Color primaryBlue = Color.fromRGBO(35, 97, 219, 1);
  static const Color accentYellow = Color.fromRGBO(248, 192, 52, 1);

  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  // Project data
  List<Map<String, dynamic>> _allProjects = [];
  bool _loadingProjects = true;

  // Cascading selections
  String? _selectedProject;
  String? _selectedBuilding;
  int? _selectedFloor;
  String? _selectedApartmentNumber;

  // Derived option lists
  List<String> _projectOptions = [];
  List<String> _buildingOptions = [];
  List<int> _floorOptions = [];
  List<String> _apartmentOptions = [];

  // The matched unit after full selection
  Map<String, dynamic>? _selectedUnit;

  bool _isSubmitting = false;

  // Image upload
  File? _coverImage;
  List<File> _subImages = [];

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchProjects() async {
    try {
      final resp = await http.get(Uri.parse('http://127.0.0.1:8000/api/projects/'));
      if (resp.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(resp.bodyBytes));
        setState(() {
          _allProjects = data
              .map((e) => Map<String, dynamic>.from(e))
              .where((p) => p['occupiedBy'] == null)
              .toList();
          final names = <String>{};
          for (var p in _allProjects) {
            if (p['project'] != null && p['project'].toString().isNotEmpty) {
              names.add(p['project'].toString());
            }
          }
          _projectOptions = names.toList()..sort();
          _loadingProjects = false;
        });
      } else {
        setState(() => _loadingProjects = false);
      }
    } catch (_) {
      setState(() => _loadingProjects = false);
    }
  }

  void _onProjectSelected(String? project) {
    setState(() {
      _selectedProject = project;
      _selectedBuilding = null;
      _selectedFloor = null;
      _selectedApartmentNumber = null;
      _selectedUnit = null;

      if (project == null) {
        _buildingOptions = [];
        _floorOptions = [];
        _apartmentOptions = [];
        return;
      }

      final filtered = _allProjects.where((p) => p['project'] == project).toList();
      final buildings = <String>{};
      for (var p in filtered) {
        if (p['building'] != null && p['building'].toString().isNotEmpty) {
          buildings.add(p['building'].toString());
        }
      }
      _buildingOptions = buildings.toList()..sort();
      _floorOptions = [];
      _apartmentOptions = [];
    });
  }

  void _onBuildingSelected(String? building) {
    setState(() {
      _selectedBuilding = building;
      _selectedFloor = null;
      _selectedApartmentNumber = null;
      _selectedUnit = null;

      if (building == null) {
        _floorOptions = [];
        _apartmentOptions = [];
        return;
      }

      final filtered = _allProjects
          .where((p) => p['project'] == _selectedProject && p['building'] == building)
          .toList();

      final floors = <int>{};
      for (var p in filtered) {
        final f = p['floor'];
        if (f != null) floors.add((f as num).toInt());
      }
      _floorOptions = floors.toList()..sort();
      _apartmentOptions = [];
    });
  }

  void _onFloorSelected(int? floor) {
    setState(() {
      _selectedFloor = floor;
      _selectedApartmentNumber = null;
      _selectedUnit = null;

      if (floor == null) {
        _apartmentOptions = [];
        return;
      }

      final filtered = _allProjects
          .where((p) =>
              p['project'] == _selectedProject &&
              p['building'] == _selectedBuilding &&
              (p['floor'] as num?)?.toInt() == floor)
          .toList();

      final apts = <String>{};
      for (var p in filtered) {
        if (p['apartmentNumber'] != null && p['apartmentNumber'].toString().isNotEmpty) {
          apts.add(p['apartmentNumber'].toString());
        }
      }
      _apartmentOptions = apts.toList()..sort();
    });
  }

  void _onApartmentSelected(String? apt) {
    setState(() {
      _selectedApartmentNumber = apt;
      if (apt == null) {
        _selectedUnit = null;
        return;
      }
      _selectedUnit = _allProjects.firstWhere(
        (p) =>
            p['project'] == _selectedProject &&
            p['building'] == _selectedBuilding &&
            (p['floor'] as num?)?.toInt() == _selectedFloor &&
            p['apartmentNumber'] == apt,
        orElse: () => {},
      );
    });
  }

  String _generateDisplayCode() {
    final rng = Random();
    final digits = List.generate(7, (_) => rng.nextInt(10)).join();
    return 'CH-$digits';
  }

  Future<void> _navigateToImagePicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => SelectApartmentImagesScreen(
          initialCoverImage: _coverImage,
          initialSubImages: _subImages,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _coverImage = result['coverImage'] as File?;
        _subImages = List<File>.from(result['subImages'] ?? []);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn đầy đủ thông tin căn hộ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      "title": _titleCtrl.text.trim(),
      "subject": _subjectCtrl.text.trim(),
      "description": _descCtrl.text.trim(),
      "price": int.tryParse(_priceCtrl.text.trim().replaceAll(',', '')) ?? 0,
      "location": {
        "ward": _selectedUnit!['commute'] ?? '',
        "commune": _selectedUnit!['ward'] ?? '',
      },
      "projectInfo": {
        "projectId": _selectedUnit!['_id'] ?? _selectedUnit!['id'] ?? '',
        "project": _selectedUnit!['project'] ?? '',
        "building": _selectedUnit!['building'] ?? '',
        "floor": _selectedUnit!['floor'] ?? 0,
        "apartmentNumber": _selectedUnit!['apartmentNumber'] ?? '',
      },
      "displayCode": _generateDisplayCode(),
      "imageUrl": "",
      "houseStatus": "Pending",
      "owner": {},
      "verifications": {
        "image": {
          "status": "",
          "staffId": null,
          "updatedAt": ""
        },
        "legal": {
          "status": "",
          "staffId": null,
          "updatedAt": ""
        },
        "ownerIntent": {
          "status": "",
          "staffId": null,
          "updatedAt": ""
        }
      },
      "postedBy": widget.currentUser?.id ?? '',
    };

    try {
      final bool hasImages = _coverImage != null || _subImages.isNotEmpty;
      http.Response resp;

      if (hasImages) {
        // Multipart request: send data fields + image files together
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('http://127.0.0.1:8000/api/apartments/'),
        );

        // Send entire payload as JSON in the 'data' field
        request.fields['data'] = json.encode(payload);

        // Add cover image first
        if (_coverImage != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'userImage',
            _coverImage!.path,
          ));
        }

        // Add sub images
        for (var img in _subImages) {
          request.files.add(await http.MultipartFile.fromPath(
            'userImages',
            img.path,
          ));
        }

        final streamedResp = await request.send();
        resp = await http.Response.fromStream(streamedResp);
      } else {
        // No images: keep the original JSON POST
        resp = await http.post(
          Uri.parse('http://127.0.0.1:8000/api/apartments/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload),
        );
      }

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Đăng nhà thành công!', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: Colors.green[700],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      } else {
        _showError('Lỗi ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError('Không kết nối được server: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: Colors.red[700],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đăng nhà môi giới',
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _loadingProjects
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSectionHeader('Thông tin cơ bản', Icons.info_outline_rounded),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _titleCtrl,
                    label: 'Tiêu đề *',
                    hint: 'Nhập tiêu đề bài đăng',
                    icon: Icons.title_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _subjectCtrl,
                    label: 'Chủ đề *',
                    hint: 'Nhập chủ đề',
                    icon: Icons.subject_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập chủ đề' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descCtrl,
                    label: 'Mô tả',
                    hint: 'Mô tả chi tiết về căn hộ...',
                    icon: Icons.description_rounded,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _priceCtrl,
                    label: 'Giá (VND) *',
                    hint: 'Nhập giá (VD: 3500000000)',
                    icon: Icons.attach_money_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Vui lòng nhập giá';
                      if ((int.tryParse(v.trim()) ?? 0) <= 0) return 'Giá phải lớn hơn 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  _buildSectionHeader('Thông tin dự án', Icons.business_rounded),
                  const SizedBox(height: 12),
                  _buildDropdown<String>(
                    label: 'Dự án *',
                    icon: Icons.location_city_rounded,
                    value: _selectedProject,
                    items: _projectOptions,
                    itemLabel: (v) => v,
                    onChanged: _onProjectSelected,
                    hint: 'Chọn dự án',
                    validator: (v) => v == null ? 'Vui lòng chọn dự án' : null,
                  ),
                  if (_buildingOptions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDropdown<String>(
                      label: 'Tòa nhà *',
                      icon: Icons.apartment_rounded,
                      value: _selectedBuilding,
                      items: _buildingOptions,
                      itemLabel: (v) => v,
                      onChanged: _onBuildingSelected,
                      hint: 'Chọn tòa nhà',
                      validator: (v) => v == null ? 'Vui lòng chọn tòa nhà' : null,
                    ),
                  ],
                  if (_floorOptions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDropdown<int>(
                      label: 'Tầng *',
                      icon: Icons.layers_rounded,
                      value: _selectedFloor,
                      items: _floorOptions,
                      itemLabel: (v) => 'Tầng $v',
                      onChanged: _onFloorSelected,
                      hint: 'Chọn tầng',
                      validator: (v) => v == null ? 'Vui lòng chọn tầng' : null,
                    ),
                  ],
                  if (_apartmentOptions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildDropdown<String>(
                      label: 'Số căn hộ *',
                      icon: Icons.door_front_door_rounded,
                      value: _selectedApartmentNumber,
                      items: _apartmentOptions,
                      itemLabel: (v) => v,
                      onChanged: _onApartmentSelected,
                      hint: 'Chọn số căn hộ',
                      validator: (v) => v == null ? 'Vui lòng chọn căn hộ' : null,
                    ),
                  ],
                  if (_selectedUnit != null) ...[
                    const SizedBox(height: 16),
                    _buildLocationPreview(),
                  ],
                  const SizedBox(height: 28),
                  _buildSectionHeader('Hình ảnh', Icons.photo_camera_rounded),
                  const SizedBox(height: 12),
                  _buildImageUploadButton(),
                  const SizedBox(height: 36),
                  _buildSubmitButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue.withValues(alpha: 0.15), accentYellow.withValues(alpha: 0.15)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryBlue, size: 22),
          labelStyle: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w600),
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: maxLines > 1 ? 16 : 0,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    required String hint,
    String? Function(T?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<T>(
        value: value,
        validator: validator,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryBlue, size: 22),
          labelStyle: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w600),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
        hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue),
        style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
        items: items
            .map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item)),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildLocationPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue.withValues(alpha: 0.07), accentYellow.withValues(alpha: 0.07)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: primaryBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                'Thông tin vị trí (tự động điền)',
                style: TextStyle(
                  color: primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _locationRow('Phường/Xã', _selectedUnit!['commute'] ?? ''),
          _locationRow('Quận/Huyện', _selectedUnit!['ward'] ?? ''),
        ],
      ),
    );
  }

  Widget _locationRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$key: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadButton() {
    final int totalImages = (_coverImage != null ? 1 : 0) + _subImages.length;
    return GestureDetector(
      onTap: _navigateToImagePicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: totalImages > 0
                ? primaryBlue.withValues(alpha: 0.3)
                : Colors.grey[300]!,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    totalImages > 0
                        ? Icons.photo_library_rounded
                        : Icons.add_photo_alternate_outlined,
                    color: primaryBlue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        totalImages > 0
                            ? '$totalImages ảnh đã chọn'
                            : 'Thêm hình ảnh',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: totalImages > 0 ? primaryBlue : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        totalImages > 0
                            ? 'Nhấn để thay đổi'
                            : 'Chọn ảnh bìa và ảnh chi tiết',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[400], size: 28),
              ],
            ),
            // Thumbnail preview
            if (totalImages > 0) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 72,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_coverImage != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_coverImage!,
                                  width: 72, height: 72, fit: BoxFit.cover),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryBlue.withValues(alpha: 0.85),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(10),
                                    bottomRight: Radius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Bìa',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ..._subImages.map((img) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(img,
                                width: 72, height: 72, fit: BoxFit.cover),
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 60,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isSubmitting
                ? [Colors.grey[400]!, Colors.grey[400]!]
                : [primaryBlue, const Color(0xFF1A4FBF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: _isSubmitting
              ? []
              : [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    SizedBox(width: 12),
                    Text(
                      'Đăng tin ngay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
