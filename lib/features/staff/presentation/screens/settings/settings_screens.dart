import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../common/presentation/providers/auth_provider.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/presentation/screens/app_settings_screens.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/localization/locale_provider.dart';
import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';
import '../../widgets/staff_scaffold.dart';

class StaffSettingsScreen extends ConsumerWidget {
  const StaffSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final primaryColor = const Color(0xFF1A56FF);
    final textDark = const Color(0xFF0F172A);
    final textGrey = const Color(0xFF64748B);
    final cardBg = Colors.white;

    // Soft, multi-layered high-depth shadows
    final tactileShadows = [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.01),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];

    Widget buildSettingCard({
      required IconData icon,
      required String title,
      String? subtitle,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: tactileShadows,
          ),
          child: Row(
            children: [
              // Icon container with soft background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9), // Soft grey background
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(icon, color: primaryColor, size: 22),
                ),
              ),
              const SizedBox(width: 16),
              // Text columns
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: textGrey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Chevron right
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8), // Soft off-white
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'Settings',
          style: GoogleFonts.libreCaslonText(
            color: primaryColor,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buildSettingCard(
                          icon: Icons.language_rounded,
                          title: context.l10n.languageSettings,
                          subtitle: locale.languageCode == 'hi' ? 'Hindi' : 'English',
                          onTap: () => context.push(StaffRoutes.settingsLanguage),
                        ),
                        buildSettingCard(
                          icon: Icons.palette_outlined,
                          title: context.l10n.themeSettings,
                          onTap: () => context.push(StaffRoutes.settingsTheme),
                        ),
                        buildSettingCard(
                          icon: Icons.fingerprint_rounded,
                          title: 'Biometric Login',
                          onTap: () => context.push(StaffRoutes.settingsBiometric),
                        ),
                        buildSettingCard(
                          icon: Icons.lock_outline_rounded,
                          title: 'Change Password',
                          onTap: () => context.push(StaffRoutes.settingsPassword),
                        ),
                        
                        // Push logout button to the bottom using IntrinsicHeight spacer
                        const Spacer(),
                        const SizedBox(height: 40),
                        
                        // Red outlined Logout button
                        GestureDetector(
                          onTap: () async {
                            await ref.read(authProvider.notifier).logout();
                            if (context.mounted) context.go(AppRoutes.login);
                          },
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2).withOpacity(0.4), // Soft light red background tint
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFEF4444).withOpacity(0.3), // Red outline
                                width: 1.5,
                              ),
                              boxShadow: tactileShadows,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.logout_rounded,
                                  color: const Color(0xFFDC2626), // Electric red icon
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Logout',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFDC2626), // Electric red text
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Language settings.
class StaffLanguageSettingsScreen extends ConsumerStatefulWidget {
  const StaffLanguageSettingsScreen({super.key});

  @override
  ConsumerState<StaffLanguageSettingsScreen> createState() =>
      _StaffLanguageSettingsScreenState();
}

class _StaffLanguageSettingsScreenState extends ConsumerState<StaffLanguageSettingsScreen> {
  late String _selectedLanguageCode;

  @override
  void initState() {
    super.initState();
    _selectedLanguageCode = ref.read(localeProvider).languageCode;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1A56FF);
    final textDark = const Color(0xFF0F172A);
    final textGrey = const Color(0xFF64748B);
    
    final tactileShadows = [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.01),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];

    Widget buildLanguageOption(String title, String subtitle, String code) {
      final isSelected = _selectedLanguageCode == code;
      return GestureDetector(
        onTap: () {
          setState(() {
            _selectedLanguageCode = code;
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: tactileShadows,
            border: isSelected
                ? Border.all(color: primaryColor.withOpacity(0.1), width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textGrey,
                    ),
                  ),
                ],
              ),
              // Radio selection state
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? primaryColor : const Color(0xFFCBD5E1),
                    width: isSelected ? 6.5 : 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8), // Soft off-white
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Settings',
          style: GoogleFonts.libreCaslonText(
            color: primaryColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Choose Language',
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select your preferred language for the application interface.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: textGrey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    buildLanguageOption('English', '(DEFAULT SYSTEM)', 'en'),
                    buildLanguageOption('Hindi', '(हिन्दी)', 'hi'),
                  ],
                ),
              ),
            ),
            
            // Anchored action button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(localeProvider.notifier).setLocale(Locale(_selectedLanguageCode));
                    if (context.mounted) {
                      context.showDsSnackBar('Language updated');
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'SAVE CHANGES',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),

            // Mock bottom navigation bar mirroring Home / Utility / Security / Account layout in screenshot
            _buildMockBottomNav(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildMockBottomNav(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMockNavItem(Icons.home_outlined, 'Home', false, primaryColor),
          _buildMockNavItem(Icons.build_outlined, 'Utility', false, primaryColor),
          _buildMockNavItem(Icons.security_outlined, 'Security', false, primaryColor),
          _buildMockNavItem(Icons.person_rounded, 'Account', true, primaryColor),
        ],
      ),
    );
  }

  Widget _buildMockNavItem(IconData icon, String label, bool isActive, Color activeColor) {
    final inactiveColor = const Color(0xFF94A3B8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        isActive
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: activeColor, size: 20),
              )
            : Icon(icon, color: inactiveColor, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? activeColor : inactiveColor,
          ),
        ),
      ],
    );
  }
}

/// Theme settings.
class StaffThemeSettingsScreen extends StatelessWidget {
  const StaffThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppThemeSettingsScreen();
  }
}

/// Biometric settings.
class StaffBiometricSettingsScreen extends ConsumerStatefulWidget {
  const StaffBiometricSettingsScreen({super.key});

  @override
  ConsumerState<StaffBiometricSettingsScreen> createState() =>
      _StaffBiometricSettingsScreenState();
}

class _StaffBiometricSettingsScreenState
    extends ConsumerState<StaffBiometricSettingsScreen> {
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled =
        await ref.read(authRepositoryProvider).isBiometricEnabled();
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1A56FF);
    final textDark = const Color(0xFF0F172A);
    final textGrey = const Color(0xFF64748B);

    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFBF9F8),
        body: Center(child: DsLoadingWidget()),
      );
    }

    final tactileShadows = [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.01),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8), // Soft off-white
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header title section
              Text(
                'Biometric Login',
                textAlign: TextAlign.center,
                style: GoogleFonts.libreCaslonText(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Secure your account with high-end precision.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textGrey,
                ),
              ),
              
              const Spacer(),

              // Centered visual hero card containing blue fingerprint icon
              Center(
                child: Container(
                  width: 200,
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF), // Soft electric-blue tint background
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.fingerprint_rounded,
                          color: primaryColor,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Action module card at the bottom
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: tactileShadows,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Switch row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable biometric login',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Use fingerprint or face to sign in',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Custom premium switch toggle
                        GestureDetector(
                          onTap: () async {
                            final newValue = !_enabled;
                            await ref.read(authRepositoryProvider).setBiometricEnabled(newValue);
                            setState(() {
                              _enabled = newValue;
                            });
                            if (context.mounted) {
                              context.showDsSnackBar(
                                newValue ? 'Biometric enabled' : 'Biometric disabled',
                              );
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 50,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: _enabled ? primaryColor : const Color(0xFFE2E8F0),
                            ),
                            child: Stack(
                              children: [
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeIn,
                                  left: _enabled ? 22 : 2,
                                  top: 2,
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: _enabled
                                        ? Icon(Icons.check, color: primaryColor, size: 16)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 20),
                    
                    // Primary CTA
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Continue Setup',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Secondary Action
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        'Skip for now',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Change password screen.
class StaffChangePasswordScreen extends ConsumerStatefulWidget {
  const StaffChangePasswordScreen({super.key});

  @override
  ConsumerState<StaffChangePasswordScreen> createState() =>
      _StaffChangePasswordScreenState();
}

class _StaffChangePasswordScreenState
    extends ConsumerState<StaffChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newController.text.isEmpty) {
      context.showDsSnackBar('Please enter a new password', type: DsSnackBarType.error);
      return;
    }
    if (_newController.text != _confirmController.text) {
      context.showDsSnackBar('Passwords do not match', type: DsSnackBarType.error);
      return;
    }
    
    setState(() => _loading = true);
    final result = await ref.read(staffRepositoryProvider).updatePassword(
          _currentController.text,
          _newController.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (_) {
        context.showDsSnackBar('Password updated successfully', type: DsSnackBarType.success);
        Navigator.of(context).pop();
      },
      onError: (f) =>
          context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1A56FF);
    final textDark = const Color(0xFF0F172A);
    final textGrey = const Color(0xFF64748B);

    Widget buildPasswordField({
      required TextEditingController controller,
      required String label,
      required String hint,
      required bool obscureText,
      required VoidCallback onToggleVisibility,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              style: GoogleFonts.inter(fontSize: 14, color: textDark),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8), // Soft off-white
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Settings',
          style: GoogleFonts.libreCaslonText(
            color: primaryColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Change Password',
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ensure your account is using a long, random password to stay secure.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: textGrey,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      buildPasswordField(
                        controller: _currentController,
                        label: 'Current password',
                        hint: 'Enter current password',
                        obscureText: _obscureCurrent,
                        onToggleVisibility: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                      const SizedBox(height: 20),
                      buildPasswordField(
                        controller: _newController,
                        label: 'New password',
                        hint: 'Create new password',
                        obscureText: _obscureNew,
                        onToggleVisibility: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                      const SizedBox(height: 20),
                      buildPasswordField(
                        controller: _confirmController,
                        label: 'Confirm password',
                        hint: 'Confirm new password',
                        obscureText: _obscureConfirm,
                        onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      
                      const Spacer(),
                      const SizedBox(height: 40),
                      
                      // Submit button
                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Update Password',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
