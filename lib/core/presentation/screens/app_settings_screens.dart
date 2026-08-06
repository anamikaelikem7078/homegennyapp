import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../extensions/context_extensions.dart';
import '../../localization/locale_provider.dart';
import '../../theme/theme_provider.dart';
import '../../../design_system/design_system.dart';

/// Shared language picker — used across all roles.
class AppLanguageSettingsScreen extends ConsumerStatefulWidget {
  const AppLanguageSettingsScreen({
    super.key,
    this.useGradient = false,
  });

  final bool useGradient;

  @override
  ConsumerState<AppLanguageSettingsScreen> createState() =>
      _AppLanguageSettingsScreenState();
}

class _AppLanguageSettingsScreenState extends ConsumerState<AppLanguageSettingsScreen> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(localeProvider).languageCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        centerTitle: true,
        title: Text(
          'Settings',
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              SizedBox(height: 16),
              // Illustration placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: context.theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.surfaceVariant, width: 8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              Text(
                'Choose Language',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 32,
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select your preferred language to customize your HomeGenny experience.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: context.colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: 32),
              _buildLanguageOption(
                title: 'English',
                subtitle: 'Default System',
                value: 'en',
                icon: Icons.language,
              ),
              SizedBox(height: 16),
              _buildLanguageOption(
                title: 'Hindi',
                subtitle: 'हिन्दी',
                value: 'hi',
                icon: Icons.translate,
              ),
              const Spacer(),
              Text(
                'COMING SOON',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'French',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Spanish',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(localeProvider.notifier).setLocale(Locale(_selected));
                    if (!context.mounted) return;
                    context.showAppSnackBar('Language updated');
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'SAVE CHANGES',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selected == value;
    return GestureDetector(
      onTap: () => setState(() => _selected = value),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1A56FF), size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF1A56FF) : context.colors.onSurfaceVariant,
                  width: isSelected ? 6 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared theme picker — used across all roles.
class AppThemeSettingsScreen extends ConsumerStatefulWidget {
  const AppThemeSettingsScreen({
    super.key,
    this.useGradient = false,
  });

  final bool useGradient;

  @override
  ConsumerState<AppThemeSettingsScreen> createState() => _AppThemeSettingsScreenState();
}

class _AppThemeSettingsScreenState extends ConsumerState<AppThemeSettingsScreen> {
  late ThemeMode _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = ref.read(themeModeProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_ios, color: context.colors.onSurface),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VISUAL IDENTITY',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: const Color(0xFF1A56FF),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Appearance',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 32,
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Personalize your digital environment. Select a theme that aligns with your creative flow and visual comfort.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: context.colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32),
              
              _buildThemeOption(
                title: 'System default',
                subtitle: 'Syncs with your device settings',
                mode: ThemeMode.system,
                icon: Icons.settings_brightness_outlined,
              ),
              SizedBox(height: 12),
              _buildThemeOption(
                title: 'Light mode',
                subtitle: 'High clarity, stone-tinted aesthetic',
                mode: ThemeMode.light,
                icon: Icons.wb_sunny_outlined,
              ),
              SizedBox(height: 12),
              _buildThemeOption(
                title: 'Dark mode',
                subtitle: 'Focused experience for low light',
                mode: ThemeMode.dark,
                icon: Icons.nightlight_round_outlined,
              ),
              
              const Spacer(),
              
              Text(
                'All settings are saved automatically to your HomeGenny profile across devices.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: context.colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(_selectedMode);
                    context.showAppSnackBar('Appearance updated');
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply Selection',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16), // buffer
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required ThemeMode mode,
    required IconData icon,
  }) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedMode = mode),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF1A56FF) : context.colors.onSurfaceVariant,
                  width: isSelected ? 5 : 1.5,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.colors.onSurface,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: context.colors.onSurfaceVariant, size: 24),
          ],
        ),
      ),
    );
  }
}
