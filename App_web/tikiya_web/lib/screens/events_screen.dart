import 'package:flutter/material.dart';

import '../ui/tikiya_colors.dart';
import '../ui/landing_background.dart';
import '../widgets/top_navigation_bar.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF070A14),
      body: Stack(
        children: [
          const Positioned.fill(child: LandingBackground()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(26, 18, 26, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TopNavigationBar(active: TopNavSection.events),
                      const SizedBox(height: 48),
                      _HeroTitle(textTheme: textTheme),
                      const SizedBox(height: 32),
                      _SearchBar(),
                      const SizedBox(height: 64),
                      const Expanded(child: _EmptyState()),
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

class _HeroTitle extends StatelessWidget {
  final TextTheme textTheme;

  const _HeroTitle({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'À ne pas manquer en Algérie',
          style: textTheme.displayMedium?.copyWith(
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Découvrez et réservez vos prochains événements: concerts,\nsoirées, spectacles et plus encore.',
          style: textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.7),
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Rechercher un événement...',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 22,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _FilterChip(
          icon: Icons.calendar_today,
          label: 'Alger',
          onPressed: () {},
        ),
        const SizedBox(width: 12),
        _FilterChip(
          icon: Icons.date_range,
          label: 'Ce week-end',
          onPressed: () {},
        ),
        const SizedBox(width: 12),
        _FilterChip(
          icon: Icons.tune,
          label: 'Filtres',
          onPressed: () {},
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.8),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  TikiyaColors.bleuCyan.withValues(alpha: 0.2),
                  const Color(0xFF2B6DFF).withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.event_busy_outlined,
              size: 56,
              color: TikiyaColors.bleuCyan.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Aucun événement pour le moment',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Les événements à venir seront bientôt disponibles.\nRevenez plus tard pour découvrir nos prochains événements !',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
