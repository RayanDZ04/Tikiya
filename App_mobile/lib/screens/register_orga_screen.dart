import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../services/session_store.dart';
import '../widgets/language_switch.dart';

class RegisterOrgaScreen extends StatefulWidget {
  const RegisterOrgaScreen({super.key});

  @override
  State<RegisterOrgaScreen> createState() => _RegisterOrgaScreenState();
}

class _RegisterOrgaScreenState extends State<RegisterOrgaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _websiteController = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  String? _error;

  static const Color bleuProfon = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);
  static const Color grisClair = Color(0xFFE0E0E0);
  static const Color grisFonce = Color(0xFF424242);

  @override
  void dispose() {
    _companyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _showStyledSnack(BuildContext context, String message,
      {Color bg = const Color(0xFF0B1C3E)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 6,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _auth.registerOrga(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        company: _companyController.text.trim(),
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
      );
      if (!mounted) return;
      await Navigator.of(context).pushNamed(
        '/otp-verify',
        arguments: _emailController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: bleuProfon,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Top : back + langue
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const LanguageSwitch(foregroundColor: Colors.white),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 370),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: grisClair),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(11, 28, 62, 0.10),
                        blurRadius: 24,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: 'Tikiya',
                            style: GoogleFonts.montserrat(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: bleuProfon,
                              letterSpacing: 0.8,
                            ),
                          ),
                          TextSpan(
                            text: '!',
                            style: GoogleFonts.montserrat(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: bleuCyan,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.orgaSignupTitle,
                        style: TextStyle(
                          color: bleuProfon,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          letterSpacing: 0.01,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFFF4D4F),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 22),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label(l10n.orgaCompanyLabel),
                              _input(
                                controller: _companyController,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? l10n.orgaCompanyRequired
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              _label(l10n.orgaProEmailLabel),
                              _input(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? l10n.emailRequired
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              _label(l10n.orgaPhoneLabel),
                              _input(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? l10n.orgaPhoneRequired
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              _label(l10n.passwordLabel),
                              _input(
                                controller: _passwordController,
                                obscureText: true,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? l10n.passwordRequired
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              _label(l10n.confirmPasswordLabel),
                              _input(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return l10n.confirmPasswordRequired;
                                  }
                                  if (v != _passwordController.text) {
                                    return l10n.passwordMismatch;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              _label(l10n.orgaWebsiteLabel),
                              _input(
                                controller: _websiteController,
                                keyboardType: TextInputType.url,
                                validator: null, // optionnel
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bleuCyan,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                bleuCyan.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            elevation: 2,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  l10n.signupTitle,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: grisFonce,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          color: grisFonce,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: grisClair),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: grisClair),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF00ACC1), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFFFF4D4F)),
          ),
        ),
      ),
    );
  }
}
