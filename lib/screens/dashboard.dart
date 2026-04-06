import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/apartment.dart';
import 'apartment_detail_screen.dart';

import '../models/user.dart';

class DashboardScreen extends StatefulWidget {
  final User? currentUser;
  const DashboardScreen({super.key, this.currentUser});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Color primaryBlue = const Color.fromRGBO(35, 97, 219, 1);
  final Color accentYellow = const Color.fromRGBO(248, 192, 52, 1);
  final Color bgTop = const Color(0xFFEAF1FF);
  final Color bgBottom = const Color(0xFFF7FBFF);
  final Color surfaceBlue = const Color(0xFFF2F6FF);
  final Color cardBlue = const Color(0xFFEDF3FF);

  List<Apartment> apartments = [];
  List<Apartment> filteredApartments = [];
  List<Map<String, dynamic>> _allProjects = [];
  bool isLoading = true;
  String? error;

  // Filter criteria
  double? _minPrice;
  double? _maxPrice;
  String? _selectedWard;
  String? _selectedCommune;
  String? _selectedProject;
  String? _selectedBuilding;
  int? _selectedFloor;

  // Extracted options
  Set<String> _wards = {};
  Set<String> _communes = {};
  Set<String> _projects = {};
  Set<String> _buildings = {};
  Set<int> _floors = {};

  bool get _hasActiveFilters =>
      _minPrice != null ||
      _maxPrice != null ||
      _selectedWard != null ||
      _selectedCommune != null ||
      _selectedProject != null ||
      _selectedBuilding != null ||
      _selectedFloor != null;

  @override
  void initState() {
    super.initState();
    fetchApartments();
  }

  bool _isAvailableApartment(Apartment apt) {
    return apt.houseStatus.trim().toLowerCase() == 'available';
  }

  String _readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }

  int? _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  String _normalizeText(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  bool _textEquals(String? a, String? b) {
    return _normalizeText(a) == _normalizeText(b);
  }

  String _projectWard(Map<String, dynamic> p) {
    return _projectLocationPair(p).$1;
  }

  String _projectCommune(Map<String, dynamic> p) {
    return _projectLocationPair(p).$2;
  }

  bool _looksLikeWardLevel(String value) {
    final text = _normalizeText(value);
    return text.contains('phường') ||
        text.contains('xa ') ||
        text.startsWith('xã') ||
        text.contains('thị trấn') ||
        text.contains('thi tran');
  }

  bool _looksLikeCommuneLevel(String value) {
    final text = _normalizeText(value);
    return text.contains('thành phố') ||
        text.contains('quan ') ||
        text.startsWith('quận') ||
        text.contains('huyen') ||
        text.startsWith('huyện') ||
        text.contains('thị xã');
  }

  (String, String) _projectLocationPair(Map<String, dynamic> p) {
    final rawWard = _readString(p, const ['ward', 'district']);
    final rawCommune = _readString(p, const ['commune', 'commute']);

    // Handle legacy/incorrect project payload where ward & commune are swapped.
    final isSwapped = _looksLikeCommuneLevel(rawWard) &&
        _looksLikeWardLevel(rawCommune);
    if (isSwapped) {
      return (rawCommune, rawWard);
    }
    return (rawWard, rawCommune);
  }

  String _projectName(Map<String, dynamic> p) {
    return _readString(p, const ['project']);
  }

  String _projectBuilding(Map<String, dynamic> p) {
    return _readString(p, const ['building']);
  }

  int? _projectFloor(Map<String, dynamic> p) {
    return _readInt(p, const ['floor']);
  }

  Future<void> fetchApartments() async {
    try {
      final responses = await Future.wait([
        http.get(ApiConfig.uri('/api/apartments/')),
        http.get(ApiConfig.uri('/api/projects/')),
      ]);
      final apartmentResponse = responses[0];
      final projectResponse = responses[1];

      if (apartmentResponse.statusCode == 200) {
        final List<dynamic> data =
            json.decode(utf8.decode(apartmentResponse.bodyBytes));
        final List<dynamic> projectData = projectResponse.statusCode == 200
            ? json.decode(utf8.decode(projectResponse.bodyBytes))
            : const [];

        setState(() {
          final allApts = data.map((json) => Apartment.fromJson(json)).toList();
          apartments = allApts.where((apt) {
            final v = apt.verifications;
            if (v == null) return false;
            final imgStatus = v['image']?['status'];
            final legStatus = v['legal']?['status'];
            final oiStatus = v['ownerIntent']?['status'];
            return imgStatus == 'Approved' &&
                legStatus == 'Approved' &&
                oiStatus == 'Approved' &&
                _isAvailableApartment(apt);
          }).toList();

          _allProjects = projectData
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          _refreshProjectOptions();
          filteredApartments = List.from(apartments);
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load apartments: ${apartmentResponse.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error =
            'Error connecting to server. Make sure the API is running at 127.0.0.1:8000.\nDetails: $e';
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _projectsBySelected({
    bool includeWard = true,
    bool includeCommune = true,
    bool includeProject = true,
    bool includeBuilding = true,
  }) {
    return _allProjects.where((p) {
      if (includeWard &&
          _selectedWard != null &&
          _projectWard(p) != _selectedWard) {
        return false;
      }
      if (includeCommune &&
          _selectedCommune != null &&
          _projectCommune(p) != _selectedCommune) {
        return false;
      }
      if (includeProject &&
          _selectedProject != null &&
          _projectName(p) != _selectedProject) {
        return false;
      }
      if (includeBuilding &&
          _selectedBuilding != null &&
          _projectBuilding(p) != _selectedBuilding) {
        return false;
      }
      return true;
    }).toList();
  }

  void _refreshProjectOptions() {
    _wards.clear();
    _communes.clear();
    _projects.clear();
    _buildings.clear();
    _floors.clear();

    final source = _allProjects;

    for (final p in source) {
      final ward = _projectWard(p);
      if (ward.isNotEmpty) _wards.add(ward);
    }
    for (final p in _projectsBySelected(
      includeWard: true,
      includeCommune: false,
      includeProject: false,
      includeBuilding: false,
    )) {
      final commune = _projectCommune(p);
      if (commune.isNotEmpty) _communes.add(commune);
    }
    for (final p in _projectsBySelected(
      includeWard: true,
      includeCommune: true,
      includeProject: false,
      includeBuilding: false,
    )) {
      final project = _projectName(p);
      if (project.isNotEmpty) _projects.add(project);
    }
    for (final p in _projectsBySelected(
      includeWard: true,
      includeCommune: true,
      includeProject: true,
      includeBuilding: false,
    )) {
      final building = _projectBuilding(p);
      if (building.isNotEmpty) _buildings.add(building);
    }
    for (final p in _projectsBySelected(
      includeWard: true,
      includeCommune: true,
      includeProject: true,
      includeBuilding: true,
    )) {
      final floor = _projectFloor(p);
      if (floor != null && floor > 0) _floors.add(floor);
    }

    if (_selectedWard != null && !_wards.contains(_selectedWard)) {
      _selectedWard = null;
    }
    if (_selectedCommune != null && !_communes.contains(_selectedCommune)) {
      _selectedCommune = null;
    }
    if (_selectedProject != null && !_projects.contains(_selectedProject)) {
      _selectedProject = null;
    }
    if (_selectedBuilding != null && !_buildings.contains(_selectedBuilding)) {
      _selectedBuilding = null;
    }
    if (_selectedFloor != null && !_floors.contains(_selectedFloor)) {
      _selectedFloor = null;
    }
  }

  void _applyFilters() {
    setState(() {
      filteredApartments = apartments.where((apt) {
        if (!_isAvailableApartment(apt)) return false;

        // Price filters are optional.
        if (_minPrice != null && apt.price < _minPrice!) return false;
        if (_maxPrice != null && apt.price > _maxPrice!) return false;

        // Location/project filters are AND-based:
        // apartment must match every selected field.
        if (_selectedWard != null && !_textEquals(apt.ward, _selectedWard)) {
          return false;
        }
        if (_selectedCommune != null &&
            !_textEquals(apt.commune, _selectedCommune)) {
          return false;
        }
        if (_selectedProject != null &&
            !_textEquals(apt.project, _selectedProject)) {
          return false;
        }
        if (_selectedBuilding != null &&
            !_textEquals(apt.building, _selectedBuilding)) {
          return false;
        }
        if (_selectedFloor != null && apt.floor != _selectedFloor) return false;

        return true;
      }).toList();
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: surfaceBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _minPrice = null;
                              _maxPrice = null;
                              _selectedWard = null;
                              _selectedCommune = null;
                              _selectedProject = null;
                              _selectedBuilding = null;
                              _selectedFloor = null;
                              _refreshProjectOptions();
                            });
                            _applyFilters();
                          },
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Filter Content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildFilterSection(
                          title: 'Price Range',
                          icon: Icons.attach_money_rounded,
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: primaryBlue.withOpacity(0.4),
                                        width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryBlue.withOpacity(0.08),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixText: '₫ ',
                                      prefixStyle: TextStyle(
                                          color: primaryBlue,
                                          fontWeight: FontWeight.bold),
                                      labelText: 'Min Price',
                                      labelStyle: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: cardBlue,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
                                    ),
                                    onChanged: (val) {
                                      _minPrice = double.tryParse(val);
                                    },
                                    controller: TextEditingController(
                                        text: _minPrice?.toStringAsFixed(0) ?? ''),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('-',
                                    style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 24,
                                        fontWeight: FontWeight.w300)),
                              ),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: primaryBlue.withOpacity(0.4),
                                        width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryBlue.withOpacity(0.08),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixText: '₫ ',
                                      prefixStyle: TextStyle(
                                          color: primaryBlue,
                                          fontWeight: FontWeight.bold),
                                      labelText: 'Max Price',
                                      labelStyle: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: cardBlue,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 16),
                                    ),
                                    onChanged: (val) {
                                      _maxPrice = double.tryParse(val);
                                    },
                                    controller: TextEditingController(
                                        text: _maxPrice?.toStringAsFixed(0) ??
                                            ''),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_wards.isNotEmpty)
                          _buildDropdownSection(
                            title: 'Ward',
                            icon: Icons.map_rounded,
                            value: _selectedWard,
                            items: _wards.toList()..sort(),
                            onChanged: (val) => setModalState(() {
                              _selectedWard = val;
                              _selectedCommune = null;
                              _selectedProject = null;
                              _selectedBuilding = null;
                              _selectedFloor = null;
                              _refreshProjectOptions();
                            }),
                          ),
                        if (_communes.isNotEmpty)
                          _buildDropdownSection(
                            title: 'Commune',
                            icon: Icons.location_city_rounded,
                            value: _selectedCommune,
                            items: _communes.toList()..sort(),
                            onChanged: (val) => setModalState(() {
                              _selectedCommune = val;
                              _selectedProject = null;
                              _selectedBuilding = null;
                              _selectedFloor = null;
                              _refreshProjectOptions();
                            }),
                          ),
                        if (_projects.isNotEmpty)
                          _buildDropdownSection(
                            title: 'Project',
                            icon: Icons.business_rounded,
                            value: _selectedProject,
                            items: _projects.toList()..sort(),
                            onChanged: (val) => setModalState(() {
                              _selectedProject = val;
                              _selectedBuilding = null;
                              _selectedFloor = null;
                              _refreshProjectOptions();
                            }),
                          ),
                        if (_buildings.isNotEmpty)
                          _buildDropdownSection(
                            title: 'Building',
                            icon: Icons.apartment_rounded,
                            value: _selectedBuilding,
                            items: _buildings.toList()..sort(),
                            onChanged: (val) => setModalState(() {
                              _selectedBuilding = val;
                              _selectedFloor = null;
                              _refreshProjectOptions();
                            }),
                          ),
                        if (_floors.isNotEmpty)
                          _buildDropdownSection(
                            title: 'Floor',
                            icon: Icons.layers_rounded,
                            value: _selectedFloor?.toString(),
                            items: _floors.map((e) => e.toString()).toList()
                              ..sort((a, b) =>
                                  int.parse(a).compareTo(int.parse(b))),
                            onChanged: (val) => setModalState(() {
                              _selectedFloor =
                                  val == null ? null : int.tryParse(val);
                              _refreshProjectOptions();
                            }),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: surfaceBlue,
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -5),
                        )
                      ],
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: primaryBlue.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Show Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection(
      {required String title, required IconData icon, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentYellow.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: Colors.orange[800]),
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
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdownSection({
    required String title,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return _buildFilterSection(
      title: title,
      icon: icon,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: BoxDecoration(
          color: cardBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryBlue.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryBlue),
            hint: Text('Select $title',
                style: TextStyle(color: Colors.grey[500], fontSize: 15)),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Any'),
              ),
              ...items.map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  )),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: bgBottom,
        body: Center(
          child: CircularProgressIndicator(color: primaryBlue),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: bgBottom,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded,
                    color: Colors.red[400], size: 60),
                const SizedBox(height: 16),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red[800], fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      error = null;
                    });
                    fetchApartments();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    if (apartments.isEmpty) {
      return Scaffold(
        backgroundColor: bgBottom,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No properties found',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgBottom,
      appBar: AppBar(
        title: Text(
          'Discover',
          style: TextStyle(
            color: Colors.amber[800],
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: bgTop,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.filter_list_rounded, color: primaryBlue),
                if (_hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: accentYellow,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterModal,
          ),
          IconButton(
            icon: Icon(Icons.notifications_none_rounded, color: primaryBlue),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: filteredApartments.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_alt_off_rounded,
                        size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No properties match your filters',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _minPrice = null;
                          _maxPrice = null;
                          _selectedWard = null;
                          _selectedCommune = null;
                          _selectedProject = null;
                          _selectedBuilding = null;
                          _selectedFloor = null;
                          _refreshProjectOptions();
                        });
                        _applyFilters();
                      },
                      child: Text('Clear Filters',
                          style: TextStyle(
                              color: primaryBlue, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
                itemCount: filteredApartments.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildOverviewPanel();
                  }
                  final item = filteredApartments[index - 1];
                  // Sample image logic based on instructions
                  const sampleImage =
                      'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=500&auto=format&fit=crop&q=60';
                  final String firstImage = item.imageUrl.split(',').first.trim();
                  final bool hasValidImage = firstImage.isNotEmpty &&
                      firstImage.startsWith('http') &&
                      firstImage != 'https://image1.com';
                  final imageToShow =
                      hasValidImage ? firstImage : sampleImage;

                  return GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ApartmentDetailScreen(
                            apartment: item,
                            currentUser: widget.currentUser,
                          ),
                        ),
                      );
                      // Based on user request, always refresh when navigating back from details
                      fetchApartments();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, cardBlue],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border:
                            Border.all(color: primaryBlue.withOpacity(0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Section
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(24)),
                                child: Hero(
                                  tag: 'apartment_image_${item.id}',
                                  child: Image.network(
                                    imageToShow,
                                    height: 220,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      height: 220,
                                      color: Colors.grey[300],
                                      child: const Center(
                                          child: Icon(
                                              Icons.broken_image_rounded,
                                              size: 50,
                                              color: Colors.grey)),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.9)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.star_rounded,
                                          color: accentYellow, size: 16),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Featured',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.9)),
                                  ),
                                  child: Icon(
                                    Icons.favorite_border_rounded,
                                    color: Colors.grey[400],
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Content Section
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black87,
                                              height: 1.2,
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: accentYellow.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: accentYellow),
                                      ),
                                      child: Text(
                                        item.houseStatus,
                                        style: TextStyle(
                                          color: Colors.amber[900],
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _formatPrice(item.price),
                                  style: TextStyle(
                                    color: Colors.amber[800],
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Property Features
                                Row(
                                  children: [
                                    _buildFeature(
                                        Icons.king_bed_rounded, '2 Beds'),
                                    _buildDotSeparator(),
                                    _buildFeature(
                                        Icons.bathtub_rounded, '2 Baths'),
                                    _buildDotSeparator(),
                                    _buildFeature(
                                        Icons.square_foot_rounded, '80 m2'),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 16),

                                // Location
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: primaryBlue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.location_on_rounded,
                                          size: 16, color: primaryBlue),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${item.ward}, ${item.commune}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }

  Widget _buildOverviewPanel() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue.withOpacity(0.95),
            const Color(0xFF3F7DFF),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${filteredApartments.length} listings available',
                  style: TextStyle(
                    color: Colors.amber[100],
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _hasActiveFilters
                      ? 'Filtered results are shown'
                      : 'Curated homes with verified information',
                  style: TextStyle(
                    color: Colors.amber.shade50.withOpacity(0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _showFilterModal,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Filters',
                      style: TextStyle(
                        color: const Color.fromRGBO(248, 192, 52, 1),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryBlue.withOpacity(0.65)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF4B5A7A),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDotSeparator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.35),
        shape: BoxShape.circle,
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000000000) {
      double billions = price / 1000000000;
      return '${billions.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} tỷ VNĐ';
    } else if (price >= 1000000) {
      double millions = price / 1000000;
      return '${millions.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} triệu VNĐ';
    }
    return '${price.toString()} VNĐ';
  }
}


