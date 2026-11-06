
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =====================================================
// CONSULTEASY DESIGN SYSTEM
// =====================================================

const Color calendarBlue = Color(0xFF2563EB);
const Color calendarDarkBlue = Color(0xFF172554);
const Color calendarBackground = Color(0xFFF4F7FC);
const Color calendarSecondary = Color(0xFF64748B);
const Color calendarBorder = Color(0xFFE2E8F0);

const Color calendarGreen = Color(0xFF059669);
const Color calendarOrange = Color(0xFFD97706);
const Color calendarRed = Color(0xFFDC2626);

// =====================================================
// LECTURER CALENDAR PAGE
// =====================================================

class LecturerCalendarPage extends StatefulWidget {
  const LecturerCalendarPage({super.key});

  @override
  State<LecturerCalendarPage> createState() =>
      _LecturerCalendarPageState();
}

class _LecturerCalendarPageState
    extends State<LecturerCalendarPage> {

  // ===================================================
  // 1. CALENDAR STATE
  // ===================================================

  DateTime _focusedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  DateTime _selectedDate = DateUtils.dateOnly(
    DateTime.now(),
  );

  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Pending',
    'Approved',
  ];

  User? get _currentUser =>
      FirebaseAuth.instance.currentUser;

  // ===================================================
  // 2. DATE HELPERS
  // ===================================================

  DateTime? _toDateTime(dynamic value) {

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  String _formatDate(DateTime date) {
    return MaterialLocalizations.of(context)
        .formatMediumDate(date);
  }

  String _formatTime(DateTime date) {
    return TimeOfDay.fromDateTime(date)
        .format(context);
  }

  String _formatDateTime(dynamic value) {

    final date = _toDateTime(value);

    if (date == null) {
      return 'Not available';
    }

    return '${_formatDate(date)} at ${_formatTime(date)}';
  }

  String _monthLabel(DateTime date) {

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  String _weekdayLabel(DateTime date) {

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return weekdays[date.weekday - 1];
  }

  // ===================================================
  // 3. BOOKING STATUS HELPERS
  // ===================================================

  String _bookingStatus(
    Map<String, dynamic> data,
  ) {

    return (data['bookingStatus'] ??
            data['status'] ??
            'Pending')
        .toString()
        .trim();
  }

  bool _isActiveBooking(
    Map<String, dynamic> data,
  ) {

    final status = _bookingStatus(data).toLowerCase();

    return ![
      'rejected',
      'cancelled',
      'canceled',
      'completed',
      'done',
    ].contains(status);
  }

  Color _statusColor(String status) {

    switch (status.toLowerCase()) {

      case 'approved':
        return calendarGreen;

      case 'pending':
        return calendarOrange;

      case 'rejected':
      case 'cancelled':
        return calendarRed;

      default:
        return calendarSecondary;
    }
  }

  Color _statusBackground(String status) {

    switch (status.toLowerCase()) {

      case 'approved':
        return const Color(0xFFDCFCE7);

      case 'pending':
        return const Color(0xFFFEF3C7);

      case 'rejected':
      case 'cancelled':
        return const Color(0xFFFEE2E2);

      default:
        return const Color(0xFFF1F5F9);
    }
  }

  Widget _statusBadge(String status) {

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        status.toUpperCase(),

        style: TextStyle(
          color: _statusColor(status),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ===================================================
  // 4. FILTER BOOKINGS
  // ===================================================

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _activeBookings(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {

    final result = docs
        .where((doc) => _isActiveBooking(doc.data()))
        .toList();

    result.sort((a, b) {

      final aDate =
          _toDateTime(a.data()['startAt']) ??
          DateTime(9999);

      final bDate =
          _toDateTime(b.data()['startAt']) ??
          DateTime(9999);

      return aDate.compareTo(bDate);
    });

    return result;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _filteredBookings(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {

    final result = docs.where((doc) {

      final status = _bookingStatus(
        doc.data(),
      ).toLowerCase();

      if (_selectedFilter == 'All') {
        return true;
      }

      return status ==
          _selectedFilter.toLowerCase();

    }).toList();

    result.sort((a, b) {

      final aDate =
          _toDateTime(a.data()['startAt']) ??
          DateTime(9999);

      final bDate =
          _toDateTime(b.data()['startAt']) ??
          DateTime(9999);

      return aDate.compareTo(bDate);
    });

    return result;
  }

  // ===================================================
  // 5. GROUP BOOKINGS BY DATE
  // ===================================================

  Map<DateTime,
      List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _groupBookingsByDate(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {

    final Map<DateTime,
        List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        grouped = {};

    for (final doc in docs) {

      final startAt = _toDateTime(
        doc.data()['startAt'],
      );

      if (startAt == null) continue;

      final date = DateUtils.dateOnly(startAt);

      grouped.putIfAbsent(
        date,
        () => [],
      );

      grouped[date]!.add(doc);
    }

    return grouped;
  }

  // ===================================================
  // 6. SELECTED DATE BOOKINGS
  // ===================================================

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _getSelectedDateBookings(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {

    return docs.where((doc) {

      final date = _toDateTime(
        doc.data()['startAt'],
      );

      return date != null &&
          DateUtils.isSameDay(
            date,
            _selectedDate,
          );

    }).toList();
  }

  // ===================================================
  // 7. CHANGE MONTH
  // ===================================================

  void _changeMonth(int amount) {

    setState(() {

      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + amount,
      );

      _selectedDate = DateTime(
        _focusedMonth.year,
        _focusedMonth.month,
        1,
      );
    });
  }

  // ===================================================
  // 8. GO TO TODAY
  // ===================================================

  void _goToToday() {

    final today = DateUtils.dateOnly(
      DateTime.now(),
    );

    setState(() {

      _focusedMonth = DateTime(
        today.year,
        today.month,
      );

      _selectedDate = today;
    });
  }

  // ===================================================
  // 9. STATISTICS SECTION
  // ===================================================

  Widget _statisticsSection(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {

    final total = docs.length;

    final pending = docs.where((doc) {
      return _bookingStatus(
        doc.data(),
      ).toLowerCase() == 'pending';
    }).length;

    final approved = docs.where((doc) {
      return _bookingStatus(
        doc.data(),
      ).toLowerCase() == 'approved';
    }).length;

    final thisMonth = docs.where((doc) {

      final date = _toDateTime(
        doc.data()['startAt'],
      );

      return date != null &&
          date.year == _focusedMonth.year &&
          date.month == _focusedMonth.month;

    }).length;

    return LayoutBuilder(
      builder: (context, constraints) {

        final columns =
            constraints.maxWidth >= 950
                ? 4
                : constraints.maxWidth >= 550
                    ? 2
                    : 1;

        final cardWidth = (
          constraints.maxWidth -
          (columns - 1) * 13
        ) / columns;

        return Wrap(
          spacing: 13,
          runSpacing: 13,

          children: [

            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Total Bookings',
                value: total,
                subtitle: 'Active consultation requests',
                icon: Icons.event_note_rounded,
                color: calendarBlue,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Pending',
                value: pending,
                subtitle: 'Awaiting your response',
                icon: Icons.pending_actions_rounded,
                color: calendarOrange,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Approved',
                value: approved,
                subtitle: 'Confirmed consultations',
                icon: Icons.check_circle_outline_rounded,
                color: calendarGreen,
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'This Month',
                value: thisMonth,
                subtitle: 'Consultations scheduled',
                icon: Icons.calendar_month_rounded,
                color: calendarDarkBlue,
              ),
            ),
          ],
        );
      },
    );
  }

  // ===================================================
  // 10. STATISTICS CARD
  // ===================================================

  Widget _statCard({
    required String title,
    required int value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {

    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),

        border: Border.all(
          color: calendarBorder,
        ),
      ),

      child: Row(
        children: [

          Container(
            height: 45,
            width: 45,

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
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

                  style: const TextStyle(
                    color: calendarSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '$value',

                  style: const TextStyle(
                    color: calendarDarkBlue,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,

                  style: const TextStyle(
                    color: calendarSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // 11. PAGE HEADER
  // ===================================================

  Widget _pageHeader() {

    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          'My Calendar',

          style: TextStyle(
            color: calendarDarkBlue,
            fontSize: 25,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),

        SizedBox(height: 6),

        Text(
          'View your consultation schedule and keep track of upcoming student appointments.',

          style: TextStyle(
            color: calendarSecondary,
            fontSize: 12,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // ===================================================
  // 12. WELCOME BANNER
  // ===================================================

  Widget _welcomeBanner() {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            calendarBlue,
            calendarDarkBlue,
          ],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(20),
      ),

      child: LayoutBuilder(
        builder: (context, constraints) {

          final compact = constraints.maxWidth < 500;

          final textContent = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),

                child: const Text(
                  'LECTURER SCHEDULE',

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),

              const SizedBox(height: 17),

              Text(
                'Your Consultation Calendar',

                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 20 : 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 9),

              const Text(
                'Stay organised, monitor your appointments and manage your consultation schedule in one place.',

                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
            ],
          );

          if (compact) {
            return textContent;
          }

          return Row(
            children: [

              Expanded(
                flex: 5,
                child: textContent,
              ),

              const SizedBox(width: 20),

              Expanded(
                flex: 2,
                child: Center(
                  child: Container(
                    height: 105,
                    width: 105,

                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.13),
                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===================================================
  // 13. CALENDAR HEADER
  // ===================================================

  Widget _calendarHeader() {

    return Row(
      children: [

        Expanded(
          child: Text(
            _monthLabel(_focusedMonth),

            style: const TextStyle(
              color: calendarDarkBlue,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        TextButton(
          onPressed: _goToToday,

          child: const Text(
            'Today',
            style: TextStyle(
              color: calendarBlue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        IconButton(
          tooltip: 'Previous month',

          onPressed: () {
            _changeMonth(-1);
          },

          icon: const Icon(
            Icons.chevron_left_rounded,
            color: calendarDarkBlue,
          ),
        ),

        IconButton(
          tooltip: 'Next month',

          onPressed: () {
            _changeMonth(1);
          },

          icon: const Icon(
            Icons.chevron_right_rounded,
            color: calendarDarkBlue,
          ),
        ),
      ],
    );
  }

  // ===================================================
  // 14. WEEKDAY HEADER
  // ===================================================

  Widget _weekdayHeader() {

    const weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return Row(
      children: weekdays.map((day) {

        return Expanded(
          child: Center(
            child: Text(
              day,

              style: const TextStyle(
                color: calendarSecondary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );

      }).toList(),
    );
  }

  // ===================================================
  // 15. CALENDAR DAY CELL
  // ===================================================

  Widget _calendarDayCell({
    required DateTime date,
    required bool selected,
    required bool today,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings,
  }) {

    final day = date.day;

    final hasBookings = bookings.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(12),

      onTap: () {

        setState(() {
          _selectedDate = date;
        });
      },

      child: Container(
        margin: const EdgeInsets.all(3),

        decoration: BoxDecoration(
          color: selected
              ? calendarBlue
              : Colors.transparent,

          borderRadius: BorderRadius.circular(12),

          border: today && !selected
              ? Border.all(
                  color: calendarBlue,
                  width: 1.4,
                )
              : null,
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text(
              '$day',

              style: TextStyle(
                color: selected
                    ? Colors.white
                    : calendarDarkBlue,

                fontSize: 13,

                fontWeight: selected || today
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),

            const SizedBox(height: 5),

            // BOOKING INDICATORS

            if (hasBookings)

              Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: bookings.take(3).map((doc) {

                  final status = _bookingStatus(
                    doc.data(),
                  );

                  final dotColor = selected
                      ? Colors.white
                      : _statusColor(status);

                  return Container(
                    width: 5,
                    height: 5,

                    margin: const EdgeInsets.symmetric(
                      horizontal: 1.5,
                    ),

                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                  );

                }).toList(),
              )

            else

              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }

  // ===================================================
  // 16. MONTH CALENDAR GRID
  // ===================================================

  Widget _calendarGrid(
    Map<DateTime,
        List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        bookingsByDate,
  ) {

    final firstDay = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;

    // Monday is the first day of the week.

    final leadingDays = firstDay.weekday - 1;

    final cellCount =
        ((leadingDays + daysInMonth + 6) ~/ 7) * 7;

    final today = DateUtils.dateOnly(
      DateTime.now(),
    );

    return GridView.builder(
      shrinkWrap: true,

      physics: const NeverScrollableScrollPhysics(),

      itemCount: cellCount,

      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
      ),

      itemBuilder: (context, index) {

        final day = index - leadingDays + 1;

        if (day < 1 || day > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date = DateTime(
          _focusedMonth.year,
          _focusedMonth.month,
          day,
        );

        final selected = DateUtils.isSameDay(
          date,
          _selectedDate,
        );

        final isToday = DateUtils.isSameDay(
          date,
          today,
        );

        final dayBookings =
            bookingsByDate[
              DateUtils.dateOnly(date)
            ] ?? [];

        return _calendarDayCell(
          date: date,
          selected: selected,
          today: isToday,
          bookings: dayBookings,
        );
      },
    );
  }

  // ===================================================
  // 17. CALENDAR LEGEND
  // ===================================================

  Widget _legendItem(
    Color color,
    String label,
  ) {

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [

        Container(
          width: 8,
          height: 8,

          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 6),

        Text(
          label,

          style: const TextStyle(
            color: calendarSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _calendarLegend() {

    return Wrap(
      spacing: 17,
      runSpacing: 9,

      children: [

        _legendItem(
          calendarOrange,
          'Pending',
        ),

        _legendItem(
          calendarGreen,
          'Approved',
        ),

        _legendItem(
          calendarBlue,
          'Today',
        ),
      ],
    );
  }

  // ===================================================
  // 18. CALENDAR CARD
  // ===================================================

  Widget _calendarCard(
    Map<DateTime,
        List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        bookingsByDate,
  ) {

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),

        border: Border.all(
          color: calendarBorder,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          _calendarHeader(),

          const SizedBox(height: 19),

          _weekdayHeader(),

          const SizedBox(height: 12),

          _calendarGrid(bookingsByDate),

          const SizedBox(height: 17),

          const Divider(
            color: calendarBorder,
          ),

          const SizedBox(height: 14),

          _calendarLegend(),
        ],
      ),
    );
  }

  // ===================================================
  // 19. SECTION HEADER
  // ===================================================

  Widget _sectionHeading(
    String title,
    String subtitle,
  ) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          title,

          style: const TextStyle(
            color: calendarDarkBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          subtitle,

          style: const TextStyle(
            color: calendarSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ===================================================
  // 20. FILTER CHIPS
  // ===================================================

  Widget _filterSection() {

    return Wrap(
      spacing: 9,
      runSpacing: 9,

      children: _filters.map((filter) {

        final selected =
            _selectedFilter == filter;

        return ChoiceChip(
          label: Text(filter),

          selected: selected,

          onSelected: (value) {

            setState(() {
              _selectedFilter = filter;
            });
          },

          selectedColor: calendarBlue,

          backgroundColor: Colors.white,

          side: BorderSide(
            color: selected
                ? calendarBlue
                : calendarBorder,
          ),

          labelStyle: TextStyle(
            color: selected
                ? Colors.white
                : calendarSecondary,

            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),

          showCheckmark: false,
        );

      }).toList(),
    );
  }

  // ===================================================
  // 21. INFORMATION ROW
  // ===================================================

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 17),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            height: 36,
            width: 36,

            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(
              icon,
              color: calendarBlue,
              size: 18,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  label,

                  style: const TextStyle(
                    color: calendarSecondary,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 5),

                SelectableText(
                  value,

                  style: const TextStyle(
                    color: calendarDarkBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // 22. BOOKING DETAILS
  // ===================================================

  void _showBookingDetails(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {

    final data = doc.data();

    final studentName =
        data['studentName'] as String? ?? 'Student';

    final studentEmail =
        data['studentEmail'] as String? ?? 'Not provided';

    final lecturerName =
        data['lecturerName'] as String? ?? 'Lecturer';

    final purpose =
        data['consultationPurpose'] as String? ??
        'No purpose provided';

    final status = _bookingStatus(data);

    final startAt = _toDateTime(
      data['startAt'],
    );

    final endAt = _toDateTime(
      data['endAt'],
    );

    showModalBottomSheet<void>(
      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (sheetContext) {

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(sheetContext).size.height * 0.88,
            ),

            decoration: const BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),

            child: SingleChildScrollView(
              padding: const EdgeInsets.all(23),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // DRAG HANDLE

                  Center(
                    child: Container(
                      width: 42,
                      height: 5,

                      decoration: BoxDecoration(
                        color: calendarBorder,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 23),

                  // HEADER

                  Row(
                    children: [

                      const Expanded(
                        child: Text(
                          'Consultation Details',

                          style: TextStyle(
                            color: calendarDarkBlue,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      _statusBadge(status),
                    ],
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'STUDENT INFORMATION',

                    style: TextStyle(
                      color: calendarSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 17),

                  _infoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Student Name',
                    value: studentName,
                  ),

                  _infoRow(
                    icon: Icons.email_outlined,
                    label: 'Student Email',
                    value: studentEmail,
                  ),

                  const Divider(
                    color: calendarBorder,
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'CONSULTATION INFORMATION',

                    style: TextStyle(
                      color: calendarSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 17),

                  _infoRow(
                    icon: Icons.school_outlined,
                    label: 'Lecturer',
                    value: lecturerName,
                  ),

                  _infoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',

                    value: startAt == null
                        ? 'Not available'
                        : _formatDate(startAt),
                  ),

                  _infoRow(
                    icon: Icons.access_time_rounded,
                    label: 'Consultation Time',

                    value: startAt == null || endAt == null
                        ? 'Not available'
                        : '${_formatTime(startAt)} – ${_formatTime(endAt)}',
                  ),

                  _infoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Request Submitted',

                    value: _formatDateTime(
                      data['createdAt'],
                    ),
                  ),

                  const SizedBox(height: 5),

                  const Text(
                    'CONSULTATION PURPOSE',

                    style: TextStyle(
                      color: calendarSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: calendarBackground,
                      borderRadius: BorderRadius.circular(13),

                      border: Border.all(
                        color: calendarBorder,
                      ),
                    ),

                    child: Text(
                      purpose,

                      style: const TextStyle(
                        color: calendarDarkBlue,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SelectableText(
                    'Booking ID: ${doc.id}',

                    style: const TextStyle(
                      color: calendarSecondary,
                      fontSize: 10,
                    ),
                  ),

                  const SizedBox(height: 23),

                  SizedBox(
                    width: double.infinity,

                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                      },

                      style: FilledButton.styleFrom(
                        backgroundColor: calendarBlue,

                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===================================================
  // 23. APPOINTMENT CARD
  // ===================================================

  Widget _appointmentCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {

    final data = doc.data();

    final studentName =
        data['studentName'] as String? ?? 'Student';

    final studentEmail =
        data['studentEmail'] as String? ?? 'Not provided';

    final purpose =
        data['consultationPurpose'] as String? ??
        'No purpose provided';

    final status = _bookingStatus(data);

    final startAt = _toDateTime(
      data['startAt'],
    );

    final endAt = _toDateTime(
      data['endAt'],
    );

    final initial = studentName.isNotEmpty
        ? studentName[0].toUpperCase()
        : 'S';

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: calendarBorder,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // STUDENT

          Row(
            children: [

              CircleAvatar(
                radius: 22,

                backgroundColor: const Color(0xFFDBEAFE),

                child: Text(
                  initial,

                  style: const TextStyle(
                    color: calendarBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      studentName,

                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: calendarDarkBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      studentEmail,

                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: calendarSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              _statusBadge(status),
            ],
          ),

          const SizedBox(height: 17),

          const Divider(
            color: calendarBorder,
            height: 1,
          ),

          const SizedBox(height: 15),

          // TIME

          Row(
            children: [

              const Icon(
                Icons.access_time_rounded,
                color: calendarBlue,
                size: 18,
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  startAt == null || endAt == null
                      ? 'Time not available'
                      : '${_formatTime(startAt)} – ${_formatTime(endAt)}',

                  style: const TextStyle(
                    color: calendarDarkBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // PURPOSE

          const Text(
            'CONSULTATION PURPOSE',

            style: TextStyle(
              color: calendarSecondary,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            purpose,

            maxLines: 2,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              color: calendarSecondary,
              fontSize: 11,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 14),

          // DETAILS BUTTON

          SizedBox(
            width: double.infinity,

            child: OutlinedButton.icon(
              onPressed: () {
                _showBookingDetails(
                  context,
                  doc,
                );
              },

              icon: const Icon(
                Icons.visibility_outlined,
                size: 17,
              ),

              label: const Text(
                'View Details',
              ),

              style: OutlinedButton.styleFrom(
                foregroundColor: calendarBlue,

                side: const BorderSide(
                  color: calendarBlue,
                ),

                padding: const EdgeInsets.symmetric(
                  vertical: 11,
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

  // ===================================================
  // 24. EMPTY APPOINTMENT STATE
  // ===================================================

  Widget _emptyState() {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),

        border: Border.all(
          color: calendarBorder,
        ),
      ),

      child: Column(
        children: [

          Container(
            height: 60,
            width: 60,

            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(17),
            ),

            child: const Icon(
              Icons.event_available_outlined,
              color: calendarSecondary,
              size: 30,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'No Consultations Scheduled',

            style: TextStyle(
              color: calendarDarkBlue,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'There are no active consultation bookings for this date. Select another date to view your appointments.',

            textAlign: TextAlign.center,

            style: TextStyle(
              color: calendarSecondary,
              fontSize: 11,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // 25. SELECTED DAY PANEL
  // ===================================================

  Widget _selectedDayPanel(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings,
  ) {

    final selectedBookings = _getSelectedDateBookings(
      bookings,
    );

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),

        border: Border.all(
          color: calendarBorder,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // HEADER

          Row(
            children: [

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      'Daily Schedule',

                      style: TextStyle(
                        color: calendarDarkBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '${_weekdayLabel(_selectedDate)}, ${_formatDate(_selectedDate)}',

                      style: const TextStyle(
                        color: calendarSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),

                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),

                child: Text(
                  '${selectedBookings.length}',

                  style: const TextStyle(
                    color: calendarBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 19),

          // FILTER

          _filterSection(),

          const SizedBox(height: 19),

          const Divider(
            color: calendarBorder,
          ),

          const SizedBox(height: 15),

          // APPOINTMENTS

          if (selectedBookings.isEmpty)

            _emptyState()

          else

            ...selectedBookings.map((doc) {

              return _appointmentCard(
                context,
                doc,
              );

            }),
        ],
      ),
    );
  }

  // ===================================================
  // 26. CALENDAR AND DAILY SCHEDULE LAYOUT
  // ===================================================

  Widget _calendarAndSchedule({
    required Map<DateTime,
        List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        bookingsByDate,

    required List<QueryDocumentSnapshot<Map<String, dynamic>>>
        bookings,
  }) {

    return LayoutBuilder(
      builder: (context, constraints) {

        // DESKTOP / WIDE TABLET

        if (constraints.maxWidth >= 1000) {

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Expanded(
                flex: 6,
                child: _calendarCard(
                  bookingsByDate,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                flex: 5,
                child: _selectedDayPanel(
                  bookings,
                ),
              ),
            ],
          );
        }

        // MOBILE / TABLET

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _calendarCard(
              bookingsByDate,
            ),

            const SizedBox(height: 22),

            _selectedDayPanel(
              bookings,
            ),
          ],
        );
      },
    );
  }

  // ===================================================
  // 27. MAIN PAGE CONTENT
  // ===================================================

  Widget _buildPageContent(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {

    final filteredBookings = _filteredBookings(
      docs,
    );

    final bookingsByDate = _groupBookingsByDate(
      filteredBookings,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),

      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1300,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // PAGE HEADER

              _pageHeader(),

              const SizedBox(height: 23),

              // WELCOME BANNER

              _welcomeBanner(),

              const SizedBox(height: 28),

              // STATISTICS

              _sectionHeading(
                'Calendar Overview',
                'Monitor your consultation bookings and appointment activity.',
              ),

              const SizedBox(height: 15),

              _statisticsSection(
                docs,
              ),

              const SizedBox(height: 30),

              // CALENDAR + SCHEDULE

              _calendarAndSchedule(
                bookingsByDate: bookingsByDate,
                bookings: filteredBookings,
              ),

              const SizedBox(height: 32),

              // FOOTER

              const Center(
                child: Text(
                  'ConsultEasy • Academic Consultation System',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: calendarSecondary,
                    fontSize: 11,
                  ),
                ),
              ),

              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  // ===================================================
  // 28. ERROR STATE
  // ===================================================

  Widget _errorState() {

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),

        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),

            border: Border.all(
              color: calendarBorder,
            ),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Icon(
                Icons.cloud_off_outlined,
                color: calendarRed,
                size: 43,
              ),

              const SizedBox(height: 15),

              const Text(
                'Unable to Load Calendar',

                style: TextStyle(
                  color: calendarDarkBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Please check your internet connection and Firestore security rules.',

                textAlign: TextAlign.center,

                style: TextStyle(
                  color: calendarSecondary,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 15),

              TextButton.icon(
                onPressed: () {
                  setState(() {});
                },

                icon: const Icon(
                  Icons.refresh_rounded,
                ),

                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================================================
  // 29. MAIN BUILD
  // ===================================================

  @override
  Widget build(BuildContext context) {

    final user = _currentUser;

    // -----------------------------------------------
    // AUTHENTICATION CHECK
    // -----------------------------------------------

    if (user == null) {

      return Scaffold(
        backgroundColor: calendarBackground,

        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Icon(
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: calendarBlue,
                ),

                const SizedBox(height: 16),

                const Text(
                  'Please sign in to access your calendar.',

                  style: TextStyle(
                    color: calendarDarkBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 15),

                FilledButton(
                  onPressed: () {

                    Navigator.of(context)
                        .pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  },

                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // -----------------------------------------------
    // MAIN SCAFFOLD
    // -----------------------------------------------

    return Scaffold(
      backgroundColor: calendarBackground,

      // APP BAR

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: calendarDarkBlue,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 68,

        title: Row(
          children: [

            Container(
              height: 38,
              width: 38,

              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(11),
              ),

              child: const Icon(
                Icons.school_rounded,
                color: calendarBlue,
                size: 23,
              ),
            ),

            const SizedBox(width: 11),

            const Text(
              'ConsultEasy',

              style: TextStyle(
                color: calendarDarkBlue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        actions: [

          IconButton(
            tooltip: 'Refresh calendar',

            onPressed: () {
              setState(() {});
            },

            icon: const Icon(
              Icons.refresh_rounded,
              color: calendarDarkBlue,
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(
              right: 15,
            ),

            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),

                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),

                child: const Row(
                  children: [

                    Icon(
                      Icons.person_rounded,
                      color: calendarBlue,
                      size: 15,
                    ),

                    SizedBox(width: 5),

                    Text(
                      'LECTURER',

                      style: TextStyle(
                        color: calendarBlue,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // -----------------------------------------------
      // FIRESTORE STREAM
      // -----------------------------------------------

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where(
              'lecturerId',
              isEqualTo: user.uid,
            )
            .snapshots(),

        builder: (context, snapshot) {

          // ERROR

          if (snapshot.hasError) {
            return _errorState();
          }

          // LOADING

          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              snapshot.data == null) {

            return const Center(
              child: CircularProgressIndicator(
                color: calendarBlue,
              ),
            );
          }

          // GET BOOKINGS

          final docs = _activeBookings(
            snapshot.data?.docs ?? [],
          );

          // DISPLAY PAGE

          return _buildPageContent(
            docs,
          );
        },
      ),
    );
  }
}
