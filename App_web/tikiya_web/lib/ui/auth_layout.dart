import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tikiya_colors.dart';
import '../widgets/top_navigation_bar.dart';

class AuthLayout extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showSideBands;
  final double sideBandWidth;
  final double sideBandOpacity;
  final TopNavSection? activeNav;
  final Color backgroundColor;

  const AuthLayout({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.showSideBands = true,
    this.sideBandWidth = 64,
    this.sideBandOpacity = 0.16,
    this.activeNav,
    this.backgroundColor = TikiyaColors.bleuProfond,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 18, 26, 12),
                    child: TopNavigationBar(active: activeNav),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  margin: padding,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TikiyaColors.grisClair),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(11, 28, 62, 0.10),
                        blurRadius: 24,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double effectiveBandWidth = showSideBands
                          ? sideBandWidth
                              .clamp(0.0, (constraints.maxWidth / 3).floorToDouble())
                              .toDouble()
                          : 0.0;

                      return Stack(
                        children: [
                          if (showSideBands && effectiveBandWidth > 0) ...[
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: effectiveBandWidth,
                              child: Opacity(
                                opacity: sideBandOpacity,
                                child: Image.asset(
                                  'assets/moucharabieh.png',
                                  fit: BoxFit.cover,
                                  alignment: Alignment.centerLeft,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              width: effectiveBandWidth,
                              child: Opacity(
                                opacity: sideBandOpacity,
                                child: Image.asset(
                                  'assets/moucharabieh.png',
                                  fit: BoxFit.cover,
                                  alignment: Alignment.centerRight,
                                ),
                              ),
                            ),
                          ],
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              28 + effectiveBandWidth,
                              32,
                              28 + effectiveBandWidth,
                              24,
                            ),
                            child: child,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class TikiyaLogo extends StatelessWidget {
  final double fontSize;
  final bool showPro;

  const TikiyaLogo({super.key, this.fontSize = 32, this.showPro = false});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Tikiya',
            style: GoogleFonts.montserrat(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: TikiyaColors.bleuProfond,
              letterSpacing: 0.8,
            ),
          ),
          TextSpan(
            text: '!',
            style: GoogleFonts.montserrat(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: TikiyaColors.bleuCyan,
              letterSpacing: 0.8,
            ),
          ),
          if (showPro)
            TextSpan(
              text: ' Pro',
              style: GoogleFonts.montserrat(
                fontSize: fontSize - 4,
                fontWeight: FontWeight.w400,
                color: TikiyaColors.grisFonce,
                letterSpacing: 0.6,
              ),
            ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
