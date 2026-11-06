
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =====================================================
// PAGE IMPORTS
// =====================================================

import 'lecturer_booking_requests.dart';
import 'lecturer_calendar.dart';

// =====================================================
// CONSULTEASY DESIGN SYSTEM
// =====================================================

const Color lecturerBlue = Color(0xFF2563EB);
const Color lecturerDarkBlue = Color(0xFF172554);
const Color lecturerBackground = Color(0xFFF4F7FC);
const Color lecturerSecondaryText = Color(0xFF64748B);
const Color lecturerBorder = Color(0xFFE2E8F0);

// =====================================================
// LECTURER DASHBOARD PAGE
// =====================================================

class LecturerDashboardPage extends StatefulWidget {
  const LecturerDashboardPage({super.key});

  @override
  State<LecturerDashboardPage> createState() =>
      _LecturerDashboardPageState();
}

class _LecturerDashboardPageState
    extends State<LecturerDashboardPage> {

  // ===================================================
  // 1. NAVIGATION STATE
  // ===================================================

  int _selectedIndex = 0;

  bool _signingOut = false;

  bool _openingBookingRequests = false;

  bool _openingCalendar = false;

  // Navigation indexes:
  // 0 = Dashboard
  // 1 = Availability
  // 2 = Booking Requests
  // 3 = Calendar
  // 4 = Profile

  // ===================================================
  // 2. SIGN OUT
  // ===================================================

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
          backgroundColor: Colors.red.shade700,
        ),
      );

      setState(() {
        _signingOut = false;
      });
    }
  }

  // ===================================================
  // 3. NAVIGATION INTEGRATION
  // ===================================================

  Future<void> _onNavigationSelected(int index) async {

    // -------------------------------------------------
    // DASHBOARD
    // -------------------------------------------------

    if (index == 0) {

      setState(() {
        _selectedIndex = 0;
      });

      return;
    }

    // -------------------------------------------------
    // MANAGE AVAILABILITY
    // -------------------------------------------------

    if (index == 1) {

      setState(() {
        _selectedIndex = 1;
      });

      try {

        await Navigator.of(context).pushNamed(
          '/manage-availability',
        );

      } finally {

        if (mounted) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      }

      return;
    }

    // -------------------------------------------------
    // BOOKING REQUESTS
    // -------------------------------------------------

    if (index == 2) {

      if (_openingBookingRequests) return;

      setState(() {
        _selectedIndex = 2;
        _openingBookingRequests = true;
      });

      try {

        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) =>
                const LecturerBookingRequestsPage(),
          ),
        );

      } finally {

        if (mounted) {

          setState(() {
            _selectedIndex = 0;
            _openingBookingRequests = false;
          });
        }
      }

      return;
    }

    // -------------------------------------------------
    // LECTURER CALENDAR
    // -------------------------------------------------

    if (index == 3) {

      if (_openingCalendar) return;

      setState(() {
        _selectedIndex = 3;
        _openingCalendar = true;
      });

      try {

        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) =>
                const LecturerCalendarPage(),
          ),
        );

      } finally {

        if (mounted) {

          setState(() {
            _selectedIndex = 0;
            _openingCalendar = false;
          });
        }
      }

      return;
    }

    // -------------------------------------------------
    // MY PROFILE
    // -------------------------------------------------

    if (index == 4) {

      setState(() {
        _selectedIndex = 4;
      });

      return;
    }
  }

  // ===================================================
  // 4. MAIN BUILD
  // ===================================================

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    // AUTHENTICATION CHECK

    if (user == null) {

      return Scaffold(
        backgroundColor: lecturerBackground,

        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: lecturerBlue,
              ),

              const SizedBox(height: 16),

              const Text(
                'Please sign in again.',
              ),

              const SizedBox(height: 12),

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
      );
    }

    // MAIN SCAFFOLD

    return Scaffold(
      backgroundColor: lecturerBackground,

      // ===============================================
      // APP BAR
      // ===============================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: lecturerDarkBlue,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,

        title: const Row(
          children: [

            Icon(
              Icons.school_rounded,
              color: lecturerBlue,
              size: 29,
            ),

            SizedBox(width: 10),

            Text(
              'ConsultEasy',

              style: TextStyle(
                color: lecturerDarkBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        actions: [

          IconButton(
            tooltip: 'Sign out',

            onPressed: _signingOut ? null : _signOut,

            icon: _signingOut
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.logout_rounded,
                  ),
          ),

          const SizedBox(width: 12),
        ],
      ),

      // ===============================================
      // RESPONSIVE BODY
      // ===============================================

      body: LayoutBuilder(
        builder: (context, constraints) {

          final isWide = constraints.maxWidth >= 850;

          if (isWide) {

            return Row(
              children: [

                _buildSideNavigation(),

                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: lecturerBorder,
                ),

                Expanded(
                  child: _buildSelectedPage(user),
                ),
              ],
            );
          }

          return _buildSelectedPage(user);
        },
      ),

      // ===============================================
      // MOBILE BOTTOM NAVIGATION
      // UPDATED: ADDED CALENDAR
      // ===============================================

      bottomNavigationBar:
          MediaQuery.sizeOf(context).width < 850
              ? NavigationBar(
                  backgroundColor: Colors.white,

                  selectedIndex: _selectedIndex,

                  onDestinationSelected:
                      _onNavigationSelected,

                  destinations: const [

                    // 0. DASHBOARD

                    NavigationDestination(
                      icon: Icon(
                        Icons.dashboard_outlined,
                      ),

                      selectedIcon: Icon(
                        Icons.dashboard_rounded,
                      ),

                      label: 'Home',
                    ),

                    // 1. AVAILABILITY

                    NavigationDestination(
                      icon: Icon(
                        Icons.calendar_month_outlined,
                      ),

                      selectedIcon: Icon(
                        Icons.calendar_month_rounded,
                      ),

                      label: 'Availability',
                    ),

                    // 2. BOOKING REQUESTS

                    NavigationDestination(
                      icon: Icon(
                        Icons.event_note_outlined,
                      ),

                      selectedIcon: Icon(
                        Icons.event_note_rounded,
                      ),

                      label: 'Bookings',
                    ),

                    // 3. CALENDAR

                    NavigationDestination(
                      icon: Icon(
                        Icons.event_available_outlined,
                      ),

                      selectedIcon: Icon(
                        Icons.event_available_rounded,
                      ),

                      label: 'Calendar',
                    ),

                    // 4. PROFILE

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
                )
              : null,
    );
  }

  // ===================================================
  // 5. DESKTOP SIDE NAVIGATION
  // UPDATED: ADDED CALENDAR
  // ===================================================

  Widget _buildSideNavigation() {

    return Container(
      width: 225,
      color: Colors.white,

      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                24,
                16,
                18,
              ),

              child: Text(
                'LECTURER MENU',

                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: lecturerSecondaryText,
                ),
              ),
            ),

            // DASHBOARD

            _sideNavItem(
              index: 0,
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
            ),

            // AVAILABILITY

            _sideNavItem(
              index: 1,
              icon: Icons.calendar_month_outlined,
              label: 'Availability',
            ),

            // BOOKING REQUESTS

            _sideNavItem(
              index: 2,
              icon: Icons.event_note_outlined,
              label: 'Booking Requests',
            ),

            // CALENDAR - NEW

            _sideNavItem(
              index: 3,
              icon: Icons.event_available_outlined,
              label: 'My Calendar',
            ),

            // PROFILE - INDEX UPDATED

            _sideNavItem(
              index: 4,
              icon: Icons.person_outline_rounded,
              label: 'My Profile',
            ),

            const Spacer(),

            const Divider(
              color: lecturerBorder,
            ),

            Padding(
              padding: const EdgeInsets.all(16),

              child: Text(
                'ConsultEasy\nAcademic Consultation System',

                style: TextStyle(
                  fontSize: 11,
                  height: 1.6,
                  color: Colors.blueGrey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================
  // 6. SIDE NAVIGATION ITEM
  // ===================================================

  Widget _sideNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {

    final selected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),

      child: Material(
        color: selected
            ? const Color(0xFFEFF6FF)
            : Colors.transparent,

        borderRadius: BorderRadius.circular(12),

        child: InkWell(
          borderRadius: BorderRadius.circular(12),

          onTap: () => _onNavigationSelected(index),

          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),

            child: Row(
              children: [

                Icon(
                  icon,
                  size: 21,

                  color: selected
                      ? lecturerBlue
                      : lecturerSecondaryText,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    label,

                    style: TextStyle(
                      fontSize: 13,

                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.w500,

                      color: selected
                          ? lecturerBlue
                          : lecturerDarkBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================================================
  // 7. PAGE SELECTION
  // UPDATED: CALENDAR INDEX 3, PROFILE INDEX 4
  // ===================================================

  Widget _buildSelectedPage(User user) {

    switch (_selectedIndex) {

      // BOOKING REQUESTS
      // Opens as a separate route.

      case 2:
        return const SizedBox.shrink();

      // CALENDAR
      // Opens as a separate route.

      case 3:
        return const SizedBox.shrink();

      // PROFILE

      case 4:
        return _buildProfilePage(user);

      // AVAILABILITY
      // Opens as a separate route.

      case 1:
        return const Center(
          child: CircularProgressIndicator(
            color: lecturerBlue,
          ),
        );

      // DASHBOARD

      default:
        return _buildDashboard(user);
    }
  }

  // ===================================================
  // 8. MAIN DASHBOARD
  // ===================================================

  Widget _buildDashboard(User user) {

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),

      builder: (context, profileSnapshot) {

        if (profileSnapshot.hasError) {

          return _errorView(
            'Unable to load your profile.',
            profileSnapshot.error,
          );
        }

        final profile = profileSnapshot.data?.data();

        final lecturerName =
            profile?['fullName'] as String? ??
            user.displayName ??
            'Lecturer';

        final lecturerEmail =
            profile?['email'] as String? ??
            user.email ??
            '';

        return _buildDashboardContent(
          user,
          lecturerName,
          lecturerEmail,
        );
      },
    );
  }

  // ===================================================
  // 9. DASHBOARD CONTENT
  // ===================================================

  Widget _buildDashboardContent(
    User user,
    String lecturerName,
    String lecturerEmail,
  ) {

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('availability')
          .where(
            'lecturerId',
            isEqualTo: user.uid,
          )
          .snapshots(),

      builder: (context, snapshot) {

        if (snapshot.hasError) {

          return _errorView(
            'Unable to load your availability.',
            snapshot.error,
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {

          return const Center(
            child: CircularProgressIndicator(
              color: lecturerBlue,
            ),
          );
        }

        final documents = snapshot.data?.docs ?? [];

        final now = DateTime.now();

        // UPCOMING AVAILABILITY

        final upcomingSlots = documents.where((doc) {

          final data = doc.data();

          final startAt = data['startAt'];
          final endAt = data['endAt'];

          return data['status'] == 'available' &&
              startAt is Timestamp &&
              endAt is Timestamp &&
              startAt.toDate().isAfter(now);

        }).toList();

        upcomingSlots.sort((a, b) {

          final aStart =
              (a.data()['startAt'] as Timestamp).toDate();

          final bStart =
              (b.data()['startAt'] as Timestamp).toDate();

          return aStart.compareTo(bStart);
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1200,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  // ===================================
                  // WELCOME BANNER
                  // ===================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),

                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          lecturerBlue,
                          lecturerDarkBlue,
                        ],

                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),

                      borderRadius: BorderRadius.circular(22),
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        const Icon(
                          Icons.waving_hand_rounded,
                          size: 34,
                          color: Colors.white,
                        ),

                        const SizedBox(height: 18),

                        Text(
                          'Welcome back, $lecturerName!',

                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'Manage your consultation schedule '
                          'and stay connected with your students.',

                          style: TextStyle(
                            color: Colors.white,
                            height: 1.6,
                            fontSize: 14,
                          ),
                        ),

                        if (lecturerEmail.isNotEmpty) ...[

                          const SizedBox(height: 14),

                          Row(
                            children: [

                              const Icon(
                                Icons.email_outlined,
                                color: Colors.white70,
                                size: 18,
                              ),

                              const SizedBox(width: 8),

                              Flexible(
                                child: Text(
                                  lecturerEmail,

                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ===================================
                  // DASHBOARD OVERVIEW
                  // ===================================

                  const Text(
                    'Dashboard Overview',

                    style: TextStyle(
                      color: lecturerDarkBlue,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Here is an overview of your consultation schedule.',

                    style: TextStyle(
                      color: lecturerSecondaryText,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===================================
                  // DASHBOARD STATISTICS
                  // ===================================

                  LayoutBuilder(
                    builder: (context, constraints) {

                      final columns =
                          constraints.maxWidth >= 800
                              ? 3
                              : constraints.maxWidth >= 500
                                  ? 2
                                  : 1;

                      final cardWidth =
                          (constraints.maxWidth -
                              (columns - 1) * 14) /
                              columns;

                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,

                        children: [

                          // TOTAL TIME SLOTS

                          SizedBox(
                            width: cardWidth,

                            child: _statCard(
                              title: 'Total Time Slots',
                              value: '${documents.length}',
                              subtitle: 'Saved availability records',
                              icon: Icons.calendar_month_rounded,
                              color: lecturerBlue,
                            ),
                          ),

                          // UPCOMING SLOTS

                          SizedBox(
                            width: cardWidth,

                            child: _statCard(
                              title: 'Upcoming Slots',
                              value: '${upcomingSlots.length}',
                              subtitle: 'Available for students',
                              icon: Icons.event_available_rounded,
                              color: const Color(0xFF059669),
                            ),
                          ),

                          // PENDING BOOKING REQUESTS

                          SizedBox(
                            width: cardWidth,

                            child: _pendingBookingRequestsCard(
                              user,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 30),

                  // ===================================
                  // QUICK ACTIONS
                  // UPDATED: FOUR ACTION CARDS
                  // ===================================

                  const Text(
                    'Quick Actions',

                    style: TextStyle(
                      color: lecturerDarkBlue,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {

                      final columns =
                          constraints.maxWidth >= 1000
                              ? 4
                              : constraints.maxWidth >= 520
                                  ? 2
                                  : 1;

                      final cardWidth =
                          (constraints.maxWidth -
                              (columns - 1) * 14) /
                              columns;

                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,

                        children: [

                          // MANAGE AVAILABILITY

                          SizedBox(
                            width: cardWidth,

                            child: _actionCard(
                              icon: Icons.calendar_month_rounded,
                              title: 'Manage Availability',

                              description:
                                  'Create and manage your consultation slots.',

                              onTap: () =>
                                  _onNavigationSelected(1),
                            ),
                          ),

                          // BOOKING REQUESTS

                          SizedBox(
                            width: cardWidth,

                            child: _actionCard(
                              icon: Icons.event_note_rounded,
                              title: 'Booking Requests',

                              description:
                                  'View and respond to student requests.',

                              onTap: () =>
                                  _onNavigationSelected(2),
                            ),
                          ),

                          // MY CALENDAR - NEW

                          SizedBox(
                            width: cardWidth,

                            child: _actionCard(
                              icon: Icons.event_available_rounded,
                              title: 'My Calendar',

                              description:
                                  'View your scheduled consultations and appointments.',

                              onTap: () =>
                                  _onNavigationSelected(3),
                            ),
                          ),

                          // MY PROFILE

                          SizedBox(
                            width: cardWidth,

                            child: _actionCard(
                              icon: Icons.person_outline_rounded,
                              title: 'My Profile',

                              description:
                                  'View your account information.',

                              onTap: () =>
                                  _onNavigationSelected(4),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // ===================================
                  // UPCOMING AVAILABILITY
                  // ===================================

                  Row(
                    children: [

                      const Expanded(
                        child: Text(
                          'Upcoming Availability',

                          style: TextStyle(
                            color: lecturerDarkBlue,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      TextButton.icon(
                        onPressed: () =>
                            _onNavigationSelected(1),

                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                        ),

                        label: const Text('Manage'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (upcomingSlots.isEmpty)

                    _emptyCard(
                      icon: Icons.event_busy_rounded,
                      title: 'No upcoming slots',

                      description:
                          'Create a consultation slot so students '
                          'can find a suitable time with you.',

                      action: FilledButton.icon(
                        onPressed: () =>
                            _onNavigationSelected(1),

                        icon: const Icon(
                          Icons.add_rounded,
                        ),

                        label: const Text(
                          'Create Availability',
                        ),
                      ),
                    )

                  else

                    ...upcomingSlots.take(5).map((doc) {
                      return _availabilityCard(doc);
                    }),

                  const SizedBox(height: 28),

                  const Center(
                    child: Text(
                      'ConsultEasy • Academic Consultation System',

                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: lecturerSecondaryText,
                        fontSize: 12,
                      ),
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
  // 10. STATISTICS CARD
  // ===================================================

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {

    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: lecturerBorder,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(
            children: [

              Container(
                padding: const EdgeInsets.all(10),

                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),

              const Spacer(),

              Flexible(
                child: Text(
                  value,

                  style: const TextStyle(
                    color: lecturerDarkBlue,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            title,

            style: const TextStyle(
              color: lecturerDarkBlue,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            subtitle,

            style: const TextStyle(
              color: lecturerSecondaryText,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // 11. QUICK ACTION CARD
  // ===================================================

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),

        side: const BorderSide(
          color: lecturerBorder,
        ),
      ),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),

        child: Padding(
          padding: const EdgeInsets.all(18),

          child: Row(
            children: [

              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(13),
                ),

                child: Icon(
                  icon,
                  color: lecturerBlue,
                  size: 25,
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
                        color: lecturerDarkBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      description,

                      style: const TextStyle(
                        color: lecturerSecondaryText,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: lecturerSecondaryText,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================================================
  // 12. AVAILABILITY CARD
  // ===================================================

  Widget _availabilityCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {

    final data = document.data();

    final startAt = data['startAt'];
    final endAt = data['endAt'];

    if (startAt is! Timestamp ||
        endAt is! Timestamp) {
      return const SizedBox.shrink();
    }

    final start = startAt.toDate();
    final end = endAt.toDate();

    final dateLabel =
        MaterialLocalizations.of(context)
            .formatMediumDate(start);

    final startLabel =
        TimeOfDay.fromDateTime(start).format(context);

    final endLabel =
        TimeOfDay.fromDateTime(end).format(context);

    return Card(
      color: Colors.white,
      elevation: 0,

      margin: const EdgeInsets.only(bottom: 12),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),

        side: const BorderSide(
          color: lecturerBorder,
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.all(17),

        child: Row(
          children: [

            Container(
              width: 48,
              height: 48,

              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),

              child: const Icon(
                Icons.event_available_rounded,
                color: lecturerBlue,
                size: 25,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(
                    dateLabel,

                    style: const TextStyle(
                      color: lecturerDarkBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    '$startLabel – $endLabel',

                    style: const TextStyle(
                      color: lecturerSecondaryText,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: const Text(
                      'AVAILABLE',

                      style: TextStyle(
                        color: Color(0xFF166534),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF16A34A),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================
  // 13. LIVE PENDING BOOKING REQUESTS CARD
  // ===================================================

  Widget _pendingBookingRequestsCard(User user) {

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where(
            'lecturerId',
            isEqualTo: user.uid,
          )
          .snapshots(),

      builder: (context, snapshot) {

        if (snapshot.hasError) {

          return _statCard(
            title: 'Pending Requests',
            value: '—',
            subtitle: 'Unable to load booking requests',
            icon: Icons.event_note_rounded,
            color: const Color(0xFF7C3AED),
          );
        }

        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            snapshot.data == null) {

          return _statCard(
            title: 'Pending Requests',
            value: '...',
            subtitle: 'Loading booking requests',
            icon: Icons.event_note_rounded,
            color: const Color(0xFF7C3AED),
          );
        }

        final bookingDocuments =
            snapshot.data?.docs ?? [];

        final pendingCount =
            bookingDocuments.where((document) {

          final status =
              document.data()['bookingStatus'] ??
              document.data()['status'];

          return status
                  .toString()
                  .toLowerCase() ==
              'pending';

        }).length;

        return _statCard(
          title: 'Pending Requests',
          value: pendingCount.toString(),
          subtitle: 'Awaiting your response',
          icon: Icons.event_note_rounded,
          color: const Color(0xFF7C3AED),
        );
      },
    );
  }

  // ===================================================
  // 14. PROFILE PAGE
  // ===================================================

  Widget _buildProfilePage(User user) {

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),

      builder: (context, snapshot) {

        if (snapshot.hasError) {

          return _errorView(
            'Unable to load your profile.',
            snapshot.error,
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {

          return const Center(
            child: CircularProgressIndicator(
              color: lecturerBlue,
            ),
          );
        }

        final profile = snapshot.data?.data();

        final name =
            profile?['fullName'] as String? ??
            user.displayName ??
            'Lecturer';

        final email =
            profile?['email'] as String? ??
            user.email ??
            'Not available';

        final role =
            profile?['role'] as String? ??
            'Not available';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 750,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  const Text(
                    'My Profile',

                    style: TextStyle(
                      color: lecturerDarkBlue,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'View your ConsultEasy account information.',

                    style: TextStyle(
                      color: lecturerSecondaryText,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(26),

                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),

                      border: Border.all(
                        color: lecturerBorder,
                      ),
                    ),

                    child: Column(
                      children: [

                        const CircleAvatar(
                          radius: 42,
                          backgroundColor: Color(0xFFDBEAFE),

                          child: Icon(
                            Icons.person_rounded,
                            color: lecturerBlue,
                            size: 44,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          name,

                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            color: lecturerDarkBlue,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Lecturer Account',

                          style: TextStyle(
                            color: lecturerSecondaryText,
                          ),
                        ),

                        const SizedBox(height: 28),

                        const Divider(
                          color: lecturerBorder,
                        ),

                        const SizedBox(height: 14),

                        _profileInfo(
                          icon: Icons.person_outline_rounded,
                          label: 'Full Name',
                          value: name,
                        ),

                        _profileInfo(
                          icon: Icons.email_outlined,
                          label: 'Email Address',
                          value: email,
                        ),

                        _profileInfo(
                          icon: Icons.badge_outlined,
                          label: 'Account Role',
                          value: role,
                        ),

                        _profileInfo(
                          icon: Icons.verified_user_outlined,
                          label: 'Authentication',
                          value: 'Firebase Authentication',
                        ),
                      ],
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
  // 15. PROFILE INFORMATION ROW
  // ===================================================

  Widget _profileInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            color: lecturerBlue,
            size: 22,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  label,

                  style: const TextStyle(
                    color: lecturerSecondaryText,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 5),

                SelectableText(
                  value,

                  style: const TextStyle(
                    color: lecturerDarkBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
  // 16. EMPTY CARD
  // ===================================================

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String description,
    Widget? action,
  }) {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: lecturerBorder,
        ),
      ),

      child: Column(
        children: [

          Icon(
            icon,
            size: 48,
            color: const Color(0xFF94A3B8),
          ),

          const SizedBox(height: 14),

          Text(
            title,

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: lecturerDarkBlue,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            description,

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: lecturerSecondaryText,
              height: 1.6,
            ),
          ),

          if (action != null) ...[

            const SizedBox(height: 20),

            action,
          ],
        ],
      ),
    );
  }

  // ===================================================
  // 17. ERROR VIEW
  // ===================================================

  Widget _errorView(
    String message,
    Object? error,
  ) {

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 550,
          ),

          child: _emptyCard(
            icon: Icons.cloud_off_outlined,
            title: message,

            description: error?.toString() ??
                'Please check your connection and Firestore Rules.',

            action: FilledButton.icon(
              onPressed: () {
                setState(() {});
              },

              icon: const Icon(
                Icons.refresh_rounded,
              ),

              label: const Text('Retry'),
            ),
          ),
        ),
      ),
    );
  }
}
