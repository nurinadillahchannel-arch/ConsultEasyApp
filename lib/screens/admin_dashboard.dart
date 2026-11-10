import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'report_management_page.dart';

const Color adminBlue = Color(0xFF2563EB);
const Color adminDarkBlue = Color(0xFF172554);
const Color adminBackground = Color(0xFFF4F7FC);
const Color adminSecondary = Color(0xFF64748B);

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in again.')),
      );
    }

    return Scaffold(
      backgroundColor: adminBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: adminDarkBlue,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.school_rounded, color: adminBlue),
            SizedBox(width: 10),
            Text(
              'ConsultEasy Admin',
              style: TextStyle(
                color: adminDarkBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Unable to load admin profile: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: adminBlue),
            );
          }

          final profile = snapshot.data!.data() ?? {};
          final role = (profile['role'] ?? '').toString();
          final name = (profile['fullName'] ?? 'Administrator').toString();

          if (role != 'Administrator') {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Access denied. This page is only available to Administrators.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView(
                padding: const EdgeInsets.all(28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [adminBlue, adminDarkBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Welcome back, $name!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Monitor ConsultEasy activities and generate system reports.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Administration',
                    style: TextStyle(
                      color: adminDarkBlue,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.assessment_outlined,
                              color: adminBlue,
                              size: 27,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Reports & Analytics',
                            style: TextStyle(
                              color: adminDarkBlue,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Generate booking, availability and user reports. Filter records by date and export them as PDF or Excel.',
                            style: TextStyle(
                              color: adminSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ReportManagementPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('Open Reports & Analytics'),
                            style: FilledButton.styleFrom(
                              backgroundColor: adminBlue,
                              minimumSize: const Size(230, 48),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
