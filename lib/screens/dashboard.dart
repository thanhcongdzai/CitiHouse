import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  List<Apartment> apartments = [];
  List<Apartment> filteredApartments = [];
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

  @override
  void initState() {
    super.initState();
    fetchApartments();
  }

  Future<void> fetchApartments() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/apartments/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          apartments = data.map((json) => Apartment.fromJson(json)).toList();
          filteredApartments = List.from(apartments);
          _extractFilterOptions();
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load apartments: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error connecting to server. Make sure the API is running at 127.0.0.1:8000.\nDetails: $e';
        isLoading = false;
      });
    }
  }

  void _extractFilterOptions() {
    _wards.clear();
    _communes.clear();
    _projects.clear();
    _buildings.clear();
    _floors.clear();

    for (var apt in apartments) {
      if (apt.ward.isNotEmpty) _wards.add(apt.ward);
      if (apt.commune.isNotEmpty) _communes.add(apt.commune);
      if (apt.project.isNotEmpty) _projects.add(apt.project);
      if (apt.building.isNotEmpty) _buildings.add(apt.building);
      if (apt.floor > 0) _floors.add(apt.floor);
    }
  }

  void _applyFilters() {
    setState(() {
      filteredApartments = apartments.where((apt) {
        bool match = true;
        if (_minPrice != null && apt.price < _minPrice!) match = false;
        if (_maxPrice != null && apt.price > _maxPrice!) match = false;
        if (_selectedWard != null && apt.ward != _selectedWard) match = false;
        if (_selectedCommune != null && apt.commune != _selectedCommune) match = false;
        if (_selectedProject != null && apt.project != _selectedProject) match = false;
        if (_selectedBuilding != null && apt.building != _selectedBuilding) match = false;
        if (_selectedFloor != null && apt.floor != _selectedFloor) match = false;
        return match;
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                                    border: Border.all(color: primaryBlue.withOpacity(0.4), width: 1.5),
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
                                      prefixStyle: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                                      labelText: 'Min Price',
                                      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    ),
                                    onChanged: (val) {
                                      _minPrice = double.tryParse(val);
                                    },
                                    controller: TextEditingController(text: _minPrice?.toStringAsFixed(0) ?? ''),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('-', style: TextStyle(color: Colors.grey[500], fontSize: 24, fontWeight: FontWeight.w300)),
                              ),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
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
                                  child: TextField(
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      prefixText: '₫ ',
                                      prefixStyle: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                                      labelText: 'Max Price',
                                      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    ),
                                    onChanged: (val) {
                                      _maxPrice = double.tryParse(val);
                                    },
                                    controller: TextEditingController(text: _maxPrice?.toStringAsFixed(0) ?? ''),
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
                            onChanged: (val) => setModalState(() => _selectedWard = val),
                          ),
                        if (_communes.isNotEmpty)
                          _buildDropdownSection(
                            title: 'Commune',
                            icon: Icons.location_city_rounded,
                            value: _selectedCommune,
                            items: _communes.toList()..sort(),
                            onChanged: (val) => setModalState(() => _selectedCommune = val),
                          ),
                        if (_projects.isNotEmpty)
                          _buildDropdownSection(
                            title: 'Project',
                            icon: Icons.business_rounded,
                            value: _selectedProject,
                            items: _projects.toList()..sort(),
                            onChanged: (val) => setModalState(() => _selectedProject = val),
                          ),
                        if (_buildings.isNotEmpty)
                          _buildDropdownSection(
                            title: 'Building',
                            icon: Icons.apartment_rounded,
                            value: _selectedBuilding,
                            items: _buildings.toList()..sort(),
                            onChanged: (val) => setModalState(() => _selectedBuilding = val),
                          ),
                        if (_floors.isNotEmpty)
                          _buildDropdownSection(
                            title: 'Floor',
                            icon: Icons.layers_rounded,
                            value: _selectedFloor?.toString(),
                            items: _floors.map((e) => e.toString()).toList()..sort((a, b) => int.parse(a).compareTo(int.parse(b))),
                            onChanged: (val) => setModalState(() => _selectedFloor = val == null ? null : int.tryParse(val)),
                          ),
                      ],
                    ),
                  ),
                  Container(
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

  Widget _buildFilterSection({required String title, required IconData icon, required Widget child}) {
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
          color: Colors.white,
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
            hint: Text(
              'Select $title', 
              style: TextStyle(color: Colors.grey[500], fontSize: 15)
            ),
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
        backgroundColor: Colors.grey[100],
        body: Center(
          child: CircularProgressIndicator(color: primaryBlue),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 60),
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
                  label: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No properties found',
                style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Discover',
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.filter_list_rounded, color: primaryBlue),
                if (_minPrice != null ||
                    _maxPrice != null ||
                    _selectedWard != null ||
                    _selectedCommune != null ||
                    _selectedProject != null ||
                    _selectedBuilding != null ||
                    _selectedFloor != null)
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
      body: filteredApartments.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_alt_off_rounded, size: 60, color: Colors.grey[400]),
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
                      });
                      _applyFilters();
                    },
                    child: Text('Clear Filters', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
              itemCount: filteredApartments.length,
              itemBuilder: (context, index) {
                final item = filteredApartments[index];
          // Sample image logic based on instructions
          const sampleImage =
              'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=500&auto=format&fit=crop&q=60';
          final bool hasValidImage = item.imageUrl.isNotEmpty &&
              item.imageUrl.startsWith('http') &&
              item.imageUrl != 'https://image1.com';
          final imageToShow = hasValidImage ? item.imageUrl : sampleImage;

          return GestureDetector(
            onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ApartmentDetailScreen(
                      apartment: item,
                      currentUser: widget.currentUser,
                    ),
                  ),
                );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
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
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: Hero(
                          tag: 'apartment_image_${item.id}',
                          child: Image.network(
                            imageToShow,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 220,
                              color: Colors.grey[300],
                              child: const Center(
                                  child: Icon(Icons.broken_image_rounded, size: 50, color: Colors.grey)),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star_rounded, color: accentYellow, size: 16),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: accentYellow.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: accentYellow),
                              ),
                              child: Text(
                                item.houseStatus,
                                style: TextStyle(
                                  color: Colors.orange[800],
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
                            color: primaryBlue,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Property Features
                        Row(
                          children: [
                            _buildFeature(Icons.king_bed_rounded, '2 Beds'),
                            _buildDotSeparator(),
                            _buildFeature(Icons.bathtub_rounded, '2 Baths'),
                            _buildDotSeparator(),
                            _buildFeature(Icons.square_foot_rounded, '80 m²'),
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
                              child: Icon(Icons.location_on_rounded, size: 16, color: primaryBlue),
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
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.w500,
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
        color: Colors.grey[400],
        shape: BoxShape.circle,
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000000000) {
      double billions = price / 1000000000;
      return '${billions.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} Billion VND';
    } else if (price >= 1000000) {
      double millions = price / 1000000;
      return '${millions.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} Million VND';
    }
    return '${price.toString()} VND';
  }
}
