import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'lib/providers/music_provider.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final musicProv = Provider.of<MusicProvider>(context);

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
          SwitchListTile(
            title:
                Text("Müzik", style: GoogleFonts.poppins(color: Colors.white)),
            value: musicProv.isPlaying,
            onChanged: (v) => musicProv.togglePlay(),
            activeColor: Colors.purpleAccent,
          ),
          Slider(
              value: musicProv.volume,
              onChanged: (v) => musicProv.setVolume(v),
              activeColor: Colors.purpleAccent),
          DropdownButton<String>(
            value: musicProv.currentTrack,
            dropdownColor: const Color(0xFF25252D),
            isExpanded: true,
            items: musicProv.tracks
                .map((t) => DropdownMenuItem(
                    value: t,
                    child:
                        Text(t, style: const TextStyle(color: Colors.white))))
                .toList(),
            onChanged: (v) {
              if (v != null) musicProv.changeTrack(v);
            },
          )
        ],
      ),
    );
  }
}
