import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cross-promotion widget for RBSoundz music apps
///
/// Displays a polite, non-intrusive section promoting other apps in the portfolio.
/// Best placed in settings/drawer pages.
class OtherAppsPromoWidget extends StatelessWidget {
  /// The current app ID - used to filter out self from the list
  /// - 'ear_n_play'
  /// - 'scale_master_guitar'
  /// - 'guitar_progression_generator'
  final String currentAppId;

  /// Optional custom styling
  final Color? backgroundColor;
  final Color? accentColor;

  const OtherAppsPromoWidget({
    Key? key,
    required this.currentAppId,
    this.backgroundColor,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherApps = _getOtherApps();

    if (otherApps.isEmpty) return const SizedBox.shrink();

    return Card(
      color: backgroundColor ?? theme.cardColor.withOpacity(0.5),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with RiffRoutine branding — tappable to visit website
            InkWell(
              onTap: () => _launchRiffRoutine(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/riff_routine_logo.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.music_note_rounded,
                          color: accentColor ?? theme.colorScheme.primary,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'More from RiffRoutine',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'riffroutine.com — Apps & resources for musicians',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: accentColor ?? theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),

            // App list
            ...otherApps.map((app) => _buildAppTile(context, app, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppTile(BuildContext context, AppInfo app, ThemeData theme) {
    final bool isComingSoon = app.isComingSoon;

    return InkWell(
      onTap: isComingSoon ? null : () => _launchAppStore(context, app),
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: isComingSoon ? 0.7 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              // App logo (actual image)
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.onSurface.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.asset(
                        app.iconAssetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to gradient + icon if image fails
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: app.gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(
                              app.icon,
                              color: Colors.white,
                              size: 28,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // "Coming Soon" badge
                  if (isComingSoon)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor ?? theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Text(
                          'SOON',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // App info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            app.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isComingSoon) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (accentColor ?? theme.colorScheme.primary).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: (accentColor ?? theme.colorScheme.primary).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Coming Soon',
                              style: TextStyle(
                                color: accentColor ?? theme.colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Arrow icon (only if not coming soon)
              if (!isComingSoon)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: accentColor ?? theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<AppInfo> _getOtherApps() {
    final allApps = [
      AppInfo(
        id: 'ear_n_play',
        name: 'Ear N Play',
        description: 'Perfect pitch & ear training for guitarists',
        icon: Icons.hearing_rounded,
        iconAssetPath: 'assets/images/ear_n_play_icon.png',
        gradientColors: [
          const Color(0xFF9EFF00),
          const Color(0xFF7ACC00),
        ],
        iosUrl: 'https://apps.apple.com/pt/app/earnplay/id6749683780',
        androidUrl: 'https://play.google.com/store/apps/details?id=com.romeubeato.ear_trainer&hl=en',
        isComingSoon: false,
      ),
      AppInfo(
        id: 'scale_master_guitar',
        name: 'Scale Master Guitar',
        description: 'Master guitar scales with interactive exercises',
        icon: Icons.music_note_rounded,
        iconAssetPath: 'assets/images/smguitar_icon.png',
        gradientColors: [
          const Color(0xFF4CAF50),
          const Color(0xFF2E7D32),
        ],
        iosUrl: 'https://apps.apple.com/no/app/scale-master-guitar/id6746448058',
        androidUrl: 'https://play.google.com/store/apps/details?id=com.rbsoundz.scalemasterguitar&hl=en',
        isComingSoon: false,
      ),
      AppInfo(
        id: 'guitar_progression_generator',
        name: 'Guitar Progression Generator',
        description: 'Create chord progressions with multiple sounds',
        icon: Icons.music_video_rounded,
        iconAssetPath: 'assets/images/cgfg_icon.png',
        gradientColors: [
          const Color(0xFFFF9800),
          const Color(0xFFE65100),
        ],
        iosUrl: 'https://apps.apple.com/pt/app/guitar-progression-generator/id6747004878',
        androidUrl: 'https://play.google.com/store/apps/details?id=com.romeubeato.chord_generator_for_guitar_v2&hl=en',
        isComingSoon: false,
      ),
    ];

    // Filter out current app
    return allApps.where((app) => app.id != currentAppId).toList();
  }

  Future<void> _launchRiffRoutine(BuildContext context) async {
    const url = 'https://www.riffroutine.com';
    final uri = Uri.parse(url);
    bool launched = false;

    for (final mode in [
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
      LaunchMode.inAppBrowserView,
      LaunchMode.inAppWebView,
    ]) {
      try {
        launched = await launchUrl(uri, mode: mode);
        if (launched) return;
      } catch (_) {
        // Try next mode
      }
    }

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open riffroutine.com'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _launchAppStore(BuildContext context, AppInfo app) async {
    final url = _getPlatformUrl(context, app);
    final uri = Uri.parse(url);
    bool launched = false;

    for (final mode in [
      LaunchMode.externalApplication,
      LaunchMode.platformDefault,
      LaunchMode.inAppBrowserView,
    ]) {
      try {
        launched = await launchUrl(uri, mode: mode);
        if (launched) return;
      } catch (_) {
        // Try next mode
      }
    }

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open store'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _getPlatformUrl(BuildContext context, AppInfo app) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return app.iosUrl;
    } else {
      return app.androidUrl;
    }
  }
}

/// Data model for app information
class AppInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final String iconAssetPath;
  final List<Color> gradientColors;
  final String iosUrl;
  final String androidUrl;
  final bool isComingSoon;

  const AppInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.iconAssetPath,
    required this.gradientColors,
    required this.iosUrl,
    required this.androidUrl,
    this.isComingSoon = false,
  });
}
