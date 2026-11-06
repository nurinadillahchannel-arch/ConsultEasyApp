
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================
// CONSULTEASY THEME
// =============================================

const Color profileBlue = Color(0xFF2563EB);
const Color profileDarkBlue = Color(0xFF172554);
const Color profileBackground = Color(0xFFF4F7FC);
const Color profileSecondary = Color(0xFF64748B);
const Color profileBorder = Color(0xFFE2E8F0);

// =============================================
// STUDENT PROFILE PAGE
// =============================================

class StudentProfilePage extends StatelessWidget {
  final User user;
  final Map<String, dynamic> profile;
  final Future<void> Function() onSignOut;
  final bool isSigningOut;

  const StudentProfilePage({
    super.key,
    required this.user,
    required this.profile,
    required this.onSignOut,
    this.isSigningOut = false,
  });

  // =========================================
  // PROFILE INFORMATION
  // =========================================

  String get studentName {
    final name = (profile['fullName'] ??
            user.displayName ??
            'Student')
        .toString()
        .trim();

    return name.isEmpty ? 'Student' : name;
  }

  String get studentEmail {
    return (profile['email'] ?? user.email ?? '').toString();
  }

  String get studentRole {
    return (profile['role'] ?? 'Student').toString();
  }

  String get studentUid {
    return (profile['uid'] ?? user.uid).toString();
  }

  DateTime? get accountCreatedDate {
    final value = profile['createdAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return user.metadata.creationTime;
  }

  // =========================================
  // DATE FORMATTING
  // =========================================

  String _formatDate(BuildContext context) {
    final date = accountCreatedDate;

    if (date == null) {
      return 'Not available';
    }

    return MaterialLocalizations.of(context)
        .formatMediumDate(date);
  }

  // =========================================
  // PAGE HEADING
  // =========================================

  Widget _pageHeading() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Profile',
          style: TextStyle(
            color: profileDarkBlue,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 7),

        Text(
          'Manage and view your ConsultEasy account information.',
          style: TextStyle(
            color: profileSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // =========================================
  // PROFILE HEADER
  // =========================================

  Widget _profileHeader() {
    final initial = studentName.isNotEmpty
        ? studentName[0].toUpperCase()
        : 'S';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: profileBorder,
        ),
      ),

      child: Column(
        children: [

          // PROFILE AVATAR
          CircleAvatar(
            radius: 43,
            backgroundColor: const Color(0xFFDBEAFE),

            child: Text(
              initial,

              style: const TextStyle(
                color: profileBlue,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 17),

          // STUDENT NAME
          Text(
            studentName,
            textAlign: TextAlign.center,

            style: const TextStyle(
              color: profileDarkBlue,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          // EMAIL
          Text(
            studentEmail.isEmpty
                ? 'Email not available'
                : studentEmail,

            textAlign: TextAlign.center,

            style: const TextStyle(
              color: profileSecondary,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 15),

          // ROLE BADGE
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 8,
            ),

            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(25),
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.school_rounded,
                  size: 15,
                  color: profileBlue,
                ),

                const SizedBox(width: 7),

                Text(
                  studentRole.toUpperCase(),

                  style: const TextStyle(
                    color: profileBlue,
                    fontSize: 11,
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

  // =========================================
  // SECTION CONTAINER
  // =========================================

  Widget _sectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
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
                width: 42,
                height: 42,

                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(11),
                ),

                child: Icon(
                  icon,
                  color: profileBlue,
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,

                      style: const TextStyle(
                        color: profileDarkBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,

                      style: const TextStyle(
                        color: profileSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          const Divider(
            color: profileBorder,
            height: 1,
          ),

          const SizedBox(height: 12),

          ...children,
        ],
      ),
    );
  }

  // =========================================
  // INFORMATION ROW
  // =========================================

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            size: 19,
            color: profileSecondary,
          ),

          const SizedBox(width: 13),

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

                const SizedBox(height: 5),

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
        ],
      ),
    );
  }

  // =========================================
  // PERSONAL INFORMATION
  // =========================================

  Widget _personalInformation(BuildContext context) {
    return _sectionCard(
      title: 'Personal Information',
      subtitle: 'Your registered personal details.',
      icon: Icons.person_outline_rounded,

      children: [
        _infoRow(
          icon: Icons.badge_outlined,
          label: 'Full Name',
          value: studentName,
        ),

        _infoRow(
          icon: Icons.email_outlined,
          label: 'Email Address',
          value: studentEmail.isEmpty
              ? 'Not available'
              : studentEmail,
        ),

        _infoRow(
          icon: Icons.school_outlined,
          label: 'Account Role',
          value: studentRole,
        ),
      ],
    );
  }

  // =========================================
  // ACCOUNT INFORMATION
  // =========================================

  Widget _accountInformation(BuildContext context) {
    return _sectionCard(
      title: 'Account Information',
      subtitle: 'Your ConsultEasy account details.',
      icon: Icons.manage_accounts_outlined,

      children: [
        _infoRow(
          icon: Icons.fingerprint_rounded,
          label: 'User ID',
          value: studentUid,
        ),

        _infoRow(
          icon: Icons.calendar_today_outlined,
          label: 'Account Created',
          value: _formatDate(context),
        ),

        _infoRow(
          icon: Icons.verified_user_outlined,
          label: 'Authentication Method',
          value: 'Firebase Authentication',
        ),
      ],
    );
  }

  // =========================================
  // PROFILE SETTINGS
  // =========================================

  Widget _settingsSection(BuildContext context) {
    return _sectionCard(
      title: 'Account Settings',
      subtitle: 'Manage your account preferences.',
      icon: Icons.settings_outlined,

      children: [

        // EDIT PROFILE
        ListTile(
          contentPadding: EdgeInsets.zero,

          leading: const Icon(
            Icons.edit_outlined,
            color: profileBlue,
          ),

          title: const Text(
            'Edit Profile',
            style: TextStyle(
              color: profileDarkBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          subtitle: const Text(
            'Update your personal information.',
            style: TextStyle(fontSize: 11),
          ),

          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: profileSecondary,
          ),

          onTap: () {
            _showComingSoon(
              context,
              'Edit Profile',
            );
          },
        ),

        const Divider(
          color: profileBorder,
        ),

        // CHANGE PASSWORD
        ListTile(
          contentPadding: EdgeInsets.zero,

          leading: const Icon(
            Icons.lock_outline_rounded,
            color: profileBlue,
          ),

          title: const Text(
            'Change Password',
            style: TextStyle(
              color: profileDarkBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          subtitle: const Text(
            'Manage your account password.',
            style: TextStyle(fontSize: 11),
          ),

          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: profileSecondary,
          ),

          onTap: () {
            _showComingSoon(
              context,
              'Change Password',
            );
          },
        ),
      ],
    );
  }

  // =========================================
  // COMING SOON MESSAGE
  // =========================================

  void _showComingSoon(
    BuildContext context,
    String feature,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$feature functionality will be implemented '
            'during Firebase integration.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // =========================================
  // SIGN OUT SECTION
  // =========================================

  Widget _signOutSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFFECACA),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Sign Out',

            style: TextStyle(
              color: profileDarkBlue,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Sign out of your ConsultEasy account '
            'on this device.',

            style: TextStyle(
              color: profileSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,

            child: OutlinedButton.icon(
              onPressed: isSigningOut
                  ? null
                  : () {
                      onSignOut();
                    },

              icon: isSigningOut
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.logout_rounded,
                      size: 18,
                    ),

              label: Text(
                isSigningOut
                    ? 'Signing Out...'
                    : 'Sign Out',
              ),

              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),

                side: const BorderSide(
                  color: Color(0xFFFECACA),
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

  // =========================================
  // MAIN BUILD
  // =========================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: profileBackground,

      child: SingleChildScrollView(
        padding: const EdgeInsets.all(25),

        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1050,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                // HEADING
                _pageHeading(),

                const SizedBox(height: 23),

                // PROFILE HEADER
                _profileHeader(),

                const SizedBox(height: 20),

                // PERSONAL INFORMATION
                _personalInformation(context),

                const SizedBox(height: 17),

                // ACCOUNT INFORMATION
                _accountInformation(context),

                const SizedBox(height: 17),

                // SETTINGS
                _settingsSection(context),

                const SizedBox(height: 17),

                // SIGN OUT
                _signOutSection(),

                const SizedBox(height: 25),

                // FOOTER
                const Center(
                  child: Text(
                    'ConsultEasy | Student Portal',

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
      ),
    );
  }
}
