import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../ui/landing_background.dart';
import '../ui/tikiya_colors.dart';
import '../l10n/app_localizations.dart';
import '../services/api_client.dart';
import '../services/organizer_needs_service.dart';
import '../widgets/language_menu.dart';

class OrgaNeedsScreen extends StatefulWidget {
  const OrgaNeedsScreen({super.key});

  @override
  State<OrgaNeedsScreen> createState() => _OrgaNeedsScreenState();
}

class _OrgaNeedsScreenState extends State<OrgaNeedsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _instagram = TextEditingController();
  final _service = OrganizerNeedsService(ApiClient());
  bool _submitting = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _instagram.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final l10n = context.l10n;
    try {
      await _service.submit(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        instagram: _instagram.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('orga_needs_success'))),
      );
      _formKey.currentState?.reset();
      _firstName.clear();
      _lastName.clear();
      _email.clear();
      _phone.clear();
      _instagram.clear();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message.isNotEmpty ? e.message : l10n.t('orga_needs_error'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('orga_needs_error'))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: TikiyaColors.grisFonce,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: LandingBackground(
                baseColor: TikiyaColors.grisFonce,
                darkColor: const Color(0xFF111111),
                bandBaseColor: const Color(0xFF2B2B2B),
                bandAccentColor: const Color(0xFF9E9E9E),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const _BrandTitle(),
                          const Spacer(),
                          const LanguageMenu(),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.topLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            } else {
                              Navigator.of(context).pushNamed('/orga');
                            }
                          },
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: Text(l10n.t('cta_back')),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1C),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 30,
                                offset: Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth >= 480;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      l10n.t('orga_needs_title'),
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.t('orga_needs_subtitle'),
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.75),
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      l10n.t('orga_needs_note'),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.65),
                                          ),
                                    ),
                                    const SizedBox(height: 20),
                                    _TwoColumnRow(
                                      isWide: isWide,
                                      left: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          _FieldLabel(l10n.t('field_first_name')),
                                          _DarkTextField(
                                            controller: _firstName,
                                            hintText: l10n.t('hint_first_name'),
                                            validator: (v) =>
                                                (v == null || v.trim().isEmpty)
                                                    ? l10n.t('field_required')
                                                    : null,
                                          ),
                                        ],
                                      ),
                                      right: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          _FieldLabel(l10n.t('field_last_name')),
                                          _DarkTextField(
                                            controller: _lastName,
                                            hintText: l10n.t('hint_last_name'),
                                            validator: (v) =>
                                                (v == null || v.trim().isEmpty)
                                                    ? l10n.t('field_required')
                                                    : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _TwoColumnRow(
                                      isWide: isWide,
                                      left: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          _FieldLabel(l10n.t('field_email')),
                                          _DarkTextField(
                                            controller: _email,
                                            hintText: l10n.t('hint_email'),
                                            keyboardType: TextInputType.emailAddress,
                                            validator: (v) {
                                              final value = (v ?? '').trim();
                                              if (value.isEmpty) return l10n.t('field_required');
                                              final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                                  .hasMatch(value);
                                              return ok ? null : l10n.t('field_invalid_email');
                                            },
                                          ),
                                        ],
                                      ),
                                      right: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          _FieldLabel(l10n.t('field_phone')),
                                          _DarkTextField(
                                            controller: _phone,
                                            hintText: l10n.t('hint_phone'),
                                            keyboardType: TextInputType.phone,
                                            validator: (v) =>
                                                (v == null || v.trim().isEmpty)
                                                    ? l10n.t('field_required')
                                                    : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _FieldLabel(l10n.t('field_website')),
                                    _DarkTextField(
                                      controller: _instagram,
                                      hintText: l10n.t('hint_website'),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? l10n.t('field_required')
                                              : null,
                                    ),
                                    const SizedBox(height: 22),
                                    SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: _submitting ? null : _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: _submitting
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : Text(
                                                l10n.t('orga_needs_submit'),
                                                style: const TextStyle(fontWeight: FontWeight.w700),
                                              ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}


class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final brandStyle = GoogleFonts.montserrat(
      textStyle: textTheme.titleLarge,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.4,
      color: Colors.white,
    );

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: l10n.t('app_title'), style: brandStyle),
          TextSpan(
            text: '!',
            style: brandStyle.copyWith(color: TikiyaColors.bleuCyan),
          ),
          TextSpan(
            text: ' Pro',
            style: brandStyle.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _TwoColumnRow extends StatelessWidget {
  final bool isWide;
  final Widget left;
  final Widget right;

  const _TwoColumnRow({
    required this.isWide,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          left,
          const SizedBox(height: 12),
          right,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 14),
        Expanded(child: right),
      ],
    );
  }
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _DarkTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
      ),
    );
  }
}

