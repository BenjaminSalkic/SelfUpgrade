#!/bin/zsh
set -euo pipefail
echo "Creating frontend/ and moving frontend files if present..."
mkdir -p frontend
FILES=(lib pubspec.yaml analysis_options.yaml README.md web ios android assets build)
for f in "${FILES[@]}"; do
  if [ -e "$f" ]; then
    mv "$f" frontend/ && echo "Moved $f -> frontend/"
  fi
done
echo "All done. Run the following commands to finish setup:"
echo "  cd frontend && flutter pub get"
echo "You may need to adjust IDE workspace settings and run a full clean/build for web assets."
