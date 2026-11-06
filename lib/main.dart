import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/student_dashboard.dart';
import 'screens/lecturer_dashboard.dart';
import 'screens/manage_availability.dart';
import 'screens/available_consultations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ConsultEasyApp());
}

class ConsultEasyApp extends StatelessWidget {
  const ConsultEasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConsultEasy',
      debugShowCheckedModeBanner: false,

      // Application Theme
      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color(0xFFF4F7FC),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Colors.white,
          centerTitle: false,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF2563EB),
              width: 1.5,
            ),
          ),
        ),
      ),

      // Initial Page
      initialRoute: '/login',

      // Application Navigation
      routes: {
        '/login': (context) => const LoginPage(),

        '/register': (context) => const RegisterPage(),

        '/student-dashboard': (context) =>
            const StudentDashboardPage(),

        '/lecturer-dashboard': (context) =>
            const LecturerDashboardPage(),

        '/manage-availability': (context) =>
            const ManageAvailabilityPage(),

        '/available-consultations': (context) =>
            const AvailableConsultationsPage(),
      },
    );
  }
}