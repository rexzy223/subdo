#!/bin/bash

clear
echo "=========================================="
echo " PANEL MANAGER AUTO INSTALL"
echo "=========================================="
echo ""
echo "1. Install Ulang Panel + Wings"
echo "2. Fix Panel"
echo "3. Start Wings"
echo "0. Exit"
echo ""
read -p "Pilih menu: " menu

# ==================================================
# MENU 1 - FULL INSTALL
# ==================================================
if [ "$menu" = "1" ]; then

read -p "Masukkan IP VPS: " IP
read -p "Masukkan Password VPS: " PASS
read -p "Masukkan Domain Panel: " DOMAIN
read -p "Masukkan Domain Node: " DOMAIN_NODE
read -p "Masukkan RAM Node (MB): " RAM

echo "🔍 Cek DNS..."

DOMAIN_IP=$(dig +short $DOMAIN | tail -n1)
NODE_IP=$(dig +short $DOMAIN_NODE | tail -n1)

if [ -z "$DOMAIN_IP" ] || [ "$DOMAIN_IP" != "$IP" ]; then
    echo "❌ Domain panel tidak valid / belum mengarah ke VPS!"
    exit
fi

if [ -z "$NODE_IP" ] || [ "$NODE_IP" != "$IP" ]; then
    echo "❌ Domain node tidak valid / belum mengarah ke VPS!"
    exit
fi

echo "✅ DNS VALID"
sleep 2

echo "🗑 Uninstall panel lama..."

sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$IP "
systemctl stop wings 2>/dev/null
docker stop \$(docker ps -aq) 2>/dev/null
docker rm -f \$(docker ps -aq) 2>/dev/null
rm -rf /var/www/pterodactyl
rm -rf /etc/pterodactyl
rm -rf /var/lib/pterodactyl
rm -rf /etc/nginx/sites-enabled/pterodactyl.conf
"

echo "🚀 Install Panel + Wings..."

sshpass -p "$PASS" ssh root@$IP "
apt update -y && apt upgrade -y
apt install -y curl wget git unzip tar nginx docker.io mariadb-server redis-server php php-fpm php-cli php-mysql php-gd php-mbstring php-xml php-bcmath php-zip php-curl
systemctl enable docker
systemctl start docker

bash <(curl -s https://pterodactyl-installer.se) <<EOF
0
panel
y
y
$DOMAIN
y
0
y
admin
admin
admin@gmail.com
Admin
Panel
y
y
0
wings
y
$DOMAIN_NODE
y
EOF
"

echo "🖥 Create Node via Script..."

sshpass -p "$PASS" ssh root@$IP <<EOF
domainnode="$DOMAIN_NODE"
ramserver="$RAM"

bash <(curl -s https://raw.githubusercontent.com/rexzy223/tema/main/createnode.sh) <<INPUT
SGP
INSTALL BY REXZY
$DOMAIN_NODE
NODE BY REXZY
$RAM
$RAM
1
INPUT
EOF

echo ""
echo "======================================"
echo "✅ INSTALL SELESAI!"
echo "Panel: https://$DOMAIN"
echo "Email: admin@gmail.com"
echo "Username: admin"
echo "Password: admin"
echo "======================================"

exit
fi

# ==================================================
# MENU 2 - FIX PANEL
# ==================================================
if [ "$menu" = "2" ]; then

read -p "Masukkan IP VPS: " IP
read -p "Masukkan Password VPS: " PASS

echo "🔧 FIX PANEL..."

sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$IP "
systemctl restart nginx
systemctl restart php*-fpm
systemctl restart mariadb
systemctl restart redis-server
systemctl restart wings
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 /var/www/pterodactyl
cd /var/www/pterodactyl 2>/dev/null
php artisan migrate --force
php artisan config:clear
php artisan cache:clear
php artisan view:clear
"

echo "✅ FIX SELESAI"
exit
fi

# ==================================================
# MENU 3 - START WINGS
# ==================================================
if [ "$menu" = "3" ]; then

read -p "Masukkan IP VPS: " IP
read -p "Masukkan Password VPS: " PASS
read -p "Masukkan Token Node: " TOKEN

echo "🚀 Menjalankan Wings..."

sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$IP "
mkdir -p /etc/pterodactyl
echo \"$TOKEN\" > /etc/pterodactyl/token
systemctl enable wings
systemctl restart wings
"

echo "✅ Wings berhasil dijalankan!"
exit
fi

# ==================================================
# EXIT
# ==================================================
if [ "$menu" = "0" ]; then
exit
fi
