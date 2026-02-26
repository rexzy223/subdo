#!/bin/bash

# ==============================
# CONFIG CLOUDLARE
# ==============================
ZONE_ID="3f33f6c4b5a3dd00ed16d1eb7677338e"
API_TOKEN="le350OqR25wWm5SpSJpcTbalOaTOKJA3FcRV4ohK"
DOMAIN="anti-ddos.me"
# ==============================

CF_API="https://api.cloudflare.com/client/v4"

############################################
# VALIDASI DEPENDENCY
############################################

if ! command -v curl &> /dev/null; then
    echo "curl belum terinstall"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "jq belum terinstall, install dulu: apt install jq -y"
    exit 1
fi

############################################
# FIX PANEL FEATURE
############################################

fix_panel() {
    echo "🔧 MENJALANKAN AUTO FIX PANEL..."
    echo ""

    echo "▶ Restart Nginx..."
    systemctl restart nginx

    echo "▶ Restart PHP-FPM..."
    systemctl restart php8.1-fpm 2>/dev/null
    systemctl restart php8.2-fpm 2>/dev/null

    echo "▶ Restart MySQL..."
    systemctl restart mysql 2>/dev/null
    systemctl restart mariadb 2>/dev/null

    echo "▶ Restart Pteroq (jika ada)..."
    systemctl restart pteroq 2>/dev/null

    echo "▶ Fix Permission Folder Panel..."
    if [ -d "/var/www/pterodactyl" ]; then
        chown -R www-data:www-data /var/www/pterodactyl
        chmod -R 755 /var/www/pterodactyl
        echo "Permission Pterodactyl diperbaiki"
    fi

    echo "▶ Test Config Nginx..."
    nginx -t

    echo "▶ Membuka Port 80 & 443..."
    ufw allow 80 2>/dev/null
    ufw allow 443 2>/dev/null
    ufw reload 2>/dev/null

    echo ""
    echo "✅ FIX PANEL SELESAI"
}

############################################
# CREATE SUBDO

create_subdomain() {
    read -p "Masukkan IP VPS: " IP
    read -p "Masukkan Nama Host (contoh: panel): " HOST

    HOST=$(echo "$HOST" | tr -cd 'a-zA-Z0-9-')
    IP=$(echo "$IP" | tr -cd '0-9.')

    if [[ -z "$HOST" || -z "$IP" ]]; then
        echo "❌ Host/IP tidak valid"
        return
    fi

    PANEL_DOMAIN="${HOST}.${DOMAIN}"
    NODE_DOMAIN="node.${HOST}.${DOMAIN}"

    create_record() {
        local RECORD_NAME=$1

        RESPONSE=$(curl -s -X POST "${CF_API}/zones/${ZONE_ID}/dns_records" \
            -H "Authorization: Bearer ${API_TOKEN}" \
            -H "Content-Type: application/json" \
            --data "{
              \"type\":\"A\",
              \"name\":\"${RECORD_NAME}\",
              \"content\":\"${IP}\",
              \"ttl\":1,
              \"proxied\":false
            }")

        echo "$RESPONSE" | jq -r '.success'
    }

    echo ""
    echo "🔄 Membuat $PANEL_DOMAIN → $IP"
    RESULT1=$(create_record "$PANEL_DOMAIN")

    echo "🔄 Membuat $NODE_DOMAIN → $IP"
    RESULT2=$(create_record "$NODE_DOMAIN")

    echo ""

    if [[ "$RESULT1" == "true" ]]; then
        echo "✅ PANEL DOMAIN BERHASIL"
        echo "🌐 $PANEL_DOMAIN"
    else
        echo "❌ Gagal membuat $PANEL_DOMAIN"
    fi

    if [[ "$RESULT2" == "true" ]]; then
        echo "✅ NODE DOMAIN BERHASIL"
        echo "🌐 $NODE_DOMAIN"
    else
        echo "❌ Gagal membuat $NODE_DOMAIN"
    fi

    echo ""
    echo "🎉 PROSES SELESAI"
}
############################################
# LIST SUBDOMAIN
############################################

list_subdomain() {
    echo "📋 Mengambil daftar subdomain..."

    RESPONSE=$(curl -s -X GET "${CF_API}/zones/${ZONE_ID}/dns_records?type=A&per_page=100" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json")

    COUNT=$(echo "$RESPONSE" | jq '.result | length')

    if [[ "$COUNT" -eq 0 ]]; then
        echo "Tidak ada subdomain."
        return
    fi

    echo ""
    echo "$RESPONSE" | jq -r '.result[] | "🌐 \(.name) → \(.content)"'
}

############################################
# MENU
############################################

show_menu() {
    clear
    echo "================================="
    echo "        SUBDOMAIN MENU           "
    echo "================================="
    echo "1. Create Subdomain"
    echo "2. Cek Subdomain"
    echo "3. Delete Subdomain"
    echo "4. List Semua Subdomain"
    echo "5. 🔧 Fix Panel"
    echo "0. Exit"
    echo "================================="
    read -p "Pilih Menu: " CHOICE

    case $CHOICE in
        1) create_subdomain ;;
        2) check_subdomain ;;
        3) delete_subdomain ;;
        4) list_subdomain ;;
        5) fix_panel ;;
        0) exit 0 ;;
        *) echo "❌ Pilihan tidak valid" ;;
    esac

    echo ""
    read -p "Tekan Enter untuk kembali..."
    show_menu
}

show_menu
