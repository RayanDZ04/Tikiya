import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/api_client.dart';
import '../services/events_service.dart';
import '../ui/tikiya_colors.dart';
import '../ui/pattern_band.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final EventsService _events = EventsService(ApiClient());
  late Future<_HomeState> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HomeState> _load() async {
    try {
      final items = await _events.listPublicEvents();
      return _HomeState(items: items);
    } catch (e) {
      return _HomeState(items: const [], error: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF070A14),
      body: Stack(
        children: [
          const Positioned.fill(child: _LandingBackground()),
          Positioned.fill(
            child: FutureBuilder<_HomeState>(
              future: _future,
              builder: (context, snap) {
                final state = snap.data;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: SafeArea(
                        bottom: false,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1120),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _TopNav(
                                    onLogin: () => Navigator.of(context).pushNamed('/login'),
                                    onRegister: () => Navigator.of(context).pushNamed('/register'),
                                  ),
                                  const SizedBox(height: 44),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final wide = constraints.maxWidth >= 920;
                                      final left = _HeroCopy(textTheme: textTheme);
                                      final right = const _PhoneMock();

                                      if (!wide) {
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            left,
                                            const SizedBox(height: 20),
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: ConstrainedBox(
                                                constraints: const BoxConstraints(maxWidth: 420),
                                                child: right,
                                              ),
                                            ),
                                            const SizedBox(height: 22),
                                            const _SearchPanel(),
                                            const SizedBox(height: 14),
                                            const _CategoryChips(),
                                            const SizedBox(height: 18),
                                            Center(
                                              child: _PrimaryButton(
                                                label: 'Voir tous les événements',
                                                onPressed: () {},
                                              ),
                                            ),
                                          ],
                                        );
                                      }

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(flex: 6, child: left),
                                                  const SizedBox(width: 28),
                                                  const Expanded(flex: 5, child: _PhoneMock()),
                                                ],
                                              ),
                                              Positioned(
                                                left: 0,
                                                right: 0,
                                                bottom: 120,
                                                child: Align(
                                                  alignment: const Alignment(0.10, 1.0),
                                                  child: ConstrainedBox(
                                                    constraints: const BoxConstraints(maxWidth: 940),
                                                    child: const _HeroBottomBlock(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingBackground extends StatelessWidget {
  const _LandingBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.35, -0.55),
                radius: 1.05,
                colors: [
                  TikiyaColors.bleuProfond.withValues(alpha: 0.95),
                  const Color(0xFF070A14),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: -180,
          top: 260,
          child: Transform.rotate(
            angle: -0.35,
            child: Container(
              width: 820,
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    TikiyaColors.bleuCyan.withValues(alpha: 0.0),
                    TikiyaColors.bleuCyan.withValues(alpha: 0.35),
                    TikiyaColors.bleuCyan.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -220,
          bottom: -40,
          child: Transform.rotate(
            angle: -0.35,
            child: Container(
              width: 920,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.0),
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Positioned(left: 0, top: 0, bottom: 0, child: PatternBand(width: 120, opacity: 0.10)),
        const Positioned(right: 0, top: 0, bottom: 0, child: PatternBand(width: 120, opacity: 0.10)),
      ],
    );
  }
}

class _TopNav extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const _TopNav({
    required this.onLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Tikiya',
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              TextSpan(
                text: '!',
                style: textTheme.titleLarge?.copyWith(
                  color: TikiyaColors.bleuCyan,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showLinks = constraints.maxWidth >= 520;
              if (!showLinks) return const SizedBox.shrink();

              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 8,
                children: const [
                  _NavLink(label: 'Découvrir'),
                  _NavLink(label: 'Événements'),
                  _NavLink(label: 'Organisateurs'),
                  _NavLink(label: 'Aide'),
                ],
              );
            },
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            _PillButton(
              label: 'Se connecter',
              onPressed: onLogin,
              variant: _PillVariant.ghost,
            ),
            _PillButton(
              label: 'Créer un compte',
              onPressed: onRegister,
              variant: _PillVariant.filled,
            ),
          ],
        ),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  const _NavLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.88),
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final TextTheme textTheme;
  const _HeroCopy({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore, réserve et vis\nles meilleurs événements',
          style: textTheme.displaySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Billets, guestlists et recommandations pour\nne rien rater autour de toi.',
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _PrimaryButton(
              label: "Télécharger l'app",
              onPressed: () {},
              icon: Icons.download_rounded,
            ),
            _SecondaryButton(
              label: 'Explorer les événements',
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _PhoneMock extends StatelessWidget {
  const _PhoneMock();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Aperçu de l’application mobile',
      image: true,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.9,
                  heightFactor: 0.9,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.2, -0.2),
                          radius: 0.9,
                          colors: [
                            TikiyaColors.bleuCyan.withValues(alpha: 0.35),
                            const Color(0xFF3B82F6).withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Image.asset(
            'assets/Iphone.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ],
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.75)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un événement...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;

              final pills = <Widget>[
                const _FilterPill(icon: Icons.place_rounded, label: 'Paris'),
                const _FilterPill(icon: Icons.event_rounded, label: 'Ce week-end'),
                const _FilterPill(icon: Icons.auto_awesome_rounded, label: '+100 événement'),
                _FilterPill(
                  icon: Icons.tune_rounded,
                  label: 'Filtres',
                  emphasis: true,
                  onTap: () {},
                ),
              ];

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: compact ? WrapAlignment.start : WrapAlignment.spaceBetween,
                children: pills,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroBottomBlock extends StatelessWidget {
  const _HeroBottomBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SearchPanel(),
        const SizedBox(height: 14),
        const _CategoryChips(),
        const SizedBox(height: 18),
        Center(
          child: _PrimaryButton(
            label: 'Voir tous les événements',
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasis;
  final VoidCallback? onTap;

  const _FilterPill({
    required this.icon,
    required this.label,
    this.emphasis = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = emphasis
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.08);
    final border = Colors.white.withValues(alpha: emphasis ? 0.28 : 0.16);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.85)),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.90),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context) {
    final items = const [
      (Icons.music_note_rounded, 'Musique'),
      (Icons.palette_rounded, 'Culture'),
      (Icons.celebration_rounded, 'Festival'),
      (Icons.headphones_rounded, 'Techno'),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (final it in items)
          _CategoryChip(icon: it.$1, label: it.$2),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CategoryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.78)),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

enum _PillVariant { filled, ghost }

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final _PillVariant variant;

  const _PillButton({
    required this.label,
    required this.onPressed,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final bool filled = variant == _PillVariant.filled;

    final bg = filled
        ? TikiyaColors.bleuCyan.withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.14);
    final fg = Colors.white;
    final border = filled ? Colors.transparent : Colors.white.withValues(alpha: 0.35);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.09),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            TikiyaColors.bleuCyan.withValues(alpha: 0.95),
            const Color(0xFF3B82F6).withValues(alpha: 0.90),
          ],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x44000000), blurRadius: 18, offset: Offset(0, 10)),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _SecondaryButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white.withValues(alpha: 0.92),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      child: Text(label),
    );
  }
}

class _HomeState { 
  final List<PublicEvent> items;
  final String? error;

  const _HomeState({required this.items, this.error});
}

class _EventCard extends StatelessWidget {
  final String title;
  final String? description;
  final String? location;
  final DateTime? startsAt;
  final num? price;

  const _EventCard({
    required this.title,
    this.description,
    this.location,
    this.startsAt,
    this.price,
  });

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$day/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final subtitleParts = <String>[];
    if (location != null && location!.trim().isNotEmpty) subtitleParts.add(location!.trim());
    if (startsAt != null) subtitleParts.add(_formatDate(startsAt!));
    if (price != null) subtitleParts.add('${price!.toString()} FCFA');

    final priceLabel = price == null ? null : '${price!.toString()} FCFA';
    final meta = subtitleParts.isEmpty ? null : subtitleParts.join(' • ');

    return _GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 140,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            TikiyaColors.bleuProfond.withValues(alpha: 0.95),
                            const Color(0xFF1D4ED8).withValues(alpha: 0.75),
                            const Color(0xFF0A0D1D),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.08,
                      child: Image.asset('assets/ticket_logo.webp', fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: Icon(Icons.favorite_border_rounded, size: 18, color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ),
                  if (priceLabel != null)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: Text(
                          priceLabel,
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (meta != null)
            Row(
              children: [
                Icon(Icons.place_rounded, size: 16, color: Colors.white.withValues(alpha: 0.55)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          Text(
            (description == null || description!.trim().isEmpty) ? 'Description non disponible.' : description!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.70)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Détails bientôt disponibles.')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.92),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Voir'),
            ),
          ),
        ],
      ),
    );
  }
}
