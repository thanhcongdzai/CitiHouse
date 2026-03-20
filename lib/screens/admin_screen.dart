import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/user.dart';
import 'staff_drawer.dart';

class AdminScreen extends StatefulWidget {
  final User currentUser;
  final VoidCallback onLogout;

  const AdminScreen({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  static const primaryBlue = Color.fromRGBO(35, 97, 219, 1);
  static const accentYellow = Color.fromRGBO(248, 192, 52, 1);
  static const bgColor = Color(0xFFF4F6FA);

  int _selectedTab = 0; // 0 = Tỷ lệ xem nhà hoàn thành, 1 = Tỷ lệ yêu cầu cọc

  // Filter state
  int? _selectedMonth;
  int? _selectedYear;

  // Data state
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _allAppointments = [];

  // Stats
  int _countYeuCauXem = 0;
  int _countDangLienHe = 0;
  int _countDaXacNhanLich = 0;
  int _countDangXem = 0;
  int _countHoanThanh = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        ApiConfig.uri('/api/viewing-appointments/'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> raw = json.decode(utf8.decode(response.bodyBytes));
        _allAppointments = raw.cast<Map<String, dynamic>>();
        _calculateStats();
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Lỗi tải dữ liệu: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Không thể kết nối máy chủ: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _calculateStats() {
    int yeuCauXem = 0;
    int dangLienHe = 0;
    int daXacNhanLich = 0;
    int dangXem = 0;
    int hoanThanh = 0;

    for (var appt in _allAppointments) {
      // Get the creation time or appointment time to filter by month/year.
      // We will look at `createdAt` if available, otherwise `appointmentTime`
      final timeStr = appt['createdAt']?.toString() ?? appt['appointmentTime']?.toString();
      if (timeStr != null && timeStr.isNotEmpty) {
        try {
          final dt = DateTime.parse(timeStr).toLocal();
          if (_selectedYear != null && dt.year != _selectedYear) continue;
          if (_selectedMonth != null && _selectedMonth != 0 && dt.month != _selectedMonth) continue;
        } catch (_) {}
      } else {
        // If no time is associated and we have a filter, maybe skip or include? We'll include if we are filtering "All" month/year.
        if (_selectedYear != null || (_selectedMonth != null && _selectedMonth != 0)) {
           continue; 
        }
      }

      final status = appt['status']?.toString();
      if (status == 'Yeu cau xem') yeuCauXem++;
      else if (status == 'Dang lien he') dangLienHe++;
      else if (status == 'Da xac nhan' || status == 'Da xac nhan lich') daXacNhanLich++;
      else if (status == 'Dang xem') dangXem++;
      else if (status == 'Hoan thanh') hoanThanh++;
    }

    _countYeuCauXem = yeuCauXem;
    _countDangLienHe = dangLienHe;
    _countDaXacNhanLich = daXacNhanLich;
    _countDangXem = dangXem;
    _countHoanThanh = hoanThanh;
  }

  void _onFilterChanged() {
    setState(() {
      _calculateStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryBlue),
        title: Text(
          _selectedTab == 0 ? 'Tỷ Lệ Xem Nhà' : 'Tỷ Lệ Yêu Cầu Cọc',
          style: const TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: primaryBlue),
            onPressed: _fetchAppointments,
            tooltip: 'Làm mới',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: StaffDrawer(
        currentUser: widget.currentUser,
        onLogout: widget.onLogout,
        isAdminViewingStatsSelected: _selectedTab == 0,
        isAdminDepositStatsSelected: _selectedTab == 1,
        onAdminViewingStatsTapped: () {
          setState(() { _selectedTab = 0; });
          Navigator.pop(context);
        },
        onAdminDepositStatsTapped: () {
          setState(() { _selectedTab = 1; });
          Navigator.pop(context);
        },
      ),
      body: _selectedTab == 0 ? _buildViewingStatsTab() : _buildDepositStatsTab(),
    );
  }

  Widget _buildViewingStatsTab() {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: primaryBlue))
              : _error != null
                  ? Center(
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchAppointments,
                      color: primaryBlue,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatCards(),
                            const SizedBox(height: 24),
                            _buildChartSection(),
                          ],
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final currentYear = DateTime.now().year;
    final years = List.generate(5, (index) => currentYear - index);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded, color: primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                // Month Dropdown
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedMonth,
                        isExpanded: true,
                        hint: const Text('Tất cả tháng', style: TextStyle(fontSize: 14)),
                        items: [
                          const DropdownMenuItem(value: 0, child: Text('Tất cả tháng', style: TextStyle(fontSize: 14))),
                          ...List.generate(12, (index) {
                            return DropdownMenuItem(
                              value: index + 1,
                              child: Text('Tháng ${index + 1}', style: const TextStyle(fontSize: 14)),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            _selectedMonth = val;
                            _onFilterChanged();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Year Dropdown
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        isExpanded: true,
                        hint: const Text('Năm', style: TextStyle(fontSize: 14)),
                        items: [
                          const DropdownMenuItem(value: 0, child: Text('Tất cả năm', style: TextStyle(fontSize: 14))),
                          ...years.map((y) {
                            return DropdownMenuItem(
                              value: y,
                              child: Text('Năm $y', style: const TextStyle(fontSize: 14)),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            _selectedYear = val == 0 ? null : val;
                            _onFilterChanged();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildStatCard('Yêu cầu xem', _countYeuCauXem, Colors.orange),
        _buildStatCard('Đang liên hệ', _countDangLienHe, Colors.amber),
        _buildStatCard('Đã xác nhận', _countDaXacNhanLich, Colors.blue),
        _buildStatCard('Đang xem', _countDangXem, Colors.purple),
        _buildStatCard('Hoàn thành', _countHoanThanh, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, MaterialColor color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 44) / 2, // 2 cards per row
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    final total = _countYeuCauXem + _countDangLienHe + _countDaXacNhanLich + _countDangXem + _countHoanThanh;
    if (total == 0) {
      return Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Không có dữ liệu trong khoảng thời gian này',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Biểu Đồ Trạng Thái',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: [
                  if (_countYeuCauXem > 0)
                    PieChartSectionData(
                      color: Colors.orange,
                      value: _countYeuCauXem.toDouble(),
                      title: '${((_countYeuCauXem / total) * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (_countDangLienHe > 0)
                    PieChartSectionData(
                      color: Colors.amber,
                      value: _countDangLienHe.toDouble(),
                      title: '${((_countDangLienHe / total) * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (_countDaXacNhanLich > 0)
                    PieChartSectionData(
                      color: Colors.blue,
                      value: _countDaXacNhanLich.toDouble(),
                      title: '${((_countDaXacNhanLich / total) * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (_countDangXem > 0)
                    PieChartSectionData(
                      color: Colors.purple,
                      value: _countDangXem.toDouble(),
                      title: '${((_countDangXem / total) * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  if (_countHoanThanh > 0)
                    PieChartSectionData(
                      color: Colors.green,
                      value: _countHoanThanh.toDouble(),
                      title: '${((_countHoanThanh / total) * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(Colors.orange, 'Yêu cầu xem'),
            _buildLegendItem(Colors.amber, 'Đang liên hệ'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(Colors.blue, 'Đã xác nhận'),
            _buildLegendItem(Colors.purple, 'Đang xem'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Colors.green, 'Hoàn thành'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  Widget _buildDepositStatsTab() {
    return const Center(
      child: Text(
        'Đang phát triển tính năng thống kê\nTỷ Lệ Yêu Cầu Cọc \ntrong tương lai.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}
