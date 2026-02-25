# ICON KART SİSTEMİ - KULLANıM KILAVUZU

## Oluşturulan Dosyalar

### 1. **IconCard Widget** (`lib/widgets/icon_card.dart`)
Ana parlak altın kart widget'ı. Tüm görsel efektleri içerir.

**Özellikler:**
- ✨ Animasyonlu altın çerçeve ve şimmer efekti
- ✨ Mermer dokusu beyaz arka plan
- ✨ Animasyonlu altın tanecikleri (speckles)
- ✨ Köşelerde parlama efektleri (glints)
- ✨ Kenar shine efektleri
- ✨ İkon gösterimi
- ✨ Başlık ve alt başlık

**Temel Kullanım:**
```dart
IconCard(
  icon: Icons.diamond,
  title: 'KARO',
  subtitle: 'Diamond',
  iconColor: Colors.blueAccent,
  size: 130,
  onTap: () => print('Kart seçildi!'),
)
```

**Parametreler:**
- `icon`: İkonun türü (IconData)
- `title`: Kart başlığı (Türkçe)
- `subtitle`: Alt başlık (İngilizce)
- `iconColor`: İkon rengi
- `size`: Kart boyutu (default: 140)
- `onTap`: Tıklanma işlevi
- `customGradient`: Özel gradient (opsiyonel)

---

### 2. **CardTypeInfo & CardTypeRegistry** (`lib/data/card_types.dart`)
Kart türlerini ve meta verileri yönetir.

**Mevcut Kart Türleri:**
1. **SPADE** (Örümcek) - Mor
2. **HEART** (Kalp) - Kırmızı
3. **DIAMOND** (Karo) - Mavi
4. **CLUB** (Sinek) - Yeşil
5. **MAGIC** (Büyü) - Cyan
6. **TREASURE** (Hazine) - Orange
7. **WILD** (Joker) - Sarı
8. **SPECIAL** (Özel) - Açık Mavi

**Verwendet:**
```dart
// Kart bilgisi al
final info = CardTypeRegistry.getInfo(CardType.spade);
print(info.turkishName);  // "Örümcek"
print(info.color);        // Colors.deepPurpleAccent

// Tüm kartları al
final allCards = CardTypeRegistry.getAllTypes();

// Özel kart türü ekle
CardTypeRegistry.registerCustomType(
  CardTypeInfo(
    type: myCustomType,
    name: 'CUSTOM',
    turkishName: 'Özel',
    icon: Icons.star,
    color: Colors.pinkAccent,
    description: 'Özel kart açıklaması',
  ),
);
```

---

### 3. **CreateCardDialog** (`lib/widgets/create_card_dialog.dart`)
Yeni kart oluşturma diyaloğu - kart türü seçimi için.

**Özellikleri:**
- Tüm kart türlerinin grid görünümü
- Seçili kartın vurgulanması (checkmark ile)
- Seçili kartta bilgi gösterimi
- İptal/Oluştur butonları

**Kullanım:**
```dart
final selectedType = await showCreateCardDialog(context);
if (selectedType != null) {
  print('Seçilen tip: ${selectedType.name}');
  // Yeni kartı işle
}
```

---

### 4. **Showcase Pages**

#### a) **IconCardShowcase** (`lib/screens/icon_card_showcase.dart`)
Tüm kart türlerinin grid gösterimi

#### b) **CardTypesExample** (`lib/screens/card_types_example.dart`)
Tam entegre örnek:
- Kart türleri grid'i
- Yeni kart oluşturma
- Detay görüntüleme
- Silme işlevi

---

## Ana Uygulamanıza Entegrasyon

### Adım 1: Widget İçe Aktar
```dart
import 'package:flutter/material.dart';
import '../widgets/icon_card.dart';
import '../widgets/create_card_dialog.dart';
import '../data/card_types.dart';

class MyCardPage extends StatefulWidget {
  @override
  State<MyCardPage> createState() => _MyCardPageState();
}

class _MyCardPageState extends State<MyCardPage> {
  List<CardType> myCards = [CardType.spade, CardType.heart];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemCount: myCards.length,
      itemBuilder: (context, index) {
        final cardInfo = CardTypeRegistry.getInfo(myCards[index]);
        return IconCard(
          icon: cardInfo.icon,
          title: cardInfo.turkishName,
          subtitle: cardInfo.name,
          iconColor: cardInfo.color,
          onTap: () => print('${cardInfo.name} seçildi'),
        );
      },
    );
  }
}
```

### Adım 2: Yeni Kart Oluşturma
```dart
void _createNewCard() async {
  final selectedType = await showCreateCardDialog(context);
  if (selectedType != null) {
    setState(() {
      myCards.add(selectedType);
    });
  }
}
```

### Adım 3: Detay Görünümü
```dart
void _showCardDetails(CardTypeInfo cardInfo) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(cardInfo.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconCard(icon: cardInfo.icon, iconColor: cardInfo.color),
          SizedBox(height: 16),
          Text(cardInfo.description),
        ],
      ),
    ),
  );
}
```

---

## Görsel Efektler Açıklaması

### 1. **Altın Çerçeve (Golden Border)**
- Sweeping gradient animasyonu
- Altın tonları ile dinamik renk geçişi
- Etrafında parlayan halo efekti

### 2. **Mermer Dokusu (Marble Texture)**
- Beyaz/gri gradient arka plan
- Kırılgan görünüm için ince çizgiler (veins)

### 3. **Altın Şerit (Gold Streak)**
- Çapraz olarak kart üstüne yerleştirilmiş
- Dinamik göz çekici efekt

### 4. **Shimmer Efekti**
- Tüm kart üzerinde hareket eden ışık
- Soft ve sakin animasyon

### 5. **Altın Tanecikleri (Gold Speckles)**
- Sinüs fonksiyonuyla animasyonlu parçacıklar
- Rastgele konumlandırılmış
- Hareket ederek yükselen efekt

### 6. **Köşe Parlaması (Corner Glints)**
- 4 köşede sinüs dalgasıyla animasyonlu ışık noktaları
- Kart üzerinde canlı parlama yaratır

### 7. **Kenar Shine'ı (Edge Shine)**
- Kart sınırı etrafında hareket eden ışık
- Soft ve gözle görülür efekt

---

## Özelleştirme Örnekleri

### Özel Renk ile IconCard
```dart
IconCard(
  icon: Icons.star,
  iconColor: Colors.purpleAccent,
  size: 200,
)
```

### Sadece İkon (Metin Olmadan)
```dart
IconCard(
  icon: Icons.diamond,
  iconColor: Colors.blueAccent,
)
```

### Özel Kart Türü Ekleme
```dart
class MyCustomCardType {
  static const special = CardType.special; // genişletilmiş
}

final customInfo = CardTypeInfo(
  type: CardType.special,
  name: 'MYTHIC',
  turkishName: 'Efsanevi',
  icon: Icons.star,
  color: Colors.purpleAccent,
  description: 'Çok nadir ve güçlü bir kart türü',
);

CardTypeRegistry.registerCustomType(customInfo);
```

---

## Animasyon Özellikleri

- **Duration**: 6 saniye (temel döngü)
- **Repeat**: Sonsuz tekrar
- **Frame Rate**: 60 FPS uyumlu
- **Performance**: Minimal impact

---

## İyileştirme Fikirleri

1. **Ses Efektleri**: Kart seçiminde ding sesi
2. **Particle Effects**: Kart oluşturma sırasında parlayan parçacıklar
3. **3D Flip Animasyonu**: Kart tıklanarak ters çevrilme
4. **Drag & Drop**: Kartları sürükle-bırak
5. **Koleksiyonlar**: Kart gruplarını kategorize etme
6. **Rareity Levels**: Kart nadir dönemleri
7. **Collection Stats**: İstatistik paneli

---

## Dosya Yapısı

```
lib/
├── data/
│   └── card_types.dart                 # Kart türleri tanımı
├── widgets/
│   ├── icon_card.dart                  # Ana IconCard widget
│   ├── create_card_dialog.dart         # Yeni kart diyaloğu
│   └── golden_card.dart                # (Mevcut - uyumlu)
└── screens/
    ├── icon_card_showcase.dart         # Showcase sayfası
    └── card_types_example.dart         # Tam entegre örnek
```

---

## Hata Giderme

**Q: Efektler görünmüyor**
A: AnimationController'ın vsync sağlayıcıdır - State'in TickerProviderStateMixin ile mixin yapılandığından emin olun

**Q: Animasyon çok hızlı/yavaş**
A: `duration` parametresini `AnimationController` oluşturmasında ayarla

**Q: Bellek sızıntısı**
A: `dispose()` içinde AnimationController'ı serbest bıraktığından emin ol

**Q: Grid çok yavaş**
A: ListView yerine GridView.builder kullan ve itemCount sınırlı tut

---

## Lisans

Bu sistem, PALE League App için özel olarak tasarlanmıştır.
