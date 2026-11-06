
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const Color bookingBlue = Color(0xFF2563EB);
const Color bookingDarkBlue = Color(0xFF172554);
const Color bookingBackground = Color(0xFFF4F7FC);

class BookingFlowException implements Exception {
  final String message;

  const BookingFlowException(this.message);

  @override
  String toString() => message;
}

class BookingConsultationPage extends StatefulWidget {
  final String availabilityId;
  final String lecturerId;
  final String lecturerName;
  final DateTime startAt;
  final DateTime endAt;

  const BookingConsultationPage({
    super.key,
    required this.availabilityId,
    required this.lecturerId,
    required this.lecturerName,
    required this.startAt,
    required this.endAt,
  });

  @override
  State<BookingConsultationPage> createState() =>
      _BookingConsultationPageState();
}

class _BookingConsultationPageState
    extends State<BookingConsultationPage> {

  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  String _dateLabel(DateTime date) {
    return MaterialLocalizations.of(context)
        .formatMediumDate(date);
  }

  String _timeLabel(DateTime date) {
    return TimeOfDay.fromDateTime(date).format(context);
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? Colors.red.shade700
              : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // =====================================================
  // UPDATED 1: STUDENT BOOKING + NOTIFICATION INTEGRATION
  // =====================================================

  Future<void> _submitBooking() async {

    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Please sign in before making a booking.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {

      final firestore = FirebaseFirestore.instance;

      // -----------------------------------------------
      // STEP 1: GET STUDENT PROFILE
      // -----------------------------------------------

      final profileSnapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!profileSnapshot.exists) {
        throw const BookingFlowException(
          'Student profile could not be found.',
        );
      }

      final profile = profileSnapshot.data()!;

      if (profile['role'] != 'Student') {
        throw const BookingFlowException(
          'Only students can make consultation bookings.',
        );
      }

      final studentName =
          (profile['fullName'] as String?)?.trim() ?? '';

      final studentEmail =
          (profile['email'] as String?)?.trim() ?? '';

      if (studentName.isEmpty || studentEmail.isEmpty) {
        throw const BookingFlowException(
          'Your profile is incomplete. Please update your details.',
        );
      }

      // -----------------------------------------------
      // STEP 2: PREPARE FIRESTORE DOCUMENT REFERENCES
      // -----------------------------------------------

      final availabilityRef = firestore
          .collection('availability')
          .doc(widget.availabilityId);

      final bookingRef = firestore
          .collection('bookings')
          .doc();

      // NEW: Notification document reference.
      final notificationRef = firestore
          .collection('notifications')
          .doc();

      final purpose = _purposeController.text.trim();

      // -----------------------------------------------
      // STEP 3: FIRESTORE TRANSACTION
      // BOOKING + AVAILABILITY + NOTIFICATION
      // -----------------------------------------------

      await firestore.runTransaction<void>(
        (transaction) async {

          // -------------------------------------------
          // STEP 3A: READ AVAILABILITY
          // -------------------------------------------

          final slotSnapshot =
              await transaction.get(availabilityRef);

          if (!slotSnapshot.exists) {
            throw const BookingFlowException(
              'This consultation slot no longer exists.',
            );
          }

          final slot = slotSnapshot.data()!;

          if (slot['status'] != 'available') {
            throw const BookingFlowException(
              'Sorry, this slot has already been booked. Please choose another slot.',
            );
          }

          if (slot['lecturerId'] is! String ||
              slot['lecturerName'] is! String ||
              slot['startAt'] is! Timestamp ||
              slot['endAt'] is! Timestamp) {

            throw const BookingFlowException(
              'This consultation slot has incomplete information.',
            );
          }

          final actualStart =
              (slot['startAt'] as Timestamp).toDate();

          final actualEnd =
              (slot['endAt'] as Timestamp).toDate();

          if (!actualStart.isAfter(DateTime.now()) ||
              !actualEnd.isAfter(actualStart)) {

            throw const BookingFlowException(
              'This consultation time is no longer valid.',
            );
          }

          if (slot['lecturerId'] != widget.lecturerId) {
            throw const BookingFlowException(
              'Lecturer information has changed. Please refresh.',
            );
          }

          // -------------------------------------------
          // STEP 3B: CREATE BOOKING DOCUMENT
          // -------------------------------------------

          transaction.set(bookingRef, {

            'bookingId': bookingRef.id,
            'availabilityId': availabilityRef.id,

            'studentId': user.uid,
            'studentName': studentName,
            'studentEmail': studentEmail,

            'lecturerId': slot['lecturerId'],
            'lecturerName': slot['lecturerName'],

            'startAt': slot['startAt'],
            'endAt': slot['endAt'],

            'consultationPurpose': purpose,

            'bookingStatus': 'Pending',

            'createdAt': FieldValue.serverTimestamp(),
          });

          // -------------------------------------------
          // STEP 3C: RESERVE AVAILABILITY SLOT
          // -------------------------------------------

          transaction.update(availabilityRef, {

            'status': 'booked',

            'bookingId': bookingRef.id,

            'bookedAt': FieldValue.serverTimestamp(),
          });

          // -------------------------------------------
          // UPDATED 2: CREATE LECTURER NOTIFICATION
          // -------------------------------------------

          transaction.set(notificationRef, {

            // Notification identification.
            'notificationID': notificationRef.id,

            // Related booking identification.
            // Note: This field uses bookingID
            // to match the Firestore Rules.

            'bookingID': bookingRef.id,

            // Lecturer receives this notification.
            'userID': slot['lecturerId'],

            // Notification information.
            'notificationTitle': 'New Consultation Request',

            'notificationMessage':
                '$studentName has submitted a new consultation request. Purpose: $purpose',

            'notificationType': 'Booking Update',

            // Initial notification status.
            'notificationStatus': 'Unread',

            // Firestore server timestamp.
            'createdDate': FieldValue.serverTimestamp(),
          });

          // -------------------------------------------
          // ALL THREE OPERATIONS ARE ATOMIC
          // -------------------------------------------

        },
      );

      // -----------------------------------------------
      // STEP 4: SUCCESS
      // -----------------------------------------------

      if (!mounted) return;

      Navigator.of(context).pop(true);

    } on BookingFlowException catch (error) {

      _showMessage(error.message);

    } on FirebaseException catch (error) {

      if (error.code == 'permission-denied') {

        _showMessage(
          'Firebase permission denied. Please check Firestore Rules.',
        );

      } else if (error.code == 'unavailable') {

        _showMessage(
          'Unable to connect to Firebase. Check your internet connection.',
        );

      } else {

        _showMessage(
          'Booking failed (${error.code}): ${error.message}',
        );
      }

    } catch (error) {

      _showMessage(
        'Unable to submit booking. $error',
      );

    } finally {

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // =====================================================
  // UPDATED 3: CONSULTATION DETAIL ROW
  // =====================================================

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            color: bookingBlue,
            size: 21,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    color: bookingDarkBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // UPDATED 4: PAGE UI
  // =====================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: bookingBackground,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: bookingDarkBlue,
        elevation: 0,

        title: const Text(
          'Book Consultation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                // HEADER

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        bookingBlue,
                        bookingDarkBlue,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),

                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Icon(
                        Icons.event_available_rounded,
                        color: Colors.white,
                        size: 34,
                      ),

                      SizedBox(height: 12),

                      Text(
                        'Confirm Your Consultation',

                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 6),

                      Text(
                        'Review your selected consultation slot and tell your lecturer what you would like to discuss.',

                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // CONSULTATION DETAILS

                const Text(
                  'Consultation Details',

                  style: TextStyle(
                    color: bookingDarkBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                Card(
                  color: Colors.white,
                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),

                    side: const BorderSide(
                      color: Color(0xFFE2E8F0),
                    ),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(18),

                    child: Column(
                      children: [

                        _detailRow(
                          Icons.person_outline_rounded,
                          'Lecturer',
                          widget.lecturerName,
                        ),

                        _detailRow(
                          Icons.calendar_month_outlined,
                          'Date',
                          _dateLabel(widget.startAt),
                        ),

                        _detailRow(
                          Icons.access_time_rounded,
                          'Time',
                          '${_timeLabel(widget.startAt)} – ${_timeLabel(widget.endAt)}',
                        ),

                        Row(
                          children: [

                            const Icon(
                              Icons.info_outline_rounded,
                              color: bookingBlue,
                              size: 21,
                            ),

                            const SizedBox(width: 12),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),

                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(20),
                              ),

                              child: const Text(
                                'PENDING APPROVAL',

                                style: TextStyle(
                                  color: Color(0xFF92400E),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // CONSULTATION PURPOSE

                const Text(
                  'Consultation Purpose',

                  style: TextStyle(
                    color: bookingDarkBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Briefly explain the topic or issue you want to discuss with the lecturer.',

                  style: TextStyle(
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _purposeController,

                  minLines: 4,
                  maxLines: 6,
                  maxLength: 500,

                  textCapitalization:
                      TextCapitalization.sentences,

                  decoration: const InputDecoration(
                    hintText:
                        'Example: I need help understanding Chapter 3 topics.',

                    alignLabelWithHint: true,

                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 70),

                      child: Icon(
                        Icons.edit_note_rounded,
                      ),
                    ),
                  ),

                  validator: (value) {

                    final text = value?.trim() ?? '';

                    if (text.isEmpty) {
                      return 'Please enter your consultation purpose.';
                    }

                    if (text.length > 500) {
                      return 'Purpose must not exceed 500 characters.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // SUBMIT BOOKING BUTTON

                SizedBox(
                  width: double.infinity,

                  child: FilledButton.icon(

                    onPressed: _isSubmitting
                        ? null
                        : _submitBooking,

                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,

                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.send_rounded,
                          ),

                    label: Text(
                      _isSubmitting
                          ? 'Submitting...'
                          : 'Submit Booking Request',
                    ),

                    style: FilledButton.styleFrom(
                      backgroundColor: bookingBlue,
                      foregroundColor: Colors.white,

                      padding: const EdgeInsets.symmetric(
                        vertical: 17,
                      ),

                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                const Center(
                  child: Text(
                    'Your request will remain pending until the lecturer responds.',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      height: 1.5,
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
}
