#!/bin/bash

# Netlify Otomatik Kurulum Script'i
# Kullanım: ./netlify-auto-setup.sh YOUR_NETLIFY_TOKEN

NETLIFY_TOKEN=$1

if [ -z "$NETLIFY_TOKEN" ]; then
  echo "Hata: Netlify token gerekli!"
  echo "Kullanım: ./netlify-auto-setup.sh YOUR_NETLIFY_TOKEN"
  echo ""
  echo "Token'ı şuradan alabilirsiniz: https://app.netlify.com/user/applications#personal-access-tokens"
  exit 1
fi

REPO_URL="https://github.com/serdardogandijital/-tarim-hayvancilik-app.git"
SITE_NAME="tarim-hayvancilik-app"

echo "Netlify CLI yükleniyor..."
npm install -g netlify-cli

echo "Netlify'e giriş yapılıyor..."
netlify login --auth $NETLIFY_TOKEN

echo "Site oluşturuluyor..."
netlify sites:create --name $SITE_NAME

echo "GitHub repository bağlanıyor..."
netlify link --git

echo "Build ayarları yapılandırılıyor..."
netlify build:settings:set --command "./netlify-build.sh"
netlify build:settings:set --dir "build/web"

echo "Deploy tetikleniyor..."
netlify deploy --prod

echo ""
echo "✅ Kurulum tamamlandı!"
echo "Site URL'iniz: https://$SITE_NAME.netlify.app"
echo ""
echo "Her GitHub push'unda otomatik deploy yapılacak."
