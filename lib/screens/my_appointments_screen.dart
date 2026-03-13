import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MyAppointmentsScreen extends StatefulWidget {
  final String userId;
  const MyAppointmentsScreen({super.key, required this.userId});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  static const primaryBlue = Color.fromRGBO(35, 97, 219, 1);
  static const accentYellow = Color.fromRGBO(248, 192, 52, 1);

  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8000/api/viewing-appointments/'));
      if (response.statusCode == 200) {
        final List<dynamic> all = json.decode(utf8.decode(response.bodyBytes));
        
        // Filter by current user's ID, handling MongoDB $oid object
        final filtered = all.cast<Map<String, dynamic>>().where((a) {
          final userIdField = a['userId'];
          String? extractedId;
          
          if (userIdField is Map && userIdField.containsKey('\$oid')) {
            extractedId = userIdField['\$oid']?.toString();
          } else {
            extractedId = userIdField?.toString();
          }
          
          return extractedId == widget.userId;
        }).toList();

        setState(() {
          _appointments = filtered;
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Failed to load appointments'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Error: $e'; _isLoading = false; });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'yeu cau xem': return primaryBlue;
      case 'da xac nhan': return Colors.green;
      case 'hoan thanh': return Colors.teal;
      case 'huy': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'yeu cau xem': return Icons.schedule_rounded;
      case 'da xac nhan': return Icons.check_circle_outline_rounded;
      case 'hoan thanh': return Icons.task_alt_rounded;
      case 'huy': return Icons.cancel_outlined;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('My Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey[200]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAppointments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: Colors.red[700])))
              : _appointments.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: primaryBlue,
                      onRefresh: _fetchAppointments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _appointments.length,
                        itemBuilder: (context, index) => _buildAppointmentCard(_appointments[index]),
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(color: primaryBlue.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.calendar_today_outlined, size: 44, color: primaryBlue),
          ),
          const SizedBox(height: 20),
          const Text('No Appointments Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text('Book a viewing from a property listing.', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    final String status = appt['status'] ?? '';
    final Color statusColor = _statusColor(status);
    final customer = appt['customer'] as Map<String, dynamic>? ?? {};
    final String name = customer['name'] ?? '-';
    final String phone = customer['phone'] ?? '-';

    DateTime? apptTime;
    try {
      apptTime = DateTime.parse(appt['appointmentTime']).toLocal();
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(color: statusColor.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          // Status header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(status), color: statusColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const Spacer(),
                if (appt['id'] != null)
                  Text('#${appt['id']}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date & Time
                Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: primaryBlue, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Appointment Time', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        Text(
                          apptTime != null
                              ? DateFormat('EEE, dd MMM yyyy – HH:mm').format(apptTime)
                              : appt['appointmentTime'] ?? '-',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 0.5),
                const SizedBox(height: 14),

                // Customer info
                Row(
                  children: [
                    Expanded(
                      child: _infoChip(Icons.person_outline_rounded, Colors.indigo, 'Customer', name),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoChip(Icons.phone_outlined, Colors.teal, 'Phone', phone),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, Color color, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
