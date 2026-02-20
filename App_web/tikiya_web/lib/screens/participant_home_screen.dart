import 'package:flutter/material.dart';

import '../ui/landing_background.dart';
import '../widgets/top_navigation_bar.dart';
import '../l10n/app_localizations.dart';

class ParticipantHomeScreen extends StatelessWidget {
  const ParticipantHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFF070A14),
      body: Stack(
        children: [
          const Positioned.fill(child: LandingBackground()),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TopNavigationBar(
                        active: TopNavSection.participants,
                      ),
                      const SizedBox(height: 44),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 920;
                            return SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _ParticipantHero(
                                    textTheme: textTheme,
                                    l10n: l10n,
                                    compact: !wide,
                                  ),
                                  const SizedBox(height: 28),
                                  _FeatureGrid(wide: wide, l10n: l10n),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantHero extends StatelessWidget {
  final TextTheme textTheme;
  final bool compact;
  final AppLocalizations l10n;

  const _ParticipantHero({required this.textTheme, required this.l10n, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final titleStyle = (compact ? textTheme.headlineMedium : textTheme.displaySmall)?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w900,
      height: 1.05,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.t('participant_title'), style: titleStyle),
        const SizedBox(height: 14),
        Text(
          l10n.t('participant_subtitle'),
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final bool wide;
  final AppLocalizations l10n;

  const _FeatureGrid({required this.wide, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final maxWidth = wide ? 980.0 : 720.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final crossAxisCount = w >= 980
                ? 3
                : w >= 640
                    ? 2
                    : 1;

            // PNG visibles en entier (pas de crop) + cartes compactes
            final imageViewportHeight = 470.0;
            // Place pour: titre (haut) + description (bas) + paddings
            final mainAxisExtent = imageViewportHeight + 108.0;

            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: mainAxisExtent,
              ),
              children: [
                _FeatureCard(
                  title: l10n.t('participant_feature1_title'),
                  subtitle: l10n.t('participant_feature1_sub'),
                  asset: 'assets/Qr.png',
                  imageViewportHeight: imageViewportHeight,
                  imageAlignment: wide ? Alignment.topCenter : Alignment.topLeft,
                  imageScale: 1.08,
                  imageYOffset: 10.0,
                ),
                _FeatureCard(
                  title: l10n.t('participant_feature2_title'),
                  subtitle: l10n.t('participant_feature2_sub'),
                  asset: 'assets/Market.png',
                  imageViewportHeight: imageViewportHeight,
                  imageAlignment: wide ? Alignment.topCenter : Alignment.topLeft,
                  imageScale: 1.22,
                ),
                _FeatureCard(
                  title: l10n.t('participant_feature3_title'),
                  subtitle: l10n.t('participant_feature3_sub'),
                  asset: 'assets/Pay.png',
                  imageViewportHeight: imageViewportHeight,
                  imageAlignment: wide ? Alignment.topCenter : Alignment.topLeft,
                  imageScale: 1.28,
                  imageYOffset: 50.0,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String asset;
  final double imageViewportHeight;
  final Alignment imageAlignment;
  final double imageScale;
  final double imageYOffset;
  final double imageXOffset;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.imageViewportHeight,
    this.imageAlignment = Alignment.center,
    this.imageScale = 1.0,
    this.imageYOffset = 0.0,
    this.imageXOffset = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return _HoverFeatureCard(
      title: title,
      subtitle: subtitle,
      asset: asset,
      imageViewportHeight: imageViewportHeight,
      imageAlignment: imageAlignment,
      imageScale: imageScale,
      imageYOffset: imageYOffset,
      imageXOffset: imageXOffset,
    );
  }
}

class _HoverFeatureCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String asset;
  final double imageViewportHeight;
  final Alignment imageAlignment;
  final double imageScale;
  final double imageYOffset;
  final double imageXOffset;

  const _HoverFeatureCard({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.imageViewportHeight,
    this.imageAlignment = Alignment.center,
    this.imageScale = 1.0,
    this.imageYOffset = 0.0,
    this.imageXOffset = 0.0,
  });

  @override
  State<_HoverFeatureCard> createState() => _HoverFeatureCardState();
}

class _HoverFeatureCardState extends State<_HoverFeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final cardScale = _hovered ? 1.03 : 1.0;
    final borderAlpha = _hovered ? 0.22 : 0.10;
    final bgAlpha = _hovered ? 0.09 : 0.06;
    final glowAlpha = _hovered ? 0.22 : 0.12;

    final titleStyle = textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w900,
      height: 1.05,
      letterSpacing: 0.2,
    );

    final subtitleStyle = textTheme.bodyMedium?.copyWith(
      color: Colors.white.withValues(alpha: 0.78),
      fontWeight: FontWeight.w600,
      height: 1.25,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: cardScale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: bgAlpha),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: borderAlpha)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2B6DFF).withValues(alpha: glowAlpha),
                blurRadius: _hovered ? 38 : 24,
                spreadRadius: _hovered ? 2 : 0,
                offset: Offset(0, _hovered ? 18 : 14),
              ),
              BoxShadow(
                color: const Color(0x33000000).withValues(alpha: _hovered ? 0.40 : 0.32),
                blurRadius: _hovered ? 30 : 22,
                offset: Offset(0, _hovered ? 18 : 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.2, -0.3),
                          radius: 1.0,
                          colors: [
                            const Color(0xFF2B6DFF).withValues(alpha: _hovered ? 0.26 : 0.18),
                            const Color(0xFF00ACC1).withValues(alpha: _hovered ? 0.14 : 0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                          const SizedBox(height: 4),
                        ClipRect(
                          child: SizedBox(
                            height: widget.imageViewportHeight,
                            width: double.infinity,
                            child: Align(
                              alignment: widget.imageAlignment,
                              child: Transform.translate(
                                offset: Offset(widget.imageXOffset, widget.imageYOffset),
                                child: Transform.scale(
                                  scale: widget.imageScale,
                                  child: Image.asset(
                                    widget.asset,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.white.withValues(alpha: 0.70),
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: subtitleStyle,
                        ),
                      ],
                    ),
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
