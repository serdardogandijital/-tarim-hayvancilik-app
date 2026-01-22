# Netlify Otomatik Kurulum

## Adım 1: Netlify Token Alın

1. **https://app.netlify.com/user/applications#personal-access-tokens** adresine gidin
2. **"New access token"** butonuna tıklayın
3. Token'a bir isim verin (örn: "Auto Deploy")
4. **"Generate token"** butonuna tıklayın
5. Token'ı kopyalayın (bir daha gösterilmeyecek!)

## Adım 2: Otomatik Kurulum

Terminal'de şu komutu çalıştırın:

```bash
./netlify-auto-setup.sh YOUR_NETLIFY_TOKEN
```

**YOUR_NETLIFY_TOKEN** yerine aldığınız token'ı yapıştırın.

## Ne Yapıyor?

✅ Netlify CLI yükler
✅ Netlify'e giriş yapar
✅ Yeni site oluşturur
✅ GitHub repository'yi bağlar
✅ Build ayarlarını yapılandırır
✅ İlk deploy'u yapar

## Alternatif: Manuel Token ile API Kullanımı

Eğer script çalışmazsa, token'ı bana verin ve ben API ile otomatik yapılandırayım.

## Sonuç

Kurulum tamamlandıktan sonra:
- Site URL: `https://tarim-hayvancilik-app.netlify.app`
- Her GitHub push'unda otomatik deploy
- Tüm ayarlar otomatik yapılandırılmış
