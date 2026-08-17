import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/localization/locale_provider.dart';
import '../../../../../design_system/design_system.dart';
import '../../../../../common/presentation/providers/auth_provider.dart';
import '../../../../../core/router/app_routes.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';
import '../../../../../core/theme/theme_provider.dart';

/// Profile tab.
class ClientProfileTabScreen extends ConsumerWidget {
  const ClientProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(clientProfileProvider);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.onSurface),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: context.colors.onSurface),
            onPressed: () => context.push(ClientRoutes.settings),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => DsErrorState(title: context.l10n.error),
        data: (p) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.theme.cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.theme.dividerColor,
                        width: 1,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: const NetworkImage(
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200',
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A56FF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.theme.cardColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check,
                        color: context.theme.cardColor,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // Name & Badge
            Center(
              child: Text(
                p.name,
                style: GoogleFonts.libreCaslonText(
                  fontSize: 28,
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A56FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  context.l10n.premiumMember,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1A56FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                context.l10n.memberSince,
                style: GoogleFonts.inter(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(height: 32),
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(value: '12', label: context.l10n.services),
                Container(
                  width: 1,
                  height: 40,
                  color: context.theme.dividerColor,
                ),
                _StatItem(value: '4.9', label: context.l10n.rating),
                Container(
                  width: 1,
                  height: 40,
                  color: context.theme.dividerColor,
                ),
                _StatItem(value: '150', label: context.l10n.credits),
              ],
            ),
            SizedBox(height: 40),
            // Account Settings
            Text(
              context.l10n.accountSettings,
              style: GoogleFonts.libreCaslonText(
                fontSize: 18,
                color: context.colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            _ProfileMenuTile(
              icon: Icons.person_outline_rounded,
              title: context.l10n.personalDetails,
              onTap: () => context.push(ClientRoutes.personalDetails),
            ),
            _ProfileMenuTile(
              icon: Icons.location_on_outlined,
              title: context.l10n.addressBook,
              onTap: () => context.push(ClientRoutes.address),
            ),
            _ProfileMenuTile(
              icon: Icons.credit_card_outlined,
              title: context.l10n.paymentMethods,
              onTap: () => context.push(ClientRoutes.paymentDetails),
            ),
            SizedBox(height: 32),
            // Support & Safety
            Text(
              context.l10n.supportSafety,
              style: GoogleFonts.libreCaslonText(
                fontSize: 18,
                color: context.colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            _ProfileMenuTile(
              icon: Icons.report_problem_outlined,
              title: context.l10n.complaints,
              onTap: () => context.push(ClientRoutes.complaintHistory),
            ),
            _ProfileMenuTile(
              icon: Icons.help_outline_rounded,
              title: context.l10n.helpCenter,
              onTap: () {},
            ),
            _ProfileMenuTile(
              icon: Icons.privacy_tip_outlined,
              title: context.l10n.privacyPolicy,
              onTap: () {},
            ),
            SizedBox(height: 40),
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go(AppRoutes.login);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade200, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  context.l10n.logOut,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(height: 100), // padding for floating nav
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF1A56FF),
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: context.colors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.theme.dividerColor, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: context.colors.onSurface, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: context.colors.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Personal details.
class ClientPersonalDetailsScreen extends ConsumerStatefulWidget {
  const ClientPersonalDetailsScreen({super.key});

  @override
  ConsumerState<ClientPersonalDetailsScreen> createState() =>
      _ClientPersonalDetailsScreenState();
}

class _ClientPersonalDetailsScreenState
    extends ConsumerState<ClientPersonalDetailsScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final result = await ref.read(clientRepositoryProvider).updateProfile({
      'name': _name.text,
      'email': _email.text,
      'phone': _phone.text,
    });
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(clientProfileProvider);
        context.showDsSnackBar('Profile updated', type: DsSnackBarType.success);
        context.pop();
      },
      onError: (f) =>
          context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(clientProfileProvider);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A56FF)),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          context.l10n.personalDetails,
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: profile.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (p) {
          if (!_initialized) {
            _name.text = p.name;
            _email.text = p.email;
            _phone.text = p.phone;
            _initialized = true;
          }
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              Text(
                context.l10n.profileManagement,
                style: GoogleFonts.inter(
                  color: const Color(0xFF1A56FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                context.l10n.refineIdentity,
                style: GoogleFonts.libreCaslonText(
                  color: context.colors.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                context.l10n.personalInfoDesc,
                style: GoogleFonts.inter(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              SizedBox(height: 32),

              // Form Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.theme.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(context.l10n.fullName, context),
                    _buildTextField(_name, Icons.person_outline, context),
                    SizedBox(height: 20),

                    _buildLabel(context.l10n.emailAddress, context),
                    _buildTextField(_email, Icons.email_outlined, context),
                    SizedBox(height: 20),

                    _buildLabel(context.l10n.phoneNumber, context),
                    _buildTextField(_phone, Icons.phone_outlined, context),
                    SizedBox(height: 32),

                    const Divider(color: Color(0xFFF3F4F6), height: 1),
                    SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A56FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: context.theme.cardColor,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                context.l10n.saveChanges,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Image Card
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.network(
                      'https://images.unsplash.com/photo-1583341612074-ccea5cd64f6a?auto=format&fit=crop&q=80&w=600',
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Text(
                        context.l10n.secureData,
                        style: GoogleFonts.inter(
                          color: context.theme.cardColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Privacy Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A56FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.theme.cardColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.check,
                        color: context.theme.cardColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      context.l10n.privacyAssured,
                      style: GoogleFonts.libreCaslonText(
                        color: context.theme.cardColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      context.l10n.privacyDesc,
                      style: GoogleFonts.inter(
                        color: context.theme.cardColor.withOpacity(0.9),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: context.colors.onSurface,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, BuildContext context, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: context.colors.onSurfaceVariant,
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1A56FF), width: 1.5),
        ),
      ),
    );
  }
}

/// Address details.
class ClientAddressScreen extends ConsumerStatefulWidget {
  const ClientAddressScreen({super.key});

  @override
  ConsumerState<ClientAddressScreen> createState() =>
      _ClientAddressScreenState();
}

class _ClientAddressScreenState extends ConsumerState<ClientAddressScreen> {
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _address.dispose();
    _city.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final result = await ref.read(clientRepositoryProvider).updateProfile({
      'address': _address.text,
      'city': _city.text,
      'pincode': _pincode.text,
    });
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(clientProfileProvider);
        context.showDsSnackBar('Address updated', type: DsSnackBarType.success);
        context.pop();
      },
      onError: (f) =>
          context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(clientProfileProvider);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A56FF)),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          context.l10n.address,
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline_rounded, color: Color(0xFF1A56FF)),
            onPressed: () {},
          ),
        ],
      ),
      body: profile.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (p) {
          if (!_initialized) {
            _address.text = p.address;
            _city.text = p.city;
            _pincode.text = p.pincode;
            _initialized = true;
          }
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              Text(
                context.l10n.profileDetails,
                style: GoogleFonts.inter(
                  color: const Color(0xFF1A56FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                context.l10n.primaryResidence,
                style: GoogleFonts.libreCaslonText(
                  color: context.colors.onSurface,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12),
              Text(
                context.l10n.addressUpdateDesc,
                style: GoogleFonts.inter(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              SizedBox(height: 32),

              _buildLabel(context.l10n.streetAddress, context),
              _buildTextField(_address, Icons.home_outlined, context),
              SizedBox(height: 20),

              _buildLabel(context.l10n.city, context),
              _buildTextField(_city, Icons.location_city_outlined, context),
              SizedBox(height: 20),

              _buildLabel(context.l10n.pincode, context),
              _buildTextField(
                _pincode,
                Icons.pin_drop_outlined,
                context,
                isNumber: true,
              ),
              SizedBox(height: 32),

              // Map Image Card
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.network(
                      'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=600', // Map-like image
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Row(
                        children: [
                          Icon(
                            Icons.check,
                            color: context.theme.cardColor,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            context.l10n.locateOnMap,
                            style: GoogleFonts.inter(
                              color: context.theme.cardColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: context.theme.cardColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Address',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.onSurface,
                    side: BorderSide(
                      color: context.theme.dividerColor,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Discard Changes',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: context.colors.onSurface,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    IconData icon,
    BuildContext context, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        prefixIcon: Icon(
          icon,
          color: context.colors.onSurfaceVariant,
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1A56FF), width: 1.5),
        ),
      ),
    );
  }
}

/// Payment details.
class ClientPaymentDetailsScreen extends ConsumerWidget {
  const ClientPaymentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(clientProfileProvider);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A56FF)),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          context.l10n.paymentDetails,
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline_rounded, color: Color(0xFF1A56FF)),
            onPressed: () {},
          ),
        ],
      ),
      body: profile.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (p) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Text(
              'Secure Your\nTransactions',
              style: GoogleFonts.libreCaslonText(
                color: context.colors.onSurface,
                fontSize: 32,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Manage your digital credentials and review historical payments within our encrypted ecosystem.',
              style: GoogleFonts.inter(
                color: context.colors.onSurfaceVariant,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            SizedBox(height: 32),

            // Primary Method Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A56FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'PRIMARY METHOD',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1A56FF),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Active since September 2023',
                            style: GoogleFonts.inter(
                              color: context.colors.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Color(0xFF1A56FF),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  const Divider(color: Color(0xFFF3F4F6), height: 1),
                  SizedBox(height: 24),

                  _buildDetailRow(context, 'Payment Method', p.paymentMethod ?? 'Not set'),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'UPI ID',
                        style: GoogleFonts.inter(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            p.upiId ?? 'Not set',
                            style: GoogleFonts.inter(
                              color: context.colors.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.copy,
                            color: Colors.grey.shade400,
                            size: 14,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildDetailRow(
                    context,
                    'Linked Account',
                    p.accountLast4 != null ? '**** ${p.accountLast4}' : 'Not set',
                  ),
                  SizedBox(height: 24),

                  const Divider(color: Color(0xFFF3F4F6), height: 1),
                  SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.showDsSnackBar(
                              'Payment details updated successfully',
                              type: DsSnackBarType.success,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A56FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Update Details',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            context.showDsSnackBar(
                              'Payment method removed',
                              type: DsSnackBarType.success,
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Remove',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Payment History
            _buildMenuTile(
              context: context,
              icon: Icons.history_rounded,
              title: context.l10n.paymentHistory,
              subtitle: 'View all recent transactions',
              onTap: () => context.push(ClientRoutes.paymentHistory),
            ),
            SizedBox(height: 16),

            // Security Settings
            _buildMenuTile(
              context: context,
              icon: Icons.verified_user_outlined,
              title: 'Security Settings',
              subtitle: 'Manage your transaction limits',
              onTap: () {},
            ),

            SizedBox(height: 32),

            // Image footer
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&q=80&w=600',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.5),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 24,
                    child: Text(
                      'Trust is our\ncurrency.',
                      style: GoogleFonts.libreCaslonText(
                        color: context.theme.cardColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: context.colors.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: context.colors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: context.colors.onSurface, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: context.colors.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: context.colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings screen.
class ClientSettingsScreen extends ConsumerStatefulWidget {
  const ClientSettingsScreen({super.key});

  @override
  ConsumerState<ClientSettingsScreen> createState() =>
      _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends ConsumerState<ClientSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _attendanceAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_ios, color: context.colors.onSurface),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade100, width: 1.5),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF1A56FF),
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // Illustration Placeholder
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1A56FF), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A56FF).withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    color: Colors.orange.shade300,
                    size: 24,
                  ),
                  SizedBox(height: 8),
                  Icon(
                    Icons.toggle_on,
                    color: Colors.orange.shade300,
                    size: 32,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 32),

          // Header
          Center(
            child: Text(
              context.l10n.accountSettings,
              style: GoogleFonts.libreCaslonText(
                fontSize: 28,
                color: context.colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Manage your ethereal living preferences and notifications.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: context.colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ),
          SizedBox(height: 32),

          // Preferences Card
          _buildSettingsCard(
            context: context,
            title: context.l10n.preferences,
            children: [
              _buildSettingItem(
                context: context,
                title: context.l10n.language,
                subtitle: context.l10n.languageDesc,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ref.watch(localeProvider).languageCode == 'hi'
                          ? 'Hindi'
                          : 'English (US)',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1A56FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: context.colors.onSurfaceVariant,
                      size: 18,
                    ),
                  ],
                ),
                onTap: () => context.push('${ClientRoutes.settings}/language'),
              ),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Divider(height: 1, color: Color(0xFFF3F4F6)),
              ),
              _buildSettingItem(
                context: context,
                title: context.l10n.appearance,
                subtitle: context.l10n.appearanceDesc,
                trailing: Container(
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.light),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration:
                              ref.watch(themeModeProvider) == ThemeMode.light
                              ? BoxDecoration(
                                  color: context.theme.cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                )
                              : null,
                          child: Text(
                            context.l10n.light,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight:
                                  ref.watch(themeModeProvider) ==
                                      ThemeMode.light
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color:
                                  ref.watch(themeModeProvider) ==
                                      ThemeMode.light
                                  ? const Color(0xFF1A56FF)
                                  : context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(ThemeMode.dark),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration:
                              ref.watch(themeModeProvider) == ThemeMode.dark
                              ? BoxDecoration(
                                  color: context.theme.cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                )
                              : null,
                          child: Text(
                            context.l10n.dark,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight:
                                  ref.watch(themeModeProvider) == ThemeMode.dark
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color:
                                  ref.watch(themeModeProvider) == ThemeMode.dark
                                  ? const Color(0xFF1A56FF)
                                  : context.colors.onSurfaceVariant,
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
          SizedBox(height: 24),

          // Notifications Card
          _buildSettingsCard(
            context: context,
            title: context.l10n.notifications,
            children: [
              _buildSettingItem(
                context: context,
                icon: Icons.notifications_outlined,
                title: context.l10n.pushNotifications,
                subtitle: context.l10n.pushNotificationsDesc,
                trailing: Switch(
                  value: _pushEnabled,
                  onChanged: (v) => setState(() => _pushEnabled = v),
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF1A56FF),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 48),
                child: Divider(height: 1, color: Color(0xFFF3F4F6)),
              ),
              _buildSettingItem(
                context: context,
                icon: Icons.email_outlined,
                title: context.l10n.emailSummaries,
                subtitle: context.l10n.emailSummariesDesc,
                trailing: Switch(
                  value: _emailEnabled,
                  onChanged: (v) => setState(() => _emailEnabled = v),
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF1A56FF),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 48),
                child: Divider(height: 1, color: Color(0xFFF3F4F6)),
              ),
              _buildSettingItem(
                context: context,
                icon: Icons.event_available_outlined,
                title: context.l10n.attendanceAlerts,
                subtitle: context.l10n.attendanceAlertsDesc,
                trailing: Switch(
                  value: _attendanceAlerts,
                  onChanged: (v) => setState(() => _attendanceAlerts = v),
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF1A56FF),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Legal & Privacy Card
          _buildSettingsCard(
            context: context,
            title: context.l10n.legalPrivacy,
            children: [
              _buildLegalItem(context.l10n.privacyPolicy, context.l10n.privacyPolicyDesc, context),
              _buildLegalItem(context.l10n.termsOfService, context.l10n.termsOfServiceDesc, context),
              _buildLegalItem(context.l10n.cookiePolicy, context.l10n.cookiePolicyDesc, context),
              _buildLegalItem(context.l10n.licenses, context.l10n.licensesDesc, context),
            ],
          ),
          SizedBox(height: 24),

          // Danger Zone
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE5E5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.deleteAccount,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE53935),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  context.l10n.deleteAccountWarning,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      context.l10n.deactivateAccount,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFE53935),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 100), // nav bar spacing
        ],
      ),
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: GoogleFonts.libreCaslonText(
                fontSize: 20,
                color: context.colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...children,
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    IconData? icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: const Color(0xFF1A56FF), size: 22),
              SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildLegalItem(String title, String subtitle, BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.colors.surfaceVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface,
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
