import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session_store.dart';
import '../ui/auth_layout.dart';
import '../ui/tikiya_colors.dart';
import '../ui/tikiya_form_widgets.dart';
import '../widgets/top_navigation_bar.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService authService;
  final SessionStore sessionStore;
  final bool isOrganizerMode;

  const RegisterScreen({
    super.key,
    required this.authService,
    required this.sessionStore,
    this.isOrganizerMode = false,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  late String _role;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _role = widget.isOrganizerMode ? 'organizer' : 'participant';
  }

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
    final routeName = ModalRoute.of(context)?.settings.name;
    final isOrganizerRoute = routeName == '/orga-register';
    final isOrganizerMode = widget.isOrganizerMode || isOrganizerRoute;

    return AuthLayout(
      backgroundColor: isOrganizerMode ? TikiyaColors.grisFonce : TikiyaColors.bleuProfond,
      activeNav: isOrganizerMode ? TopNavSection.organizers : null,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: TikiyaLogo(showPro: isOrganizerMode),
            ),
            const SizedBox(height: 10),
            Text(
              'Inscription',
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
            if (isOrganizerMode) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'Compte organisateur',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),
            ],
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
                      : const Text("S'inscrire"),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => Navigator.of(context).pushReplacementNamed(
                        isOrganizerMode ? '/orga-login' : '/login',
                      ),
              child: const Text('Déjà un compte ? Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}
