
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'booking_consultations.dart';

// =============================================
// CONSULTEASY COLORS
// =============================================

const Color availablePrimaryBlue = Color(0xFF2563EB);
const Color availableDarkBlue = Color(0xFF172554);
const Color availableSecondaryText = Color(0xFF64748B);
const Color availableBorderColor = Color(0xFFE2E8F0);

// =============================================
// AVAILABLE CONSULTATIONS PAGE
// =============================================

class StudentAvailableConsultationsPage extends StatefulWidget {
  final String? lecturerId;
  final String? lecturerName;
  final VoidCallback? onClearLecturerFilter;

  const StudentAvailableConsultationsPage({
    super.key,
    this.lecturerId,
    this.lecturerName,
    this.onClearLecturerFilter,
  });

  @override
  State<StudentAvailableConsultationsPage> createState() =>
      _StudentAvailableConsultationsPageState();
}

class _StudentAvailableConsultationsPageState
    extends State<StudentAvailableConsultationsPage> {

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  // =========================================
  // FIRESTORE AVAILABILITY STREAM
  // =========================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      get _availabilityStream {
    return FirebaseFirestore.instance
        .collection('availability')
        .where('status', isEqualTo: 'available')
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =========================================
  // DATE CONVERSION
  // =========================================

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  // =========================================
  // FILTER UPCOMING SLOTS
  // =========================================

  List<QueryDocumentSnapshot<Map<String, dynamic>>>
      _futureSlots(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final now = DateTime.now();

    final slots = documents.where((document) {
      final data = document.data();

      final startAt = _readDate(data['startAt']);
      final endAt = _readDate(data['endAt']);

      final lecturerId =
          (data['lecturerId'] ?? '').toString();

      final lecturerName =
          (data['lecturerName'] ?? '').toString();

      if (startAt == null ||
          endAt == null ||
          !startAt.isAfter(now)) {
        return false;
      }

      if (!endAt.isAfter(startAt) ||
          lecturerId.isEmpty) {
        return false;
      }

      if (widget.lecturerId != null &&
          widget.lecturerId!.isNotEmpty &&
          lecturerId != widget.lecturerId) {
        return false;
      }

      if (_searchQuery.isNotEmpty &&
          !lecturerName
              .toLowerCase()
              .contains(_searchQuery)) {
        return false;
      }

      return true;
    }).toList();

    slots.sort((a, b) {
      final aDate = _readDate(a.data()['startAt'])!;
      final bDate = _readDate(b.data()['startAt'])!;

      return aDate.compareTo(bDate);
    });

    return slots;
  }

  // =========================================
  // PAGE HEADING
  // =========================================

  Widget _pageHeading() {
    final isFiltered = widget.lecturerId != null &&
        widget.lecturerId!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Consultations',
            style: TextStyle(
              color: availableDarkBlue,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            isFiltered
                ? 'Available sessions offered by '
                    '${widget.lecturerName ?? 'the selected lecturer'}.'
                : 'Browse upcoming consultation sessions '
                    'and choose a suitable time.',
            style: const TextStyle(
              color: availableSecondaryText,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
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
          _searchQuery = value.trim().toLowerCase();
        });
      },

      decoration: InputDecoration(
        hintText: 'Search by lecturer name...',
        prefixIcon: const Icon(Icons.search_rounded),

        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
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
            color: availableBorderColor,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: availableBorderColor,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: availablePrimaryBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // =========================================
  // SLOT DETAIL ROW
  // =========================================

  Widget _detailRow({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: availablePrimaryBlue,
          size: 18,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: availableSecondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================
  // BOOKING NAVIGATION
  // =========================================

  Future<void> _openBookingForm({
    required String availabilityId,
    required String lecturerId,
    required String lecturerName,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BookingConsultationPage(
          availabilityId: availabilityId,
          lecturerId: lecturerId,
          lecturerName: lecturerName,
          startAt: startAt,
          endAt: endAt,
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Booking request submitted successfully. '
              'Status: Pending.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // =========================================
  // CONSULTATION SLOT CARD
  // =========================================

  Widget _slotCard(
    QueryDocumentSnapshot<Map<String, dynamic>> slot,
  ) {
    final data = slot.data();

    final lecturerName =
        (data['lecturerName'] ?? 'Lecturer').toString();

    final lecturerId =
        (data['lecturerId'] ?? '').toString();

    final startAt = _readDate(data['startAt']);
    final endAt = _readDate(data['endAt']);

    if (startAt == null || endAt == null) {
      return const SizedBox.shrink();
    }

    final dateLabel =
        MaterialLocalizations.of(context)
            .formatMediumDate(startAt);

    final startLabel =
        MaterialLocalizations.of(context)
            .formatTimeOfDay(
      TimeOfDay.fromDateTime(startAt),
    );

    final endLabel =
        MaterialLocalizations.of(context)
            .formatTimeOfDay(
      TimeOfDay.fromDateTime(endAt),
    );

    return Container(
      padding: const EdgeInsets.all(19),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: availableBorderColor,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // LECTURER INFORMATION
          Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFDBEAFE),

                child: Text(
                  lecturerName.isEmpty
                      ? 'L'
                      : lecturerName[0].toUpperCase(),

                  style: const TextStyle(
                    color: availablePrimaryBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  lecturerName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: availableDarkBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),

                child: const Text(
                  'AVAILABLE',
                  style: TextStyle(
                    color: Color(0xFF166534),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // DATE
          _detailRow(
            icon: Icons.calendar_month_outlined,
            text: dateLabel,
          ),

          const SizedBox(height: 11),

          // TIME
          _detailRow(
            icon: Icons.access_time_rounded,
            text: '$startLabel – $endLabel',
          ),

          const Spacer(),

          // BOOK BUTTON
          SizedBox(
            width: double.infinity,

            child: FilledButton.icon(
              onPressed: lecturerId.isEmpty
                  ? null
                  : () => _openBookingForm(
                        availabilityId: slot.id,
                        lecturerId: lecturerId,
                        lecturerName: lecturerName,
                        startAt: startAt,
                        endAt: endAt,
                      ),

              icon: const Icon(
                Icons.event_available_rounded,
                size: 18,
              ),

              label: const Text(
                'Book Consultation',
              ),

              style: FilledButton.styleFrom(
                backgroundColor: availablePrimaryBlue,
                foregroundColor: Colors.white,

                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),

          if (lecturerId.isEmpty) ...[
            const SizedBox(height: 7),

            const Text(
              'Booking is unavailable because this slot '
              'has no lecturer ID.',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================
  // EMPTY STATE
  // =========================================

  Widget _emptyState({
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: availableBorderColor,
        ),
      ),

      child: Column(
        children: [
          const Icon(
            Icons.event_busy_outlined,
            size: 45,
            color: Color(0xFF94A3B8),
          ),

          const SizedBox(height: 13),

          Text(
            title,
            textAlign: TextAlign.center,

            style: const TextStyle(
              color: availableDarkBlue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            message,
            textAlign: TextAlign.center,

            style: const TextStyle(
              color: availableSecondaryText,
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
    final isLecturerFiltered =
        widget.lecturerId != null &&
        widget.lecturerId!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),

      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1350,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              _pageHeading(),

              // FILTERED LECTURER
              if (isLecturerFiltered &&
                  widget.onClearLecturerFilter != null) ...[

                Align(
                  alignment: Alignment.centerLeft,

                  child: TextButton.icon(
                    onPressed: widget.onClearLecturerFilter,

                    icon: const Icon(
                      Icons.arrow_back_rounded,
                    ),

                    label: const Text(
                      'View all lecturers’ slots',
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],

              // SEARCH
              _searchField(),

              const SizedBox(height: 22),

              // FIRESTORE DATA
              StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: _availabilityStream,

                builder: (context, snapshot) {

                  if (snapshot.hasError) {
                    return _emptyState(
                      title: 'Unable to load consultation slots',
                      message:
                          'Please check your connection and '
                          'Firestore Rules, then refresh the page.',
                    );
                  }

                  if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      snapshot.data == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(35),

                        child: CircularProgressIndicator(
                          color: availablePrimaryBlue,
                        ),
                      ),
                    );
                  }

                  final slots = _futureSlots(
                    snapshot.data?.docs ?? [],
                  );

                  // EMPTY SLOTS
                  if (slots.isEmpty) {
                    return _emptyState(
                      title: isLecturerFiltered
                          ? 'No upcoming slots for this lecturer'
                          : 'No available consultation slots',

                      message:
                          'There are currently no upcoming sessions '
                          'matching your selection. Please check again later.',
                    );
                  }

                  // DISPLAY SLOTS
                  return Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [

                      Text(
                        '${slots.length} available '
                        '${slots.length == 1 ? 'slot' : 'slots'}',

                        style: const TextStyle(
                          color: availableDarkBlue,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 14),

                      LayoutBuilder(
                        builder: (context, constraints) {

                          final columns =
                              constraints.maxWidth >= 1100
                                  ? 3
                                  : constraints.maxWidth >= 700
                                      ? 2
                                      : 1;

                          return GridView.builder(
                            shrinkWrap: true,

                            physics:
                                const NeverScrollableScrollPhysics(),

                            itemCount: slots.length,

                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 255,
                            ),

                            itemBuilder: (context, index) {
                              return _slotCard(
                                slots[index],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
