#!/bin/bash

# ==========================================
# AUTO CONFIG WINGS - PTERODACTYL
# Cara pakai:
# bash <(curl -s https://raw.githubusercontent.com/USER/REPO/main/wings.sh)
# ==========================================

echo "Mengambil konfigurasi otomatis untuk Wings..."

cd /var/www/pterodactyl || { echo "❌ Direktori panel tidak ditemukan"; exit 1; }

NODE_ID=$(php artisan tinker --execute="echo optional(\Pterodactyl\Models\Node::latest()->first())->id;" | grep -E '^[0-9]+$' | tail -n 1)

if [ -z "$NODE_ID" ]; then
    echo "❌ Gagal mendapatkan Node ID dari database."
    echo "⚠️ Silakan konfigurasi Wings secara manual."
    exit 1
fi

echo "✅ Node ID terdeteksi: $NODE_ID"
echo "Membuat file konfigurasi Wings..."

mkdir -p /etc/pterodactyl
php artisan p:node:configuration $NODE_ID > /etc/pterodactyl/config.yml

echo "Menyalakan Wings..."

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable wings
systemctl restart wings

sleep 5

echo ""
echo "=============================="
echo "STATUS WINGS"
echo "=============================="

if systemctl is-active --quiet wings; then
    echo -e "\e[1;32m[SUKSES] Wings berhasil dikonfigurasi dan ONLINE!\e[0m"
else
    echo -e "\e[1;31m[WARNING] Wings gagal start otomatis.\e[0m"
    echo "Cek dengan perintah:"
    echo "systemctl status wings"
fi

echo ""
echo "Konfigurasi Wings selesai."
