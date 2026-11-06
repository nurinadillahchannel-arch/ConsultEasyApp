
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =====================================================
// CONSULTEASY DESIGN SYSTEM
// =====================================================

const Color availabilityBlue = Color(0xFF2563EB);
const Color availabilityDarkBlue = Color(0xFF172554);
const Color availabilityBackground = Color(0xFFF4F7FC);
const Color availabilitySecondaryText = Color(0xFF64748B);
const Color availabilityBorder = Color(0xFFE2E8F0);

const Color availabilityGreen = Color(0xFF059669);
const Color availabilityPurple = Color(0xFF7C3AED);
const Color availabilityOrange = Color(0xFFD97706);

// =====================================================
// MANAGE AVAILABILITY PAGE
// =====================================================

class ManageAvailabilityPage extends StatefulWidget {
  const ManageAvailabilityPage({super.key});

  @override
  State<ManageAvailabilityPage> createState() =>
      _ManageAvailabilityPageState();
}

class _ManageAvailabilityPageState
    extends State<ManageAvailabilityPage> {

  // ===================================================
  // UPDATED 1: FORM STATE
  // ===================================================

  DateTime _selectedDate =
      DateTime.now().add(const Duration(days: 1));

  TimeOfDay _startTime =
      const TimeOfDay(hour: 9, minute: 0);

  TimeOfDay _endTime =
      const TimeOfDay(hour: 10, minute: 0);

  bool _isSaving = false;

  // ===================================================
  // UPDATED 2: DATE AND TIME HELPERS
  // ===================================================

  DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  DateTime _combineDateAndTime(
    DateTime date,
    TimeOfDay time,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  // ===================================================
  // UPDATED 3: MESSAGE HANDLER
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
              : availabilityGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ===================================================
  // UPDATED 4: DATE PICKER
  // ===================================================

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    final today = _dateOnly(now);

    final picked = await showDatePicker(
      context: context,

      initialDate: _selectedDate.isBefore(today)
          ? today
          : _selectedDate,

      firstDate: today,

      lastDate: today.add(
        const Duration(days: 365),
      ),

      helpText: 'Select consultation date',

      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: availabilityBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: availabilityDarkBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = _dateOnly(picked);
      });
    }
  }

  // ===================================================
  // UPDATED 5: TIME PICKER
  // ===================================================

  Future<void> _chooseTime({
    required bool isStart,
  }) async {

    final picked = await showTimePicker(
      context: context,

      initialTime: isStart
          ? _startTime
          : _endTime,

      helpText: isStart
          ? 'Select start time'
          : 'Select end time',
    );

    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  // ===================================================
  // UPDATED 6: ADD AVAILABILITY TO FIREBASE
  // ===================================================

  Future<void> _addAvailability() async {

    if (_isSaving) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Your session has expired. Please log in again.',
        isError: true,
      );

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }

      return;
    }

    final start = _combineDateAndTime(
      _selectedDate,
      _startTime,
    );

    final end = _combineDateAndTime(
      _selectedDate,
      _endTime,
    );

    // Validate start time.

    if (!start.isAfter(DateTime.now())) {
      _showMessage(
        'Consultation start time must be in the future.',
        isError: true,
      );
      return;
    }

    // Validate end time.

    if (!end.isAfter(start)) {
      _showMessage(
        'End time must be later than start time.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {

      // -----------------------------------------------
      // Verify lecturer profile.
      // -----------------------------------------------

      final profileSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (!profileSnapshot.exists) {
        _showMessage(
          'Lecturer profile not found.',
          isError: true,
        );
        return;
      }

      final profile = profileSnapshot.data();

      if (profile == null ||
          profile['role'] != 'Lecturer') {

        _showMessage(
          'Only registered lecturers can create availability.',
          isError: true,
        );
        return;
      }

      final lecturerName =
          (profile['fullName'] as String?)?.trim() ?? '';

      if (lecturerName.isEmpty) {
        _showMessage(
          'Your lecturer profile has no registered name.',
          isError: true,
        );
        return;
      }

      // -----------------------------------------------
      // Check existing availability.
      // Prevent overlapping consultation slots.
      // -----------------------------------------------

      final existingSlots =
          await FirebaseFirestore.instance
              .collection('availability')
              .where(
                'lecturerId',
                isEqualTo: user.uid,
              )
              .get();

      for (final document in existingSlots.docs) {

        final data = document.data();

        if (data['startAt'] is! Timestamp ||
            data['endAt'] is! Timestamp) {
          continue;
        }

        if (data['status'] == 'cancelled') {
          continue;
        }

        final existingStart =
            (data['startAt'] as Timestamp).toDate();

        final existingEnd =
            (data['endAt'] as Timestamp).toDate();

        final overlaps =
            start.isBefore(existingEnd) &&
            end.isAfter(existingStart);

        if (overlaps) {
          _showMessage(
            'This time overlaps with an existing slot.',
            isError: true,
          );
          return;
        }
      }

      // -----------------------------------------------
      // Save availability to Firestore.
      // -----------------------------------------------

      await FirebaseFirestore.instance
          .collection('availability')
          .add({

        'lecturerId': user.uid,

        'lecturerName': lecturerName,

        'startAt': Timestamp.fromDate(start),

        'endAt': Timestamp.fromDate(end),

        'status': 'available',

        'createdAt': FieldValue.serverTimestamp(),

      });

      _showMessage(
        'Availability added successfully!',
      );

      // -----------------------------------------------
      // Reset form after successful submission.
      // -----------------------------------------------

      if (mounted) {
        setState(() {
          _selectedDate = DateTime.now().add(
            const Duration(days: 1),
          );

          _startTime =
              const TimeOfDay(hour: 9, minute: 0);

          _endTime =
              const TimeOfDay(hour: 10, minute: 0);
        });
      }

    } on FirebaseException catch (e) {

      if (e.code == 'permission-denied') {
        _showMessage(
          'Permission denied. Please check Firestore Rules.',
          isError: true,
        );
      } else {
        _showMessage(
          'Unable to save availability: ${e.message ?? e.code}',
          isError: true,
        );
      }

    } catch (e) {

      _showMessage(
        'Something went wrong. Please try again.',
        isError: true,
      );

    } finally {

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ===================================================
  // UPDATED 7: DELETE AVAILABILITY
  // ===================================================

  Future<void> _deleteAvailability(
    String documentId,
  ) async {

    final confirmed = await showDialog<bool>(
      context: context,

      builder: (dialogContext) {

        return AlertDialog(
          backgroundColor: Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          title: const Text(
            'Delete Availability?',
            style: TextStyle(
              color: availabilityDarkBlue,
              fontWeight: FontWeight.bold,
            ),
          ),

          content: const Text(
            'Are you sure you want to delete this consultation slot? '
            'This action cannot be undone.',
            style: TextStyle(
              color: availabilitySecondaryText,
              height: 1.5,
            ),
          ),

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
                backgroundColor: Colors.red.shade600,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please log in again.',
        isError: true,
      );
      return;
    }

    try {

      final slotReference = FirebaseFirestore.instance
          .collection('availability')
          .doc(documentId);

      // Check latest slot information before deletion.

      final slotSnapshot = await slotReference.get();

      if (!mounted) return;

      if (!slotSnapshot.exists) {
        _showMessage(
          'This availability slot no longer exists.',
          isError: true,
        );
        return;
      }

      final slotData = slotSnapshot.data();

      if (slotData == null ||
          slotData['lecturerId'] != user.uid ||
          slotData['status'] != 'available') {

        _showMessage(
          'Only your available slots can be deleted.',
          isError: true,
        );
        return;
      }

      await slotReference.delete();

      _showMessage(
        'Availability deleted successfully.',
      );

    } on FirebaseException catch (e) {

      _showMessage(
        e.code == 'permission-denied'
            ? 'You cannot delete this slot.'
            : 'Unable to delete availability.',
        isError: true,
      );

    } catch (e) {

      _showMessage(
        'Something went wrong while deleting the slot.',
        isError: true,
      );
    }
  }

  // ===================================================
  // UPDATED 8: SECTION HEADING
  // ===================================================

  Widget _sectionHeading(
    String title,
    String subtitle, {
    Widget? trailing,
  }) {

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style: const TextStyle(
                  color: availabilityDarkBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                subtitle,
                style: const TextStyle(
                  color: availabilitySecondaryText,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        if (trailing != null) trailing,
      ],
    );
  }

  // ===================================================
  // UPDATED 9: DATE AND TIME PICKER BUTTON
  // ===================================================

  Widget _pickerButton({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onPressed,
  }) {

    return OutlinedButton(
      onPressed: _isSaving ? null : onPressed,

      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 17,
        ),

        alignment: Alignment.centerLeft,

        foregroundColor: availabilityDarkBlue,

        side: const BorderSide(
          color: availabilityBorder,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),

      child: Row(
        children: [

          Container(
            height: 39,
            width: 39,

            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(11),
            ),

            child: Icon(
              icon,
              color: availabilityBlue,
              size: 20,
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
                    color: availabilitySecondaryText,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  value,
                  style: const TextStyle(
                    color: availabilityDarkBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: availabilitySecondaryText,
            size: 21,
          ),
        ],
      ),
    );
  }

  // ===================================================
  // UPDATED 10: CREATE AVAILABILITY FORM
  // ===================================================

  Widget _buildCreateForm() {

    return Container(
      padding: const EdgeInsets.all(23),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        border: Border.all(
          color: availabilityBorder,
        ),

        boxShadow: [
          BoxShadow(
            color: availabilityDarkBlue.withValues(alpha: 0.025),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // FORM HEADER

          Row(
            children: [

              Container(
                height: 45,
                width: 45,

                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(13),
                ),

                child: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: availabilityBlue,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      'Create Time Slot',
                      style: TextStyle(
                        color: availabilityDarkBlue,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'New consultation session',
                      style: TextStyle(
                        color: availabilitySecondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(
            color: availabilityBorder,
          ),

          const SizedBox(height: 18),

          const Text(
            'CONSULTATION DATE',
            style: TextStyle(
              color: availabilitySecondaryText,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 10),

          _pickerButton(
            label: 'Select date',

            value: MaterialLocalizations.of(context)
                .formatMediumDate(_selectedDate),

            icon: Icons.calendar_month_rounded,

            onPressed: _chooseDate,
          ),

          const SizedBox(height: 23),

          const Text(
            'CONSULTATION TIME',
            style: TextStyle(
              color: availabilitySecondaryText,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 10),

          LayoutBuilder(
            builder: (context, constraints) {

              final startButton = _pickerButton(
                label: 'Start time',
                value: _startTime.format(context),
                icon: Icons.access_time_rounded,
                onPressed: () =>
                    _chooseTime(isStart: true),
              );

              final endButton = _pickerButton(
                label: 'End time',
                value: _endTime.format(context),
                icon: Icons.schedule_rounded,
                onPressed: () =>
                    _chooseTime(isStart: false),
              );

              if (constraints.maxWidth < 390) {
                return Column(
                  children: [
                    startButton,
                    const SizedBox(height: 12),
                    endButton,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: startButton),
                  const SizedBox(width: 12),
                  Expanded(child: endButton),
                ],
              );
            },
          ),

          const SizedBox(height: 19),

          // INFORMATION

          Container(
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
                  color: availabilityBlue,
                  size: 18,
                ),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Students will be able to view and request '
                    'consultation sessions during your available time.',
                    style: TextStyle(
                      color: availabilityDarkBlue,
                      fontSize: 11,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 23),

          // SUBMIT BUTTON

          SizedBox(
            width: double.infinity,
            height: 52,

            child: FilledButton.icon(
              onPressed: _isSaving
                  ? null
                  : _addAvailability,

              style: FilledButton.styleFrom(
                backgroundColor: availabilityBlue,
                foregroundColor: Colors.white,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),

              icon: _isSaving
                  ? const SizedBox(
                      height: 19,
                      width: 19,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.add_rounded,
                      size: 21,
                    ),

              label: Text(
                _isSaving
                    ? 'Saving Availability...'
                    : 'Add Availability',

                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // UPDATED 11: STATISTICS CARD
  // ===================================================

  Widget _statCard({
    required String title,
    required int value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color background,
  }) {

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),

        border: Border.all(
          color: availabilityBorder,
        ),
      ),

      child: Row(
        children: [

          Container(
            height: 46,
            width: 46,

            decoration: BoxDecoration(
              color: background,
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
                    color: availabilitySecondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value.toString(),
                  style: const TextStyle(
                    color: availabilityDarkBlue,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: availabilitySecondaryText,
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
  // UPDATED 12: STATISTICS SECTION
  // ===================================================

  Widget _buildStatistics(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {

    final availableCount = documents.where((doc) {
      return doc.data()['status'] == 'available';
    }).length;

    final bookedCount = documents.where((doc) {
      return doc.data()['status'] == 'booked';
    }).length;

    return LayoutBuilder(
      builder: (context, constraints) {

        final columns = constraints.maxWidth >= 750
            ? 3
            : constraints.maxWidth >= 450
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
                title: 'Total Slots',
                value: documents.length,
                subtitle: 'All saved time slots',
                icon: Icons.calendar_month_rounded,
                color: availabilityBlue,
                background: const Color(0xFFEFF6FF),
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Available Slots',
                value: availableCount,
                subtitle: 'Open for student requests',
                icon: Icons.event_available_rounded,
                color: availabilityGreen,
                background: const Color(0xFFD1FAE5),
              ),
            ),

            SizedBox(
              width: cardWidth,
              child: _statCard(
                title: 'Booked Slots',
                value: bookedCount,
                subtitle: 'Reserved consultation slots',
                icon: Icons.event_busy_rounded,
                color: availabilityOrange,
                background: const Color(0xFFFEF3C7),
              ),
            ),
          ],
        );
      },
    );
  }

  // ===================================================
  // UPDATED 13: AVAILABILITY STATUS DESIGN
  // ===================================================

  Color _statusColor(String status) {

    switch (status.toLowerCase()) {

      case 'available':
        return availabilityGreen;

      case 'booked':
        return availabilityOrange;

      case 'cancelled':
        return Colors.red.shade600;

      default:
        return availabilitySecondaryText;
    }
  }

  Color _statusBackground(String status) {

    switch (status.toLowerCase()) {

      case 'available':
        return const Color(0xFFDCFCE7);

      case 'booked':
        return const Color(0xFFFEF3C7);

      case 'cancelled':
        return const Color(0xFFFEE2E2);

      default:
        return const Color(0xFFF1F5F9);
    }
  }

  // ===================================================
  // UPDATED 14: AVAILABILITY CARD
  // ===================================================

  Widget _buildAvailabilityCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {

    final data = document.data();

    if (data['startAt'] is! Timestamp ||
        data['endAt'] is! Timestamp) {
      return const SizedBox.shrink();
    }

    final start =
        (data['startAt'] as Timestamp).toDate();

    final end =
        (data['endAt'] as Timestamp).toDate();

    final status =
        data['status'] as String? ?? 'unknown';

    final canDelete =
        status == 'available' &&
        start.isAfter(DateTime.now());

    final dateLabel =
        MaterialLocalizations.of(context)
            .formatMediumDate(start);

    final startLabel =
        TimeOfDay.fromDateTime(start).format(context);

    final endLabel =
        TimeOfDay.fromDateTime(end).format(context);

    final statusColor = _statusColor(status);

    final statusBackground =
        _statusBackground(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),

        border: Border.all(
          color: availabilityBorder,
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // DATE ICON

          Container(
            height: 51,
            width: 51,

            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),

            child: const Icon(
              Icons.event_available_rounded,
              color: availabilityBlue,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          // SLOT DETAILS

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: availabilityDarkBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  children: [

                    const Icon(
                      Icons.access_time_rounded,
                      color: availabilitySecondaryText,
                      size: 15,
                    ),

                    const SizedBox(width: 6),

                    Flexible(
                      child: Text(
                        '$startLabel – $endLabel',
                        style: const TextStyle(
                          color: availabilitySecondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Text(
                    status.toUpperCase(),

                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // DELETE ACTION

          if (canDelete)
            IconButton(
              tooltip: 'Delete availability',

              onPressed: () {
                _deleteAvailability(document.id);
              },

              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
              ),

              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade600,
                size: 21,
              ),
            ),
        ],
      ),
    );
  }

  // ===================================================
  // UPDATED 15: EMPTY AVAILABILITY STATE
  // ===================================================

  Widget _buildEmptyState() {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: availabilityBorder,
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
              Icons.calendar_month_outlined,
              size: 31,
              color: availabilitySecondaryText,
            ),
          ),

          const SizedBox(height: 17),

          const Text(
            'No Availability Yet',
            style: TextStyle(
              color: availabilityDarkBlue,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'You have not created any consultation slots. '
            'Create your first availability to allow students '
            'to request a consultation with you.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: availabilitySecondaryText,
              fontSize: 12,
              height: 1.7,
            ),
          ),

          const SizedBox(height: 10),

          const Icon(
            Icons.arrow_upward_rounded,
            color: availabilityBlue,
            size: 22,
          ),
        ],
      ),
    );
  }

  // ===================================================
  // UPDATED 16: ERROR STATE
  // ===================================================

  Widget _buildErrorState() {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(23),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),

        border: Border.all(
          color: availabilityBorder,
        ),
      ),

      child: const Column(
        children: [

          Icon(
            Icons.cloud_off_outlined,
            size: 38,
            color: Colors.red,
          ),

          SizedBox(height: 13),

          Text(
            'Unable to Load Availability',
            style: TextStyle(
              color: availabilityDarkBlue,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),

          SizedBox(height: 7),

          Text(
            'Please check your internet connection '
            'and Firestore permissions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: availabilitySecondaryText,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // UPDATED 17: AVAILABILITY LIST
  // ===================================================

  Widget _buildAvailabilityList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {

    if (documents.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: documents.map((document) {
        return _buildAvailabilityCard(document);
      }).toList(),
    );
  }

  // ===================================================
  // UPDATED 18: MAIN PAGE HEADER
  // ===================================================

  Widget _buildPageHeader() {

    return Row(
      children: [

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                'Manage Availability',
                style: TextStyle(
                  color: availabilityDarkBlue,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),

              SizedBox(height: 6),

              Text(
                'Manage your academic consultation schedule.',
                style: TextStyle(
                  color: availabilitySecondaryText,
                  fontSize: 12,
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
              color: availabilityBorder,
            ),
          ),

          child: Row(
            children: [

              const Icon(
                Icons.calendar_today_rounded,
                color: availabilityBlue,
                size: 15,
              ),

              const SizedBox(width: 8),

              Text(
                MaterialLocalizations.of(context)
                    .formatMediumDate(DateTime.now()),

                style: const TextStyle(
                  color: availabilityDarkBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================================================
  // UPDATED 19: WELCOME BANNER
  // ===================================================

  Widget _buildWelcomeBanner() {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            availabilityBlue,
            availabilityDarkBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(21),

        boxShadow: [
          BoxShadow(
            color: availabilityBlue.withValues(alpha: 0.13),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: LayoutBuilder(
        builder: (context, constraints) {

          final isCompact = constraints.maxWidth < 500;

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
                  'LECTURER PORTAL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Your Consultation Schedule',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 21 : 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 9),

              const Text(
                'Create and manage your available time slots. '
                'Give students the opportunity to schedule '
                'academic consultations with you.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
            ],
          );

          if (isCompact) {
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
                      color: Colors.white.withValues(alpha: 0.12),
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
  // UPDATED 20: MAIN FIRESTORE STREAM
  // ===================================================

  Widget _buildAvailabilityContent(User user) {

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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 800,
                ),
                child: _buildErrorState(),
              ),
            ),
          );
        }

        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            snapshot.data == null) {

          return const Center(
            child: CircularProgressIndicator(
              color: availabilityBlue,
            ),
          );
        }

        final documents = [
          ...?snapshot.data?.docs,
        ];

        // Sort upcoming slots first.
        // Past slots are displayed afterwards.

        final now = DateTime.now();

        documents.sort((a, b) {

          final aValue = a.data()['startAt'];
          final bValue = b.data()['startAt'];

          final aStart = aValue is Timestamp
              ? aValue.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);

          final bStart = bValue is Timestamp
              ? bValue.toDate()
              : DateTime.fromMillisecondsSinceEpoch(0);

          final aUpcoming = aStart.isAfter(now);
          final bUpcoming = bStart.isAfter(now);

          if (aUpcoming != bUpcoming) {
            return aUpcoming ? -1 : 1;
          }

          if (aUpcoming) {
            return aStart.compareTo(bStart);
          }

          return bStart.compareTo(aStart);
        });

        // -----------------------------------------------
        // MAIN RESPONSIVE CONTENT
        // -----------------------------------------------

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

                  _buildPageHeader(),

                  const SizedBox(height: 23),

                  // WELCOME BANNER

                  _buildWelcomeBanner(),

                  const SizedBox(height: 27),

                  // STATISTICS

                  _sectionHeading(
                    'Availability Overview',
                    'Monitor your consultation slot activities.',
                  ),

                  const SizedBox(height: 15),

                  _buildStatistics(documents),

                  const SizedBox(height: 30),

                  // CREATE FORM + AVAILABILITY LIST

                  LayoutBuilder(
                    builder: (context, constraints) {

                      if (constraints.maxWidth >= 950) {

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            SizedBox(
                              width: 395,
                              child: _buildCreateForm(),
                            ),

                            const SizedBox(width: 23),

                            Expanded(
                              child: _buildAvailabilitySection(
                                documents,
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          _buildCreateForm(),

                          const SizedBox(height: 30),

                          _buildAvailabilitySection(
                            documents,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 35),

                  // FOOTER

                  const Center(
                    child: Text(
                      'ConsultEasy • Academic Consultation System',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: availabilitySecondaryText,
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
    );
  }

  // ===================================================
  // UPDATED 21: AVAILABILITY SECTION
  // ===================================================

  Widget _buildAvailabilitySection(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        _sectionHeading(
          'My Availability',
          'View and manage your saved consultation slots.',
        ),

        const SizedBox(height: 17),

        _buildAvailabilityList(documents),
      ],
    );
  }

  // ===================================================
  // UPDATED 22: MAIN PAGE BUILD
  // ===================================================

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: availabilityBackground,

      // -----------------------------------------------
      // APP BAR
      // -----------------------------------------------

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: availabilityDarkBlue,
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
                color: availabilityBlue,
                size: 23,
              ),
            ),

            const SizedBox(width: 11),

            const Text(
              'ConsultEasy',
              style: TextStyle(
                color: availabilityDarkBlue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),

        actions: [

          Padding(
            padding: const EdgeInsets.only(right: 18),
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
                      Icons.calendar_month_rounded,
                      color: availabilityBlue,
                      size: 15,
                    ),

                    SizedBox(width: 6),

                    Text(
                      'LECTURER',
                      style: TextStyle(
                        color: availabilityBlue,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.7,
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
      // BODY
      // -----------------------------------------------

      body: user == null

          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 45,
                      color: availabilityBlue,
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      'Please sign in to continue.',
                      style: TextStyle(
                        color: availabilityDarkBlue,
                        fontWeight: FontWeight.bold,
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
            )

          : _buildAvailabilityContent(user),
    );
  }
}