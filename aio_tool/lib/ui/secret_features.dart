import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // Blur için

// --- 1. PARLAYAN ANAHTAR BUTONU ---
class GlowingKeyButton extends StatefulWidget {
  final VoidCallback onTap;
  const GlowingKeyButton({super.key, required this.onTap});

  @override
  State<GlowingKeyButton> createState() => _GlowingKeyButtonState();
}

class _GlowingKeyButtonState extends State<GlowingKeyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Nefes alma/Parlama animasyonu
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 2.0, end: 15.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(color: Colors.greenAccent, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.6),
                  blurRadius: _animation.value,
                  spreadRadius: 2,
                )
              ],
            ),
            child:
                const Icon(Icons.vpn_key, size: 16, color: Colors.greenAccent),
          ),
        );
      },
    );
  }
}

// --- 2. HACKER GİRİŞ EKRANI (DIALOG) ---
class HackerLoginDialog extends StatefulWidget {
  const HackerLoginDialog({super.key});

  @override
  State<HackerLoginDialog> createState() => _HackerLoginDialogState();
}

class _HackerLoginDialogState extends State<HackerLoginDialog> {
  final TextEditingController _controller = TextEditingController();
  String _status = "AWAITING INPUT...";
  Color _statusColor = Colors.green;

  void _checkPassword() {
    if (_controller.text.trim() == "natroff") {
      setState(() {
        _status = "ACCESS GRANTED";
        _statusColor = Colors.cyanAccent;
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        Navigator.pop(context); // Dialogu kapat
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SecretRoomScreen()),
        );
      });
    } else {
      setState(() {
        _status = "ACCESS DENIED";
        _statusColor = Colors.red;
      });
      _controller.clear();
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _status = "AWAITING INPUT...";
            _statusColor = Colors.green;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        height: 250,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: _statusColor, width: 2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: _statusColor.withOpacity(0.3), blurRadius: 20)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("NATROFF SECURITY PROTOCOL v6.0",
                style: GoogleFonts.sourceCodePro(
                    color: Colors.grey, fontSize: 10)),
            const SizedBox(height: 20),
            Text("> ENTER PASSKEY:",
                style: GoogleFonts.sourceCodePro(
                    color: Colors.greenAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              autofocus: true,
              style:
                  GoogleFonts.sourceCodePro(color: Colors.white, fontSize: 18),
              cursorColor: Colors.greenAccent,
              onSubmitted: (_) => _checkPassword(),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: InputBorder.none,
                focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.greenAccent)),
              ),
            ),
            const Spacer(),
            Text(_status,
                style: GoogleFonts.sourceCodePro(
                    color: _statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}

// --- 3. GİZLİ ODA (CONGRATULATIONS) ---
class SecretRoomScreen extends StatelessWidget {
  const SecretRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Arka plan efekti
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0xFF2E003E), Colors.black],
                    radius: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified, size: 80, color: Colors.amber),
                const SizedBox(height: 20),
                Text(
                  "CONGRATULATIONS!",
                  style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      shadows: [
                        const BoxShadow(
                            color: Colors.purple,
                            blurRadius: 20,
                            spreadRadius: 5)
                      ]),
                ),
                const SizedBox(height: 10),
                Text(
                  "You found the secret admin panel.",
                  style: GoogleFonts.sourceCodePro(
                      color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 50),
                // Buraya gizli butonlar veya içerik koyabilirsin
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      foregroundColor: Colors.white),
                  child: const Text("CLOSE"),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
