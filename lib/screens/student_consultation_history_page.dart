
import 'package:flutter/material.dart';

// =============================================
// CONSULTEASY THEME
// =============================================

const Color historyBlue = Color(0xFF2563EB);
const Color historyDarkBlue = Color(0xFF172554);
const Color historyBackground = Color(0xFFF4F7FC);
const Color historySecondary = Color(0xFF64748B);
const Color historyBorder = Color(0xFFE2E8F0);

// =============================================
// CONSULTATION HISTORY MODEL
// =============================================

class _HistoryRecord {
  final String historyID;
  final String bookingID;
  final String studentID;
  final String lecturerID;
  final DateTime consultationDate;
  final String consultationStatus;
  final String remarks;

  const _HistoryRecord({
    required this.historyID,
    required this.bookingID,
    required this.studentID,
    required this.lecturerID,
    required this.consultationDate,
    required this.consultationStatus,
    required this.remarks,
  });
}

// =============================================
// STUDENT CONSULTATION HISTORY PAGE
// =============================================

class StudentConsultationHistoryPage extends StatefulWidget {
  const StudentConsultationHistoryPage({super.key});

  @override
  State<StudentConsultationHistoryPage> createState() =>
      _StudentConsultationHistoryPageState();
}

class _StudentConsultationHistoryPageState
    extends State<StudentConsultationHistoryPage> {

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';
  String _selectedStatus = 'All';

  // =========================================
  // SAMPLE DATA - UI PREVIEW ONLY
  // =========================================

  final List<_HistoryRecord> _historyRecords = [
    _HistoryRecord(
      historyID: 'HST-2026-003',
      bookingID: 'CE-2026-003',
      studentID: 'STU-1024',
      lecturerID: 'LEC-002',
      consultationDate: DateTime(2026, 11, 3),
      consultationStatus: 'Completed',
      remarks:
          'Discussed programming assignment requirements. '
          'Lecturer provided additional explanations '
          'and coding guidance.',
    ),

    _HistoryRecord(
      historyID: 'HST-2026-002',
      bookingID: 'CE-2026-002',
      studentID: 'STU-1024',
      lecturerID: 'LEC-001',
      consultationDate: DateTime(2026, 10, 28),
      consultationStatus: 'Completed',
      remarks:
          'Discussed project development progress. '
          'Several improvements were suggested '
          'for the project documentation.',
    ),

    _HistoryRecord(
      historyID: 'HST-2026-001',
      bookingID: 'CE-2026-001',
      studentID: 'STU-1024',
      lecturerID: 'LEC-003',
      consultationDate: DateTime(2026, 10, 20),
      consultationStatus: 'Completed',
      remarks:
          'Discussed database design and SQL queries. '
          'Student demonstrated understanding '
          'of the database concepts.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =========================================
  // HISTORY COUNTS
  // =========================================

  int get _totalRecords => _historyRecords.length;

  int get _completedRecords =>
      _historyRecords.where(
        (record) =>
            record.consultationStatus.toLowerCase() ==
            'completed',
      ).length;

  DateTime? get _latestConsultation {
    if (_historyRecords.isEmpty) return null;

    final sorted = [..._historyRecords]
      ..sort(
        (a, b) => b.consultationDate.compareTo(
          a.consultationDate,
        ),
      );

    return sorted.first.consultationDate;
  }

  // =========================================
  // STATUS FILTERS
  // =========================================

  List<String> get _statusFilters {
    final statuses = _historyRecords
        .map((record) => record.consultationStatus)
        .toSet()
        .toList()
      ..sort();

    return ['All', ...statuses];
  }

  // =========================================
  // FILTER HISTORY
  // =========================================

  List<_HistoryRecord> get _filteredRecords {
    final records = _historyRecords.where((record) {

      final matchesStatus =
          _selectedStatus == 'All' ||
          record.consultationStatus == _selectedStatus;

      final query = _searchQuery.toLowerCase();

      final matchesSearch =
          record.historyID.toLowerCase().contains(query) ||
          record.bookingID.toLowerCase().contains(query) ||
          record.lecturerID.toLowerCase().contains(query) ||
          record.studentID.toLowerCase().contains(query) ||
          record.remarks.toLowerCase().contains(query);

      return matchesStatus && matchesSearch;
    }).toList();

    records.sort(
      (a, b) => b.consultationDate.compareTo(
        a.consultationDate,
      ),
    );

    return records;
  }

  // =========================================
  // DATE FORMATTING
  // =========================================

  String _formatDate(DateTime date) {
    return MaterialLocalizations.of(context)
        .formatMediumDate(date);
  }

  // =========================================
  // STATUS COLOUR
  // =========================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF059669);

      case 'cancelled':
        return const Color(0xFFDC2626);

      default:
        return const Color(0xFFD97706);
    }
  }

  // =========================================
  // PAGE HEADING
  // =========================================

  Widget _pageHeading() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consultation History',
          style: TextStyle(
            color: historyDarkBlue,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 7),

        Text(
          'Review your previous consultation sessions '
          'and lecturer feedback.',
          style: TextStyle(
            color: historySecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // =========================================
  // PREVIEW NOTICE
  // =========================================

  Widget _previewNotice() {
    return Container(
      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFED7AA),
        ),
      ),

      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFC2410C),
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'UI Preview: Consultation records are sample data. '
              'Firebase integration will be added later.',
              style: TextStyle(
                color: Color(0xFF9A3412),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // SUMMARY CARD
  // =========================================

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: historyBorder,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,

            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(
              icon,
              color: color,
              size: 23,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: historySecondary,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: historyDarkBlue,
                    fontSize: 20,
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

  // =========================================
  // SUMMARY SECTION
  // =========================================

  Widget _buildSummary() {
    return LayoutBuilder(
      builder: (context, constraints) {

        final columns =
            constraints.maxWidth >= 850 ? 3 : 1;

        final latestDate = _latestConsultation;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),

          crossAxisCount: columns,
          crossAxisSpacing: 13,
          mainAxisSpacing: 13,

          childAspectRatio:
              columns == 3 ? 2.5 : 3.2,

          children: [
            _summaryCard(
              title: 'Total Records',
              value: _totalRecords.toString(),
              icon: Icons.history_rounded,
              color: historyBlue,
            ),

            _summaryCard(
              title: 'Completed Consultations',
              value: _completedRecords.toString(),
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF059669),
            ),

            _summaryCard(
              title: 'Latest Consultation',
              value: latestDate == null
                  ? '-'
                  : _formatDate(latestDate),
              icon: Icons.calendar_month_outlined,
              color: const Color(0xFF7C3AED),
            ),
          ],
        );
      },
    );
  }

  // =========================================
  // SEARCH FIELD
  // =========================================

  Widget _searchField() {
    return TextField(
      controller: _searchController,

      onChanged: (value) {
        setState(() {
          _searchQuery = value.trim();
        });
      },

      decoration: InputDecoration(
        hintText: 'Search Booking ID, Lecturer ID...',
        prefixIcon: const Icon(
          Icons.search_rounded,
        ),

        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _searchQuery = '';
                  });
                },

                icon: const Icon(Icons.close_rounded),
              ),

        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: historyBorder,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: historyBorder,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: historyBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // =========================================
  // STATUS FILTER
  // =========================================

  Widget _buildStatusFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,

      child: Row(
        children: _statusFilters.map((status) {

          final selected = _selectedStatus == status;

          return Padding(
            padding: const EdgeInsets.only(right: 9),

            child: ChoiceChip(
              label: Text(status),
              selected: selected,

              onSelected: (_) {
                setState(() {
                  _selectedStatus = status;
                });
              },

              selectedColor: historyBlue,
              backgroundColor: Colors.white,

              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : historySecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),

              side: BorderSide(
                color: selected
                    ? historyBlue
                    : historyBorder,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =========================================
  // STATUS BADGE
  // =========================================

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        status.toUpperCase(),

        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // =========================================
  // DETAIL ROW
  // =========================================

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: historyBlue,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: historySecondary,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                value,
                style: const TextStyle(
                  color: historyDarkBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================
  // HISTORY CARD
  // =========================================

  Widget _historyCard(_HistoryRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),

      padding: const EdgeInsets.all(19),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: historyBorder,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // HISTORY ID AND STATUS
          Row(
            children: [
              Expanded(
                child: Text(
                  record.historyID,

                  style: const TextStyle(
                    color: historySecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              _statusBadge(record.consultationStatus),
            ],
          ),

          const SizedBox(height: 18),

          // CONSULTATION DATE
          _detailRow(
            icon: Icons.calendar_month_outlined,
            title: 'Consultation Date',
            value: _formatDate(record.consultationDate),
          ),

          const SizedBox(height: 15),

          // LECTURER ID
          _detailRow(
            icon: Icons.person_outline_rounded,
            title: 'Lecturer ID',
            value: record.lecturerID,
          ),

          const SizedBox(height: 15),

          // BOOKING ID
          _detailRow(
            icon: Icons.confirmation_number_outlined,
            title: 'Booking ID',
            value: record.bookingID,
          ),

          const SizedBox(height: 15),

          // REMARKS
          _detailRow(
            icon: Icons.notes_rounded,
            title: 'Consultation Remarks',
            value: record.remarks,
          ),

          const SizedBox(height: 19),

          const Divider(color: historyBorder),

          const SizedBox(height: 10),

          // VIEW DETAILS BUTTON
          SizedBox(
            width: double.infinity,

            child: OutlinedButton.icon(
              onPressed: () {
                _showHistoryDetails(record);
              },

              icon: const Icon(
                Icons.visibility_outlined,
                size: 18,
              ),

              label: const Text(
                'View Full Details',
              ),

              style: OutlinedButton.styleFrom(
                foregroundColor: historyBlue,

                side: const BorderSide(
                  color: historyBlue,
                ),

                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // FULL HISTORY DETAILS
  // =========================================

  void _showHistoryDetails(_HistoryRecord record) {

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),

      builder: (sheetContext) {

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,

              children: [

                Center(
                  child: Container(
                    width: 42,
                    height: 5,

                    decoration: BoxDecoration(
                      color: historyBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Consultation Details',

                  style: TextStyle(
                    color: historyDarkBlue,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  'History ID: ${record.historyID}',

                  style: const TextStyle(
                    color: historySecondary,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 20),

                _statusBadge(record.consultationStatus),

                const SizedBox(height: 25),

                _detailRow(
                  icon: Icons.confirmation_number_outlined,
                  title: 'Booking ID',
                  value: record.bookingID,
                ),

                const SizedBox(height: 20),

                _detailRow(
                  icon: Icons.person_outline_rounded,
                  title: 'Student ID',
                  value: record.studentID,
                ),

                const SizedBox(height: 20),

                _detailRow(
                  icon: Icons.school_outlined,
                  title: 'Lecturer ID',
                  value: record.lecturerID,
                ),

                const SizedBox(height: 20),

                _detailRow(
                  icon: Icons.calendar_month_outlined,
                  title: 'Consultation Date',
                  value: _formatDate(record.consultationDate),
                ),

                const SizedBox(height: 20),

                _detailRow(
                  icon: Icons.flag_outlined,
                  title: 'Final Consultation Status',
                  value: record.consultationStatus,
                ),

                const SizedBox(height: 20),

                _detailRow(
                  icon: Icons.notes_rounded,
                  title: 'Remarks',
                  value: record.remarks,
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,

                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },

                    style: FilledButton.styleFrom(
                      backgroundColor: historyBlue,

                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),

                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================
  // EMPTY STATE
  // =========================================

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: historyBorder,
        ),
      ),

      child: Column(
        children: [
          const Icon(
            Icons.history_rounded,
            size: 52,
            color: Color(0xFF94A3B8),
          ),

          const SizedBox(height: 15),

          const Text(
            'No Consultation History Found',

            style: TextStyle(
              color: historyDarkBlue,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Your consultation records will appear here '
            'after consultation sessions are recorded.',

            textAlign: TextAlign.center,

            style: TextStyle(
              color: historySecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // MAIN BUILD
  // =========================================

  @override
  Widget build(BuildContext context) {

    final records = _filteredRecords;

    return Container(
      color: historyBackground,

      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1200,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                _pageHeading(),

                const SizedBox(height: 18),

                _previewNotice(),

                const SizedBox(height: 27),

                // SUMMARY
                const Text(
                  'History Overview',

                  style: TextStyle(
                    color: historyDarkBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                _buildSummary(),

                const SizedBox(height: 30),

                // SEARCH
                _searchField(),

                const SizedBox(height: 22),

                // HISTORY HEADER
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Previous Consultations',

                        style: TextStyle(
                          color: historyDarkBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Text(
                      '${records.length} records',

                      style: const TextStyle(
                        color: historySecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // FILTER
                _buildStatusFilters(),

                const SizedBox(height: 20),

                // HISTORY LIST
                if (records.isEmpty)
                  _emptyState()
                else
                  ...records.map(_historyCard),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
