import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session_store.dart';
import '../ui/auth_layout.dart';
import '../ui/tikiya_colors.dart';
import '../ui/tikiya_form_widgets.dart';
import '../widgets/top_navigation_bar.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final SessionStore sessionStore;
  final bool isOrganizerMode;

  const LoginScreen({
    super.key,
    required this.authService,
    required this.sessionStore,
    this.isOrganizerMode = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
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
      final res = await widget.authService.login(
        email: _email.text.trim(),
        password: _password.text,
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
    final routeName = ModalRoute.of(context)?.settings.name;
    final isOrganizerRoute = routeName == '/orga-login';
    final isOrganizerMode = widget.isOrganizerMode || isOrganizerRoute;

    return AuthLayout(
      backgroundColor: isOrganizerMode ? TikiyaColors.grisFonce : TikiyaColors.bleuProfond,
      activeNav: isOrganizerMode ? TopNavSection.organizers : null,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TikiyaLogo(showPro: isOrganizerMode),
            const SizedBox(height: 10),
            Text(
              'Connexion',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 20),
            const TikiyaLabel('Email'),
            TikiyaTextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Email requis' : null,
            ),
            const SizedBox(height: 18),
            const TikiyaLabel('Mot de passe'),
            TikiyaTextField(
              controller: _password,
              obscureText: true,
              validator: (v) => (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (_error != null) const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
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
                      : const Text('Se connecter'),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => Navigator.of(context).pushReplacementNamed(
                        isOrganizerMode ? '/orga-register' : '/register',
                      ),
              child: const Text("Pas de compte ? S'inscrire"),
            ),
          ],
        ),
      ),
    );
  }
}
