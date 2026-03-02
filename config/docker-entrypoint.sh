#!/usr/bin/env sh
set -eu

# ---------------------------
# Initialize variables with default values
# ---------------------------
PUBLIC_DIR=${PUBLIC_DIR:-public}
HTTPS=${HTTPS:-on}
FASTCGI_PASS=${FASTCGI_PASS:-php}

ALONE=false

# ---------------------------
# Determine FastCGI backend configuration
# ---------------------------
case "$FASTCGI_PASS" in
  test)
    FASTCGI_PASS_KEY=""
    FASTCGI_PASS_VALUE=""
    ;;
  alone)
    ALONE=true
    FASTCGI_PASS_KEY="Alone"
    FASTCGI_PASS_VALUE="nginx"
    ;;
  *)
    FASTCGI_PASS_KEY=${FASTCGI_PASS_KEY:-fastcgi_pass}
    FASTCGI_PASS_VALUE=${FASTCGI_PASS_VALUE:-php:9900}
    ;;
esac

echo "Public dir : $PUBLIC_DIR"
echo "HTTPS : $HTTPS"
echo "Fastcgi_pass : $FASTCGI_PASS_KEY $FASTCGI_PASS_VALUE"

# Export variables for envsubst in templates
export PUBLIC_DIR HTTPS FASTCGI_PASS_KEY FASTCGI_PASS_VALUE

# ---------------------------
# Generate Nginx configuration
# ---------------------------
TARGET_CONF="/etc/nginx/sites-available/website"

if [ -f /etc/nginx/sites-available/website.custom ]; then
    cp /etc/nginx/sites-available/website.custom "$TARGET_CONF"
    echo "Website custom nginx config applied"
else
    TEMPLATE_FILE=$([ "$ALONE" = true ] && echo "/etc/nginx/sites-available/website.alone" || echo "/etc/nginx/sites-available/website.template")
    echo "Generating website nginx config from $TEMPLATE_FILE"
    envsubst '$PUBLIC_DIR,$HTTPS,$FASTCGI_PASS_KEY,$FASTCGI_PASS_VALUE' < "$TEMPLATE_FILE" > "$TARGET_CONF"
fi

# ---------------------------
# Execute final command
# ---------------------------
exec "$@"