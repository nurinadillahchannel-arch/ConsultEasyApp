
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =============================================
// CONSULTEASY COLOURS
// =============================================

const Color bookingBlue = Color(0xFF2563EB);
const Color bookingDarkBlue = Color(0xFF172554);
const Color bookingBackground = Color(0xFFF4F7FC);
const Color bookingSecondaryText = Color(0xFF64748B);
const Color bookingBorder = Color(0xFFE2E8F0);

// =============================================
// BOOKING EXCEPTION
// =============================================

class _BookingPageException implements Exception {
  final String message;

  const _BookingPageException(this.message);

  @override
  String toString() => message;
}

// =============================================
// BOOKING MODEL
// =============================================

class _BookingPreview {
  final String documentId;
  final String bookingId;
  final String availabilityId;
  final String lecturerName;
  final String purpose;
  final String status;
  final DateTime? startAt;
  final DateTime? endAt;

  const _BookingPreview({
    required this.documentId,
    required this.bookingId,
    required this.availabilityId,
    required this.lecturerName,
    required this.purpose,
    required this.status,
    required this.startAt,
    required this.endAt,
  });
}

// =============================================
// MY BOOKINGS PAGE
// =============================================

class StudentMyBookingsPage extends StatefulWidget {
  const StudentMyBookingsPage({super.key});

  @override
  State<StudentMyBookingsPage> createState() =>
      _StudentMyBookingsPageState();
}

class _StudentMyBookingsPageState
    extends State<StudentMyBookingsPage> {

  String _selectedFilter = 'All';

  final Set<String> _processingBookings = {};

  final List<String> _filters = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
    'Cancelled',
  ];

  // =============================================
  // GET CURRENT USER
  // =============================================

  User? get _currentUser =>
      FirebaseAuth.instance.currentUser;

  // =============================================
  // CONVERT FIRESTORE DATA
  // =============================================

  String _readString(
    dynamic value, {
    required String fallback,
  }) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return fallback;
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  String _normaliseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';

      case 'approved':
        return 'Approved';

      case 'rejected':
        return 'Rejected';

      case 'cancelled':
        return 'Cancelled';

      default:
        return status;
    }
  }

  _BookingPreview _mapBooking(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    return _BookingPreview(
      documentId: document.id,

      bookingId: _readString(
        data['bookingId'],
        fallback: document.id,
      ),

      availabilityId: _readString(
        data['availabilityId'],
        fallback: '',
      ),

      lecturerName: _readString(
        data['lecturerName'],
        fallback: 'Lecturer',
      ),

      purpose: _readString(
        data['consultationPurpose'],
        fallback: 'No consultation purpose provided.',
      ),

      status: _normaliseStatus(
        _readString(
          data['bookingStatus'],
          fallback: 'Pending',
        ),
      ),

      startAt: _readDate(data['startAt']),

      endAt: _readDate(data['endAt']),
    );
  }

  // =============================================
  // FILTER BOOKINGS
  // =============================================

  List<_BookingPreview> _filteredBookings(
    List<_BookingPreview> allBookings,
  ) {
    if (_selectedFilter == 'All') {
      return allBookings;
    }

    return allBookings
        .where((booking) =>
            booking.status == _selectedFilter)
        .toList();
  }

  // =============================================
  // COUNT BOOKINGS
  // =============================================

  int _countStatus(
    List<_BookingPreview> bookings,
    String status,
  ) {
    if (status == 'All') {
      return bookings.length;
    }

    return bookings
        .where((booking) => booking.status == status)
        .length;
  }

  // =============================================
  // STATUS COLOURS
  // =============================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF059669);

      case 'rejected':
        return const Color(0xFFDC2626);

      case 'cancelled':
        return const Color(0xFF64748B);

      case 'pending':
      default:
        return const Color(0xFFD97706);
    }
  }

  Color _statusBackground(String status) {
    return _statusColor(status).withOpacity(0.10);
  }

  // =============================================
  // DATE AND TIME FORMATTING
  // =============================================

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Date unavailable';
    }

    return MaterialLocalizations.of(context)
        .formatMediumDate(date);
  }

  String _formatTime(DateTime? date) {
    if (date == null) {
      return 'Time unavailable';
    }

    return TimeOfDay.fromDateTime(date).format(context);
  }

  // =============================================
  // MESSAGE HANDLER
  // =============================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Colors.red.shade700
              : const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // =============================================
  // PAGE HEADING
  // =============================================

  Widget _pageHeading() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Bookings',
          style: TextStyle(
            color: bookingDarkBlue,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 7),

        Text(
          'Manage and track your consultation requests.',
          style: TextStyle(
            color: bookingSecondaryText,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // =============================================
  // SUMMARY CARD
  // =============================================

  Widget _summaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: bookingBorder),
      ),

      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,

            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: bookingSecondaryText,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  count.toString(),
                  style: const TextStyle(
                    color: bookingDarkBlue,
                    fontSize: 23,
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

  // =============================================
  // SUMMARY SECTION
  // =============================================

  Widget _buildSummary(
    List<_BookingPreview> bookings,
  ) {
    final summaries = [
      {
        'title': 'Total Bookings',
        'status': 'All',
        'icon': Icons.event_note_rounded,
        'color': bookingBlue,
      },
      {
        'title': 'Pending',
        'status': 'Pending',
        'icon': Icons.hourglass_top_rounded,
        'color': const Color(0xFFD97706),
      },
      {
        'title': 'Approved',
        'status': 'Approved',
        'icon': Icons.check_circle_outline_rounded,
        'color': const Color(0xFF059669),
      },
      {
        'title': 'Rejected',
        'status': 'Rejected',
        'icon': Icons.cancel_outlined,
        'color': const Color(0xFFDC2626),
      },
      {
        'title': 'Cancelled',
        'status': 'Cancelled',
        'icon': Icons.event_busy_outlined,
        'color': const Color(0xFF64748B),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {

        final columns =
            constraints.maxWidth >= 1200
                ? 5
                : constraints.maxWidth >= 850
                    ? 3
                    : constraints.maxWidth >= 550
                        ? 2
                        : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),

          itemCount: summaries.length,

          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 100,
          ),

          itemBuilder: (context, index) {
            final item = summaries[index];

            return _summaryCard(
              title: item['title'] as String,

              count: _countStatus(
                bookings,
                item['status'] as String,
              ),

              icon: item['icon'] as IconData,

              color: item['color'] as Color,
            );
          },
        );
      },
    );
  }

  // =============================================
  // FILTER SECTION
  // =============================================

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,

      child: Row(
        children: _filters.map((filter) {

          final selected =
              _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 9),

            child: ChoiceChip(
              label: Text(filter),

              selected: selected,

              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter;
                });
              },

              selectedColor: bookingBlue,
              backgroundColor: Colors.white,

              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : bookingSecondaryText,

                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.w500,

                fontSize: 12,
              ),

              side: BorderSide(
                color: selected
                    ? bookingBlue
                    : bookingBorder,
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

  // =============================================
  // BOOKING STATUS BADGE
  // =============================================

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),

      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        status.toUpperCase(),

        style: TextStyle(
          color: _statusColor(status),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // =============================================
  // DETAIL ROW
  // =============================================

  Widget _detailRow(
    IconData icon,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: bookingBlue,
          size: 18,
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: bookingSecondaryText,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // =============================================
  // BOOKING CARD
  // =============================================

  Widget _bookingCard(
    _BookingPreview booking,
  ) {
    final isProcessing =
        _processingBookings.contains(booking.documentId);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(19),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: bookingBorder),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          // BOOKING ID AND STATUS

          Row(
            children: [
              Expanded(
                child: Text(
                  booking.bookingId,
                  style: const TextStyle(
                    color: bookingSecondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              _statusBadge(booking.status),
            ],
          ),

          const SizedBox(height: 17),

          // LECTURER DETAILS

          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFDBEAFE),

                child: Text(
                  booking.lecturerName[0].toUpperCase(),

                  style: const TextStyle(
                    color: bookingBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lecturer',
                      style: TextStyle(
                        color: bookingSecondaryText,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      booking.lecturerName,
                      style: const TextStyle(
                        color: bookingDarkBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 19),

          const Divider(color: bookingBorder),

          const SizedBox(height: 14),

          // DATE

          _detailRow(
            Icons.calendar_month_outlined,
            _formatDate(booking.startAt),
          ),

          const SizedBox(height: 12),

          // TIME

          _detailRow(
            Icons.access_time_rounded,
            '${_formatTime(booking.startAt)} - '
            '${_formatTime(booking.endAt)}',
          ),

          const SizedBox(height: 12),

          // PURPOSE

          _detailRow(
            Icons.description_outlined,
            booking.purpose,
          ),

          const SizedBox(height: 18),

          // ACTION BUTTONS

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showBookingDetails(booking);
                  },

                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 17,
                  ),

                  label: const Text('View Details'),

                  style: OutlinedButton.styleFrom(
                    foregroundColor: bookingBlue,

                    side: const BorderSide(
                      color: bookingBlue,
                    ),

                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              if (booking.status == 'Pending' ||
                  booking.status == 'Approved')

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isProcessing
                        ? null
                        : () {
                            _confirmCancellation(booking);
                          },

                    icon: isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.close_rounded,
                            size: 17,
                          ),

                    label: Text(
                      isProcessing
                          ? 'Cancelling...'
                          : 'Cancel Request',
                    ),

                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          const Color(0xFFDC2626),

                      side: const BorderSide(
                        color: Color(0xFFFECACA),
                      ),

                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================================
  // BOOKING DETAILS BOTTOM SHEET
  // =============================================

  void _showBookingDetails(
    _BookingPreview booking,
  ) {
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
            padding: const EdgeInsets.all(24),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,

              children: [

                Center(
                  child: Container(
                    width: 42,
                    height: 5,

                    decoration: BoxDecoration(
                      color: bookingBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Booking Details',
                  style: TextStyle(
                    color: bookingDarkBlue,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  booking.bookingId,
                  style: const TextStyle(
                    color: bookingSecondaryText,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 18),

                _statusBadge(booking.status),

                const SizedBox(height: 22),

                _detailRow(
                  Icons.person_outline,
                  booking.lecturerName,
                ),

                const SizedBox(height: 17),

                _detailRow(
                  Icons.calendar_month_outlined,
                  _formatDate(booking.startAt),
                ),

                const SizedBox(height: 17),

                _detailRow(
                  Icons.access_time_rounded,
                  '${_formatTime(booking.startAt)} - '
                  '${_formatTime(booking.endAt)}',
                ),

                const SizedBox(height: 17),

                _detailRow(
                  Icons.description_outlined,
                  booking.purpose,
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,

                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },

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

  // =============================================
  // CONFIRM CANCELLATION
  // =============================================

  Future<void> _confirmCancellation(
    _BookingPreview booking,
  ) async {

    final confirmed = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,

          title: const Text(
            'Cancel Booking?',
            style: TextStyle(
              color: bookingDarkBlue,
              fontWeight: FontWeight.bold,
            ),
          ),

          content: const Text(
            'Are you sure you want to cancel this consultation request?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },

              child: const Text('Keep Booking'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },

              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),

              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _cancelBooking(booking);
    }
  }

  // =============================================
  // FIREBASE CANCELLATION
  // =============================================

  Future<void> _cancelBooking(
    _BookingPreview booking,
  ) async {

    if (_processingBookings.contains(booking.documentId)) {
      return;
    }

    final user = _currentUser;

    if (user == null) {
      _showMessage(
        'Please log in again.',
        isError: true,
      );
      return;
    }

    setState(() {
      _processingBookings.add(booking.documentId);
    });

    try {

      final firestore = FirebaseFirestore.instance;

      final bookingRef = firestore
          .collection('bookings')
          .doc(booking.documentId);

      await firestore.runTransaction<void>(
        (transaction) async {

          // GET BOOKING

          final bookingSnapshot =
              await transaction.get(bookingRef);

          if (!bookingSnapshot.exists) {
            throw const _BookingPageException(
              'This booking no longer exists.',
            );
          }

          final bookingData =
              bookingSnapshot.data()!;

          // VERIFY STUDENT OWNERSHIP

          if (bookingData['studentId'] != user.uid) {
            throw const _BookingPageException(
              'You are not authorised to cancel this booking.',
            );
          }

          // CHECK BOOKING STATUS

          final currentStatus =
              (bookingData['bookingStatus'] as String?)
                      ?.toLowerCase() ??
                  '';

          if (currentStatus != 'pending' &&
              currentStatus != 'approved') {
            throw const _BookingPageException(
              'This booking can no longer be cancelled.',
            );
          }

          // GET AVAILABILITY DOCUMENT

          final availabilityId =
              bookingData['availabilityId'];

          DocumentReference<Map<String, dynamic>>?
              availabilityRef;

          DocumentSnapshot<Map<String, dynamic>>?
              availabilitySnapshot;

          if (availabilityId is String &&
              availabilityId.trim().isNotEmpty) {

            availabilityRef = firestore
                .collection('availability')
                .doc(availabilityId);

            availabilitySnapshot =
                await transaction.get(availabilityRef);
          }

          // UPDATE BOOKING STATUS

          transaction.update(
            bookingRef,
            {
              'bookingStatus': 'Cancelled',

              'cancelledAt':
                  FieldValue.serverTimestamp(),
            },
          );

          // RELEASE THE SLOT IF IT BELONGS TO THIS BOOKING

          if (availabilityRef != null &&
              availabilitySnapshot != null &&
              availabilitySnapshot.exists) {

            final slotData =
                availabilitySnapshot.data()!;

            final belongsToBooking =
                slotData['status'] == 'booked' &&
                slotData['bookingId'] == bookingRef.id;

            if (belongsToBooking) {

              transaction.update(
                availabilityRef,
                {
                  'status': 'available',

                  'bookingId': FieldValue.delete(),

                  'bookedAt': FieldValue.delete(),
                },
              );
            }
          }
        },
      );

      if (!mounted) return;

      _showMessage(
        'Booking cancelled successfully.',
      );

    } on _BookingPageException catch (error) {

      _showMessage(
        error.message,
        isError: true,
      );

    } on FirebaseException catch (error) {

      if (error.code == 'permission-denied') {

        _showMessage(
          'Permission denied. Please check Firestore Rules.',
          isError: true,
        );

      } else if (error.code == 'unavailable') {

        _showMessage(
          'Unable to connect to Firebase. Check your internet connection.',
          isError: true,
        );

      } else {

        _showMessage(
          'Cancellation failed: ${error.message ?? error.code}',
          isError: true,
        );
      }

    } catch (error) {

      _showMessage(
        'Something went wrong. Please try again.',
        isError: true,
      );

    } finally {

      if (mounted) {
        setState(() {
          _processingBookings.remove(booking.documentId);
        });
      }
    }
  }

  // =============================================
  // EMPTY STATE
  // =============================================

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: bookingBorder),
      ),

      child: Column(
        children: [

          const Icon(
            Icons.event_busy_outlined,
            size: 50,
            color: Color(0xFF94A3B8),
          ),

          const SizedBox(height: 15),

          Text(
            _selectedFilter == 'All'
                ? 'No Bookings Yet'
                : 'No $_selectedFilter Bookings',

            style: const TextStyle(
              color: bookingDarkBlue,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Your consultation bookings will appear here once you submit a request.',

            textAlign: TextAlign.center,

            style: TextStyle(
              color: bookingSecondaryText,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // ERROR STATE
  // =============================================

  Widget _errorState(Object? error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: bookingBorder),
      ),

      child: Column(
        children: [

          const Icon(
            Icons.cloud_off_outlined,
            color: Color(0xFFDC2626),
            size: 45,
          ),

          const SizedBox(height: 15),

          const Text(
            'Unable to Load Bookings',
            style: TextStyle(
              color: bookingDarkBlue,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Please check your internet connection or Firebase configuration.',

            textAlign: TextAlign.center,

            style: TextStyle(
              color: bookingSecondaryText,
              fontSize: 13,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 15),

          OutlinedButton.icon(
            onPressed: () {
              setState(() {});
            },

            icon: const Icon(Icons.refresh_rounded),

            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // =============================================
  // MAIN PAGE CONTENT
  // =============================================

  Widget _buildPageContent(
    List<_BookingPreview> allBookings,
  ) {

    final bookings =
        _filteredBookings(allBookings);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),

      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1250,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              // PAGE HEADING

              _pageHeading(),

              const SizedBox(height: 25),

              // BOOKING OVERVIEW

              const Text(
                'Booking Overview',

                style: TextStyle(
                  color: bookingDarkBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              _buildSummary(allBookings),

              const SizedBox(height: 30),

              // CONSULTATION REQUESTS

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Your Consultation Requests',

                      style: TextStyle(
                        color: bookingDarkBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Text(
                    '${bookings.length} records',

                    style: const TextStyle(
                      color: bookingSecondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // FILTERS

              _buildFilters(),

              const SizedBox(height: 20),

              // BOOKING LIST

              if (bookings.isEmpty)
                _emptyState()
              else
                ...bookings.map(_bookingCard),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================
  // MAIN BUILD
  // =============================================

  @override
  Widget build(BuildContext context) {

    final user = _currentUser;

    // CHECK LOGIN

    if (user == null) {
      return _buildPageContent([]);
    }

    // FIRESTORE STREAM

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where(
            'studentId',
            isEqualTo: user.uid,
          )
          .snapshots(),

      builder: (context, snapshot) {

        // ERROR

        if (snapshot.hasError) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(25),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pageHeading(),

                const SizedBox(height: 25),

                _errorState(snapshot.error),
              ],
            ),
          );
        }

        // LOADING

        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            !snapshot.hasData) {

          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),

              child: CircularProgressIndicator(
                color: bookingBlue,
              ),
            ),
          );
        }

        // GET FIRESTORE DOCUMENTS

        final documents =
            snapshot.data?.docs ?? [];

        // CONVERT DOCUMENTS INTO BOOKING OBJECTS

        final allBookings = documents
            .map(_mapBooking)
            .toList();

        // SORT BY CONSULTATION DATE

        allBookings.sort((a, b) {

          final aDate = a.startAt ??
              DateTime.fromMillisecondsSinceEpoch(0);

          final bDate = b.startAt ??
              DateTime.fromMillisecondsSinceEpoch(0);

          return bDate.compareTo(aDate);
        });

        // DISPLAY REAL FIREBASE DATA

        return _buildPageContent(allBookings);
      },
    );
  }
}
