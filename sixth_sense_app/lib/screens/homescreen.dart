import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:sixth_sense_app/services/appwrite_service.dart';

// Colors
class AppColors {
  static const bg = Color(0xFFF3F6FB);
  static const cardWhite = Color(0xFFFFFFFF);
  static const primaryBlue = Color(0xFF2457E0);
  static const deepBlue = Color(0xFF16336E);
  static const softBlue = Color(0xFFDCE8FB);
  static const paleBlue = Color(0xFFEEF3FC);
  static const iceBlue = Color(0xFFD6E6FB);
  static const textDark = Color(0xFF141B2E);
  static const textMuted = Color(0xFF8791A4);
  static const success = Color(0xFF2FA873);
  static const successBg = Color(0xFFE5F6EE);
  static const alertBg = Color(0xFFFCEBEA);
  static const alertText = Color(0xFFC44848);
  static const cardShadow = Color(0x0F1B2A57);
}

/// Small typed result so the UI can distinguish "not logged in",
/// "row missing", and "other error" instead of one blank screen.
class _UserLoadResult {
  final Map<String, dynamic>? data;
  final String? errorMessage;
  _UserLoadResult.success(this.data) : errorMessage = null;
  _UserLoadResult.failure(this.errorMessage) : data = null;
}

class CaneDashboardScreen extends StatefulWidget {
  const CaneDashboardScreen({super.key});

  @override
  State<CaneDashboardScreen> createState() => _CaneDashboardScreenState();

  static List<BoxShadow> get _cardShadow => [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

class _CaneDashboardScreenState extends State<CaneDashboardScreen> {
  late Future<_UserLoadResult> userFuture;

  Future<_UserLoadResult> _getCurrentUserData() async {
    try {
      final authUser = await AppwriteService.account.get();

      final profile = await AppwriteService.tablesDB.getRow(
        databaseId: AppwriteService.databaseId,
        tableId: AppwriteService.userTableId,
        rowId: authUser.$id,
      );

      // ignore: avoid_print
      print('Loaded profile row for auth user: ${authUser.$id}');
      return _UserLoadResult.success(profile.data);
    } on AppwriteException catch (e) {
      // Surfaces the real Appwrite error: 401 = not logged in / bad
      // session or missing scope, 404 = wrong databaseId/tableId.
      return _UserLoadResult.failure('Appwrite error ${e.code}: ${e.message}');
    } catch (e) {
      return _UserLoadResult.failure('Unexpected error: $e');
    }
  }

  void _reload() {
    setState(() {
      userFuture = _getCurrentUserData();
    });
  }

  @override
  void initState() {
    super.initState();
    userFuture = _getCurrentUserData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_UserLoadResult>(
      future: userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
          );
        }

        final result = snapshot.data;

        if (snapshot.hasError || result == null || result.errorMessage != null) {
          final message = snapshot.hasError
              ? snapshot.error.toString()
              : (result?.errorMessage ?? 'Unknown error');
          return Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.alertText, size: 40),
                    const SizedBox(height: 14),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 13.5),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _reload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final user = result.data!;

        return Scaffold(
          backgroundColor: AppColors.bg,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primaryBlue,
              onRefresh: () async {
                _reload();
                await userFuture;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(user),
                    const SizedBox(height: 24),
                    _buildConnectionCard(user),
                    const SizedBox(height: 26),
                    _sectionLabel('Live detection'),
                    _buildStatRow(user),
                    const SizedBox(height: 26),
                    _sectionLabel('Location'),
                    _buildLocationCard(user),
                    const SizedBox(height: 26),
                    _buildAlertsCard(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Map<String, dynamic> user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good morning',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              (user['name'] as String?)?.trim().isNotEmpty == true ? user['name'] : 'User',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _circleIconButton(Icons.notifications_none_rounded),
            const SizedBox(width: 10),
            _circleIconButton(Icons.person_outline_rounded),
          ],
        ),
      ],
    );
  }

  Widget _circleIconButton(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        shape: BoxShape.circle,
        boxShadow: CaneDashboardScreen._cardShadow,
      ),
      child: Icon(icon, size: 19, color: AppColors.deepBlue),
    );
  }

  Widget _buildConnectionCard(Map<String, dynamic> user) {
    final bool connected = user['caneConnected'] ?? true;
    final int batteryPct = (user['batteryLevel'] is int) ? user['batteryLevel'] : 82;
    final double batteryFraction = batteryPct / 100;
    final String signal = user['signalStrength'] ?? 'Strong';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: connected
              ? [AppColors.primaryBlue, AppColors.deepBlue]
              : [AppColors.textMuted, AppColors.textDark],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: connected ? const Color(0xFF6FE39A) : const Color(0xFFE0855E),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (connected ? const Color(0xFF6FE39A) : const Color(0xFFE0855E))
                          .withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                connected ? 'Cane connected' : 'Cane disconnected',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.1,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.7), size: 20),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _batteryRing(batteryFraction),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$batteryPct%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Battery · ~${(batteryPct / 14).round()} hrs left',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              _signalPill(signal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _batteryRing(double value) {
    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 46,
            height: 46,
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0),
              strokeWidth: 4,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
        ],
      ),
    );
  }

  Widget _signalPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_rounded, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildStatRow(Map<String, dynamic> user) {
    final int objects = (user['objectsDetected'] is int) ? user['objectsDetected'] : 3;
    final String closest =
        (user['closestObstacleM'] != null) ? user['closestObstacleM'].toString() : '0.8';

    return Row(
      children: [
        Expanded(
          child: _featureCard(
            icon: Icons.blur_on_rounded,
            iconBg: AppColors.iceBlue,
            title: '$objects',
            unit: 'objects',
            subtitle: 'Detected nearby',
            trend: '+1 vs last min',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _featureCard(
            icon: Icons.social_distance_rounded,
            iconBg: AppColors.softBlue,
            title: closest,
            unit: 'm',
            subtitle: 'Closest obstacle',
            trend: 'Front-left',
          ),
        ),
      ],
    );
  }

  Widget _featureCard({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String unit,
    required String subtitle,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: CaneDashboardScreen._cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: -0.4,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            trend,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.primaryBlue.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Map<String, dynamic> user) {
    final String location = (user['lastKnownLocation'] as String?)?.trim().isNotEmpty == true
        ? user['lastKnownLocation']
        : 'Kadri Hills, Mangalore';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: CaneDashboardScreen._cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.paleBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.location_on_rounded, color: AppColors.primaryBlue, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Location',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              backgroundColor: AppColors.paleBlue,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'View map',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: CaneDashboardScreen._cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent alerts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'See all',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue.withOpacity(0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _alertRow(
            icon: Icons.warning_amber_rounded,
            text: 'Obstacle detected ahead',
            time: '2 min ago',
            isDanger: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.bg, height: 1),
          ),
          _alertRow(
            icon: Icons.check_circle_rounded,
            text: 'SOS button test passed',
            time: '1 hr ago',
            isDanger: false,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.bg, height: 1),
          ),
          _alertRow(
            icon: Icons.warning_amber_rounded,
            text: 'Left safe zone: Kadri Hills',
            time: '3 hrs ago',
            isDanger: true,
          ),
        ],
      ),
    );
  }

  Widget _alertRow({
    required IconData icon,
    required String text,
    required String time,
    required bool isDanger,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDanger ? AppColors.alertBg : AppColors.successBg,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            size: 17,
            color: isDanger ? AppColors.alertText : AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
