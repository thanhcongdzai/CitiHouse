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

  int _selectedTab = 0; // 0 = Viewing Completion Rate, 1 = Deposit Request Rate

  // Filter state
  int? _selectedMonth;
  int? _selectedYear;

  // Data state
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _allAppointments = [];
  List<Map<String, dynamic>> _allDepositOrders = [];

  // Stats
  int _countYeuCauXem = 0;
  int _countDangLienHe = 0;
  int _countDaXacNhanLich = 0;
  int _countDangXem = 0;
  int _countHoanThanh = 0;
  int _countDaYeuCauCoc = 0;
  int _countDaThanhToan = 0;
  int _countChoThanhToan = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _fetchStatsData();
  }

  Future<void> _fetchStatsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final responses = await Future.wait([
        http.get(ApiConfig.uri('/api/viewing-appointments/')),
        http.get(ApiConfig.uri('/api/deposit-orders/')),
      ]);

      final viewingRes = responses[0];
      final depositRes = responses[1];

      if (viewingRes.statusCode == 200 && depositRes.statusCode == 200) {
        final List<dynamic> rawViewing =
            json.decode(utf8.decode(viewingRes.bodyBytes));
        final List<dynamic> rawDeposits =
            json.decode(utf8.decode(depositRes.bodyBytes));

        _allAppointments =
            rawViewing.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _allDepositOrders = rawDeposits
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        _calculateStats();
        _calculateDepositStats();
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        final codes = <String>[
          'viewing-appointments: ${viewingRes.statusCode}',
          'deposit-orders: ${depositRes.statusCode}',
        ].join(' | ');
        if (mounted) {
          setState(() {
            _error = 'Loi tai du lieu: $codes';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Khong the ket noi may chu: $e';
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
      final timeStr =
          appt['createdAt']?.toString() ?? appt['appointmentTime']?.toString();
      if (timeStr != null && timeStr.isNotEmpty) {
        try {
          final dt = DateTime.parse(timeStr).toLocal();
          if (_selectedYear != null && dt.year != _selectedYear) continue;
          if (_selectedMonth != null &&
              _selectedMonth != 0 &&
              dt.month != _selectedMonth) continue;
        } catch (_) {}
      } else {
        // If no time is associated and we have a filter, maybe skip or include? We'll include if we are filtering "All" month/year.
        if (_selectedYear != null ||
            (_selectedMonth != null && _selectedMonth != 0)) {
          continue;
        }
      }

      final status = appt['status']?.toString();
      if (status == 'Yeu cau xem')
        yeuCauXem++;
      else if (status == 'Dang lien he')
        dangLienHe++;
      else if (status == 'Da xac nhan' || status == 'Da xac nhan lich')
        daXacNhanLich++;
      else if (status == 'Dang xem')
        dangXem++;
      else if (status == 'Hoan thanh') hoanThanh++;
    }

    _countYeuCauXem = yeuCauXem;
    _countDangLienHe = dangLienHe;
    _countDaXacNhanLich = daXacNhanLich;
    _countDangXem = dangXem;
    _countHoanThanh = hoanThanh;
  }

  bool _isInSelectedPeriod(Map<String, dynamic> item, List<String> timeKeys) {
    String? timeStr;
    for (final key in timeKeys) {
      final value = item[key]?.toString();
      if (value != null && value.isNotEmpty) {
        timeStr = value;
        break;
      }
    }

    if (timeStr != null && timeStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(timeStr).toLocal();
        if (_selectedYear != null && dt.year != _selectedYear) return false;
        if (_selectedMonth != null &&
            _selectedMonth != 0 &&
            dt.month != _selectedMonth) {
          return false;
        }
        return true;
      } catch (_) {
        return true;
      }
    }

    if (_selectedYear != null ||
        (_selectedMonth != null && _selectedMonth != 0)) {
      return false;
    }
    return true;
  }

  void _calculateDepositStats() {
    int daYeuCauCoc = 0;
    int daThanhToan = 0;
    int choThanhToan = 0;

    for (var appt in _allAppointments) {
      if (!_isInSelectedPeriod(appt, const ['createdAt', 'appointmentTime'])) {
        continue;
      }
      final status = appt['status']?.toString();
      if (status == 'Da yeu cau coc') {
        daYeuCauCoc++;
      }
    }

    for (var deposit in _allDepositOrders) {
      if (!_isInSelectedPeriod(
          deposit, const ['createdAt', 'updatedAt', 'expiredAt'])) {
        continue;
      }
      final status = deposit['status']?.toString();
      if (status == 'Da thanh toan') {
        daThanhToan++;
      } else if (status == 'Cho thanh toan') {
        choThanhToan++;
      }
    }

    _countDaYeuCauCoc = daYeuCauCoc;
    _countDaThanhToan = daThanhToan;
    _countChoThanhToan = choThanhToan;
  }

  void _onFilterChanged() {
    setState(() {
      _calculateStats();
      _calculateDepositStats();
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
            onPressed: _fetchStatsData,
            tooltip: 'Refresh',
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
          Navigator.pop(context);
          if (_selectedTab != 0) {
            setState(() => _selectedTab = 0);
          }
        },
        onAdminDepositStatsTapped: () {
          Navigator.pop(context);
          if (_selectedTab != 1) {
            setState(() => _selectedTab = 1);
          }
        },
      ),
      body:
          _selectedTab == 0 ? _buildViewingStatsTab() : _buildDepositStatsTab(),
    );
  }

  Widget _buildViewingStatsTab() {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: primaryBlue))
              : _error != null
                  ? Center(
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchStatsData,
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
                        hint: const Text('All months',
                            style: TextStyle(fontSize: 14)),
                        items: [
                          const DropdownMenuItem(
                              value: 0,
                              child: Text('All months',
                                  style: TextStyle(fontSize: 14))),
                          ...List.generate(12, (index) {
                            return DropdownMenuItem(
                              value: index + 1,
                              child: Text('Month ${index + 1}',
                                  style: const TextStyle(fontSize: 14)),
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
                          const DropdownMenuItem(
                              value: 0,
                              child: Text('All years',
                                  style: TextStyle(fontSize: 14))),
                          ...years.map((y) {
                            return DropdownMenuItem(
                              value: y,
                              child: Text('Year $y',
                                  style: const TextStyle(fontSize: 14)),
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
        _buildStatCard('Viewing Request', _countYeuCauXem, Colors.orange),
        _buildStatCard('Contacting', _countDangLienHe, Colors.amber),
        _buildStatCard('Đã xác nhận', _countDaXacNhanLich, Colors.blue),
        _buildStatCard('Viewing', _countDangXem, Colors.purple),
        _buildStatCard('Completed', _countHoanThanh, Colors.green),
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
    final total = _countYeuCauXem +
        _countDangLienHe +
        _countDaXacNhanLich +
        _countDangXem +
        _countHoanThanh;
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
            'None dữ liệu trong khoảng thời gian này',
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
            'Status Chart',
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
                      title:
                          '${((_countYeuCauXem / total) * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  if (_countDangLienHe > 0)
                    PieChartSectionData(
                      color: Colors.amber,
                      value: _countDangLienHe.toDouble(),
                      title:
                          '${((_countDangLienHe / total) * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  if (_countDaXacNhanLich > 0)
                    PieChartSectionData(
                      color: Colors.blue,
                      value: _countDaXacNhanLich.toDouble(),
                      title:
                          '${((_countDaXacNhanLich / total) * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  if (_countDangXem > 0)
                    PieChartSectionData(
                      color: Colors.purple,
                      value: _countDangXem.toDouble(),
                      title:
                          '${((_countDangXem / total) * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  if (_countHoanThanh > 0)
                    PieChartSectionData(
                      color: Colors.green,
                      value: _countHoanThanh.toDouble(),
                      title:
                          '${((_countHoanThanh / total) * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
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
            _buildLegendItem(Colors.orange, 'Viewing Request'),
            _buildLegendItem(Colors.amber, 'Contacting'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(Colors.blue, 'Đã xác nhận'),
            _buildLegendItem(Colors.purple, 'Viewing'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(Colors.green, 'Completed'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
      ],
    );
  }

  Widget _buildDepositStatsTab() {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: primaryBlue))
              : _error != null
                  ? Center(
                      child: Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchStatsData,
                      color: primaryBlue,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _buildStatCard('Đã yêu cầu cọc',
                                    _countDaYeuCauCoc, Colors.orange),
                                _buildStatCard('Đã thanh toán',
                                    _countDaThanhToan, Colors.green),
                                _buildStatCard('Chờ thanh toán',
                                    _countChoThanhToan, Colors.blue),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildDepositChartSection(),
                          ],
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildDepositChartSection() {
    final total = _countDaYeuCauCoc + _countDaThanhToan + _countChoThanhToan;
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
            'Không có dữ liệu trong khoảng thời gian này',
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
            'Biêu đồ yêu cầu cọc',
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
                  if (_countDaYeuCauCoc > 0)
                    PieChartSectionData(
                      color: Colors.orange,
                      value: _countDaYeuCauCoc.toDouble(),
                      title:
                          '${((_countDaYeuCauCoc / total) * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  if (_countDaThanhToan > 0)
                    PieChartSectionData(
                      color: Colors.green,
                      value: _countDaThanhToan.toDouble(),
                      title:
                          '${((_countDaThanhToan / total) * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  if (_countChoThanhToan > 0)
                    PieChartSectionData(
                      color: Colors.blue,
                      value: _countChoThanhToan.toDouble(),
                      title:
                          '${((_countChoThanhToan / total) * 100).toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem(Colors.orange, 'Deposit Requested'),
                  _buildLegendItem(Colors.green, 'Paid'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Colors.blue, 'Pending Payment'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}


