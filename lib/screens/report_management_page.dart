import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel_plus/excel_plus.dart' as excel;
import 'package:file_saver/file_saver.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const Color reportBlue = Color(0xFF2563EB);
const Color reportDarkBlue = Color(0xFF172554);
const Color reportBackground = Color(0xFFF4F7FC);
const Color reportSecondary = Color(0xFF64748B);
const Color reportBorder = Color(0xFFE2E8F0);

class ReportManagementPage extends StatefulWidget {
  final bool showAppBar;

  const ReportManagementPage({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<ReportManagementPage> createState() =>
      _ReportManagementPageState();
}

class _ReportManagementPageState extends State<ReportManagementPage> {
  late DateTimeRange _dateRange;
  late Future<_ReportData> _reportFuture;

  String _selectedReport = 'Booking Report';
  String _selectedStatus = 'All';
  bool _exporting = false;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 30)),
      end: DateTime(now.year, now.month, now.day),
    );

    _reportFuture = _loadReport();
  }

  Future<_ReportData> _loadReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Please sign in to generate a report.');
    }

    final firestore = FirebaseFirestore.instance;
    final profileSnapshot = await firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!profileSnapshot.exists) {
      throw Exception('Your user profile could not be found.');
    }

    final profile = profileSnapshot.data() ?? <String, dynamic>{};
    final role = (profile['role'] ?? '').toString().trim();

    if (role == 'Student') {
      final bookingSnapshot = await firestore
          .collection('bookings')
          .where('studentId', isEqualTo: user.uid)
          .get();

      return _ReportData(
        role: role,
        bookings: _documentsToMaps(bookingSnapshot),
      );
    }

    if (role == 'Lecturer') {
      final results = await Future.wait([
        firestore
            .collection('bookings')
            .where('lecturerId', isEqualTo: user.uid)
            .get(),
        firestore
            .collection('availability')
            .where('lecturerId', isEqualTo: user.uid)
            .get(),
      ]);

      return _ReportData(
        role: role,
        bookings: _documentsToMaps(
          results[0],
        ),
        availability: _documentsToMaps(
          results[1],
        ),
      );
    }

    if (role == 'Administrator') {
      final results = await Future.wait([
        firestore.collection('users').get(),
        firestore.collection('bookings').get(),
        firestore.collection('availability').get(),
      ]);

      return _ReportData(
        role: role,
        users: _documentsToMaps(
          results[0],
        ),
        bookings: _documentsToMaps(
          results[1],
        ),
        availability: _documentsToMaps(
          results[2],
        ),
      );
    }

    throw Exception(
      'Your account role is not supported for report generation.',
    );
  }

  List<Map<String, dynamic>> _documentsToMaps(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map((document) {
      return <String, dynamic>{
        ...document.data(),
        '_documentId': document.id,
      };
    }).toList();
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  DateTime? _bookingDate(Map<String, dynamic> data) {
    for (final key in [
      'startAt',
      'bookingDate',
      'consultationDate',
      'createdAt',
      'createdDate',
    ]) {
      final date = _toDate(data[key]);
      if (date != null) return date;
    }
    return null;
  }

  DateTime? _availabilityDate(Map<String, dynamic> data) {
    for (final key in [
      'startAt',
      'availableDate',
      'createdAt',
      'createdDate',
    ]) {
      final date = _toDate(data[key]);
      if (date != null) return date;
    }
    return null;
  }

  DateTime? _userCreatedDate(Map<String, dynamic> data) {
    return _toDate(data['createdAt'] ?? data['createdDate']);
  }

  bool _isWithinDateRange(DateTime? date) {
    if (date == null) return false;

    final start = DateTime(
      _dateRange.start.year,
      _dateRange.start.month,
      _dateRange.start.day,
    );
    final end = DateTime(
      _dateRange.end.year,
      _dateRange.end.month,
      _dateRange.end.day,
      23,
      59,
      59,
      999,
    );

    return !date.isBefore(start) && !date.isAfter(end);
  }

  List<String> _reportOptions(String role) {
    if (role == 'Student') {
      return ['My Booking Report'];
    }
    if (role == 'Lecturer') {
      return ['My Booking Report', 'Availability Report'];
    }
    return [
      'Booking Report',
      'Availability Report',
      'User Report',
    ];
  }

  List<String> _statusOptions(String reportType) {
    if (reportType == 'Availability Report') {
      return ['All', 'available', 'booked', 'unavailable'];
    }
    if (reportType == 'User Report') {
      return ['All', 'Student', 'Lecturer', 'Administrator'];
    }
    return [
      'All',
      'Pending',
      'Approved',
      'Rejected',
      'Cancelled',
      'Completed',
    ];
  }

  List<Map<String, dynamic>> _filteredBookings(_ReportData data) {
    return data.bookings.where((booking) {
      final date = _bookingDate(booking);
      if (!_isWithinDateRange(date)) return false;

      if (_selectedStatus == 'All') return true;
      final status = (booking['bookingStatus'] ?? '')
          .toString()
          .toLowerCase();
      return status == _selectedStatus.toLowerCase();
    }).toList()
      ..sort((a, b) {
        final aDate = _bookingDate(a) ?? DateTime(1900);
        final bDate = _bookingDate(b) ?? DateTime(1900);
        return bDate.compareTo(aDate);
      });
  }

  List<Map<String, dynamic>> _filteredAvailability(_ReportData data) {
    return data.availability.where((slot) {
      if (!_isWithinDateRange(_availabilityDate(slot))) return false;

      if (_selectedStatus == 'All') return true;
      final status = (slot['status'] ?? '')
          .toString()
          .toLowerCase();
      return status == _selectedStatus.toLowerCase();
    }).toList()
      ..sort((a, b) {
        final aDate = _availabilityDate(a) ?? DateTime(1900);
        final bDate = _availabilityDate(b) ?? DateTime(1900);
        return bDate.compareTo(aDate);
      });
  }

  List<Map<String, dynamic>> _filteredUsers(_ReportData data) {
    return data.users.where((user) {
      if (!_isWithinDateRange(_userCreatedDate(user))) return false;

      if (_selectedStatus == 'All') return true;
      return (user['role'] ?? '').toString().toLowerCase() ==
          _selectedStatus.toLowerCase();
    }).toList()
      ..sort((a, b) => (a['fullName'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((b['fullName'] ?? '').toString().toLowerCase()));
  }

  String _dateText(DateTime? date) {
    if (date == null) return 'Not recorded';
    return DateFormat('dd MMM yyyy').format(date);
  }

  String _timeText(Map<String, dynamic> data) {
    final start = _toDate(data['startAt']);
    final end = _toDate(data['endAt']);

    if (start != null && end != null) {
      return '${DateFormat('hh:mm a').format(start)} - '
          '${DateFormat('hh:mm a').format(end)}';
    }

    final startTime = (data['startTime'] ?? data['bookingTime'] ?? '')
        .toString();
    final endTime = (data['endTime'] ?? '').toString();

    if (startTime.isEmpty && endTime.isEmpty) return 'Not recorded';
    if (endTime.isEmpty) return startTime;
    return '$startTime - $endTime';
  }

  String _statusText(Map<String, dynamic> data, String key) {
    final value = (data[key] ?? 'Unknown').toString().trim();
    if (value.isEmpty) return 'Unknown';
    return value[0].toUpperCase() + value.substring(1);
  }

  String _effectiveReportType(String role) {
    final options = _reportOptions(role);
    return options.contains(_selectedReport) ? _selectedReport : options.first;
  }

  List<String> _headersFor(String reportType, String role) {
    if (reportType == 'Availability Report') {
      return [
        'Availability ID',
        'Lecturer',
        'Date',
        'Time',
        'Status',
      ];
    }

    if (reportType == 'User Report') {
      return ['Name', 'Email', 'Role', 'Created Date'];
    }

    if (role == 'Student') {
      return [
        'Booking ID',
        'Date',
        'Time',
        'Lecturer',
        'Purpose',
        'Status',
      ];
    }

    if (role == 'Lecturer') {
      return [
        'Booking ID',
        'Date',
        'Time',
        'Student',
        'Purpose',
        'Status',
      ];
    }

    return [
      'Booking ID',
      'Date',
      'Time',
      'Student',
      'Lecturer',
      'Purpose',
      'Status',
    ];
  }

  List<List<String>> _rowsFor(
    _ReportData data,
    String reportType,
  ) {
    if (reportType == 'Availability Report') {
      return _filteredAvailability(data).map((slot) {
        return [
          (slot['availabilityId'] ?? slot['_documentId'] ?? '').toString(),
          (slot['lecturerName'] ?? 'Lecturer').toString(),
          _dateText(_availabilityDate(slot)),
          _timeText(slot),
          _statusText(slot, 'status'),
        ];
      }).toList();
    }

    if (reportType == 'User Report') {
      return _filteredUsers(data).map((user) {
        return [
          (user['fullName'] ?? 'Unknown').toString(),
          (user['email'] ?? '').toString(),
          (user['role'] ?? 'Unknown').toString(),
          _dateText(_userCreatedDate(user)),
        ];
      }).toList();
    }

    return _filteredBookings(data).map((booking) {
      final common = [
        (booking['bookingId'] ?? booking['_documentId'] ?? '').toString(),
        _dateText(_bookingDate(booking)),
        _timeText(booking),
      ];

      if (data.role == 'Student') {
        return [
          ...common,
          (booking['lecturerName'] ?? 'Lecturer').toString(),
          (booking['consultationPurpose'] ?? '').toString(),
          _statusText(booking, 'bookingStatus'),
        ];
      }

      if (data.role == 'Lecturer') {
        return [
          ...common,
          (booking['studentName'] ?? 'Student').toString(),
          (booking['consultationPurpose'] ?? '').toString(),
          _statusText(booking, 'bookingStatus'),
        ];
      }

      return [
        ...common,
        (booking['studentName'] ?? 'Student').toString(),
        (booking['lecturerName'] ?? 'Lecturer').toString(),
        (booking['consultationPurpose'] ?? '').toString(),
        _statusText(booking, 'bookingStatus'),
      ];
    }).toList();
  }

  List<Map<String, dynamic>> _activeRecords(
    _ReportData data,
    String reportType,
  ) {
    if (reportType == 'Availability Report') {
      return _filteredAvailability(data);
    }
    if (reportType == 'User Report') {
      return _filteredUsers(data);
    }
    return _filteredBookings(data);
  }

  Future<void> _selectDateRange() async {
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _dateRange,
      helpText: 'Select report period',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: reportBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: reportDarkBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _dateRange = selected);
    }
  }

  void _refreshReport() {
    setState(() {
      _reportFuture = _loadReport();
    });
  }

  Future<void> _exportPdf(
    _ReportData data,
    String reportType,
  ) async {
    if (_exporting) return;

    setState(() => _exporting = true);

    try {
      final headers = _headersFor(reportType, data.role);
      final rows = _rowsFor(data, reportType);
      final exportRows = rows.isEmpty
          ? [List<String>.filled(headers.length, 'No records found')]
          : rows;

      final pdf = pw.Document();
      final period = '${_dateText(_dateRange.start)} - '
          '${_dateText(_dateRange.end)}';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(28),
          build: (context) => [
            pw.Text(
              'ConsultEasy',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              reportType,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text('Role: ${data.role}'),
            pw.Text('Report period: $period'),
            pw.Text(
              'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: exportRows,
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 8,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF2563EB),
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(5),
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.5,
              ),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      await FileSaver.instance.saveFile(
        name: 'ConsultEasy_${reportType.replaceAll(' ', '_')}_Report',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (!mounted) return;
      _showMessage('PDF report generated successfully.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Unable to generate PDF: $error', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportExcel(
    _ReportData data,
    String reportType,
  ) async {
    if (_exporting) return;

    setState(() => _exporting = true);

    try {
      final workbook = excel.Excel.createExcel();
      final sheet = workbook['Sheet1'];
      final headers = _headersFor(reportType, data.role);
      final rows = _rowsFor(data, reportType);

      sheet.appendRow(
        headers.map((header) => excel.TextCellValue(header)).toList(),
      );

      if (rows.isEmpty) {
        sheet.appendRow([
          excel.TextCellValue('No records found for the selected filters.'),
        ]);
      } else {
        for (final row in rows) {
          sheet.appendRow(
            row.map((value) => excel.TextCellValue(value)).toList(),
          );
        }
      }

      final bytes = workbook.save();
      if (bytes == null) {
        throw Exception('The Excel workbook could not be created.');
      }

      await FileSaver.instance.saveFile(
        name: 'ConsultEasy_${reportType.replaceAll(' ', '_')}_Report',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.custom,
        customMimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (!mounted) return;
      _showMessage('Excel report generated successfully.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Unable to generate Excel report: $error', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: reportBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: reportSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: reportDarkBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics(_ReportData data, String reportType) {
    final bookings = _filteredBookings(data);
    final availability = _filteredAvailability(data);
    final users = _filteredUsers(data);

    if (reportType == 'User Report') {
      final students = users.where((u) => u['role'] == 'Student').length;
      final lecturers = users.where((u) => u['role'] == 'Lecturer').length;
      final administrators =
          users.where((u) => u['role'] == 'Administrator').length;

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _metricCard(
            title: 'Total Users',
            value: '${users.length}',
            icon: Icons.people_alt_outlined,
            color: reportBlue,
          ),
          _metricCard(
            title: 'Students',
            value: '$students',
            icon: Icons.school_outlined,
            color: Colors.teal,
          ),
          _metricCard(
            title: 'Lecturers',
            value: '$lecturers',
            icon: Icons.person_outline,
            color: Colors.deepPurple,
          ),
          _metricCard(
            title: 'Administrators',
            value: '$administrators',
            icon: Icons.admin_panel_settings_outlined,
            color: Colors.orange,
          ),
        ],
      );
    }

    if (reportType == 'Availability Report') {
      final available = availability.where((s) =>
          (s['status'] ?? '').toString().toLowerCase() == 'available').length;
      final booked = availability.where((s) =>
          (s['status'] ?? '').toString().toLowerCase() == 'booked').length;
      final unavailable = availability.where((s) =>
          (s['status'] ?? '').toString().toLowerCase() == 'unavailable').length;

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _metricCard(
            title: 'Total Slots',
            value: '${availability.length}',
            icon: Icons.calendar_month_outlined,
            color: reportBlue,
          ),
          _metricCard(
            title: 'Available',
            value: '$available',
            icon: Icons.event_available_outlined,
            color: Colors.teal,
          ),
          _metricCard(
            title: 'Booked',
            value: '$booked',
            icon: Icons.event_busy_outlined,
            color: Colors.deepPurple,
          ),
          _metricCard(
            title: 'Unavailable',
            value: '$unavailable',
            icon: Icons.block_outlined,
            color: Colors.orange,
          ),
        ],
      );
    }

    int countStatus(String status) => bookings.where((booking) =>
        (booking['bookingStatus'] ?? '').toString().toLowerCase() ==
        status.toLowerCase()).length;

    final cards = <Widget>[
      _metricCard(
        title: 'Total Bookings',
        value: '${bookings.length}',
        icon: Icons.event_note_outlined,
        color: reportBlue,
      ),
      _metricCard(
        title: 'Pending',
        value: '${countStatus('Pending')}',
        icon: Icons.hourglass_empty_rounded,
        color: Colors.orange,
      ),
      _metricCard(
        title: 'Approved',
        value: '${countStatus('Approved')}',
        icon: Icons.check_circle_outline,
        color: Colors.teal,
      ),
      _metricCard(
        title: 'Rejected',
        value: '${countStatus('Rejected')}',
        icon: Icons.cancel_outlined,
        color: Colors.red,
      ),
    ];

    if (data.role == 'Administrator') {
      final students = data.users.where((u) => u['role'] == 'Student').length;
      final lecturers = data.users.where((u) => u['role'] == 'Lecturer').length;
      cards.insert(
        1,
        _metricCard(
          title: 'Total Users',
          value: '${data.users.length}',
          icon: Icons.people_alt_outlined,
          color: Colors.deepPurple,
        ),
      );
      cards.add(
        _metricCard(
          title: 'Students / Lecturers',
          value: '$students / $lecturers',
          icon: Icons.groups_outlined,
          color: Colors.teal,
        ),
      );
    }

    return Wrap(spacing: 12, runSpacing: 12, children: cards);
  }

  Widget _buildReportTable(_ReportData data, String reportType) {
    final headers = _headersFor(reportType, data.role);
    final rows = _rowsFor(data, reportType);

    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: reportBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.description_outlined, size: 46, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'No Report Records Found',
              style: TextStyle(
                color: reportDarkBlue,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Try changing the date range or report filter.',
              textAlign: TextAlign.center,
              style: TextStyle(color: reportSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: reportBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            const Color(0xFFF8FAFC),
          ),
          columns: headers
              .map((header) => DataColumn(
                    label: Text(
                      header,
                      style: const TextStyle(
                        color: reportDarkBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ))
              .toList(),
          rows: rows.map((row) {
            return DataRow(
              cells: row
                  .map((value) => DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 230),
                          child: Text(
                            value,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: reportDarkBlue,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReportContent(_ReportData data) {
    final options = _reportOptions(data.role);
    final reportType = _effectiveReportType(data.role);
    final statusOptions = _statusOptions(reportType);

    if (!options.contains(_selectedReport)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedReport != reportType) {
          setState(() {
            _selectedReport = reportType;
            _selectedStatus = 'All';
          });
        }
      });
    }

    if (!statusOptions.contains(_selectedStatus)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedStatus = 'All');
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 28 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reports & Analytics',
                style: TextStyle(
                  color: reportDarkBlue,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Generate and export reports based on your account access (${data.role}).',
                style: const TextStyle(
                  color: reportSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Report Overview',
                style: TextStyle(
                  color: reportDarkBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildMetrics(data, reportType),
              const SizedBox(height: 26),
              const Text(
                'Report Filters',
                style: TextStyle(
                  color: reportDarkBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: isWide ? 230 : constraints.maxWidth,
                    child: DropdownButtonFormField<String>(
                      initialValue: reportType,
                      decoration: const InputDecoration(
                        labelText: 'Report Type',
                        prefixIcon: Icon(Icons.assessment_outlined),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: options.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedReport = value;
                          _selectedStatus = 'All';
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: isWide ? 190 : constraints.maxWidth,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status / Category',
                        prefixIcon: Icon(Icons.filter_list_rounded),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: statusOptions.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedStatus = value);
                        }
                      },
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text(
                      '${DateFormat('dd/MM/yy').format(_dateRange.start)} - '
                      '${DateFormat('dd/MM/yy').format(_dateRange.end)}',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: reportBlue,
                      minimumSize: const Size(190, 54),
                      side: const BorderSide(color: reportBorder),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _refreshReport,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: reportDarkBlue,
                      minimumSize: const Size(120, 54),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Generated Report',
                      style: TextStyle(
                        color: reportDarkBlue,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isWide)
                    Text(
                      '${_activeRecords(data, reportType).length} records',
                      style: const TextStyle(
                        color: reportSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildReportTable(data, reportType),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: _exporting
                        ? null
                        : () => _exportPdf(data, reportType),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Export PDF'),
                    style: FilledButton.styleFrom(
                      backgroundColor: reportBlue,
                      minimumSize: const Size(150, 48),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exporting
                        ? null
                        : () => _exportExcel(data, reportType),
                    icon: const Icon(Icons.table_view_rounded),
                    label: const Text('Export Excel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: reportBlue,
                      minimumSize: const Size(150, 48),
                    ),
                  ),
                  if (_exporting)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: reportBackground,
        body: Center(child: Text('Please sign in to access reports.')),
      );
    }

    return Scaffold(
      backgroundColor: reportBackground,
      appBar: widget.showAppBar
          ? AppBar(
        backgroundColor: Colors.white,
        foregroundColor: reportDarkBlue,
        elevation: 0,
        title: const Text(
          'Reports & Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh report',
            onPressed: _refreshReport,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      )
          : null,
      body: FutureBuilder<_ReportData>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: reportBlue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to Load Reports',
                      style: TextStyle(
                        color: reportDarkBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: reportSecondary),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _refreshReport,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No report data available.'));
          }

          return _buildReportContent(data);
        },
      ),
    );
  }
}

class _ReportData {
  final String role;
  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> availability;
  final List<Map<String, dynamic>> users;

  const _ReportData({
    required this.role,
    this.bookings = const [],
    this.availability = const [],
    this.users = const [],
  });
}
