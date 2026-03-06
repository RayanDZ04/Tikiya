import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/l10n.dart';
import '../services/auth_service.dart';

/// Full-screen OTP email verification.
///
/// Expects route argument `email` (String) — the address the code was sent to.
/// Pops with `true` on success so the caller can navigate accordingly.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const Color _blue = Color(0xFF0B1C3E);
  static const Color _cyan = Color(0xFF00ACC1);
  static const int _codeLength = 6;

  final _auth = AuthService();
  final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_codeLength, (_) => FocusNode());

  bool _loading = false;
  bool _resending = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: GoogleFonts.montserrat(
                color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: error ? const Color(0xFFB00020) : _blue,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _verify() async {
    if (_code.length < _codeLength) return;
    setState(() => _loading = true);
    try {
      await _auth.verifyEmail(code: _code);
      if (!mounted) return;
      _showSnack(context.l10n.otpSuccess);
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _showSnack('$e', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await _auth.resendOtp();
      if (!mounted) return;
      _showSnack(context.l10n.otpResendSuccess);
      // Clear fields
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
    } catch (e) {
      _showSnack('$e', error: true);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: _blue,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A0B1C3E),
                    blurRadius: 24,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_read_outlined,
                        size: 48, color: _cyan),
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    l10n.otpTitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Subtitle
                  Text(
                    l10n.otpSubtitle(email),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // OTP input boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_codeLength, (i) {
                      return SizedBox(
                        width: 44,
                        height: 52,
                        child: TextFormField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _blue,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFFBDBDBD)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: _cyan, width: 2),
                            ),
                          ),
                          onChanged: (v) {
                            if (v.length == 1 && i < _codeLength - 1) {
                              _focusNodes[i + 1].requestFocus();
                            } else if (v.isEmpty && i > 0) {
                              _focusNodes[i - 1].requestFocus();
                            }
                            // Auto-submit when last box filled
                            if (i == _codeLength - 1 && v.length == 1) {
                              _verify();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  // Verify button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 2,
                      ),
                      onPressed: _loading ? null : _verify,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : Text(
                              l10n.otpVerify,
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Resend link
                  TextButton(
                    onPressed: _resending ? null : _resend,
                    child: _resending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _cyan))
                        : Text(
                            l10n.otpResend,
                            style: GoogleFonts.montserrat(
                              color: _cyan,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
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
