# 🚀 Uygulamayı Nasıl Çalıştırırım?

## Hızlı Başlangıç

### 1️⃣ iOS Simülatöründe Çalıştırma (Önerilen)

Terminal'de şu komutları sırayla çalıştırın:

```bash
# Proje klasörüne gidin
cd "/Users/macbook/Desktop/TH Takvim/tarim_hayvancilik_app"

# iOS simülatörünü açın
open -a Simulator

# 5-10 saniye bekleyin, simülatör açılsın

# Uygulamayı çalıştırın
flutter run
```

Simülatör açıldıktan sonra uygulama otomatik olarak yüklenecek ve çalışacaktır.

### 2️⃣ macOS Desktop'ta Çalıştırma (Hızlı Test)

```bash
cd "/Users/macbook/Desktop/TH Takvim/tarim_hayvancilik_app"
flutter run -d macos
```

### 3️⃣ Chrome'da Çalıştırma (Web Versiyonu)

```bash
cd "/Users/macbook/Desktop/TH Takvim/tarim_hayvancilik_app"
flutter run -d chrome
```

## 📱 Özellikler Nasıl Test Edilir?

### Tarım Modülü
1. Alt menüden "Tarım" sekmesine gidin
2. Konum izni isteğini kabul edin
3. Konumunuza göre ekim önerileri görün
4. Hava durumu kartını inceleyin
5. Bu ay ekilebilecek ürünleri görün
6. Önerileri okuyun

### Hayvancılık Modülü
1. Alt menüden "Hayvancılık" sekmesine gidin
2. Sağ üstteki "+" butonuna tıklayın
3. Yeni hayvan ekleyin:
   - Ad: Örn. "Sarıkız"
   - Tür: İnek seçin
   - Cins: Örn. "Montofon"
   - Doğum tarihi seçin
   - İsteğe bağlı: Son doğum ve öğüre tarihi ekleyin
4. "Kaydet" butonuna tıklayın
5. Hayvan kartına tıklayarak detayları görün
6. Düzenle veya sil butonlarını kullanın

## 🔧 Sorun Giderme

### "No devices found" Hatası
```bash
# iOS simülatörünü manuel açın
open -a Simulator

# Cihazları kontrol edin
flutter devices

# Belirli cihazda çalıştırın
flutter run -d <device-id>
```

### Paket Hataları
```bash
# Paketleri temizle ve yeniden yükle
flutter clean
flutter pub get

# iOS için (sadece macOS'ta)
cd ios
pod install
cd ..
```

### Build Hataları
```bash
# Flutter'ı güncelle
flutter upgrade

# Doktor kontrolü
flutter doctor -v
```

## 🎯 Hızlı Komutlar

```bash
# Uygulamayı yeniden başlat (hot restart)
# Uygulama çalışırken terminalde: Shift + R

# Hot reload (değişiklikleri anında yükle)
# Uygulama çalışırken terminalde: R

# Uygulamayı durdur
# Terminalde: Q
```

## 📦 Release Build (Yayın için)

### iOS
```bash
flutter build ios --release
```

### Android
```bash
flutter build apk --release
# veya
flutter build appbundle --release
```

## ✅ İlk Çalıştırma Checklist

- [ ] Flutter SDK kurulu mu? (`flutter --version`)
- [ ] Xcode kurulu mu? (iOS için)
- [ ] Paketler yüklendi mi? (`flutter pub get`)
- [ ] Simülatör/Emülatör açık mı?
- [ ] İnternet bağlantısı var mı? (paket indirme için)

## 💡 İpuçları

1. **İlk çalıştırma uzun sürebilir** - Flutter ilk seferde tüm bağımlılıkları derler
2. **Hot reload kullanın** - Kod değişikliklerini anında görmek için
3. **Konum izni verin** - Tarım modülü için gerekli
4. **Simülatörde konum simüle edin** - Features > Location menüsünden

---

**Hazır mı?** Terminal'i açın ve yukarıdaki komutları çalıştırın! 🚀
