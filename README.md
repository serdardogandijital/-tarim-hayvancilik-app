# 🌾 Tarım & Hayvancılık Yönetim Uygulaması

Modern, şık ve kullanıcı dostu bir mobil uygulama ile tarım ve hayvancılık işlemlerinizi kolayca yönetin.

## 📱 Özellikler

### 🌱 Tarım Modülü
- **Konum Bazlı Öneriler**: GPS ile bulunduğunuz bölgeye özel ekim önerileri
- **Ekim Takvimi**: Aylık bazda hangi ürünlerin ekileceğini gösterir
- **Hava Durumu**: Güncel hava durumu bilgisi ve ekim için uygunluk
- **Akıllı Öneriler**: Sulama, gübreleme ve zararlı kontrolü önerileri

### 🐄 Hayvancılık Modülü
- **Hayvan Kayıtları**: Tüm hayvanlarınızı sistematik şekilde kaydedin
- **Doğum Takibi**: Hayvanların doğum tarihlerini ve son doğum bilgilerini takip edin
- **Kızgınlık Takibi**: Sonraki kızgınlık dönemlerini hatırlayın
- **Detaylı Bilgiler**: Her hayvan için yaş, cins, tür ve notlar

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler
- Flutter SDK (3.10.4 veya üzeri)
- Xcode (iOS için)
- Android Studio (Android için)
- Bir iOS simülatörü veya Android emülatörü

### Adım 1: Bağımlılıkları Yükleyin
```bash
cd tarim_hayvancilik_app
flutter pub get
```

### Adım 2: iOS için Ek Kurulum (sadece iOS)
```bash
cd ios
pod install
cd ..
```

### Adım 3: Uygulamayı Çalıştırın

**iOS Simülatöründe:**
```bash
flutter run
```

**Android Emülatöründe:**
```bash
flutter run
```

**Belirli bir cihazda:**
```bash
# Kullanılabilir cihazları listeleyin
flutter devices

# Belirli bir cihazda çalıştırın
flutter run -d <device-id>
```

## 📦 Kullanılan Teknolojiler

- **Flutter**: Cross-platform mobil uygulama framework'ü
- **Material Design 3**: Modern ve şık UI/UX
- **Google Fonts**: Poppins font ailesi
- **Geolocator**: Konum servisleri
- **Geocoding**: Adres çözümleme
- **Intl**: Tarih ve sayı formatlama (Türkçe desteği)
- **Provider**: State management (gelecek güncellemeler için hazır)
- **Firebase**: Backend altyapısı (opsiyonel, gelecek güncellemeler için hazır)

## 🎨 Tasarım Özellikleri

- ✅ Modern ve minimalist arayüz
- ✅ Material Design 3 standartları
- ✅ Yeşil renk paleti (tarım teması)
- ✅ Kolay navigasyon (alt menü)
- ✅ Responsive kartlar ve listeler
- ✅ İkonlar ve emoji'lerle görsel zenginlik
- ✅ Türkçe dil desteği

## 📱 Ekran Görüntüleri

Uygulama 2 ana modülden oluşur:

1. **Tarım Ekranı**: Konum, hava durumu, ekim takvimi ve öneriler
2. **Hayvancılık Ekranı**: Hayvan listesi, detaylar ve kayıt yönetimi

## 🔐 İzinler

Uygulama aşağıdaki izinleri kullanır:

- **Konum İzni**: Bölgeye özel tarım önerileri için
- **İnternet**: Hava durumu bilgisi için (gelecek güncellemelerde)

## 🚀 Play Store ve App Store'a Yükleme

### Android (Play Store)

1. **Release APK Oluşturun:**
```bash
flutter build apk --release
```

2. **App Bundle Oluşturun (önerilir):**
```bash
flutter build appbundle --release
```

3. **Play Console'a Yükleyin:**
   - [Google Play Console](https://play.google.com/console) adresine gidin
   - Yeni uygulama oluşturun
   - `build/app/outputs/bundle/release/app-release.aab` dosyasını yükleyin

### iOS (App Store)

1. **Release Build Oluşturun:**
```bash
flutter build ios --release
```

2. **Xcode ile Archive:**
   - Xcode'da `ios/Runner.xcworkspace` dosyasını açın
   - Product > Archive seçin
   - Archive tamamlandığında Distribute App seçin

3. **App Store Connect'e Yükleyin:**
   - [App Store Connect](https://appstoreconnect.apple.com) adresine gidin
   - Yeni uygulama oluşturun
   - Xcode'dan archive'ı yükleyin

## 🔄 Gelecek Güncellemeler

- [ ] Firebase entegrasyonu (kullanıcı hesapları)
- [ ] Gerçek zamanlı hava durumu API entegrasyonu
- [ ] Bulut senkronizasyonu
- [ ] Fotoğraf ekleme özelliği
- [ ] Bildirimler (kızgınlık ve tarla tarih hatırlatmaları)
- [ ] Raporlama ve istatistikler
- [ ] Çoklu dil desteği

## 📞 Destek

Herhangi bir sorun veya öneri için lütfen iletişime geçin.

## 📄 Hukuki Dokümanlar

- [Gizlilik Politikası](docs/privacy_policy.md)
- [Kullanım Koşulları](docs/terms_of_use.md)

Bu repo, `.github/workflows/pages.yml` ile `docs/` klasörünü otomatik olarak GitHub Pages'e deploy eder. İlk kez etkinleştirmek için repo ayarlarından **Settings → Pages** menüsüne gidip "GitHub Actions" modunu seçin. Workflow her `main` push'unda güncel politikaları yayınlayacak; oluşan URL'yi App Privacy formunda kullanabilirsiniz.

## 📄 Lisans

Bu proje özel kullanım içindir.

---

**Geliştirici Notu**: Bu uygulama Flutter ile geliştirilmiştir ve hem iOS hem de Android platformlarında çalışır. Expo kullanılmamıştır, doğrudan native build sistemi kullanılmaktadır.
