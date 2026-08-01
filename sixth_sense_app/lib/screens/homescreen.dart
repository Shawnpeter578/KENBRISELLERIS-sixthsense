import 'package:flutter/material.dart';

/// ---- Theme tokens (kept local so this screen drops into any project) ----
class AppColors {
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFF60A5FA);
  static const background = Color(0xFFF7FAFF);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE7EDF7);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFEA580C);
  static const danger = Color(0xFFDC2626);
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ---- Placeholder data — wire up real logic later ----
  static const bool caneConnected = true;
  static const String caneName = "Sixth Sense Cane";
  static const int batteryPercent = 78;

  static const int obstaclesToday = 14;
  static const int obstaclesAvoided = 13;
  static const double distanceKm = 2.6;

  static const bool hasActiveAlert = false;
  static const String lastAlertText = "Obstacle detected — Main Street";
  static const String lastAlertTime = "Today, 10:42 AM";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const _Header(),
            const SizedBox(height: 24),
            const _CanePairingCard(
              connected: caneConnected,
              caneName: caneName,
              batteryPercent: batteryPercent,
            ),
            const SizedBox(height: 16),
            const _MobilityLogCard(
              obstaclesDetected: obstaclesToday,
              obstaclesAvoided: obstaclesAvoided,
              distanceKm: distanceKm,
            ),
            const SizedBox(height: 16),
            const _AlertCard(
              hasActiveAlert: hasActiveAlert,
              lastAlertText: lastAlertText,
              lastAlertTime: lastAlertTime,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Good morning',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Shawn',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textPrimary,
            size: 21,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared card shell
// ---------------------------------------------------------------------------

class _CardShell extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Border? border;

  const _CardShell({required this.child, this.backgroundColor, this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: border ?? Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const _CardTitle({required this.icon, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 11),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.1,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Cane pairing & battery status
// ---------------------------------------------------------------------------

class _CanePairingCard extends StatelessWidget {
  final bool connected;
  final String caneName;
  final int batteryPercent;

  const _CanePairingCard({
    required this.connected,
    required this.caneName,
    required this.batteryPercent,
  });

  Color get _batteryColor {
    if (batteryPercent > 50) return AppColors.success;
    if (batteryPercent > 20) return AppColors.warning;
    return AppColors.danger;
  }

  IconData get _batteryIcon {
    if (batteryPercent > 80) return Icons.battery_full_rounded;
    if (batteryPercent > 50) return Icons.battery_5_bar_rounded;
    if (batteryPercent > 20) return Icons.battery_3_bar_rounded;
    return Icons.battery_alert_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardTitle(
            icon: Icons.bluetooth_rounded,
            title: 'Cane Status',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (connected ? AppColors.success : AppColors.textSecondary)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: connected ? AppColors.success : AppColors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    connected ? 'Connected' : 'Offline',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: connected ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.accessible_forward_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caneName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Paired device',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Icon(_batteryIcon, size: 18, color: _batteryColor),
              const SizedBox(width: 7),
              Text(
                '$batteryPercent%',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                batteryPercent > 20 ? 'Battery healthy' : 'Charge soon',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: batteryPercent / 100,
              minHeight: 9,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(_batteryColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Usage / mobility log — obstacle detection focused
// ---------------------------------------------------------------------------

class _MobilityLogCard extends StatelessWidget {
  final int obstaclesDetected;
  final int obstaclesAvoided;
  final double distanceKm;

  const _MobilityLogCard({
    required this.obstaclesDetected,
    required this.obstaclesAvoided,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final avoidRate = obstaclesDetected == 0
        ? 0
        : ((obstaclesAvoided / obstaclesDetected) * 100).round();

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardTitle(icon: Icons.route_rounded, title: 'Mobility Log'),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatBlock(
                  icon: Icons.sensors_rounded,
                  iconColor: AppColors.warning,
                  value: obstaclesDetected.toString(),
                  label: 'Obstacles\ndetected',
                ),
              ),
              _divider(),
              Expanded(
                child: _StatBlock(
                  icon: Icons.verified_rounded,
                  iconColor: AppColors.success,
                  value: '$avoidRate%',
                  label: 'Avoided\nsafely',
                ),
              ),
              _divider(),
              Expanded(
                child: _StatBlock(
                  icon: Icons.map_rounded,
                  iconColor: AppColors.primary,
                  value: '${distanceKm.toStringAsFixed(1)} km',
                  label: 'Distance\ncovered',
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Obstacles this week',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                _DayBar(label: 'M', heightFactor: 0.35, count: 6),
                _DayBar(label: 'T', heightFactor: 0.55, count: 9),
                _DayBar(label: 'W', heightFactor: 0.45, count: 8),
                _DayBar(label: 'T', heightFactor: 0.9, count: 16),
                _DayBar(label: 'F', heightFactor: 0.65, count: 11),
                _DayBar(label: 'S', heightFactor: 0.3, count: 5),
                _DayBar(label: 'S', heightFactor: 0.75, count: 14, isToday: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 46,
        color: AppColors.border,
      );
}

class _StatBlock extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatBlock({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary.withOpacity(0.85),
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _DayBar extends StatelessWidget {
  final String label;
  final double heightFactor;
  final int count;
  final bool isToday;

  const _DayBar({
    required this.label,
    required this.heightFactor,
    required this.count,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: isToday ? AppColors.primary : AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: heightFactor,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: isToday
                        ? const LinearGradient(
                            colors: [AppColors.primaryLight, AppColors.primary],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : null,
                    color: isToday ? null : AppColors.primaryLight.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              color: isToday ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Obstacle / fall alert
// ---------------------------------------------------------------------------

class _AlertCard extends StatelessWidget {
  final bool hasActiveAlert;
  final String lastAlertText;
  final String lastAlertTime;

  const _AlertCard({
    required this.hasActiveAlert,
    required this.lastAlertText,
    required this.lastAlertTime,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = hasActiveAlert ? AppColors.danger : AppColors.success;

    return _CardShell(
      backgroundColor: hasActiveAlert ? accent.withOpacity(0.05) : AppColors.surface,
      border: Border.all(
        color: hasActiveAlert ? accent.withOpacity(0.25) : AppColors.border,
        width: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  hasActiveAlert ? Icons.warning_rounded : Icons.shield_rounded,
                  size: 18,
                  color: accent,
                ),
              ),
              const SizedBox(width: 11),
              const Text(
                'Safety Alerts',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hasActiveAlert ? 'Active' : 'All clear',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  hasActiveAlert ? Icons.report_rounded : Icons.check_circle_rounded,
                  size: 20,
                  color: accent,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasActiveAlert ? lastAlertText : 'No fall or obstacle events',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasActiveAlert ? lastAlertTime : 'Last checked just now',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}