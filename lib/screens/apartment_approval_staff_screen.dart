import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/apartment.dart';
import '../models/user.dart';
import 'apartment_approval_detail_screen.dart';
import 'staff_drawer.dart';

class ApprovalStepConfig {
  final String stepKey;
  final String screenTitle;
  final String emptyAvailableMessage;
  final String emptyMyJobsMessage;
  final String approvalLabel;

  const ApprovalStepConfig({
    required this.stepKey,
    required this.screenTitle,
    required this.emptyAvailableMessage,
    required this.emptyMyJobsMessage,
    required this.approvalLabel,
  });
}

const imageApprovalConfig = ApprovalStepConfig(
  stepKey: 'image',
  screenTitle: 'Duyet Hinh Anh',
  emptyAvailableMessage: 'Khong co bai dang nao cho duyet hinh anh',
  emptyMyJobsMessage: 'Ban chua nhan viec duyet hinh anh nao',
  approvalLabel: 'duyet hinh anh',
);

const legalApprovalConfig = ApprovalStepConfig(
  stepKey: 'legal',
  screenTitle: 'Duyet Phap Ly',
  emptyAvailableMessage: 'Khong co bai dang nao cho duyet phap ly',
  emptyMyJobsMessage: 'Ban chua nhan viec duyet phap ly nao',
  approvalLabel: 'duyet phap ly',
);

const ownerApprovalConfig = ApprovalStepConfig(
  stepKey: 'ownerIntent',
  screenTitle: 'Xac Nhan Chu Nha',
  emptyAvailableMessage: 'Khong co bai dang nao cho xac nhan chu nha',
  emptyMyJobsMessage: 'Ban chua nhan viec xac nhan chu nha nao',
  approvalLabel: 'xac nhan chu nha',
);

class ApprovalTaskStaffScreen extends StatefulWidget {
  final User currentUser;
  final VoidCallback onLogout;
  final ApprovalStepConfig? stepConfig;

  const ApprovalTaskStaffScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
    this.stepConfig,
  });

  @override
  State<ApprovalTaskStaffScreen> createState() =>
      _ApprovalTaskStaffScreenState();
}

class _ApprovalTaskStaffScreenState extends State<ApprovalTaskStaffScreen> {
  static const primaryBlue = Color.fromRGBO(35, 97, 219, 1);
  static const accentYellow = Color.fromRGBO(248, 192, 52, 1);

  List<Apartment> _apartments = [];
  bool _isLoading = true;
  String? _error;
  bool _showOnlyMyJobs = false;
  bool _showCompletedJobs = false;

  ApprovalStepConfig? get _stepConfig => widget.stepConfig;
  bool get _isScoped => _stepConfig != null;
  String get _stepKey => _stepConfig!.stepKey;

  @override
  void initState() {
    super.initState();
    _fetchPendingApartments();
  }

  Future<void> _fetchPendingApartments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(ApiConfig.uri('/api/apartments/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          final allApts = data.map((json) => Apartment.fromJson(json)).toList();
          _apartments = allApts.where(_matchesPendingScope).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  bool _matchesPendingScope(Apartment apt) {
    final v = apt.verifications;
    if (v == null) return false;
    if (!_isScoped) return true;
    return v[_stepKey] != null;
  }

  List<Apartment> _buildDisplayedApartments() {
    if (_showCompletedJobs) {
      return _apartments.where(_isCompletedByCurrentUser).toList();
    }
    if (_showOnlyMyJobs) {
      return _apartments.where(_isInProgressForCurrentUser).toList();
    }
    return _apartments.where(_isAvailableForCurrentUser).toList();
  }

  bool _isAssignedToCurrentUser(Apartment apt) {
    final v = apt.verifications;
    if (v == null) return false;
    if (_isScoped) {
      final staffId = v[_stepKey]?['staffId']?.toString();
      return staffId == widget.currentUser.id;
    }

    final imgStaff = v['image']?['staffId']?.toString();
    final legStaff = v['legal']?['staffId']?.toString();
    final oiStaff = v['ownerIntent']?['staffId']?.toString();
    return imgStaff == widget.currentUser.id ||
        legStaff == widget.currentUser.id ||
        oiStaff == widget.currentUser.id;
  }

  bool _isAvailableForCurrentUser(Apartment apt) {
    final v = apt.verifications;
    if (v == null || apt.houseStatus != 'Pending') return false;
    if (_isScoped) {
      final staffId = v[_stepKey]?['staffId'];
      return staffId == null || staffId.toString().isEmpty;
    }

    final imgStaff = v['image']?['staffId'];
    final legStaff = v['legal']?['staffId'];
    final oiStaff = v['ownerIntent']?['staffId'];
    return (imgStaff == null || imgStaff.toString().isEmpty) &&
        (legStaff == null || legStaff.toString().isEmpty) &&
        (oiStaff == null || oiStaff.toString().isEmpty);
  }

  bool _isCompletedByCurrentUser(Apartment apt) {
    final v = apt.verifications;
    if (v == null) return false;
    if (_isScoped) {
      final stepMap = v[_stepKey] as Map<String, dynamic>? ?? {};
      final staffId = stepMap['staffId']?.toString();
      final status = stepMap['status']?.toString();
      final imgStatus = v['image']?['status']?.toString();
      final legalStatus = v['legal']?['status']?.toString();
      final ownerStatus = v['ownerIntent']?['status']?.toString();
      final approvedAll = imgStatus == 'Approved' &&
          legalStatus == 'Approved' &&
          ownerStatus == 'Approved';

      if (staffId != widget.currentUser.id) return false;
      if (status == 'Rejected') return true;
      if (status != 'Approved') return false;

      if (approvedAll) {
        return apt.houseStatus == 'Available' &&
            apt.finalApprove == widget.currentUser.id;
      }

      return true;
    }

    bool isCompletedStep(String key) {
      final stepMap = v[key] as Map<String, dynamic>? ?? {};
      final staffId = stepMap['staffId']?.toString();
      final status = stepMap['status']?.toString();
      return staffId == widget.currentUser.id &&
          (status == 'Approved' || status == 'Rejected');
    }

    return isCompletedStep('image') ||
        isCompletedStep('legal') ||
        isCompletedStep('ownerIntent');
  }

  bool _isInProgressForCurrentUser(Apartment apt) {
    final v = apt.verifications;
    if (v == null || apt.houseStatus != 'Pending') return false;
    if (_isScoped) {
      final stepMap = v[_stepKey] as Map<String, dynamic>? ?? {};
      final staffId = stepMap['staffId']?.toString();
      final status = stepMap['status']?.toString();
      final imgStatus = v['image']?['status']?.toString();
      final legalStatus = v['legal']?['status']?.toString();
      final ownerStatus = v['ownerIntent']?['status']?.toString();
      final approvedAll = imgStatus == 'Approved' &&
          legalStatus == 'Approved' &&
          ownerStatus == 'Approved';

      if (staffId != widget.currentUser.id) return false;
      if (status == 'Pending') return true;
      return status == 'Approved' && approvedAll;
    }

    bool isPendingStep(String key) {
      final stepMap = v[key] as Map<String, dynamic>? ?? {};
      final staffId = stepMap['staffId']?.toString();
      final status = stepMap['status']?.toString();
      return staffId == widget.currentUser.id && status == 'Pending';
    }

    return isPendingStep('image') ||
        isPendingStep('legal') ||
        isPendingStep('ownerIntent');
  }

  String _resolveAppBarTitle() {
    if (_showCompletedJobs) return 'Finished Jobs';
    if (_showOnlyMyJobs) return 'Công việc của tôi';
    return _isScoped ? _stepConfig!.screenTitle : 'Approve Bai Dang (Can Nhan)';
  }

  String _resolveEmptyMessage() {
    if (_showCompletedJobs) {
      return _isScoped
          ? 'Ban chua hoan thanh cong viec nao'
          : 'Ban chua duyet xong cong viec nao';
    }
    if (_showOnlyMyJobs) {
      return _isScoped
          ? _stepConfig!.emptyMyJobsMessage
          : 'Ban chua nhan viec duyet nao';
    }
    return _isScoped
        ? _stepConfig!.emptyAvailableMessage
        : 'Khong co bai dang nao can nhan';
  }

  String _resolveStatusLabel() {
    if (_showCompletedJobs) return 'Da hoan thanh';
    if (_showOnlyMyJobs) {
      return 'Accepted ${_stepConfig?.approvalLabel ?? 'duyet'}';
    }
    return 'Chua co nguoi nhan';
  }

  @override
  Widget build(BuildContext context) {
    final displayedApartments = _buildDisplayedApartments();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          _resolveAppBarTitle(),
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
        isCompletedJobsSelected: _showCompletedJobs,
        onAllJobsTapped: () {
          setState(() {
            _showOnlyMyJobs = false;
            _showCompletedJobs = false;
          });
          Navigator.pop(context);
        },
        onMyJobsTapped: () {
          setState(() {
            _showOnlyMyJobs = true;
            _showCompletedJobs = false;
          });
          Navigator.pop(context);
        },
        onCompletedJobsTapped: () {
          setState(() {
            _showOnlyMyJobs = false;
            _showCompletedJobs = true;
          });
          Navigator.pop(context);
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15)),
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
                              color: Colors.green[400],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _resolveEmptyMessage(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
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
                          final String firstImage =
                              apt.imageUrl.split(',').first.trim();
                          final bool hasValidImage = firstImage.isNotEmpty &&
                              firstImage.startsWith('http') &&
                              firstImage != 'https://image1.com';
                          final imageToShow =
                              hasValidImage ? firstImage : sampleImage;

                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ApartmentApprovalDetailScreen(
                                    apartment: apt,
                                    currentUser: widget.currentUser,
                                    isMyJob:
                                        _showOnlyMyJobs || _showCompletedJobs,
                                    focusStepKey: _stepConfig?.stepKey,
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
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        width: 100,
                                        height: 120,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(
                                              Icons.broken_image_rounded,
                                              size: 30,
                                              color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 12, 16, 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                              Icon(Icons.location_on_rounded,
                                                  size: 14,
                                                  color: Colors.grey[500]),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  '${apt.ward}, ${apt.commune}',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _showOnlyMyJobs
                                                  ? primaryBlue.withOpacity(0.1)
                                                  : accentYellow
                                                      .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _showOnlyMyJobs
                                                    ? primaryBlue
                                                        .withOpacity(0.3)
                                                    : accentYellow
                                                        .withOpacity(0.5),
                                              ),
                                            ),
                                            child: Text(
                                              _resolveStatusLabel(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: _showOnlyMyJobs
                                                    ? primaryBlue
                                                    : const Color(0xFFB8860B),
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

class ApartmentApprovalStaffScreen extends StatelessWidget {
  final User currentUser;
  final VoidCallback onLogout;

  const ApartmentApprovalStaffScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ApprovalTaskStaffScreen(
      currentUser: currentUser,
      onLogout: onLogout,
    );
  }
}
