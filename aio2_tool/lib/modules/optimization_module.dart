import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OptimizationModule extends StatelessWidget {
  const OptimizationModule({super.key});

  Future<void> _reg(BuildContext context, String val) async {
    try {
      await Process.run('reg', [
        'add',
        r'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects',
        '/v',
        'VisualFXSetting',
        '/t',
        'REG_DWORD',
        '/d',
        val,
        '/f'
      ]);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Performans ayarı uygulandı!"),
          backgroundColor: Colors.green));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.speed, size: 60, color: Colors.orangeAccent),
        const SizedBox(height: 20),
        Text("Performans Yönetimi",
            style:
                GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 50),

        // GLOW BUTONLAR
        _GlowButton(
          title: "En İyi Performans",
          description: "Görselliği kapatır, hızı artırır.",
          color: Colors.greenAccent,
          icon: Icons.flash_on,
          onTap: () => _reg(context, "2"),
        ),
        const SizedBox(height: 30),
        _GlowButton(
          title: "En İyi Görünüm",
          description: "Tüm görsel efektleri açar.",
          color: Colors.purpleAccent,
          icon: Icons.high_quality,
          onTap: () => _reg(context, "1"),
        ),
      ],
    );
  }
}

class _GlowButton extends StatefulWidget {
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _GlowButton({
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isHovered = true);
      }), // Mouse girdi
      onExit: (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isHovered = false);
      }), // Mouse çıktı
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 400,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(_isHovered ? 0.2 : 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: widget.color.withOpacity(_isHovered ? 1.0 : 0.3),
                width: 2),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: 30, // Güçlü Glow, 40 dene
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(widget.icon, color: widget.color, size: 40),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text(widget.description,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
