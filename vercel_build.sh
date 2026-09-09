#!/bin/bash
set -e

echo "=== Installing Flutter SDK on Vercel ==="
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable flutter
fi

# Vercel build containers run as root. Flutter refuses that by default, so
# explicitly opt in for this isolated CI build container.
export FLUTTER_ALLOW_ROOT=true
export CI=true
export PATH="$PATH:$(pwd)/flutter/bin"
flutter --version

echo "=== Generating .env Configuration ==="
: "${SUPABASE_URL:?SUPABASE_URL must be configured in the deployment environment}"
: "${SUPABASE_ANON_KEY:?SUPABASE_ANON_KEY must be configured in the deployment environment}"
cat <<EOF > .env
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
GEMINI_API_KEY=${GEMINI_API_KEY}
EOF

echo "=== Installing Flutter Dependencies ==="
flutter pub get

echo "=== Building Flutter Web Application ==="
flutter build web --release --base-href /

echo "=== Flutter Web Build Complete! ==="
