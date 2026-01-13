import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../services/session_store.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/language_switch.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _auth = AuthService();
  String? _error;

  static const Color bleuProfon = Color(0xFF1A237E);
  static const Color bleuCyan = Color(0xFF00ACC1);
  static const Color grisClair = Color(0xFFE0E0E0);
  static const Color grisFonce = Color(0xFF424242);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _showStyledSnack(BuildContext context, String message, {Color bg = const Color(0xFF1A237E)}) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: bleuProfon,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 56),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: const LanguageSwitch(foregroundColor: Colors.white),
                ),
              ),
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
                        color: Color.fromRGBO(26, 35, 126, 0.10),
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
                              text: l10n.appTitle,
                            style: GoogleFonts.montserrat(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A237E),
                              letterSpacing: 0.8,
                            ),
                          ),
                          TextSpan(
                            text: '!',
                            style: GoogleFonts.montserrat(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF00ACC1),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.signupTitle,
                        style: TextStyle(
                          color: bleuProfon,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          letterSpacing: 0.01,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFFF4D4F),
                            fontWeight: FontWeight.w600,
                          ),
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
                              _label(l10n.firstNameLabel),
                              _input(
                                controller: _firstNameController,
                                validator: (v) => (v == null || v.isEmpty)
                                ? l10n.firstNameRequired
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              _label(l10n.lastNameLabel),
                              _input(
                                controller: _lastNameController,
                                validator: (v) => (v == null || v.isEmpty)
                                ? l10n.lastNameRequired
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              _label(l10n.emailLabel),
                              _input(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => (v == null || v.isEmpty)
                                ? l10n.emailRequired
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
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: bleuCyan,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () async {
                                    if (!(_formKey.currentState?.validate() ?? false)) {
                                      setState(() => _error = l10n.fixFields);
                                      return;
                                    }
                                    setState(() => _error = null);
                                    _showStyledSnack(context, l10n.signupProgress);
                                    try {
                                      await _auth.register(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text,
                                        firstName: _firstNameController.text.trim(),
                                        lastName: _lastNameController.text.trim(),
                                        role: 'organisateur',
                                      );
                                      if (!context.mounted) return;
                                      _showStyledSnack(context, l10n.signupSuccess);
                                      Navigator.pushReplacementNamed(context, '/');
                                    } catch (e) {
                                      _showStyledSnack(context, 'Erreur: $e', bg: const Color(0xFFB00020));
                                    }
                                  },
                                  child: Text(
                                    l10n.signupTitle,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17,
                                      letterSpacing: 0.01,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Google Sign-Up (same as login)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: bleuCyan),
                            foregroundColor: bleuCyan,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          icon: const Icon(Icons.g_mobiledata, size: 24),
                          label: Text(
                            l10n.googleSignup,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.01,
                            ),
                          ),
                          onPressed: () async {
                            try {
                              final google = GoogleSignIn(
                                scopes: const ['email', 'profile'],
                                serverClientId:
                                    '1095903953092-56rvogj8p1tlsm0rqmd4qp2ec5e3vt5v.apps.googleusercontent.com',
                              );
                              await google.signOut();
                              final account = await google.signIn();
                              final auth = await account?.authentication;
                              final idToken = auth?.idToken;
                              if (idToken == null) {
                                if (!context.mounted) return;
                                _showStyledSnack(context, l10n.googleFailed, bg: const Color(0xFFB00020));
                                return;
                              }
                              if (!context.mounted) return;
                              _showStyledSnack(context, l10n.googleProgress);
                              await _auth.loginWithGoogleIdToken(idToken);
                              if (!context.mounted) return;
                              _showStyledSnack(context, l10n.connected);
                              Navigator.pushReplacementNamed(context, '/');
                            } catch (e) {
                              final msg = e.toString();
                              if (msg.contains('ApiException: 10')) {
                                if (!context.mounted) return;
                                final accepted = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(l10n.googleUnavailableTitle),
                                    content: Text(l10n.googleUnavailableBody),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                                      ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.activate)),
                                    ],
                                  ),
                                );
                                if (accepted == true) {
                                  SessionStore.I.setSession(const UserSession(
                                    id: 'demo',
                                    email: 'demo@tikiya.local',
                                    username: 'Demo',
                                    role: 'user',
                                    accessToken: 'demo-token',
                                  ));
                                  if (!context.mounted) return;
                                  _showStyledSnack(context, l10n.demoEnabled);
                                  Navigator.pushReplacementNamed(context, '/');
                                  return;
                                }
                              }
                              if (!context.mounted) return;
                              _showStyledSnack(context, 'Erreur: $e', bg: const Color(0xFFB00020));
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushNamed('/login'),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Déjà un compte ? ',
                                style: TextStyle(color: bleuProfon),
                              ),
                              TextSpan(
                                text: 'Se connecter',
                                style: TextStyle(color: bleuCyan),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.zero,
        child: const BottomNav(current: 'login'),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: grisFonce,
            fontSize: 16,
            letterSpacing: 0.01,
          ),
        ),
      );

  Widget _input({
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF3F4F7),
          contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
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
            borderSide: const BorderSide(color: bleuCyan),
          ),
        ),
        style: const TextStyle(color: grisFonce, fontSize: 16),
      ),
    );
  }
}

// Role selection removed per request; registration uses only email and password.
