#!/bin/bash

# ==============================
# CONFIG CLOUDLFARE
# ==============================
ZONE_ID="5f405908bbcf1b3b20173307ce046584"
API_TOKEN="8_EQmOFSrPzb6wFtPFgrMTdLWDXzuuoDmUw2asJR"
DOMAIN="rexzystr.my.id"
# ==============================

CF_API="https://api.cloudflare.com/client/v4"
INSTALLER_URL="https://raw.githubusercontent.com/pterodactyl-installer/pterodactyl-installer/master/install.sh"

############################################
# SUBDOMAIN FUNCTIONS
############################################

create_subdomain() {
    read -p "Masukkan IP VPS: " IP
    read -p "Masukkan Nama Host: " HOST

    HOST=$(echo "$HOST" | tr -cd 'a-zA-Z0-9.-')
    IP=$(echo "$IP" | tr -cd '0-9.')

    FULL_DOMAIN="${HOST}.${DOMAIN}"

    echo "🔄 Membuat ${FULL_DOMAIN} → ${IP}"

    RESPONSE=$(curl -s -X POST "${CF_API}/zones/${ZONE_ID}/dns_records" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"${FULL_DOMAIN}\",\"content\":\"${IP}\",\"ttl\":1,\"proxied\":false}")

    if echo "$RESPONSE" | grep -q '"success":true'; then
        echo "✅ Berhasil membuat subdomain"
    else
        echo "❌ Gagal membuat subdomain"
        echo "$RESPONSE"
    fi
}

check_subdomain() {
    read -p "Masukkan Subdomain: " DOMAIN_CHECK
    RESULT=$(dig +short "$DOMAIN_CHECK")

    if [[ -z "$RESULT" ]]; then
        echo "❌ Tidak ditemukan"
    else
        echo "✅ Valid → $RESULT"
    fi
}

delete_subdomain() {
    read -p "Masukkan Subdomain yang ingin dihapus: " DOMAIN_DELETE

    RESPONSE=$(curl -s -X GET "${CF_API}/zones/${ZONE_ID}/dns_records?name=${DOMAIN_DELETE}" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json")

    RECORD_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | head -n1 | cut -d':' -f2 | tr -d '"')

    if [[ -z "$RECORD_ID" ]]; then
        echo "❌ Record tidak ditemukan"
        return
    fi

    DELETE_RESPONSE=$(curl -s -X DELETE "${CF_API}/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json")

    if echo "$DELETE_RESPONSE" | grep -q '"success":true'; then
        echo "✅ Berhasil dihapus"
    else
        echo "❌ Gagal menghapus"
        echo "$DELETE_RESPONSE"
    fi
}

list_subdomain() {
    echo "📋 Daftar Subdomain:"
    RESPONSE=$(curl -s -X GET "${CF_API}/zones/${ZONE_ID}/dns_records?type=A&per_page=100" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json")

    echo "$RESPONSE" | grep -o '"name":"[^"]*","content":"[^"]*"' | while read line; do
        NAME=$(echo "$line" | cut -d'"' -f4)
        IP=$(echo "$line" | cut -d'"' -f8)
        echo "🌐 $NAME → $IP"
    done
}

############################################
# INSTALL / UNINSTALL PTERODACTYL
############################################

run_installer() {
    bash <(curl -s $INSTALLER_URL)
}

uninstall_menu() {
    clear
    echo "=============================="
    echo "       UNINSTALL MENU         "
    echo "=============================="
    echo "1. Uninstall Panel"
    echo "2. Uninstall Wings"
    echo "3. Uninstall Panel + Wings"
    echo "0. Kembali"
    echo "=============================="
    read -p "Pilih: " UN_CHOICE

    case $UN_CHOICE in
        1)
            echo "⚠️ Menjalankan Uninstall Panel..."
            run_installer
            ;;
        2)
            echo "⚠️ Menjalankan Uninstall Wings..."
            run_installer
            ;;
        3)
            echo "⚠️ Menjalankan Uninstall Panel + Wings..."
            run_installer
            ;;
        0)
            return
            ;;
        *)
            echo "❌ Pilihan tidak valid"
            ;;
    esac
}

############################################
# MENU
############################################

show_menu() {
    clear
    echo "================================="
    echo "        VPS CONTROL MENU         "
    echo "================================="
    echo "1. Create Subdomain"
    echo "2. Cek Subdomain"
    echo "3. Delete Subdomain"
    echo "4. List Semua Subdomain"
    echo "5. Install Panel"
    echo "6. Install Wings"
    echo "7. Install Panel + Wings"
    echo "8. Uninstall Panel / Wings"
    echo "0. Exit"
    echo "================================="
    read -p "Pilih Menu: " CHOICE

    case $CHOICE in
        1) create_subdomain ;;
        2) check_subdomain ;;
        3) delete_subdomain ;;
        4) list_subdomain ;;
        5) run_installer ;;
        6) run_installer ;;
        7) run_installer ;;
        8) uninstall_menu ;;
        0) exit 0 ;;
        *) echo "❌ Pilihan tidak valid" ;;
    esac

    echo ""
    read -p "Tekan Enter untuk kembali..."
    show_menu
}

show_menu
