
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =============================================
// CONSULTEASY THEME
// =============================================

const Color profileBlue = Color(0xFF2563EB);
const Color profileDarkBlue = Color(0xFF172554);
const Color profileBackground = Color(0xFFF4F7FC);
const Color profileSecondary = Color(0xFF64748B);
const Color profileBorder = Color(0xFFE2E8F0);

const Color profileGreen = Color(0xFF059669);
const Color profileOrange = Color(0xFFD97706);
const Color profileRed = Color(0xFFDC2626);

// =============================================
// LECTURER PROFILE PAGE
// =============================================

class LecturerProfilePage extends StatefulWidget {
  const LecturerProfilePage({super.key});

  @override
  State<LecturerProfilePage> createState() =>
      _LecturerProfilePageState();
}

class _LecturerProfilePageState
    extends State<LecturerProfilePage> {

  // ===========================================
  // VARIABLES
  // ===========================================

  User? get _currentUser =>
      FirebaseAuth.instance.currentUser;

  // ===========================================
  // FORMAT DATE
  // ===========================================

  String _formatDate(DateTime? date) {

    if (date == null) {
      return 'Not available';
    }

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ===========================================
  // GET USER INITIALS
  // ===========================================

  String _getInitials(String name) {

    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'L';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'
        .toUpperCase();
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
  // COMING SOON ACTION
  // ===========================================

  void _comingSoon(String feature) {

    _showMessage(
      '$feature will be connected during the functionality integration stage.',
    );
  }

  // ===========================================
  // PAGE HEADER
  // ===========================================

  Widget _pageHeader() {

    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          'My Profile',

          style: TextStyle(
            color: profileDarkBlue,
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 7),

        Text(
          'Manage your personal information and account settings.',

          style: TextStyle(
            color: profileSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),

      ],
    );
  }

  // ===========================================
  // PROFILE HEADER CARD
  // ===========================================

  Widget _profileHeaderCard({
    required String name,
    required String email,
    required bool emailVerified,
  }) {

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF1E40AF),
          ],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: profileBlue.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),

      child: LayoutBuilder(
        builder: (context, constraints) {

          final compact = constraints.maxWidth < 450;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [

                  CircleAvatar(
                    radius: 39,

                    backgroundColor: Colors.white,

                    child: Text(
                      _getInitials(name),

                      style: const TextStyle(
                        color: profileBlue,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 17),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        Text(
                          name,

                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          email,

                          style: const TextStyle(
                            color: Color(0xFFDBEAFE),
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 9),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),

                          child: const Text(
                            'LECTURER ACCOUNT',

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),

                ],
              ),

              const SizedBox(height: 22),

              Container(
                padding: const EdgeInsets.all(13),

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Row(
                  children: [

                    Icon(
                      emailVerified
                          ? Icons.verified_rounded
                          : Icons.info_outline_rounded,

                      color: Colors.white,
                      size: 20,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        emailVerified
                            ? 'Your email address is verified.'
                            : 'Your email address is not verified.',

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    Icon(
                      emailVerified
                          ? Icons.check_circle
                          : Icons.warning_amber_rounded,

                      color: Colors.white,
                      size: 18,
                    ),

                  ],
                ),
              ),

            ],
          );
        },
      ),
    );
  }

  // ===========================================
  // SECTION CARD
  // ===========================================

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(21),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: profileBorder,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Container(
                width: 37,
                height: 37,

                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),

                child: Icon(
                  icon,
                  color: profileBlue,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,

                  style: const TextStyle(
                    color: profileDarkBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            ],
          ),

          const SizedBox(height: 20),

          const Divider(
            color: profileBorder,
          ),

          const SizedBox(height: 15),

          child,

        ],
      ),
    );
  }

  // ===========================================
  // INFORMATION TILE
  // ===========================================

  Widget _informationTile({
    required String label,
    required String value,
    required IconData icon,
    Widget? trailing,
  }) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: 36,
            height: 36,

            decoration: BoxDecoration(
              color: profileBackground,
              borderRadius: BorderRadius.circular(9),
            ),

            child: Icon(
              icon,
              color: profileSecondary,
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
                    color: profileSecondary,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 6),

                SelectableText(
                  value,

                  style: const TextStyle(
                    color: profileDarkBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              ],
            ),
          ),

          if (trailing != null) trailing,

        ],
      ),
    );
  }

  // ===========================================
  // ACCOUNT STATUS
  // ===========================================

  Widget _accountStatus({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {

    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
        ),
      ),

      child: Row(
        children: [

          Icon(
            icon,
            color: color,
            size: 21,
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  label,

                  style: const TextStyle(
                    color: profileSecondary,
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,

                  style: TextStyle(
                    color: color,
                    fontSize: 12,
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

  // ===========================================
  // ACCOUNT SECURITY SECTION
  // ===========================================

  Widget _securitySection(User? user) {

    final emailVerified = user?.emailVerified ?? false;

    return _sectionCard(
      title: 'Account Security',
      icon: Icons.security_rounded,

      child: Column(
        children: [

          _informationTile(
            label: 'Password',
            value: '••••••••••••',
            icon: Icons.lock_outline_rounded,
          ),

          _informationTile(
            label: 'Email Verification',
            value: emailVerified
                ? 'Verified'
                : 'Not Verified',
            icon: Icons.verified_user_outlined,
          ),

          const SizedBox(height: 4),

          SizedBox(
            width: double.infinity,

            child: OutlinedButton.icon(
              onPressed: () {
                _comingSoon('Change Password');
              },

              icon: const Icon(
                Icons.lock_reset_rounded,
                size: 18,
              ),

              label: const Text('Change Password'),

              style: OutlinedButton.styleFrom(
                foregroundColor: profileBlue,

                side: const BorderSide(
                  color: profileBlue,
                ),

                padding: const EdgeInsets.symmetric(
                  vertical: 14,
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

  // ===========================================
  // ACCOUNT INFORMATION SECTION
  // ===========================================

  Widget _accountInformation(User? user) {

    final createdAt = user?.metadata.creationTime;

    return _sectionCard(
      title: 'Account Information',
      icon: Icons.manage_accounts_outlined,

      child: Column(
        children: [

          _informationTile(
            label: 'Account Type',
            value: 'Lecturer',
            icon: Icons.school_outlined,
          ),

          _informationTile(
            label: 'Account Created',
            value: _formatDate(createdAt),
            icon: Icons.calendar_today_outlined,
          ),

          _informationTile(
            label: 'Firebase User ID',
            value: user?.uid ?? 'Not available',
            icon: Icons.fingerprint_rounded,
          ),

        ],
      ),
    );
  }

  // ===========================================
  // PROFILE ACTION BUTTONS
  // ===========================================

  Widget _profileActions() {

    return _sectionCard(
      title: 'Profile Settings',
      icon: Icons.settings_outlined,

      child: Column(
        children: [

          // EDIT PROFILE

          SizedBox(
            width: double.infinity,

            child: FilledButton.icon(
              onPressed: () {
                _comingSoon('Edit Profile');
              },

              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
              ),

              label: const Text('Edit Profile'),

              style: FilledButton.styleFrom(
                backgroundColor: profileBlue,
                foregroundColor: Colors.white,

                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // CHANGE PASSWORD

          SizedBox(
            width: double.infinity,

            child: OutlinedButton.icon(
              onPressed: () {
                _comingSoon('Account Settings');
              },

              icon: const Icon(
                Icons.tune_rounded,
                size: 18,
              ),

              label: const Text('Account Settings'),

              style: OutlinedButton.styleFrom(
                foregroundColor: profileBlue,

                side: const BorderSide(
                  color: profileBorder,
                ),

                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // SIGN OUT

          SizedBox(
            width: double.infinity,

            child: OutlinedButton.icon(
              onPressed: () {
                _comingSoon('Sign Out');
              },

              icon: const Icon(
                Icons.logout_rounded,
                size: 18,
              ),

              label: const Text('Sign Out'),

              style: OutlinedButton.styleFrom(
                foregroundColor: profileRed,

                side: const BorderSide(
                  color: Color(0xFFFECACA),
                ),

                padding: const EdgeInsets.symmetric(
                  vertical: 15,
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

  // ===========================================
  // MAIN PROFILE CONTENT
  // ===========================================

  Widget _profileContent(
    BuildContext context,
    User? user,
  ) {

    final displayName =
        (user?.displayName?.trim().isNotEmpty ?? false)
            ? user!.displayName!.trim()
            : 'Lecturer';

    final email =
        user?.email ?? 'Email not available';

    final emailVerified =
        user?.emailVerified ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1100,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // PAGE HEADER

                  _pageHeader(),

                  const SizedBox(height: 25),

                  // PROFILE OVERVIEW

                  _profileHeaderCard(
                    name: displayName,
                    email: email,
                    emailVerified: emailVerified,
                  ),

                  const SizedBox(height: 22),

                  // PERSONAL INFORMATION

                  _sectionCard(
                    title: 'Personal Information',
                    icon: Icons.person_outline_rounded,

                    child: Column(
                      children: [

                        _informationTile(
                          label: 'Full Name',
                          value: displayName,
                          icon: Icons.person_outline_rounded,
                        ),

                        _informationTile(
                          label: 'Email Address',
                          value: email,
                          icon: Icons.email_outlined,
                        ),

                        _informationTile(
                          label: 'Account Role',
                          value: 'Lecturer',
                          icon: Icons.school_outlined,
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ACCOUNT INFORMATION

                  _accountInformation(user),

                  const SizedBox(height: 18),

                  // ACCOUNT SECURITY

                  _securitySection(user),

                  const SizedBox(height: 18),

                  // PROFILE SETTINGS

                  _profileActions(),

                  const SizedBox(height: 30),

                  // FOOTER

                  const Center(
                    child: Text(
                      'ConsultEasy | Lecturer Portal',

                      style: TextStyle(
                        color: profileSecondary,
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

  // ===========================================
  // MAIN BUILD
  // ===========================================

  @override
  Widget build(BuildContext context) {

    final user = _currentUser;

    if (user == null) {

      return Container(
        color: profileBackground,

        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Icon(
                Icons.person_off_outlined,
                size: 50,
                color: profileSecondary,
              ),

              SizedBox(height: 15),

              Text(
                'Login Required',

                style: TextStyle(
                  color: profileDarkBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 7),

              Text(
                'Please sign in to view your profile.',

                style: TextStyle(
                  color: profileSecondary,
                  fontSize: 12,
                ),
              ),

            ],
          ),
        ),
      );
    }

    return Container(
      color: profileBackground,

      child: _profileContent(
        context,
        user,
      ),
    );
  }
}
