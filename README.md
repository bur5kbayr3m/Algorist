# Algorist - Portföy Yönetim Uygulaması

📱 **Flutter ile geliştirilmiş modern portföy takip uygulaması**

---

## 🚀 TAMAMLANAN ÖZELLİKLER

### 📊 Portföy Yönetimi
- ✅ Portföyüm sayfası - indigo temalı modern tasarım
- ✅ Varlık ekleme/düzenleme/silme işlemleri
- ✅ Toplam varlık değeri görüntüleme
- ✅ Portföy dağılımı grafikleri (Pie Chart)
- ✅ Yoğunluk widget'ı ile varlık analizi
- ✅ İşlem geçmişi takibi
- ✅ Varlık satış işlemleri ve kar/zarar hesaplama

### 🔐 Kimlik Doğrulama & Güvenlik
- ✅ Login/Register işlemleri
- ✅ BCrypt şifre hashleme (güvenli şifre saklama)
- ✅ Email doğrulama sistemi (6 haneli kod)
- ✅ Şifre sıfırlama özelliği
- ✅ Google ile giriş entegrasyonu
- ✅ Provider ile state yönetimi

### 💾 Veritabanı & Veri Yönetimi
- ✅ SQLite veritabanı entegrasyonu
- ✅ Kullanıcı bilgileri saklama
- ✅ Varlık verileri saklama
- ✅ Kullanıcı tercihleri saklama
- ✅ Widget tercihleri saklama

### 👤 Profil Yönetimi
- ✅ Profil sayfası
- ✅ Profil fotoğrafı ekleme (galeri/kamera)
- ✅ Profil fotoğrafı drawer'da görüntüleme
- ✅ Ad soyad ve telefon güncelleme
- ✅ Şifre değiştirme

### ⚙️ Tercihler & Ayarlar
- ✅ Push bildirimleri açma/kapama (aktif switch)
- ✅ Email bildirimleri açma/kapama (aktif switch)
- ✅ Karanlık mod tercihi (aktif switch)
- ✅ Tercihler veritabanında saklanıyor

### 🔔 Bildirim Sistemi
- ✅ flutter_local_notifications entegrasyonu
- ✅ Email bildirim servisi (mailer paketi)
- ✅ Şifre değişikliği güvenlik bildirimi
- ✅ Android bildirim izinleri

### 🎨 Tasarım & UI/UX
- ✅ Indigo temalı modern tasarım (#4F46E5, #7C3AED)
- ✅ Gradient butonlar ve kartlar
- ✅ Hamburger menüsü (Drawer)
- ✅ Kullanıcıya özel widget seçimi
- ✅ Responsive tasarım
- ✅ Modern email doğrulama popup'ları (indigo temalı)

### 📱 Ekranlar
- ✅ Giriş Ekranı (Login)
- ✅ Kayıt Ekranı (Register)
- ✅ Dashboard
- ✅ Portföy Ekranı
- ✅ Varlık Ekleme Ekranı (hisse seçim modalı ile)
- ✅ İşlem Geçmişi Ekranı
- ✅ Profil Ekranı
- ✅ Email Doğrulama Ekranı
- ✅ Şifre Sıfırlama Ekranı
- ✅ Piyasalar Ekranı (gerçek zamanlı Yahoo Finance verileri)
- ✅ Piyasa Varlık Detay Ekranı (4 grafik tipi)
- ✅ Analiz Ekranı

### 📊 Grafikler & Görselleştirme
- ✅ Portföy dağılımı (Pie Chart)
- ✅ Çizgi grafik (Line Chart)
- ✅ Alan grafik (Area Chart)
- ✅ Mum grafik (Candlestick Chart)
- ✅ Çubuk grafik (Bar Chart)
- ✅ Tarihsel veri gösterimi (gün, hafta, ay, 3 ay, yıl, tümü)

### 🌐 API Entegrasyonları
- ✅ Yahoo Finance API - BIST hisse verileri
- ✅ Gerçek zamanlı fiyat çekme
- ✅ Tarihsel veri çekme
- ✅ 30 saniyede bir otomatik güncelleme

---

## 🛠️ TEKNİK DETAYLAR

### Kullanılan Teknolojiler
- **Flutter** 3.38.3
- **Dart** 3.10.1
- **SQLite** (sqflite paketi)
- **BCrypt** şifre hashleme
- **Provider** state yönetimi
- **Google Sign In**
- **flutter_local_notifications** 19.5.0
- **mailer** 6.6.0
- **image_picker** profil fotoğrafı
- **fl_chart** 0.69.0 grafikler
- **http** 1.2.0 API istekleri
- **Yahoo Finance API** gerçek zamanlı BIST verileri

### Android Konfigürasyonu
- Core Library Desugaring aktif (Java 8+ API desteği)
- Bildirim izinleri (POST_NOTIFICATIONS, VIBRATE, etc.)
- Min SDK: 21
- Target SDK: 34

---

## 📋 GELECEK PLANLAR

- [x] ~~API entegrasyonu (canlı fiyat verileri)~~ ✅ Yahoo Finance ile tamamlandı
- [x] ~~Daha fazla grafik türü~~ ✅ 4 grafik tipi eklendi
- [ ] Widget sıralama özelliği
- [ ] Portföy performans analizi
- [ ] Hedef belirleme özelliği
- [ ] Export/Import özelliği
- [ ] Daha fazla borsa eklenmesi (kripto, döviz, emtia)
- [ ] Fiyat alarmları

---

## 🏃 Çalıştırma

```bash
# Bağımlılıkları yükle
flutter pub get

# Uygulamayı çalıştır
flutter run
```

---

## 📝 Son Güncelleme

**Tarih:** 15 Ocak 2026

**Son Değişiklikler:**

### 📈 Piyasalar & Gerçek Zamanlı Veri
- **Yahoo Finance API entegrasyonu** - Gerçek zamanlı BIST hisse verileri
- **4 farklı grafik tipi** eklendi: Çizgi (Line), Alan (Area), Mum (Candlestick), Çubuk (Bar)
- Piyasalar ana sayfasında **3 hisse** gösterimi
- BIST 100 modalında **17 hisse** gösterimi (+ butonu ile)
- **30 saniyede bir otomatik güncelleme** sistemi

### 💰 Portföy İyileştirmeleri
- Hisseler için **gerçek zamanlı kar/zarar** hesaplama
- Yahoo Finance üzerinden güncel fiyat çekme
- Portföy silme işlemi düzeltildi (setState ile)
- Hisse kartlarında anlık fiyat ve kar/zarar gösterimi

### 🎯 Varlık Ekleme
- Hisse eklerken **arama ve seçim modalı** eklendi
- 20 BIST hissesi listesi
- Gerçek zamanlı fiyat ve değişim bilgisi
- Arama özelliği

### 🎨 Navigasyon & UI İyileştirmeleri
- Analiz ve Profil ekranlarından **geri butonları kaldırıldı**
- Alt navigasyon `pushAndRemoveUntil` ile güncellendi
- Login ekranından PortfolioScreen'e yönlendirme eklendi
- Grafiklerde tarihsel veri gösterimi (gün, hafta, ay, 3 ay, yıl, tümü)

### 📦 Paketler
- **fl_chart 0.69.0** paketi eklendi
- **http 1.2.0** ile API istekleri
- **yahoo_finance_service** yeni servis oluşturuldu

**Toplam:** +1446 satır eklendi, -439 satır silindi

---

## 👨‍💻 Geliştirici

Flutter ile ❤️ ile geliştirildi.
