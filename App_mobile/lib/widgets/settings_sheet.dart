import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/l10n.dart';
import '../services/user_service.dart';
import '../services/session_store.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────
/// Affiche le bottom-sheet Paramètres par-dessus le profil.
void showSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _SettingsSheet(),
  );
}

// ─── Main sheet ───────────────────────────────────────────────────────────────
class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: bleuProfond.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: bleuCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.settings_outlined,
                    size: 20, color: bleuCyan),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.settingsTitle,
                style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: bleuProfond,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Options
          _SettingsTile(
            icon: Icons.email_outlined,
            title: l10n.settingsChangeEmail,
            subtitle: l10n.settingsChangeEmailSub,
            onTap: () {
              Navigator.pop(context);
              _showChangeEmailSheet(context);
            },
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: l10n.settingsChangePassword,
            subtitle: l10n.settingsChangePasswordSub,
            onTap: () {
              Navigator.pop(context);
              _showChangePasswordSheet(context);
            },
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: Icons.badge_outlined,
            title: l10n.settingsChangeUsername,
            subtitle: l10n.settingsChangeUsernameSub,
            onTap: () {
              Navigator.pop(context);
              _showChangeUsernameSheet(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Tile ─────────────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bleuCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: bleuCyan),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: bleuProfond,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: bleuProfond.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 18, color: bleuProfond.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Change email sheet ───────────────────────────────────────────────────────
void _showChangeEmailSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _ChangeEmailSheet(),
  );
}

class _ChangeEmailSheet extends StatefulWidget {
  const _ChangeEmailSheet();
  @override
  State<_ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<_ChangeEmailSheet> {
  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _pwVisible = false;
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      await UserService().changeEmail(
        currentPassword: _pwCtrl.text.trim(),
        newEmail: _emailCtrl.text.trim(),
      );
      // Mettre à jour la session locale avec le nouvel email
      final sess = SessionStore.I.session.value;
      if (sess != null) {
        await SessionStore.I.setSession(UserSession(
          id: sess.id,
          email: _emailCtrl.text.trim(),
          username: sess.username,
          role: sess.role,
          accessToken: sess.accessToken,
          refreshToken: sess.refreshToken,
        ));
      }
      setState(() { _success = true; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: _success ? _SuccessBanner(
          message: l10n.settingsEmailSuccess,
          onDone: () => Navigator.pop(context),
        ) : Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHandle(),
              const SizedBox(height: 20),
              _SheetTitle(
                  icon: Icons.email_outlined, title: l10n.settingsChangeEmail),
              const SizedBox(height: 24),
              _FormField(
                controller: _emailCtrl,
                label: l10n.settingsNewEmail,
                hint: 'exemple@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.fieldRequired;
                  if (!v.contains('@') || !v.contains('.')) {
                    return l10n.fieldEmailInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _FormField(
                controller: _pwCtrl,
                label: l10n.settingsCurrentPassword,
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscure: !_pwVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                      _pwVisible ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: bleuProfond.withValues(alpha: 0.4)),
                  onPressed: () =>
                      setState(() => _pwVisible = !_pwVisible),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.fieldRequired;
                  if (v.length < 8) return l10n.fieldMin8Chars;
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _error!),
              ],
              const SizedBox(height: 20),
              _SubmitButton(
                label: l10n.settingsChangeEmail,
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Change password sheet ────────────────────────────────────────────────────
void _showChangePasswordSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _ChangePasswordSheet(),
  );
}

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  static const Color bleuProfond = Color(0xFF0B1C3E);

  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _currentVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      await UserService().changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      setState(() { _success = true; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: _success ? _SuccessBanner(
          message: l10n.settingsPasswordSuccess,
          onDone: () => Navigator.pop(context),
        ) : Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHandle(),
              const SizedBox(height: 20),
              _SheetTitle(
                  icon: Icons.lock_outline,
                  title: l10n.settingsChangePassword),
              const SizedBox(height: 24),
              _FormField(
                controller: _currentCtrl,
                label: l10n.settingsCurrentPassword,
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscure: !_currentVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                      _currentVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                      color: bleuProfond.withValues(alpha: 0.4)),
                  onPressed: () =>
                      setState(() => _currentVisible = !_currentVisible),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.fieldRequired;
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _FormField(
                controller: _newCtrl,
                label: l10n.settingsNewPassword,
                hint: '••••••••',
                icon: Icons.lock_reset,
                obscure: !_newVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                      _newVisible ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: bleuProfond.withValues(alpha: 0.4)),
                  onPressed: () =>
                      setState(() => _newVisible = !_newVisible),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.fieldRequired;
                  if (v.length < 8) return l10n.fieldMin8Chars;
                  if (v == _currentCtrl.text) {
                    return l10n.fieldPasswordSameAsCurrent;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _FormField(
                controller: _confirmCtrl,
                label: l10n.settingsPasswordConfirm,
                hint: '••••••••',
                icon: Icons.check_circle_outline,
                obscure: !_confirmVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                      _confirmVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 20,
                      color: bleuProfond.withValues(alpha: 0.4)),
                  onPressed: () =>
                      setState(() => _confirmVisible = !_confirmVisible),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.fieldRequired;
                  if (v != _newCtrl.text) {
                    return l10n.passwordMismatch;
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _error!),
              ],
              const SizedBox(height: 20),
              _SubmitButton(
                label: l10n.settingsChangePassword,
                loading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Change username sheet ────────────────────────────────────────────────────
void _showChangeUsernameSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _ChangeUsernameSheet(),
  );
}

class _ChangeUsernameSheet extends StatefulWidget {
  const _ChangeUsernameSheet();
  @override
  State<_ChangeUsernameSheet> createState() => _ChangeUsernameSheetState();
}

class _ChangeUsernameSheetState extends State<_ChangeUsernameSheet> {
  static const Color bleuProfond = Color(0xFF0B1C3E);

  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      final username = _usernameCtrl.text.trim();
      await UserService().changeUsername(username: username);
      // Mettre à jour la session locale
      final session = SessionStore.I.session.value;
      if (session != null) {
        SessionStore.I.setSession(session.copyWith(username: username));
      }
      setState(() { _success = true; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: _success
            ? _SuccessBanner(
                message: l10n.settingsUsernameSuccess,
                onDone: () => Navigator.pop(context),
              )
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SheetHandle(),
                    const SizedBox(height: 20),
                    _SheetTitle(
                        icon: Icons.badge_outlined,
                        title: l10n.settingsChangeUsername),
                    const SizedBox(height: 24),
                    _FormField(
                      controller: _usernameCtrl,
                      label: l10n.settingsNewUsername,
                      hint: l10n.settingsUsernameHint,
                      icon: Icons.badge_outlined,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.fieldRequired;
                        }
                        if (v.trim().length < 2) return l10n.fieldMin2Chars;
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _ErrorBanner(message: _error!),
                    ],
                    const SizedBox(height: 20),
                    _SubmitButton(
                      label: l10n.settingsChangeUsername,
                      loading: _loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFF0B1C3E).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF00ACC1).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF00ACC1)),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0B1C3E),
          ),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
  });
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: bleuProfond.withValues(alpha: 0.5),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: bleuProfond),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.montserrat(
                fontSize: 13,
                color: bleuProfond.withValues(alpha: 0.25)),
            prefixIcon:
                Icon(icon, size: 18, color: bleuCyan.withValues(alpha: 0.7)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: bleuProfond.withValues(alpha: 0.12)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: bleuProfond.withValues(alpha: 0.12)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: bleuCyan, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 16, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message, required this.onDone});
  final String message;
  final VoidCallback onDone;

  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SheetHandle(),
        const SizedBox(height: 32),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF43A047).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline,
              size: 40, color: Color(0xFF43A047)),
        ),
        const SizedBox(height: 20),
        Text(
          message,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: bleuProfond,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: bleuCyan,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: onDone,
            child: Text(
              l10n.homeFiltersClose,
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  static const Color bleuProfond = Color(0xFF0B1C3E);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bleuProfond,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                label,
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
      ),
    );
  }
}
