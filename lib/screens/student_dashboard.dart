
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'report_management_page.dart';

const Color primaryBlue = Color(0xFF2563EB);
const Color darkBlue = Color(0xFF172554);
const Color pageBackground = Color(0xFFF4F7FC);
const Color secondaryText = Color(0xFF64748B);

class _StudentNavItem {
  final String title;
  final IconData icon;

  const _StudentNavItem(this.title, this.icon);
}

const List<_StudentNavItem> _navItems = [
  _StudentNavItem('Dashboard', Icons.dashboard_outlined),
  _StudentNavItem('Calendar', Icons.calendar_month_outlined),
  _StudentNavItem('Lecturers', Icons.people_outline_rounded),
  _StudentNavItem('My Bookings', Icons.event_note_outlined),
  _StudentNavItem('Profile', Icons.person_outline_rounded),
  // NEW: Reports & Analytics is available to Student accounts.
  _StudentNavItem('Reports', Icons.assessment_outlined),
];

DateTime? _toDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;

  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}

DateTime? _bookingDate(Map<String, dynamic> data) {
  for (final key in [
    'startAt',
    'bookingDate',
    'consultationDate',
    'date',
  ]) {
    final value = _toDateTime(data[key]);

    if (value != null) return value;
  }

  // Support separate date and time strings if present.
  final date = data['bookingDate'] ?? data['date'];
  final time = data['bookingTime'] ?? data['startTime'];

  if (date is String && time is String) {
    return DateTime.tryParse('${date.trim()} ${time.trim()}');
  }

  return null;
}

bool _isActiveBooking(Map<String, dynamic> data) {
  final status = (data['bookingStatus'] ??
          data['status'] ??
          'Pending')
      .toString()
      .toLowerCase()
      .trim();

  return ![
    'completed',
    'done',
    'cancelled',
    'canceled',
    'rejected',
  ].contains(status);
}

String _displayName(Map<String, dynamic> data) {
  return (data['lecturerName'] ??
          data['lecturerFullName'] ??
          data['lecturer'] ??
          'Lecturer')
      .toString();
}

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() =>
      _StudentDashboardPageState();
}

class _StudentDashboardPageState
    extends State<StudentDashboardPage> {
  int _selectedIndex = 0;
  bool _signingOut = false;

  DateTime _focusedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  String? _cachedUid;

  Stream<QuerySnapshot<Map<String, dynamic>>>? _cachedBookings;

  // Booking documents are expected in:
  // bookings/{bookingId}
  // with studentId equal to the signed-in Firebase UID.
  Stream<QuerySnapshot<Map<String, dynamic>>> _bookingStream(
    String uid,
  ) {
    if (_cachedBookings == null || _cachedUid != uid) {
      _cachedUid = uid;

      _cachedBookings = FirebaseFirestore.instance
          .collection('bookings')
          .where('studentId', isEqualTo: uid)
          .snapshots();
    }

    return _cachedBookings!;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> get _availabilityStream {
    return FirebaseFirestore.instance
        .collection('availability')
        .where('status', isEqualTo: 'available')
        .snapshots();
  }

  Future<void> _signOut() async {
    if (_signingOut) return;

    setState(() => _signingOut = true);

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to sign out: $e')),
      );

      setState(() => _signingOut = false);
    }
  }

  void _openBookingPage() {
    Navigator.of(context).pushNamed('/available-consultations');
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _activeBookings(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final result = docs
        .where((doc) => _isActiveBooking(doc.data()))
        .toList();

    result.sort((a, b) {
      final aDate = _bookingDate(a.data()) ??
          DateTime(9999);

      final bDate = _bookingDate(b.data()) ??
          DateTime(9999);

      return aDate.compareTo(bDate);
    });

    return result;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _futureSlots(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final now = DateTime.now();

    final result = docs.where((doc) {
      final data = doc.data();
      final start = _toDateTime(data['startAt']);

      return data['status'] == 'available' &&
          (start == null || start.isAfter(now));
    }).toList();

    result.sort((a, b) {
      final aDate = _toDateTime(a.data()['startAt']) ??
          DateTime(9999);

      final bDate = _toDateTime(b.data()['startAt']) ??
          DateTime(9999);

      return aDate.compareTo(bDate);
    });

    return result;
  }

  String _dateText(DateTime? date) {
    if (date == null) return 'Date not set';

    return MaterialLocalizations.of(context)
        .formatMediumDate(date);
  }

  String _timeText(Map<String, dynamic> data) {
    final start = _toDateTime(data['startAt']) ??
        _toDateTime(data['bookingDate']) ??
        _toDateTime(data['consultationDate']);

    final end = _toDateTime(data['endAt']);

    if (start != null) {
      final startText = MaterialLocalizations.of(context)
          .formatTimeOfDay(TimeOfDay.fromDateTime(start));

      if (end != null) {
        final endText = MaterialLocalizations.of(context)
            .formatTimeOfDay(TimeOfDay.fromDateTime(end));

        return '$startText - $endText';
      }

      return startText;
    }

    final time = data['bookingTime'] ??
        data['startTime'] ??
        data['time'];

    return time?.toString() ?? 'Time not set';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF059669);

      case 'rejected':
      case 'cancelled':
      case 'canceled':
        return const Color(0xFFDC2626);

      case 'completed':
        return const Color(0xFF64748B);

      default:
        return const Color(0xFFD97706);
    }
  }

  Widget _pageHeading(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: darkBlue,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: const TextStyle(
              color: secondaryText,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageContent(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
    String title, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: darkBlue,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String description,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: darkBlue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: secondaryText,
              height: 1.5,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action,
          ],
        ],
      ),
    );
  }

  Widget _errorCard({Object? error}) {
  return _emptyCard(
    icon: Icons.cloud_off_outlined,
    title: 'Unable to load data',
    description: error == null
        ? 'Please check your Firestore Rules and connection.'
        : error.toString(),
    action: TextButton.icon(
      onPressed: () => setState(() {}),
      icon: const Icon(Icons.refresh),
      label: const Text('Refresh'),
    ),
  );
}

  Widget _bookingCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final lecturer = _displayName(data);

    final purpose = (data['consultationPurpose'] ??
            data['purpose'] ??
            '')
        .toString();

    final status = (data['bookingStatus'] ??
            data['status'] ??
            'Pending')
        .toString();

    final date = _bookingDate(data);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: primaryBlue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecturer,
                    style: const TextStyle(
                      color: darkBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_dateText(date)} • ${_timeText(data)}',
                    style: const TextStyle(
                      color: secondaryText,
                      fontSize: 13,
                    ),
                  ),
                  if (purpose.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      purpose,
                      style: const TextStyle(
                        color: secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status)
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _statusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _availabilityCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final lecturer = _displayName(data);
    final start = _toDateTime(data['startAt']);
    final end = _toDateTime(data['endAt']);

    final dateText = _dateText(start);

    final timeText = start == null
        ? 'Time not set'
        : _timeText({
            'startAt': start,
            'endAt': end,
          });

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF059669).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.school_outlined,
            color: Color(0xFF059669),
          ),
        ),
        title: Text(
          lecturer,
          style: const TextStyle(
            color: darkBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Text('$dateText • $timeText'),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: secondaryText,
        ),
        onTap: _openBookingPage,
      ),
    );
  }

  Widget _buildSidebar(User user, String studentName) {
    return Container(
      width: 245,
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 16, 22),
            child: Row(
              children: [
                const Icon(
                  Icons.school_rounded,
                  color: primaryBlue,
                  size: 30,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ConsultEasy',
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final selected = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Material(
                    color: selected
                        ? primaryBlue.withValues(alpha: 0.10)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        item.icon,
                        color: selected
                            ? primaryBlue
                            : secondaryText,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: selected ? primaryBlue : darkBlue,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        setState(() => _selectedIndex = index);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFDBEAFE),
                  child: Icon(
                    Icons.person_outline,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(User user, String studentName) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _bookingStream(user.uid),
      builder: (context, bookingSnapshot) {
        if (bookingSnapshot.hasError) {
          return _pageContent([
            _pageHeading(
              'Student Dashboard',
              'Manage your academic consultations.',
            ),
            _errorCard(),
          ]);
        }

        final bookings = _activeBookings(
          bookingSnapshot.data?.docs ?? [],
        );

        final now = DateTime.now();

        final upcoming = bookings.where((doc) {
          final date = _bookingDate(doc.data());

          return date == null || !date.isBefore(
            DateTime(now.year, now.month, now.day),
          );
        }).take(3).toList();

        return StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: _availabilityStream,
          builder: (context, availabilitySnapshot) {
            final slots = _futureSlots(
              availabilitySnapshot.data?.docs ?? [],
            ).take(3).toList();

            return _pageContent([
              // Welcome banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, darkBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.waving_hand_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Welcome back, $studentName!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Plan your consultations, check lecturer '
                      'availability and keep track of your bookings.',
                      style: TextStyle(
                        color: Colors.white,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _openBookingPage,
                      icon: const Icon(Icons.add),
                      label: const Text('Book a Consultation'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              _sectionHeader(
                'My Upcoming Consultations',
                actionLabel: 'View all',
                onAction: () {
                  setState(() => _selectedIndex = 3);
                },
              ),

              if (bookingSnapshot.connectionState ==
                      ConnectionState.waiting &&
                  bookingSnapshot.data == null)
                const Center(child: CircularProgressIndicator())
              else if (upcoming.isEmpty)
                _emptyCard(
                  icon: Icons.calendar_today_outlined,
                  title: 'No upcoming consultations',
                  description:
                      'Your bookings will appear here after you '
                      'request a consultation.',
                  action: OutlinedButton.icon(
                    onPressed: _openBookingPage,
                    icon: const Icon(Icons.search),
                    label: const Text('Find Available Slots'),
                  ),
                )
              else
                ...upcoming.map(_bookingCard),

              const SizedBox(height: 22),

              _sectionHeader(
                'Available Consultation Slots',
                actionLabel: 'Explore all',
                onAction: () {
                  setState(() => _selectedIndex = 2);
                },
              ),

              if (availabilitySnapshot.hasError)
                _errorCard(error: availabilitySnapshot.error)
              else if (availabilitySnapshot.connectionState ==
                      ConnectionState.waiting &&
                  availabilitySnapshot.data == null)
                const Center(child: CircularProgressIndicator())
              else if (slots.isEmpty)
                _emptyCard(
                  icon: Icons.event_busy_outlined,
                  title: 'No available slots',
                  description:
                      'There are currently no upcoming consultation '
                      'slots available.',
                  action: TextButton.icon(
                    onPressed: () {
                      setState(() => _selectedIndex = 2);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check lecturers'),
                  ),
                )
              else
                ...slots.map(_availabilityCard),
            ]);
          },
        );
      },
    );
  }

  Widget _buildCalendar(User user) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _bookingStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _pageContent([
            _pageHeading(
              'My Calendar',
              'View your scheduled consultations.',
            ),
            _errorCard(error: snapshot.error),
          ]);
        }

        final bookings = _activeBookings(
          snapshot.data?.docs ?? [],
        );

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

        final leadingDays = firstDay.weekday - 1;

        final cellCount =
            ((leadingDays + daysInMonth + 6) ~/ 7) * 7;

        final selectedBookings = bookings.where((doc) {
          final date = _bookingDate(doc.data());

          return date != null &&
              DateUtils.isSameDay(date, _selectedDate);
        }).toList();

        const months = [
          'January', 'February', 'March', 'April',
          'May', 'June', 'July', 'August',
          'September', 'October', 'November', 'December',
        ];

        return _pageContent([
          _pageHeading(
            'My Calendar',
            'See your consultation dates and appointments.',
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${months[_focusedMonth.month - 1]} '
                        '${_focusedMonth.year}',
                        style: const TextStyle(
                          color: darkBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Previous month',
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month - 1,
                          );
                        });
                      },
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      tooltip: 'Next month',
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month + 1,
                          );
                        });
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    for (final day in [
                      'Mon', 'Tue', 'Wed', 'Thu',
                      'Fri', 'Sat', 'Sun',
                    ])
                      Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              color: secondaryText,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cellCount,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.9,
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

                    final selected =
                        DateUtils.isSameDay(date, _selectedDate);

                    final hasBooking = bookings.any((doc) {
                      final bookingDate =
                          _bookingDate(doc.data());

                      return bookingDate != null &&
                          DateUtils.isSameDay(
                            bookingDate,
                            date,
                          );
                    });

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() => _selectedDate = date);
                      },
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: selected
                              ? primaryBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : darkBlue,
                                fontWeight: selected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasBooking
                                    ? (selected
                                        ? Colors.white
                                        : primaryBlue)
                                    : Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                const Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: primaryBlue,
                      size: 9,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Consultation booking',
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          _sectionHeader(
            'Appointments on ${_dateText(_selectedDate)}',
          ),

          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null)
            const Center(child: CircularProgressIndicator())
          else if (selectedBookings.isEmpty)
            _emptyCard(
              icon: Icons.event_available_outlined,
              title: 'No bookings on this date',
              description:
                  'Select another date or find an available '
                  'lecturer consultation slot.',
              action: OutlinedButton.icon(
                onPressed: _openBookingPage,
                icon: const Icon(Icons.search),
                label: const Text('Find Consultation'),
              ),
            )
          else
            ...selectedBookings.map(_bookingCard),
        ]);
      },
    );
  }

  Widget _buildLecturers() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _availabilityStream,
      builder: (context, snapshot) {
        final slots = _futureSlots(
          snapshot.data?.docs ?? [],
        );

        return _pageContent([
          _pageHeading(
            'Lecturers & Availability',
            'Browse available consultation sessions before booking.',
          ),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openBookingPage,
              icon: const Icon(Icons.search),
              label: const Text('Open Booking Page'),
              style: FilledButton.styleFrom(
                backgroundColor: primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 17),
              ),
            ),
          ),

          const SizedBox(height: 24),

          _sectionHeader(
            'Available Consultation Slots',
          ),

          if (snapshot.hasError)
            _errorCard()
          else if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              snapshot.data == null)
            const Center(child: CircularProgressIndicator())
          else if (slots.isEmpty)
            _emptyCard(
              icon: Icons.event_busy_outlined,
              title: 'No available slots',
              description:
                  'Lecturers have not published any upcoming '
                  'consultation slots yet.',
            )
          else
            ...slots.map(_availabilityCard),

          const SizedBox(height: 28),

          _sectionHeader('Lecturer Timetables'),

          _emptyCard(
            icon: Icons.calendar_view_week_outlined,
            title: 'Lecturer class timetables',
            description:
                'This section will display lecturers’ class schedules '
                'after timetable management is connected. Consultation '
                'availability is shown above.',
          ),
        ]);
      },
    );
  }

  Widget _buildMyBookings(User user) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _bookingStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _pageContent([
            _pageHeading(
              'My Bookings',
              'Track the status of your consultation requests.',
            ),
            _errorCard(),
          ]);
        }

        final bookings = _activeBookings(
          snapshot.data?.docs ?? [],
        );

        return _pageContent([
          _pageHeading(
            'My Bookings',
            'View your upcoming consultations and booking status.',
          ),

          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              snapshot.data == null)
            const Center(child: CircularProgressIndicator())
          else if (bookings.isEmpty)
            _emptyCard(
              icon: Icons.event_note_outlined,
              title: 'No bookings yet',
              description:
                  'Your consultation requests will appear here '
                  'after you book an available slot.',
              action: FilledButton.icon(
                onPressed: _openBookingPage,
                icon: const Icon(Icons.add),
                label: const Text('Book Consultation'),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryBlue,
                ),
              ),
            )
          else
            ...bookings.map(_bookingCard),
        ]);
      },
    );
  }

  Widget _buildProfile(
    User user,
    Map<String, dynamic> profile,
  ) {
    final name = (profile['fullName'] as String?) ??
        user.displayName ??
        'Student';

    final email = (profile['email'] as String?) ??
        user.email ??
        '';

    return _pageContent([
      _pageHeading(
        'My Profile',
        'View your ConsultEasy account information.',
      ),

      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 42,
              backgroundColor: Color(0xFFDBEAFE),
              child: Icon(
                Icons.person_rounded,
                size: 44,
                color: primaryBlue,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: darkBlue,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(color: secondaryText),
            ),

            const SizedBox(height: 22),

            const Divider(),

            ListTile(
              leading: const Icon(
                Icons.school_outlined,
                color: primaryBlue,
              ),
              title: const Text('Account type'),
              subtitle: const Text('Student'),
            ),

            ListTile(
              leading: const Icon(
                Icons.verified_user_outlined,
                color: primaryBlue,
              ),
              title: const Text('Authentication'),
              subtitle: const Text('Firebase Authentication'),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signingOut ? null : _signOut,
                icon: const Icon(Icons.logout_rounded),
                label: Text(
                  _signingOut ? 'Signing out...' : 'Sign Out',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildCurrentPage(
    User user,
    Map<String, dynamic> profile,
  ) {
    final studentName =
        (profile['fullName'] as String?) ??
            user.displayName ??
            'Student';

    switch (_selectedIndex) {
      case 0:
        return _buildDashboard(user, studentName);

      case 1:
        return _buildCalendar(user);

      case 2:
        return _buildLecturers();

      case 3:
        return _buildMyBookings(user);

      case 4:
        return _buildProfile(user, profile);

      // NEW: Open the role-filtered reporting module.
      case 5:
        return const ReportManagementPage(showAppBar: false);

      default:
        return _buildDashboard(user, studentName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: pageBackground,
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            child: const Text('Please sign in again'),
          ),
        ),
      );
    }

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data?.data() ?? {};

        final studentName =
            (profile['fullName'] as String?) ??
                user.displayName ??
                'Student';

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            return Scaffold(
              backgroundColor: pageBackground,

              appBar: AppBar(
                backgroundColor: Colors.white,
                foregroundColor: darkBlue,
                elevation: 0,
                title: Text(
                  isDesktop
                      ? _navItems[_selectedIndex].title
                      : 'ConsultEasy',
                  style: const TextStyle(
                    color: darkBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: _signingOut ? null : _signOut,
                    icon: _signingOut
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.logout_rounded),
                  ),
                  const SizedBox(width: 12),
                ],
              ),

              body: Row(
                children: [
                  if (isDesktop)
                    _buildSidebar(user, studentName),

                  Expanded(
                    child: _buildCurrentPage(user, profile),
                  ),
                ],
              ),

              bottomNavigationBar: isDesktop
                  ? null
                  : NavigationBar(
                      backgroundColor: Colors.white,
                      selectedIndex: _selectedIndex,
                      indicatorColor:
                          primaryBlue.withValues(alpha: 0.12),
                      labelBehavior:
                          NavigationDestinationLabelBehavior
                              .alwaysShow,
                      onDestinationSelected: (index) {
                        setState(() => _selectedIndex = index);
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard_rounded),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.calendar_month_outlined),
                          selectedIcon:
                              Icon(Icons.calendar_month_rounded),
                          label: 'Calendar',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.people_outline_rounded),
                          selectedIcon: Icon(Icons.people_rounded),
                          label: 'Lecturers',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.event_note_outlined),
                          selectedIcon: Icon(Icons.event_note_rounded),
                          label: 'Bookings',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_outline_rounded),
                          selectedIcon: Icon(Icons.person_rounded),
                          label: 'Profile',
                        ),
                        // NEW: Reports tab for mobile Student navigation.
                        NavigationDestination(
                          icon: Icon(Icons.assessment_outlined),
                          selectedIcon: Icon(Icons.assessment_rounded),
                          label: 'Reports',
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}
