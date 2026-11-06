
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =====================================================
// CONSULTEASY DESIGN SYSTEM
// =====================================================

const Color requestBlue = Color(0xFF2563EB);
const Color requestDarkBlue = Color(0xFF172554);
const Color requestBackground = Color(0xFFF4F7FC);
const Color requestSecondary = Color(0xFF64748B);
const Color requestBorder = Color(0xFFE2E8F0);

const Color requestGreen = Color(0xFF059669);
const Color requestOrange = Color(0xFFD97706);
const Color requestRed = Color(0xFFDC2626);
const Color requestPurple = Color(0xFF7C3AED);

// =====================================================
// BOOKING ACTION EXCEPTION
// =====================================================

class BookingActionException implements Exception {
  final String message;

  const BookingActionException(this.message);

  @override
  String toString() => message;
}

// =====================================================
// LECTURER BOOKING REQUESTS PAGE
// =====================================================

class LecturerBookingRequestsPage extends StatefulWidget {
  const LecturerBookingRequestsPage({super.key});

  @override
  State<LecturerBookingRequestsPage> createState() =>
      _LecturerBookingRequestsPageState();
}

class _LecturerBookingRequestsPageState
    extends State<LecturerBookingRequestsPage> {

  // ===================================================
  // UPDATED 1: PAGE STATE
  // ===================================================

  String _selectedFilter = 'All';

  String _searchQuery = '';

  bool _showSearch = true;

  final TextEditingController _searchController =
      TextEditingController();

  final List<String> _filters = [
    'All',
    'Pending',
    'Approved',
    'Rejected',
  ];

  final Set<String> _processingBookings = {};

  User? get _currentUser =>
      FirebaseAuth.instance.currentUser;

  // ===================================================
  // UPDATED 2: DISPOSE CONTROLLER
  // ===================================================

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ===================================================
  // UPDATED 3: SAFE STRING HELPER
  // ===================================================

  String _getString(
    Map<String, dynamic> data,
    String field, {
    String fallback = 'Not provided',
  }) {
    final value = data[field];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return fallback;
  }

  // ===================================================
  // UPDATED 4: FIRESTORE DATE CONVERSION
  // ===================================================

  DateTime? _getDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // ===================================================
  // UPDATED 5: DATE FORMATTING
  // ===================================================

  String _formatDate(
    BuildContext context,
    dynamic value,
  ) {
    final date = _getDate(value);

    if (date == null) {
      return 'Date not available';
    }

    return MaterialLocalizations.of(context)
        .formatMediumDate(date);
  }

  // ===================================================
  // UPDATED 6: TIME FORMATTING
  // ===================================================

  String _formatTime(
    BuildContext context,
    dynamic value,
  ) {
    final date = _getDate(value);

    if (date == null) {
      return '--:--';
    }

    return TimeOfDay.fromDateTime(date)
        .format(context);
  }

  // ===================================================
  // UPDATED 7: DATETIME FORMATTING
  // ===================================================

  String _formatDateTime(
    BuildContext context,
    dynamic value,
  ) {
    final date = _getDate(value);

    if (date == null) {
      return 'Not available';
    }

    final dateLabel =
        MaterialLocalizations.of(context)
            .formatMediumDate(date);

    final timeLabel =
        TimeOfDay.fromDateTime(date).format(context);

    return '$dateLabel at $timeLabel';
  }

  // ===================================================
  // UPDATED 8: STATUS COLOURS
  // ===================================================

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return requestGreen;

      case 'rejected':
      case 'cancelled':
        return requestRed;

      case 'pending':
        return requestOrange;

      default:
        return requestSecondary;
    }
  }

  Color _statusBackground(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFFDCFCE7);

      case 'rejected':
      case 'cancelled':
        return const Color(0xFFFEE2E2);

      case 'pending':
        return const Color(0xFFFEF3C7);

      default:
        return const Color(0xFFF1F5F9);
    }
  }

  // ===================================================
  // UPDATED 9: STATUS BADGE
  // ===================================================

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

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
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // ===================================================
  // UPDATED 10: MESSAGE HANDLER
  // ===================================================

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
              : requestGreen,

          behavior: SnackBarBehavior.floating,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ===================================================
  // UPDATED 11: CONFIRM APPROVE / REJECT
  // ===================================================

  Future<void> _confirmResponse({
    required String bookingId,
    required String newStatus,
  }) async {

    if (newStatus != 'Approved' &&
        newStatus != 'Rejected') {
      return;
    }

    final isApproval = newStatus == 'Approved';

    final confirmed = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          icon: Icon(
            isApproval
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,

            color: isApproval
                ? requestGreen
                : requestRed,

            size: 42,
          ),

          title: Text(
            isApproval
                ? 'Approve Booking?'
                : 'Reject Booking?',

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: requestDarkBlue,
              fontWeight: FontWeight.bold,
            ),
          ),

          content: Text(
            isApproval
                ? 'Are you sure you want to approve this consultation request?'
                : 'Are you sure you want to reject this consultation request? The reserved time slot will be released.',

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: requestSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),

          actionsAlignment: MainAxisAlignment.center,

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },

              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },

              style: FilledButton.styleFrom(
                backgroundColor: isApproval
                    ? requestGreen
                    : requestRed,
              ),

              child: Text(
                isApproval
                    ? 'Yes, Approve'
                    : 'Yes, Reject',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _respondToBooking(
      bookingId: bookingId,
      newStatus: newStatus,
    );
  }

  // ===================================================
  // UPDATED 12: FIRESTORE APPROVE / REJECT TRANSACTION
  // UPDATED: CREATE STUDENT NOTIFICATION AUTOMATICALLY
  // ===================================================

  Future<void> _respondToBooking({
    required String bookingId,
    required String newStatus,
  }) async {

    // Accept only the two supported lecturer actions.
    if (newStatus != 'Approved' &&
        newStatus != 'Rejected') {
      return;
    }

    if (_processingBookings.contains(bookingId)) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Your session has expired. Please log in again.',
        isError: true,
      );
      return;
    }

    setState(() {
      _processingBookings.add(bookingId);
    });

    try {
      final firestore = FirebaseFirestore.instance;

      final bookingRef = firestore
          .collection('bookings')
          .doc(bookingId);

      // NEW: Create one notification document reference.
      // It is written in the same transaction as the booking update.
      final notificationRef = firestore
          .collection('notifications')
          .doc();

      await firestore.runTransaction<void>(
        (transaction) async {

          // -------------------------------------------
          // STEP 1: READ BOOKING
          // -------------------------------------------

          final bookingSnapshot =
              await transaction.get(bookingRef);

          if (!bookingSnapshot.exists) {
            throw const BookingActionException(
              'This booking request no longer exists.',
            );
          }

          final bookingData = bookingSnapshot.data()!;

          // -------------------------------------------
          // STEP 2: VERIFY LECTURER OWNERSHIP
          // -------------------------------------------

          if (bookingData['lecturerId'] != user.uid) {
            throw const BookingActionException(
              'You are not authorised to manage this booking.',
            );
          }

          // Only pending bookings can be processed.
          final currentStatus =
              (bookingData['bookingStatus'] as String?) ?? 'Pending';

          if (currentStatus.toLowerCase() != 'pending') {
            throw const BookingActionException(
              'This booking has already been processed.',
            );
          }

          // -------------------------------------------
          // STEP 3: READ RELATED AVAILABILITY
          // -------------------------------------------

          final availabilityId = bookingData['availabilityId'];

          if (availabilityId is! String ||
              availabilityId.trim().isEmpty) {
            throw const BookingActionException(
              'Availability information is missing from this booking.',
            );
          }

          final availabilityRef = firestore
              .collection('availability')
              .doc(availabilityId);

          final availabilitySnapshot =
              await transaction.get(availabilityRef);

          if (!availabilitySnapshot.exists) {
            throw const BookingActionException(
              'The associated availability slot could not be found.',
            );
          }

          final slotData = availabilitySnapshot.data()!;

          // Make sure this slot is still reserved by this booking.
          if (slotData['lecturerId'] != user.uid ||
              slotData['status'] != 'booked' ||
              slotData['bookingId'] != bookingId) {
            throw const BookingActionException(
              'The reserved availability slot is no longer valid.',
            );
          }

          // -------------------------------------------
          // STEP 4: VALIDATE STUDENT DETAILS
          // -------------------------------------------

          final studentId = bookingData['studentId'];

          if (studentId is! String || studentId.trim().isEmpty) {
            throw const BookingActionException(
              'Student information is missing from this booking.',
            );
          }

          final lecturerName =
              (bookingData['lecturerName'] as String?)?.trim().isNotEmpty == true
                  ? (bookingData['lecturerName'] as String).trim()
                  : 'your lecturer';

          // -------------------------------------------
          // STEP 5: APPROVE BOOKING
          // -------------------------------------------

          if (newStatus == 'Approved') {

            // Update the booking. The availability slot remains booked.
            transaction.update(
              bookingRef,
              {
                'bookingStatus': 'Approved',
                'approvedAt': FieldValue.serverTimestamp(),
                'lecturerResponseAt': FieldValue.serverTimestamp(),
              },
            );

            // NEW: Notify the student that the booking was approved.
            transaction.set(
              notificationRef,
              {
                'notificationID': notificationRef.id,
                'bookingID': bookingId,
                'userID': studentId,
                'notificationTitle': 'Booking Approved',
                'notificationMessage':
                    'Your consultation request with $lecturerName has been approved.',
                'notificationType': 'Booking Update',
                'notificationStatus': 'Unread',
                'createdDate': FieldValue.serverTimestamp(),
              },
            );
          }

          // -------------------------------------------
          // STEP 6: REJECT BOOKING
          // -------------------------------------------

          else if (newStatus == 'Rejected') {

            // Update the booking with the required response fields.
            transaction.update(
              bookingRef,
              {
                'bookingStatus': 'Rejected',
                'rejectedAt': FieldValue.serverTimestamp(),
                'lecturerResponseAt': FieldValue.serverTimestamp(),
                'rejectionReason':
                    'The lecturer declined this consultation request.',
              },
            );

            // Release the reserved slot.
            transaction.update(
              availabilityRef,
              {
                'status': 'available',
                'bookingId': FieldValue.delete(),
                'bookedAt': FieldValue.delete(),
              },
            );

            // NEW: Notify the student that the booking was rejected.
            transaction.set(
              notificationRef,
              {
                'notificationID': notificationRef.id,
                'bookingID': bookingId,
                'userID': studentId,
                'notificationTitle': 'Booking Rejected',
                'notificationMessage':
                    'Your consultation request with $lecturerName has been rejected. Please choose another available consultation slot.',
                'notificationType': 'Booking Update',
                'notificationStatus': 'Unread',
                'createdDate': FieldValue.serverTimestamp(),
              },
            );
          }
        },
      );

      if (!mounted) return;

      _showMessage(
        newStatus == 'Approved'
            ? 'Booking approved. Student notification created.'
            : 'Booking rejected. Student notification created and availability released.',
      );

    } on BookingActionException catch (error) {

      _showMessage(
        error.message,
        isError: true,
      );

    } on FirebaseException catch (error) {

      if (error.code == 'permission-denied') {
        _showMessage(
          'Permission denied. Check the bookings, availability and notifications Firestore Rules.',
          isError: true,
        );
      } else if (error.code == 'unavailable') {
        _showMessage(
          'Unable to connect to Firebase. Check your internet connection.',
          isError: true,
        );
      } else {
        _showMessage(
          'Booking update failed: ${error.message ?? error.code}',
          isError: true,
        );
      }

    } catch (error) {

      _showMessage(
        'Something went wrong: $error',
        isError: true,
      );

    } finally {

      if (mounted) {
        setState(() {
          _processingBookings.remove(bookingId);
        });
      }
    }
  }

  // ===================================================
  // UPDATED 13: PAGE HEADER
  // ===================================================

  Widget _pageHeader() {
    return Row(
      children: [

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                'Booking Requests',

                style: TextStyle(
                  color: requestDarkBlue,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),

              SizedBox(height: 6),

              Text(
                'Review and manage consultation requests submitted by your students.',

                style: TextStyle(
                  color: requestSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: requestBorder,
            ),
          ),

          child: const Row(
            children: [

              Icon(
                Icons.event_note_rounded,
                color: requestBlue,
                size: 16,
              ),

              SizedBox(width: 7),

              Text(
                'LECTURER',

                style: TextStyle(
                  color: requestBlue,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================================================
  // UPDATED 14: WELCOME BANNER
  // ===================================================

  Widget _welcomeBanner() {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            requestBlue,
            requestDarkBlue,
          ],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: requestBlue.withValues(alpha: 0.13),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: LayoutBuilder(
        builder: (context, constraints) {

          final isCompact = constraints.maxWidth < 500;

          final content = Column(
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
                  'STUDENT CONSULTATIONS',

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
                'Stay on Top of Your Requests',

                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 20 : 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 9),

              const Text(
                'Review incoming consultation requests, check student information and respond to pending bookings.',

                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
            ],
          );

          if (isCompact) {
            return content;
          }

          return Row(
            children: [

              Expanded(
                flex: 5,
                child: content,
              ),

              const SizedBox(width: 20),

              Expanded(
                flex: 2,
                child: Center(
                  child: Container(
                    height: 105,
                    width: 105,

                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.assignment_turned_in_rounded,
                      color: Colors.white,
                      size: 51,
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
  // UPDATED 15: STATISTICS CARD
  // ===================================================

  Widget _statCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {

    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),

        border: Border.all(
          color: requestBorder,
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
                    color: requestSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value.toString(),
                  style: const TextStyle(
                    color: requestDarkBlue,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: requestSecondary,
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
  // UPDATED 16: STATISTICS SECTION
  // ===================================================

  Widget _statisticsSection(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {

    final total = docs.length;

    final pending = docs.where((doc) {
      return _getString(
        doc.data(),
        'bookingStatus',
        fallback: '',
      ).toLowerCase() == 'pending';
    }).length;

    final approved = docs.where((doc) {
      return _getString(
        doc.data(),
        'bookingStatus',
        fallback: '',
      ).toLowerCase() == 'approved';
    }).length;

    final rejected = docs.where((doc) {
      return _getString(
        doc.data(),
        'bookingStatus',
        fallback: '',
      ).toLowerCase() == 'rejected';
    }).length;

    return LayoutBuilder(
      builder: (context, constraints) {

        final columns = constraints.maxWidth >= 900
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
                title: 'Total Requests',
                value: total,
                icon: Icons.event_note_rounded,
                color: requestBlue,
                subtitle: 'All booking requests',
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Pending',
                value: pending,
                icon: Icons.pending_actions_rounded,
                color: requestOrange,
                subtitle: 'Awaiting your response',
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Approved',
                value: approved,
                icon: Icons.check_circle_outline_rounded,
                color: requestGreen,
                subtitle: 'Confirmed requests',
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Rejected',
                value: rejected,
                icon: Icons.cancel_outlined,
                color: requestRed,
                subtitle: 'Declined requests',
              ),
            ),
          ],
        );
      },
    );
  }

  // ===================================================
  // UPDATED 17: SECTION HEADING
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
            color: requestDarkBlue,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          subtitle,
          style: const TextStyle(
            color: requestSecondary,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ===================================================
  // UPDATED 18: SEARCH BAR
  // ===================================================

  Widget _searchBar() {

    return TextField(
      controller: _searchController,

      onChanged: (value) {
        setState(() {
          _searchQuery = value.trim().toLowerCase();
        });
      },

      decoration: InputDecoration(
        hintText: 'Search student, email or purpose...',

        prefixIcon: const Icon(
          Icons.search_rounded,
          color: requestSecondary,
        ),

        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',

                icon: const Icon(
                  Icons.close_rounded,
                ),

                onPressed: () {
                  _searchController.clear();

                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,

        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: requestBorder,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: requestBorder,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: requestBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ===================================================
  // UPDATED 19: FILTER CHIPS
  // ===================================================

  Widget _filterSection() {

    return Wrap(
      spacing: 9,
      runSpacing: 9,

      children: _filters.map((filter) {

        final selected = _selectedFilter == filter;

        return ChoiceChip(
          label: Text(filter),

          selected: selected,

          onSelected: (value) {
            setState(() {
              _selectedFilter = filter;
            });
          },

          selectedColor: requestBlue,

          backgroundColor: Colors.white,

          side: BorderSide(
            color: selected
                ? requestBlue
                : requestBorder,
          ),

          labelStyle: TextStyle(
            color: selected
                ? Colors.white
                : requestSecondary,

            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),

          showCheckmark: false,
        );
      }).toList(),
    );
  }

  // ===================================================
  // UPDATED 20: FILTER AND SORT BOOKINGS
  // ===================================================

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _filterBookings(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {

    final filtered = docs.where((doc) {

      final data = doc.data();

      final status = _getString(
        data,
        'bookingStatus',
        fallback: '',
      ).toLowerCase();

      final studentName = _getString(
        data,
        'studentName',
        fallback: '',
      ).toLowerCase();

      final studentEmail = _getString(
        data,
        'studentEmail',
        fallback: '',
      ).toLowerCase();

      final purpose = _getString(
        data,
        'consultationPurpose',
        fallback: '',
      ).toLowerCase();

      final matchesFilter =
          _selectedFilter == 'All' ||
          status == _selectedFilter.toLowerCase();

      final matchesSearch =
          _searchQuery.isEmpty ||
          studentName.contains(_searchQuery) ||
          studentEmail.contains(_searchQuery) ||
          purpose.contains(_searchQuery);

      return matchesFilter && matchesSearch;

    }).toList();

    // Sort newest request first.

    filtered.sort((a, b) {

      final aDate =
          _getDate(a.data()['createdAt']) ??
          _getDate(a.data()['startAt']) ??
          DateTime(2000);

      final bDate =
          _getDate(b.data()['createdAt']) ??
          _getDate(b.data()['startAt']) ??
          DateTime(2000);

      return bDate.compareTo(aDate);
    });

    return filtered;
  }

  // ===================================================
  // UPDATED 21: INFORMATION ROW
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
              color: requestBlue,
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
                    color: requestSecondary,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 5),

                SelectableText(
                  value,
                  style: const TextStyle(
                    color: requestDarkBlue,
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
  // UPDATED 22: BOOKING DETAILS BOTTOM SHEET
  // ===================================================

  void _showBookingDetails(
    BuildContext context,
    Map<String, dynamic> data,
    String documentId,
  ) {

    final studentName = _getString(
      data,
      'studentName',
      fallback: 'Student',
    );

    final studentEmail = _getString(
      data,
      'studentEmail',
    );

    final lecturerName = _getString(
      data,
      'lecturerName',
    );

    final purpose = _getString(
      data,
      'consultationPurpose',
    );

    final status = _getString(
      data,
      'bookingStatus',
      fallback: 'Pending',
    );

    final isPending =
        status.toLowerCase() == 'pending';

    final isProcessing =
        _processingBookings.contains(documentId);

    showModalBottomSheet(
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
                        color: requestBorder,
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
                          'Booking Details',

                          style: TextStyle(
                            color: requestDarkBlue,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      _statusBadge(status),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // STUDENT INFORMATION

                  const Text(
                    'STUDENT INFORMATION',

                    style: TextStyle(
                      color: requestSecondary,
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
                    color: requestBorder,
                  ),

                  const SizedBox(height: 18),

                  // CONSULTATION INFORMATION

                  const Text(
                    'CONSULTATION INFORMATION',

                    style: TextStyle(
                      color: requestSecondary,
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
                    label: 'Consultation Date',
                    value: _formatDate(
                      sheetContext,
                      data['startAt'],
                    ),
                  ),

                  _infoRow(
                    icon: Icons.access_time_rounded,
                    label: 'Consultation Time',

                    value:
                        '${_formatTime(sheetContext, data['startAt'])} – '
                        '${_formatTime(sheetContext, data['endAt'])}',
                  ),

                  _infoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Request Submitted',
                    value: _formatDateTime(
                      sheetContext,
                      data['createdAt'],
                    ),
                  ),

                  const SizedBox(height: 5),

                  // CONSULTATION PURPOSE

                  const Text(
                    'CONSULTATION PURPOSE',

                    style: TextStyle(
                      color: requestSecondary,
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
                      color: requestBackground,
                      borderRadius: BorderRadius.circular(13),

                      border: Border.all(
                        color: requestBorder,
                      ),
                    ),

                    child: Text(
                      purpose,

                      style: const TextStyle(
                        color: requestDarkBlue,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // BOOKING ID

                  SelectableText(
                    'Booking ID: $documentId',

                    style: const TextStyle(
                      color: requestSecondary,
                      fontSize: 10,
                    ),
                  ),

                  const SizedBox(height: 23),

                  // PENDING ACTIONS

                  if (isPending) ...[

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),

                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Icon(
                            Icons.info_outline_rounded,
                            color: requestBlue,
                            size: 18,
                          ),

                          SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              'Review the student request carefully before approving or rejecting it.',

                              style: TextStyle(
                                color: requestDarkBlue,
                                fontSize: 11,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [

                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: isProcessing
                                ? null
                                : () {

                                    Navigator.pop(sheetContext);

                                    _confirmResponse(
                                      bookingId: documentId,
                                      newStatus: 'Rejected',
                                    );
                                  },

                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                            ),

                            label: const Text('Reject'),

                            style: OutlinedButton.styleFrom(
                              foregroundColor: requestRed,

                              side: const BorderSide(
                                color: requestRed,
                              ),

                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: FilledButton.icon(
                            onPressed: isProcessing
                                ? null
                                : () {

                                    Navigator.pop(sheetContext);

                                    _confirmResponse(
                                      bookingId: documentId,
                                      newStatus: 'Approved',
                                    );
                                  },

                            icon: const Icon(
                              Icons.check_rounded,
                              size: 18,
                            ),

                            label: const Text('Approve'),

                            style: FilledButton.styleFrom(
                              backgroundColor: requestGreen,
                              foregroundColor: Colors.white,

                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (!isPending)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),

                      decoration: BoxDecoration(
                        color: requestBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Text(
                        'This request has already been $status. No further action is required.',

                        textAlign: TextAlign.center,

                        style: const TextStyle(
                          color: requestSecondary,
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,

                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                      },

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
  // UPDATED 23: BOOKING REQUEST CARD
  // ===================================================

  Widget _bookingCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {

    final data = doc.data();

    final studentName = _getString(
      data,
      'studentName',
      fallback: 'Student',
    );

    final studentEmail = _getString(
      data,
      'studentEmail',
    );

    final purpose = _getString(
      data,
      'consultationPurpose',
    );

    final status = _getString(
      data,
      'bookingStatus',
      fallback: 'Pending',
    );

    final startAt = data['startAt'];
    final endAt = data['endAt'];

    final initial = studentName.isNotEmpty
        ? studentName[0].toUpperCase()
        : 'S';

    final isProcessing =
        _processingBookings.contains(doc.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),

        border: Border.all(
          color: requestBorder,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // STUDENT INFORMATION

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              CircleAvatar(
                radius: 23,

                backgroundColor: const Color(0xFFDBEAFE),

                child: Text(
                  initial,

                  style: const TextStyle(
                    color: requestBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      studentName,

                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: requestDarkBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      studentEmail,

                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: requestSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 7),

              _statusBadge(status),
            ],
          ),

          const SizedBox(height: 17),

          const Divider(
            color: requestBorder,
            height: 1,
          ),

          const SizedBox(height: 16),

          // DATE

          Row(
            children: [

              const Icon(
                Icons.calendar_month_outlined,
                color: requestBlue,
                size: 18,
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  _formatDate(context, startAt),

                  style: const TextStyle(
                    color: requestDarkBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // TIME

          Row(
            children: [

              const Icon(
                Icons.access_time_rounded,
                color: requestBlue,
                size: 18,
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  '${_formatTime(context, startAt)} – '
                  '${_formatTime(context, endAt)}',

                  style: const TextStyle(
                    color: requestDarkBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // PURPOSE

          const Text(
            'CONSULTATION PURPOSE',

            style: TextStyle(
              color: requestSecondary,
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
              color: requestSecondary,
              fontSize: 11,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 16),

          // VIEW DETAILS

          SizedBox(
            width: double.infinity,

            child: OutlinedButton.icon(
              onPressed: isProcessing
                  ? null
                  : () {
                      _showBookingDetails(
                        context,
                        data,
                        doc.id,
                      );
                    },

              icon: isProcessing
                  ? const SizedBox(
                      height: 17,
                      width: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.visibility_outlined,
                      size: 18,
                    ),

              label: Text(
                isProcessing
                    ? 'Processing...'
                    : 'View Booking Details',
              ),

              style: OutlinedButton.styleFrom(
                foregroundColor: requestBlue,

                side: const BorderSide(
                  color: requestBlue,
                ),

                padding: const EdgeInsets.symmetric(
                  vertical: 12,
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
  // UPDATED 24: EMPTY STATE
  // ===================================================

  Widget _emptyState() {

    final title = _searchQuery.isNotEmpty
        ? 'No Matching Requests'
        : _selectedFilter == 'All'
            ? 'No Booking Requests Yet'
            : 'No $_selectedFilter Requests';

    final description = _searchQuery.isNotEmpty
        ? 'Try another search keyword or change the selected filter.'
        : 'New consultation requests submitted by students will appear here.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: requestBorder,
        ),
      ),

      child: Column(
        children: [

          Container(
            height: 65,
            width: 65,

            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(18),
            ),

            child: const Icon(
              Icons.event_busy_rounded,
              color: requestSecondary,
              size: 32,
            ),
          ),

          const SizedBox(height: 17),

          Text(
            title,

            style: const TextStyle(
              color: requestDarkBlue,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            description,

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: requestSecondary,
              fontSize: 12,
              height: 1.7,
            ),
          ),

          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 15),

            TextButton.icon(
              onPressed: () {
                _searchController.clear();

                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'All';
                });
              },

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Clear Search and Filters'),
            ),
          ],
        ],
      ),
    );
  }

  // ===================================================
  // UPDATED 25: ERROR STATE
  // ===================================================

  Widget _errorState(Object? error) {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),

        border: Border.all(
          color: requestBorder,
        ),
      ),

      child: Column(
        children: [

          const Icon(
            Icons.cloud_off_outlined,
            color: requestRed,
            size: 42,
          ),

          const SizedBox(height: 14),

          const Text(
            'Unable to Load Booking Requests',

            style: TextStyle(
              color: requestDarkBlue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Please check your internet connection and Firestore security rules.',

            textAlign: TextAlign.center,

            style: TextStyle(
              color: requestSecondary,
              fontSize: 12,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 14),

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
    );
  }

  // ===================================================
  // UPDATED 26: BOOKING REQUEST LIST
  // ===================================================

  Widget _requestList(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {

    final filteredDocs = _filterBookings(docs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // SECTION HEADER

        Row(
          children: [

            const Expanded(
              child: Text(
                'Incoming Requests',

                style: TextStyle(
                  color: requestDarkBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Text(
              '${filteredDocs.length} requests',

              style: const TextStyle(
                color: requestSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        const Text(
          'Search, filter and review student consultation requests.',

          style: TextStyle(
            color: requestSecondary,
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 17),

        // SEARCH

        _searchBar(),

        const SizedBox(height: 15),

        // FILTER

        _filterSection(),

        const SizedBox(height: 21),

        // BOOKING CARDS

        if (filteredDocs.isEmpty)

          _emptyState()

        else

          LayoutBuilder(
            builder: (context, constraints) {

              final columns =
                  constraints.maxWidth >= 950 ? 2 : 1;

              final cardWidth = (
                constraints.maxWidth -
                (columns - 1) * 14
              ) / columns;

              return Wrap(
                spacing: 14,
                runSpacing: 0,

                children: filteredDocs.map((doc) {

                  return SizedBox(
                    width: cardWidth,

                    child: _bookingCard(
                      context,
                      doc,
                    ),
                  );

                }).toList(),
              );
            },
          ),
      ],
    );
  }

  // ===================================================
  // UPDATED 27: MAIN PAGE CONTENT
  // ===================================================

  Widget _buildPageContent(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),

      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1200,
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
                'Booking Overview',
                'Monitor your student consultation requests.',
              ),

              const SizedBox(height: 15),

              _statisticsSection(docs),

              const SizedBox(height: 31),

              // REQUEST LIST

              _requestList(
                context,
                docs,
              ),

              const SizedBox(height: 32),

              // FOOTER

              const Center(
                child: Text(
                  'ConsultEasy • Academic Consultation System',

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: requestSecondary,
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
  // UPDATED 28: MAIN BUILD
  // ===================================================

  @override
  Widget build(BuildContext context) {

    final user = _currentUser;

    if (user == null) {

      return Scaffold(
        backgroundColor: requestBackground,

        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Icon(
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: requestBlue,
                ),

                const SizedBox(height: 16),

                const Text(
                  'Please sign in to access booking requests.',

                  style: TextStyle(
                    color: requestDarkBlue,
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

    return Scaffold(
      backgroundColor: requestBackground,

      // -----------------------------------------------
      // APP BAR
      // -----------------------------------------------

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: requestDarkBlue,
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
                color: requestBlue,
                size: 23,
              ),
            ),

            const SizedBox(width: 11),

            const Text(
              'ConsultEasy',

              style: TextStyle(
                color: requestDarkBlue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),

        actions: [

          IconButton(
            tooltip: 'Refresh booking requests',

            onPressed: () {
              setState(() {});
            },

            icon: const Icon(
              Icons.refresh_rounded,
              color: requestDarkBlue,
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
                      color: requestBlue,
                      size: 15,
                    ),

                    SizedBox(width: 5),

                    Text(
                      'LECTURER',

                      style: TextStyle(
                        color: requestBlue,
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
      // BODY: FIRESTORE STREAM
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),

              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 800,
                  ),

                  child: _errorState(snapshot.error),
                ),
              ),
            );
          }

          // LOADING

          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              snapshot.data == null) {

            return const Center(
              child: CircularProgressIndicator(
                color: requestBlue,
              ),
            );
          }

          // DOCUMENTS

          final docs = [
            ...?snapshot.data?.docs,
          ];

          // SORT NEWEST REQUEST FIRST

          docs.sort((a, b) {

            final aDate =
                _getDate(a.data()['createdAt']) ??
                _getDate(a.data()['startAt']) ??
                DateTime(2000);

            final bDate =
                _getDate(b.data()['createdAt']) ??
                _getDate(b.data()['startAt']) ??
                DateTime(2000);

            return bDate.compareTo(aDate);
          });

          return _buildPageContent(docs);
        },
      ),
    );
  }
}
