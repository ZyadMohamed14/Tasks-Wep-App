#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# Create a dummy .env file to satisfy the asset requirement
if [ ! -f .env ]; then
  echo "Creating dummy .env file..."
  touch .env
fi

if [ -d "flutter" ]; then
  echo "Flutter directory exists, skipping clone"
else
  echo "Cloning Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

export PATH="$PATH:`pwd`/flutter/bin"

echo "Flutter version:"
flutter --version

echo "Enabling web support..."
flutter config --enable-web

echo "Fetching packages..."
flutter pub get

echo "Building web app..."
flutter build web --release --base-href "/"

# Create 404.html for fallback routing
cp build/web/index.html build/web/404.html

echo "Build complete!"
