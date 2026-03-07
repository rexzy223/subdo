#!/bin/bash

# ===============================
# INPUT DATA
# ===============================

echo "Masukkan nama lokasi:"
read location_name

echo "Masukkan deskripsi lokasi:"
read location_description

echo "Masukkan domain node:"
read domain

echo "Masukkan nama node:"
read node_name

echo "Masukkan RAM (MB):"
read ram

echo "Masukkan Disk (MB):"
read disk_space

echo "Masukkan Location ID:"
read locid


# ===============================
# MASUK KE PANEL
# ===============================

cd /var/www/pterodactyl || { echo "❌ Direktori panel tidak ditemukan"; exit 1; }


# ===============================
# BUAT LOCATION
# ===============================

echo "Membuat Location..."

php artisan p:location:make \
--short="$location_name" \
--long="$location_description"


# ===============================
# BUAT NODE
# ===============================

echo "Membuat Node..."

php artisan p:node:make \
--name="$node_name" \
--description="$location_description" \
--locationId="$locid" \
--fqdn="$domain" \
--public=1 \
--scheme=https \
--proxy=0 \
--maintenance=0 \
--maxMemory="$ram" \
--overallocateMemory=0 \
--maxDisk="$disk_space" \
--overallocateDisk=0 \
--uploadSize=100 \
--daemonListeningPort=8080 \
--daemonSFTPPort=2022 \
--daemonBase="/var/lib/pterodactyl/volumes"


# ===============================
# AUTO CONFIG WINGS
# ===============================

echo ""
echo "Mengambil konfigurasi otomatis untuk Wings..."

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


# ===============================
# START WINGS
# ===============================

echo "Menyalakan Wings..."

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable wings
systemctl restart wings

sleep 3


# ===============================
# CEK STATUS
# ===============================

if systemctl is-active --quiet wings; then
    echo ""
    echo -e "\e[1;32m[SUKSES] Wings berhasil dikonfigurasi dan ONLINE!\e[0m"
else
    echo ""
    echo -e "\e[1;31m[WARNING] Wings gagal start otomatis.\e[0m"
    echo "Cek dengan: systemctl status wings"
fi


echo ""
echo "====================================="
echo "INSTALL NODE + WINGS SELESAI"
echo "====================================="
