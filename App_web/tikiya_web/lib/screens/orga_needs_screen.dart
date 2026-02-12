import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../ui/landing_background.dart';
import '../ui/tikiya_colors.dart';

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
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _instagram.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      Align(
                        alignment: Alignment.topLeft,
                        child: const _BrandTitle(),
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
                          label: const Text('Retour'),
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
                                      'Présentez-nous votre activité',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Vous serez recontacté par notre équipe',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Colors.white.withValues(alpha: 0.75),
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Ce formulaire est réservé aux organisateurs & agences',
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
                                          _FieldLabel('Prénom*'),
                                          _DarkTextField(
                                            controller: _firstName,
                                            hintText: 'Ryad',
                                          ),
                                        ],
                                      ),
                                      right: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          _FieldLabel('Nom*'),
                                          _DarkTextField(
                                            controller: _lastName,
                                            hintText: 'Mahrez',
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
                                          _FieldLabel('E-mail*'),
                                          _DarkTextField(
                                            controller: _email,
                                            hintText: 'votre@email-pro.dz',
                                            keyboardType: TextInputType.emailAddress,
                                          ),
                                        ],
                                      ),
                                      right: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          _FieldLabel('Téléphone*'),
                                          _DarkTextField(
                                            controller: _phone,
                                            hintText: '+213 # ## ## ## ##',
                                            keyboardType: TextInputType.phone,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    _FieldLabel('Site web*'),
                                    _DarkTextField(
                                      controller: _instagram,
                                      hintText: 'Liens de votre site',
                                    ),
                                    const SizedBox(height: 22),
                                    SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: const Text(
                                          'Soumettre mes informations',
                                          style: TextStyle(fontWeight: FontWeight.w700),
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
          TextSpan(text: 'Tikiya', style: brandStyle),
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

  const _DarkTextField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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

