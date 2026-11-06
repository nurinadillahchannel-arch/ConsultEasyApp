
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const Color lecturerPrimaryBlue = Color(0xFF2563EB);
const Color lecturerDarkBlue = Color(0xFF172554);
const Color lecturerSecondaryText = Color(0xFF64748B);
const Color lecturerBorderColor = Color(0xFFE2E8F0);

class _LecturerSlotPreview {
  final DateTime startAt;
  final DateTime endAt;

  const _LecturerSlotPreview({
    required this.startAt,
    required this.endAt,
  });
}

class _LecturerSummary {
  final String id;
  final String name;
  final List<_LecturerSlotPreview> slots;

  const _LecturerSummary({
    required this.id,
    required this.name,
    required this.slots,
  });
}

class StudentLecturersPage extends StatefulWidget {
  final void Function(String? lecturerId, String? lecturerName)
      onViewSlots;

  const StudentLecturersPage({
    super.key,
    required this.onViewSlots,
  });

  @override
  State<StudentLecturersPage> createState() =>
      _StudentLecturersPageState();
}

class _StudentLecturersPageState
    extends State<StudentLecturersPage> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

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

  List<_LecturerSummary> _buildLecturerSummaries(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    final Map<String, _LecturerSummary> grouped = {};
    final now = DateTime.now();

    for (final document in documents) {
      final data = document.data();

      final lecturerId =
          (data['lecturerId'] ?? '').toString().trim();

      final lecturerName =
          (data['lecturerName'] ?? '').toString().trim();

      final startValue = data['startAt'];
      final endValue = data['endAt'];

      if (lecturerId.isEmpty ||
          lecturerName.isEmpty ||
          startValue is! Timestamp ||
          endValue is! Timestamp) {
        continue;
      }

      final startAt = startValue.toDate();
      final endAt = endValue.toDate();

      if (!startAt.isAfter(now) ||
          !endAt.isAfter(startAt)) {
        continue;
      }

      grouped.putIfAbsent(
        lecturerId,
        () => _LecturerSummary(
          id: lecturerId,
          name: lecturerName,
          slots: <_LecturerSlotPreview>[],
        ),
      );

      grouped[lecturerId]!.slots.add(
        _LecturerSlotPreview(
          startAt: startAt,
          endAt: endAt,
        ),
      );
    }

    final summaries = grouped.values.toList();

    for (final lecturer in summaries) {
      lecturer.slots.sort(
        (a, b) => a.startAt.compareTo(b.startAt),
      );
    }

    summaries.sort(
      (a, b) => a.name
          .toLowerCase()
          .compareTo(b.name.toLowerCase()),
    );

    return summaries;
  }

  // =========================================
  // PAGE HEADING
  // =========================================

  Widget _pageHeading() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lecturers',
            style: TextStyle(
              color: lecturerDarkBlue,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Discover lecturers who currently offer consultation sessions.',
            style: TextStyle(
              color: lecturerSecondaryText,
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
        hintText: 'Search lecturer name...',
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
            color: lecturerBorderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: lecturerBorderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(
            color: lecturerPrimaryBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // =========================================
  // LECTURER CARD
  // =========================================

  Widget _lecturerCard(_LecturerSummary lecturer) {
    final nextSlot = lecturer.slots.first;

    final dateLabel =
        MaterialLocalizations.of(context)
            .formatMediumDate(nextSlot.startAt);

    final timeLabel =
        MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(nextSlot.startAt),
    );

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: lecturerBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFFDBEAFE),
                child: Text(
                  lecturer.name.isEmpty
                      ? 'L'
                      : lecturer.name[0].toUpperCase(),
                  style: const TextStyle(
                    color: lecturerPrimaryBlue,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  lecturer.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: lecturerDarkBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${lecturer.slots.length} available '
              '${lecturer.slots.length == 1 ? 'slot' : 'slots'}',
              style: const TextStyle(
                color: Color(0xFF166534),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'Next available session',
            style: TextStyle(
              color: lecturerSecondaryText,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: lecturerPrimaryBlue,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '$dateLabel • $timeLabel',
                  style: const TextStyle(
                    color: lecturerDarkBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                widget.onViewSlots(
                  lecturer.id,
                  lecturer.name,
                );
              },
              icon: const Icon(
                Icons.calendar_month_rounded,
                size: 18,
              ),
              label: const Text('View Available Slots'),
              style: FilledButton.styleFrom(
                backgroundColor: lecturerPrimaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
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

  // =========================================
  // EMPTY STATE
  // =========================================

  Widget _emptyState({
    required String title,
    required String message,
    IconData icon = Icons.people_outline_rounded,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: lecturerBorderColor,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 45,
            color: const Color(0xFF94A3B8),
          ),

          const SizedBox(height: 13),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: lecturerDarkBlue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: lecturerSecondaryText,
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

              _searchField(),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    widget.onViewSlots(null, null);
                  },
                  icon: const Icon(
                    Icons.event_available_outlined,
                  ),
                  label: const Text(
                    'Browse All Available Consultation Slots',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: lecturerPrimaryBlue,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    side: const BorderSide(
                      color: lecturerPrimaryBlue,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: _availabilityStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _emptyState(
                      title: 'Unable to load lecturers',
                      message:
                          'Please check your internet connection '
                          'and Firestore Rules, then try again.',
                      icon: Icons.cloud_off_outlined,
                    );
                  }

                  if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      snapshot.data == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(35),
                        child: CircularProgressIndicator(
                          color: lecturerPrimaryBlue,
                        ),
                      ),
                    );
                  }

                  final lecturers =
                      _buildLecturerSummaries(
                    snapshot.data?.docs ?? [],
                  ).where((lecturer) {
                    return lecturer.name
                        .toLowerCase()
                        .contains(_searchQuery);
                  }).toList();

                  if (lecturers.isEmpty) {
                    return _emptyState(
                      title: _searchQuery.isEmpty
                          ? 'No lecturers available yet'
                          : 'No matching lecturers found',
                      message: _searchQuery.isEmpty
                          ? 'Lecturers will appear here after '
                              'they publish upcoming consultation slots.'
                          : 'Try another lecturer name or '
                              'clear your search.',
                    );
                  }

                  return Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${lecturers.length} '
                        '${lecturers.length == 1 ? 'lecturer' : 'lecturers'} found',
                        style: const TextStyle(
                          color: lecturerSecondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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
                            itemCount: lecturers.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 245,
                            ),
                            itemBuilder: (context, index) {
                              return _lecturerCard(
                                lecturers[index],
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
