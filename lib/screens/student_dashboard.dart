
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'student_lecturers_page.dart';
import 'student_available_consultations_page.dart';
import 'student_my_bookings_page.dart';
import 'student_notifications_page.dart';
import 'student_consultation_history_page.dart';
import 'student_profile_page.dart';

const Color primaryBlue = Color(0xFF2563EB);
const Color darkBlue = Color(0xFF172554);
const Color pageBackground = Color(0xFFF4F7FC);
const Color secondaryText = Color(0xFF64748B);
const Color borderColor = Color(0xFFE2E8F0);
const Color successGreen = Color(0xFF059669);
const Color warningOrange = Color(0xFFD97706);
const Color dangerRed = Color(0xFFDC2626);

// =============================================
// STUDENT NAVIGATION MODEL
// =============================================

class _StudentNavItem {
  final String title;
  final IconData icon;
  final String subtitle;

  const _StudentNavItem(
    this.title,
    this.icon,
    this.subtitle,
  );
}

const List<_StudentNavItem> _navItems = [
  _StudentNavItem(
    'Dashboard',
    Icons.dashboard_outlined,
    'Your consultation overview',
  ),
  _StudentNavItem(
    'Lecturers',
    Icons.people_outline_rounded,
    'Find your lecturers',
  ),
  _StudentNavItem(
    'Available Consultations',
    Icons.calendar_month_outlined,
    'Browse available time slots',
  ),
  _StudentNavItem(
    'My Bookings',
    Icons.event_note_outlined,
    'Manage your consultation requests',
  ),
  _StudentNavItem(
    'Calendar',
    Icons.calendar_today_outlined,
    'View your consultation schedule',
  ),
  _StudentNavItem(
    'Notifications',
    Icons.notifications_none_rounded,
    'Stay updated with booking activities',
  ),
  _StudentNavItem(
    'Consultation History',
    Icons.history_rounded,
    'Review previous consultations',
  ),
  _StudentNavItem(
    'My Profile',
    Icons.person_outline_rounded,
    'Manage your account information',
  ),
];

// =============================================
// SAMPLE APPOINTMENT MODEL
// =============================================

class _DemoAppointment {
  final String lecturer;
  final String subject;
  final DateTime date;
  final String dateLabel;
  final String time;
  final String status;

  const _DemoAppointment({
    required this.lecturer,
    required this.subject,
    required this.date,
    required this.dateLabel,
    required this.time,
    required this.status,
  });
}

// Temporary sample data for UI preview.
// Firestore integration will be implemented later.

final List<_DemoAppointment> _demoAppointments = [
  _DemoAppointment(
    lecturer: 'Dr. Aina Rahman',
    subject: 'Data Structures Consultation',
    date: DateTime(2026, 11, 10),
    dateLabel: '10 November 2026',
    time: '10:00 AM - 10:30 AM',
    status: 'Approved',
  ),
  _DemoAppointment(
    lecturer: 'Mr. Ahmad Hakim',
    subject: 'Programming Project Discussion',
    date: DateTime(2026, 11, 12),
    dateLabel: '12 November 2026',
    time: '02:00 PM - 02:30 PM',
    status: 'Pending',
  ),
];

// =============================================
// STUDENT DASHBOARD PAGE
// =============================================

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

  String? _selectedLecturerId;
  String? _selectedLecturerName;

  DateTime _focusedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  DateTime _selectedDate =
      DateUtils.dateOnly(DateTime.now());

  User? get _user => FirebaseAuth.instance.currentUser;

  String get _studentName {
    final displayName =
        _user?.displayName?.trim() ?? '';

    if (displayName.isNotEmpty) {
      return displayName;
    }

    final email = _user?.email ?? '';

    if (email.contains('@')) {
      return email.split('@').first;
    }

    return 'Student';
  }

  String get _studentEmail {
    return _user?.email ?? 'Student Account';
  }

  // =========================================
  // NAVIGATION FUNCTIONS
  // =========================================

  void _selectPage(
    int index, {
    bool closeDrawer = false,
  }) {
    setState(() {
      _selectedIndex = index;
    });

    if (closeDrawer) {
      Navigator.of(context).pop();
    }
  }

  // Open available slots based on selected lecturer.

  void _viewLecturerSlots(
    String? lecturerId,
    String? lecturerName,
  ) {
    setState(() {
      _selectedLecturerId = lecturerId;
      _selectedLecturerName = lecturerName;
      _selectedIndex = 2;
    });
  }

  // Clear lecturer filter.

  void _clearLecturerFilter() {
    setState(() {
      _selectedLecturerId = null;
      _selectedLecturerName = null;
    });
  }

  // =========================================
  // SIGN OUT
  // =========================================

  Future<void> _signOut() async {
    if (_signingOut) return;

    setState(() {
      _signingOut = true;
    });

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
        SnackBar(
          content: Text('Unable to sign out: $e'),
        ),
      );

      setState(() {
        _signingOut = false;
      });
    }
  }

  // =========================================
  // SHARED UI COMPONENTS
  // =========================================

  Widget _pageHeading(
    String title,
    String subtitle,
  ) {
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

  Widget _pageContent(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1350,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _sectionHeader(
    String title, {
    String? action,
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
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action),
            ),
        ],
      ),
    );
  }

  // =========================================
  // STATUS BADGE
  // =========================================

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();

    final color =
        normalized == 'approved' ||
                normalized == 'completed'
            ? successGreen
            : normalized == 'rejected' ||
                    normalized == 'cancelled'
                ? dangerRed
                : warningOrange;

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
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =========================================
  // SUMMARY STATISTICS CARD
  // =========================================

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: 235,
      child: Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 23,
                  ),
                ),

                Text(
                  value,
                  style: const TextStyle(
                    color: darkBlue,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 17),

            Text(
              title,
              style: const TextStyle(
                color: darkBlue,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              subtitle,
              style: const TextStyle(
                color: secondaryText,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================
  // APPOINTMENT CARD
  // =========================================

  Widget _appointmentCard(
    _DemoAppointment appointment,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: primaryBlue,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.lecturer,
                  style: const TextStyle(
                    color: darkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  appointment.subject,
                  style: const TextStyle(
                    color: secondaryText,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 9),

                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: secondaryText,
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        appointment.dateLabel,
                        style: const TextStyle(
                          color: secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: secondaryText,
                    ),

                    const SizedBox(width: 6),

                    Text(
                      appointment.time,
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _statusBadge(appointment.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // SIDEBAR
  // =========================================

  Widget _buildSidebar({
    required bool isDrawer,
  }) {
    return Container(
      width: isDrawer ? double.infinity : 260,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                22,
                24,
                16,
                22,
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.10),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: primaryBlue,
                      size: 27,
                    ),
                  ),

                  const SizedBox(width: 11),

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

            const Divider(
              height: 1,
              color: borderColor,
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(
                22,
                22,
                22,
                10,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'STUDENT MENU',
                  style: TextStyle(
                    color: secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];

                  final selected =
                      _selectedIndex == index;

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 6,
                    ),
                    child: Material(
                      color: selected
                          ? primaryBlue.withOpacity(0.10)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(12),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
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
                            color: selected
                                ? primaryBlue
                                : darkBlue,
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        selected: selected,
                        onTap: () {
                          _selectPage(
                            index,
                            closeDrawer: isDrawer,
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(
              height: 1,
              color: borderColor,
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 21,
                    backgroundColor: Color(0xFFDBEAFE),
                    child: Icon(
                      Icons.person_rounded,
                      color: primaryBlue,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _studentName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: darkBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),

                        Text(
                          _studentEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: secondaryText,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: 'Sign out',
                    onPressed:
                        _signingOut ? null : _signOut,
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: secondaryText,
                      size: 19,
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

  // =========================================
  // DASHBOARD WELCOME BANNER
  // =========================================

  Widget _welcomeBanner(String studentName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primaryBlue,
            darkBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'STUDENT PORTAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 17),

                Text(
                  'Welcome back, $studentName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Manage your academic consultations, '
                  'connect with lecturers and keep track '
                  'of your appointments in one place.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 22),

                FilledButton.icon(
                  onPressed: () => _selectPage(2),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Book a Consultation',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 19,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 15),

          Container(
            width: 105,
            height: 105,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 55,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // QUICK ACTION BUTTON
  // =========================================

  Widget _quickAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 7,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.09),
                borderRadius:
                    BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: primaryBlue,
                size: 20,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: darkBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: secondaryText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================
  // NOTIFICATION PREVIEW ITEM
  // =========================================

  Widget _notificationItem({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: color,
          size: 21,
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: darkBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                message,
                style: const TextStyle(
                  color: secondaryText,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                time,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================
  // HISTORY PREVIEW ITEM
  // =========================================

  Widget _historyItem({
    required String lecturer,
    required String subject,
    required String date,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: successGreen.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.history_rounded,
            color: successGreen,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                lecturer,
                style: const TextStyle(
                  color: darkBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subject,
                style: const TextStyle(
                  color: secondaryText,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                date,
                style: const TextStyle(
                  color: secondaryText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        const Icon(
          Icons.check_circle_rounded,
          color: successGreen,
          size: 20,
        ),
      ],
    );
  }

  // =========================================
  // STUDENT DASHBOARD PAGE
  // =========================================

  Widget _dashboardPage(String studentName) {
    return _pageContent(
      Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _pageHeading(
            'Student Dashboard',
            'Monitor your consultation activities '
            'and academic appointments.',
          ),

          _welcomeBanner(studentName),

          const SizedBox(height: 25),

          _sectionHeader('Consultation Overview'),

          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: [
              _statCard(
                title: 'Upcoming Consultations',
                value: '02',
                subtitle: 'Scheduled sessions',
                icon: Icons.calendar_month_rounded,
                color: primaryBlue,
              ),

              _statCard(
                title: 'Pending Requests',
                value: '01',
                subtitle: 'Awaiting lecturer response',
                icon: Icons.pending_actions_rounded,
                color: warningOrange,
              ),

              _statCard(
                title: 'Notifications',
                value: '03',
                subtitle: 'New updates',
                icon: Icons.notifications_active_outlined,
                color: const Color(0xFF7C3AED),
              ),

              _statCard(
                title: 'Completed Sessions',
                value: '08',
                subtitle: 'Previous consultations',
                icon: Icons.task_alt_rounded,
                color: successGreen,
              ),
            ],
          ),

          const SizedBox(height: 28),

          LayoutBuilder(
            builder: (context, constraints) {
              final mainContent = Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: borderColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(
                          'Upcoming Consultations',
                          action: 'View all',
                          onAction: () => _selectPage(3),
                        ),

                        ..._demoAppointments.map(
                          _appointmentCard,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: borderColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(
                          'Previous Consultation Records',
                          action: 'View history',
                          onAction: () => _selectPage(6),
                        ),

                        _historyItem(
                          lecturer: 'Dr. Sarah Abdullah',
                          subject: 'Database Management',
                          date: '28 October 2026',
                        ),

                        const Divider(height: 22),

                        _historyItem(
                          lecturer: 'Mr. Daniel Lee',
                          subject: 'Object Oriented Programming',
                          date: '20 October 2026',
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final sideContent = Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: borderColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('Quick Actions'),

                        _quickAction(
                          icon: Icons.search_rounded,
                          title: 'Find Lecturers',
                          subtitle: 'Browse lecturer profiles',
                          onTap: () => _selectPage(1),
                        ),

                        const Divider(height: 22),

                        _quickAction(
                          icon: Icons.calendar_month_rounded,
                          title: 'Available Slots',
                          subtitle: 'Explore consultation times',
                          onTap: () => _selectPage(2),
                        ),

                        const Divider(height: 22),

                        _quickAction(
                          icon: Icons.event_note_rounded,
                          title: 'My Bookings',
                          subtitle: 'View booking requests',
                          onTap: () => _selectPage(3),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(18),
                      border: Border.all(
                        color: borderColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(
                          'Recent Notifications',
                          action: 'View all',
                          onAction: () => _selectPage(5),
                        ),

                        _notificationItem(
                          icon: Icons.check_circle_outline,
                          color: successGreen,
                          title: 'Booking Approved',
                          message:
                              'Your consultation request has been approved.',
                          time: 'Today, 9:30 AM',
                        ),

                        const Divider(height: 22),

                        _notificationItem(
                          icon: Icons.event_note_outlined,
                          color: primaryBlue,
                          title: 'Booking Reminder',
                          message:
                              'You have an upcoming consultation session.',
                          time: 'Yesterday',
                        ),

                        const Divider(height: 22),

                        _notificationItem(
                          icon: Icons.notifications_active_outlined,
                          color: warningOrange,
                          title: 'New Update',
                          message:
                              'A lecturer has updated their availability.',
                          time: '2 days ago',
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (constraints.maxWidth >= 950) {
                return Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: mainContent,
                    ),

                    const SizedBox(width: 20),

                    Expanded(
                      flex: 2,
                      child: sideContent,
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  mainContent,
                  const SizedBox(height: 22),
                  sideContent,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================
  // CALENDAR LEGEND
  // =========================================

  Widget _calendarLegend(
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

        const SizedBox(width: 7),

        Text(
          label,
          style: const TextStyle(
            color: secondaryText,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // =========================================
  // STUDENT CALENDAR PAGE
  // =========================================

  Widget _calendarPage() {
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

    final selectedAppointments =
        _demoAppointments.where((item) {
      return DateUtils.isSameDay(
        item.date,
        _selectedDate,
      );
    }).toList();

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

    return _pageContent(
      Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _pageHeading(
            'My Calendar',
            'View your consultation dates and appointments.',
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
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

                          _selectedDate = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month,
                            1,
                          );
                        });
                      },
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                      ),
                    ),

                    IconButton(
                      tooltip: 'Next month',
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month + 1,
                          );

                          _selectedDate = DateTime(
                            _focusedMonth.year,
                            _focusedMonth.month,
                            1,
                          );
                        });
                      },
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    for (final day in [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ])
                      Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              color: secondaryText,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                GridView.builder(
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  itemCount: cellCount,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 0.95,
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
                        DateUtils.isSameDay(
                      date,
                      _selectedDate,
                    );

                    final today =
                        DateUtils.isSameDay(
                      date,
                      DateTime.now(),
                    );

                    final hasAppointment =
                        _demoAppointments.any((item) {
                      return DateUtils.isSameDay(
                        item.date,
                        date,
                      );
                    });

                    return InkWell(
                      borderRadius:
                          BorderRadius.circular(11),
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: selected
                              ? primaryBlue
                              : today
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(11),
                          border: today && !selected
                              ? Border.all(
                                  color: primaryBlue,
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : darkBlue,
                                fontSize: 12,
                                fontWeight: selected || today
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 4),

                            if (hasAppointment)
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? Colors.white
                                      : successGreen,
                                  shape: BoxShape.circle,
                                ),
                              )
                            else
                              const SizedBox(height: 5),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 15),

                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  children: [
                    _calendarLegend(
                      primaryBlue,
                      'Selected date',
                    ),
                    _calendarLegend(
                      successGreen,
                      'Has consultation',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _sectionHeader(
            'Consultations on '
            '${_selectedDate.day} '
            '${months[_selectedDate.month - 1]} '
            '${_selectedDate.year}',
          ),

          if (selectedAppointments.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    color: secondaryText,
                    size: 38,
                  ),

                  SizedBox(height: 12),

                  Text(
                    'No consultations on this date',
                    style: TextStyle(
                      color: darkBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(
                    'Select another date to view your consultation schedule.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            ...selectedAppointments.map(_appointmentCard),
        ],
      ),
    );
  }

  // =========================================
  // STUDENT MODULE PAGE ROUTER
  // =========================================

  Widget _buildCurrentPage(
    User user,
    Map<String, dynamic> profile,
    String studentName,
  ) {
    switch (_selectedIndex) {
      case 0:
        return _dashboardPage(studentName);

      case 1:
        return StudentLecturersPage(
          onViewSlots: _viewLecturerSlots,
        );

      case 2:
        return StudentAvailableConsultationsPage(
          lecturerId: _selectedLecturerId,
          lecturerName: _selectedLecturerName,
          onClearLecturerFilter: _clearLecturerFilter,
        );

      case 3:
        return const StudentMyBookingsPage();

      case 4:
        return _calendarPage();

      case 5:
        return const StudentNotificationsPage();

      case 6:
        return const StudentConsultationHistoryPage();

      case 7:
        return StudentProfilePage(
          user: user,
          profile: profile,
          onSignOut: _signOut,
          isSigningOut: _signingOut,
        );

      default:
        return _dashboardPage(studentName);
    }
  }

  // =========================================
  // MAIN BUILD
  // =========================================

  @override
  Widget build(BuildContext context) {
    final user = _user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: pageBackground,
        body: Center(
          child: Text(
            'Please sign in to access the Student Dashboard.',
          ),
        ),
      );
    }

    // Temporary profile data for the UI stage.
    // Firestore profile editing will be connected later.

    final profile = <String, dynamic>{
      'uid': user.uid,
      'fullName': user.displayName ?? _studentName,
      'email': user.email ?? '',
      'role': 'Student',
      'createdAt': user.metadata.creationTime,
    };

    final name =
        (profile['fullName'] as String?)?.trim() ?? '';

    final studentName =
        name.isNotEmpty ? name : _studentName;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= 1000;

        // Mobile navigation destinations.
        const mobileNavIndexes = [
          0,
          2,
          3,
          5,
          7,
        ];

        final mobileSelectedIndex =
            mobileNavIndexes.indexOf(_selectedIndex);

        return Scaffold(
          backgroundColor: pageBackground,

          drawer: isDesktop
              ? null
              : Drawer(
                  child: _buildSidebar(
                    isDrawer: true,
                  ),
                ),

          // APP BAR
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: darkBlue,
            elevation: 0,

            title: Text(
              _navItems[_selectedIndex].title,
              style: const TextStyle(
                color: darkBlue,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            actions: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => _selectPage(5),
                icon: const Icon(
                  Icons.notifications_none_rounded,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(
                  right: 16,
                ),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFFDBEAFE),
                  child: Text(
                    studentName.isNotEmpty
                        ? studentName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // MAIN BODY
          body: Row(
            children: [
              if (isDesktop)
                _buildSidebar(
                  isDrawer: false,
                ),

              Expanded(
                child: _buildCurrentPage(
                  user,
                  profile,
                  studentName,
                ),
              ),
            ],
          ),

          // MOBILE BOTTOM NAVIGATION
          bottomNavigationBar: isDesktop
              ? null
              : NavigationBar(
                  backgroundColor: Colors.white,

                  selectedIndex:
                      mobileSelectedIndex < 0
                          ? 0
                          : mobileSelectedIndex,

                  indicatorColor:
                      primaryBlue.withOpacity(0.12),

                  labelBehavior:
                      NavigationDestinationLabelBehavior
                          .alwaysShow,

                  onDestinationSelected: (index) {
                    _selectPage(
                      mobileNavIndexes[index],
                    );
                  },

                  destinations: const [
                    NavigationDestination(
                      icon: Icon(
                        Icons.dashboard_outlined,
                      ),
                      selectedIcon: Icon(
                        Icons.dashboard_rounded,
                      ),
                      label: 'Home',
                    ),

                    NavigationDestination(
                      icon: Icon(
                        Icons.calendar_month_outlined,
                      ),
                      selectedIcon: Icon(
                        Icons.calendar_month_rounded,
                      ),
                      label: 'Slots',
                    ),

                    NavigationDestination(
                      icon: Icon(
                        Icons.event_note_outlined,
                      ),
                      selectedIcon: Icon(
                        Icons.event_note_rounded,
                      ),
                      label: 'Bookings',
                    ),

                    NavigationDestination(
                      icon: Icon(
                        Icons.notifications_none_rounded,
                      ),
                      selectedIcon: Icon(
                        Icons.notifications_rounded,
                      ),
                      label: 'Alerts',
                    ),

                    NavigationDestination(
                      icon: Icon(
                        Icons.person_outline_rounded,
                      ),
                      selectedIcon: Icon(
                        Icons.person_rounded,
                      ),
                      label: 'Profile',
                    ),
                  ],
                ),
        );
      },
    );
  }
}
