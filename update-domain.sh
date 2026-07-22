#!/usr/bin/env bash
#
# update-domain.sh
#
# Rewrites every absolute site URL (canonical tags, Open Graph URLs,
# sitemap entries, the robots.txt sitemap line) from the current domain
# to a new one, in a single pass.
#
# Usage:
#   ./update-domain.sh https://preventionresearchinstitute.org
#
# Run it from the site root, commit the result, and deploy. Then submit
# the new sitemap in Google Search Console and set up a 301 from the old
# host to the new one.
#
set -euo pipefail

CURRENT="https://prevention-research-institute.netlify.app"

if [ $# -ne 1 ]; then
  echo "usage: $0 https://newdomain.tld" >&2
  exit 1
fi

NEW="${1%/}"

case "$NEW" in
  https://*) ;;
  *) echo "error: the new domain must start with https://" >&2; exit 1 ;;
esac

if [ "$NEW" = "$CURRENT" ]; then
  echo "nothing to do: already set to $CURRENT"
  exit 0
fi

FILES=$(grep -rl "$CURRENT" . \
          --include='*.html' \
          --include='*.xml' \
          --include='*.txt' \
          --include='*.toml' \
          --include='*.sh' 2>/dev/null || true)

if [ -z "$FILES" ]; then
  echo "no references to $CURRENT found"
  exit 0
fi

echo "Rewriting:"
echo "  from  $CURRENT"
echo "  to    $NEW"
echo

TOTAL=0
for f in $FILES; do
  n=$(grep -c "$CURRENT" "$f" || true)
  # Portable in-place edit across GNU and BSD sed.
  sed -i.bak "s|$CURRENT|$NEW|g" "$f" && rm -f "$f.bak"
  printf '  %-32s %s replaced\n' "$f" "$n"
  TOTAL=$((TOTAL + n))
done

echo
echo "Done. $TOTAL references updated across $(echo "$FILES" | wc -w | tr -d ' ') files."
echo
echo "Remaining manual steps:"
echo "  1. Point the domain at Netlify and confirm HTTPS is issued."
echo "  2. Add a 301 from the old host to $NEW."
echo "  3. Submit $NEW/sitemap.xml in Google Search Console."
