#!/bin/bash
set -e

# Flutter'ı yükle
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

# Flutter'ı doğrula
flutter doctor

# Bağımlılıkları yükle
flutter pub get

# Web için build yap
flutter build web --release
