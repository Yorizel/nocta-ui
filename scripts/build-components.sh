#!/usr/bin/env bash
set -euo pipefail

echo "[1/4] Preparing output file..."
mkdir -p public/registry
output_file="public/registry/components.json"
echo "{" > "$output_file"
first=true

echo "[2/4] Preparing regex fixes..."

fix_icons_script="$(mktemp -t fixicons.XXXXXX.pl)"
cat > "$fix_icons_script" <<'PERL'
s#import\s+\{[^}]*\bIcons\b[^}]*\}\s+from\s+(["'])@/app/components/ui/icons/icons\1#import { Icons } from \1@/app/components/ui/icons\1#g;
PERL

echo "[3/4] Encoding TSX components to Base64 JSON..."
find app/components/ui -type f -name '*.tsx' \
  ! -name '*-demos*' | while read -r file; do
    filename=$(basename "$file")

    fixed_content=$(perl -p "$fix_icons_script" "$file")

    encoded=$(printf "%s" "$fixed_content" | base64 | tr -d '\n')

    if [ "$first" = true ]; then
      first=false
    else
      echo "," >> "$output_file"
    fi
    echo "  \"${filename}\": \"${encoded}\"" >> "$output_file"
done

echo "" >> "$output_file"
echo "}" >> "$output_file"

rm -f "$fix_icons_script"

echo "[4/4] Done! Components registry written to $output_file"
