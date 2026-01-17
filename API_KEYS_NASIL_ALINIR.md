# 🌤️ Hava Durumu API Anahtarları Nasıl Alınır?

Uygulama gerçek hava durumu verilerini almak için güvenilir API'ler kullanır. API anahtarlarını almak **ücretsiz** ve çok kolaydır!

## 📋 Gerekli API Anahtarları

### 1️⃣ OpenWeatherMap API Key (ÖNERİLEN)

**Neden OpenWeatherMap?**
- Dünya çapında en güvenilir hava durumu servisi
- Türkiye için doğru ve güncel veriler
- Günde 1000 ücretsiz istek
- Çiftçiler için ideal

**Nasıl Alınır:**

1. **Kayıt Ol**: https://home.openweathermap.org/users/sign_up
2. **Email Doğrula**: Gelen emaildeki linke tıkla
3. **API Key Al**: 
   - https://home.openweathermap.org/api_keys adresine git
   - "Create Key" butonuna tıkla
   - Key'i kopyala

**Örnek API Key:** `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`

---

### 2️⃣ WeatherAPI Key (YEDEKLEMEİÇİN)

**Neden WeatherAPI?**
- Hızlı ve güvenilir
- Günde 1 milyon ücretsiz istek
- Yedek veri kaynağı olarak mükemmel

**Nasıl Alınır:**

1. **Kayıt Ol**: https://www.weatherapi.com/signup.aspx
2. **Email Doğrula**: Gelen emaildeki linke tıkla
3. **API Key Al**: 
   - Dashboard'da otomatik gösterilir
   - Veya https://www.weatherapi.com/my/ adresinden kopyala

**Örnek API Key:** `1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p`

---

## 🔧 API Anahtarlarını Uygulamaya Ekleme

### Adım 1: API Anahtarlarını Kaydet

`lib/services/weather_service.dart` dosyasını açın ve şu satırları bulun:

```dart
static const String _openWeatherApiKey = 'YOUR_OPENWEATHER_API_KEY';
static const String _weatherApiKey = 'YOUR_WEATHERAPI_KEY';
```

Aldığınız API anahtarlarını buraya yapıştırın:

```dart
static const String _openWeatherApiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
static const String _weatherApiKey = '1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p';
```

### Adım 2: Uygulamayı Yeniden Çalıştır

```bash
flutter run
```

## ✅ Test Etme

1. Uygulamayı açın
2. Tarım sekmesine gidin
3. Konum izni verin veya manuel il seçin
4. Hava Durumu kartında **gerçek veriler** görünecek:
   - Gerçek sıcaklık
   - Gerçek nem oranı
   - Gerçek rüzgar hızı
   - Tarım için uygunluk tavsiyesi

## 🎯 Özellikler

### Çoklu Kaynak Doğrulama
Uygulama **2 farklı kaynaktan** veri çeker ve **ortalama** alır:
- OpenWeatherMap
- WeatherAPI

Bu sayede veriler **%100 güvenilir** olur!

### Akıllı Tarım Tavsiyeleri

Hava durumu verileri analiz edilir:
- ✅ **Sıcaklık**: 5°C - 35°C arası ideal
- ✅ **Rüzgar**: 10 m/s'den az olmalı
- ✅ **Nem**: %30 - %90 arası uygun
- ✅ **Bulutluluk**: %80'den az olmalı

### Gerçek Zamanlı Öneriler

- 🌡️ "Hava çok soğuk, ekim için uygun değil"
- 💨 "Rüzgar çok kuvvetli, ilaçlama yapmayın"
- 💧 "Hava çok kuru, sulama yapın"
- 🌧️ "Nem çok yüksek, mantar hastalıklarına dikkat"
- ✅ "Tarım faaliyetleri için uygun hava koşulları"

## 🔒 Güvenlik

- API anahtarları `.gitignore` dosyasına eklenmiştir
- Kodunuzu GitHub'a yüklerseniz anahtarlar paylaşılmaz
- Anahtarlarınızı kimseyle paylaşmayın

## 💡 İpuçları

1. **Her iki API'yi de ekleyin** - Biri çalışmazsa diğeri devreye girer
2. **Ücretsiz limitler yeterli** - Günlük kullanım için fazlasıyla yeterli
3. **Test edin** - Farklı illeri seçerek hava durumunu kontrol edin

## 🆘 Sorun Giderme

### "Hava durumu bilgisi alınamadı" hatası

1. API anahtarlarını doğru kopyaladığınızdan emin olun
2. İnternet bağlantınızı kontrol edin
3. API limitinizi aşmadığınızdan emin olun

### API Limiti Aşıldı

- OpenWeatherMap: Günde 1000 istek (yeterli)
- WeatherAPI: Günde 1 milyon istek (çok fazla)

Limitler aşılırsa ertesi gün sıfırlanır.

---

**Hazır mı?** API anahtarlarınızı alın ve gerçek hava durumu verilerinin keyfini çıkarın! 🌤️
