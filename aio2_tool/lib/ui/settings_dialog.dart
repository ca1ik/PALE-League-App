import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E24),
      title: Row(children: [
        const Icon(Icons.settings, color: Colors.purpleAccent),
        const SizedBox(width: 10),
        Text("Ayarlar", style: GoogleFonts.poppins(color: Colors.white))
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.music_off, color: Colors.grey),
            title: Text("Müzik kaldırıldı",
                style: GoogleFonts.poppins(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
