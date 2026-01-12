# 📈 Piyasalar Ekranı - Kullanım Kılavuzu

## 🎯 Özellikler

### ✅ Temel Özellikler
- **En Popüler 5 Türk Hissesi**: THYAO, BIMAS, EREGL, SAHOL, AKBNK
- **Döviz Kurları**: USD/TRY, EUR/TRY
- **Emtia**: Altın (Gram)
- **BIST 100 Endeks Bilgisi**: Anlık endeks değeri ve değişim
- **Gerçek Zamanlı Değişim**: Her varlık için fiyat ve yüzdelik değişim

### ➕ Varlık Ekleme Özelliği
Kullanıcılar "+" butonuna basarak 3 kategoriden varlık ekleyebilir:

#### 1. BIST 100 Hisseleri
- ASELS (Aselsan)
- TUPRS (Tüpraş)
- KCHOL (Koç Holding)
- GARAN (Garanti Bankası)
- ISCTR (İş Bankası)
- SISE (Şişe Cam)
- PETKM (Petkim)
- VAKBN (Vakıfbank)
- ENKAI (Enka İnşaat)
- TCELL (Turkcell)

#### 2. TEFAS Fonları
- GAH (Garanti Portföy Altın)
- TBH (Tacirler Portföy B Tipi)
- IPH (İş Portföy Hisse)
- YAH (Yapı Kredi Portföy Altın)
- AKH (Akbank Portföy Hisse)

#### 3. Tahvil & Menkul Değerler
- Devlet Tahvilleri
- Hazine Bonoları
- Şirket Eurobond'ları

## 🎨 Tasarım Özellikleri

### Renk Şeması
- **Hisse Sembolleri**: 🔵 Mavi
- **Döviz**: 🟢 Yeşil
- **Emtia**: 🟡 Sarı/Amber
- **Fon**: 🟣 Mor
- **Pozitif Değişim**: Yeşil
- **Negatif Değişim**: Kırmızı

### Kart Tasarımı
- Yuvarlatılmış köşeler (12px)
- İnce border
- Dark mode uyumlu
- İkon tabanlı kategori gösterimi

## 📱 Kullanım

### Ana Ekran
```
📊 BIST 100: 10,234.56 (+1.24%)
├── İzleme Listem (8 varlık)
│   ├── THYAO - Türk Hava Yolları
│   ├── BIMAS - BIM Mağazaları
│   ├── USD/TRY - Amerikan Doları
│   └── ...
└── [+] Ekle Butonu
```

### Varlık Ekleme
1. Sağ alt köşedeki **"+ Ekle"** butonuna tıkla
2. 3 sekme arasından seç:
   - BIST 100
   - TEFAS
   - Tahvil
3. Arama çubuğundan ara (sembol veya isim)
4. İstediğin varlığa tıkla
5. ✅ Otomatik olarak izleme listesine eklenir

### Arama Özelliği
- Sembol ile: "THYAO", "USD", "GAH"
- İsim ile: "Türk Hava", "Dolar", "Altın"
- Gerçek zamanlı filtreleme

## 🔧 Teknik Detaylar

### Dosya Yapısı
```
lib/screens/markets_screen.dart
├── MarketsScreen (Ana Widget)
│   ├── _loadWatchlist()
│   ├── _getDefaultMarketItems()
│   ├── _showAddItemDialog()
│   └── _buildMarketItemCard()
└── AddMarketItemSheet (Bottom Sheet)
    ├── TabController (3 tab)
    ├── SearchController
    └── _buildItemsList()
```

### Veri Modeli
```dart
class MarketItem {
  final String symbol;      // Sembol (THYAO, USD/TRY)
  final String name;        // Tam isim
  final String category;    // Hisse, Döviz, Emtia, Fon
  final double price;       // Güncel fiyat
  final double change;      // Değişim miktarı
  final double changePercent; // Değişim yüzdesi
}
```

### State Management
- StatefulWidget kullanımı
- Local state (_watchlist)
- Pull-to-refresh desteği

## 🚀 Gelecek Özellikler (İsteğe Bağlı)

### Faz 2 - API Entegrasyonu
- [ ] Borsa İstanbul API
- [ ] TCMB Döviz Kurları
- [ ] TEFAS API
- [ ] Gerçek zamanlı veri akışı

### Faz 3 - Gelişmiş Özellikler
- [ ] Fiyat alarm sistemi
- [ ] Grafik görüntüleme
- [ ] Haberlere entegrasyon
- [ ] Portföy ekleme (direkt alım)
- [ ] Watchlist kaydetme (DB)
- [ ] Sıralama ve filtreleme
- [ ] Favorilere ekleme

### Faz 4 - Detay Ekranı
- [ ] Varlık detay sayfası
- [ ] Tarihsel grafik (1G, 1H, 1A, Tümü)
- [ ] Al/Sat butonları
- [ ] Teknik analiz göstergeleri
- [ ] Şirket bilgileri

## 📊 Mock Data

Şu an için mock (sahte) veri kullanılıyor. Gerçek API entegrasyonu için:

### Önerilen API'ler
1. **Hisse Senetleri**: IS Investment API, BIST API
2. **Döviz**: TCMB, Bloomberg, Alpha Vantage
3. **TEFAS**: TEFAS Resmi API
4. **Kripto**: Binance, CoinGecko

## 🎯 Navigasyon

Piyasalar ekranına erişim:
```
Ana Menü (☰) → Piyasalar
```

Portfolio Screen'den:
```dart
MarketsScreen(userEmail: authProvider.currentUserEmail!)
```

## 💡 Notlar

- Fiyatlar **demo amaçlıdır**, gerçek piyasa verileri değildir
- Dark/Light mode otomatik uyumlu
- Material 3 tasarım prensiplerine uygun
- Performance optimize edilmiş (AppLogger kullanımı)
- Responsive tasarım

## 🐛 Bilinen Sınırlamalar

- ⚠️ Gerçek API entegrasyonu yok (mock data)
- ⚠️ Watchlist kaydedilmiyor (henüz DB yok)
- ⚠️ Otomatik yenileme yok (pull-to-refresh var)
- ⚠️ Grafikler yok

---

**Durum**: ✅ Temel implementasyon tamamlandı  
**Test Edildi**: ✅ Kod analizi başarılı (0 error)  
**Tasarım**: ✅ Mevcut tema ile uyumlu
