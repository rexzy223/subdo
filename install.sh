#!/bin/bash

clear
echo "=========================================="
echo " SMART AUTO PANEL INSTALLER + FIXER"
echo "=========================================="
echo ""
echo "1. Install / Fix Panel"
echo "0. Exit"
echo ""
read -p "Pilih menu: " menu

[ "$menu" != "1" ] && exit

echo ""
read -p "Masukkan IP VPS: " IP
read -p "Masukkan Password VPS: " PASS
read -p "Masukkan Domain Panel: " DOMAIN
read -p "Masukkan Domain Node: " DOMAIN_NODE
read -p "Masukkan RAM Node (MB): " RAM

echo ""
echo "🔍 CEK DNS..."

DOMAIN_IP=$(dig +short $DOMAIN | tail -n1)

if [ -z "$DOMAIN_IP" ]; then
    echo "❌ DNS belum aktif!"
    exit
fi

if [ "$DOMAIN_IP" != "$IP" ]; then
    echo "❌ Domain tidak mengarah ke IP VPS!"
    echo "IP VPS: $IP"
    echo "IP Domain: $DOMAIN_IP"
    exit
fi

echo "✅ DNS VALID"
sleep 2

echo ""
echo "🌐 CEK STATUS WEB PANEL..."

HTTP_STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" https://$DOMAIN)

PANEL_INSTALLED=$(sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$IP "[ -d /var/www/pterodactyl ] && echo yes")

# ===============================
# CASE 1: PANEL SUDAH AKTIF
# ===============================
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Panel sudah aktif!"
    INSTALL_MODE="node_only"

# ===============================
# CASE 2: PANEL TERINSTALL TAPI WEB MATI
# ===============================
elif [ "$PANEL_INSTALLED" = "yes" ]; then
    echo "⚠ Panel terinstall tapi web tidak aktif"
    echo "🔧 AUTO FIXING..."

    sshpass -p "$PASS" ssh root@$IP "
    systemctl restart nginx
    systemctl restart php*-fpm
    systemctl restart mariadb
    systemctl restart redis-server
    chown -R www-data:www-data /var/www/pterodactyl
    cd /var/www/pterodactyl
    php artisan migrate --force
    php artisan config:clear
    php artisan cache:clear
    "

    sleep 5

    HTTP_STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" https://$DOMAIN)

    if [ "$HTTP_STATUS" != "200" ]; then
        echo "❌ Fix gagal, reinstall full..."
        INSTALL_MODE="full"
    else
        echo "✅ Fix berhasil!"
        INSTALL_MODE="node_only"
    fi

# ===============================
# CASE 3: BELUM TERINSTALL
# ===============================
else
    echo "🚀 Panel belum terinstall"
    INSTALL_MODE="full"
fi

# ===============================
# FULL INSTALL
# ===============================
if [ "$INSTALL_MODE" = "full" ]; then

sshpass -p "$PASS" ssh root@$IP "
apt update -y && apt upgrade -y
apt install -y curl wget git unzip tar nginx docker.io mariadb-server redis-server
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
fi

# ===============================
# BUAT NODE (SELALU JALAN)
# ===============================

echo "🔑 GENERATE API KEY..."

API_KEY=$(sshpass -p "$PASS" ssh root@$IP "cd /var/www/pterodactyl && php artisan p:api:make" | grep ptla_)

if [ -z "$API_KEY" ]; then
    echo "❌ Gagal ambil API KEY"
    exit
fi

echo "📍 CREATE LOCATION..."

LOCATION_ID=$(curl -s -X POST "https://$DOMAIN/api/application/locations" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json" \
-H "Content-Type: application/json" \
-d '{"short":"auto","long":"Auto Location"}' | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

echo "🖥 CREATE NODE..."

NODE_ID=$(curl -s -X POST "https://$DOMAIN/api/application/nodes" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json" \
-H "Content-Type: application/json" \
-d "{
\"name\":\"AUTO-NODE\",
\"location_id\":$LOCATION_ID,
\"fqdn\":\"$DOMAIN_NODE\",
\"scheme\":\"https\",
\"memory\":$RAM,
\"memory_overallocate\":0,
\"disk\":50000,
\"disk_overallocate\":0,
\"upload_size\":100,
\"daemon_sftp\":2022,
\"daemon_listen\":8080
}" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

echo "⚙ AMBIL CONFIG WINGS..."

curl -s -X GET "https://$DOMAIN/api/application/nodes/$NODE_ID/configuration" \
-H "Authorization: Bearer $API_KEY" \
-H "Accept: Application/vnd.pterodactyl.v1+json" \
> wings_config.json

sshpass -p "$PASS" scp wings_config.json root@$IP:/etc/pterodactyl/config.yml
sshpass -p "$PASS" ssh root@$IP "systemctl restart wings"

echo ""
echo "======================================"
echo "✅ SELESAI!"
echo "Panel: https://$DOMAIN"
echo "Email: admin@gmail.com"
echo "Username: admin"
echo "Password: admin"
echo "Node ID: $NODE_ID"
echo "======================================"
