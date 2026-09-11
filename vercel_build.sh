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
SUPABASE_URL="${SUPABASE_URL:-https://fjxnjtcxrxeknkoupvsr.supabase.co}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZqeG5qdGN4cnhla25rb3VwdnNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg0MzI0NTEsImV4cCI6MjEwNDAwODQ1MX0.5r9Q_KdkwrVf5gdUKlSD-FBNpR5srJaBE0tbYP2IHWw}"
GEMINI_API_KEY="${GEMINI_API_KEY:-AQ.Ab8RN6KTb0yUvZ2H5gLzXa9O9c3YDD86pXDSHaX2W2B6y9RbTQ}"
GOOGLE_WEB_CLIENT_ID="${GOOGLE_WEB_CLIENT_ID:-8370055353-blvefq7n1goseingrf872f8nmasfa9ee.apps.googleusercontent.com}"

cat <<EOF > .env
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
GEMINI_API_KEY=${GEMINI_API_KEY}
GOOGLE_WEB_CLIENT_ID=${GOOGLE_WEB_CLIENT_ID}
GOOGLE_IOS_CLIENT_ID=your_ios_client_id_here
EOF

echo "=== Installing Flutter Dependencies ==="
flutter pub get

echo "=== Building Flutter Web Application ==="
flutter build web --release --base-href /

echo "=== Flutter Web Build Complete! ==="
