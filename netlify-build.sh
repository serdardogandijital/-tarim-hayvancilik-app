#!/bin/bash
set -e

echo "Installing Flutter..."
# Flutter'ı yükle
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

echo "Flutter version:"
flutter --version

echo "Running flutter doctor..."
flutter doctor -v

echo "Getting dependencies..."
flutter pub get

echo "Building web..."
flutter build web --release --base-href "/"

echo "Copying _redirects file..."
cp _redirects build/web/_redirects || cp web/_redirects build/web/_redirects

echo "Build completed successfully!"
