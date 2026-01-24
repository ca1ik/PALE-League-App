import 'dart:async';
import 'package:flutter/material.dart';

// Ana uygulama ekranınızın olduğu dosyayı buraya import edin.
// Örneğin: import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Animasyon kontrolcüsü (2.5 saniyede belirip kaybolacak şekilde ayarlandı)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Opaklık animasyonu (0'dan 1'e, sonra tekrar 0'a)
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Animasyonu başlat
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // 4 saniye sonra ana ekrana geçiş yap
    Timer(const Duration(seconds: 4), () {
      // Navigator.pushReplacement ile ana ekrana geçiş yapılır.
      // Kendi ana ekran widget'ınızı buraya ekleyin.
      // Navigator.of(context).pushReplacement(
      //   MaterialPageRoute(builder: (_) => const MyHomePage(title: 'Flutter Demo Home Page')),
      // );
      // Not: Ana ekran widget'ınızın adını ve yolunu doğru belirttiğinizden emin olun.
      // Eğer `MyHomePage` adında bir widget'ınız varsa, yorumu kaldırıp kullanabilirsiniz.
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka plan rengini siyah yaparak efektin daha iyi görünmesini sağlayalım
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _opacityAnimation,
          // Görüntüyü yükle ve saydamlığını artır
          child: Opacity(
            opacity:
                0.7, // Saydamlığı artırmak için değeri düşürün (örneğin 0.5)
            child: Image.asset(
              'assets/image_4.png', // Görüntü dosyanızın yolu
              fit: BoxFit.cover, // Ekranı kaplaması için
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}
