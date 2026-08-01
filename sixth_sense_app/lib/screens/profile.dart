import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:sixth_sense_app/services/appwrite_service.dart';

class AppColors {
  static const bg = Color(0xFFF7F9FC);
  static const card = Colors.white;
  static const primary = Color(0xFF2F6FED);
  static const primaryLight = Color(0xFFE8F0FE);
  static const textDark = Color(0xFF1A1D23);
  static const textMuted = Color(0xFF8A8F99);
  static const divider = Color(0xFFEEF1F6);
  static const danger = Color(0xFFE5484D);
  static const dangerLight = Color(0xFFFBEAEA);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<_ProfileData> _loadProfile() async {
    final user = await AppwriteService.account.get();
    final row = await AppwriteService.tablesDB.getRow(
      databaseId: AppwriteService.databaseId,
      tableId: AppwriteService.userTableId,
      rowId: user.$id,
    );
    return _ProfileData(user: user, values: row.data);
  }

  Future<void> _reload() async {
    setState(() => _profileFuture = _loadProfile());
    await _profileFuture;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProfileData>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          final error = snapshot.error is AppwriteException
              ? (snapshot.error as AppwriteException).message
              : snapshot.error?.toString() ?? 'Profile could not be loaded.';
          return Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.error_outline_rounded,
                          color: AppColors.danger, size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      error ?? 'Profile could not be loaded.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _reload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final profile = snapshot.data!;
        final name = _value(profile.values['name'], profile.user.name, 'Unnamed User');
        final email = _value(profile.values['email'], profile.user.email, 'No email');
        final emailVerified = profile.user.emailVerification;
        final phone = _value(profile.values['phone'], '', 'Not provided');
        final bio = _value(profile.values['bio'], '', 'No bio added yet.');
        final avatarUrl = _value(profile.values['avatarUrl'], '', '');
        final joined = profile.user.$createdAt.length >= 10
            ? profile.user.$createdAt.substring(0, 10)
            : profile.user.$createdAt;

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    name: name,
                    email: email,
                    avatarUrl: avatarUrl,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('Account'),
                        const SizedBox(height: 10),
                        _InfoCard(
                          children: [
                            _InfoTile(
                              icon: Icons.badge_outlined,
                              label: 'Name',
                              value: name,
                            ),
                            const _Divider(),
                            _InfoTile(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: email,
                              trailing:
                                  emailVerified ? const _VerifiedBadge() : null,
                            ),
                            const _Divider(),
                            _InfoTile(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: phone,
                            ),
                            const _Divider(),
                            _InfoTile(
                              icon: Icons.calendar_today_outlined,
                              label: 'Joined',
                              value: joined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        const _SectionLabel('About'),
                        const SizedBox(height: 10),
                        _InfoCard(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                bio,
                                style: const TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // TODO: hook up real logout logic
                            },
                            icon: const Icon(Icons.logout_rounded,
                                size: 18, color: AppColors.danger),
                            label: const Text(
                              'Log out',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              backgroundColor: AppColors.dangerLight,
                              side: BorderSide.none,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
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
    );
  }

  String _value(dynamic value, String fallback, String emptyValue) {
    final text = value?.toString().trim() ?? '';
    return text.isNotEmpty ? text : (fallback.isNotEmpty ? fallback : emptyValue);
  }
}

class _ProfileData {
  const _ProfileData({required this.user, required this.values});

  final models.User user;
  final Map<String, dynamic> values;
}

class _Header extends StatelessWidget {
  final String name;
  final String email;
  final String avatarUrl;

  const _Header({
    required this.name,
    required this.email,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty
        ? name[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : '?');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 64, 20, 36),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                image: avatarUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                border: Border.all(color: AppColors.card, width: 3),
              ),
              alignment: Alignment.center,
              child: avatarUrl.isEmpty
                  ? Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            name.isNotEmpty ? name : 'Unnamed User',
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.check_circle_rounded, size: 12, color: AppColors.primary),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.divider, indent: 66);
  }
}