import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'booking_consultations.dart';

const Color studentBlue = Color(0xFF2563EB);
const Color studentDarkBlue = Color(0xFF172554);
const Color studentBackground = Color(0xFFF4F7FC);

class AvailableConsultationsPage extends StatelessWidget {
  const AvailableConsultationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: studentBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: studentDarkBlue,
        elevation: 0,
        title: const Text(
          'Available Consultations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: user == null
          ? const Center(
              child: Text('Please sign in to continue.'),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('availability')
                  .where('status', isEqualTo: 'available')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Unable to load consultation slots. '
                        'Please check your connection and '
                        'Firestore security rules.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: studentBlue,
                    ),
                  );
                }

                final now = DateTime.now();

                final slots = (snapshot.data?.docs ?? [])
                    .where((doc) {
                  final data = doc.data();
                  final startAt = data['startAt'];

                  return startAt is Timestamp &&
                      startAt.toDate().isAfter(now) &&
                      data['endAt'] is Timestamp;
                }).toList();

                slots.sort((a, b) {
                  final aStart =
                      (a.data()['startAt'] as Timestamp)
                          .toDate();

                  final bStart =
                      (b.data()['startAt'] as Timestamp)
                          .toDate();

                  return aStart.compareTo(bStart);
                });

                if (slots.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.event_busy_rounded,
                            size: 64,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Available Slots',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: studentDarkBlue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'There are currently no upcoming '
                            'consultation slots. Please check again later.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            studentBlue,
                            studentDarkBlue,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Find Your Consultation Slot',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Explore upcoming consultation times '
                            'offered by your lecturers.',
                            style: TextStyle(
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      '${slots.length} available '
                      '${slots.length == 1 ? 'slot' : 'slots'}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: studentDarkBlue,
                      ),
                    ),

                    const SizedBox(height: 14),

                    ...slots.map((slot) {
                      final data = slot.data();

                      final lecturerName =
                          data['lecturerName'] as String? ??
                              'Lecturer';

                      final start =
                          (data['startAt'] as Timestamp)
                              .toDate();

                      final end =
                          (data['endAt'] as Timestamp)
                              .toDate();

                      final dateLabel =
                          MaterialLocalizations.of(context)
                              .formatMediumDate(start);

                      final startLabel =
                          TimeOfDay.fromDateTime(start)
                              .format(context);

                      final endLabel =
                          TimeOfDay.fromDateTime(end)
                              .format(context);

                      return Card(
                        color: Colors.white,
                        elevation: 0,
                        margin: const EdgeInsets.only(
                          bottom: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                          side: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFEFF6FF,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: studentBlue,
                                      size: 28,
                                    ),
                                  ),

                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Text(
                                      lecturerName,
                                      style: const TextStyle(
                                        color: studentDarkBlue,
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),

                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    color: studentBlue,
                                    size: 20,
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Text(
                                      dateLabel,
                                      style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: studentBlue,
                                    size: 20,
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Text(
                                      '$startLabel – $endLabel',
                                      style: const TextStyle(
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'AVAILABLE',
                                  style: TextStyle(
                                    color: Color(0xFF166534),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed:
                                      (data['lecturerId'] is String &&
                                              (data['lecturerId']
                                                      as String)
                                                  .isNotEmpty)
                                          ? () async {
                                              final result =
                                                  await Navigator.of(
                                                          context)
                                                      .push<bool>(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      BookingConsultationPage(
                                                    availabilityId:
                                                        slot.id,
                                                    lecturerId:
                                                        data['lecturerId']
                                                            as String,
                                                    lecturerName:
                                                        lecturerName,
                                                    startAt: start,
                                                    endAt: end,
                                                  ),
                                                ),
                                              );

                                              if (result == true &&
                                                  context.mounted) {
                                                ScaffoldMessenger.of(
                                                        context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Booking request submitted successfully. Status: Pending.',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                    behavior:
                                                        SnackBarBehavior
                                                            .floating,
                                                  ),
                                                );
                                              }
                                            }
                                          : null,

                                  icon: const Icon(
                                    Icons.event_available_rounded,
                                  ),

                                  label: const Text(
                                    'Book Consultation',
                                  ),

                                  style: FilledButton.styleFrom(
                                    backgroundColor: studentBlue,
                                    foregroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}