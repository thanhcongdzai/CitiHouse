import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/apartment.dart';
import 'staff_drawer.dart';
import 'apartment_approval_detail_screen.dart';

class ApartmentApprovalStaffScreen extends StatefulWidget {
  final User currentUser;
  final VoidCallback onLogout;

  const ApartmentApprovalStaffScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  State<ApartmentApprovalStaffScreen> createState() => _ApartmentApprovalStaffScreenState();
}

class _ApartmentApprovalStaffScreenState extends State<ApartmentApprovalStaffScreen> {
  static const primaryBlue = Color.fromRGBO(35, 97, 219, 1);
  static const accentYellow = Color.fromRGBO(248, 192, 52, 1);

  List<Apartment> _apartments = [];
  bool _isLoading = true;
  String? _error;
  bool _showOnlyMyJobs = false; // Toggle between "Available Jobs" and "Accepted Jobs"

  @override
  void initState() {
    super.initState();
    _fetchPendingApartments();
  }

  Future<void> _fetchPendingApartments() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await http.get(ApiConfig.uri('/api/apartments/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          final allApts = data.map((json) => Apartment.fromJson(json)).toList();
          
          _apartments = allApts.where((apt) {
            final v = apt.verifications;
            if (v == null) return false;
            
            // Only keep apartments that are in Pending state (need processing or final publish)
            return apt.houseStatus == 'Pending';
          }).toList();
          
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Server error: ${response.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Connection error: $e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter apartments based on active tab
    final displayedApartments = _showOnlyMyJobs
        ? _apartments.where((apt) {
            final v = apt.verifications;
            if (v == null) return false;
            final imgStaff = v['image']?['staffId']?.toString();
            final legStaff = v['legal']?['staffId']?.toString();
            final oiStaff = v['ownerIntent']?['staffId']?.toString();
            
            // At least one step assigned to this user
            return imgStaff == widget.currentUser.id || 
                   legStaff == widget.currentUser.id || 
                   oiStaff == widget.currentUser.id;
          }).toList()
        : _apartments.where((apt) {
            final v = apt.verifications;
            if (v == null) return false;
            final imgStaff = v['image']?['staffId'];
            final legStaff = v['legal']?['staffId'];
            final oiStaff = v['ownerIntent']?['staffId'];
            
            // All three steps are unassigned
            return (imgStaff == null || imgStaff.toString().isEmpty) && 
                   (legStaff == null || legStaff.toString().isEmpty) && 
                   (oiStaff == null || oiStaff.toString().isEmpty);
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          _showOnlyMyJobs ? 'Công Việc Của Tôi' : 'Approve Bài Đăng (Cần Nhận)',
          style: const TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryBlue),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchPendingApartments,
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: StaffDrawer(
        currentUser: widget.currentUser,
        onLogout: widget.onLogout,
        isMyJobsSelected: _showOnlyMyJobs,
        onAllJobsTapped: () {
          setState(() {
            _showOnlyMyJobs = false;
          });
          Navigator.pop(context); // Close drawer
        },
        onMyJobsTapped: () {
          setState(() {
            _showOnlyMyJobs = true;
          });
          Navigator.pop(context); // Close drawer
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchPendingApartments,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : displayedApartments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.fact_check_outlined, 
                              size: 72, 
                              color: Colors.green[400]
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _showOnlyMyJobs 
                                ? 'Bạn chưa nhận việc duyệt nào' 
                                : 'None bài đăng nào cần nhận',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchPendingApartments,
                      color: primaryBlue,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedApartments.length,
                        itemBuilder: (context, index) {
                          final apt = displayedApartments[index];
                          const sampleImage =
                              'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=500&auto=format&fit=crop&q=60';
                          final String firstImage = apt.imageUrl.split(',').first.trim();
                          final bool hasValidImage = firstImage.isNotEmpty &&
                              firstImage.startsWith('http') &&
                              firstImage != 'https://image1.com';
                          final imageToShow = hasValidImage ? firstImage : sampleImage;
                          
                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ApartmentApprovalDetailScreen(
                                    apartment: apt,
                                    currentUser: widget.currentUser,
                                    isMyJob: _showOnlyMyJobs,
                                  ),
                                ),
                              );
                              _fetchPendingApartments();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
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
                              child: Row(
                                children: [
                                  // Image
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      bottomLeft: Radius.circular(20),
                                    ),
                                    child: Image.network(
                                      imageToShow,
                                      width: 100,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 100,
                                        height: 120,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(Icons.broken_image_rounded, size: 30, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Content
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            apt.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black87,
                                              height: 1.2,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[500]),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  '${apt.ward}, ${apt.commune}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _showOnlyMyJobs 
                                                ? primaryBlue.withOpacity(0.1) 
                                                : accentYellow.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _showOnlyMyJobs 
                                                  ? primaryBlue.withOpacity(0.3) 
                                                  : accentYellow.withOpacity(0.5)
                                              ),
                                            ),
                                            child: Text(
                                              _showOnlyMyJobs ? 'Accepted duyệt' : 'Chưa có người nhận',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: _showOnlyMyJobs ? primaryBlue : const Color(0xFFB8860B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

