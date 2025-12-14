import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();

  // Couleurs approximatives des variables CSS du proto
  static const Color bleuProfon = Color(0xFF1A237E);
  static const Color bleuCyan = Color(0xFF00ACC1);
  static const Color grisClair = Color(0xFFE0E0E0);
  static const Color grisFonce = Color(0xFF424242);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showStyledSnack(BuildContext context, String message, {Color bg = bleuProfon}) {
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
    return Scaffold(
      backgroundColor: bleuProfon,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 56),
              // Card conteneur
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
                      // Logo
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: 'Tikiya',
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
                      const Text(
                        'Se connecter',
                        style: TextStyle(
                          color: bleuProfon,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          letterSpacing: 0.01,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Formulaire
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
                              _label('Adresse e-mail'),
                              _input(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Veuillez entrer votre e-mail'
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              _label('Mot de passe'),
                              _input(
                                controller: _passwordController,
                                obscureText: true,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Veuillez entrer votre mot de passe'
                                    : null,
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
                                    if (!_formKey.currentState!.validate()) return;
                                    _showStyledSnack(context, 'Connexion...');
                                    try {
                                      final res = await _auth.login(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text,
                                      );
                                      _showStyledSnack(context, 'Connecté');
                                      Navigator.pushReplacementNamed(context, '/');
                                    } catch (e) {
                                      _showStyledSnack(context, 'Erreur: $e', bg: const Color(0xFFB00020));
                                    }
                                  },
                                  child: const Text(
                                    'Connexion',
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
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushNamed('/register'),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            children: [
                              TextSpan(
                                text: "Pas encore de compte ? ",
                                style: TextStyle(color: bleuProfon),
                              ),
                              TextSpan(
                                text: "S'inscrire",
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
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 14),
        decoration: const BoxDecoration(
          color: grisClair,
          boxShadow: [
            BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.07), blurRadius: 16, offset: Offset(0, -2)),
          ],
        ),
        child: const Text(
          'Tikiya© 2025',
          textAlign: TextAlign.center,
          style: TextStyle(color: grisFonce, fontSize: 18, letterSpacing: 0.05),
        ),
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
