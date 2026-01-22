#!/bin/bash
set -e

echo "Installing Flutter..."
# Flutter'ı yükle
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

echo "Flutter version:"
flutter --version

echo "Getting dependencies..."
flutter pub get

echo "Building web..."
flutter build web --release --base-href "/"

echo "Copying _redirects file..."
if [ -f "_redirects" ]; then
  cp _redirects build/web/_redirects
elif [ -f "web/_redirects" ]; then
  cp web/_redirects build/web/_redirects
else
  echo "/*    /index.html   200" > build/web/_redirects
fi

echo "Build completed successfully!"
