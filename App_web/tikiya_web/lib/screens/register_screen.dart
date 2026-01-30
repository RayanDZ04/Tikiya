import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session_store.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService authService;
  final SessionStore sessionStore;

  const RegisterScreen({
    super.key,
    required this.authService,
    required this.sessionStore,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  String _role = 'participant';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.authService.register(
        email: _email.text.trim(),
        password: _password.text,
        role: _role,
      );
      await widget.sessionStore.save(accessToken: res.accessToken, user: res.user);

      if (!mounted) return;
      if (res.user.role == 'organizer' || res.user.role == 'organisateur') {
        Navigator.of(context).pushNamedAndRemoveUntil('/orga', (_) => false);
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil('/participant', (_) => false);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Email requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'Mot de passe'),
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
                  ),
                  const SizedBox(height: 16),
                  Text('Je suis :', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ChoiceChip(
                        label: const Text('Participant'),
                        selected: _role == 'participant',
                        onSelected: (_) => setState(() => _role = 'participant'),
                      ),
                      ChoiceChip(
                        label: const Text('Organisateur'),
                        selected: _role == 'organizer',
                        onSelected: (_) => setState(() => _role = 'organizer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            if (!_formKey.currentState!.validate()) return;
                            _submit();
                          },
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("S'inscrire"),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                    child: const Text('Déjà un compte ? Se connecter'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
