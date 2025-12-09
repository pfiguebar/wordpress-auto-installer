# WordPress Auto Installer 🖥️

Script en **Bash** para instalar y configurar automáticamente un sitio WordPress en servidores Linux (Debian/Ubuntu).
Incluye:
 instalación de WP‑CLI, 
 configuración de Apache, 
 creación de base de datos, 
 permisos, 
 instalación de Elementor y 
 desactivación de Gutenberg.

Además, genera un **tema hijo** basado en *twentytwentyfive* con un template básico.

---

## 🚀 Características
- Descarga e instala WordPress con WP‑CLI.
- Configura base de datos y credenciales automáticamente.
- Ajusta permisos y configuración de Apache.
- Crea un tema hijo personalizado.
- Instala y activa Elementor.
- Desactiva Gutenberg y elimina plugins/temas innecesarios.
- Añade el dominio local en `/etc/hosts`.

---

## 📦 Requisitos
- Debian/Ubuntu con Apache, PHP y MySQL/MariaDB instalados.
- Usuario con permisos `sudo`.
- Acceso a `/var/www`.

---

## ⚙️ Uso

Clona el repositorio:
modifica variables directamente en el script antes de ejecutarlo
Ejecuta el script indicando carpeta y dominio:

```bash
git clone https://github.com/pfigueroa/wordpress-auto-installer.git
cd wordpress-auto-installer
./wordpress-auto-installer.sh prueba prueba.com
