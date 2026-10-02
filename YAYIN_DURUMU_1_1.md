# Çiftçi+ 1.1.0 (33) yayın durumu — 2 Ekim 2026

## Hazırlanan sürüm

- `pubspec.yaml` 1.1.0+33; mevcut App Store sürümü 1.0 / build 11, Play üretim sürümü 1.0.3 / versionCode 32.
- Android uygulama manifestinde `com.android.vending.BILLING` izni var. Debug APK'nın birleşik manifestinde izin ve Billing Library sürümü doğrulandı.
- 81 Flutter testi geçti. `flutter analyze --no-fatal-infos --no-fatal-warnings` sıfır hata ve uyarıyla tamamlandı; mevcut 126 bilgi düzeyi stil bildirimi sürüyor.
- iOS codesign kapalı Release derlemesi ve 1.1.0 (33) için imzalı App Store IPA'sı başarıyla oluşturuldu: `build/ios/ipa/tarim_hayvancilik_app.ipa` (39,7 MB). Xcode, varsayılan 1×1 piksel açılış görseli için kalite uyarısı veriyor.
- Gizlilik politikası taslağında artık var olmayan hesap/eşitleme iddiaları kaldırıldı ve OpenAI, hava durumu, isteğe bağlı reklam/satın alma akışları belirtildi. Bu dosya henüz canlı Netlify sitesine dağıtılmadı.

## Canlıya çıkışı engelleyen gerçek durum

1. **Ücretli haklar:** App Store Connect'te `ciftci_analiz_10` (Apple ID 6818513076) ve `ciftci_analiz_50` (Apple ID 6818513224) tüketilebilir **taslaklar** oluşturuldu. Türkçe ad/açıklama ile Türkiye temel fiyatları sırasıyla ₺9,99 ve ₺44,99 kaydedildi. Ürünler henüz incelemede veya satışta değil; erişilebilirlik ve inceleme görselleri tamamlanmalı. Apple'ın ücretli uygulama sözleşmesi, banka hesabı ve vergi formları aktif. Apple ilk ürünleri yeni sürümle birlikte incelemeye göndermeyi istiyor. Play Console, yayınlanmış APK'da faturalandırma izni olmadığından ürün oluşturma ekranını açmıyor; önce yeni imzalı paket yüklenmeli.
2. **Hesap ve sunucu:** `ciftci-6befb` Firebase projesi bulundu; iOS uygulaması ve doğru Android paket adıyla yeni Firebase uygulaması kayıtlı. Projede Cloud Billing kapalı, Cloud Functions dağıtımı için Blaze bağlantısı gerekiyor. Şu an kimlik doğrulama, sunucu hak defteri, ödeme/iade uzlaştırması ve şirket API anahtarıyla çalışan analiz hizmeti yok. Uygulama kullanıcıdan kendi OpenAI anahtarını istiyor. `ANALYSIS_PURCHASES_ENABLED` bu nedenle kapalı kalmalı.
3. **Google Play imzası:** `android/key.properties` ve mevcut Play upload keystore dosyası bu projede yok. Masaüstündeki genel isimli anahtar Mayıs 2026 tarihli; Çiftçi+ Şubat 2026'da yayındaydı. Eşleşme doğrulanmadan kullanılmamalı. Play Console'daki upload sertifikasıyla karşılaştırmak ve gerekirse upload anahtarı sıfırlaması yapmak gerekiyor.
4. **Reklamlar:** Canlı AdMob banner/ödüllü birim kimlikleri verilmedi. Android AdMob politika kısıtı giderilmeden ödüllü reklamı açmak doğru değil. Release derlemesinde mevcut ayarla reklamlar yüklenmez.
5. **Mağaza metinleri:** App Store'daki 1.0 açıklaması “reklamsız” ve “veriler üçüncü taraflarla paylaşılmaz” diyor; yeni sürümün gerçek veri akışına uygun şekilde güncellenmeli. Apple gizlilik bildirimi ve Play Data Safety alanları da aynı bilgilere göre kontrol edilmeli.

**Yayın kuralı:** Yalnızca kodun derlenmesi veya ödeme butonunun görünmesi gerçek satışın güvenli olduğu anlamına gelmez. Sunucu, mağaza ürünleri, iade/geri yükleme ve yalnızca Çakır iPhone 14 Pro Max üzerindeki sandbox testleri tamamlanmadan ücretli sürüm gönderilmez.
