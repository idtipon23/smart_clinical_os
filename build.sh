#!/bin/bash
set -e

# 1. ติดตั้ง Flutter SDK
if [ ! -d "_flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 _flutter
fi

export PATH="$PATH:$(pwd)/_flutter/bin"

# 2. Build Web โดยปิด icon tree shaking เพื่อป้องกันไอคอนหาย
flutter config --no-analytics
flutter pub get

: "${SUPABASE_URL:?Set SUPABASE_URL in the Vercel project environment}"
: "${SUPABASE_ANON_KEY:?Set SUPABASE_ANON_KEY in the Vercel project environment}"

flutter build web --release --no-tree-shake-icons \
  --dart-define="SUPABASE_URL=${SUPABASE_URL}" \
  --dart-define="SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}"