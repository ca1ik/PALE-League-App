import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class AiPhotoModule extends StatefulWidget {
  const AiPhotoModule({super.key});
  @override
  State<AiPhotoModule> createState() => _AiPhotoModuleState();
}

class _AiPhotoModuleState extends State<AiPhotoModule> {
  bool _loading = false;
  Uint8List? _imageBytes;

  Future<void> _generate() async {
    setState(() => _loading = true);
    // Demo: Picsum'dan rastgele görsel çekiyoruz (Gerçek API buraya bağlanır)
    try {
      final response = await http.get(Uri.parse(
          "https://picsum.photos/seed/${Random().nextInt(1000)}/800/800"));
      if (response.statusCode == 200) {
        setState(() => _imageBytes = response.bodyBytes);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Sol Panel: Kontroller
        Expanded(
          flex: 4,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // RGB BAŞLIK
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(colors: [
                  Colors.purple,
                  Colors.pink,
                  Colors.orange,
                  Colors.blue
                ]).createShader(bounds),
                child: Text("Natroff AI Art",
                    style: GoogleFonts.orbitron(
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              const SizedBox(height: 20),
              Text("Hayalindeki görseli oluştur...",
                  style: GoogleFonts.poppins(color: Colors.grey)),
              const SizedBox(height: 20),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                    hintText: "Örn: Uzayda süzülen bir kedi...",
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15))),
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.blue]),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.purple.withOpacity(0.5), blurRadius: 20)
                    ]),
                child: ElevatedButton(
                  onPressed: _loading ? null : _generate,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 20)),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.white),
                            const SizedBox(width: 10),
                            Text("OLUŞTUR",
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ],
                        ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(width: 40),
        // Sağ Panel: Görsel
        Expanded(
          flex: 6,
          child: Container(
            height: 500,
            decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                      color: Colors.purple.withOpacity(0.2), blurRadius: 40)
                ]),
            child: _imageBytes == null
                ? const Center(
                    child: Icon(Icons.image, size: 80, color: Colors.white10))
                : ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                  ),
          ),
        )
      ],
    );
  }
}
