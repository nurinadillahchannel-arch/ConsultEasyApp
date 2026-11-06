
import 'package:flutter/material.dart';

// =============================================
// CONSULTEASY THEME
// =============================================

const Color notificationBlue = Color(0xFF2563EB);
const Color notificationDarkBlue = Color(0xFF172554);
const Color notificationBackground = Color(0xFFF4F7FC);
const Color notificationSecondary = Color(0xFF64748B);
const Color notificationBorder = Color(0xFFE2E8F0);

// =============================================
// NOTIFICATION MODEL
// =============================================

class LecturerNotification {
  final String id;
  final String title;
  final String message;
  final String category;
  final String time;
  final IconData icon;
  final Color color;
  final bool isRead;

  const LecturerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.time,
    required this.icon,
    required this.color,
    required this.isRead,
  });

  LecturerNotification copyWith({
    bool? isRead,
  }) {
    return LecturerNotification(
      id: id,
      title: title,
      message: message,
      category: category,
      time: time,
      icon: icon,
      color: color,
      isRead: isRead ?? this.isRead,
    );
  }
}

// =============================================
// LECTURER NOTIFICATIONS PAGE
// =============================================

class LecturerNotificationsPage extends StatefulWidget {
  const LecturerNotificationsPage({super.key});

  @override
  State<LecturerNotificationsPage> createState() =>
      _LecturerNotificationsPageState();
}

class _LecturerNotificationsPageState
    extends State<LecturerNotificationsPage> {

  // ===========================================
  // VARIABLES
  // ===========================================

  String _selectedCategory = 'All';

  String _searchQuery = '';

  final TextEditingController _searchController =
      TextEditingController();

  // ===========================================
  // DEMONSTRATION NOTIFICATIONS
  // Replace with Firestore data later.
  // ===========================================

  final List<LecturerNotification> _notifications = [

    LecturerNotification(
      id: 'N001',
      title: 'New Consultation Request',
      message:
          'A student has requested a consultation session '
          'for 12 November 2026 at 10:00 AM.',
      category: 'Bookings',
      time: 'Today, 10:30 AM',
      icon: Icons.event_available_rounded,
      color: notificationBlue,
      isRead: false,
    ),

    LecturerNotification(
      id: 'N002',
      title: 'Consultation Request Received',
      message:
          'You have received a new consultation request '
          'from a student. Please review the request.',
      category: 'Bookings',
      time: 'Today, 9:15 AM',
      icon: Icons.calendar_month_rounded,
      color: Colors.orange,
      isRead: false,
    ),

    LecturerNotification(
      id: 'N003',
      title: 'Upcoming Consultation',
      message:
          'You have an approved consultation session '
          'scheduled for tomorrow.',
      category: 'Schedule',
      time: 'Yesterday, 4:30 PM',
      icon: Icons.access_time_rounded,
      color: Colors.green,
      isRead: false,
    ),

    LecturerNotification(
      id: 'N004',
      title: 'Availability Updated',
      message:
          'Your consultation availability has been '
          'successfully updated.',
      category: 'Schedule',
      time: 'Yesterday, 11:20 AM',
      icon: Icons.edit_calendar_rounded,
      color: Colors.purple,
      isRead: true,
    ),

    LecturerNotification(
      id: 'N005',
      title: 'System Announcement',
      message:
          'Welcome to ConsultEasy. Manage your consultation '
          'schedule and booking requests through the lecturer portal.',
      category: 'System',
      time: '2 days ago',
      icon: Icons.campaign_rounded,
      color: Colors.indigo,
      isRead: true,
    ),

    LecturerNotification(
      id: 'N006',
      title: 'Consultation Reminder',
      message:
          'Remember to review your upcoming consultation '
          'appointments and prepare for your sessions.',
      category: 'Schedule',
      time: '3 days ago',
      icon: Icons.notifications_active_rounded,
      color: Colors.teal,
      isRead: true,
    ),
  ];

  // ===========================================
  // CATEGORY LIST
  // ===========================================

  final List<String> _categories = [
    'All',
    'Bookings',
    'Schedule',
    'System',
  ];

  // ===========================================
  // NOTIFICATION COUNTERS
  // ===========================================

  int get _totalNotifications =>
      _notifications.length;

  int get _unreadNotifications =>
      _notifications.where((item) => !item.isRead).length;

  int get _bookingNotifications =>
      _notifications.where(
        (item) => item.category == 'Bookings',
      ).length;

  int get _systemNotifications =>
      _notifications.where(
        (item) => item.category == 'System',
      ).length;

  // ===========================================
  // FILTER NOTIFICATIONS
  // ===========================================

  List<LecturerNotification> get _filteredNotifications {

    return _notifications.where((notification) {

      final matchesCategory =
          _selectedCategory == 'All' ||
          notification.category == _selectedCategory;

      final query = _searchQuery.toLowerCase();

      final matchesSearch =
          notification.title.toLowerCase().contains(query) ||
          notification.message.toLowerCase().contains(query) ||
          notification.category.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;

    }).toList();
  }

  // ===========================================
  // MARK NOTIFICATION AS READ
  // ===========================================

  void _markAsRead(String id) {

    setState(() {

      final index = _notifications.indexWhere(
        (item) => item.id == id,
      );

      if (index != -1) {
        _notifications[index] =
            _notifications[index].copyWith(
          isRead: true,
        );
      }

    });
  }

  // ===========================================
  // MARK ALL AS READ
  // ===========================================

  void _markAllAsRead() {

    setState(() {

      for (int i = 0; i < _notifications.length; i++) {

        _notifications[i] =
            _notifications[i].copyWith(
          isRead: true,
        );

      }

    });

    _showMessage('All notifications marked as read.');
  }

  // ===========================================
  // SHOW MESSAGE
  // ===========================================

  void _showMessage(String message) {

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );

  }

  // ===========================================
  // DISPOSE
  // ===========================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ===========================================
  // PAGE HEADER
  // ===========================================

  Widget _buildHeader() {

    return LayoutBuilder(
      builder: (context, constraints) {

        final compact = constraints.maxWidth < 550;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [

                Container(
                  width: 48,
                  height: 48,

                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(13),
                  ),

                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: notificationBlue,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        'Notifications',

                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: notificationDarkBlue,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Stay updated with your consultation activities.',

                        style: TextStyle(
                          fontSize: 12,
                          color: notificationSecondary,
                        ),
                      ),

                    ],
                  ),
                ),

              ],
            ),

            const SizedBox(height: 20),

            if (_unreadNotifications > 0)

              Align(
                alignment: Alignment.centerRight,

                child: TextButton.icon(
                  onPressed: _markAllAsRead,

                  icon: const Icon(
                    Icons.done_all_rounded,
                    size: 18,
                  ),

                  label: const Text('Mark all as read'),

                  style: TextButton.styleFrom(
                    foregroundColor: notificationBlue,
                  ),
                ),
              ),

          ],
        );
      },
    );
  }

  // ===========================================
  // SUMMARY CARD
  // ===========================================

  Widget _summaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required double width,
  }) {

    return SizedBox(
      width: width,

      child: Container(
        padding: const EdgeInsets.all(17),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: notificationBorder,
          ),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                Container(
                  width: 39,
                  height: 39,

                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),

                  child: Icon(
                    icon,
                    color: color,
                    size: 21,
                  ),
                ),

                Text(
                  '$count',

                  style: const TextStyle(
                    color: notificationDarkBlue,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              ],
            ),

            const SizedBox(height: 13),

            Text(
              title,

              style: const TextStyle(
                color: notificationDarkBlue,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Notifications',

              style: TextStyle(
                color: notificationSecondary,
                fontSize: 10,
              ),
            ),

          ],
        ),
      ),
    );
  }

  // ===========================================
  // SUMMARY SECTION
  // ===========================================

  Widget _buildSummary(double availableWidth) {

    final cardWidth = availableWidth < 400
        ? (availableWidth - 12) / 2
        : availableWidth < 750
            ? (availableWidth - 12) / 2
            : (availableWidth - 36) / 4;

    return Wrap(
      spacing: 12,
      runSpacing: 12,

      children: [

        _summaryCard(
          title: 'Total',
          count: _totalNotifications,
          icon: Icons.notifications_rounded,
          color: notificationBlue,
          width: cardWidth,
        ),

        _summaryCard(
          title: 'Unread',
          count: _unreadNotifications,
          icon: Icons.mark_email_unread_rounded,
          color: Colors.orange,
          width: cardWidth,
        ),

        _summaryCard(
          title: 'Bookings',
          count: _bookingNotifications,
          icon: Icons.event_note_rounded,
          color: Colors.green,
          width: cardWidth,
        ),

        _summaryCard(
          title: 'System',
          count: _systemNotifications,
          icon: Icons.settings_suggest_rounded,
          color: Colors.purple,
          width: cardWidth,
        ),

      ],
    );
  }

  // ===========================================
  // SEARCH BAR
  // ===========================================

  Widget _buildSearchBar() {

    return TextField(
      controller: _searchController,

      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },

      decoration: InputDecoration(

        hintText: 'Search notifications...',

        prefixIcon: const Icon(
          Icons.search_rounded,
          color: notificationSecondary,
        ),

        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _searchQuery = '';
                  });
                },

                icon: const Icon(Icons.close_rounded),
              )
            : null,

        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: notificationBorder,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: notificationBorder,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: notificationBlue,
          ),
        ),

      ),
    );
  }

  // ===========================================
  // CATEGORY FILTER
  // ===========================================

  Widget _buildCategoryFilters() {

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,

      child: Row(
        children: _categories.map((category) {

          final selected =
              _selectedCategory == category;

          final count = category == 'All'
              ? _totalNotifications
              : _notifications.where(
                  (item) => item.category == category,
                ).length;

          return Padding(
            padding: const EdgeInsets.only(right: 9),

            child: ChoiceChip(

              selected: selected,

              onSelected: (_) {
                setState(() {
                  _selectedCategory = category;
                });
              },

              label: Text('$category ($count)'),

              selectedColor: const Color(0xFFDBEAFE),

              backgroundColor: Colors.white,

              labelStyle: TextStyle(
                color: selected
                    ? notificationBlue
                    : notificationSecondary,

                fontSize: 12,

                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),

              side: BorderSide(
                color: selected
                    ? notificationBlue
                    : notificationBorder,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

            ),
          );

        }).toList(),
      ),
    );
  }

  // ===========================================
  // CATEGORY BADGE
  // ===========================================

  Color _categoryColor(String category) {

    switch (category) {

      case 'Bookings':
        return notificationBlue;

      case 'Schedule':
        return Colors.green;

      case 'System':
        return Colors.purple;

      default:
        return notificationSecondary;
    }
  }

  Widget _categoryBadge(String category) {

    final color = _categoryColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        category,

        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ===========================================
  // NOTIFICATION CARD
  // ===========================================

  Widget _buildNotificationCard(
    LecturerNotification notification,
  ) {

    return Container(
      margin: const EdgeInsets.only(bottom: 13),

      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.white
            : const Color(0xFFF8FBFF),

        borderRadius: BorderRadius.circular(15),

        border: Border.all(
          color: notification.isRead
              ? notificationBorder
              : const Color(0xFFBFDBFE),
        ),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(15),

        onTap: () {

          if (!notification.isRead) {
            _markAsRead(notification.id);
          }

        },

        child: Padding(
          padding: const EdgeInsets.all(17),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              // ICON

              Container(
                width: 45,
                height: 45,

                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 23,
                ),
              ),

              const SizedBox(width: 13),

              // CONTENT

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,

                      children: [

                        Text(
                          notification.title,

                          style: TextStyle(
                            color: notificationDarkBlue,
                            fontSize: 13,
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                          ),
                        ),

                        if (!notification.isRead)

                          Container(
                            width: 7,
                            height: 7,

                            decoration: const BoxDecoration(
                              color: notificationBlue,
                              shape: BoxShape.circle,
                            ),
                          ),

                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      notification.message,

                      style: const TextStyle(
                        color: notificationSecondary,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 9,
                      runSpacing: 7,
                      crossAxisAlignment: WrapCrossAlignment.center,

                      children: [

                        _categoryBadge(
                          notification.category,
                        ),

                        Text(
                          notification.time,

                          style: const TextStyle(
                            color: notificationSecondary,
                            fontSize: 10,
                          ),
                        ),

                      ],
                    ),

                  ],
                ),
              ),

              const SizedBox(width: 5),

              // READ STATUS

              if (!notification.isRead)

                const Tooltip(
                  message: 'Unread',

                  child: Icon(
                    Icons.circle,
                    color: notificationBlue,
                    size: 9,
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }

  // ===========================================
  // EMPTY STATE
  // ===========================================

  Widget _buildEmptyState() {

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 55,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notificationBorder,
        ),
      ),

      child: Column(
        children: [

          Container(
            width: 75,
            height: 75,

            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.notifications_off_outlined,
              color: notificationBlue,
              size: 36,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'No Notifications Found',

            style: TextStyle(
              color: notificationDarkBlue,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _searchQuery.isNotEmpty
                ? 'Try another search keyword.'
                : 'There are no notifications in this category.',

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: notificationSecondary,
              fontSize: 12,
            ),
          ),

        ],
      ),
    );
  }

  // ===========================================
  // NOTIFICATION LIST
  // ===========================================

  Widget _buildNotificationList() {

    final notifications = _filteredNotifications;

    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: notifications.map(
        (notification) => _buildNotificationCard(
          notification,
        ),
      ).toList(),
    );
  }

  // ===========================================
  // MAIN PAGE
  // ===========================================

  @override
  Widget build(BuildContext context) {

    return Container(
      color: notificationBackground,

      child: LayoutBuilder(
        builder: (context, constraints) {

          return SingleChildScrollView(

            padding: const EdgeInsets.all(24),

            child: Center(
              child: ConstrainedBox(

                constraints: const BoxConstraints(
                  maxWidth: 1150,
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    // HEADER

                    _buildHeader(),

                    const SizedBox(height: 22),

                    // SUMMARY

                    _buildSummary(
                      constraints.maxWidth - 48 > 0
                          ? constraints.maxWidth - 48
                          : constraints.maxWidth,
                    ),

                    const SizedBox(height: 30),

                    // NOTIFICATION SECTION HEADER

                    const Text(
                      'Notification Centre',

                      style: TextStyle(
                        color: notificationDarkBlue,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'View and manage your latest notifications.',

                      style: TextStyle(
                        color: notificationSecondary,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SEARCH

                    _buildSearchBar(),

                    const SizedBox(height: 18),

                    // CATEGORY FILTER

                    _buildCategoryFilters(),

                    const SizedBox(height: 22),

                    // NOTIFICATIONS

                    _buildNotificationList(),

                    const SizedBox(height: 25),

                    // FOOTER

                    const Center(
                      child: Text(
                        'ConsultEasy | Lecturer Portal',

                        style: TextStyle(
                          color: notificationSecondary,
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
        },
      ),
    );
  }
}
