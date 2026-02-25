# Premium Cards - Yeni Kart Tipleri

## 🎨 Eklenen Kart Tipleri

### 1. **ICON** 
- **Renk Paleti**: Altın (#FFD700), Beyaz, Amber
- **Efektler**: Kristal patlaması, altın partiküller, dönen border shimmer
- **Tier**: ⭐⭐⭐⭐⭐ (5 yıldız)
- **Özellik**: Arka plan görseli desteği (assets/cards/icon.png)

### 2. **RAMADAN**
- **Renk Paleti**: Mor (#8B00FF), Altın (#FFD700), Teal (#00CED1)
- **Efektler**: Ay-yıldız motifleri, mistik partiküller, mor-altın gradient
- **Tier**: ⭐⭐⭐ (3 yıldız)
- **Özellik**: Hilal ve yıldız pattern, ruhani parıltı

### 3. **FUTURE STARS**
- **Renk Paleti**: Cyan (#00FFFF), Mavi (#0080FF), Beyaz
- **Efektler**: Neon hologram, dijital grid, tarama çizgisi, köşe aksentleri
- **Tier**: ⭐⭐⭐⭐ (4 yıldız)
- **Özellik**: Futuristik dijital efektler, yukarı yükselen partiküller

### 4. **FANTASY**
- **Renk Paleti**: Magenta (#FF00FF), Mor (#8B00FF), Pembe (#FF69B4)
- **Efektler**: Mistik spiral desenler, sihirli partiküller, nabız aura
- **Tier**: ⭐⭐⭐⭐ (4 yıldız)
- **Özellik**: Dairesel hareket eden partiküller, büyülü glow

### 5. **WINTER**
- **Renk Paleti**: Yeşil (#00FF7F), Buz Mavisi (#E0FFFF), Zümrüt (#50C878)
- **Efektler**: Buzul kristal desenleri, kar taneleri, buzlu shimmer
- **Tier**: ⭐⭐⭐ (3 yıldız)
- **Özellik**: Kar tanesi şekilleri, yavaş düşen animasyon

### 6. **HEROES**
- **Renk Paleti**: Kırmızı (#FF0000), Turuncu (#FF4500), Altın (#FFD700)
- **Efektler**: Alev patlaması, ateş partikülleri, ısı dalgası
- **Tier**: ⭐⭐⭐⭐⭐ (5 yıldız)
- **Özellik**: Alev şekilleri, yukarı yükselen ateş efekti

---

## 📁 Dosya Yapısı

```
lib/
├── data/
│   └── card_types.dart              # Enum ve metadata güncellemeleri
├── widgets/
│   ├── icon_card.dart               # Mevcut ICON kartı
│   ├── create_card_dialog.dart      # Güncellendi - yeni kartları destekler
│   └── premium_cards/               # YENİ KLASÖR
│       ├── ramadan_card.dart
│       ├── future_stars_card.dart
│       ├── fantasy_card.dart
│       ├── winter_card.dart
│       └── heroes_card.dart
├── ui/
│   └── fc_animated_card.dart        # Güncellendi - yeni kart tipleri için renkler
├── screens/
│   └── premium_cards_showcase.dart  # YENİ - Tüm kartları gösteren demo
└── data/
    └── player_data.dart             # globalCardTypes listesi güncellendi
```

---

## 🚀 Kullanım

### 1. Oyuncu Oluştururken Kart Tipi Seçimi

```dart
// CreateCardDialog otomatik olarak yeni kartları gösterir
showCreateCardDialog(context);
```

### 2. Manuel Kart Kullanımı

```dart
// Ramadan Kartı
RamadanCard(
  icon: Icons.nightlight_round,
  title: 'RAMADAN',
  subtitle: 'Special',
  size: 200,
  onTap: () => print('Tapped!'),
)

// Future Stars Kartı
FutureStarsCard(
  icon: Icons.auto_awesome,
  title: 'FUTURE',
  size: 200,
)

// Fantasy Kartı
FantasyCard(
  icon: Icons.auto_fix_high,
  title: 'FANTASY',
  size: 200,
)

// Winter Kartı
WinterCard(
  icon: Icons.ac_unit,
  title: 'WINTER',
  size: 200,
)

// Heroes Kartı
HeroesCard(
  icon: Icons.local_fire_department,
  title: 'HEROES',
  size: 200,
)
```

### 3. Showcase Sayfasını Görüntüleme

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const PremiumCardsShowcase(),
  ),
);
```

---

## 🎯 Teknik Detaylar

### Animasyon Özellikleri
- **60 FPS hedefi**: Tüm animasyonlar optimize edilmiş
- **Particle pooling**: Performans için partiküller önceden oluşturulur
- **RepaintBoundary**: Gerekli yerlerde kullanılabilir
- **CustomPainter**: Canvas API ile özel çizimler

### Performans
- Partiküller lazy-load edilir (ilk render'da oluşturulur)
- AnimationController'lar dispose edilir
- Shader efektleri sadece premium kartlarda aktif

### Renk Sistemi
- Her kart tipi için benzersiz gradient
- Border, glow ve title renkleri tutarlı
- FCAnimatedCard ile tam entegrasyon

---

## 🔧 Entegrasyon Kontrol Listesi

✅ CardType enum'ına yeni tipler eklendi  
✅ CardTypeRegistry'ye metadata eklendi  
✅ Premium card widget'ları oluşturuldu  
✅ CreateCardDialog güncellendi  
✅ FCAnimatedCard renk metodları güncellendi  
✅ globalCardTypes listesi güncellendi  
✅ Tier yıldız sistemi güncellendi  
✅ Shader efektleri eklendi  
✅ Showcase sayfası oluşturuldu  

---

## 🎨 Tasarım Prensipleri

1. **Benzersizlik**: Her kart tipi görsel olarak ayırt edilebilir
2. **Animasyon Kalitesi**: Smooth, 60fps, profesyonel
3. **Tema Tutarlılığı**: Her kartın kendine özgü hikayesi var
4. **Performans**: Optimize edilmiş, mobil uyumlu
5. **Modülerlik**: Kolay genişletilebilir yapı

---

## 📝 Notlar

- ICON kartı için `assets/cards/icon.png` dosyası gerekli
- Tüm kartlar dark theme için optimize edilmiş
- withOpacity yerine withValues kullanıldı (Flutter 3.27+)
- Tüm kartlar responsive ve farklı boyutlarda çalışır

---

## 🎬 Demo

Showcase sayfasını çalıştırarak tüm kartları canlı olarak görebilirsiniz:

```dart
runApp(MaterialApp(
  home: PremiumCardsShowcase(),
));
```

---

**Geliştirici**: Kiro AI Assistant  
**Tarih**: 2026  
**Versiyon**: 1.0.0
