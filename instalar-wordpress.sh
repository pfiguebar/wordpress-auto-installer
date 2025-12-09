#!/bin/bash

# Verificar que se pasen dos argumentos
if [ $# -lt 2 ]; then
  echo "❌ Debes indicar carpeta y dominio. Ejemplo:"
  echo "./instalar-wordpress.sh proyecto1 proyecto1.local"
  exit 1
fi

SITE_DIR="$1"
SITE_DOMAIN="$2"
DB_NAME="wordpress_${SITE_DIR}"
DB_USER="usuario01"
DB_PASS="A1b2c3f4"
DB_HOST="localhost"
SITE_URL="http://$SITE_DOMAIN"
SITE_TITLE="Proyecto $SITE_DIR"
ADMIN_USER="usuario01"
ADMIN_PASS="A!b2c3f4B!b2c3f4"
ADMIN_EMAIL="admin@$SITE_DOMAIN"

# 🔍 Comprobar si WP-CLI está instalado
if ! command -v wp &> /dev/null
then
    echo "⚠️ WP-CLI no está instalado. Procediendo a instalarlo..."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    php wp-cli.phar --info || { echo "❌ Error: PHP no está instalado o no funciona"; exit 1; }
    chmod +x wp-cli.phar
    sudo mv wp-cli.phar /usr/local/bin/wp
    echo "✅ WP-CLI instalado correctamente."
else
    echo "✅ WP-CLI ya está instalado."
fi

# Crear carpeta para el sitio
mkdir -p "/var/www/$SITE_DIR"
cd "/var/www/$SITE_DIR" || exit

# Descargar WordPress
wp core download

# Crear archivo de configuración
wp config create --dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_PASS --dbhost=$DB_HOST --skip-check

# Crear base de datos (si no existe)
wp db create

# Instalar WordPress
wp core install --url=$SITE_URL --title="$SITE_TITLE" --admin_user=$ADMIN_USER --admin_password=$ADMIN_PASS --admin_email=$ADMIN_EMAIL

# Dar permisos a la instalación
sudo chown -R www-data:www-data "/var/www/$SITE_DIR"
sudo find "/var/www/$SITE_DIR" -type d -exec chmod 755 {} \;
sudo find "/var/www/$SITE_DIR" -type f -exec chmod 644 {} \;

# Activar un tema por defecto
sudo -u www-data wp theme install twentytwentyfive --activate

# Crear tema hijo basado en twentytwentyfive
CHILD_THEME_DIR="/var/www/$SITE_DIR/wp-content/themes/$SITE_DOMAIN"

if [ ! -d "$CHILD_THEME_DIR" ]; then
    echo "⚙️ Creando tema hijo $SITE_DOMAIN..."
    sudo -u www-data mkdir -p "$CHILD_THEME_DIR"

    # Crear style.css del tema hijo
    sudo -u www-data tee "$CHILD_THEME_DIR/style.css" > /dev/null <<EOF
/*
Theme Name: $SITE_DOMAIN
Template: twentytwentyfive
Version: 1.0
*/
EOF

    # Crear functions.php del tema hijo
    sudo -u www-data tee "$CHILD_THEME_DIR/functions.php" > /dev/null <<'EOF'
<?php
function child_theme_enqueue_styles() {
    wp_enqueue_style('parent-style', get_template_directory_uri() . '/style.css');
}
add_action('wp_enqueue_scripts', 'child_theme_enqueue_styles');
EOF

    # Crear template básico
    sudo -u www-data tee "$CHILD_THEME_DIR/template-basico.php" > /dev/null <<'EOF'
<?php
/*
Template Name: Template Básico
Description: Muestra solo los títulos de las páginas.
*/

get_header();

$args = array(
    'post_type'      => 'page',
    'posts_per_page' => -1,
    'orderby'        => 'title',
    'order'          => 'ASC'
);

$custom_query = new WP_Query($args);

if ( $custom_query->have_posts() ) {
    while ( $custom_query->have_posts() ) {
        $custom_query->the_post();
        echo '<h2>' . get_the_title() . '</h2>';
    }
    wp_reset_postdata();
}

get_footer();
EOF

    echo "✅ Tema hijo $SITE_DOMAIN creado. Template básico creado"
else
    echo "ℹ️ El tema hijo $SITE_DOMAIN ya existe."
fi

# Añadir FS_METHOD=direct a wp-config.php si no existe
if ! grep -q "FS_METHOD" wp-config.php; then
    echo "⚙️ Configurando FS_METHOD=direct en wp-config.php..."
    echo "define('FS_METHOD', 'direct');" | sudo tee -a wp-config.php > /dev/null
    echo "✅ FS_METHOD añadido a wp-config.php"
fi

# Reaplicar permisos para asegurar consistencia
sudo chown -R www-data:www-data "/var/www/$SITE_DIR"


# Activar el tema hijo
sudo -u www-data wp theme activate "$SITE_DOMAIN"

# Desinstalar plugins por defecto
sudo -u www-data wp plugin uninstall hello
sudo -u www-data wp plugin uninstall akismet

# Instalar plugin disable gutember para solo usar Elementor y clasic
sudo -u www-data wp plugin install disable-gutenberg --activate

# Instalar y activar Elementor
sudo -u www-data wp plugin install elementor --activate

# Eliminar temas que no sea tema padre y tema hijo (twentytwentyfour y twentytwentythree)
sudo -u www-data wp theme list --field=name | grep -v -E "twentytwentyfive|$SITE_DOMAIN" | xargs -r sudo -u www-data wp theme delete

echo "✅ Gutenberg desactivado y Elementor activado como editor principal. Eliminado temas no usados"

# Crear archivo de configuración de Apache
VHOST_FILE="/etc/apache2/sites-available/$SITE_DIR.conf"
sudo tee $VHOST_FILE > /dev/null <<EOF
<VirtualHost *:80>
    ServerAdmin $ADMIN_EMAIL
    ServerName $SITE_DOMAIN
    DocumentRoot /var/www/$SITE_DIR

    <Directory /var/www/$SITE_DIR>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$SITE_DIR-error.log
    CustomLog \${APACHE_LOG_DIR}/$SITE_DIR-access.log combined
</VirtualHost>
EOF

# Habilitar el sitio y recargar Apache
sudo a2ensite "$SITE_DIR.conf"
sudo systemctl reload apache2

# Añadir dominio local en /etc/hosts si no existe
if ! grep -q "$SITE_DOMAIN" /etc/hosts; then
    echo "127.0.0.1   $SITE_DOMAIN" | sudo tee -a /etc/hosts > /dev/null
    echo "✅ Dominio $SITE_DOMAIN añadido a /etc/hosts"
else
    echo "ℹ️ El dominio $SITE_DOMAIN ya existe en /etc/hosts"
fi

echo "✅ Instalación de WordPress completada en $SITE_URL"
echo "👉 Ya puedes acceder a tu sitio en: $SITE_URL"

