#!/bin/sh

# ci_post_clone.sh
# Generates Secrets.xcconfig from Xcode Cloud environment variables

echo "Generating Secrets.xcconfig..."

cat > "$CI_PRIMARY_REPOSITORY_PATH/my-protein-buddy/Secrets.xcconfig" <<EOF
//
//  Secrets.xcconfig
//  my-protein-buddy
//

FATSECRET_CLIENT_ID = ${FATSECRET_CLIENT_ID}
FATSECRET_CLIENT_SECRET = ${FATSECRET_CLIENT_SECRET}
GOOGLE_URL_SCHEME = ${GOOGLE_URL_SCHEME}
EOF

echo "Secrets.xcconfig generated successfully."
