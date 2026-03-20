import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SelectApartmentImagesScreen extends StatefulWidget {
  final File? initialCoverImage;
  final List<File> initialSubImages;

  const SelectApartmentImagesScreen({
    super.key,
    this.initialCoverImage,
    this.initialSubImages = const [],
  });

  @override
  State<SelectApartmentImagesScreen> createState() =>
      _SelectApartmentImagesScreenState();
}

class _SelectApartmentImagesScreenState
    extends State<SelectApartmentImagesScreen> {
  static const Color primaryBlue = Color.fromRGBO(35, 97, 219, 1);
  static const Color accentYellow = Color.fromRGBO(248, 192, 52, 1);

  File? _coverImage;
  List<File> _subImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _coverImage = widget.initialCoverImage;
    _subImages = List<File>.from(widget.initialSubImages);
  }

  Future<void> _pickCoverImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _coverImage = File(picked.path));
    }
  }

  Future<void> _pickSubImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _subImages.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  void _removeSubImage(int index) {
    setState(() => _subImages.removeAt(index));
  }

  void _removeCoverImage() {
    setState(() => _coverImage = null);
  }

  void _confirm() {
    Navigator.pop(context, {
      'coverImage': _coverImage,
      'subImages': _subImages,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chọn hình ảnh',
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // === COVER IMAGE SECTION ===
          _buildSectionHeader('Ảnh bìa', Icons.image_rounded),
          const SizedBox(height: 8),
          Text(
            'Chọn 1 ảnh bìa đại diện cho căn hộ',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickCoverImage,
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _coverImage != null
                      ? primaryBlue.withValues(alpha: 0.3)
                      : Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _coverImage != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_coverImage!, fit: BoxFit.cover),
                        ),
                        // Badge
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Ảnh bìa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        // Remove button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _removeCoverImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red[600],
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 56, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        Text(
                          'Nhấn để chọn ảnh bìa',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 28),

          // === SUB IMAGES SECTION ===
          _buildSectionHeader('Ảnh chi tiết', Icons.photo_library_rounded),
          const SizedBox(height: 8),
          Text(
            'Chọn nhiều ảnh mô tả chi tiết căn hộ',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 12),

          // Add sub-images button
          GestureDetector(
            onTap: _pickSubImages,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      color: primaryBlue, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'Thêm ảnh chi tiết',
                    style: TextStyle(
                      fontSize: 16,
                      color: primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_subImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '${_subImages.length} ảnh đã chọn',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _subImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_subImages[index], fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeSubImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red[600],
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],

          const SizedBox(height: 36),

          // === CONFIRM BUTTON ===
          SizedBox(
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, Color(0xFF1A4FBF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 22),
                label: const Text(
                  'Xác nhận',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
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
              colors: [
                primaryBlue.withValues(alpha: 0.15),
                accentYellow.withValues(alpha: 0.15),
              ],
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
}
