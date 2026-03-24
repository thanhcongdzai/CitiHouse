import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../models/apartment.dart';

class ApartmentImagesScreen extends StatefulWidget {
  final Apartment apartment;
  final bool canUploadStaffImage;

  const ApartmentImagesScreen({
    super.key,
    required this.apartment,
    this.canUploadStaffImage = false,
  });

  @override
  State<ApartmentImagesScreen> createState() => _ApartmentImagesScreenState();
}

class _ApartmentImagesScreenState extends State<ApartmentImagesScreen> {
  static const primaryBlue = Color.fromRGBO(35, 97, 219, 1);

  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  late Apartment _apartment;
  List<XFile> _selectedStaffImages = [];

  @override
  void initState() {
    super.initState();
    _apartment = widget.apartment;
  }

  List<String> _parseImageList(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.startsWith('http'))
        .toList();
  }

  List<String> get _userImages {
    final apiImages = _parseImageList(_apartment.imageUrl)
        .where((e) => e != 'https://image1.com')
        .toList();
    return apiImages.isNotEmpty
        ? apiImages
        : [
            'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&auto=format&fit=crop&q=60',
          ];
  }

  List<String> get _staffImages {
    final raw =
        _apartment.verifications?['image']?['staffImage']?.toString() ?? '';
    return _parseImageList(raw);
  }

  Future<void> _pickStaffImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty || !mounted) return;

    setState(() {
      final existingPaths = _selectedStaffImages.map((e) => e.path).toSet();
      final newImages =
          picked.where((image) => !existingPaths.contains(image.path));
      _selectedStaffImages = [..._selectedStaffImages, ...newImages];
    });
  }

  void _clearSelectedStaffImages() {
    setState(() {
      _selectedStaffImages = [];
    });
  }

  Future<void> _uploadStaffImages() async {
    if (_selectedStaffImages.isEmpty) return;

    setState(() => _isUploading = true);
    try {
      final request = http.MultipartRequest(
        'PUT',
        ApiConfig.uri('/api/apartments/${_apartment.id}/'),
      );
      request.fields['data'] = '{}';
      for (final image in _selectedStaffImages) {
        request.files.add(
          await http.MultipartFile.fromPath('staffImage', image.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = json.decode(utf8.decode(response.bodyBytes));
        final updatedApartment = Apartment.fromJson(body);
        if (!mounted) return;
        setState(() {
          _apartment = updatedApartment;
          _selectedStaffImages = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload staff image thành công'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload thất bại: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi upload: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _apartment);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: AppBar(
          title: const Text(
            'Hình Ảnh Thực Tế',
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
            onPressed: () => Navigator.pop(context, _apartment),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('Ảnh của người dùng'),
            const SizedBox(height: 12),
            _buildImageGrid(_userImages),
            const SizedBox(height: 24),
            _buildSectionTitle('Ảnh xác thực của nhân viên'),
            const SizedBox(height: 12),
            _staffImages.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'Chưa có ảnh xác thực nào được nhân viên upload.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : _buildImageGrid(_staffImages),
            if (widget.canUploadStaffImage) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Chọn ảnh xác thực'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _isUploading ? null : _pickStaffImages,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryBlue.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                  child: _selectedStaffImages.isEmpty
                      ? const Column(
                          children: [
                            SizedBox(height: 12),
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: primaryBlue,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Nhấn để chọn ảnh',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Ảnh đã chọn hiển thị trong khung này',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 12),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.photo_library_outlined,
                                  color: primaryBlue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Đã chọn ${_selectedStaffImages.length} ảnh',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildLocalImageGrid(_selectedStaffImages),
                          ],
                        ),
                ),
              ),
              if (_selectedStaffImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isUploading ? null : _clearSelectedStaffImages,
                  child: const Text('Bỏ chọn tất cả'),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isUploading || _selectedStaffImages.isEmpty
                      ? null
                      : _uploadStaffImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(_isUploading ? 'Đang upload...' : 'Upload ảnh'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: primaryBlue,
      ),
    );
  }

  Widget _buildImageGrid(List<String> images) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullScreenImageViewer(
                  images: images,
                  initialIndex: index,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Hero(
                tag: 'fullscreen_image_${images[index]}_$index',
                child: Image.network(
                  images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocalImageGrid(List<XFile> images) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(images[index].path),
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.images.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Hero(
              tag: 'fullscreen_image_${widget.images[index]}_$index',
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 60),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
