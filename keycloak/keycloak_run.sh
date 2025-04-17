docker run -dp 80:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  quay.io/keycloak/keycloak \
  start \
  --http-enabled true \
  --hostname https://d32lzfs0qoxfh3.cloudfront.net \
  --proxy-headers forwarded
