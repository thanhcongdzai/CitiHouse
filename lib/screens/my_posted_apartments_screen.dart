import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/apartment.dart';
import '../models/user.dart';
import 'apartment_detail_screen.dart';

class MyPostedApartmentsScreen extends StatefulWidget {
  final User currentUser;

  const MyPostedApartmentsScreen({super.key, required this.currentUser});

  @override
  State<MyPostedApartmentsScreen> createState() => _MyPostedApartmentsScreenState();
}

class _MyPostedApartmentsScreenState extends State<MyPostedApartmentsScreen> {
  static const primaryBlue = Color.fromRGBO(35, 97, 219, 1);
  static const accentYellow = Color.fromRGBO(248, 192, 52, 1);
  final Color bgBottom = const Color(0xFFF7FBFF);

  bool _isLoading = true;
  String? _error;
  List<Apartment> _myApartments = [];

  @override
  void initState() {
    super.initState();
    _fetchMyApartments();
  }

  Future<void> _fetchMyApartments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await http.get(ApiConfig.uri('/api/apartments/'));
      if (res.statusCode != 200) {
        throw Exception('Lỗi tải dữ liệu: ${res.statusCode}');
      }

      final data = json.decode(utf8.decode(res.bodyBytes)) as List<dynamic>;
      final allApts = data.map((e) => Apartment.fromJson(e)).toList();

      final userId = widget.currentUser.id;
      final myApts = allApts.where((apt) {
        return apt.postedBy == userId;
      }).toList();

      setState(() {
        _myApartments = myApts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(int amount) {
    if (amount == 0) return '0 đ';
    final formatter = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${amount.toString().replaceAllMapped(formatter, (m) => '.')} đ';
  }

  String _formatStatus(String status) {
    if (status == 'inContract') return 'In Contract';
    if (status == 'available') return 'Available';
    if (status.toLowerCase() == 'rejected') return 'Rejected';
    if (status.toLowerCase() == 'pending') return 'Pending';
    return status.isNotEmpty ? status : 'Pending';
  }

  Color _getStatusColor(String status) {
    if (status == 'inContract') return Colors.blue;
    if (status == 'available') return Colors.green;
    if (status.toLowerCase() == 'rejected') return Colors.red;
    return Colors.black.withOpacity(0.6);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: bgBottom,
        appBar: AppBar(
          title: const Text(
            'My posted apartment',
            style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w800, fontSize: 20),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          iconTheme: const IconThemeData(color: primaryBlue),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _fetchMyApartments,
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            labelColor: primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryBlue,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
            tabs: [
              Tab(text: 'My List'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBody(showRejected: false),
            _buildBody(showRejected: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({required bool showRejected}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryBlue));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchMyApartments,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white),
            )
          ],
        ),
      );
    }

    final filteredList = _myApartments.where((apt) {
      final isAptRejected = apt.houseStatus.toLowerCase() == 'rejected';
      return showRejected ? isAptRejected : !isAptRejected;
    }).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
              child: Icon(Icons.home_work_outlined, size: 72, color: Colors.blue[400]),
            ),
            const SizedBox(height: 20),
            Text(
              showRejected ? 'Không có căn hộ bị từ chối' : 'Bạn chưa đăng căn hộ nào',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyApartments,
      color: primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final apt = filteredList[index];
          
          const sampleImage = 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=500&auto=format&fit=crop&q=60';
          final String firstImage = apt.imageUrl.split(',').first.trim();
          final bool hasValidImage = firstImage.isNotEmpty && firstImage.startsWith('http') && firstImage != 'https://image1.com';
          final imageToShow = hasValidImage ? firstImage : sampleImage;

          return GestureDetector(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Image.network(
                        imageToShow,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.broken_image_rounded, size: 50, color: Colors.grey)),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(apt.houseStatus),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatStatus(apt.houseStatus),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          apt.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${apt.project}, ${apt.commune}, ${apt.ward}',
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _formatCurrency(apt.price),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryBlue),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
