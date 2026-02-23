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
# MENU 1 - FULL INSTALL AUTO EXPECT
# ==================================================
if [ "$menu" = "1" ]; then

read -p "Masukkan IP VPS: " IP
read -p "Masukkan Password VPS: " PASS
read -p "Masukkan Domain Panel: " DOMAIN
read -p "Masukkan Domain Node: " DOMAIN_NODE

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

echo "📦 Install dependency (expect, sshpass)..."
apt update -y
apt install -y sshpass expect curl

echo "🗑 Uninstall panel lama..."

sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$IP "
systemctl stop wings 2>/dev/null
docker stop \$(docker ps -aq) 2>/dev/null
docker rm -f \$(docker ps -aq) 2>/dev/null
rm -rf /var/www/pterodactyl
rm -rf /etc/pterodactyl
rm -rf /var/lib/pterodactyl
"

echo "🚀 INSTALL PANEL..."

sshpass -p "$PASS" ssh root@$IP bash -s <<EOF
apt update -y
apt install -y expect curl

expect <<EOD
set timeout -1
spawn bash <(curl -s https://pterodactyl-installer.se)

expect "Input 0-6" { send "0\r" }
expect "Database name" { send "\r" }
expect "Database username" { send "\r" }
expect "Password" { send "\r" }

expect "Select timezone" {
    send "Asia/Jakarta\r"
    send "admin@gmail.com\r"
    send "admin@gmail.com\r"
    send "admin\r"
    send "admin\r"
    send "admin\r"
    send "admin\r"
    send "$DOMAIN\r"
}

expect {
    "(y/N)" { send "y\r" }
    "(Y)es/(N)o" { send "y\r" }
}

expect "Set the FQDN" { send "$DOMAIN\r" }

expect eof
EOD
EOF

echo "🚀 INSTALL WINGS..."

sshpass -p "$PASS" ssh root@$IP bash -s <<EOF
expect <<EOD
set timeout -1
spawn bash <(curl -s https://pterodactyl-installer.se)

expect "Input 0-6" { send "1\r" }
expect "Enter the panel address" { send "$DOMAIN\r" }
expect "Database host username" { send "admin\r" }
expect "Database host password" { send "admin\r" }
expect "Set the FQDN" { send "$DOMAIN_NODE\r" }
expect "Enter email address" { send "admin@gmail.com\r" }

expect {
    "(y/N)" { send "y\r" }
    "(Y)es/(N)o" { send "y\r" }
}

expect eof
EOD
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
echo \"$TOKEN\" > /etc/pterodactyl/config.yml
systemctl enable wings
systemctl restart wings
"

echo "✅ Wings berhasil dijalankan!"
exit
fi

if [ "$menu" = "0" ]; then
exit
fi
