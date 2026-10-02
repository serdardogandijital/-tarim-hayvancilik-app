# Çiftçi+ 1.1.0 (33) yayın durumu — 2 Ekim 2026

## Bu sürümün kapsamı

- Günlük çiftlik özeti, yaklaşan işler, tohumlama/doğum, stok ve gelir-gider kayıtları; ana sayfada Canlı Baskül ile Bitki Analizi ilk sırada.
- İlk kullanımda 3 analiz hakkı; sonraki günlerin ilk girişinde +1 hak. Başarılı fotoğraf analizi 1 hak kullanır. Haklar şu an cihazda saklanır, hesaplar arasında taşınmaz.
- Kullanıcının kendi OpenAI API anahtarı fotoğraflı analiz için gereklidir. Bu sürümde canlı reklam, ödüllü reklam ve ücretli hak satışı yoktur. 10/50 hak ürünleri App Store Connect'te taslak olarak kalacak; sürüm incelemesine eklenmeyecek.
- `pubspec.yaml` sürümü `1.1.0+33`. Canlı App Store 1.0 (build 11), Play Store 1.0.3 (versionCode 32).

## Tamamlanan hazırlık

- Android için yeni yükleme anahtarı bu Mac'te proje dışında oluşturuldu. Google Play Console'da eski anahtarın kaybı nedeniyle sıfırlama talebi, yeni açık sertifikayla gönderildi. Konsol talebi **beklemede** gösteriyor. Yeni gizli anahtar ve parola Git'e eklenmedi.
- Yeni anahtarla imzalı Android AAB başarıyla üretildi: `build/app/outputs/bundle/release/app-release.aab` (69,0 MB). Google onayı gelince Play Console'a yüklenebilir.
- iOS 1.1.0 (33) için imzalı App Store IPA'sı bir kez oluşturuldu; satış/reklam arayüzünü gizleyen son değişikliklerden sonra yeniden derlenmeli.
- Gizlilik politikası kaynak dosyaları gerçek veri akışına göre güncellendi; canlı Netlify sayfasına dağıtım henüz doğrulanmadı.
- Son kodda 81 Flutter testi geçti; statik analizde hata/uyarı yok (126 bilgi düzeyi stil notu). Android release derlemesi tamamlandı.

## Yayın için kalan işler

1. Google yeni Android yükleme anahtarını onayladıktan sonra imzalı AAB'yi Play Console'a yüklemek ve üretim sürümünü incelemeye göndermek. Anahtar onaylanmadan paket yüklenemez.
2. Son kodla imzalı IPA'yı yeniden üretmek, App Store Connect'e yüklemek, 1.1.0 sürüm kaydını ve gerçek davranışı anlatan mağaza metinlerini tamamlamak.
3. Güncel gizlilik politikasını canlı URL'ye dağıtıp App Store gizlilik beyanı ile Play Data Safety yanıtlarını gerçek SDK/veri akışına göre doğrulamak. Eski mağaza açıklamasındaki “veri üçüncü taraflarla paylaşılmaz” ifadesi güncel davranışla uyuşmuyor.
4. Yayın adayını yalnızca Çakır iPhone 14 Pro Max üzerindeki ayrı `.dev` uygulamada kamera, analiz, hak ve temel kayıt akışlarında doğrulamak; mağaza uygulamasının verilerini korumak.

Ücretli paketler sonraki bir iş olarak tutuluyor. Hesap/oturum, sunucuda hak defteri, satın alma doğrulaması ve ödeme geri alma akışı olmadan etkinleştirilmeyecek.
