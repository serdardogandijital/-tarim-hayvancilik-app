# Netlify'e Deploy Talimatları

## Hızlı Kurulum (Ücretsiz)

1. **Netlify'e gidin:** https://app.netlify.com
2. **GitHub ile giriş yapın**
3. **"Add new site" > "Import an existing project"** tıklayın
4. **"Deploy with GitHub"** seçin
5. **Repository seçin:** `serdardogandijital/-tarim-hayvancilik-app`
6. **Build settings:**
   - Build command: `flutter build web --release` (otomatik algılanacak)
   - Publish directory: `build/web` (otomatik algılanacak)
7. **"Deploy site"** butonuna tıklayın

## Otomatik Deploy
Her GitHub push'unda otomatik olarak deploy edilir.

## Ücretsiz Özellikler
- ✅ Sınırsız bandwidth
- ✅ SSL sertifikası (HTTPS)
- ✅ Özel domain desteği
- ✅ Otomatik CI/CD
- ✅ Global CDN
- ✅ Form handling
- ✅ Branch previews

## Site URL
Deploy sonrası Netlify size otomatik bir URL verecek:
`https://random-name-123456.netlify.app`

Özel domain de ekleyebilirsiniz.

## Not
İlk build biraz uzun sürebilir (Flutter kurulumu nedeniyle). Sonraki build'ler daha hızlı olacaktır.
