# 📍 Simülatörde Türkiye Konumu Nasıl Ayarlanır?

Simülatör varsayılan olarak California (CA) konumunu kullanır. Türkiye'den bir konum ayarlamak için:

## 🎯 Yöntem 1: Simülatörde Manuel Konum Ayarlama

### iOS Simülatör

1. **Simülatörü açın**
2. **Features** menüsüne tıklayın
3. **Location** > **Custom Location...** seçin
4. Türkiye'den bir şehir koordinatı girin:

**Popüler Türkiye Şehirleri:**

| Şehir | Latitude | Longitude |
|-------|----------|-----------|
| İstanbul | 41.0082 | 28.9784 |
| Ankara | 39.9334 | 32.8597 |
| İzmir | 38.4237 | 27.1428 |
| Antalya | 36.8969 | 30.7133 |
| Bursa | 40.1826 | 29.0665 |
| Kütahya | 39.4242 | 29.9833 |
| Konya | 37.8667 | 32.4833 |

**Örnek: İstanbul için**
- Latitude: `41.0082`
- Longitude: `28.9784`

5. **OK** butonuna tıklayın
6. Uygulamayı yeniden başlatın veya konum yenile butonuna basın

## 🎯 Yöntem 2: GPX Dosyası ile Konum Simülasyonu

1. **GPX dosyası oluşturun** (istanbul.gpx):

```xml
<?xml version="1.0"?>
<gpx version="1.1" creator="Xcode">
    <wpt lat="41.0082" lon="28.9784">
        <name>İstanbul</name>
    </wpt>
</gpx>
```

2. **Simülatörde:**
   - Features > Location > Custom Location...
   - GPX dosyasını sürükleyin

## 🎯 Yöntem 3: Manuel İl Seçimi (ÖNERİLEN)

Simülatörde konum ayarlamak yerine uygulamadaki **"Farklı İl Seç"** butonunu kullanın:

1. Uygulamayı açın
2. **"Farklı İl Seç"** butonuna tıklayın
3. İstediğiniz ili seçin (örn: İstanbul, Kütahya)
4. Hava durumu otomatik güncellenecek

Bu yöntem **en kolay ve en güvenilir** yöntemdir! ✅

## 🔧 Sorun Giderme

### "CA" veya "Simülatör konumu" görünüyorsa:

1. **Manuel seçim yapın**: "Farklı İl Seç" butonunu kullanın
2. **Simülatör konumunu değiştirin**: Yukarıdaki yöntemlerden birini kullanın
3. **Uygulamayı yeniden başlatın**: Hot restart (R tuşu)

### Konum izni verilmemişse:

1. Simülatör > Settings > Privacy & Security > Location Services
2. Location Services'i açın
3. Uygulamanızı bulun ve "While Using the App" seçin

## ✅ Test

Konum ayarlandıktan sonra:
- Konum kartında şehir adı görünmeli
- Hava durumu gerçek verilerle güncellenecek
- Ekim takvimi seçili şehre göre özelleşecek

---

**Not:** Gerçek cihazda test ederseniz GPS otomatik çalışacaktır!
