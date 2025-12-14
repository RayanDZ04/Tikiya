import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

enum UserRole { participant, organisateur }

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();
  UserRole? _role = UserRole.participant;
  String? _error;

  static const Color bleuProfon = Color(0xFF1A237E);
  static const Color bleuCyan = Color(0xFF00ACC1);
  static const Color grisClair = Color(0xFFE0E0E0);
  static const Color grisFonce = Color(0xFF424242);

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Tikiya',
                              style: TextStyle(
                                color: bleuProfon,
                                fontWeight: FontWeight.w700,
                                fontSize: 28,
                                letterSpacing: 0.04,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            TextSpan(
                              text: '!',
                              style: TextStyle(
                                color: bleuCyan,
                                fontWeight: FontWeight.w900,
                                fontSize: 28,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "S'inscrire",
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
                              _label('Rôle'),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: _RoleToggle(
                                  selected: _role,
                                  onChanged: (role) => setState(() => _role = role),
                                ),
                              ),
                              const SizedBox(height: 18),

                              _label("Nom d'utilisateur"),
                              _input(
                                controller: _usernameController,
                                validator: (v) => (v == null || v.isEmpty)
                                    ? "Veuillez entrer un nom d'utilisateur"
                                    : null,
                              ),
                              const SizedBox(height: 18),

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
                                    if (!(_formKey.currentState?.validate() ?? false)) {
                                      setState(() => _error = 'Veuillez corriger les champs');
                                      return;
                                    }
                                    setState(() => _error = null);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Inscription...')),
                                    );
                                    try {
                                      final res = await _auth.register(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Inscrit, vous pouvez vous connecter')),
                                      );
                                      Navigator.pushReplacementNamed(context, '/');
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Erreur: $e')),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    "S'inscrire",
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
                        onTap: () => Navigator.of(context).pushNamed('/login'),
                        child: const Text(
                          'Déjà un compte ? Se connecter',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: bleuCyan,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
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

class _RoleToggle extends StatelessWidget {
  final UserRole? selected;
  final ValueChanged<UserRole> onChanged;

  static const Color bleuProfon = Color(0xFF1A237E);
  static const Color bleuCyan = Color(0xFF00ACC1);
  static const Color grisClair = Color(0xFFE0E0E0);

  const _RoleToggle({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: grisClair),
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          Expanded(
            child: _RoleItem(
              label: 'Participant',
              selected: selected == UserRole.participant,
              onTap: () => onChanged(UserRole.participant),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _RoleItem(
              label: 'Organisateur',
              selected: selected == UserRole.organisateur,
              onTap: () => onChanged(UserRole.organisateur),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color bleuCyan = Color(0xFF00ACC1);
  static const Color grisClair = Color(0xFFE0E0E0);
  static const Color bleuProfon = Color(0xFF1A237E);

  const _RoleItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? bleuCyan : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? bleuCyan : grisClair, width: 1.5),
          boxShadow: selected
              ? const [BoxShadow(color: Color.fromRGBO(0, 172, 193, 0.12), blurRadius: 8, offset: Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : bleuProfon,
          ),
        ),
      ),
    );
  }
}
