import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart' show navigatorKey;

/// Affiche une popup de résultat de paiement (succès ou échec).
/// Appelé depuis le deep link tikiya://payment/success ou /failure
Future<void> showPaymentResultDialog(
  BuildContext context, {
  required bool success,
  String? ticketId,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (_) => _PaymentResultDialog(success: success, ticketId: ticketId),
  );
}

class _PaymentResultDialog extends StatefulWidget {
  const _PaymentResultDialog({required this.success, this.ticketId});
  final bool success;
  final String? ticketId;

  @override
  State<_PaymentResultDialog> createState() => _PaymentResultDialogState();
}

class _PaymentResultDialogState extends State<_PaymentResultDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  static const Color bleuProfond = Color(0xFF0B1C3E);
  static const Color bleuCyan = Color(0xFF00ACC1);
  static const Color vert = Color(0xFF43A047);
  static const Color rouge = Color(0xFFEF5350);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.success;
    final Color accent = isSuccess ? vert : rouge;
    final IconData icon =
        isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final String title = isSuccess ? 'Paiement réussi !' : 'Paiement échoué';
    final String subtitle = isSuccess
        ? 'Votre billet a été confirmé.\nRetrouvez-le dans "Mes Billets".'
        : 'Le paiement n\'a pas pu être traité.\nVeuillez réessayer.';

    return FadeTransition(
      opacity: _fade,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 40,
                    spreadRadius: 2),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Top band ────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                    gradient: LinearGradient(
                      colors: isSuccess
                          ? [bleuProfond, bleuCyan]
                          : [rouge, const Color(0xFFFF8A80)],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // ── Icon ────────────────────────────────────────────────
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent, size: 52),
                ),
                const SizedBox(height: 20),
                // ── Title ───────────────────────────────────────────────
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: bleuProfond,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: bleuProfond.withValues(alpha: 0.55),
                      height: 1.6,
                    ),
                  ),
                ),
                // ── Ticket ID ───────────────────────────────────────────
                if (isSuccess && widget.ticketId != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: bleuProfond.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.confirmation_num_outlined,
                            size: 14,
                            color: bleuProfond.withValues(alpha: 0.4)),
                        const SizedBox(width: 6),
                        Text(
                          'N° ${widget.ticketId!.substring(0, 8).toUpperCase()}',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: bleuProfond.withValues(alpha: 0.6),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                // ── Buttons ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: [
                      if (isSuccess)
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              // Utilise la clé globale pour une navigation
                              // sûre après fermeture du dialog.
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                navigatorKey.currentState
                                    ?.pushReplacementNamed('/tickets');
                              });
                            },
                            icon: const Icon(Icons.confirmation_num,
                                color: Colors.white, size: 18),
                            label: Text(
                              'Voir mes billets',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: bleuProfond,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      if (isSuccess) const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: bleuProfond.withValues(alpha: 0.2)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            isSuccess ? 'Retour à l\'accueil' : 'Fermer',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: bleuProfond.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
