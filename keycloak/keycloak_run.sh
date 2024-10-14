docker run -dp 80:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  quay.io/keycloak/keycloak:26.0.0 \
  start \
  --hostname https://d2x0uw0bb89fpe.cloudfront.net \
  --http-enabled true \
  --proxy-headers xforwarded
